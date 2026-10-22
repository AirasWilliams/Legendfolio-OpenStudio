# Contributing to Legendfolio

Thanks for helping make a practical tabletop companion. Small, focused improvements are easier to review and protect the workflows players already rely on.

Original application code is AGPL-3.0-only. Submit code you have the right to contribute under that licence. No copyright transfer or separate contributor agreement is assumed. Third-party content retains its applicable terms; see LICENSES.md.

## Useful contributions

- Reproducible reports of layout, interaction or data problems.
- Accessibility and real-device testing.
- Documentation improvements and setup corrections.
- Focused fixes with meaningful regression evidence.
- Rules corrections with an appropriate source and a clear edition distinction.

Discuss new systems, major interface changes and database architecture before implementation. The [roadmap](docs/ROADMAP.md) explains current priorities.

## Report a problem

Use the repository's Issues tab for ordinary bugs. Include:

1. Application build and hosted/self-hosted/local context.
2. Device, browser, viewport/orientation and Interface Level where relevant.
3. Steps, expected result and actual result.
4. Whether the problem happens with fictional/blank data.
5. A redacted screenshot or minimal example, if helpful.

Keep emails, tokens, character secrets, private campaign notes and personal artwork out of public reports. Use [SECURITY.md](SECURITY.md) for vulnerabilities.

## Develop safely

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

These exercise backend configuration, source assembly, deterministic build/archive, cloud helpers and gameplay cores using fictional data. They are not live Supabase acceptance. Historical database/UI suites are not all included; add focused public tests with clear prerequisites as this contributor suite grows. Use `npm start` after building to serve `dist/` locally.

## Review expectations

- Describe the concrete problem and resulting behaviour.
- Keep scope narrow and include appropriate verification.
- Exercise phone, both tablet orientations and desktop for layout changes, including intermediate breakpoint widths.
- For navigation, verify visible destinations, alignment, focus and selection after rerenders and resizing.
- For shared state, test the owner, approved member, pending member and unrelated account as relevant.
- Cover stale revisions, interrupted operations, retry IDs and account/campaign switches where affected.
- Keep database changes additive and compatible with existing clients when possible.
- Preserve private information boundaries and existing character data.
- Keep roadmap capabilities separate from delivered behaviour in descriptions and documentation.

Do not submit copied commercial rulebook/adventure text, maps or artwork without appropriate redistribution permission. Code licensing and content licensing are separate.

The maintainer decides the official roadmap and accepts contributions after review. A proposed change does not imply a release date or support commitment.
