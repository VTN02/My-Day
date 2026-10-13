import { NextRequest, NextResponse } from 'next/server';
import { createAdminServiceClient, isSupabaseConfigured } from '@/lib/supabase-server';

export async function GET(req: NextRequest) {
  if (!isSupabaseConfigured()) {
    return NextResponse.json({
      status: 'not_configured',
      message: 'Supabase authentication service is not configured.',
      users: [],
      total: 0,
    });
  }

  try {
    const supabase = createAdminServiceClient();
    const searchParams = req.nextUrl.searchParams;
    const query = searchParams.get('q')?.toLowerCase() || '';
    const statusFilter = searchParams.get('status') || 'all';
    const page = parseInt(searchParams.get('page') || '1', 10);
    const perPage = parseInt(searchParams.get('perPage') || '20', 10);

    // 1. Fetch real registered users via Supabase Admin API
    const { data: usersData, error: usersError } = await supabase.auth.admin.listUsers({
      page,
      perPage: 200, // Fetch up to 200 for filtering
    });

    if (usersError) {
      return NextResponse.json(
        { status: 'unavailable', error: usersError.message, users: [], total: 0 },
        { status: 500 }
      );
    }

    // 2. Fetch operational status overrides from admin_user_management
    const { data: statusRecords } = await supabase
      .from('admin_user_management')
      .select('user_id, status, suspension_reason, suspended_at');

    const statusMap = new Map<string, { status: string; reason?: string; suspendedAt?: string }>();
    if (statusRecords) {
      statusRecords.forEach((r) => {
        statusMap.set(r.user_id, {
          status: r.status,
          reason: r.suspension_reason,
          suspendedAt: r.suspended_at,
        });
      });
    }

    // 3. Transform and map strictly non-sensitive fields
    let mappedUsers = (usersData.users || []).map((u) => {
      const override = statusMap.get(u.id);
      return {
        id: u.id,
        email: u.email || 'No email registered',
        displayName: (u.user_metadata?.full_name as string) || (u.user_metadata?.name as string) || 'Anonymous User',
        createdAt: u.created_at,
        lastSignIn: u.last_sign_in_at || 'Never signed in',
        status: (override?.status || 'active') as 'active' | 'suspended',
        provider: u.app_metadata?.provider || 'email',
        suspensionReason: override?.reason || null,
      };
    });

    // 4. Apply search query
    if (query) {
      mappedUsers = mappedUsers.filter(
        (u) =>
          u.email.toLowerCase().includes(query) ||
          u.displayName.toLowerCase().includes(query) ||
          u.id.toLowerCase().includes(query)
      );
    }

    // 5. Apply status filter
    if (statusFilter !== 'all') {
      mappedUsers = mappedUsers.filter((u) => u.status === statusFilter);
    }

    const total = mappedUsers.length;
    const paginatedUsers = mappedUsers.slice((page - 1) * perPage, page * perPage);

    return NextResponse.json({
      status: 'configured',
      users: paginatedUsers,
      total,
      page,
      perPage,
    });
  } catch (err: any) {
    return NextResponse.json(
      { status: 'unavailable', error: err?.message, users: [], total: 0 },
      { status: 500 }
    );
  }
}
