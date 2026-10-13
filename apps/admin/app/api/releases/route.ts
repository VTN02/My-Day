import { NextRequest, NextResponse } from 'next/server';
import { fetchAllReleases, addReleaseRecord } from '@/lib/releases-store';
import { logAdminAction } from '@/lib/audit-logger';

export async function GET(req: NextRequest) {
  try {
    const releases = await fetchAllReleases();
    return NextResponse.json({
      status: 'configured',
      releases,
    });
  } catch (err: any) {
    return NextResponse.json(
      { status: 'unavailable', error: err?.message, releases: [] },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      versionName,
      versionCode,
      channel = 'stable',
      releaseNotes = [],
      isMandatory = false,
      fileSizeBytes = 0,
      checksumSha256 = '',
      downloadUrl = '',
      actorEmail = 'super_admin@myday.app',
    } = body;

    if (!versionName || !versionCode) {
      return NextResponse.json(
        { error: 'versionName and versionCode are required.' },
        { status: 400 }
      );
    }

    const newRelease = await addReleaseRecord({
      versionName,
      versionCode: parseInt(versionCode, 10),
      channel,
      releaseNotes: Array.isArray(releaseNotes) ? releaseNotes : [releaseNotes],
      isMandatory: Boolean(isMandatory),
      fileSizeBytes,
      checksumSha256,
      downloadUrl,
    });

    await logAdminAction({
      actorEmail,
      action: 'RELEASE_DRAFT_CREATED',
      targetType: 'AppRelease',
      targetId: newRelease.id,
      outcome: 'success',
      metadata: { versionName, versionCode },
    });

    return NextResponse.json({ success: true, release: newRelease });
  } catch (err: any) {
    return NextResponse.json(
      { error: err?.message || 'Failed to create release draft.' },
      { status: 500 }
    );
  }
}
