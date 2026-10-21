create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  name text not null,
  company text,
  password_hash text not null,
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  verified_at timestamptz null
);

create table if not exists public.email_verifications (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  otp text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  verified_at timestamptz null
);

create index if not exists users_email_idx on public.users(email);
create index if not exists email_verifications_email_idx on public.email_verifications(email);
create index if not exists email_verifications_expires_at_idx on public.email_verifications(expires_at);
