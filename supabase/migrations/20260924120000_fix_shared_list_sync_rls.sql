CREATE OR REPLACE FUNCTION public.sync_shared_list(
    p_list_id UUID,
    p_name TEXT,
    p_is_starred BOOLEAN DEFAULT NULL,
    p_position INTEGER DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_list_exists BOOLEAN;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'AUTHENTICATION_REQUIRED';
    END IF;

    PERFORM pg_advisory_xact_lock(hashtextextended(p_list_id::text, 0));

    SELECT EXISTS (
        SELECT 1
        FROM public.lists
        WHERE id = p_list_id
    ) INTO v_list_exists;

    IF v_list_exists THEN
        IF NOT EXISTS (
            SELECT 1
            FROM public.list_members
            WHERE list_id = p_list_id
              AND user_id = v_user_id
        ) THEN
            RAISE EXCEPTION 'LIST_ACCESS_DENIED';
        END IF;

        UPDATE public.lists
        SET name = p_name,
            is_starred = COALESCE(p_is_starred, is_starred),
            position = COALESCE(p_position, position)
        WHERE id = p_list_id;
    ELSE
        INSERT INTO public.lists (id, name, created_by, is_starred, position)
        VALUES (
            p_list_id,
            p_name,
            v_user_id,
            COALESCE(p_is_starred, false),
            COALESCE(p_position, 0)
        );
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_shared_list(UUID, TEXT, BOOLEAN, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sync_shared_list(UUID, TEXT, BOOLEAN, INTEGER) TO authenticated;
