# Monetization Plan

Status: Post-v1 strategy. This is not part of the initial v1 release build.

Last updated: 2026-03-28

## Why This Exists

Tap Ten now has a playable core loop, a native pack browser, and a complete 12-category starter library. The project brief still keeps monetization out of v1, but the repo needs a documented plan for how monetization should work once the free base game is stable.

This document captures the current recommendation:

- Keep the core game clean and free at first.
- Monetize with additive permanent pack unlocks, not gameplay friction.
- Avoid ads in or around live round flow.
- Defer subscriptions until the app proves repeat usage and a real ongoing content cadence.

## Current Starting Point

- The repo currently ships 12 bundled category packs with 12 questions each, for 144 questions total.
- One pack roughly maps to one category today.
- A default full game can consume about 10 questions across both teams.
- That makes the existing library a strong free starter base, but not yet a strong recurring-content catalog for a subscription business.

Implication:

- If the current bundled library ships free before monetization is added, it should remain free permanently.
- Paid content should be clearly additive through future expansion packs and bundles.

## Locked Free Starter Library

The permanent free starter library is the full currently shipped 12-pack catalog:

- Everyday Life
- Food & Drink
- Film & TV
- Music
- Sport
- Geography
- History
- Science
- Technology
- Travel
- Work & School
- Pop Culture & Trends

This is the free base game. It should stay free permanently if it reaches users before monetization ships.

Commercial implication:

- future paid content must be sold as additive premium expansions
- store copy should describe the paid catalog as "more packs" rather than "unlock the real game"
- no currently shipped free category pack should be reclassified as paid later

## Market Snapshot

### What adjacent apps are doing

- [Heads Up!](https://apps.apple.com/us/app/heads-up/id623592465) uses a durable permanent-content model: paid upfront plus additional deck purchases.
- [Guess the Word! Charades Game](https://apps.apple.com/us/app/guess-the-word-charades-game/id1269130452) uses a cleaner freemium model: free download, no-ads positioning, low-price permanent packs, and optional lifetime unlocks.
- [Family Feud Live!](https://apps.apple.com/us/app/family-feud-live/id1195092555) uses a much more aggressive live-service model with recurring VIP membership and currency-style purchases. That shape fits synchronous meta systems better than Tap Ten's current single-device party flow.

### Platform and monetization signals

- Apple's business-model guidance says freemium works best when the app is updated continually and warns that poor-quality ads can reduce engagement and retention: [App Store business models](https://developer.apple.com/app-store/business-models/).
- Apple's in-app purchase guidance supports permanent unlocks, promoted IAP merchandising, and Family Sharing-ready catalog design for eligible products:
  - [In-App Purchase overview](https://developer.apple.com/in-app-purchase/)
  - [Promote In-App Purchases](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/promote-in-app-purchases/)
- Appfigures' 2025 mobile games trends report notes that subscriptions are still used by fewer than 20% of the top 1,000 highest-grossing games: [2025 Mobile Games Trends Report](https://land.appfigures.com/2025-mobile-games-trends-report).
- RevenueCat's 2025 subscription report highlights weaker long-term retention in gaming subscription cohorts, especially on shorter billing periods: [State of Subscription Apps 2025](https://www.revenuecat.com/state-of-subscription-apps-2025/).
- Sensor Tower's 2025 gaming report reinforces that revenue continues to favor games with stronger retention and ongoing merchandising rather than one-off install spikes: [State of Mobile Gaming 2025](https://sensortower.com/state-of-gaming-2025).

## Recommended Model

The recommended first monetization pass is:

- Free base game
- Permanent non-consumable premium pack unlocks
- Premium pack bundles
- Optional full paid-catalog unlock

Not recommended for the first pass:

- Interstitial or banner ads
- Rewarded ads in the active round loop
- Coin/currency systems
- Subscription-first pricing
- Retroactive paywalling of packs that previously shipped free

## Product Decisions

### 1. Keep the launch library free if it ships free

If the current 12-pack starter library reaches users before monetization is added, do not later turn those exact packs into paid content.

Why:

- It creates review risk and trust damage.
- The cleanest commercial message is "the base game is generous; paid packs add more."

### 2. Sell session-complete value

A paid SKU should usually add around 24 to 36 questions minimum, or be bundled to feel equivalent in session value.

Why:

- A single default full game can burn through roughly 10 questions.
- A paid 12-question pack is likely to feel too thin unless it serves a very strong niche.

### 3. Treat content as the product, not power

Tap Ten should sell:

- new themes
- new categories or subcategories
- stronger niche occasions
- better variety for repeat groups

Tap Ten should not sell:

- score boosts
- extra time
- gameplay advantages
- gating of core round flow

### 4. Keep monetization out of live play

Store surfaces should live in Home, Pack Browser, setup, or clearly post-game contexts. They should not interrupt a host during active round management.

## Packaging Standard

For the first monetization pass, a premium storefront SKU should map to session-complete value:

- target value: 24 questions per premium expansion
- target difficulty split: 8 easy / 8 medium / 8 hard across the full 24-question expansion
- implementation may use one 24-question JSON file or two linked 12-question local packs behind one storefront product
- a standalone 12-question paid pack should be avoided unless it serves unusually strong niche demand

## Pricing Ladder

Approved initial ladder:

- 24-question evergreen premium expansion: $2.99
- 24-question seasonal or tentpole premium expansion: $3.99
- Three-expansion launch bundle: $7.99
- Full paid-catalog unlock: do not ship this at the first paid launch; add it only once at least 5 evergreen premium expansions exist, with an initial target price of $14.99

Catalog rules:

- Prefer permanent ownership over temporary access.
- Enable Family Sharing for eligible one-time purchases where it improves value perception.
- Avoid weekly pricing entirely.

## Approved First Premium Slate

These are the approved first paid expansions and their intended packaging:

- After Dark Vol. 1
  - 24 questions
  - evergreen
  - tone: cheeky adult party energy, but not explicit or app-store-risky
  - price: $2.99
- Date Night
  - 24 questions
  - evergreen
  - tone: romance, flirting, relationship habits, couples-night energy
  - price: $2.99
- Office & Icebreakers
  - 24 questions
  - evergreen
  - tone: meetings, presentations, workplace awkwardness, team banter
  - price: $2.99
- Holiday Chaos
  - 24 questions
  - seasonal
  - tone: travel stress, gift drama, family gatherings, party mishaps
  - price: $3.99
  - target launch window: October to November seasonal merchandising window

Approved launch bundle:

- Launch Trio Bundle
  - includes: After Dark Vol. 1, Date Night, Office & Icebreakers
  - price: $7.99

Approved wave-2 candidates after the initial paid launch:

- Family-Friendly Extras
- US Pop Culture / 2020s Trends

Why this slate:

- each concept has a clear purchase occasion
- the three evergreen expansions are broad enough to support a stable first paid launch
- Holiday Chaos gives the catalog a natural seasonal merchandising beat
- the wave-2 candidates extend the catalog without forcing a subscription too early

## Rollout Phases

### Phase 0: Keep v1 free and polished

- Ship the base game without monetization.
- Learn whether groups replay and which categories they prefer.
- Avoid adding pricing friction before the core game is stable enough for recommendation-driven growth.

### Phase 1: Add the pack store

- Add premium pack metadata to the local content model.
- Introduce a native Pack Store using the existing pack browser as the merchandising foundation.
- Unlock bundled local JSON packs with non-consumable IAPs.
- Use the approved launch catalog: After Dark Vol. 1, Date Night, Office & Icebreakers.

### Phase 2: Add merchandising cadence

- Release premium packs in themed drops.
- Use seasonal windows as reacquisition moments.
- Promote important pack and bundle SKUs through App Store merchandising and website/app copy.
- Use Holiday Chaos as the first seasonal premium beat.

## Seasonal Merchandising Plan

### Window 1: Evergreen Paid Launch

Target window:

- first paid launch window after the free base game is stable enough to support merchandising

Launch merchandising focus:

- `After Dark Vol. 1` as the most impulse-friendly single-pack feature
- `Launch Trio Bundle` as the best-value paid callout
- `Date Night` and `Office & Icebreakers` as supporting catalog depth

Promoted IAP candidates:

- `After Dark Vol. 1`
- `Launch Trio Bundle`

Copy rule:

- emphasize additive value: "More packs for game night" rather than "unlock the real game"

### Window 2: October to November Seasonal Push

Target window:

- October to November, led by `Holiday Chaos`

Seasonal merchandising focus:

- `Holiday Chaos` as the seasonal headline SKU
- `Launch Trio Bundle` as the evergreen cross-sell

Promoted IAP candidates:

- `Holiday Chaos`
- `Launch Trio Bundle`

Ownership rule:

- `Holiday Chaos` remains owned permanently after purchase; it is merchandised seasonally, not rented seasonally

### Copy And Creative Rules

App Store and website copy should:

- make it explicit that the 12-pack starter library stays free
- describe paid content as extra themed expansions
- highlight session-ready value such as `24 new questions`
- avoid any implication that active gameplay is interrupted by monetization

Screenshot / website creative priorities:

- one frame that shows the free base game generosity
- one frame that shows the premium expansion shelf
- one frame that highlights the bundle as best value
- one seasonal creative swap for `Holiday Chaos` during the October to November window

### Phase 3: Re-evaluate membership only if the pack business proves out

Only consider a membership if:

- repeat purchase behavior is healthy
- the catalog is deep enough that all-access feels obviously valuable
- the team can maintain a reliable premium content cadence

If a membership is ever added later:

- prefer annual-first pricing
- keep monthly as a secondary option if needed
- do not add a weekly plan
- do not lock the core game behind the subscription

## Metrics And Gates

The first monetization pass needs explicit go / no-go gates. Recommended internal targets:

- install to first completed game: `25%+`
- 30-day return on a different day: `15%+`
- pack browser visit rate among active players: `8%+`
- payer conversion within 90 days of store launch: `3%+`
- average payer spend: `$7+`
- repeat purchase rate within 180 days: `20%+` of payers
- refund rate: `<5%`

### Measurement Stack

Keep measurement narrow and first-party-biased:

- `App Store Connect`
  - source of truth for installs, product sales, proceeds, and refunds
- `Narrow in-app monetization events`
  - source of truth for first game started/completed, pack browser opened, purchase started, purchase completed, and restore completed
- `Debug/local diagnostics`
  - acceptable short-term fallback during development, but not enough alone for a paid launch decision

Implementation rule:

- if monetization ships before a broader analytics system exists, add only the smallest first-party event pipeline needed for the funnel above
- do not add ad-tech style SDK sprawl just to answer basic pack-sales questions

### Go / No-Go Rules

Use these rules for the first paid rollout:

- greenlight continued premium-pack investment if payer conversion, average payer spend, and refund rate all meet target and at least one retention signal is healthy
- hold any subscription discussion unless repeat purchase behavior meets target and at least five evergreen paid expansions exist
- if pack browser visits are weak but the purchase rate from store viewers is healthy, improve merchandising and discovery before changing prices
- if pack browser visits are healthy but purchase conversion misses target, revisit catalog value, copy, and SKU packaging before adding more monetization complexity
- if refund rate exceeds target, treat that as a content-value warning before scaling the paid catalog

Principle:

- prove the pack business before adding a subscription
- prove store discovery before adding more monetization complexity

## Risks And Guardrails

- Do not weaken first-time trust by reclassifying existing free packs as paid later.
- Do not let the store make the free app feel crippled.
- Do not interrupt host-speed round flow with monetization.
- Do not introduce a content cadence promise the team cannot sustain.
- Do not create temporary ownership confusion; purchased packs should stay owned.
- Be careful with recency-heavy pop-culture packs so paid content does not date too quickly.

## Backlog Mapping

Execution work for this plan lives in `PROJECT_BACKLOG.md`. The main follow-up buckets are:

- lock the free starter library and premium expansion boundary
- define the first premium pack slate and pricing ladder
- add pack monetization metadata to the local content model
- build a native pack store and restore-purchases flow
- integrate StoreKit non-consumable pack unlocks and App Store catalog work
- define monetization measurement and go / no-go gates
- instrument the monetization funnel with narrow first-party events
- prepare seasonal merchandising and promoted IAP launches
- author the first premium content wave and the Holiday Chaos follow-up
