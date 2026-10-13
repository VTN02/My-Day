import { NextRequest, NextResponse } from 'next/server';
import { createServerSupabaseClient, isSupabaseConfigured } from '@/lib/supabase-server';
import { logAdminAction } from '@/lib/audit-logger';

export async function POST(req: NextRequest) {
  try {
    if (isSupabaseConfigured()) {
      const supabase = createServerSupabaseClient();
      const { data: { user } } = await supabase.auth.getUser();

      if (user) {
        await logAdminAction({
          actorId: user.id,
          actorEmail: user.email || 'unknown',
          action: 'ADMIN_LOGOUT',
          targetType: 'SuperAdminSession',
          targetId: user.id,
          ipAddress: req.headers.get('x-forwarded-for') || '127.0.0.1',
          userAgent: req.headers.get('user-agent') || 'unknown',
          outcome: 'success',
        });
      }

      await supabase.auth.signOut();
    }

    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json({ success: true }); // Always allow client to clear local session
  }
}
