# MyDay — System Architecture

## Overview
MyDay is an offline-first personal life management platform built around a single monorepo structure.

```text
myday/
├── apps/
│   ├── mobile/         # Flutter Android Client (Drift/SQLite, Riverpod, GoRouter)
│   ├── web/            # Next.js Public Website & Documentation
│   └── admin/          # Next.js Super Admin Management Console
├── packages/
│   └── contracts/      # Cross-platform schema definitions and contracts
├── services/
│   └── ai/             # Future AI recommendation engine
└── supabase/           # Optional Cloud Persistence, Auth & Edge Functions
```

## Architectural Principles
1. **Offline-First Resilience**: All core features (Tasks, Finance, Notes, Calendar, Today Dashboard) operate completely locally without network dependency.
2. **Data Privacy & Security**: User data resides in local SQLite on-device. Zero unauthenticated data leakage.
3. **Integer Monetary Arithmetic**: All financial values are modeled in integer minor currency units (cents) to avoid floating-point inaccuracies.
4. **Separation of Concerns**: Feature-driven directory architecture in Flutter (`lib/features/{feature}/presentation|data|domain`).
