-- Migration: 20260927000000_add_invite_validation_rpc.sql
-- Description: RPC function for validating list invites atomically with concurrency locking and 5-member limit check.

CREATE OR REPLACE FUNCTION public.validate_list_invite(
    p_token_hash TEXT
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
BEGIN
    IF p_token_hash IS NULL OR length(trim(p_token_hash)) = 0 THEN
        RETURN jsonb_build_object(
            'valid', false,
            'error_code', 'INVALID_TOKEN_FORMAT',
            'message', 'El formato del token de invitación es inválido.'
        );
    END IF;

    -- 1. Find invite by token hash
    SELECT * INTO v_invite
    FROM public.list_invites
    WHERE token_hash = p_token_hash
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
        'member_count', v_member_count,
        'max_members', 5,
        'expires_at', v_invite.expires_at
    );
END;
$$;

REVOKE ALL ON FUNCTION public.validate_list_invite(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.validate_list_invite(TEXT) TO anon, authenticated, service_role;
