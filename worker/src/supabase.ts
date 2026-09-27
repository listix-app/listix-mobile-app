import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { Database, Env, InviteValidationResult } from './types.ts';
import { hashToken, maskToken } from './security.ts';

export async function validateInviteToken(
  token: string,
  env: Env,
): Promise<InviteValidationResult> {
  const supabaseUrl = env.SUPABASE_URL?.trim();
  const serviceRoleKey = env.SUPABASE_SERVICE_ROLE_KEY?.trim();

  if (!supabaseUrl || !serviceRoleKey) {
    console.error('Supabase credentials missing in environment secrets.');
    return {
      valid: false,
      errorCode: 'MISSING_CONFIGURATION',
      message: 'El servidor no está configurado correctamente para validar invitaciones.',
    };
  }

  const tokenHash = await hashToken(token);

  try {
    const supabase = createClient<Database>(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: rpcData, error: rpcError } = await supabase.rpc(
      'validate_list_invite',
      { p_token_hash: tokenHash },
    );

    if (!rpcError && rpcData) {
      const res = rpcData as Record<string, unknown>;
      return {
        valid: Boolean(res.valid),
        errorCode: (res.error_code as any) || undefined,
        message: (res.message as string) || undefined,
        listId: (res.list_id as string) || undefined,
        listName: (res.list_name as string) || undefined,
        memberCount: typeof res.member_count === 'number' ? res.member_count : undefined,
        maxMembers: typeof res.max_members === 'number' ? res.max_members : 5,
        expiresAt: (res.expires_at as string) || undefined,
      };
    }

    if (rpcError) {
      console.warn(
        `RPC validate_list_invite failed for token ${maskToken(token)}, falling back to queries: ${rpcError.message}`,
      );
    }

    return await fallbackValidateInvite(supabase, tokenHash);
  } catch (err: unknown) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error(`Error validating token ${maskToken(token)}: ${errorMsg}`);
    return {
      valid: false,
      errorCode: 'SERVER_ERROR',
      message: 'Ocurrió un error inesperado al procesar la invitación.',
    };
  }
}

async function fallbackValidateInvite(
  supabase: SupabaseClient<Database>,
  tokenHash: string,
): Promise<InviteValidationResult> {
  const { data: invite, error: inviteError } = await supabase
    .from('list_invites')
    .select('id, list_id, expires_at, is_active')
    .eq('token_hash', tokenHash)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (inviteError || !invite) {
    return {
      valid: false,
      errorCode: 'INVITE_NOT_FOUND',
      message: 'El enlace de invitación no existe o es inválido.',
    };
  }

  if (!invite.is_active) {
    return {
      valid: false,
      errorCode: 'INVITE_REVOKED',
      message: 'Este enlace de invitación ha sido desactivado o revocado.',
    };
  }

  const expiresAt = new Date(invite.expires_at);
  if (expiresAt.getTime() <= Date.now()) {
    return {
      valid: false,
      errorCode: 'INVITE_EXPIRED',
      message: 'El enlace de invitación ha caducado.',
    };
  }

  const { data: list, error: listError } = await supabase
    .from('lists')
    .select('id, name, deleted_at')
    .eq('id', invite.list_id)
    .is('deleted_at', null)
    .maybeSingle();

  if (listError || !list) {
    return {
      valid: false,
      errorCode: 'LIST_NOT_FOUND',
      message: 'La lista compartida ya no existe.',
    };
  }

  const { count, error: countError } = await supabase
    .from('list_members')
    .select('*', { count: 'exact', head: true })
    .eq('list_id', invite.list_id);

  const memberCount = count ?? 0;

  if (!countError && memberCount >= 5) {
    return {
      valid: false,
      errorCode: 'MEMBER_LIMIT_REACHED',
      message: 'La lista ya cuenta con el máximo de 5 colaboradores permitidos.',
      listName: list.name,
      memberCount,
      maxMembers: 5,
    };
  }

  return {
    valid: true,
    listId: invite.list_id,
    listName: list.name,
    memberCount,
    maxMembers: 5,
    expiresAt: invite.expires_at,
  };
}
