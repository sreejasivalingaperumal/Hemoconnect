# 🩸 HemoConnect
### "Connecting Donors, Saving Lives"

HemoConnect is a production-quality, modern HealthTech blood donation and emergency management platform built with **Flutter 3.x**, **Material 3**, and **Supabase (PostgreSQL, Auth, Storage)**.

---

## 🚀 Quick Setup Instructions

### 1. Configure Supabase Project
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard) and create a new project.
2. Open the **SQL Editor** in Supabase and run the contents of [`supabase_schema.sql`](./supabase_schema.sql).
3. This creates:
   - `profiles` table with automatic RLS security.
   - `donors` table for applications & status.
   - `emergency_requests` table for urgent dispatches.
   - `medical-reports` private Storage bucket & access policies.

### 2. Insert Supabase API Keys
Open [`lib/config/supabase_config.dart`](./lib/config/supabase_config.dart) and insert your project credentials:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Create Admin Account
1. Register a new account inside the app using email `admin@hemoconnect.com` (or any email).
2. Go to your **Supabase Dashboard -> SQL Editor** and promote the user to Admin:

```sql
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'admin@hemoconnect.com';
```

3. Re-login to the app to immediately access the **Admin Dashboard**!

---

## 🛠️ Features Included

- **Animated Splash Screen**: Pulse blood drop logo, session check & role-based routing.
- **Responsive Auth**: Desktop split-screen illustration + elevated login card / stacked mobile UI.
- **Donor Portal**:
  - Hero banner card with CTA.
  - 4-Step Registration Wizard (Personal -> Blood -> Health -> Medical Report File Upload).
  - Find Donors lookup (displays approved donors only).
  - Emergency Blood Request form & live status tracking.
  - Profile & persistent Dark Mode toggle.
- **Admin Portal**:
  - Desktop Sidebar navigation drawer.
  - Live Analytics charts powered by `fl_chart` using real Supabase PostgreSQL data.
  - Verify Donors pipeline with expandable cards, medical report viewer (image preview & PDF), and Approve/Reject controls.
  - Blood Stock inventory dashboard calculated live for all 8 blood groups (A+, A-, B+, B-, AB+, AB-, O+, O-).
  - Emergency Request management workflow (Pending -> Processing -> Completed).
  - Donor Registry table & card views with multi-field search and filters.
