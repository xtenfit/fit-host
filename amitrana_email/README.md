# Amit Rana Email Verification Platform

A Next.js app for secure email verification with OTP, Supabase storage, and automated email delivery.

## Features

- modern verification landing page
- OTP generation and validation
- Supabase persistence for email + OTP records
- automated email delivery through Resend
- secure API cleanup and validation
- production-ready structure for Vercel deployment

## Tech stack

- Next.js 14
- TypeScript
- Supabase
- Resend
- Vercel

## Project structure

```text
amitrana-email/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── send-otp/
│   │   │   │   └── route.ts
│   │   │   └── verify-otp/
│   │   │       └── route.ts
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   └── page.tsx
│   └── lib/
│       ├── email.ts
│       ├── otp.ts
│       └── supabase.ts
├── supabase/
│   └── schema.sql
├── .env.example
├── next.config.mjs
├── next-env.d.ts
├── package.json
├── tsconfig.json
├── README.md
└── .gitignore
```

## Environment variables

Copy [.env.example](.env.example) to `.env.local` and fill in values:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
RESEND_API_KEY=your-resend-api-key
FROM_EMAIL=noreply@amitran.tech
NEXT_PUBLIC_APP_URL=http://localhost:3000
OTP_TTL_MINUTES=10
```

## Install

```bash
npm install
```

## Run locally

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

## Database setup with Supabase

Run the SQL from [supabase/schema.sql](supabase/schema.sql) in your Supabase SQL editor.

This creates the `email_verifications` table with fields for:

- email
- name
- company
- otp
- is_verified
- created_at
- expires_at
- verified_at

## Automated email delivery

This app sends email through Resend, which is a clean production mail service. You can replace it with Cloudflare Email or another SMTP provider later if needed.

## Deploy to Vercel

1. Push the project to GitHub.
2. Import the repo in Vercel.
3. Set the environment variables in the Vercel dashboard.
4. Deploy.

## Production note

The public page can be open to visitors, but the OTP-sending route should stay protected behind server-side logic and secure env secrets. For a real app, add authentication for admin pages and verify users in your app database as well.

## Example API usage

```bash
curl -X POST http://localhost:3000/api/send-otp \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "email": "jane@company.com",
    "company": "Amit Rana Studio"
  }'
```
