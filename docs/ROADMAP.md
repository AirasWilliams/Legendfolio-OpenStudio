# Legendfolio roadmap

This roadmap describes direction, not guaranteed delivery dates. Build 61 is the public SMART PLAY baseline. Planned features below should not be advertised as available in that build.

## Available foundation

- Local-first character records, PDF import/review and portable backups.
- Guided character proposals, ability allocation/rolling and bundled/uploaded portraits.
- Local campaign libraries, DM notebook and guided campaign foundations.
- Optional Supabase accounts, personal cloud characters and builder drafts.
- Campaign invites, membership, character reviews and approved snapshots.
- Connected party status, encounters/initiative, sessions/activity and campaign dice.
- Responsive navigation, user profiles, appearance controls, Interface Levels, PWA launch/update flow and campaign sheet templates.

These capabilities have different local/shared scopes; the [README](../README.md#current-limits) explains the current boundaries.

## Next major programme: Live Campaign Tabletop

The player enters **WORLD**. The DM prepares and controls the experience in **Worldcraft Studio**.

### Worldcraft Studio

Campaign-scoped scene construction and linking for maps, locations, encounters, NPCs, approved PCs, tokens and related world content. A scene browser, central canvas and contextual inspector should keep preparation focused. DM preparation remains private until explicitly published.

### WORLD

The player's authorised live scene, permitted tokens, current situation/turn, requests and relevant character actions. Players should understand what is happening and what they can do without having to navigate a second disconnected campaign system.

### Maps, tokens and movement

- DM-published scenes and controlled scene transitions.
- Map/grid calibration, selection, pan/zoom and validated token movement.
- Automatic token preparation from a character portrait suggested using recorded ancestry and selected appearance preferences.
- Bundled portrait selection, personal uploads and adjustable token crop.
- Character portrait updates reflected in linked campaign/placed tokens.
- Token control tied to actual campaign membership and character approval.
- Shared scene coordinates across desktop, both tablet orientations, mobile and the planned Discord client.

### Fog and automatic character vision

- Optional DM-controlled exploration fog and manual reveal/conceal tools.
- Movement-driven reveal using authorised scene data and character vision.
- Approved darkvision range, bright/dim/dark areas, light sources and wall/door occlusion.
- Per-character sight, explored-map memory and DM-controlled information sharing.
- A DM preview through a selected character's view.
- Protected unrevealed map/media delivery; visual overlays alone are insufficient.

Additional special senses and richer lighting effects follow in explicitly defined increments. Imported/custom traits that cannot be resolved confidently require review.

### Beginner-friendly targeting

Preview requirements, permitted target information, necessary movement, resource costs and what remains before confirmation. Use the campaign's real Action/Bonus/Reaction/movement or custom points system. Beginner explanations become more compact at Intermediate and Veteran levels while sharing the same backend checks.

### Responsive play

- Desktop: use available width for the table and simultaneous practical tools.
- Tablet: retain a full side rail and contextual panels suited to both orientations.
- Phone: map-first interaction, permanent Actions access and contextual strips for scene and character tools.

The agreed mobile consolidation ships with tabletop so its navigation is tested against the actual play experience.

### Discord Activity

A Discord Activity will be another client of the same campaign backend. Account linking, campaign admission, approved characters, authorised movement and dice must use the same services as web/PWA clients. Discord channel presence will not grant campaign membership or DM authority.

### Reliability and active review

Build the programme in small reviewed increments: layout/prototypes, shared scenes/tokens, fog/vision, targeting/actions and Discord. Review actual browser/device behaviour, existing workflow regressions, permission boundaries, concurrent edits, retries and reconnection throughout development.

## Further work

- Complete rules-aware character materialisation, eligibility and class progression.
- DM-awarded XP/level monitoring and a level-up experience adapted to Interface Level.
- Broader shared quests, discoveries, rewards and worldbuilding workflows.
- Richer authorised movement, terrain, additional senses and lighting.
- Reusable campaign modules and custom campaign support with clear content provenance.

Additional game systems and campaign books require their own mechanics/content work. A custom text field is not a complete rules engine, and compatibility tools do not grant redistribution rights to third-party books or art.

## Architectural commitments

1. The player owns their personal character.
2. The DM administers the campaign.
3. The backend maintains committed shared state.
4. Permissions govern what each participant can see and do.
5. Private discoveries and DM information remain private unless deliberately shared.
6. Presentation, automation and Interface Level do not override those boundaries.
