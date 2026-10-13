import { NextRequest, NextResponse } from 'next/server';
import { createServerSupabaseClient, createAdminServiceClient, isSupabaseConfigured } from '@/lib/supabase-server';
import { logAdminAction } from '@/lib/audit-logger';

export async function POST(req: NextRequest) {
  try {
    const { email, password } = await req.json();

    if (!email || !password) {
      return NextResponse.json(
        { error: 'Email and password are required.' },
        { status: 400 }
      );
    }

    if (!isSupabaseConfigured()) {
      return NextResponse.json(
        {
          error: 'Authentication service is not configured. Please configure Supabase environment variables.',
          status: 'not_configured',
        },
        { status: 503 }
      );
    }

    const supabase = createServerSupabaseClient();
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (authError || !authData.user) {
      await logAdminAction({
        actorEmail: email,
        action: 'ADMIN_LOGIN_FAILED',
        targetType: 'SuperAdminSession',
        targetId: 'auth_attempt',
        ipAddress: req.headers.get('x-forwarded-for') || '127.0.0.1',
        userAgent: req.headers.get('user-agent') || 'unknown',
        outcome: 'failure',
        metadata: { reason: authError?.message || 'Invalid credentials' },
      });

      return NextResponse.json(
        { error: authError?.message || 'Invalid administrative credentials.' },
        { status: 401 }
      );
    }

    // Role verification: user must have 'super_admin' or 'admin' role in admin_user_roles
    const adminClient = createAdminServiceClient();
    const { data: roleData, error: roleError } = await adminClient
      .from('admin_user_roles')
      .select('role, is_active')
      .eq('user_id', authData.user.id)
      .single();

    if (roleError || !roleData || !roleData.is_active) {
      await supabase.auth.signOut();
      await logAdminAction({
        actorId: authData.user.id,
        actorEmail: email,
        action: 'ADMIN_LOGIN_FORBIDDEN',
        targetType: 'SuperAdminSession',
        targetId: authData.user.id,
        ipAddress: req.headers.get('x-forwarded-for') || '127.0.0.1',
        userAgent: req.headers.get('user-agent') || 'unknown',
        outcome: 'failure',
        metadata: { reason: 'Account lacks administrative role privileges.' },
      });

      return NextResponse.json(
        { error: 'Access denied: this account does not possess Super Admin permissions.' },
        { status: 403 }
      );
    }

    // Record successful login audit log
    await logAdminAction({
      actorId: authData.user.id,
      actorEmail: email,
      action: 'ADMIN_LOGIN_SUCCESS',
      targetType: 'SuperAdminSession',
      targetId: authData.user.id,
      ipAddress: req.headers.get('x-forwarded-for') || '127.0.0.1',
      userAgent: req.headers.get('user-agent') || 'unknown',
      outcome: 'success',
      metadata: { role: roleData.role },
    });

    return NextResponse.json({
      success: true,
      user: {
        id: authData.user.id,
        email: authData.user.email,
        role: roleData.role,
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: err?.message || 'An unexpected error occurred during sign in.' },
      { status: 500 }
    );
  }
}
