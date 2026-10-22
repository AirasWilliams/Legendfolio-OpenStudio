# Self-hosting Legendfolio

This guide describes the Build 60 deployment layout. It covers a static Legendfolio frontend plus your own managed Supabase project. It does not describe running the Supabase server stack yourself.

Local personal use needs no Supabase setup: run the included local server and choose **Enter Studio**. Connected accounts, cloud records and shared campaigns require the steps below.

## 1. Prepare an independent instance

Use a separate Supabase project for your deployment and a test project for development. A fork must not rely on the original maintainer's production backend. Your instance's accounts and campaign invitations belong to its own database.

Keep important local records in complete character/campaign backups. Reusing the same hostname, port and browser profile preserves access to that origin's local library; changing origins creates a different local storage context.

The folder containing `index.html`, `cloud_core.js`, `cloud-config.json`, `vercel.json` and `scripts/` is the deployment root. Node.js 22 or later is needed for its static build. This build uses Node built-ins; it does not require a frontend framework installation.

## 2. Create the database and apply migrations

Create a Supabase project and open its SQL Editor. On a fresh project, run all supplied migration files in filename order, **001 through 018, once each**:

| Suffix | Area |
| --- | --- |
| 001 | Private profiles and personal characters |
| 002 | Campaigns, invitations and membership |
| 003 | Character review |
| 004 | Campaign people/roster |
| 005–006 | Campaign deletion and recovery |
| 007–009 | Review history, approved sheets and rejoining |
| 010 | Campaign dashboard |
| 011 | Campaign activity |
| 012 | Connected sessions |
| 013 | Authoritative campaign dice |
| 014 | Shared party status |
| 015 | Connected encounters |
| 016 | Builder drafts and campaign policy |
| 017 | Campaign Builder |
| 018 | Campaign sheet templates |

The source files are in [supabase/migrations](../supabase/migrations). Filename order matters; later files depend on earlier tables/helpers. Stop and investigate any SQL error instead of skipping the failed file. Do not reapply already installed migrations. For an existing installation, back up the database and apply only the missing changes.

These migrations target Supabase's existing `auth` roles/functions. They are not a standalone database bootstrap for arbitrary PostgreSQL installations. The browser key cannot create this schema.

## 3. Set browser configuration

Use the project's **publishable** key, or a supported legacy anon key. Never use a secret/service-role key, database password or connection string in any browser configuration.

The build reads these process environment variables:

```text
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_REPLACE_WITH_YOUR_KEY
LEGENDFOLIO_SITE_URL=https://YOUR_APP_DOMAIN
```

On Vercel, add them in the project's environment settings for the appropriate deployment environments. `LEGENDFOLIO_SITE_URL` must be an HTTPS address for the deployed app. The config validator normalises it to that origin's `/index.html`.

For a local static build, set environment variables in the shell before running the build. For example, PowerShell:

```powershell
$env:SUPABASE_URL = 'https://YOUR_PROJECT_REF.supabase.co'
$env:SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_REPLACE_WITH_YOUR_KEY'
$env:LEGENDFOLIO_SITE_URL = 'https://YOUR_APP_DOMAIN'
node scripts/build.mjs
```

**The supplied Node build does not automatically load `.env` files.** Copying `.env.example` to `.env` alone does not configure it. Environment values override `cloud-config.json`; otherwise that file supplies defaults.

When serving the source folder through `server.py`, the browser reads that folder's `cloud-config.json` directly. Configure it for your instance:

```json
{
  "supabaseUrl": "https://YOUR_PROJECT_REF.supabase.co",
  "supabasePublishableKey": "sb_publishable_REPLACE_WITH_YOUR_KEY",
  "siteUrl": "https://YOUR_APP_DOMAIN/",
  "sdkPath": "./vendor/supabase-2.117.3.js"
}
```

These examples are placeholders, not working credentials. Before publishing a fork, replace inherited live-service defaults with clearly labelled placeholder configuration. An example `.env` file should contain examples, not the upstream deployment's actual project settings. Do not publish local `.env` files.

Publishable keys are designed for browser use. They do not replace backend permission checks. [Supabase API keys](https://supabase.com/docs/guides/getting-started/api-keys)

## 4. Configure allowed network access

The included Vercel Content Security Policy permits a specific Supabase origin. **Changing `SUPABASE_URL` does not automatically change that header.**

In `vercel.json`, update the Supabase HTTPS origin inside the `Content-Security-Policy` header's `connect-src` directive to match your project. Preserve the other directives and existing script hashes. The relevant portion should have this shape:

```text
connect-src 'self' https://YOUR_PROJECT_REF.supabase.co https://cdnjs.cloudflare.com;
```

Current connected features use HTTP polling. Future Realtime/Discord work will require its own reviewed network/frame policy; broad wildcard origins or disabling the policy is not a substitute.

If you edit embedded scripts in `index.html`, their `script-src` hashes also need to be regenerated through the maintainer's release process. The supplied `scripts/build.mjs` does not regenerate those hashes.

## 5. Configure authentication

In Supabase **Authentication → URL Configuration**, set the production Site URL to your application's HTTPS origin and add the redirect URLs your instance uses. For example:

```text
https://YOUR_APP_DOMAIN/index.html
http://127.0.0.1:8766/index.html
http://localhost:8766/index.html
```

The app appends `?auth=verify` or `?auth=recovery`. Configure redirect matching to permit those return URLs. For local development, Supabase supports wildcard entries such as `http://127.0.0.1:8766/**` and `http://localhost:8766/**`. Keep production rules restricted to your actual deployment; configure preview domains deliberately. See [Supabase redirect URL guidance](https://supabase.com/docs/guides/auth/redirect-urls).

Enable the email/password sign-in flow and decide your email-confirmation policy. Configure and test verification/recovery email delivery, including provider limits, before offering public registration. Supabase instance settings control actual email behaviour; successful local UI tests do not prove delivery.

This release uses PKCE for account links. Finish verification/recovery in the same browser context that initiated the flow where needed; if the browser cannot recover the link's session, request a fresh link from the intended app/browser.

No in-app AI provider key is required. The current portrait workflow uses bundled art and personal uploads.

## 6. Build and deploy

Run from the deployment root:

```sh
node scripts/build.mjs
```

The output is `dist/`. It includes the application, static assets, bundled libraries and validated public cloud configuration. The build does not apply migrations or test a live Supabase project.

For Vercel:

- Set Root Directory to the directory containing `vercel.json`.
- Use the included configuration: build command `node scripts/build.mjs`, output directory `dist`, no framework preset required.
- Set the environment values from step 3 and the allowed origin from step 4.
- Deploy to HTTPS, then verify the resulting `cloud-config.json` uses your own public project configuration.

For other static hosts, serve `dist/` and reproduce the security/cache headers in `vercel.json`. Do not serve the entire development tree, environment files or test databases. Keep update metadata/configuration fresh and the app/service-worker release identities consistent.

The current manifest and authentication helpers assume an origin-root application with `/index.html`. Subdirectory deployments require adaptation and are not a documented drop-in configuration.

## 7. Verify before inviting users

Use separate fictional DM, player and unrelated accounts:

1. Register, receive a verification email, sign in, sign out and complete password recovery.
2. Back up a character to the account; load it on another device/browser. Confirm the unrelated account cannot read it.
3. Create a connected campaign as DM, issue an invite, submit a player-owned character and approve it.
4. Confirm pending members cannot use approved-member gameplay access. Confirm a frontend DM selection does not grant ownership of another account's campaign.
5. Confirm party HP/conditions and connected initiative follow the configured visibility and polling behaviour.
6. Roll privately and verify that no DM campaign roll is created. Make a campaign roll and inspect its authorised DM record.
7. Publish a clean fillable sheet template; populate it as an approved member and reject an unrelated account.
8. Exercise competing edits, an interrupted request and safe retry. Confirm local records remain recoverable.
9. Test local entry, reload/offline use after caching, backups and app updates on a real phone and both tablet orientations.

Preserve the supplied Row Level Security policies and validated operations. A successful login is not proof of campaign isolation. Do not open direct table access simply to bypass an application error.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Local library appears empty | Hostname, port, browser profile and local/cloud character scope; restore a backup if you deliberately moved origins. |
| Cloud configuration missing | Values in the served `cloud-config.json`, environment scope and build logs. A `.env` file is not loaded automatically. |
| Browser blocks a cloud request | `connect-src` in the deployed CSP must include your project's HTTPS origin. |
| Missing table/function | Correct project and migration order; identify the first missing/failed migration. |
| Confirmation/recovery returns to another site | Site URL, redirect allowlist and the deployed `LEGENDFOLIO_SITE_URL`. |
| Email does not arrive | Supabase Auth/email configuration, provider delivery/rate limits and spam filtering. |
| A campaign invite works on the official app but not your fork | The two deployments may use different databases; invites are instance-specific. |
| DM tools show local data rather than shared records | Select the intended owned connected campaign; local notebook data is separate. |
| Stale changes are rejected | Review the newer revision and use the application's conflict controls. |
| Update remains unverified | Network/cache headers, `release.json`, `sw.js` and matching release identity. Back up records before diagnosing site storage. |

## Operations and limits

Plan database backups, account abuse handling, email delivery, retention and service monitoring before public registration. Provider service limits and costs apply even when the application code is free.

The current schema/clients do not make every notebook feature a shared service. Refer to the README's limits and keep roadmap features clearly separate from deployed ones.
