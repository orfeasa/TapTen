# Release Checklist

Use this checklist before creating a release candidate or TestFlight build.

## 1) Build and Static Checks

- [ ] Run iOS build:
  - `xcodebuild build -project PesVres/TapTen.xcodeproj -scheme TapTen -destination 'generic/platform=iOS' -derivedDataPath /tmp/pesvres-dd CODE_SIGNING_ALLOWED=NO`
- [ ] Ensure no local pack-schema regressions:
  - `./scripts/audit_question_packs.sh`
- [ ] Confirm working tree contains only intended release changes.

## 2) Content Integrity

- [ ] Confirm final category set is intact:
  - Everyday Life, Food & Drink, Film & TV, Music, Sport, Geography, History, Science, Technology, Travel, Work & School, Pop Culture & Trends.
- [ ] Confirm each category remains at 12 questions with 4 easy / 4 medium / 4 hard.
- [ ] Confirm no duplicate prompts are reported by the audit script.
- [ ] Review any questions still marked `quality: "draft"` and decide: promote or defer.

## 3) Gameplay Smoke Test (Manual)

Run one full game (at least 2 rounds per team) and verify:

- [ ] Home:
  - `How To Play` opens reliably.
  - `Browse Question Packs` opens and loads category/pack counts.
- [ ] New Game:
  - Team names are editable and validation errors are clear.
  - Category and difficulty filters behave correctly.
  - Start fails with a clear message if filters produce no playable pool.
- [ ] Pass Device:
  - Round progress and team handoff text are correct.
- [ ] Host Round:
  - Tap reveals/untaps answers correctly.
  - `Pause` / `Resume` works without timer drift.
  - Final 10-second timer format remains stable.
  - `End Game` uses destructive confirmation dialog.
- [ ] Round Summary:
  - Points and found-answer count match revealed answers.
  - Continue CTA label matches state (`Next Round` or `Continue to Final Results`).
  - Source link appears only after round ends.
- [ ] Final Results:
  - Winner/runner-up display is correct.
  - `Home` returns to Home screen (not New Game).
  - `Play Again` starts a fresh game with scores reset.

## 4) Feedback and Accessibility Spot Check

- [ ] With `Sounds` ON: countdown/round-end audio is audible.
- [ ] With `Sounds` OFF: countdown/round-end audio is silent.
- [ ] With `Haptics` ON: reveal taps produce haptics.
- [ ] With `Haptics` OFF: reveal taps do not produce haptics.
- [ ] Verify key controls remain readable and tappable at larger Dynamic Type.

## 5) Ship/No-Ship Gate

- [ ] No P0 backlog task remains open.
- [ ] Any open P1/P2 item is consciously deferred and documented.
- [ ] Manual Review Needed section in `PROJECT_BACKLOG.md` is updated.

