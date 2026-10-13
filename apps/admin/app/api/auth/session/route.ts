import { NextRequest, NextResponse } from 'next/server';
import { createServerSupabaseClient, createAdminServiceClient, isSupabaseConfigured } from '@/lib/supabase-server';

export async function GET(req: NextRequest) {
  try {
    if (!isSupabaseConfigured()) {
      return NextResponse.json({
        authenticated: false,
        isConfigured: false,
        message: 'Backend authentication service not configured.',
      });
    }

    const supabase = createServerSupabaseClient();
    const { data: { user }, error: userError } = await supabase.auth.getUser();

    if (userError || !user) {
      return NextResponse.json({
        authenticated: false,
        isConfigured: true,
      });
    }

    const adminClient = createAdminServiceClient();
    const { data: roleData } = await adminClient
      .from('admin_user_roles')
      .select('role, is_active')
      .eq('user_id', user.id)
      .single();

    return NextResponse.json({
      authenticated: true,
      isConfigured: true,
      user: {
        id: user.id,
        email: user.email,
        role: roleData?.role || 'admin',
        lastSignIn: user.last_sign_in_at,
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { authenticated: false, error: err?.message },
      { status: 500 }
    );
  }
}
