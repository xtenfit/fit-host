# Fit Host — Production Next.js Web Platform

Official website and web dashboard for **Fit Host** (`https://fithost.amitrana.tech`), engineered to mirror the visual identity, local-cached sync architecture, and Supabase database models of the native Flutter mobile application.

---

## 1. Architecture Overview

- **Framework**: Next.js 16 (App Router) with React 19 and TypeScript.
- **Styling**: Tailwind CSS v4 with custom neon green (`#39FF88`) and electric blue (`#0866F5`) theme tokens, dark surfaces (`#0A0F0D`, `#14181F`, `#1E242E`), and glassmorphic panels.
- **Authentication & Backend**: Supabase SSR (`@supabase/ssr` and `@supabase/supabase-js`) using Server Components, Route Handlers, and secure HTTP-only session cookies.
- **Hosting**: Vercel with automatic Edge CDN routing and custom domain configuration.
- **Security**: Database-enforced Row Level Security (RLS) on all tables (`auth.uid() = user_id`), strict HTTP security headers via `vercel.json`, zero public caching of `/dashboard`.

---

## 2. Directory Structure

```
website/
├── public/                     # Authentic app icons, exercise categories & mobile screenshots
│   ├── fit_host_icon.png
│   └── images/
│       ├── categories/         # Strength, cardio, hiit, bodyweight, etc.
│       └── screenshots/        # Live Flutter screens (home, workouts, nutrition, progress, diary)
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── (public)/           # /, /features, /how-it-works, /about, /support, /privacy, /terms
│   │   ├── (auth)/             # /login, /signup, /verify-email, /forgot-password
│   │   ├── auth/               # /auth/callback (PKCE route handler), /auth/recovery (password reset)
│   │   ├── dashboard/          # Authenticated dashboard (real Supabase data only)
│   │   ├── globals.css         # Theme tokens, neon glows, scrollbars
│   │   ├── layout.tsx          # Root layout with SEO metadata & responsive navigation
│   │   ├── robots.ts           # robots.txt generation
│   │   └── sitemap.ts          # XML sitemap generation
│   ├── components/
│   │   ├── layout/             # Navbar (auth-aware, mobile drawer) & Footer
│   │   └── dashboard/          # SignOutButton & dashboard widgets
│   ├── lib/
│   │   └── supabase/           # client.ts (browser), server.ts (cookies), middleware.ts (session refresh)
│   └── middleware.ts           # Route protection & session renewal proxy
├── test/
│   └── site-verification.test.mjs # Automated architecture & security test suite
├── vercel.json                 # Vercel deployment headers & cache controls
└── next.config.ts              # Turbopack & remote image patterns
```

---

## 3. Environment Variables

Create `.env.local` inside `website/` (or configure in Vercel Project Settings):

```bash
NEXT_PUBLIC_SUPABASE_URL=https://eedubttdylyqrhyeikwb.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_RIk7q1B0Cj6BWmsNGAMUsA_t09zbMv6
NEXT_PUBLIC_SITE_URL=https://fithost.amitrana.tech
```

> **Security Note**: Never add or expose `SUPABASE_SERVICE_ROLE_KEY` in client environments. The website operates under least privilege using user sessions and Supabase RLS.

---

## 4. Local Development & Testing

```bash
cd website

# Install dependencies
npm install

# Run automated tests
npm test

# Build for production
npm run build

# Start local dev server
npm run dev
```

---

## 5. Vercel Deployment Instructions

1. **Import Repository**:
   - In the Vercel Dashboard, select **New Project** and import the `fit-host` repository.
2. **Set Root Directory**:
   - In Project Settings, set **Root Directory** to `website`.
3. **Framework Preset**:
   - Choose `Next.js`.
4. **Configure Environment Variables**:
   - `NEXT_PUBLIC_SUPABASE_URL`: `https://eedubttdylyqrhyeikwb.supabase.co`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`: `sb_publishable_RIk7q1B0Cj6BWmsNGAMUsA_t09zbMv6`
   - `NEXT_PUBLIC_SITE_URL`: `https://fithost.amitrana.tech`
5. **Deploy**:
   - Click **Deploy**.

---

## 6. Custom Domain & DNS Setup

To link `https://fithost.amitrana.tech`:

1. In Vercel Project Settings -> **Domains**, add:
   `fithost.amitrana.tech`
2. In your DNS Provider (e.g. Cloudflare for `amitrana.tech`):
   - **Type**: `CNAME`
   - **Name**: `fithost`
   - **Target**: `cname.vercel-dns.com`
   - **Proxy status**: `DNS only` (Gray cloud) if Vercel handles SSL certificates directly.
3. **Safeguard**:
   - **DO NOT MODIFY** the existing `n8n` subdomain or Cloudflare Tunnel records. They remain private and untouched.

---

## 7. Supabase Redirect URL Configuration

In Supabase Dashboard -> **Authentication** -> **URL Configuration**:

1. **Site URL**: `https://fithost.amitrana.tech`
2. **Redirect URLs**:
   - `io.supabase.fithost://login-callback` *(PRESERVED for Flutter Mobile)*
   - `https://fithost.amitrana.tech/auth/callback` *(Web Production)*
   - `http://localhost:3000/auth/callback` *(Web Local Development)*
