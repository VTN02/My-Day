import { NextRequest, NextResponse } from 'next/server';
import { createAdminServiceClient, isSupabaseConfigured } from '@/lib/supabase-server';

export async function GET(req: NextRequest) {
  if (!isSupabaseConfigured()) {
    return NextResponse.json({
      status: 'not_configured',
      message: 'Audit logging service is not configured.',
      logs: [],
      total: 0,
    });
  }

  try {
    const supabase = createAdminServiceClient();
    const searchParams = req.nextUrl.searchParams;
    const search = searchParams.get('q')?.toLowerCase() || '';
    const format = searchParams.get('format');
    const limit = parseInt(searchParams.get('limit') || '50', 10);

    let query = supabase
      .from('admin_audit_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit);

    const { data: logs, error } = await query;

    if (error) {
      return NextResponse.json(
        { status: 'unavailable', error: error.message, logs: [], total: 0 },
        { status: 500 }
      );
    }

    let filtered = logs || [];
    if (search) {
      filtered = filtered.filter(
        (l) =>
          l.actor_email.toLowerCase().includes(search) ||
          l.action.toLowerCase().includes(search) ||
          l.target_type.toLowerCase().includes(search) ||
          l.id.toLowerCase().includes(search)
      );
    }

    // CSV Export option
    if (format === 'csv') {
      const header = 'ID,Timestamp,Actor,Action,Target Type,Target ID,Outcome,IP Address\n';
      const rows = filtered
        .map(
          (l) =>
            `"${l.id}","${l.created_at}","${l.actor_email}","${l.action}","${l.target_type}","${l.target_id}","${l.outcome}","${l.ip_address}"`
        )
        .join('\n');
      return new NextResponse(header + rows, {
        headers: {
          'Content-Type': 'text/csv',
          'Content-Disposition': `attachment; filename="myday_audit_logs_${new Date().toISOString().split('T')[0]}.csv"`,
        },
      });
    }

    const formattedLogs = filtered.map((l) => ({
      id: l.id,
      actorEmail: l.actor_email,
      action: l.action,
      targetType: l.target_type,
      targetId: l.target_id,
      timestamp: new Date(l.created_at).toLocaleString(),
      result: l.outcome as 'success' | 'failure',
      ipAddress: l.ip_address || 'unknown',
      metadata: l.metadata || {},
    }));

    return NextResponse.json({
      status: 'configured',
      logs: formattedLogs,
      total: formattedLogs.length,
    });
  } catch (err: any) {
    return NextResponse.json(
      { status: 'unavailable', error: err?.message, logs: [], total: 0 },
      { status: 500 }
    );
  }
}
