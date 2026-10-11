# Phase 4 verification

Date: 2026-10-09. Run in the Claude Code cloud VM on the top of the stacked Phase 4 client branches (the Phase 0–3 stacks are
still not merged into `staging`, so Phase 4 is stacked on them):

| Repo | Branch | Notes |
|---|---|---|
| client | `modernise/p4-9-verify` (stack [#198](https://github.com/OpenManifest/openmanifest/pull/198) → … → [#205](https://github.com/OpenManifest/openmanifest/pull/205), then [#206](https://github.com/OpenManifest/openmanifest/pull/206)) | head = P4.8 plus the documentation of this phase |
| backend | `modernise/p4-9-verify` (status PRs #179 … #186, then this PR) | docs only; backend code is unchanged since Phase 2 |

## State of the client

No Redux. Server data is in Apollo; the rest is `useSession` (credentials in `expo-secure-store` on native and `localStorage` on
web, current dropzone, push token), `usePreferences` (colour scheme), a small non-persisted `useThemeOverrides`, component state,
and react-hook-form for every form. The theme is `useAppTheme()` (preference or device scheme + the current dropzone's colours
from Apollo). Logging out and an expired session both go through `resetSession`. The description is in
`client:docs/reference/README.md` §3 and `client:docs/reference/diagrams.md` §2.

Removed packages: `redux`, `react-redux`, `redux-persist`, `@reduxjs/toolkit`. Added: `zustand` 5.0.15, `expo-secure-store` ~57.0.4.

## Client commands

```
yarn check:types    → exit 0
yarn check:linting  → exit 0: ESLint 9 "0 errors, 234 warnings" (244 at the end of Phase 3), Prettier clean
yarn check:graphql  → OK: 89 files, 76 operations, 50 fragments checked against schema.graphql
yarn check:testing  → Test Suites: 33 passed, 33 total; Tests: 97 passed, 5 skipped, 1 todo, 103 total
yarn ts:graphql && git diff app/api → clean
EXPO_ENV=staging npx expo export --platform web → exit 0;  EXPO_ENV=local → exit 0
TZ=Australia/Brisbane node scripts/web-smoke.mjs   (login → dropzone → board → load → group sheet from the load screen →
desktop 1280x800: ok                                deep links /dropzone/manifest and the load URL → log out → log in as a
phone360 360x640: ok                                second user in the same page session)
yarn audit --groups dependencies --summary → 42 vulnerabilities (23 High, 19 Moderate, 0 Critical); 46 at the end of Phase 3
npx expo-doctor → 19/21 (the two checks that need the network cannot run in the VM, as in Phase 3)
```

Versus Phase 3 (19 suites, 48 passed, 7 skipped, 1 todo): +14 suites and +49 passing tests. New suites: session store and
migration, `palette`, `useAppTheme`, wizard field state, image viewer, user, weather, dropzone wizard, rig, membership, rig
inspection, rig inspection template, manifest dialogs, manifest group, and the rewritten logout test. The five skipped tests
are the pinned bugs BUG-065, BUG-067, BUG-086 and BUG-096 (two); BUG-063 (deleted with the `AbortController`) and BUG-066
(unskipped and passing) left the list. The `it.todo` is BUG-068.

`scripts/web-smoke.mjs` gained two steps in this phase: it opens the manifest group sheet from the load screen's speed dial
(P4.7) and it logs out and logs in as `jumper1@example.com` without reloading (P4.8). A session created by the Phase 3 build
(`persist:open-manifest.0.9.1`) stays logged in on the P4.1, P4.3 and P4.8 builds (same origin, checked each time; the P4.8
build also deletes the old key), and the dropzone and profile screens that moved from Redux to context state were opened in a
browser against the local backend (rigs, rig inspection template, user list, profile with the edit and membership dialogs).

## CI on GitHub

| PR | Task | `checks` | `web-export` |
|---|---|---|---|
| [#198](https://github.com/OpenManifest/openmanifest/pull/198) | P4.1 | success | success |
| [#199](https://github.com/OpenManifest/openmanifest/pull/199) | P4.2 | success | success |
| [#200](https://github.com/OpenManifest/openmanifest/pull/200) | P4.3 | success | success |
| [#201](https://github.com/OpenManifest/openmanifest/pull/201) | P4.4 | success | success |
| [#202](https://github.com/OpenManifest/openmanifest/pull/202) | P4.5 | success | success |
| [#203](https://github.com/OpenManifest/openmanifest/pull/203) | P4.6 | success | success |
| [#204](https://github.com/OpenManifest/openmanifest/pull/204) | P4.7 | success | success |
| [#205](https://github.com/OpenManifest/openmanifest/pull/205) | P4.8 | **failure** on the first push (the new logout test loads the real Apollo client and hit Jest's default 5 s on a cold runner), fixed with the usual 30 s test timeout | success |

DeepSource still reports a failure on most client PRs (it flags `scripts/**`, see the Phase 1 report). CI on `staging` itself
runs once the stacks are merged (owner check below).

## Tasks

| Task | Client PR | Backend status PR | Outcome |
|---|---|---|---|
| P4.1 session store, secure storage | #198 | #179 | BUG-017 fixed; migration from the redux-persist blob |
| P4.2 theme hook | #199 | #180 | `useAppTheme()`, `usePreferences`, Appearance setting |
| P4.3 remove snapshots | #200 | #181 | `global` only holds `authenticated` |
| P4.4 screen state, image viewer | #201 | #182 | contexts and component state |
| P4.5 forms group 1 | #202 | #183 | dropzone wizard, weather, user on react-hook-form |
| P4.6 forms group 2 | #203 | #184 | rig, membership, rig inspection (+template) |
| P4.7 manifest dialogs | #204 | #185 | BUG-066 and BUG-079 fixed; plan wording on slot permissions corrected |
| P4.8 remove Redux | #205 | #186 | BUG-063, BUG-064, BUG-069 fixed; BUG-018 client part |
| P4.9 verify | #206 | this PR | this report |

## Things learned during the phase (each is in the PR it concerns)

- Moving state out of Redux surfaced behaviour that was only there by accident: the theme used to be persisted, so the dropzone
  colours appear a moment later on a cold start now (Apollo has to answer first); nothing but one screen read most of the
  "screen" slices; a write-only `selectedUsers`, `dropzoneWizard.complete()` and `forms.manifest.setOpen` did nothing at all; the
  old `ManifestGroup` slice sent `rig: "NaN"` for slots without a rig.
- redux-persist's rehydration and the session migration race at start-up (both read the same key). The redux-persist version-1
  migration therefore keeps the credentials, dropzone id and push token in the blob until P4.8, and the session storage writes
  its own entry before it deletes the old one.
- react-hook-form's path types cannot unfold the schema's cyclic GraphQL types (`TicketType`, `JumpType`): form values use
  narrow `Pick<>` shapes (`TS2589` otherwise).
- The permission names in the plan (`updateSlot` / `updateUserSlot`) were swapped relative to the API (`update_slot.rb:50`); fixed
  in the plan text, and the P6 MoveSlot step had the same slip.
- Jest: a test that loads the real Apollo client needs a longer timeout in CI than locally; `react-native-reanimated/mock`
  needs `react-native-worklets/src/mock`; the real `react-native-reanimated-carousel` reports its own position back to the
  wizard and races with it under Jest (mocked in the wizard test).
- `prettier --write app` also reformats the `.gql` files; run it with the `ts`/`tsx` glob only (two commits had to undo this).

## Bug register changes in Phase 4

Fixed: BUG-017 (P4.1), BUG-063, BUG-064, BUG-069 (P4.8), BUG-066, BUG-079 (P4.7). BUG-018: client part fixed in P4.8 (the push
token is cleared before logging out), the server side stays with P6.18. No new bugs were registered.

## Backlog

- **Apollo Client 4** (`@apollo/client` 4.x) — reconsider after Phase 6; requires `useQuery` callback removal and new error types.
- **graphql-codegen 7** (cli 7, typescript-operations 6) — P3.19 stayed on cli 5 / plugins 4 because the 6.x operations plugin
  stops emitting `__typename?` and re-declares enums as string literals; migrate with `nonOptionalTypename` decisions for the
  fixtures and mocks.
- Persist the last dropzone's colours (or the theme) so a cold start does not show the default red until Apollo answers.
- A group action on the manifest board (neither display mode has one, BUG-066's note).

## Owner checks (pending)

1. Merge the Phase 0 → Phase 4 stacks in order in both repos and confirm the latest `CI` run on `staging` is green (including
   `web-export`). Phase 3's notes about the first `publish.yml` run still apply.
2. On one iPhone and one Android phone run `client:docs/SMOKE_TEST.md` sections Login and Manifest (updated in this phase),
   including: install this build over the previous one and stay logged in (P4.1), log out and log in as a second user without
   restarting the app (P4.8), the Appearance switch (P4.2), the dropzone, weather, profile, rig, inspection and membership
   forms (P4.5, P4.6), a group manifested from the load screen and a slot edited by tapping it (P4.7). Needs the EAS
   development builds (D2, D4) from Phase 3.
3. Answer D1–D8 (D4 blocks native builds, see the Phase 3 report) and decide the DeepSource question.
