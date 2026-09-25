-- Migration: 20260924000000_create_listix_schema.sql
-- Description: Core schema for Listix collaborative lists, members, items, invites, RLS, and Realtime.

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 1. TABLES
-- ==============================================================================

-- Lists Table
CREATE TABLE IF NOT EXISTS public.lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_starred BOOLEAN NOT NULL DEFAULT false,
    position INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- List Members Table (Max 5 members per list enforced via trigger)
CREATE TABLE IF NOT EXISTS public.list_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    list_id UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    display_name TEXT,
    email TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_list_member UNIQUE (list_id, user_id)
);

-- List Items Table (corresponds to SQLite items)
CREATE TABLE IF NOT EXISTS public.list_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    list_id UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    position INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- List Invites Table (token is hashed, never stored plaintext)
CREATE TABLE IF NOT EXISTS public.list_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    list_id UUID NOT NULL REFERENCES public.lists(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_lists_created_by ON public.lists(created_by);
CREATE INDEX IF NOT EXISTS idx_lists_updated_at ON public.lists(updated_at);
CREATE INDEX IF NOT EXISTS idx_list_members_list_id ON public.list_members(list_id);
CREATE INDEX IF NOT EXISTS idx_list_members_user_id ON public.list_members(user_id);
CREATE INDEX IF NOT EXISTS idx_list_items_list_id ON public.list_items(list_id);
CREATE INDEX IF NOT EXISTS idx_list_items_updated_at ON public.list_items(updated_at);
CREATE INDEX IF NOT EXISTS idx_list_invites_list_id ON public.list_invites(list_id);
CREATE INDEX IF NOT EXISTS idx_list_invites_token_hash ON public.list_invites(token_hash);

-- ==============================================================================
-- 2. ENFORCE MAX 5 MEMBERS PER LIST
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.check_list_members_limit()
RETURNS TRIGGER AS $$
DECLARE
    current_count INT;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtextextended(NEW.list_id::text, 0));

    SELECT COUNT(*) INTO current_count
    FROM public.list_members
    WHERE list_id = NEW.list_id;

    IF current_count >= 5 THEN
        RAISE EXCEPTION 'LIST_MEMBER_LIMIT_REACHED: Maximum 5 active members per list allowed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_check_list_members_limit ON public.list_members;
CREATE TRIGGER trigger_check_list_members_limit
BEFORE INSERT ON public.list_members
FOR EACH ROW
EXECUTE FUNCTION public.check_list_members_limit();

-- ==============================================================================
-- 3. AUTO-ADD LIST CREATOR AS OWNER
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_list_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO public.list_members (list_id, user_id, role, display_name)
    VALUES (NEW.id, NEW.created_by, 'owner', 'Owner')
    ON CONFLICT (list_id, user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_on_list_created ON public.lists;
CREATE TRIGGER trigger_on_list_created
AFTER INSERT ON public.lists
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_list_owner();

-- Automatic updated_at trigger helper
CREATE OR REPLACE FUNCTION public.update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_lists_updated_at ON public.lists;
CREATE TRIGGER trigger_lists_updated_at
BEFORE UPDATE ON public.lists
FOR EACH ROW
EXECUTE FUNCTION public.update_timestamp();

DROP TRIGGER IF EXISTS trigger_list_items_updated_at ON public.list_items;
CREATE TRIGGER trigger_list_items_updated_at
BEFORE UPDATE ON public.list_items
FOR EACH ROW
EXECUTE FUNCTION public.update_timestamp();

-- ==============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ==============================================================================

-- Helper function to check if current user is an active member of list
CREATE OR REPLACE FUNCTION public.is_list_member(p_list_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.list_members
        WHERE list_id = p_list_id
          AND user_id = auth.uid()
    );
$$;

-- Enable RLS
ALTER TABLE public.lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.list_invites ENABLE ROW LEVEL SECURITY;

-- Lists Policies
CREATE POLICY "Members can select their lists"
    ON public.lists FOR SELECT
    USING (public.is_list_member(id));

CREATE POLICY "Authenticated users can create owned lists"
    ON public.lists FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL AND created_by = auth.uid());

CREATE POLICY "Members can update their lists"
    ON public.lists FOR UPDATE
    USING (public.is_list_member(id));

CREATE POLICY "List admins and owners can delete lists"
    ON public.lists FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.list_members
            WHERE list_id = public.lists.id
              AND user_id = auth.uid()
              AND role IN ('owner', 'admin')
        )
    );

-- List Members Policies
CREATE POLICY "Members can view other members in same list"
    ON public.list_members FOR SELECT
    USING (public.is_list_member(list_id));

CREATE POLICY "Owners and admins can manage members"
    ON public.list_members FOR INSERT
    WITH CHECK (false);

CREATE POLICY "Owners and admins can update member roles"
    ON public.list_members FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.list_members
            WHERE list_id = public.list_members.list_id
              AND user_id = auth.uid()
              AND role IN ('owner', 'admin')
        )
    );

CREATE POLICY "Users can leave list or owners can remove members"
    ON public.list_members FOR DELETE
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.list_members
            WHERE list_id = public.list_members.list_id
              AND user_id = auth.uid()
              AND role IN ('owner', 'admin')
        )
    );

-- List Items Policies
CREATE POLICY "Members can view items"
    ON public.list_items FOR SELECT
    USING (public.is_list_member(list_id));

CREATE POLICY "Members can insert items"
    ON public.list_items FOR INSERT
    WITH CHECK (public.is_list_member(list_id));

CREATE POLICY "Members can update items"
    ON public.list_items FOR UPDATE
    USING (public.is_list_member(list_id));

CREATE POLICY "Members can delete items"
    ON public.list_items FOR DELETE
    USING (public.is_list_member(list_id));

-- List Invites Policies
-- ==============================================================================
-- 5. RPC PROCEDURES (Share & Join Logic)
-- ==============================================================================

-- Create secure invitation RPC
CREATE OR REPLACE FUNCTION public.create_list_invite(
    p_list_id UUID,
    p_token_hash TEXT,
    p_expires_at TIMESTAMPTZ
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_invite RECORD;
BEGIN
    -- Validate caller is member
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

    -- Insert new invite
    INSERT INTO public.list_invites (
        list_id,
        token_hash,
        created_by,
        expires_at,
        is_active
    ) VALUES (
        p_list_id,
        p_token_hash,
        auth.uid(),
        p_expires_at,
        true
    )
    RETURNING id, list_id, expires_at, created_at, is_active INTO v_invite;

    RETURN jsonb_build_object(
        'success', true,
        'invite_id', v_invite.id,
        'list_id', v_invite.list_id,
        'expires_at', v_invite.expires_at,
        'created_at', v_invite.created_at
    );
END;
$$;

-- Join list by invite token RPC
CREATE OR REPLACE FUNCTION public.join_list_by_token(
    p_token_hash TEXT,
    p_display_name TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL
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
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'UNAUTHENTICATED: User must be signed in to join a list';
    END IF;

    -- 1. Find active invite by token hash
    SELECT * INTO v_invite
    FROM public.list_invites
    WHERE token_hash = p_token_hash
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

REVOKE ALL ON FUNCTION public.create_list_invite(UUID, TEXT, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.join_list_by_token(TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_list_invite(UUID, TEXT, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_list_by_token(TEXT, TEXT, TEXT) TO authenticated;

-- ==============================================================================
-- 6. REALTIME REPLICATION CONFIGURATION
-- ==============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'lists'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.lists;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'list_items'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.list_items;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'list_members'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.list_members;
    END IF;
END $$;

ALTER TABLE public.lists REPLICA IDENTITY FULL;
ALTER TABLE public.list_items REPLICA IDENTITY FULL;
ALTER TABLE public.list_members REPLICA IDENTITY FULL;
