# Phase 3 verification

Date: 2026-10-09. Run in the Claude Code cloud VM on the top of the stacked Phase 3 client branches (none of Phase 0–3 is merged
into `staging`; everything was built on the owner's "stacked PRs" instruction):

| Repo | Branch | Notes |
|---|---|---|
| client | `modernise/p3-22-verify` (stack #177 → #178 → #179 → … → #196 on top of Phases 0–1, then this PR) | head = P3.21 plus `README.md` §10 refresh |
| backend | `modernise/p3-22-verify` (status PRs #158 … #177, then this PR) | docs only; backend code is unchanged since Phase 2 |

P3.3 (Facebook login) is **blocked on decision D4** and is not part of this stack (see "Not done" below).

## Versions (client)

```
node -v                       → v24.21.0   (.nvmrc = 24; ci.yml and publish.yml read it)
expo                          → 57.0.27    (was 47.0.13)
react-native                  → 0.86.3     (was 0.70.8)
react / react-dom             → 19.2.3     (was 18.1.0)
react-native-web              → 0.21.4     (was 0.18.10)
react-native-reanimated       → 4.5.1 with react-native-worklets 0.10.1   (was 2.12.0)
react-native-paper            → 5.15.3, MD2 theme     (was 4.12.4)
React Navigation              → native 7.5.0, stack 7.12.0, bottom-tabs 7.20.0, drawer 7.14.3   (was 6.x)
@gorhom/bottom-sheet          → 5.2.14     (was 4.4.5)
@apollo/client / graphql      → 3.14.1 / 16.14.2   (was 3.7.11 / 15.8.0)
typescript / eslint / prettier → 5.9.3 / 9.39.5 / 3.9.9   (Rome removed)
jest / jest-expo / RNTL       → 29.7.0 / 57.0.x / 13.3.3
web bundler                   → Metro (`expo export --platform web` → `dist/`), webpack removed
```

## Client commands

```
yarn check:types    → exit 0
yarn check:linting  → exit 0: ESLint 9 "0 errors, 244 warnings" (the table is in client PR #195), Prettier clean
yarn check:graphql  → OK: 89 files, 76 operations, 50 fragments checked against schema.graphql
yarn check:testing  → Test Suites: 19 passed, 19 total; Tests: 48 passed, 7 skipped, 1 todo, 56 total
EXPO_ENV=staging npx expo export --platform web → exit 0 (dist/index.html present; also exit 0 with EXPO_ENV=local)
python3 scripts/serve-web-build.py dist 19006 &
TZ=Australia/Brisbane node scripts/web-smoke.mjs --out /tmp/smoke      (login → dropzone → board → load, then /dropzone/manifest
desktop 1280x800: ok                                                    and the load URL as full page loads)
phone360 360x640: ok
yarn ts:graphql && git diff --exit-code app/api → clean (P3.19)
```

Versus Phase 2 (15 suites, 33 passed, 7 skipped, 1 todo): +4 suites and +15 tests: `Skeleton` (4), `ColorPicker` (4), `NumberField` (5),
`sameVariables` (2). The seven skipped tests are the BUG-063/065/066/067/086/096 tests from Phase 1.

`npx expo-doctor` (offline, `EXPO_OFFLINE`-style: `api.expo.dev`, `exp.host` and the React Native Directory are unreachable from the VM):

```
19/21 checks passed. 2 checks failed:
✖ Check Expo config (app.json/ app.config.js) schema      (needs the network)
✖ Validate packages against React Native Directory package metadata   (needs the network)
```

No check that can run locally fails (no direct `@expo/*` installs, no unexpected package versions, no Hermes V1 regression on 57.0.27).
The "native modules use compatible support package versions" check is not among the failures.

`yarn audit --groups dependencies --summary`:

```
46 vulnerabilities found - Packages audited: 906
Severity: 23 Moderate | 23 High      (0 critical)
```

Phase 0 baseline was 715 advisories (61 critical, 452 high, 161 moderate, 41 low) in 2078 packages (BUG-016). What is left:

| Package | Distinct advisories | Via | Note |
|---|---|---|---|
| `@xmldom/xmldom` | 15 (13 high, 2 moderate) | `expo-facebook` | goes away with P3.3 (D4) |
| `xml2js` | 1 (moderate) | `expo-facebook` | same |
| `braces` | 1 (high) | `expo` | build-time tooling inside `expo` |
| `node-forge` | 1 (high) | `expo`, `expo-updates` | build-time tooling |
| `uuid` | 1 (moderate) | `expo` | build-time tooling |
| `@babel/runtime` | 1 (moderate) | `@mui/material` (web) | regexp complexity in generated helpers; needs a newer MUI |

That is 20 distinct advisories on 6 packages; `yarn audit` reports 46 because it counts every dependency path. 17 of the 20 come through
`expo-facebook`, so P3.3 removes most of what is left.

## CI on GitHub

| PR | Task | `checks` | `web-export` |
|---|---|---|---|
| [#188](https://github.com/OpenManifest/openmanifest/actions/runs/37853705208) | P3.13 | success | success |
| [#189](https://github.com/OpenManifest/openmanifest/actions/runs/37855606673) | P3.14 | **failure** (`yarn install --frozen-lockfile`: the lockfile still had the `lottie-web@^5.12.2` key after I pinned 5.13.0 by hand) | failure (same) |
| [#190](https://github.com/OpenManifest/openmanifest/actions/runs/37856873170) | P3.15 | success | success |
| [#196](https://github.com/OpenManifest/openmanifest/actions/runs/37862258885) | P3.21 | success | success |

The P3.14 lockfile was fixed in a commit on that branch and carried up the stack by merge commits (P3.15 … P3.21, each merge was clean).
After the fix `checks` and `web-export` are green on [#189](https://github.com/OpenManifest/openmanifest/actions/runs/37862814815) and
[#195](https://github.com/OpenManifest/openmanifest/actions/runs/37862885813). DeepSource still reports a failure on most client PRs (it flags `scripts/**`, see the
Phase 1 report). CI on `staging` itself runs once the stacks are merged (owner check below).

## Tasks

| Task | Client PR | Backend status PR | Outcome |
|---|---|---|---|
| P3.1 remove unused deps | #177 | #158 | 14 deps and 4 devDeps removed |
| P3.2 remove `sentry-expo` | #178 | #159 | removed with its CI/workflow references |
| P3.3 Facebook login | – | – | **blocked on D4** |
| P3.4 replace three UI libraries | #179 | #160 | plain bottom tabs, `SkeletonContent` |
| P3.5 SDK 48 | #180 | #161 | yarn.lock regenerated; single `@react-navigation/core` |
| P3.6 SDK 49 | #181 | #162 | RN 0.72, Reanimated 3.3 |
| P3.7 SDK 50 + Metro web | #182 | #163 | webpack removed, `public/` replaces `web/`, `environment.ts` |
| P3.8 SDK 51 | #183 | #164 | push token `projectId` |
| P3.9 React Navigation 7 | #184 | #165 | BUG-083 fixed; TypeScript 5.9.3, ts-node 10.9.2 pulled forward |
| P3.10 SDK 52 | #185 | #166 | Paper typing shim; direct `@expo/*` installs removed |
| P3.11 Paper 5 (core) | #186 | #167 | MD2 theme, `AppTheme`, `ProgressBar` wrapper |
| P3.12 Paper 5 (screens) | #187 | #168 | 0 type errors; BUG-099 fixed, BUG-100 added |
| P3.13 replace unmaintained libs | #188 | #169 | colour picker, number field, wizard paging |
| P3.14 SDK 53, React 19, New Architecture | #189 | #170 | `react-native-web-lottie` replaced |
| P3.15 SDK 54, Reanimated 4, Node 24 | #190 | #171 | bottom sheet 5, carousel 5 |
| P3.16 SDK 55 | #191 | #172 | react-native-maps jest mock |
| P3.17 SDK 56 | #192 | #173 | `absoluteFillObject`, jest preset package |
| P3.18 SDK 57 | #193 | #174 | no source changes |
| P3.19 Apollo, graphql, codegen | #194 | #175 | codegen stayed on cli 5 (deviation), refetch-loop bug found and fixed |
| P3.20 ESLint 9, Prettier, no Rome | #195 | #176 | 244 warnings, 0 errors |
| P3.21 app config and EAS | #196 | #177 | BUG-088 fixed, dev client profile |

## Things learned during the phase (each is recorded in the PR or the plan)

- The offline SDK procedure (`bundledNativeModules.json` alignment) worked for every step from 48 to 57; `expo-doctor` could only run its local checks.
- Several upgrades broke Jest in ways the app code could not see: `react-native-gesture-handler` 2.28's `BaseButton` mock drops its children
  (every `TouchableOpacity` rendered empty), `react-native-maps` 1.27 throws on import without its native module, expo-asset's package `exports`
  hide `build/*`, Jest 29 cannot resolve array-conditioned `@babel/runtime` helper exports, RNTL 13 skips hidden elements by default. Fixes
  are in `jest.setup.ts` and the `jest` block of `package.json`.
- Production-affecting findings the upgrades exposed: the authenticated Apollo link was installed too late after a reload (BUG-099, fixed in
  P3.12); Apollo 3.14 drops undefined variables, which made `isEqual`-guarded effects refetch forever (fixed in P3.19 with
  `app/utils/sameVariables.ts`); `react-native-web-lottie` crashed every Lottie screen on React 19 (replaced in P3.14); `publish.yml` ran Node 16
  (now `.nvmrc`).
- The web build is layout-sensitive to Paper 5's `ProgressBar` (fills its parent's height on web); `app/components/ProgressBar` wraps it.
- Test fixtures collide in the Apollo cache by `__typename` + `id`: P3.11 aligned the `UserRole:1` name in the permissions mock with the current user fixture.
- `process.env.EXPO_ENV` is read at build time only; app code reads `Constants.expoConfig.extra.environment` (P3.7).

## Bug register changes in Phase 3

Fixed: BUG-083 (P3.9), BUG-088 (P3.21), BUG-099 (P3.12, found in the phase). Added: BUG-099, BUG-100 (cold load of permission-gated tab
URLs ends on `/`; deferred, needs a design decision). BUG-016 (client advisories): 715 → 46 advisories, 0 critical; the remainder is listed
above and is mostly `expo-facebook` (P3.3). BUG-084 (Facebook login) and BUG-085 (maps; needs keys) stay open.

## Not done

- **P3.3** waits on D4. Until it lands, `expo-facebook` 12.2.0 stays in `package.json` and the `app.config.ts` plugin list; it cannot be built
  into a native app with current SDKs, so **native builds are blocked until D4 is answered** (web is unaffected).
- No `yarn audit` job in client CI (BUG-016's fix column suggested one); add it when D4 is resolved so it can be made blocking.
- Layout fixes for Android edge-to-edge (SDK 54+) and small screens are Phase 5.

## Owner checks (pending)

1. Answer D4 (and D1–D8 generally); merge the Phase 0 → Phase 3 stacks in order in both repos and confirm the latest `CI` run on `staging`
   is green, including `web-export`. The first merge of the Phase 3 stack deploys nothing by itself, but `publish.yml` now builds with
   `expo export --platform web` and publishes `dist/` (it was not run here): check the next staging deploy loads, `/confirm` and the Apple
   `.well-known` file resolve.
2. With EAS development builds (needs D2 and D4): run all of `client:docs/SMOKE_TEST.md` on an iPhone (iOS ≥ 16.4), an Android phone, a small
   Android phone (360×640 dp) and with maximum font size. Also check push notifications (manifest a user, give a call), Apple login, the
   camera / photo picker on the profile avatar, maps on the dropzone setup location step (BUG-085), the New Architecture on both platforms
   (nothing in the VM exercises native code), and the wizard and number-field replacements from P3.13. Record results here; layout
   failures are expected and feed Phase 5.
3. Decide the DeepSource question from the Phase 1 report.
