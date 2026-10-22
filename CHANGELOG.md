# Changelog

## Build 61 — Public Preview — 23 October 2026

- Independent public source/deployment package based on the working Build 60 SMART PLAY interface.
- Original application code released under AGPL-3.0-only; bundled portraits under CC BY 4.0 to the extent applicable rights are held, with provenance/checksums. SRD/dependency notices retained separately.
- Online features retained, with no upstream Supabase URL/key in default configuration. The default build operates locally and explains how a host can enable connected play.
- Shared backend configuration contract supports compatible HTTPS Supabase origins, custom domains and publishable/legacy anon keys; rejects privileged keys and malformed configuration.
- Complete Node-only source build replaces dependence on private PDFs, a personal backdrop and machine-specific generation scripts. The preferred source, styles, rule data, migrations and build/test scripts are included.
- Content Security Policy hashes and the permitted backend origin are generated together. Vercel and static-host header guidance are included.
- Each deployment includes a downloadable corresponding-source archive linked from About.
- Generic Python/Node local launchers, optional-cloud setup guide, public README, contribution/security guidance and CI build/test workflow.
- Existing character ownership, approvals, campaign permissions, local storage keys and tabletop roadmap retained. WORLD/Worldcraft Studio, playable tokens, fog/vision and Discord are not implemented in this release.

No new SQL migration is introduced. Fresh connected deployments need migrations 001–018. Existing compatible databases need only previously missing migrations.

## Build 60 — Navigation alignment

Separated player navigation from DM Studio at every viewport width; removed legacy duplicate player tabs and centred tablet rail icons/labels.
