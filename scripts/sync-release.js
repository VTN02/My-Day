/**
 * sync-release.js
 * Automatically synchronizes version.json with the latest GitHub release of MyDay.
 * Can be run manually or automatically via GitHub Actions upon any new release.
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const REPO = process.env.REPO || 'VTN02/My-Day';
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const VERSION_FILE = path.resolve(__dirname, '..', 'version.json');

function fetchLatestRelease() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.github.com',
      path: `/repos/${REPO}/releases/latest`,
      headers: {
        'User-Agent': 'MyDay-Release-Sync',
        'Accept': 'application/vnd.github.v3+json',
        ...(GITHUB_TOKEN ? { 'Authorization': `token ${GITHUB_TOKEN}` } : {}),
      },
    };

    https.get(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`Failed to parse release JSON: ${e.message}`));
          }
        } else {
          reject(new Error(`GitHub API returned HTTP ${res.statusCode}: ${data}`));
        }
      });
    }).on('error', reject);
  });
}

function parseReleaseNotes(body) {
  if (!body) return ['Performance improvements, stability fixes, and UI refinements.'];

  const lines = body.split(/\r?\n/);
  const notes = [];

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('• ')) {
      const clean = line.replace(/^[-*•]\s+/, '').replace(/\*\*|\*|__|_/g, '').trim();
      if (clean) notes.push(clean);
    }
  }

  if (notes.length === 0) {
    for (const rawLine of lines) {
      const line = rawLine.trim();
      if (line && !line.startsWith('#') && !line.startsWith('---') && !line.startsWith('```')) {
        const clean = line.replace(/\*\*|\*|__|_/g, '').trim();
        if (clean) {
          notes.push(clean);
          if (notes.length >= 6) break;
        }
      }
    }
  }

  return notes.length > 0
    ? notes
    : ['Performance improvements, stability fixes, and UI refinements.'];
}

async function run() {
  console.log(`Fetching latest release for ${REPO}...`);
  const release = await fetchLatestRelease();

  const tagName = release.tag_name || 'v1.1.1';
  const cleanVersion = tagName.replace(/^[vV]/, '');

  let versionCode = 0;
  if (tagName.includes('+')) {
    versionCode = parseInt(tagName.split('+').pop(), 10) || 0;
  }
  if (!versionCode) {
    const parts = cleanVersion.split('.').map((p) => parseInt(p, 10) || 0);
    versionCode = (parts[0] || 0) * 10000 + (parts[1] || 0) * 100 + (parts[2] || 0);
  }

  const assets = release.assets || [];
  let apkAsset = assets.find((a) => a.name.toLowerCase().endsWith('.apk'));
  const universalAsset = assets.find((a) => a.name.toLowerCase().includes('universal') && a.name.toLowerCase().endsWith('.apk'));
  if (universalAsset) apkAsset = universalAsset;

  const apkUrl = apkAsset ? apkAsset.browser_download_url : (release.html_url || '');

  let fileSize = '72 MB';
  if (apkAsset && apkAsset.size) {
    const mb = Math.round(apkAsset.size / (1024 * 1024));
    fileSize = `${mb} MB`;
  }

  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  let releaseDate = 'October 2026';
  if (release.published_at) {
    const dt = new Date(release.published_at);
    releaseDate = `${months[dt.getMonth()]} ${dt.getFullYear()}`;
  }

  const releaseNotes = parseReleaseNotes(release.body);

  const versionJson = {
    latest_version: cleanVersion,
    version_code: versionCode,
    apk_download_url: apkUrl,
    mirror_url: 'https://whatsapp.com/channel/0029VbC9tOXGU3BRlJoxya3h',
    release_date: releaseDate,
    file_size: fileSize,
    is_mandatory: (release.body || '').toLowerCase().includes('[mandatory]'),
    release_notes: releaseNotes,
  };

  fs.writeFileSync(VERSION_FILE, JSON.stringify(versionJson, null, 2) + '\n', 'utf8');
  console.log(`Successfully synced version.json to ${cleanVersion} (code: ${versionCode})!`);
}

run().catch((err) => {
  console.error('Error syncing release:', err);
  process.exit(1);
});
