-- ============================================================================
-- 🩸 HemoConnect Supabase PostgreSQL Schema & Security Script
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. EXTENSIONS
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- 2. TABLES
-- ----------------------------------------------------------------------------

-- PROFILES TABLE
-- Linked directly to Supabase auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT NOT NULL,
  blood_group TEXT,
  role TEXT DEFAULT 'donor' CHECK (role IN ('donor', 'admin')),
  city TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- DONORS TABLE
-- Stores donor applications & verification status
CREATE TABLE IF NOT EXISTS public.donors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  city TEXT NOT NULL,
  blood_group TEXT NOT NULL,
  medical_condition TEXT,
  alcohol TEXT,
  smoking TEXT,
  medical_report TEXT,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- EMERGENCY REQUESTS TABLE
-- Stores urgent blood requests
CREATE TABLE IF NOT EXISTS public.emergency_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  patient_name TEXT NOT NULL,
  hospital TEXT NOT NULL,
  blood_group TEXT NOT NULL,
  units INTEGER NOT NULL DEFAULT 1,
  phone TEXT NOT NULL,
  location TEXT NOT NULL,
  status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Processing', 'Completed')),
  request_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 3. INDEXES FOR FAST PERFORMANCE
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_donors_status ON public.donors(status);
CREATE INDEX IF NOT EXISTS idx_donors_blood_group ON public.donors(blood_group);
CREATE INDEX IF NOT EXISTS idx_donors_city ON public.donors(city);
CREATE INDEX IF NOT EXISTS idx_donors_user_id ON public.donors(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_status ON public.emergency_requests(status);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- ----------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_requests ENABLE ROW LEVEL SECURITY;

-- --- PROFILES POLICIES ---

-- Allow users to read their own profile
CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id OR EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- Allow users to insert their own profile during registration
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Allow users to update their own profile (or admins to update any profile)
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id OR EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  ));

-- --- DONORS POLICIES ---

-- Donors can view their own application, Admins can view all applications,
-- and Authenticated Users can search APPROVED donors.
CREATE POLICY "View donor applications"
  ON public.donors FOR SELECT
  USING (
    status = 'Approved'
    OR auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Authenticated users can submit donor registrations
CREATE POLICY "Submit donor application"
  ON public.donors FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Admins or profile owner can update donor applications
CREATE POLICY "Update donor applications"
  ON public.donors FOR UPDATE
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can delete donor applications
CREATE POLICY "Admins can delete donors"
  ON public.donors FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- --- EMERGENCY REQUESTS POLICIES ---

-- All authenticated users can view emergency requests
CREATE POLICY "View emergency requests"
  ON public.emergency_requests FOR SELECT
  USING (auth.role() = 'authenticated');

-- Authenticated users can insert emergency requests
CREATE POLICY "Create emergency request"
  ON public.emergency_requests FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Admins or owner can update emergency request status
CREATE POLICY "Update emergency request status"
  ON public.emergency_requests FOR UPDATE
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can delete emergency requests
CREATE POLICY "Delete emergency request"
  ON public.emergency_requests FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ----------------------------------------------------------------------------
-- 5. STORAGE BUCKET & POLICIES
-- Bucket Name: medical-reports
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('medical-reports', 'medical-reports', false)
ON CONFLICT (id) DO NOTHING;

-- Policy: Authenticated users can upload to medical-reports bucket
CREATE POLICY "Users can upload medical report"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'medical-reports'
    AND auth.role() = 'authenticated'
  );

-- Policy: File owners or Admins can read medical reports
CREATE POLICY "Users and admins can view medical reports"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'medical-reports'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
      )
    )
  );

-- ----------------------------------------------------------------------------
-- 6. ADMIN SETUP ASSISTANCE INSTRUCTIONS
-- ----------------------------------------------------------------------------
-- To promote an existing user to Admin, execute this query in your Supabase SQL Editor:
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@hemoconnect.com';
