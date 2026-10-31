# PostHog Data Warehouse Source Setup

Created 0 of 6 detected sources in PostHog. The OAuth and secure credential steps require browser setup, so all 6 sources need to be completed in the PostHog app.

## Changes made

- Reviewed the detected Firebase, GitHub, Google Analytics, Resend, Supabase, and Vercel sources.
- Confirmed the current PostHog connector requirements for Resend, Supabase, and Vercel.
- Prepared pre-filled PostHog source URLs for every detected source.
- No application source code or environment configuration was changed.

## Files created

- `posthog-warehouse-report.md` — this setup handoff report.

## Sources requiring browser setup

- [Connect Firebase](https://us.i.posthog.com/project/689658/data-warehouse/new-source?kind=Firebase&utm_source=wizard&utm_campaign=warehouse-source)
- [Connect GitHub](https://us.i.posthog.com/project/689658/data-warehouse/new-source?kind=Github&utm_source=wizard&utm_campaign=warehouse-source)
- [Connect Google Analytics](https://us.i.posthog.com/project/689658/data-warehouse/new-source?kind=GoogleAnalytics&utm_source=wizard&utm_campaign=warehouse-source)
- [Connect Resend](https://us.i.posthog.com/project/689658/data-warehouse/new-source?kind=Resend&utm_source=wizard&utm_campaign=warehouse-source) — OAuth was selected. Authorize a Resend account with full access so PostHog can read audiences, broadcasts, contacts, domains, emails and metrics, and suppressions.
- [Connect Supabase](https://us.i.posthog.com/project/689658/data-warehouse/new-source?kind=Supabase&utm_source=wizard&utm_campaign=warehouse-source) — use the Session-pooler connection details and the database password, not an `anon` or `service_role` key.
- [Connect Vercel](https://us.i.posthog.com/project/689658/data-warehouse/new-source?kind=Vercel&utm_source=wizard&utm_campaign=warehouse-source) — enter a read-only access token and, when syncing team-owned resources, the optional team ID.

## Manual next steps

1. Open each link above and complete authentication in PostHog.
2. For Supabase, select the publicly reachable Session-pooler endpoint shown by Supabase.
3. For Vercel, ensure the token's role can read billing if the `billing_charges` table should sync.
4. Review the tables and sync settings in PostHog before starting each initial import.
