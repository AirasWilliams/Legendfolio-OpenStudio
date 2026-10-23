# Build 62 — Public performance and stability update

24 October 2026. This patch brings the performance fixes verified in the private Build 65 into the existing public preview. It does not include the private build's newer gameplay features.

- Reduced repeated artwork copies across character snapshots, undo/redo and campaign storage.
- Compact local saves keep repeated artwork once while preserving character data, all existing history states and campaign recovery.
- Rapid edits coalesce into fewer writes, with one local save in flight. Campaign switches flush pending changes first.
- Startup loads one campaign library rather than a duplicate current-character history.
- Unchanged portrait images/backgrounds are retained, and repeated presentation refreshes coalesce into one animation frame.
- Installation caches five essential shell files. Portraits, PDFs and SDKs cache when used, with bounded background cache writes.
- Build/source archives use canonical text line endings for reproducible output.

The maintainer confirmed reduced RAM usage and smooth editing/mode switching on the private build. This is not a numerical guarantee for every browser or dataset.

## Updating

Close other older Legendfolio tabs/windows, reopen the app, apply the update and restart once. Do not clear site data or uninstall to update. Existing local saves migrate automatically; original storage keys are retained as a pre-upgrade fallback. No new SQL migration is required.

Compact saves use `legendfolio-compact-studio-v1`. Older builds cannot read new compact saves. Before deliberately downgrading, export an All campaigns backup from Build 62. Do not edit simultaneously in an older build after migration. Local records remain specific to their original web address/browser profile.

Offline installations need an initial online launch. Portraits and rulebooks become available offline after first use.

## Public package

Cloud remains disabled by default. Operators can connect their own compatible Supabase project using the existing setup guide and migrations 001–018. The package contains no upstream backend URL/key, private character data or migration 019/Worldcraft implementation.

Original application code remains AGPL-3.0-only. Portrait rights/provenance, SRD attribution, third-party notices and branding policy retain their existing terms. The downloadable distribution includes editable source, corresponding-source ZIP and a SHA-256 checksum.

## Verification

The public test suite covers default-disabled and configured backend builds, exact CSP hashes, blank seed, source/archive completeness, deterministic builds, save migration/failure recovery, undo isolation, character switching, rendering coalescing, lazy cache concurrency, offline entry and update checks. The normal build and all public tests must pass before package publication.
