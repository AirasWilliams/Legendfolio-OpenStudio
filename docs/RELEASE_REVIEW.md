# Build 61 review

23 October 2026. This report describes local verification of the public package, not deployment to GitHub/Vercel or acceptance of a new hosted Supabase instance.

## Source and package boundaries

The public tree was created from an explicit source/asset allowlist. It contains no private development workspace, Git history, character PDFs, paid-book text dumps, personal backdrop, database dump, local environment file or production backend defaults. A targeted text scan checked known original deployment identifiers, personal paths/character phrases and secret-shaped values. This is an export audit, not a claim that an existing remote repository's history has been audited.

All seven gameplay engines and all 18 existing SQL migrations were compared byte-for-byte with the working baseline. Application assembly and packaging changed; character/campaign ownership rules did not. Portrait checksums/provenance, exact SRD attribution and dependency notices are included. The maintainer explicitly authorised AGPL-3.0-only for original code and CC BY 4.0 for portrait rights held; branding remains separate.

## Build and automated checks

The included Node-only tests cover optional/default-disabled configuration, managed/custom HTTPS origins, legacy anon keys, privileged-key rejection, malformed/partial configuration, disabled/invalid/configured startup, matching script hashes, blank seed, source archive contents, deterministic output, asset checksums, migration presence, documentation links, cloud helpers and gameplay-core behaviour.

Real browser inspection found a Windows newline-normalisation problem in the first source-build implementation: CSP hashes matched raw files but not the browser's normalised script text. The builder now emits LF-normalised HTML and places UTF-8 metadata before the CSP. A dedicated regression check covers both details.

The generated source archive is extracted into a clean directory and rebuilt independently, verifying that the release does not need the private maintainer workspace. ZIP integrity, config defaults, release/cache identity and complete source inclusion are checked before packaging.

## Actual browser workflow

The clean public app was served on localhost. Its Main Menu displayed local entry and online setup without an upstream account form. The setup dialog, local entry, launch update check, installation dismissal, appearance setup, Hub, local campaign/character creation, deferred Interface Level, all seven player destinations and Hub-to-DM launch were exercised through the interface. About displayed the software/content notices and source-download link.

Player navigation/layout was measured at 320, 390, 699, 700, 820, 1072, 1199, 1200, 1920 and 3840 CSS pixels. It retained exactly seven primary destinations with centred icons and no page-level horizontal overflow. DM layouts were measured at nine phone/tablet/desktop widths, retaining player-navigation isolation and no horizontal overflow. These are browser viewport checks, not a claim of hardware testing on every device.

## Remaining deployment acceptance

An operator must configure their own backend, apply only missing migrations, verify email/redirects, and test separate DM/player/unrelated accounts. No new migration was introduced for this public packaging release. Provider limits, real-device installed-PWA behaviour, fresh-host security headers and any existing Git history require operator review. No live production configuration, campaigns or remote repository visibility was changed here.

WORLD/Worldcraft tabletop, token movement, fog/vision and Discord are not shipped by this release.
