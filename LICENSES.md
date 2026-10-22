# Licensing and attribution

## Original application code — AGPL-3.0-only

Copyright (C) 2026 Airas Williams and Legendfolio contributors.

Original application source, build scripts and tests in this release are licensed under the GNU Affero General Public License version 3.0 only. The complete text is in [LICENSE](LICENSE). This software is provided without warranty as described in that licence.

The deployed application's About screen links to a downloadable corresponding-source archive. Each build generates that archive from the included preferred editable source, build scripts, migrations, tests, dependencies, assets and notices. Runtime account/campaign data and private operator credentials are not source-archive inputs.

## Bundled character portraits — CC BY 4.0

The portrait gallery's `.webp` images and original catalogue/provenance metadata are made available by Airas Williams under Creative Commons Attribution 4.0 International **to the extent the licensor holds applicable rights**. AI-generated material may not attract copyright protection in every jurisdiction; no exclusive copyright or guarantee of third-party clearance is asserted for otherwise unprotectable output.

Suggested credit: “Legendfolio portrait gallery — Airas Williams / Legendfolio contributors; AI-generated using OpenAI image generation and prepared for Legendfolio; CC BY 4.0 where applicable. Changes: [describe your modifications].”

Retain the attribution, licence reference and modification notice required by the licence. [CC BY 4.0 text](licenses/CC-BY-4.0.txt). [Portrait provenance and checksums](portraits/PROVENANCE.json). The statement above records the known generation/preparation method; it does not claim a human artist created every image or that a legal clearance review has been completed.

## SRD rules content — CC BY 4.0

This work includes material taken from the System Reference Document 5.1 (“SRD 5.1”) by Wizards of the Coast LLC and available at https://dnd.wizards.com/resources/systems-reference-document. The SRD 5.1 is licensed under the Creative Commons Attribution 4.0 International License available at https://creativecommons.org/licenses/by/4.0/legalcode.

This work includes material from the System Reference Document 5.2.1 (“SRD 5.2.1”) by Wizards of the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the Creative Commons Attribution 4.0 International License, available at https://creativecommons.org/licenses/by/4.0/legalcode.

`rules/srd-2014.pdf` is the SRD 5.1 reference; `rules/srd-2024.pdf` is the SRD 5.2.1 reference. Their legal pages are retained. `src/data/rules-library.json` contains extracted/indexed rule and spell material adapted from those sources; extraction, indexing and presentation can introduce errors, so compare the included source PDFs when a rule is uncertain. That adapted content remains under CC BY 4.0.

Commercial adventures, setting books, private attachments, personal character PDFs and source-book text dumps are not included in this public release. Campaign-specific compatibility controls do not grant permission to redistribute those books or official artwork.

## Third-party software

- **Supabase JavaScript client 2.117.3:** bundled distribution and notice in `vendor/`; preserve [SUPABASE-LICENSE.txt](vendor/SUPABASE-LICENSE.txt). Package origin/integrity metadata: [provenance.json](vendor/provenance.json).
- **pdf-lib 1.17.1:** bundled distribution with its [MIT notice](vendor/PDF-LIB-LICENSE.md).
- **PDF.js 4.10.38:** loaded from cdnjs for PDF import when needed, not included as an original Legendfolio component. PDF.js is distributed under Apache-2.0 by its authors; retain applicable notices when redistributing a vendored copy. Upstream: https://github.com/mozilla/pdf.js/tree/v4.10.38 .
- **Licence texts:** AGPL-3.0-only and CC BY 4.0 texts are reproduced from the SPDX licence-list-data repository. Authoritative publishers: https://www.gnu.org/licenses/agpl-3.0.html and https://creativecommons.org/licenses/by/4.0/ . Text source: https://github.com/spdx/license-list-data .

Third-party software retains its own copyright and licence. Applying AGPL to original Legendfolio code does not relicense those components.

## Branding and user content

See [BRANDING.md](BRANDING.md) for the name/logo policy. User-uploaded artwork, personal characters and campaign records are not licensed to the public merely because they are opened in this application. Their owners retain applicable rights.
