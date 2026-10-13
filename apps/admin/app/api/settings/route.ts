import { NextRequest, NextResponse } from 'next/server';
import { createAdminServiceClient, isSupabaseConfigured } from '@/lib/supabase-server';
import { logAdminAction } from '@/lib/audit-logger';

export async function GET(req: NextRequest) {
  if (!isSupabaseConfigured()) {
    return NextResponse.json({
      status: 'not_configured',
      message: 'Settings storage is not configured.',
      settings: null,
    });
  }

  try {
    const supabase = createAdminServiceClient();
    const { data: rows, error } = await supabase.from('platform_settings').select('*');

    if (error) {
      return NextResponse.json(
        { status: 'unavailable', error: error.message, settings: null },
        { status: 500 }
      );
    }

    const settingsMap: Record<string, any> = {};
    (rows || []).forEach((r) => {
      settingsMap[r.key] = r.value;
    });

    return NextResponse.json({
      status: 'configured',
      settings: {
        minVersionCode: settingsMap.min_supported_version_code ?? '4',
        recommendedVersion: settingsMap.recommended_version ?? '1.1.1',
        updateAdvisory:
          settingsMap.update_advisory ??
          'Please upgrade to the latest MyDay release to ensure data integrity and full feature access.',
        isMaintenanceEnabled: Boolean(settingsMap.maintenance_mode_enabled ?? false),
        maintenanceMessage:
          settingsMap.maintenance_notice ??
          'MyDay platform is currently performing scheduled infrastructure maintenance.',
        whatsappUrl:
          settingsMap.whatsapp_community_url ??
          'https://whatsapp.com/channel/0029VbC9tOXGU3BRlJoxya3h',
        websiteUrl: settingsMap.website_url ?? 'https://myday.app',
        supportUrl:
          settingsMap.support_url ?? 'https://github.com/VTN02/My-Day/issues',
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { status: 'unavailable', error: err?.message, settings: null },
      { status: 500 }
    );
  }
}

export async function PUT(req: NextRequest) {
  if (!isSupabaseConfigured()) {
    return NextResponse.json(
      { error: 'Settings storage is not configured.' },
      { status: 503 }
    );
  }

  try {
    const body = await req.json();
    const {
      minVersionCode,
      recommendedVersion,
      updateAdvisory,
      isMaintenanceEnabled,
      maintenanceMessage,
      whatsappUrl,
      websiteUrl,
      supportUrl,
      actorEmail = 'super_admin@myday.app',
    } = body;

    const supabase = createAdminServiceClient();

    const updates = [
      {
        key: 'min_supported_version_code',
        value: minVersionCode,
        updated_by: actorEmail,
        updated_at: new Date().toISOString(),
      },
      {
        key: 'recommended_version',
        value: recommendedVersion,
        updated_by: actorEmail,
        updated_at: new Date().toISOString(),
      },
      {
        key: 'update_advisory',
        value: updateAdvisory,
        updated_by: actorEmail,
        updated_at: new Date().toISOString(),
      },
      {
        key: 'maintenance_mode_enabled',
        value: Boolean(isMaintenanceEnabled),
        updated_by: actorEmail,
        updated_at: new Date().toISOString(),
      },
      {
        key: 'maintenance_notice',
        value: maintenanceMessage,
        updated_by: actorEmail,
        updated_at: new Date().toISOString(),
      },
      {
        key: 'whatsapp_community_url',
        value: whatsappUrl,
        updated_by: actorEmail,
        updated_at: new Date().toISOString(),
      },
      {
        key: 'website_url',
        value: websiteUrl,
        updated_by: actorEmail,
        updated_at: new Date().toISOString(),
      },
      {
        key: 'support_url',
        value: supportUrl,
        updated_by: actorEmail,
        updated_at: new Date().toISOString(),
      },
    ];

    const { error } = await supabase.from('platform_settings').upsert(updates);
    if (error) throw error;

    await logAdminAction({
      actorEmail,
      action: 'PLATFORM_CONFIG_UPDATED',
      targetType: 'PlatformSettings',
      targetId: 'global_config',
      ipAddress: req.headers.get('x-forwarded-for') || '127.0.0.1',
      outcome: 'success',
      metadata: { minVersionCode, recommendedVersion, isMaintenanceEnabled },
    });

    return NextResponse.json({ success: true, message: 'Platform settings saved successfully.' });
  } catch (err: any) {
    return NextResponse.json(
      { error: err?.message || 'Failed to persist platform settings.' },
      { status: 500 }
    );
  }
}
