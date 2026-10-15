const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

// Obtain GitHub token via Git Credential Manager
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
            console.log(`\nAsset ${assetName} uploaded successfully!`);
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
        console.log(`Uploaded ${assetName}: ${pct}% (${(uploadedBytes / (1024 * 1024)).toFixed(1)} MB / ${(stats.size / (1024 * 1024)).toFixed(1)} MB)...`);
      }
    });

    fileStream.pipe(req);
  });
}

async function main() {
  const apkPath = path.resolve(__dirname, '..', 'myday-v1.3.0.apk');
  if (!fs.existsSync(apkPath)) {
    console.error(`APK not found at ${apkPath}`);
    process.exit(1);
  }

  const tagName = 'v1.3.0';
  const name = 'MyDay v1.3.0 — Task Analytics, Expense Budgets, Money Tracker & Live Sync';
  const body = `## What's New in MyDay v1.3.0 🚀\r\n\r\n` +
    `### 📊 Task Status Automation & Analytics\r\n` +
    `- **Intelligent Cohorts:** Automated dynamic task cohorts (Urgent, Due Soon, In Progress, Upcoming, Overdue, Completed).\r\n` +
    `- **Task Analytics Dashboard:** Visual completion rates, priority distribution, and velocity metrics.\r\n` +
    `- **Notes Report Export:** 1-tap export of productivity summaries directly into rich MyDay Notes blocks.\r\n\r\n` +
    `### 💰 Multi-Period Expense Budgeting\r\n` +
    `- **Flexible Horizons:** Daily, weekly, and monthly expense budgets with real-time spend tracking.\r\n` +
    `- **Threshold Warnings:** Proactive alert flags at 80% and 100% budget utilization.\r\n` +
    `- **Custom Categories:** Add unlimited custom categories with color palettes and custom icons.\r\n\r\n` +
    `### 🤝 Money Tracker (Borrowed & Lent)\r\n` +
    `- **Track Receivables & Payables:** Monitor who owes you and who you owe with due date alerts.\r\n` +
    `- **Partial Repayments:** Record partial or full repayments with quick-fill chips.\r\n` +
    `- **Ledger Balance Sync:** Atomically update liquid Cash and Card account balances upon lending or repaying.\r\n\r\n` +
    `### ⚡ Live Cross-App Reactivity\r\n` +
    `- Immediate real-time data sync across Today Dashboard, Calendar, Finance, and Money Tracker without manual refresh.\r\n\r\n` +
    `---\r\n### 📦 Installation\r\n` +
    `Download **myday-v1.3.0.apk** below and tap to install directly over your existing app. All your notes, tasks, habits, and split transactions are 100% preserved.`;

  console.log(`\n=== Creating Release ${tagName} ===`);
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
  console.log(`Uploading myday-v1.3.0.apk...`);
  await uploadAsset(release, apkPath, 'myday-v1.3.0.apk');
  console.log(`\nSuccessfully released ${tagName}!`);
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
