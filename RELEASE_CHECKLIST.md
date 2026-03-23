# Release Checklist

Use this checklist before creating a release candidate or TestFlight build.

## 1) Build and Static Checks

- [ ] Run iOS build:
  - `xcodebuild build -project PesVres/TapTen.xcodeproj -scheme TapTen -destination 'generic/platform=iOS' -derivedDataPath /tmp/pesvres-dd CODE_SIGNING_ALLOWED=NO`
- [ ] Run compatibility build at the current deployment floor (`iOS 17`):
  - `xcodebuild build -project PesVres/TapTen.xcodeproj -scheme TapTen -destination 'generic/platform=iOS' -derivedDataPath /tmp/pesvres-dd-ios17 CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=17.0`
  - If `actool` reports missing simulator runtimes during the asset-thinning step on a restricted/sandboxed host, rerun the same command on a normal full-Xcode machine before treating it as an app regression.
- [ ] Ensure no local pack-schema regressions:
  - `./scripts/audit_question_packs.sh`
- [ ] Confirm working tree contains only intended release changes.

## 2) TestFlight Automation

- [ ] Confirm GitHub Actions secrets are configured:
  - `APP_STORE_CONNECT_API_KEY_ID`
  - `APP_STORE_CONNECT_ISSUER_ID`
  - `APP_STORE_CONNECT_API_KEY_BASE64`
- [ ] Confirm the CI runner has sufficient signing access for archive/export.
- [ ] If using in-app question reporting in the release build, confirm `QuestionFeedbackEndpointURL` is set for that build configuration (or equivalent runtime environment injection is present).
- [ ] Trigger one beta upload path:
  - GitHub Actions `TestFlight Beta` workflow manual dispatch, or
  - push a `beta-*` tag, or
  - local `bundle exec fastlane beta` on a signing-capable machine.
- [ ] Verify the build number increments and the uploaded build appears in TestFlight.
- [ ] Verify no generated fastlane artifacts pollute the working tree after a local beta run.

## 2b) Website / Support URLs

- [ ] If the release relies on public support/privacy URLs, confirm the `Website Pages` workflow succeeds on `main`.
- [ ] Confirm `playtapten.com` serves the live landing page over HTTPS.
- [ ] Confirm `playtapten.com/privacy.html` loads successfully.
- [ ] Confirm support links on the site resolve to the expected contact path.

## 3) Content Integrity

- [ ] Confirm final category set is intact:
  - Everyday Life, Food & Drink, Film & TV, Music, Sport, Geography, History, Science, Technology, Travel, Work & School, Pop Culture & Trends.
- [ ] Confirm each category remains at 12 questions with 4 easy / 4 medium / 4 hard.
- [ ] Confirm no duplicate prompts are reported by the audit script.
- [ ] Review any questions still marked `quality: "draft"` and decide: promote or defer.

## 4) Gameplay Smoke Test (Manual)

Run one full game (at least 2 rounds per team) and verify:

- [ ] Home:
  - `How To Play` opens reliably.
  - `Browse Question Packs` opens and loads category/pack counts.
  - App remains portrait-only on iPhone.
- [ ] New Game:
  - Team names open with a random suggested pair, remain editable, and validation errors are clear.
  - `Shuffle Names` replaces both team names immediately.
  - Rounds/timer controls are not shown in setup.
  - Category and difficulty filters behave correctly.
  - `Start Game` remains visible without scrolling to the end of setup.
  - Start fails with a clear message if filters produce no playable pool.
- [ ] Settings:
  - Changing default rounds/timer does not crash.
  - Updated defaults apply to the next New Game entry.
- [ ] Pass Device:
  - Round progress and team handoff text are correct.
- [ ] Question Preview:
  - The prompt is visible before the timer starts.
  - `Start Timer` is the only obvious primary action.
- [ ] Host Round:
  - Tap reveals/untaps answers correctly.
  - `Pause` / `Resume` works without timer drift.
  - Final 10-second timer format remains stable.
  - Final 10-second countdown audio starts at `10` and ramps cleanly through `1`.
  - `End Game` uses destructive confirmation dialog.
  - After time-up, `View source` and `Flag question` are available before continuing.
  - On narrow iPhones, post-timeup review actions stay on one row without overlapping the question text.
  - `Flag question` opens the feedback sheet, shows category/difficulty/source, and either sends in-app or saves locally with a clear confirmation state.
- [ ] Round Summary:
  - Points and found-answer count match revealed answers.
  - Continue CTA label matches state (`Next Round` or `Continue to Final Results`).
- [ ] Final Results:
  - Winner/runner-up display is correct.
  - `Home` returns to the Home screen.
  - `Play Again` starts a fresh game with scores reset.

## 5) Feedback and Accessibility Spot Check

- [ ] With `Sounds` ON: countdown/round-end audio is audible.
- [ ] With `Sounds` ON: Round Summary and Final Results payoff sounds are audible.
- [ ] With `Sounds` OFF: countdown/round-end audio is silent.
- [ ] With `Haptics` ON: reveal taps produce haptics.
- [ ] With `Haptics` OFF: reveal taps do not produce haptics.
- [ ] Verify key controls remain readable and tappable at larger Dynamic Type.

## 6) Ship/No-Ship Gate

- [ ] No P0 backlog task remains open.
- [ ] Any open P1/P2 item is consciously deferred and documented.
- [ ] Manual Review Needed section in `PROJECT_BACKLOG.md` is updated.
- [ ] Any blocked release-ops task (for example TestFlight signing/credentials) is either cleared or explicitly accepted before ship.
