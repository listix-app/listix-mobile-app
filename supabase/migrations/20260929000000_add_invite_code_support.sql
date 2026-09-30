-- Migration: 20260929000000_add_invite_code_support.sql
-- Description: Adds short alphanumeric invite_code support to list_invites while preserving internal secure token_hash, expiration, revocation, and 5-member limit.

-- 1. Add invite_code column and index
ALTER TABLE public.list_invites
ADD COLUMN IF NOT EXISTS invite_code TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_list_invites_invite_code
ON public.list_invites (upper(invite_code))
WHERE invite_code IS NOT NULL;

-- 2. Update create_list_invite RPC to accept p_invite_code
CREATE OR REPLACE FUNCTION public.create_list_invite(
    p_list_id UUID,
    p_token_hash TEXT,
    p_expires_at TIMESTAMPTZ,
    p_invite_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_invite RECORD;
BEGIN
    -- Validate caller is list owner or admin
    IF NOT EXISTS (
        SELECT 1 FROM public.list_members
        WHERE list_id = p_list_id AND user_id = auth.uid() AND role IN ('owner', 'admin')
    ) THEN
        RAISE EXCEPTION 'PERMISSION_DENIED: User is not a member of list %', p_list_id;
    END IF;

    -- Deactivate previous active invites for this list to support rotating links
    UPDATE public.list_invites
    SET is_active = false
    WHERE list_id = p_list_id AND is_active = true;

    -- Insert new invite with both secure token hash and public invite code
    INSERT INTO public.list_invites (
        list_id,
        token_hash,
        invite_code,
        created_by,
        expires_at,
        is_active
    ) VALUES (
        p_list_id,
        p_token_hash,
        UPPER(TRIM(p_invite_code)),
        auth.uid(),
        p_expires_at,
        true
    )
    RETURNING id, list_id, invite_code, expires_at, created_at, is_active INTO v_invite;

    RETURN jsonb_build_object(
        'success', true,
        'invite_id', v_invite.id,
        'list_id', v_invite.list_id,
        'invite_code', v_invite.invite_code,
        'expires_at', v_invite.expires_at,
        'created_at', v_invite.created_at
    );
END;
$$;

-- 3. Update validate_list_invite RPC to validate by invite_code or token_hash
DROP FUNCTION IF EXISTS public.validate_list_invite(TEXT);

CREATE OR REPLACE FUNCTION public.validate_list_invite(
    p_token_hash TEXT DEFAULT NULL,
    p_invite_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_invite RECORD;
    v_list RECORD;
    v_member_count INT;
    v_search_code TEXT;
    v_search_hash TEXT;
BEGIN
    v_search_code := UPPER(TRIM(COALESCE(p_invite_code, '')));
    v_search_hash := TRIM(COALESCE(p_token_hash, ''));

    IF v_search_code = '' AND v_search_hash = '' THEN
        RETURN jsonb_build_object(
            'valid', false,
            'error_code', 'INVALID_TOKEN_FORMAT',
            'message', 'El formato del código o token de invitación es inválido.'
        );
    END IF;

    -- If only p_token_hash was passed and length is <= 12, treat it as an invite code
    IF v_search_code = '' AND length(v_search_hash) > 0 AND length(v_search_hash) <= 12 THEN
        v_search_code := UPPER(v_search_hash);
    END IF;

    -- 1. Find invite by invite code or token hash
    SELECT * INTO v_invite
    FROM public.list_invites
    WHERE (
        (v_search_code <> '' AND invite_code IS NOT NULL AND UPPER(invite_code) = v_search_code)
        OR (v_search_hash <> '' AND token_hash = v_search_hash)
    )
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_invite IS NULL THEN
        RETURN jsonb_build_object(
            'valid', false,
            'error_code', 'INVITE_NOT_FOUND',
            'message', 'El enlace de invitación no existe o es inválido.'
        );
    END IF;

    -- 2. Check if revoked
    IF NOT v_invite.is_active THEN
        RETURN jsonb_build_object(
            'valid', false,
            'error_code', 'INVITE_REVOKED',
            'message', 'Este enlace de invitación ha sido desactivado o revocado.'
        );
    END IF;

    -- 3. Check expiration
    IF v_invite.expires_at <= now() THEN
        RETURN jsonb_build_object(
            'valid', false,
            'error_code', 'INVITE_EXPIRED',
            'message', 'El enlace de invitación ha caducado.'
        );
    END IF;

    -- 4. Check list existence and non-deletion
    SELECT * INTO v_list
    FROM public.lists
    WHERE id = v_invite.list_id
      AND deleted_at IS NULL;

    IF v_list IS NULL THEN
        RETURN jsonb_build_object(
            'valid', false,
            'error_code', 'LIST_NOT_FOUND',
            'message', 'La lista compartida ya no existe.'
        );
    END IF;

    -- 5. Lock list ID to count members atomically and avoid race conditions
    PERFORM pg_advisory_xact_lock(hashtextextended(v_invite.list_id::text, 0));

    SELECT COUNT(*) INTO v_member_count
    FROM public.list_members
    WHERE list_id = v_invite.list_id;

    IF v_member_count >= 5 THEN
        RETURN jsonb_build_object(
            'valid', false,
            'error_code', 'MEMBER_LIMIT_REACHED',
            'message', 'La lista ya cuenta con el máximo de 5 colaboradores permitidos.',
            'list_name', v_list.name,
            'member_count', v_member_count,
            'max_members', 5
        );
    END IF;

    -- 6. Invite is valid and ready
    RETURN jsonb_build_object(
        'valid', true,
        'list_id', v_invite.list_id,
        'list_name', v_list.name,
        'invite_code', v_invite.invite_code,
        'member_count', v_member_count,
        'max_members', 5,
        'expires_at', v_invite.expires_at
    );
END;
$$;

-- 4. Update join_list_by_token RPC to accept p_invite_code
DROP FUNCTION IF EXISTS public.join_list_by_token(TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.join_list_by_token(
    p_token_hash TEXT DEFAULT NULL,
    p_display_name TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_invite_code TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_invite RECORD;
    v_list RECORD;
    v_member_count INT;
    v_is_already_member BOOLEAN;
    v_items JSONB;
    v_members JSONB;
    v_user_id UUID;
    v_search_code TEXT;
    v_search_hash TEXT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHENTICATED: User must be signed in to join a list';
    END IF;

    v_search_code := UPPER(TRIM(COALESCE(p_invite_code, '')));
    v_search_hash := TRIM(COALESCE(p_token_hash, ''));

    IF v_search_code = '' AND length(v_search_hash) > 0 AND length(v_search_hash) <= 12 THEN
        v_search_code := UPPER(v_search_hash);
    END IF;

    -- 1. Find active invite by code or token hash
    SELECT * INTO v_invite
    FROM public.list_invites
    WHERE (
        (v_search_code <> '' AND invite_code IS NOT NULL AND UPPER(invite_code) = v_search_code)
        OR (v_search_hash <> '' AND token_hash = v_search_hash)
    )
      AND is_active = true
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_invite IS NULL THEN
        RAISE EXCEPTION 'INVALID_INVITE: Invitation link does not exist or was disabled';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.list_members
        WHERE list_id = v_invite.list_id
          AND user_id = v_user_id
    ) INTO v_is_already_member;

    IF NOT v_is_already_member AND v_invite.expires_at <= now() THEN
        RAISE EXCEPTION 'INVITE_EXPIRED: Invitation link has expired';
    END IF;

    PERFORM pg_advisory_xact_lock(hashtextextended(v_invite.list_id::text, 0));

    -- 4. Check 5-member limit if not already a member
    SELECT COUNT(*) INTO v_member_count
    FROM public.list_members
    WHERE list_id = v_invite.list_id;

    IF NOT v_is_already_member AND v_member_count >= 5 THEN
        RAISE EXCEPTION 'LIST_MEMBER_LIMIT_REACHED: This list already has the maximum of 5 active members';
    END IF;

    -- 5. Add user to list_members if not already present
    IF NOT v_is_already_member THEN
        INSERT INTO public.list_members (
            list_id,
            user_id,
            role,
            display_name,
            email
        ) VALUES (
            v_invite.list_id,
            v_user_id,
            'member',
            COALESCE(p_display_name, 'Colaborador'),
            p_email
        );
    END IF;

    -- 6. Fetch full list data for initial SQLite sync
    SELECT * INTO v_list
    FROM public.lists
    WHERE id = v_invite.list_id;

    SELECT COALESCE(jsonb_agg(to_jsonb(i)), '[]'::jsonb) INTO v_items
    FROM public.list_items i
    WHERE i.list_id = v_invite.list_id AND i.deleted_at IS NULL;

    SELECT COALESCE(jsonb_agg(to_jsonb(m)), '[]'::jsonb) INTO v_members
    FROM public.list_members m
    WHERE m.list_id = v_invite.list_id;

    RETURN jsonb_build_object(
        'success', true,
        'list', to_jsonb(v_list),
        'items', v_items,
        'members', v_members,
        'already_member', v_is_already_member
    );
END;
$$;

-- 5. Grant permissions
REVOKE ALL ON FUNCTION public.create_list_invite(UUID, TEXT, TIMESTAMPTZ, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.validate_list_invite(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.join_list_by_token(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_list_invite(UUID, TEXT, TIMESTAMPTZ, TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.validate_list_invite(TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.join_list_by_token(TEXT, TEXT, TEXT, TEXT) TO authenticated, service_role;
