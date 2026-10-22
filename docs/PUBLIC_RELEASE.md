# Preparing the first public repository

The README and these guides describe the current Build 60 capabilities and planned direction. Preparing documentation does not itself audit the full repository/history, apply a licence or change GitHub visibility.

## Recommended online-feature policy

Keep the connected feature code in the public project. Support **local-first use with optional cloud setup** in one codebase.

People trying the app can choose Enter Studio without creating an account. People self-hosting shared campaigns can follow [SELF_HOSTING.md](SELF_HOSTING.md) and use their own Supabase instance. Hosted-service access and operating costs remain an instance operator's decision.

Before release, remove inherited production defaults from fork-oriented example configuration. Public source must not silently position the maintainer's live database as a shared development service. This is a configuration/release-preparation requirement, not a reason to remove cloud functionality from the codebase.

The current code expects a valid public cloud configuration during the supplied static build; it does not yet define a separate compile-time cloud-disabled build profile. Emptying configuration or deleting cloud modules is not a documented safe way to produce one. Use the existing local operating mode, and implement/test a proper configuration-disabled mode if desired later.

## Release preparation

1. **Choose and apply a software licence.** AGPL-3.0 is recommended for the stated community/hosted-service goals, subject to dependency compatibility review. The maintainer has not yet adopted it. Add an actual licence file and update README/contribution terms together. Public visibility alone does not grant an open-source licence.
2. **Audit dependency and content licensing.** Preserve Supabase/PDF library notices; identify exact SRD versions and required attribution; document portrait provenance/terms; keep user uploads and third-party books/art separate from the code licence. Publish a concrete asset licence/notice rather than assuming all files share one licence.
3. **Audit the tree and Git history.** Check for secret credentials, session tokens, personal/campaign data, private attachments, database exports and unintended generated files. Ignore rules do not remove already tracked history. Rotate exposed secret credentials before history cleanup where applicable. Publishable keys are a separate configuration concern, not privileged credentials.
4. **Prepare independent example configuration.** Replace live defaults in `cloud-config.json` and `.env.example`, document environment variables, and ensure the matching CSP origin is configured. Test a fresh fork with its own backend and a fresh local-only user.
5. **Publish the preferred editable source and release tooling.** Include the interface source modules/styles, generation scripts, pinned test dependencies and fictional fixtures needed to reproduce the application. The current deployment build alone copies generated HTML and is not that complete workflow. If AGPL is adopted, review corresponding-source obligations for all covered deployed components.
6. **Make CI and contributor setup reproducible.** Remove machine-specific paths from public test runners or document/provision their runtime. Include a clean build/test workflow and review generated output, security hashes, release identity and package contents.
7. **Prepare issue and security intake.** Enable private vulnerability reporting where appropriate; add clear issue expectations and contribution boundaries. No contact details or SLAs should be invented.
8. **Verify the release from a clean checkout.** Use fictional data, local entry, a separate Supabase project, separate DM/player/unrelated accounts and real mobile/tablet testing. Confirm no private fixture data is in the public application.
9. **Publish a named public preview.** Keep delivered features separate from roadmap promises. Preserve the known working baseline and provide additive migration/update steps.

## Repository placement

Place `README.md`, `CONTRIBUTING.md` and `SECURITY.md` at the root of the actual public GitHub repository, alongside the current deployment layout. Place the accompanying files in `docs/`.

If the application lives in a subfolder of a larger source repository, adapt README links, startup commands and deployment-root instructions to that final layout. Do not publish a private development workspace wholesale just to expose the application.

This documentation does not require changing the existing official deployment's backend configuration. Public-fork defaults and the official service's environment settings should be managed deliberately and independently.
