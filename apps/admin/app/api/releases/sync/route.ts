import { NextRequest, NextResponse } from 'next/server';
import { syncReleasesFromGitHub } from '@/lib/releases-store';
import { logAdminAction } from '@/lib/audit-logger';

export async function POST(req: NextRequest) {
  try {
    const releases = await syncReleasesFromGitHub();

    await logAdminAction({
      actorEmail: 'super_admin@myday.app',
      action: 'RELEASES_SYNCED_GITHUB',
      targetType: 'GitHubRepository',
      targetId: 'VTN02/My-Day',
      outcome: 'success',
      metadata: { count: releases.length },
    });

    return NextResponse.json({
      success: true,
      message: `Successfully synchronized ${releases.length} releases from GitHub.`,
      releases,
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: err?.message || 'Failed to sync with GitHub Releases' },
      { status: 500 }
    );
  }
}
