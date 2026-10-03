export interface Env {
  SUPABASE_URL?: string;
  SUPABASE_SERVICE_ROLE_KEY?: string;
  PLAY_STORE_URL?: string;
  INVITE_BASE_URL?: string;
  ANDROID_PACKAGE_NAME?: string;
  ANDROID_SHA256_FINGERPRINT?: string;
  APP_SCHEME?: string;
  SUPPORT_EMAIL?: string;
}

export type InviteErrorCode =
  | 'INVALID_TOKEN_FORMAT'
  | 'INVITE_NOT_FOUND'
  | 'INVITE_REVOKED'
  | 'INVITE_EXPIRED'
  | 'LIST_NOT_FOUND'
  | 'MEMBER_LIMIT_REACHED'
  | 'SERVER_ERROR'
  | 'MISSING_CONFIGURATION';

export interface InviteValidationResult {
  valid: boolean;
  errorCode?: InviteErrorCode;
  message?: string;
  listId?: string;
  listName?: string;
  memberCount?: number;
  maxMembers?: number;
  expiresAt?: string;
}

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      lists: {
        Row: {
          id: string;
          name: string;
          created_by: string;
          is_starred: boolean;
          position: number;
          created_at: string;
          updated_at: string;
          deleted_at: string | null;
        };
        Insert: {
          id?: string;
          name: string;
          created_by: string;
          is_starred?: boolean;
          position?: number;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Update: {
          id?: string;
          name?: string;
          created_by?: string;
          is_starred?: boolean;
          position?: number;
          created_at?: string;
          updated_at?: string;
          deleted_at?: string | null;
        };
        Relationships: [];
      };
      list_members: {
        Row: {
          id: string;
          list_id: string;
          user_id: string;
          role: string;
          display_name: string | null;
          email: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          list_id: string;
          user_id: string;
          role?: string;
          display_name?: string | null;
          email?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          list_id?: string;
          user_id?: string;
          role?: string;
          display_name?: string | null;
          email?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [];
      };
      list_invites: {
        Row: {
          id: string;
          list_id: string;
          token_hash: string;
          invite_code: string | null;
          created_by: string | null;
          expires_at: string;
          is_active: boolean;
          created_at: string;
        };
        Insert: {
          id?: string;
          list_id: string;
          token_hash: string;
          invite_code?: string | null;
          created_by?: string | null;
          expires_at: string;
          is_active?: boolean;
          created_at?: string;
        };
        Update: {
          id?: string;
          list_id?: string;
          token_hash?: string;
          invite_code?: string | null;
          created_by?: string | null;
          expires_at?: string;
          is_active?: boolean;
          created_at?: string;
        };
        Relationships: [];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      validate_list_invite: {
        Args: {
          p_token_hash?: string | null;
          p_invite_code?: string | null;
        };
        Returns: Record<string, unknown>;
      };
    };
    Enums: {
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
}
