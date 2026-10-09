# Phase 5 verification

Date: 2026-10-09. Run in the Claude Code cloud VM on the top of the stacked Phase 5 client branches (the Phase 0–3 stacks are
still not merged into `staging`, so Phase 5 is stacked on Phase 4, which is stacked on them):

| Repo | Branch | Notes |
|---|---|---|
| client | `modernise/p5-10-verify` (stack [#207](https://github.com/OpenManifest/openmanifest/pull/207) → … → [#215](https://github.com/OpenManifest/openmanifest/pull/215), then [#216](https://github.com/OpenManifest/openmanifest/pull/216)) | head = P5.9 plus the checklist and smoke captures of this phase |
| backend | `modernise/p5-10-verify` (status PRs #188 … #196, then this PR) | docs only; backend code is unchanged since Phase 2 |

## State of the client

Every screen group has been moved onto the shared layout primitives in `app/components/layout/` (`ScreenContainer`,
`FormColumn`, `FloatingActionArea`, `useBreakpoint`, `Sheet`; description in `client:docs/reference/README.md` §2):

- Login, dropzone selection, error screen: scrolling, safe-area aware, logo and card sized relative to the screen (P5.3).
- The carousel wizards (sign-up, user setup, dropzone setup, password flows) and the old weather wizard: `FormColumn` scroll,
  buttons in a `KeyboardStickyView` footer, page width from `onLayout` (P5.2, P5.7).
- One `Sheet` for every bottom sheet: dynamic height, interactive keyboard handling, `BottomSheetTextInput` for the fields in
  it (P5.4).
- Manifest board and load screen: flex layout, the slots list is the load screen's only scroll container, FABs outside the
  scroll content (P5.5). Configuration screens the same way, in theme colours (P5.6).
- Weather forms: fit 360 dp, inputs grow on Android (P5.7).
- Rows, headers and inputs use `minHeight`; navigation chrome caps its text scale at 1.6 (P5.8).
- ESLint rejects `KeyboardAvoidingView`, React Native's `SafeAreaView` and `Dimensions.get` outside the primitives (P5.9).

Added package: `react-native-keyboard-controller` 1.21.9 (the SDK 57 pin; `expo install` cannot reach its version API through
the VM's proxy, so the version was read from `expo/bundledNativeModules.json`). `app.config.ts` has
`android.softwareKeyboardLayoutMode: 'resize'`. Deleted as dead code: `navigation_wizard`, `DialogOrSheet.refactor.tsx`,
`DialogOrSheet.web copy.tsx`, `useKeyboardVisibility`, `constants/Layout.ts`, `load/views/CardView.tsx`.

## Client commands

```
yarn check:types    → exit 0
yarn check:linting  → exit 0: ESLint 9 "0 errors, 230 warnings" (234 at the end of Phase 4), Prettier clean
yarn check:graphql  → OK: 89 files, 76 operations, 50 fragments checked against schema.graphql
yarn check:testing  → Test Suites: 39 passed, 39 total; Tests: 116 passed, 5 skipped, 1 todo, 122 total
                      grep -c VirtualizedLists on the full Jest output → 0
yarn ts:graphql && git diff app/api → clean
EXPO_ENV=staging npx expo export --platform web → exit 0;  EXPO_ENV=local → exit 0
TZ=Australia/Brisbane node scripts/web-smoke.mjs   (see below)
desktop 1280x800: ok
phone360 360x640: ok
yarn audit --groups dependencies --summary → 42 vulnerabilities (23 High, 19 Moderate, 0 Critical); 42 at the end of Phase 4
```

Versus Phase 4 (33 suites, 97 passed, 5 skipped, 1 todo): +6 suites and +19 passing tests: `FormColumn`, `FloatingActionArea`,
`ScreenContainer`, `useBreakpoint`, `Sheet`, wizard `Buttons`. The five skipped tests and the `it.todo` are unchanged.

`scripts/web-smoke.mjs` now has these layout checks (each also runs at 1280×800):

- `checkLayout(route)`: `document.scrollingElement.scrollWidth <= viewport width`, and every visible
  `[data-testid$="-primary-action"]` element can be scrolled into view, lies inside the viewport and is what a click at its
  centre hits. Routes: `/login`, `/signup`, the dropzone selection, `/dropzone/manifest`, a load, the profile, ten
  configuration routes, the three weather routes and `/setup`.
- "Sign up" is reachable on `/login` (it was at y = 653 in a 640 px viewport before P5.3).
- The last slot row of the seed's 14 slot load can be scrolled to and clicked.
- The board and the load with every font size doubled (react-native-web writes px, so `html { font-size: 200% }` would change
  nothing): layout check, clipped-row check, last row reachable. This is a rough emulation (icon fonts scale too).
- A dark-mode screenshot of the ticket types screen.

Screenshots at 360×640 (`phone360-*`) and 1280×800 (`desktop-*`) of login, dropzone selection, sign-up (a wizard step),
dropzone setup (a wizard step), board, load, load at 200 % text, profile, ticket types (a configuration screen) and the
weather wizard and winds screens are in [`phase-5/`](phase-5/).

## CI on GitHub

| PR | Task | `checks` | `web-export` |
|---|---|---|---|
| [#205](https://github.com/OpenManifest/openmanifest/pull/205) | P4.8 (re-run) | success | success |
| [#206](https://github.com/OpenManifest/openmanifest/pull/206) | P4.9 | success | success |
| [#207](https://github.com/OpenManifest/openmanifest/pull/207) | P5.1 | success | success |
| [#208](https://github.com/OpenManifest/openmanifest/pull/208) | P5.2 | success | success |
| [#209](https://github.com/OpenManifest/openmanifest/pull/209) | P5.3 | success | success |
| [#210](https://github.com/OpenManifest/openmanifest/pull/210) | P5.4 | success | success |
| [#211](https://github.com/OpenManifest/openmanifest/pull/211) | P5.5 | success | success |
| [#212](https://github.com/OpenManifest/openmanifest/pull/212) | P5.6 | success | success |
| [#213](https://github.com/OpenManifest/openmanifest/pull/213) | P5.7 | success | success |
| [#214](https://github.com/OpenManifest/openmanifest/pull/214) | P5.8 | success | success |
| [#215](https://github.com/OpenManifest/openmanifest/pull/215) | P5.9 | success | success |

DeepSource still reports a failure on most client PRs (see the Phase 1 report). CI on `staging` itself runs once the stacks are
merged (owner check below).

## Tasks

| Task | Client PR | Backend status PR | Outcome |
|---|---|---|---|
| P5.1 layout primitives | #207 | #188 | `done` |
| P5.2 wizards | #208 | #189 | BUG-070, BUG-073 (wizards); owner-check |
| P5.3 login, dropzone selection | #209 | #190 | BUG-076, BUG-071; owner-check |
| P5.4 bottom sheets | #210 | #191 | BUG-073 (sheets); owner-check |
| P5.5 manifest board, load screen | #211 | #192 | BUG-072, BUG-074, BUG-071 (FABs); owner-check |
| P5.6 configuration screens | #212 | #193 | BUG-075, BUG-087, BUG-074; owner-check |
| P5.7 weather screens | #213 | #194 | BUG-078; owner-check |
| P5.8 large font scales | #214 | #195 | BUG-077; owner-check |
| P5.9 layout lint guard | #215 | #196 | `done` |
| P5.10 verify | #216 | this PR | this report |

## Bugs

BUG-070 … BUG-078 are all marked fixed in `BUGS.md`, each with "device check pending": the cloud VM can only prove the layout
on web, not the soft keyboard, edge-to-edge insets or system font scale on a phone. BUG-087 (hard-coded white on
configuration screens) is fixed too.

## Things learned during the phase (each is in the PR it concerns)

- Inside a tab navigator the screen already ends above the tab bar, which covers the bottom inset. `useSafeAreaInsets()` still
  returns the root inset there, so `FloatingActionArea` checks `BottomTabBarHeightContext` and skips the inset; a native
  `SafeAreaView` (`ScreenContainer`) measures its real overlap and needs no such care. Paper's `FAB.Group` is rendered in the
  screen, not in a `Portal`, for the same reason.
- `GradientText.web` set `background` (shorthand) and `background-clip: text`; React re-applies the shorthand when the theme
  changes and that resets the clip, so web titles turned into solid blocks once the dropzone's colours loaded. Found while
  taking P5.2 screenshots.
- The old weather wizard used Paper 4's `color` button prop, which Paper 5 ignores: its Cancel text was invisible.
- The stock `@gorhom/bottom-sheet` Jest mock exports React Native's `TextInput` as `BottomSheetTextInput`; `jest.setup.ts`
  wraps it so tests can tell the two apart.
- The app theme is MD2, so the plan's `variant="headlineMedium"` / `"displaySmall"` do not exist; explicit sizes are used.
- The plan's `bottomInset` for sheets would lift the sheet off the screen edge; the content is padded by the inset instead.
- `prettier --write app` rewrites the `.gql` files (as in Phase 4): use a `.ts`/`.tsx` glob.

## Owner checks (not possible in the cloud VM)

- Run the "Layout" section of `client:docs/SMOKE_TEST.md` on a small Android phone (360×640 dp), a large Android phone, an
  iPhone and an iPad, each at the default and the maximum font size, with dark mode on one device. Specifically: the keyboard in
  every wizard and sheet; whether the save button in a sheet needs a pinned footer (P5.4); FAB position over the tab bar and
  gesture bar (P5.5, P5.6).
- Close client#133 and client#134 if they no longer reproduce (P5.2).
- Merge the Phase 0–5 stacks in order in both repos and confirm CI on `staging`.
