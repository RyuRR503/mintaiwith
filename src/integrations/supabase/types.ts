export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      behavior_flags: {
        Row: {
          action: string
          created_at: string
          device_id: string
          id: number
          reasons: string[]
          score: number
          wallet: string | null
        }
        Insert: {
          action: string
          created_at?: string
          device_id: string
          id?: never
          reasons?: string[]
          score: number
          wallet?: string | null
        }
        Update: {
          action?: string
          created_at?: string
          device_id?: string
          id?: never
          reasons?: string[]
          score?: number
          wallet?: string | null
        }
        Relationships: []
      }
      catches: {
        Row: {
          accuracy: number
          amount: number
          amount_wei: string | null
          city: string
          created_at: string
          deadline: number | null
          device_id: string | null
          id: string
          lat: number
          lng: number
          mode: string
          nonce: string | null
          place: string
          settled_at: string | null
          signature: string | null
          spawn_id: string
          symbol: string
          token_address: string | null
          tx_hash: string | null
          wallet: string
        }
        Insert: {
          accuracy: number
          amount: number
          amount_wei?: string | null
          city: string
          created_at?: string
          deadline?: number | null
          device_id?: string | null
          id?: string
          lat: number
          lng: number
          mode?: string
          nonce?: string | null
          place: string
          settled_at?: string | null
          signature?: string | null
          spawn_id: string
          symbol: string
          token_address?: string | null
          tx_hash?: string | null
          wallet: string
        }
        Update: {
          accuracy?: number
          amount?: number
          amount_wei?: string | null
          city?: string
          created_at?: string
          deadline?: number | null
          device_id?: string | null
          id?: string
          lat?: number
          lng?: number
          mode?: string
          nonce?: string | null
          place?: string
          settled_at?: string | null
          signature?: string | null
          spawn_id?: string
          symbol?: string
          token_address?: string | null
          tx_hash?: string | null
          wallet?: string
        }
        Relationships: []
      }
      claim_codes: {
        Row: {
          accuracy: number
          code: string
          created_at: string
          device_id: string
          expires_at: string
          ip: string | null
          lat: number
          lng: number
          spawn_id: string
          used_at: string | null
          wallet: string | null
        }
        Insert: {
          accuracy: number
          code: string
          created_at?: string
          device_id: string
          expires_at: string
          ip?: string | null
          lat: number
          lng: number
          spawn_id: string
          used_at?: string | null
          wallet?: string | null
        }
        Update: {
          accuracy?: number
          code?: string
          created_at?: string
          device_id?: string
          expires_at?: string
          ip?: string | null
          lat?: number
          lng?: number
          spawn_id?: string
          used_at?: string | null
          wallet?: string | null
        }
        Relationships: []
      }
      display_snapshots: {
        Row: {
          built_at: string
          key: string
          lease_until: string
          payload: Json
        }
        Insert: {
          built_at?: string
          key: string
          lease_until?: string
          payload: Json
        }
        Update: {
          built_at?: string
          key?: string
          lease_until?: string
          payload?: Json
        }
        Relationships: []
      }
      legendary_events: {
        Row: {
          amount: number
          city: string
          code: string
          created_at: string
          duration_min: number
          id: string
          lat: number
          lng: number
          place: string
          radius_m: number
          starts_at: string
          symbol: string
          tx_hash: string | null
          winner_wallet: string | null
        }
        Insert: {
          amount: number
          city: string
          code: string
          created_at?: string
          duration_min?: number
          id?: string
          lat: number
          lng: number
          place: string
          radius_m?: number
          starts_at: string
          symbol: string
          tx_hash?: string | null
          winner_wallet?: string | null
        }
        Update: {
          amount?: number
          city?: string
          code?: string
          created_at?: string
          duration_min?: number
          id?: string
          lat?: number
          lng?: number
          place?: string
          radius_m?: number
          starts_at?: string
          symbol?: string
          tx_hash?: string | null
          winner_wallet?: string | null
        }
        Relationships: []
      }
      places: {
        Row: {
          brand: string
          city: string
          country: string
          created_at: string
          id: string
          lat: number
          lng: number
          name: string
          osm_id: number
          osm_type: string
          symbol: string
        }
        Insert: {
          brand: string
          city: string
          country?: string
          created_at?: string
          id?: string
          lat: number
          lng: number
          name: string
          osm_id: number
          osm_type: string
          symbol: string
        }
        Update: {
          brand?: string
          city?: string
          country?: string
          created_at?: string
          id?: string
          lat?: number
          lng?: number
          name?: string
          osm_id?: number
          osm_type?: string
          symbol?: string
        }
        Relationships: []
      }
      position_log: {
        Row: {
          accuracy: number
          city: string
          created_at: string
          device_id: string | null
          id: string
          lat: number
          lng: number
          wallet: string | null
        }
        Insert: {
          accuracy: number
          city: string
          created_at?: string
          device_id?: string | null
          id?: string
          lat: number
          lng: number
          wallet?: string | null
        }
        Update: {
          accuracy?: number
          city?: string
          created_at?: string
          device_id?: string | null
          id?: string
          lat?: number
          lng?: number
          wallet?: string | null
        }
        Relationships: []
      }
      spawns: {
        Row: {
          amount: number
          catches_count: number
          claimed_at: string | null
          claimed_by: string | null
          cooldown_min: number
          created_at: string
          day: string | null
          expires_at: string | null
          id: string
          place_id: string
          rarity: string
          respawn_at: string | null
          symbol: string
          tx_hash: string | null
        }
        Insert: {
          amount: number
          catches_count?: number
          claimed_at?: string | null
          claimed_by?: string | null
          cooldown_min?: number
          created_at?: string
          day?: string | null
          expires_at?: string | null
          id: string
          place_id: string
          rarity?: string
          respawn_at?: string | null
          symbol: string
          tx_hash?: string | null
        }
        Update: {
          amount?: number
          catches_count?: number
          claimed_at?: string | null
          claimed_by?: string | null
          cooldown_min?: number
          created_at?: string
          day?: string | null
          expires_at?: string | null
          id?: string
          place_id?: string
          rarity?: string
          respawn_at?: string | null
          symbol?: string
          tx_hash?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "spawns_place_id_fkey"
            columns: ["place_id"]
            isOneToOne: false
            referencedRelation: "places"
            referencedColumns: ["id"]
          },
        ]
      }
      test_wallets: {
        Row: {
          created_at: string
          wallet: string
        }
        Insert: {
          created_at?: string
          wallet: string
        }
        Update: {
          created_at?: string
          wallet?: string
        }
        Relationships: []
      }
      waitlist: {
        Row: {
          city: string | null
          company: string | null
          created_at: string
          email: string
          id: string
          kind: string
        }
        Insert: {
          city?: string | null
          company?: string | null
          created_at?: string
          email: string
          id?: string
          kind?: string
        }
        Update: {
          city?: string | null
          company?: string | null
          created_at?: string
          email?: string
          id?: string
          kind?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      claim_display_lease: {
        Args: { _key: string; _lease_seconds: number; _stale_seconds: number }
        Returns: boolean
      }
      schedule_daily_legendary: { Args: never; Returns: undefined }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
