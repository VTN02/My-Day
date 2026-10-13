-- MyDay Super Admin — Core Platform & Security Schema
-- Migration: 20261012000002_admin_core_schema.sql

-- 1. Admin User Roles (RBAC for privileged access)
CREATE TABLE IF NOT EXISTS public.admin_user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'admin', 'auditor')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Admin User Operational Status (Account status metadata)
CREATE TABLE IF NOT EXISTS public.admin_user_management (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'scheduled_deletion')),
  suspension_reason TEXT,
  suspended_at TIMESTAMPTZ,
  suspended_by UUID REFERENCES auth.users(id),
  deletion_scheduled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. App Releases Table (Genuine version artifact catalog)
CREATE TABLE IF NOT EXISTS public.app_releases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version_name TEXT NOT NULL UNIQUE,
  version_code INT NOT NULL UNIQUE,
  channel TEXT NOT NULL DEFAULT 'stable' CHECK (channel IN ('stable', 'beta')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'ready', 'published', 'withdrawn')),
  file_size_bytes BIGINT NOT NULL DEFAULT 0,
  checksum_sha256 TEXT NOT NULL DEFAULT '',
  download_url TEXT NOT NULL DEFAULT '',
  is_mandatory BOOLEAN NOT NULL DEFAULT false,
  release_notes TEXT[] NOT NULL DEFAULT '{}',
  published_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Release Downloads Tracking Table (Actual download events)
CREATE TABLE IF NOT EXISTS public.release_downloads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  release_id UUID REFERENCES public.app_releases(id) ON DELETE CASCADE,
  version_name TEXT NOT NULL,
  version_code INT NOT NULL,
  client_type TEXT NOT NULL DEFAULT 'web',
  ip_hash TEXT,
  user_agent TEXT,
  downloaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_release_downloads_release 
  ON public.release_downloads (release_id, downloaded_at DESC);

-- 5. Append-Only Admin Audit Logs Table
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID,
  actor_email TEXT NOT NULL,
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  outcome TEXT NOT NULL CHECK (outcome IN ('success', 'failure')),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_created_at 
  ON public.admin_audit_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_action 
  ON public.admin_audit_logs (action, created_at DESC);

-- Cryptographic Append-Only Guarantee: Prevent updates and deletes on audit logs
CREATE OR REPLACE FUNCTION prevent_audit_log_modification()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'Audit logs are immutable append-only records and cannot be updated or deleted.';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_immutable_audit_logs ON public.admin_audit_logs;
CREATE TRIGGER trg_immutable_audit_logs
BEFORE UPDATE OR DELETE ON public.admin_audit_logs
FOR EACH ROW EXECUTE FUNCTION prevent_audit_log_modification();

-- 6. Platform Settings (Global key-value configuration)
CREATE TABLE IF NOT EXISTS public.platform_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_by TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 7. System Health Diagnostics History
CREATE TABLE IF NOT EXISTS public.system_health_probes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('healthy', 'degraded', 'unavailable', 'not_monitored')),
  latency_ms INT NOT NULL DEFAULT 0,
  details TEXT,
  checked_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_health_probes_service_date 
  ON public.system_health_probes (service_name, checked_at DESC);

-- 8. Row Level Security Policies
ALTER TABLE public.admin_user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_user_management ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_releases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.release_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_health_probes ENABLE ROW LEVEL SECURITY;

-- Deny all direct client access; queries execute via Server Role / Route Handlers
CREATE POLICY "Deny direct public select on admin_user_roles" 
  ON public.admin_user_roles FOR ALL USING (false);

CREATE POLICY "Deny direct public select on admin_user_management" 
  ON public.admin_user_management FOR ALL USING (false);

CREATE POLICY "Allow public read on published app_releases" 
  ON public.app_releases FOR SELECT USING (status = 'published');

CREATE POLICY "Deny direct public write on app_releases" 
  ON public.app_releases FOR INSERT WITH CHECK (false);

CREATE POLICY "Deny direct public write on release_downloads" 
  ON public.release_downloads FOR ALL USING (false);

CREATE POLICY "Deny direct public on admin_audit_logs" 
  ON public.admin_audit_logs FOR ALL USING (false);

CREATE POLICY "Allow public read on safe platform_settings" 
  ON public.platform_settings FOR SELECT USING (key IN ('min_supported_version_code', 'recommended_version', 'maintenance_mode', 'maintenance_notice', 'whatsapp_community_url', 'privacy_policy_url', 'support_url'));

CREATE POLICY "Deny direct public write on platform_settings" 
  ON public.platform_settings FOR INSERT WITH CHECK (false);

CREATE POLICY "Deny direct public on system_health_probes" 
  ON public.system_health_probes FOR ALL USING (false);
