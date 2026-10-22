# Contributing to Legendfolio

Thanks for helping make a practical tabletop companion. Small, focused improvements are easier to review and protect the workflows players already rely on.

The project's software licence is not yet adopted in this release. Confirm the repository's current licensing/contribution terms before submitting code; do not assume a copyright transfer or contributor agreement exists. Third-party content must retain its applicable terms.

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

It copies the existing embedded application and validates public configuration. It does not regenerate interface code, CSP hashes or migration state. Source-generation and full regression tooling may be separate from a deployment archive; identify the actual source tree and release workflow with the maintainer before making a broad change.

Where `tests/cloud_core.test.cjs` is present, its focused cloud-helper checks can run with:

```sh
node tests/cloud_core.test.cjs
```

That is a mocked client/unit suite, not a live backend acceptance test. Some database tests currently expect maintainer-workspace paths and a separately provisioned PGlite test runtime; a deployment archive is not a complete reproducible test harness. Document test prerequisites instead of weakening checks to make an incomplete setup pass.

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
