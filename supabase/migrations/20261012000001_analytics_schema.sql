-- MyDay Super Admin — Analytics & App Reach Telemetry Schema
-- Migration: 20261012000001_analytics_schema.sql

-- 1. Raw Telemetry Events Table (Bounded retention, indexed for rollup queries)
CREATE TABLE IF NOT EXISTS public.analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID UNIQUE NOT NULL, -- Client-generated UUIDv4 for deduplication
  event_type TEXT NOT NULL,
  client_type TEXT NOT NULL CHECK (client_type IN ('web', 'mobile_android')),
  installation_id UUID,          -- Anonymous installation ID (Mobile only)
  visitor_hash TEXT,             -- Ephemeral daily salt hash (Web only)
  app_version TEXT,              -- e.g. "1.1.1"
  version_code INT,              -- e.g. 4
  os_version TEXT,               -- e.g. "Android 14"
  device_category TEXT CHECK (device_category IN ('mobile', 'tablet', 'desktop', 'unknown')),
  feature TEXT,                  -- 'today', 'tasks', 'calendar', 'finance', 'notes', 'myday_split', 'profile', 'settings'
  action TEXT,                   -- 'task_created', 'task_completed', 'split_expense_created', etc.
  referral_source TEXT,          -- 'direct', 'whatsapp', 'github', 'organic', etc.
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Optimize queries for analytics time-slices and funnel steps
CREATE INDEX IF NOT EXISTS idx_analytics_events_type_date 
  ON public.analytics_events (event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_events_install_date 
  ON public.analytics_events (installation_id, created_at DESC) 
  WHERE installation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_events_feature_date 
  ON public.analytics_events (feature, created_at DESC) 
  WHERE feature IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at 
  ON public.analytics_events (created_at DESC);

-- 2. Daily Pre-Computed Aggregates Table
CREATE TABLE IF NOT EXISTS public.analytics_daily_aggregates (
  date DATE PRIMARY KEY,
  web_page_views INT NOT NULL DEFAULT 0,
  unique_web_visitors INT NOT NULL DEFAULT 0,
  download_button_impressions INT NOT NULL DEFAULT 0,
  download_button_clicks INT NOT NULL DEFAULT 0,
  confirmed_downloads INT NOT NULL DEFAULT 0,
  app_first_opens INT NOT NULL DEFAULT 0,
  daily_active_installations INT NOT NULL DEFAULT 0,
  weekly_active_installations INT NOT NULL DEFAULT 0,
  monthly_active_installations INT NOT NULL DEFAULT 0,
  total_sessions INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Daily Feature Usage Aggregates Table
CREATE TABLE IF NOT EXISTS public.analytics_feature_daily (
  date DATE NOT NULL,
  feature TEXT NOT NULL,
  total_opens INT NOT NULL DEFAULT 0,
  distinct_active_installations INT NOT NULL DEFAULT 0,
  total_actions INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (date, feature)
);

CREATE INDEX IF NOT EXISTS idx_analytics_feature_daily_date 
  ON public.analytics_feature_daily (date DESC);

-- 4. Row Level Security Policies
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_daily_aggregates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_feature_daily ENABLE ROW LEVEL SECURITY;

-- Deny all direct client access; queries execute via Server Role / Route Handlers
DROP POLICY IF EXISTS "Deny direct public select on analytics_events" ON public.analytics_events;
CREATE POLICY "Deny direct public select on analytics_events" 
  ON public.analytics_events FOR SELECT USING (false);

DROP POLICY IF EXISTS "Deny direct public write on analytics_events" ON public.analytics_events;
CREATE POLICY "Deny direct public write on analytics_events" 
  ON public.analytics_events FOR INSERT WITH CHECK (false);
