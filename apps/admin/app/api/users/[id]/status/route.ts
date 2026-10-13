import { NextRequest, NextResponse } from 'next/server';
import { createAdminServiceClient, isSupabaseConfigured } from '@/lib/supabase-server';
import { logAdminAction } from '@/lib/audit-logger';

export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  if (!isSupabaseConfigured()) {
    return NextResponse.json(
      { error: 'Database service is not configured.' },
      { status: 503 }
    );
  }

  const userId = params.id;
  const { action, reason, actorEmail } = await req.json();

  if (!action || !['suspend', 'reactivate', 'delete'].includes(action)) {
    return NextResponse.json(
      { error: 'Invalid action specified. Supported: suspend, reactivate, delete' },
      { status: 400 }
    );
  }

  try {
    const supabase = createAdminServiceClient();
    const adminEmail = actorEmail || 'super_admin@myday.app';

    if (action === 'suspend') {
      const { error } = await supabase
        .from('admin_user_management')
        .upsert({
          user_id: userId,
          status: 'suspended',
          suspension_reason: reason || 'Administrative policy suspension',
          suspended_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        });

      if (error) throw error;

      await logAdminAction({
        actorEmail: adminEmail,
        action: 'USER_SUSPENDED',
        targetType: 'UserAccount',
        targetId: userId,
        ipAddress: req.headers.get('x-forwarded-for') || '127.0.0.1',
        outcome: 'success',
        metadata: { reason },
      });

      return NextResponse.json({ success: true, status: 'suspended' });
    }

    if (action === 'reactivate') {
      const { error } = await supabase
        .from('admin_user_management')
        .upsert({
          user_id: userId,
          status: 'active',
          suspension_reason: null,
          suspended_at: null,
          updated_at: new Date().toISOString(),
        });

      if (error) throw error;

      await logAdminAction({
        actorEmail: adminEmail,
        action: 'USER_REACTIVATED',
        targetType: 'UserAccount',
        targetId: userId,
        ipAddress: req.headers.get('x-forwarded-for') || '127.0.0.1',
        outcome: 'success',
      });

      return NextResponse.json({ success: true, status: 'active' });
    }

    if (action === 'delete') {
      // Schedule controlled deletion in metadata
      const { error: upsertErr } = await supabase
        .from('admin_user_management')
        .upsert({
          user_id: userId,
          status: 'scheduled_deletion',
          deletion_scheduled_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          updated_at: new Date().toISOString(),
        });

      if (upsertErr) throw upsertErr;

      // Delete from Supabase Auth
      const { error: deleteErr } = await supabase.auth.admin.deleteUser(userId);
      if (deleteErr) throw deleteErr;

      await logAdminAction({
        actorEmail: adminEmail,
        action: 'USER_DELETED',
        targetType: 'UserAccount',
        targetId: userId,
        ipAddress: req.headers.get('x-forwarded-for') || '127.0.0.1',
        outcome: 'success',
        metadata: { policy: 'Controlled cryptographic decommission' },
      });

      return NextResponse.json({ success: true, status: 'deleted' });
    }

    return NextResponse.json({ error: 'Unsupported action' }, { status: 400 });
  } catch (err: any) {
    return NextResponse.json(
      { error: err?.message || 'Failed to update user status.' },
      { status: 500 }
    );
  }
}
