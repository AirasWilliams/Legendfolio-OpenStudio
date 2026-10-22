# Feedback and development policy

Legendfolio follows a maintainer-directed development process. The maintainer and internal team set the official roadmap, implement changes, review them and publish releases.

**External pull requests are not accepted.** This applies to code, documentation, tests and assets. Pull requests may be closed without merging; forked repositories are not merged into the official codebase. Opening an issue or receiving a response does not authorise an external pull request or promise implementation.

## Welcome feedback

- Reproducible reports of layout, interaction or data problems.
- Accessibility and real-device testing results.
- Documentation errors and setup corrections reported through Issues.
- Feature suggestions and minimal examples using fictional data.
- Rules corrections with an appropriate source and a clear edition distinction.

Use Issues for feedback and suggestions. The internal team investigates reports and implements official changes. The [roadmap](docs/ROADMAP.md) explains current priorities; a report or suggestion does not imply a release date or support commitment.

## Open-source rights and independent forks

Original application code is licensed under AGPL-3.0-only. Independent forks, modifications, use and redistribution remain permitted under that licence. This official contribution policy does not add restrictions to the licence or require permission to exercise its rights.

Fork maintainers may run their own contribution processes. Preserve required notices, provide corresponding source where required and clearly identify unofficial builds. Third-party content and branding have separate terms; see [LICENSES.md](LICENSES.md) and [BRANDING.md](BRANDING.md).

## Report a problem

Use the repository's Issues tab for ordinary bugs. Include:

1. Application build and hosted/self-hosted/local context.
2. Device, browser, viewport/orientation and Interface Level where relevant.
3. Steps, expected result and actual result.
4. Whether the problem happens with fictional/blank data.
5. A redacted screenshot or minimal example, if helpful.

Keep emails, tokens, character secrets, private campaign notes and personal artwork out of public reports. Use [SECURITY.md](SECURITY.md) for vulnerabilities.

## Internal development and independent forks

Use your own test backend and fictional records. Never develop against the maintainer's production database by inheriting its browser configuration. Back up important local records before testing imports or migrations.

The current deployment build is:

```sh
node scripts/build.mjs
```

It assembles `src/`, generates security hashes/release metadata and writes `dist/`, the prebuilt local application and a corresponding-source archive. Node.js 22 or later is required; no npm dependency download is needed. Do not hand-edit generated HTML or release metadata.

Run the included reproducible public checks with:

```sh
npm test
```

These exercise backend configuration, source assembly, deterministic build/archive, cloud helpers and gameplay cores using fictional data. They are not live Supabase acceptance. Historical database/UI suites are not all included. Internal developers and independent fork maintainers should add focused tests with clear prerequisites for their changes. Use `npm start` after building to serve `dist/` locally.

## Review practices for internal changes and independent forks

- Describe the concrete problem and resulting behaviour.
- Keep scope narrow and include appropriate verification.
- Exercise phone, both tablet orientations and desktop for layout changes, including intermediate breakpoint widths.
- For navigation, verify visible destinations, alignment, focus and selection after rerenders and resizing.
- For shared state, test the owner, approved member, pending member and unrelated account as relevant.
- Cover stale revisions, interrupted operations, retry IDs and account/campaign switches where affected.
- Keep database changes additive and compatible with existing clients when possible.
- Preserve private information boundaries and existing character data.
- Keep roadmap capabilities separate from delivered behaviour in descriptions and documentation.

Do not include copied commercial rulebook/adventure text, maps or artwork without appropriate redistribution permission. Code licensing and content licensing are separate.

The practices above describe responsible development; they do not constitute an invitation to submit pull requests to the official repository. Report security concerns privately through [SECURITY.md](SECURITY.md).
