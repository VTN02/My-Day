import { NextRequest, NextResponse } from 'next/server';
import { updateReleaseStatus } from '@/lib/releases-store';
import { logAdminAction } from '@/lib/audit-logger';

export async function PATCH(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  const releaseId = params.id;
  const { action, actorEmail } = await req.json();

  if (!action || !['publish', 'withdraw'].includes(action)) {
    return NextResponse.json(
      { error: 'Invalid action. Supported: publish, withdraw' },
      { status: 400 }
    );
  }

  try {
    const adminEmail = actorEmail || 'super_admin@myday.app';
    const updated = await updateReleaseStatus(releaseId, action);

    if (!updated) {
      return NextResponse.json({ error: 'Release not found' }, { status: 404 });
    }

    await logAdminAction({
      actorEmail: adminEmail,
      action: action === 'publish' ? 'RELEASE_PUBLISHED' : 'RELEASE_WITHDRAWN',
      targetType: 'AppRelease',
      targetId: `${updated.versionName} (Code ${updated.versionCode})`,
      outcome: 'success',
      metadata: { releaseId, status: updated.status },
    });

    return NextResponse.json({ success: true, release: updated });
  } catch (err: any) {
    return NextResponse.json(
      { error: err?.message || 'Failed to update release status.' },
      { status: 500 }
    );
  }
}
