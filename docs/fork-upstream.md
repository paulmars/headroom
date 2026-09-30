# Fork differences and upstream contribution plan

Audit date: 2026-09-30. This records the implementation Paul is using, rather
than treating every intermediate layout commit as a separate feature.

## Baselines and integration status

| Baseline | Commit | Meaning |
|---|---|---|
| Original common base | `ef559a6d8b49ecf599d8e4c7a0d0fe44ea5423dd` | Upstream 2.1.0 |
| Fork before update | `2ade485` | Fork main after PR #3; still version 2.1.0 |
| Upstream release | `3e5ff507c2c9bec1d790afe2d080cb0fc565608d` | Tag `v2.1.7` |
| Replayed fork tip | `225c5c9` | 21 fork commits replayed on the release |
| Audited fork main | `cea6d223fa5a23a89fdac87e3fe6b5091cdd4957` | Merged PR #4; version 2.1.7 |
| Upstream main at audit | `dec02f2322cb1cb79315bcf5fb198ace454509c5` | Additional work after the release |

The update PR is already merged:

https://github.com/paulmars/headroom/pull/4

`v2.1.7` is an ancestor of fork main. The merge joining the original fork
history and the rebased history did not change the rebased file tree:
`git diff 225c5c9 cea6d22` is empty. Do not rebase public main again or open a
second update PR containing the same work.

`git range-diff ef559a6..2ade485 v2.1.7..225c5c9` accounts for all 21 fork
commits: 19 match exactly, the attention-dot change retains upstream's new
preview strings, and the placed-widget fix is reapplied after overlapping
migration work. Its final form still registers both configuration systems,
with stable distinct kinds and a test for the registration wiring.

The 2.1.0 → 2.1.7 update brings upstream's provider detection and recovery
fixes, in-place quota-refill handling, GitHub attention aging, menu-bar preview,
Claude Status integration, desk-display settings and scheduled dimming,
portable host tests, dark menu-bar plate, and Claude OAuth loop fixes. See
`CHANGELOG.md` sections 2.1.1–2.1.7 for the release details. Those are upstream
changes, not candidates to contribute back.

## What the fork changes relative to v2.1.7

### 1. Preserve already-placed widgets when adding provider selection

Upstream registers one `AppIntentConfiguration` under `HeadroomWidget`, the
identity previously used for a static widget. The fork keeps a static
**Headroom — All providers** widget at `HeadroomWidget` and registers the
editable **Headroom — Provider** widget at `HeadroomWidget.Configurable`.
Both load the same cache and view; the legacy provider requests another
timeline after 15 minutes.

This addresses frozen tiles after changing configuration systems. Provider
selection itself already exists upstream; the contribution is compatibility,
not a new provider picker. Tiles created with the intermediate upstream
editable definition under the old kind may need removal and re-adding as
**Headroom — Provider**. The code cannot preserve two configuration systems
under one kind. Actual migration on an installed widget still needs a manual
upgrade check; the unit tests check identities and source wiring.

### 2. Add widget pace and reset readings, with compact Mac layouts

Upstream's cached headline percentage is the maximum visible pool percentage.
The fork selects the overview/headline pool instead, so the number and pace
reading refer to the same pool as the chart (normally weekly). It computes
slack as `pace - used`, using that pool's sampled pace or pool pace and then
its overview delta as fallback. It does not borrow another pool's pace.

The cache adds optional provider fields `paceDeltaPct`, `sessionResetsIn`,
`weekResetsIn`, `weekResetsAt`, and optional layer `resetsIn`. Older caches
still decode. Reset durations are saved even when a pool has no percentage
and therefore no ring. This is a widget-cache change; the fork does not
change the host's `/usage` schema.

| Surface | Upstream v2.1.7 | Fork |
|---|---|---|
| Mac small widget | Provider name and used percentage below rings | Name, weekly reset (`1w: 3d1h`), then session reset (`5h: 1h34m`); no printed percentage |
| Mac medium chart legend | Name and remaining percentage | One line, e.g. `Claude: 33% spare` or `Codex: 4% over` |
| Mac medium without history | Rings, name, used percentage | Rings and the same one-line pace summary |
| iPhone small widget | Name and used percentage | Keeps both and adds reset rows; Codex omits the session row |
| iPhone medium chart legend | Name and remaining percentage | Adds a third pace row, e.g. `33% to spare` |
| iPhone medium without history | Rings, name, used percentage | Adds pace below the used percentage |

Weekly resets today use a local 12-hour clock (`2pm`); other days use compact
durations (`3d1h`). Mac always shows both reset rows, including for Codex and
providers with unknown resets (`1w: —`, `5h: —`). The iPhone weekly row has no
`1w:` prefix. Unknown pace is explicit (`— spare` on Mac, `— to spare` on
other widget presentations). Stale/no-history layouts shrink rings and gaps
to make space. Labels scale to fit; multi-provider columns share width.

### 3. Put each provider's quota summary below its own popover ring

Upstream puts one primary burndown headline beneath the whole overview grid.
The fork removes that shared sentence and places a compact reset, signed
pace slack, and remaining percentage below each provider's ring, using
`QuotaOverviewSummary` to bind the text to provider IDs.

A typical column reads `5d1h`, `11% to spare`, `58% left`. A reset today reads
`1pm`; without a duration the fallback is `Sun 1pm`. There is no `Reset:`
prefix. Negative slack reads `4% over`; a missing/sub-point delta uses
`On Pace` or `Over Pace`. Remaining percentage is clamped to 0–100 and omitted
when unknown. A provider without overview burndown keeps the older caption.
A stale/error status remains a separate row rather than replacing the quota
summary. Provider title and caption spacing are tightened.

This changes the **popover**, not the numeric contents of the menu-bar icon.
Ring math and the host's quota readings stay upstream's implementation.

### 4. Let the attention dot be hidden independently of its tooltip

Settings → General → Menu bar icon adds **Attention dot**, on by default.
`menuBarIconHideAttentionPip` stores the inverse Boolean locally in
UserDefaults; it is not a host config key or a multi-Mac synced preference.
The status-item renderer omits the pip when disabled, but the tooltip still
reports warnings. Existing defaults-change observation updates the icon.

Upstream 2.1.7's dark plate remains: its renderer sets `isTemplate = false`
unconditionally. The earlier fork's claim that turning off the dot restores
a monochrome template is no longer accurate. The glossary now records the
actual behavior; the existing Settings hint and source comments still need
that wording corrected in the attention-dot contribution. There is no new
runtime toggle/tooltip unit test in this fork delta.

## Exact file inventory

At the audited fork main, the release-to-fork diff is **16 files, 1,115
insertions and 85 deletions**. These counts exclude this audit document and
the accompanying documentation corrections.

| File | Fork contribution |
|---|---|
| `Shared/HeadroomCopy.swift` | Reset/clock/slack formatters and attention-toggle copy |
| `Shared/MenuBarIconStyle.swift` | Hide-pip defaults key and preference accessor |
| `Shared/WidgetCacheWriter.swift` | Headline-pool binding, pace and reset cache fields |
| `Shared/WidgetIdentity.swift` | New stable legacy/editable widget identities |
| `Shared/WidgetSnapshot.swift` | Optional cache fields, decoding and demo values |
| `Shared/WidgetSnapshotPresentation.swift` | Pace summaries and platform-specific reset rows |
| `docs/glossary.md` | Fork vocabulary and layout rules |
| `docs/ios-companion.md` | Compatibility widget and migration caveat |
| `macos/Sources/QuotaSection.swift` | Per-provider reset, pace, remaining and status captions |
| `macos/Sources/Settings/SettingsView+General.swift` | Attention-dot toggle UI |
| `macos/Sources/Settings/SettingsView.swift` | Preference binding |
| `macos/Sources/StatusItemController.swift` | Pip visibility separated from warning tooltip |
| `macos/Tests/ContractTests.swift` | 13 added test methods plus cache/round-trip assertions |
| `macos/project.yml` | WidgetIdentity included in both widget extension targets |
| `widget/HeadroomWidget.swift` | Legacy registration/provider and compact platform layouts |
| `widget/HeadroomWidgetIntent.swift` | Clarifies which configuration handles old tiles |

There are no fork changes to `host/`, `firmware/`, `ios/`, `watch/`, release
workflows, version, or update feed relative to the release tag. Shared Swift
and widget code still affects multiple Apple targets.

## What newer upstream main adds

Upstream main at `dec02f2` has nine commits after the release tag, including
a merge and the 2.1.7 update-feed commit. It adds the local usage study and
stats-card formats, loopback study routes, the **Your usage** window,
friends/cards and imports from other Macs. It also changes mobile scheme
configuration and signing defaults. This work is not included in the fork's
release-based update and is not a fork feature to propose upstream.

The three files edited on both sides after `v2.1.7` are
`Shared/HeadroomCopy.swift`, `docs/glossary.md`, and `macos/project.yml`.
The inspected upstream additions address different sections; a future
contribution should still apply and test against the then-current upstream
main. Do not propose the full two-dot tree diff from upstream main to the
fork: that would also remove newer upstream functionality.

## Suggested upstream PRs and exit criteria

Prepare focused commits on current upstream main, using the final file diff
as the source of truth. The fork history contains both original and rebased
copies of the same commits; replaying the entire log would duplicate work.

1. **Widget migration compatibility.** Identities, legacy provider and
   registration, project source entries, migration docs and the two identity/
   wiring tests. Keep visual changes out. Demonstrate upgrade behavior for a
   legacy static tile, an intermediate editable tile, and a new provider tile.
2. **Widget pace/reset information.** Cache writer/model/presentation, widget
   layouts, relevant formatters and tests. Keep the pool-binding correction
   explicit. Obtain agreement on the Mac/iPhone layout differences, hardcoded
   `1w`/`5h` labels for other providers, and 12-hour clocks. Include screenshots
   for one/three providers, stale/no-history states and missing cache fields.
3. **Per-provider popover summaries.** QuotaSection, the overview formatters,
   glossary and four overview tests. Include before/after screenshots with
   under/over pace and a failing provider. These share copy helpers with the
   widget work, so split their hunks deliberately or stack on that PR.
4. **Optional attention dot.** Preference, Settings, status-item change and
   copy. Correct the obsolete monochrome claim and verify default-on,
   disabled-with-warning, and tooltip behavior with the dark plate.

The upstream PRs are proposals, not submitted as part of this audit. The
first PR is a correctness fix independent of layout preferences. The other
three need upstream product agreement; identical implementation is not
required if upstream delivers the behavior Paul wants.

Retire the fork after those desired behaviors are available in an upstream
release and checked on Paul's installed app: old widgets refresh, chosen
providers persist, pace/reset/remaining readings are acceptable, and the dot
can be hidden with warnings still discoverable. Test widget replacement and
preferences during that switch. If upstream declines a presentation choice,
explicitly decide whether to accept its alternative before declaring the
fork unnecessary. Keep the original fork refs until the switch is verified.

## Validation and remaining limits

Fresh checks in the isolated `cleanup` worktree on 2026-09-30, with application
code at `cea6d22` and Xcode 26.6 (17F113):

| Check | Result |
|---|---|
| `./scripts/gen-project.sh` | Passed |
| macOS `Headroom` Debug test gate | 119 tests, zero failures; includes Mac widget build |
| Host unittest discovery with temporary `HOME` | 712 tests, passed |
| `./scripts/check-glossary-copy.sh` | Passed |
| `git diff --check` | Passed |
| iOS simulator build | Blocked before compilation: embedded watch requires watchOS 26.5 |
| watchOS simulator build | Blocked: no eligible destination, watchOS 26.5 unavailable |

Only `/Applications/Xcode.app` is installed; the prescribed beta toolchain
is absent. Re-run both simulator build gates from `AGENTS.md` on a machine
with working watchOS support before calling cross-platform validation
complete. No physical widget upgrade, visual layout, signed CloudKit, or
hardware test was performed. The host service and installed app were not
replaced. This audit makes documentation changes only and does not release a
new app version.

To reproduce the historical comparison (fetch the release tag if needed):

```bash
git diff --stat v2.1.7 cea6d22
git diff v2.1.7 cea6d22 -- Shared macos widget docs
git merge-base --is-ancestor v2.1.7 cea6d22
git diff --exit-code 225c5c9 cea6d22
git range-diff ef559a6..2ade485 v2.1.7..225c5c9
```
