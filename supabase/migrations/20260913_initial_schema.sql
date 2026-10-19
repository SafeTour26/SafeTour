-- SafeTour: Database Schema Migration & Security Provisioning
-- Target Database: Supabase / PostgreSQL 15+

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Create Core Tables

-- 2.1 Profiles Table (linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    age INT CHECK (age >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.2 Emergency Contacts Table
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    contact_name TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    contact_phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.3 Safety Zones Table
CREATE TABLE IF NOT EXISTS public.safety_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    area_name TEXT NOT NULL UNIQUE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters INT DEFAULT 1000,
    day_score NUMERIC(3, 1) CHECK (day_score BETWEEN 1.0 AND 10.0),
    night_score NUMERIC(3, 1) CHECK (night_score BETWEEN 1.0 AND 10.0),
    overall_score NUMERIC(3, 1) CHECK (overall_score BETWEEN 1.0 AND 10.0),
    crowd_rating INT CHECK (crowd_rating BETWEEN 1 AND 10),
    lighting_rating INT CHECK (lighting_rating BETWEEN 1 AND 10),
    safety_tips TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.4 SOS Events Table
CREATE TABLE IF NOT EXISTS public.sos_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'false_alarm')),
    triggered_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Indexes for Query Performance
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON public.emergency_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_safety_zones_coords ON public.safety_zones(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_safety_zones_area_name ON public.safety_zones(area_name);
CREATE INDEX IF NOT EXISTS idx_sos_events_user_id ON public.sos_events(user_id);
CREATE INDEX IF NOT EXISTS idx_sos_events_status_time ON public.sos_events(status, triggered_at DESC);

-- 4. Triggers & Auto-Sync Functions

-- 4.1 Update timestamp helper
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_safety_zones_updated_at ON public.safety_zones;
CREATE TRIGGER set_safety_zones_updated_at
    BEFORE UPDATE ON public.safety_zones
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4.2 Auto-create profile on auth.users creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, phone_number)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1),
            'SafeTour User'
        ),
        NEW.phone
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Row Level Security (RLS) Policies

-- 5.1 Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sos_events ENABLE ROW LEVEL SECURITY;

-- 5.2 Profiles RLS: SELECT and UPDATE only where auth.uid() = id
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 5.3 Emergency Contacts RLS: Full CRUD only where auth.uid() = user_id
DROP POLICY IF EXISTS "emergency_contacts_select_own" ON public.emergency_contacts;
CREATE POLICY "emergency_contacts_select_own"
    ON public.emergency_contacts
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "emergency_contacts_insert_own" ON public.emergency_contacts;
CREATE POLICY "emergency_contacts_insert_own"
    ON public.emergency_contacts
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "emergency_contacts_update_own" ON public.emergency_contacts;
CREATE POLICY "emergency_contacts_update_own"
    ON public.emergency_contacts
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "emergency_contacts_delete_own" ON public.emergency_contacts;
CREATE POLICY "emergency_contacts_delete_own"
    ON public.emergency_contacts
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- 5.4 Safety Zones RLS: Read-only for anon and authenticated; Write locked to service_role
DROP POLICY IF EXISTS "safety_zones_read_all" ON public.safety_zones;
CREATE POLICY "safety_zones_read_all"
    ON public.safety_zones
    FOR SELECT
    TO anon, authenticated
    USING (true);

DROP POLICY IF EXISTS "safety_zones_service_role_all" ON public.safety_zones;
CREATE POLICY "safety_zones_service_role_all"
    ON public.safety_zones
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- 5.5 SOS Events RLS: INSERT and SELECT only where auth.uid() = user_id
DROP POLICY IF EXISTS "sos_events_select_own" ON public.sos_events;
CREATE POLICY "sos_events_select_own"
    ON public.sos_events
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "sos_events_insert_own" ON public.sos_events;
CREATE POLICY "sos_events_insert_own"
    ON public.sos_events
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
