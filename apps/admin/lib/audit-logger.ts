import { createAdminServiceClient, isSupabaseConfigured } from './supabase-server';

export interface AuditLogPayload {
  actorId?: string;
  actorEmail: string;
  action: string;
  targetType: string;
  targetId: string;
  ipAddress?: string;
  userAgent?: string;
  outcome: 'success' | 'failure';
  metadata?: Record<string, any>;
}

export async function logAdminAction(payload: AuditLogPayload): Promise<boolean> {
  if (!isSupabaseConfigured()) {
    console.warn('[AuditLog] Supabase not configured. Skipping persistent audit entry:', payload.action);
    return false;
  }

  try {
    const supabase = createAdminServiceClient();
    const { error } = await supabase.from('admin_audit_logs').insert([
      {
        actor_id: payload.actorId || null,
        actor_email: payload.actorEmail,
        action: payload.action,
        target_type: payload.targetType,
        target_id: payload.targetId,
        ip_address: payload.ipAddress || 'unknown',
        user_agent: payload.userAgent || 'unknown',
        outcome: payload.outcome,
        metadata: payload.metadata || {},
      },
    ]);

    if (error) {
      console.error('[AuditLog] Failed to persist audit record:', error.message);
      return false;
    }
    return true;
  } catch (err: any) {
    console.error('[AuditLog] Unexpected error logging admin action:', err);
    return false;
  }
}
