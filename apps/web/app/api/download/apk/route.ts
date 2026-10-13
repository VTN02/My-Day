import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export async function GET(req: NextRequest) {
  try {
    // Read version.json from root
    const versionFilePath = path.resolve(process.cwd(), '..', '..', 'version.json');
    let downloadUrl = 'https://github.com/VTN02/My-Day/releases/download/v1.1.1/myday-v1.1.1.apk';

    if (fs.existsSync(versionFilePath)) {
      try {
        const raw = fs.readFileSync(versionFilePath, 'utf8');
        const data = JSON.parse(raw);
        if (data.apk_download_url) {
          downloadUrl = data.apk_download_url;
        }
      } catch (e) {
        // Fallback to default
      }
    }

    // Try sending telemetry to admin ingestion endpoint asynchronously
    try {
      const adminUrl = process.env.ADMIN_URL || 'http://localhost:3000';
      fetch(`${adminUrl}/api/analytics/collect`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify([
          {
            eventId: `web_click_${Date.now()}_${Math.random().toString(36).substring(7)}`,
            eventType: 'download_button_click',
            clientType: 'web',
            deviceCategory: 'mobile',
            timestamp: new Date().toISOString(),
          },
          {
            eventId: `web_confirm_${Date.now()}_${Math.random().toString(36).substring(7)}`,
            eventType: 'download_confirmed',
            clientType: 'web',
            appVersion: '1.1.1',
            versionCode: 4,
            timestamp: new Date().toISOString(),
          },
        ]),
      }).catch(() => {});
    } catch (e) {
      // Non-blocking
    }

    // Redirect to verified APK download URL
    return NextResponse.redirect(downloadUrl, 307);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to resolve APK release download artifact' },
      { status: 500 }
    );
  }
}
