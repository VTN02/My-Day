const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

const creds = execSync('git credential fill', {
  input: 'protocol=https\nhost=github.com\n',
  encoding: 'utf8',
});
const match = creds.match(/password=(.+)/);
if (!match) {
  console.error('Could not obtain GitHub token from credential manager');
  process.exit(1);
}
const token = match[1].trim();
const REPO = 'VTN02/My-Day';

function apiRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            resolve(data);
          }
        } else {
          reject(new Error(`API Error ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

function uploadAsset(release, filePath, assetName) {
  const stats = fs.statSync(filePath);
  return new Promise((resolve, reject) => {
    const uploadUrl = new URL(release.upload_url.replace('{?name,label}', ''));
    uploadUrl.searchParams.set('name', assetName);

    const req = https.request(
      {
        hostname: uploadUrl.hostname,
        path: uploadUrl.pathname + uploadUrl.search,
        method: 'POST',
        headers: {
          'User-Agent': 'MyDay-Release-Publisher',
          'Authorization': `token ${token}`,
          'Content-Type': 'application/vnd.android.package-archive',
          'Content-Length': stats.size,
        },
      },
      (res) => {
        let resp = '';
        res.on('data', (c) => (resp += c));
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            console.log(`Asset ${assetName} uploaded successfully!`);
            resolve(JSON.parse(resp));
          } else {
            reject(new Error(`Asset upload failed (${res.statusCode}): ${resp}`));
          }
        });
      }
    );

    req.on('error', reject);

    const fileStream = fs.createReadStream(filePath);
    let uploadedBytes = 0;
    let lastLog = 0;

    fileStream.on('data', (chunk) => {
      uploadedBytes += chunk.length;
      const now = Date.now();
      if (now - lastLog > 2000) {
        lastLog = now;
        const pct = ((uploadedBytes / stats.size) * 100).toFixed(1);
        console.log(`Uploaded ${assetName}: ${pct}% (${(uploadedBytes / (1024 * 1024)).toFixed(1)} MB)...`);
      }
    });

    fileStream.pipe(req);
  });
}

async function createReleaseAndUpload({ tagName, name, body, apkPath, apkName }) {
  console.log(`\n=== Creating Release ${tagName} ===`);
  try {
    execSync(`git push -f origin ${tagName}`, { stdio: 'inherit' });
  } catch (e) {
    console.log('Tag push note:', e.message);
  }

  const releasePayload = JSON.stringify({
    tag_name: tagName,
    name: name,
    body: body,
    draft: false,
    prerelease: false,
  });

  const release = await apiRequest(
    {
      hostname: 'api.github.com',
      path: `/repos/${REPO}/releases`,
      method: 'POST',
      headers: {
        'User-Agent': 'MyDay-Release-Publisher',
        'Authorization': `token ${token}`,
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(releasePayload),
      },
    },
    releasePayload
  );

  console.log(`Created release ${tagName} (ID: ${release.id})`);
  console.log(`Uploading ${apkName}...`);
  await uploadAsset(release, apkPath, apkName);
  console.log(`Finished ${tagName}!`);
}

async function main() {
  const apk120 = path.resolve(__dirname, '..', 'myday-v1.2.0.apk');
  const apk121 = path.resolve(__dirname, '..', 'myday-v1.2.1.apk');

  // 1. Recreate v1.2.0
  await createReleaseAndUpload({
    tagName: 'v1.2.0',
    name: 'MyDay v1.2.0 — Samsung Notes Experience, Calendar & Identity Refresh',
    body: `## What's New in MyDay v1.2.0\r\n\r\n` +
      `### 🎨 Brand Identity Refresh\r\n` +
      `- **Transparent Brand Logo:** Applied the clean, refined human-ribbon logo without background across both the Android mobile app and the Super Admin enterprise console.\r\n` +
      `- **Enhanced UI Aesthetics:** Polished header branding and avatar styling to present a cohesive look.\r\n\r\n` +
      `### 📝 MyDay Notes (Samsung Notes–Inspired Experience)\r\n` +
      `- **Multi-Modal Note Editor:** Write, sketch, format rich text, insert checklists, and organize notes.\r\n` +
      `- **Vector Canvas Drawing:** Smooth sketching and handwritten notes with customizable pen width and color palettes.\r\n` +
      `- **Flexible Attachments:** Full support for embedding and opening images, documents, and external links directly inside notes.\r\n` +
      `- **Folder Organization & Trash Bin:** Organize notes into hierarchical folders with safe 30-day soft deletion and restore capabilities.\r\n\r\n` +
      `### 🔔 Smart Reminder Escalation\r\n` +
      `- **Escalating Alerts:** Configure repetitive reminder escalation intervals (every 2m, 5m, 10m, 15m) for critical tasks so you never miss a deadline.\r\n` +
      `- **Customizable Reminder Tunes:** Manage and select from genuine audio tune catalogs configured through the Super Admin Portal.\r\n\r\n` +
      `### 📅 Calendar Integration\r\n` +
      `- **Unified Task & Schedule View:** Integrated calendar with task distribution indicators and dot markers.\r\n` +
      `- **Day & Month Navigation:** Quickly inspect deadlines, reminders, and daily habits directly from the calendar interface.\r\n\r\n` +
      `### 📄 In-App Document Viewer & Android Integration\r\n` +
      `- **Built-In Document Reader:** Preview PDFs and image attachments seamlessly within the app.\r\n` +
      `- **Android "Open with" Support:** Directly open documents and attachments using external system applications.\r\n\r\n` +
      `---\r\n### 📦 Installation\r\n` +
      `Download and install \`myday-v1.2.0.apk\` below.`,
    apkPath: apk120,
    apkName: 'myday-v1.2.0.apk',
  });

  // 2. Recreate v1.2.1 (latest)
  await createReleaseAndUpload({
    tagName: 'v1.2.1',
    name: 'MyDay v1.2.1 — Resilient Updater, Notes Experience & Calendar',
    body: `## What's New in MyDay v1.2.1 🚀\r\n\r\n` +
      `### 🔄 In-App Updater & Stability\r\n` +
      `- **Responsive Update Sheet:** Fixed the modal bottom sheet overflow on all mobile screen heights; action buttons are now permanently visible.\r\n` +
      `- **Resilient Chunked OTA Downloads:** Added automatic HTTP Range resume across network hiccups and connection drops (up to 5 automatic retries).\r\n` +
      `- **Dynamic Version Resolution:** Device packages query Android's package manager dynamically for reliable update checks.\r\n\r\n` +
      `### 🎨 Brand Identity Refresh\r\n` +
      `- **Transparent Brand Logo:** Applied clean ribbon logo without background across the app and admin console.\r\n\r\n` +
      `### 📝 MyDay Notes Experience\r\n` +
      `- **Multi-Modal Notes Editor:** Vector canvas sketch drawing, rich text formatting, checklist blocks, and audio/file attachments.\r\n` +
      `- **Folder Organization & Safe Trash:** Hierarchical folders with soft deletion and restore.\r\n\r\n` +
      `### 🔔 Smart Reminder Escalation\r\n` +
      `- **Escalating Alerts:** Configurable repetitive reminder intervals for critical tasks.\r\n` +
      `- **Customizable Tunes:** Super Admin–managed audio tunes catalog.\r\n\r\n` +
      `### 📅 Calendar Integration\r\n` +
      `- **Unified Task & Schedule View:** Monthly dot indicators linked to tasks and daily habits.\r\n\r\n` +
      `---\r\n### 📦 Installation\r\n` +
      `Download **myday-v1.2.1.apk** below and tap to install directly over your existing app. All your notes, tasks, habits, and split transactions are 100% preserved.`,
    apkPath: apk121,
    apkName: 'myday-v1.2.1.apk',
  });

  console.log('\nAll releases successfully restored!');
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
