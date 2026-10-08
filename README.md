# MyDay — Personal Life Management & Productivity Platform

A privacy-conscious, offline-first personal life management application designed for Android, along with a companion public website and super-admin management console.

---

## 📁 Repository Structure

```text
myday/
├── apps/
│   ├── mobile/         # Flutter Android Application (Offline-first, Riverpod, Drift)
│   ├── web/            # Next.js Public Landing & Documentation Site
│   └── admin/          # Next.js Super Admin Management Dashboard
├── services/
│   └── ai/             # FastAPI AI services (Reserved for future milestone)
├── packages/
│   └── contracts/      # Shared TypeScript/Dart data contracts & types
├── supabase/           # Supabase DB migrations, seed data, and Edge functions
├── docs/               # System architecture, PRD, SRS, UI/UX, database & security specs
├── scripts/            # Tooling and verification scripts
└── .github/workflows/  # Continuous Integration & Delivery automation
```

---

## 🚀 Quick Start

### Mobile (Flutter)
- Ensure Flutter 3.44+ and Android SDK are installed.
```bash
cd apps/mobile
flutter pub get
flutter gen-l10n
flutter test
flutter run
```

### Web Landing Site
```bash
cd apps/web
npm install
npm run dev
```

### Super Admin Dashboard
```bash
cd apps/admin
npm install
npm run dev
```

---

## 🎨 Design System

- **Primary Indigo:** `#4F46E5`
- **Secondary Violet:** `#7C3AED`
- **Accent Cyan:** `#06B6D4`
- **Success Mint:** `#10B981`
- **Expense/Alert Coral:** `#F97373`
- **Typography:** Modern sans-serif (Inter / Outfit)
- **Supported Languages:** English, Tamil (தமிழ்), Sinhala (සිංහල)

---

## 🔒 Security & Privacy

- Full offline-first capability with zero mandatory account registration for MVP.
- All tasks, transactions, and notes remain encrypted and local on device.
- Financial monetary values are tracked in integer minor currency units (cents).
