# MyDay — Database Architecture Overview

## Storage Engine
- Client-side: **Drift ORM with SQLite**.
- Multi-platform persistent local relational database.
- Strict schema versioning, foreign keys, and indexes.

## Core Tables (Milestone 2 Design)
1. `tasks`: Primary task records with priority, categories, due date/time, and completion status.
2. `task_categories`: Dynamic or predefined categories with custom colors and icons.
3. `financial_accounts`: Accounts (`cash`, `card`) with initial balance and tracking.
4. `financial_transactions`: Incomes and expenses with integer minor units (`amount_cents`).
5. `monthly_budgets`: Category budget targets per calendar month.
6. `notes`: Text body, pinned status, categories, and timestamps.
7. `note_attachments`: Metadata linking files in application private storage.
8. `user_profile`: Local display name, avatar URI, bio, preferred language, currency.
9. `app_settings`: App preferences, theme mode, notification settings.
