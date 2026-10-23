# Public release and hosting policy

Build 62 keeps the connected feature code with local-first entry and optional instance configuration. It does not introduce a public shared development database.

## Package contents

- Original code under AGPL-3.0-only and a reproducible Node-only source build.
- Editable source/styles, blank seed, SRD data, migrations and focused public tests.
- A prebuilt local application and configurable static deployment output.
- No upstream Supabase URL/key in default configuration. Disabled builds permit no Supabase network origin.
- A corresponding-source ZIP generated with each deployment and available through About.
- 112 portraits with CC BY 4.0 permission to the extent applicable rights are held, AI-generation provenance and checksums.
- Exact SRD attribution, library notices and a separate branding policy.
- Setup documentation and CI using fictional data, without production credentials.

## Online onboarding

1. Try Enter Studio locally; no account/backend required.
2. Join an existing instance through its sign-in and campaign invite workflow.
3. To host connected play, follow [SELF_HOSTING.md](SELF_HOSTING.md), apply migrations 001–018 to your own Supabase project and supply its public configuration.
4. Build/deploy and verify separate DM/player/unrelated accounts before inviting users.

Vercel Hobby and Supabase Free are starter options subject to current terms/limits, not a promise of permanent zero-cost public hosting. Vercel Hobby is for personal/non-commercial use; Supabase Free projects can pause after low activity. See [Vercel terms](https://vercel.com/legal/terms) and [Supabase pausing](https://supabase.com/docs/guides/platform/free-project-pausing).

## Publishing the repository

Place this package's contents at the repository root. This export includes no Git history. If changing an existing repository's visibility, audit its commits, branches, tracked attachments and settings independently. A clean new ZIP does not sanitise existing history.

The official deployment is not reconfigured by this package. Its environment settings remain the operator's responsibility. Fork accounts/campaigns are independent unless operators deliberately use the same trusted backend.

Review the package and enable GitHub private vulnerability reporting before inviting security reports. Add actual repository/contact details when known; this release invents neither a security mailbox nor an SLA.

Before public connected registration, verify Auth/email delivery, campaign isolation, backups, abuse handling and provider limits on the actual deployment. Local automated checks do not establish live acceptance.

## Official development and independent forks

The maintainer and internal team direct official development and releases. Bug reports, reproducible examples, accessibility feedback, documentation corrections and suggestions are welcome through Issues. External pull requests are not accepted, and forked repositories are not merged into the official codebase. See [the feedback and development policy](../CONTRIBUTING.md).

Independent forks, modifications and redistribution remain permitted under AGPL-3.0-only and the applicable content licences. This official contribution policy does not add licence restrictions. Clearly identify unofficial builds and preserve the required notices and corresponding-source availability.

## Release discipline

Preserve source downloads, notices, migration order, matching cache identities and explicit local/cloud scopes. Additive database changes and reviewed increments protect existing users.

WORLD, Worldcraft Studio, tabletop tokens/movement, fog/vision and Discord remain planned. See [ROADMAP.md](ROADMAP.md).

## Tested public package publication

A direct maintainer push to public `main` runs build/tests with read-only permissions. After those pass, a separate publishing job regenerates the five prebuilt application/source files, verifies the remote head and uses a non-forced push. Pull requests cannot run the write job. A new build version produces a versioned GitHub release ZIP and checksum; existing curated release assets are retained. See [Build 62 notes](BUILD62_RELEASE.md). Routine development remains outside this publication path.
