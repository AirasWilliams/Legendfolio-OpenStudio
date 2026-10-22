<p align="center">
  <img src="legendfolio-favicon-v2.svg" width="64" height="64" alt="Legendfolio open-book emblem">
</p>

# Legendfolio Open Studio

**Your character. Your campaign. Your next adventure.**

Legendfolio is a local-first tabletop roleplaying companion for players and Dungeon Masters. It brings character records, guided creation, campaign organisation and connected gameplay tools into one responsive studio.

It began as a personal character tracker and is growing into a shared play environment. The aim is straightforward: help players understand their options, reduce bookkeeping and give DMs practical control over their campaigns.

**Current application: Build 61 · Public Preview**  
**Status: actively developed public preview**  
**Code: AGPL-3.0-only · Portraits: CC BY 4.0 where applicable**  
**Rules foundations: D&D 5e (2014) and revised 2024 rules, with custom proposals**

[Open Legendfolio](https://legendfolio.vercel.app/) · [Run locally](#run-locally) · [Set up your own cloud deployment](docs/SELF_HOSTING.md) · [Roadmap](docs/ROADMAP.md)

> WORLD, Worldcraft Studio, playable maps, tokens, fog of war, automatic vision and Discord Activities are planned. They are not included in Build 61.

## Contents

- [What Legendfolio does](#what-legendfolio-does)
- [Start as a player](#start-as-a-player)
- [Start as a Dungeon Master](#start-as-a-dungeon-master)
- [Local and connected use](#local-and-connected-use)
- [Characters, approvals and campaign authority](#characters-approvals-and-campaign-authority)
- [Imports, exports and backups](#imports-exports-and-backups)
- [Run locally](#run-locally)
- [Deploy your own instance](#deploy-your-own-instance)
- [Development and contribution](#development-and-contribution)
- [Current limits](#current-limits)
- [Privacy and security](#privacy-and-security)
- [Licensing, attribution and artwork](#licensing-attribution-and-artwork)

## What Legendfolio does

### Character Studio

- Maintain character identity, ability scores, skills, saving throws, attacks, spells, equipment, artwork, relationships and notes.
- Use Actions tools for combat, exploration and roleplay, with access to health, conditions, resources and dice.
- Import information from digitally filled character-sheet PDFs, review the extracted information and retain additional unmapped material where supported.
- Create characters through an eight-step guided pathway: foundation, class, ancestry, background, abilities, training and gear, identity, and review.
- Choose standard array, 27-point point buy or personal 4d6-drop-lowest ability rolls, with recorded roll history and score assignment.
- Browse 112 bundled portraits across 11 supported ancestries, or upload personal character artwork.
- Keep characters organised across multiple local campaigns, with independent campaign records and progress.
- Save portable character backups, prepare files for DM review and load approved character files.

**Guided creation produces a reviewable character proposal.** It is not yet a complete class-progression or rules-eligibility engine. Features, origin increases, HP/AC, equipment and spell choices can require source review and DM adjudication. Personal ability-score rolls are generated in the browser and are not server-verified campaign dice.

### DM Studio

- Build local or connected campaigns through a guided foundation, world, table-rules, session-zero and review pathway.
- Organise a campaign notebook: party roster, sessions and recaps, NPCs and relationships, quests, timelines, rewards, rules, decisions, factions, downtime, research, private notes and custom content.
- Use campaign-specific academic tools for Strixhaven-style play.
- Invite accounts to connected campaigns and review character submissions and protected changes.
- Inspect approved connected character sheets in a read-only view.
- Run connected encounters with manual or server-generated initiative, turn order, rounds and a shared current scene.
- View permitted connected party HP, temporary HP, conditions and concentration; configure what other players may see.
- Receive server-generated campaign dice results in a DM roll log.
- Configure a clean fillable campaign PDF and field mappings for character-sheet export.

**Local notebook entries and connected records have distinct scopes.** A locally entered quest, NPC, calendar note or reward is not automatically published to the party. Shared features use their explicit connected workflows; complete worldbuilding synchronisation is still being developed.

### SMART PLAY experience

- Main Menu with sign-in, account creation, recovery and an explicit **Enter Studio** option for local use.
- Launch update checks and an installation offer where supported.
- Appearance setup with presets, hue, pastel intensity, metallic finish, light/dark schemes and live preview.
- Beginner, Intermediate and Veteran **Interface Levels**, chosen after selecting a character and adjustable in Settings.
- User profiles with a display name, image and short bio, separate from character identity.
- Desktop icon navigation, a tablet side rail and swipeable phone navigation.
- A revealing utilities strip for the Hub, Sheet Fields, Artwork, character switching, Backup & Export, and Settings.
- DM Studio launched from the Hub.

Interface Level changes guidance and presentation. It does not grant campaign permissions or certify a character build.

## Start as a player

1. Open the hosted application or a local instance.
2. Sign in for connected features, or choose **Enter Studio** to work locally.
3. Choose your appearance, then open the Studio Hub.
4. Launch Character Studio to create/import a character, or open Saved Characters.
5. Review the character and choose an Interface Level.
6. For connected play, save a cloud character, use the campaign's invite workflow and submit it for DM review.
7. After approval, use the connected campaign tools for the permitted party view, shared encounter context and campaign dice.

The character sheet remains your working record. Make a complete backup before substantial edits or moving to another browser/device.

## Start as a Dungeon Master

1. Open the Hub and select **Launch DM Studio**.
2. Create or select a campaign. Choose a device campaign for a local notebook, or a connected campaign for shared features.
3. For connected play, sign in to the account that owns the campaign, create an invite and review submitted characters.
4. Configure table rules and party visibility. Use the connected roster and encounter tools for live play.
5. Publish shared session information through its dedicated workflow. Keep private preparation in the appropriate DM-only or device-notebook area.
6. Optionally publish a clean fillable sheet template and mappings for approved members to populate.

Selecting DM Studio changes the interface. Cloud campaign authority comes from the authenticated campaign owner and backend permissions.

## Local and connected use

Legendfolio keeps both modes in the same application. Cloud services are optional for personal use and required for shared online features.

| Capability | Local use | Connected use |
| --- | --- | --- |
| Character editing, artwork, notes and guided creation | Yes | Yes; cloud drafts/saves are explicit workflows |
| Device campaigns and DM notebook | Yes | Remain local unless a specific shared workflow is used |
| Portable character files and manual DM review files | Yes | Also available |
| Account profile and cloud character library | Local profile only | Account-scoped profile and character storage |
| Invitations, membership and server-backed character approval | No | Yes |
| Shared party health and connected encounters | No | Yes, subject to membership and visibility rules |
| Private dice practice | Yes | Yes |
| Server-generated campaign dice and DM roll log | No | Yes |
| Campaign PDF template | Device-scoped template | Owner-published template for approved members |
| Shared WORLD/tabletop and Discord Activity | Planned | Planned |

### Local-first does not mean every feature is offline

Local mode pauses account/campaign requests and session hydration until sign-in is deliberately enabled. The application can still check for app updates. External rules links and first-time PDF.js loading require internet access.

After the application and its bundled assets are cached, supported local workflows remain available offline. Cloud operations require connectivity. Local autosave is separate from explicitly backing up a character to a cloud account.

### Hosted service and self-hosting

The official hosted app and a self-hosted instance can use the same software while operating against different databases. Accounts, invitations and campaigns belong to the backend serving that instance; they are not automatically shared between installations.

The public build disables online features by default and includes no upstream backend configuration. Hosts configure their own compatible Supabase project before enabling connected use; players then sign in normally. See the [self-hosting guide](docs/SELF_HOSTING.md).

The project vision keeps core gameplay free of subscription feature gates. Operating a hosted instance can still incur hosting, database, email and storage costs.

## Characters, approvals and campaign authority

Legendfolio distinguishes three important records:

- **Personal character:** the player's own persistent record.
- **Campaign-approved character:** the version accepted into a particular campaign.
- **Active gameplay status:** live information such as HP and conditions, handled by the relevant connected service.

Protected character changes follow the DM review workflow. Editing a personal record does not automatically replace an approved campaign snapshot. Approval does not transfer ownership of the personal character to the DM.

Connected operations use authenticated permissions, revision checks and retry protection where implemented. An interrupted operation may be pending or unconfirmed; use its recovery/retry controls rather than assuming that a failed response means nothing was committed.

Current connected party/encounter updates use visible-app polling, generally every five seconds. DM dice-log checks use a longer interval, currently fifteen seconds. These are not WebSocket push feeds, email alerts or guaranteed background notifications. The tabletop roadmap introduces a more responsive shared-state delivery layer.

## Imports, exports and backups

### Import a character PDF

Digitally completed, fillable sheets offer the best input. Review the import before applying it, especially for unfamiliar/custom templates. A PDF field's label, encoding or layout can limit what can be extracted.

Scanned/image-only PDFs are not a guaranteed import path, and this release does not include a general OCR service. Importing text is not equivalent to validating the character's mechanics.

### Backup & Export

- **Cloud:** explicitly back up a character to the signed-in account or restore a cloud character.
- **Local:** download a complete character backup, preview a restored backup and create a separate local character.
- **Character sheet:** populate a configured clean fillable campaign PDF, or use the labelled Legendfolio summary when no template is available.

**A character-sheet PDF is not a complete restorable backup.** Use the complete character backup for artwork, notes, inventory and other retained record data. Keep a campaign-library backup when moving the whole local collection.

Portable restoration preserves independent campaign approval by creating a separate character and removing cloud bindings/approval markers from the imported copy.

Campaign templates support mapped form fields and a source PDF up to 2 MB. The DM must provide an actually clean blank sheet; clearing form values is not a general PDF-redaction service. Export warnings identify unsupported or overlong mapped values.

### Browser storage and installation

Browser-local data belongs to the site's origin and browser profile. Changing hostname, port, browser or device can open a different local library. Clearing site data, using a temporary/private session or removing application storage can remove local records.

Install the PWA through the supported browser's installation/Add to Home Screen flow. Installation is optional and does not replace backups. Use the same trusted application address consistently.

When a new build is available, use the app's update controls after finishing current operations and backing up important records. If update verification fails, the saved build can remain usable; reconnect and check again later.

## Run locally

For the release/deployment layout, run commands from the folder containing `index.html` and `server.py`. GitHub's **Code → Download ZIP** is sufficient to obtain the files; a Git installation is not required for local play.

### Windows launcher

Install Python 3 if it is not already available, then open **Start Legendfolio.cmd**. The included helper starts a server bound to `127.0.0.1` and opens:

```text
http://127.0.0.1:8766/index.html
```

### Other platforms or manual startup

Run:

```sh
python3 server.py
```

On systems where Python is named `python`, use `python server.py` instead. The server listens locally on port 8766. Choose **Enter Studio** for local use.

Serve the application over localhost or HTTPS instead of double-clicking `index.html`: account access, installation and browser security features depend on the served environment. The development server is not a public production server.

## Deploy your own instance

The current release is a static web application with an optional Supabase backend. Vercel configuration is included.

| Requirement | Local personal use | Your own cloud deployment |
| --- | --- | --- |
| Modern browser | Required | Required |
| Python 3 | For the included local launcher | Optional for local testing |
| Node.js 22 or later | Not needed for the Python launcher | Needed for the supplied static build |
| Supabase project | Not needed in local mode | Required for connected features |
| HTTPS hosting | Not needed on localhost | Required for the deployed application |

The source build command is:

```sh
node scripts/build.mjs
```

It assembles the included source, validates optional backend configuration, generates matching security hashes/network policy and writes deployable files to `dist/`. It also updates the prebuilt root application and creates a downloadable corresponding-source archive. It does not provision Supabase, apply SQL migrations or start a server. No npm dependency installation is required for this Node-only build.

Run `npm start` after building to serve `dist/` locally. The Python launcher can serve the prebuilt root application without Node.

For a fresh connected instance:

1. Create your own Supabase project.
2. Apply the supplied migrations **001 through 018, in filename order, once each**.
3. Configure your public project URL/key and your deployed site address.
4. Configure authentication redirects. The build derives its allowed backend network origin from your configuration.
5. Build/deploy, then test separate DM and player accounts.

Follow the [complete self-hosting guide](docs/SELF_HOSTING.md) for exact configuration, CSP, redirects, migration order and acceptance checks. The guide takes precedence over older release-specific deployment notes that refer to the original maintainer's installation.

## Development and contribution

Legendfolio follows a maintainer-directed development process. Reproducible bug reports, accessibility and device-testing feedback, documentation corrections and suggestions are welcome through Issues. The maintainer and internal team investigate reports and implement official changes.

**External pull requests are not accepted, and forked repositories are not merged into the official codebase.** Independent forks, modifications and redistribution remain permitted under AGPL-3.0-only and the applicable content licences. This governance policy does not restrict those licence rights. Read [CONTRIBUTING.md](CONTRIBUTING.md) for feedback, development and fork guidance, and [SECURITY.md](SECURITY.md) for private vulnerability reporting.

### Current deployment layout

```text
src/                       Preferred editable interface/source/data
index.html                 Generated, prebuilt local application
cloud_core.js              Cloud data/configuration helpers used by the build
cloud-config.json          Browser-readable backend configuration
scripts/build.mjs          Source assembly, config validation, CSP and source ZIP
supabase/migrations/       Ordered database changes
vendor/                    Bundled libraries and their notices
rules/                     Bundled SRD reference PDFs
portraits/                 Bundled portrait files and catalogue
manifest.webmanifest       PWA metadata
sw.js                      Service worker and app cache behaviour
release.json               Build identity used by the update checker
docs/                      Public setup, roadmap and release guidance
```

The preferred editable source is included in `src/`: the HTML template, styles, core modules, feature modules and blank seed/rule data. `src/build-manifest.json` records assembly order. Rebuild with `npm run build`; security hashes, release identity, service-worker identity and a corresponding-source ZIP are generated together. No private character PDF, personal backdrop or external maintainer workspace is required.

Run `npm test` for the included configuration, build, archive, cloud-helper and gameplay-core tests. These local tests do not replace two-account acceptance against your own Supabase deployment. The full historical QA workspace is not included wholesale; its review boundaries are described in the release report.

The public roadmap and public-release preparation steps are in [docs/ROADMAP.md](docs/ROADMAP.md) and [docs/PUBLIC_RELEASE.md](docs/PUBLIC_RELEASE.md).

## Current limits

- Guided Quickbuild records a proposal; complete rules-aware character materialisation and level progression are still being developed.
- The current rules foundations focus on 5e. Custom proposals do not imply complete support for every TTRPG rules engine.
- Spell slots, action economy and several resources remain local; they are not all part of the shared party-health service.
- Connected encounters currently retain one current encounter per campaign and a limited recent history. Preparing a replacement is not an encounter archive.
- Local notebook worldbuilding is not universally synchronised or published.
- Browser/PWA emulation checks do not replace testing on every physical device/browser combination.
- There is no in-app AI character/portrait generation service in this build.
- Live maps, linked playable tokens, secure exploration fog, automatic character vision, guided targeting costs, XP/level-up automation and Discord integration are roadmap features.

For reproducible problems, use the repository's Issues tab and include the build number, device/browser, viewport or orientation, steps and expected/actual behaviour. Use fictional character data where possible. Report vulnerabilities through the [security process](SECURITY.md), not a public issue containing private data.

## Privacy and security

Personal characters belong to their account owners. DMs administer their campaigns. Backend permissions determine access to connected information. A frontend role switch, Interface Level or local preference cannot grant cloud DM authority.

Cloud backups are explicit operations. The complete personal record you choose to upload can include artwork and private character notes. Character submissions intentionally send the submitted record to authorised DM reviewers. Review what you submit; server-limited public party summaries are a different view.

An account profile is separate from a character portrait. Private visual-dice practice history is kept locally and is excluded from character exports/cloud submissions by that workflow. Connected campaign rolls are intentionally recorded for authorised DM review.

Supabase publishable/legacy anon keys are browser configuration. Secret/service-role keys and database credentials must never appear in the frontend or public repository. Access protection depends on authentication, Row Level Security and the supplied validated operations. [Supabase security guidance](https://supabase.com/docs/guides/database/secure-data)

Self-hosters operate their own instance and are responsible for its access settings, backups, retention, email delivery and privacy practices. This README is not a hosted-service privacy policy or a guarantee of end-to-end encryption.

## Licensing, attribution and artwork

Original application code is licensed under **GNU AGPL version 3.0 only**. See [LICENSE](LICENSE). Modified hosted versions must offer corresponding source to their interacting users under the licence's terms. Each build includes a source download linked from About. AGPL permits commercial use and does not imply every hosted service is free of operating costs.

Bundled portraits are available under **CC BY 4.0 to the extent applicable rights are held**, with AI-generation/preparation provenance. SRD content and third-party libraries retain their own terms. User uploads are separate. Read [LICENSES.md](LICENSES.md) for exact SRD attribution, library notices, portrait credit and qualifications, and [BRANDING.md](BRANDING.md) for the name/logo policy. Campaign-specific compatibility tools do not grant redistribution rights to commercial campaign books or official artwork.

Legendfolio is an independent project. It is not an official Wizards of the Coast, D&D Beyond, Discord, Supabase or Vercel product. Referenced names and marks belong to their respective owners.

---

**The DM creates the experience. Legendfolio brings it to life. The player plays.**
