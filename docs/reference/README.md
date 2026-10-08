# OpenManifest — reference documentation

This is the system-level reference for the OpenManifest platform. It lives in the backend repository
(`OpenManifest/openmanifest-server`) and covers both repositories. The client repository
(`OpenManifest/openmanifest`) has its own `docs/reference/README.md` with client-only detail and links back here.

Written during modernisation pass 1 (2026-10-08) against:

| Repo | Default branch | Commit described |
|---|---|---|
| `OpenManifest/openmanifest-server` | `staging` | `b8dc33a` "chore: server urls (#124)", 2023-10-18 |
| `OpenManifest/openmanifest` | `staging` | `3112795` "[ci skip]: Published 1.1.60", 2023-10-18 |

Related documents:

- [`BUGS.md`](BUGS.md) — bug register for both repos (IDs `BUG-xxx`)
- [`diagrams.md`](diagrams.md) — architecture, ER, sequence and state diagrams
- [`GENERALISATION.md`](GENERALISATION.md) — turning skydiving-specific concepts into a generic "dispatch people on vehicles" platform
- [`CLOUD_ENV.md`](CLOUD_ENV.md) — Claude Code cloud environment setup script and per-session commands
- [`../MODERNISATION_PLAN.md`](../MODERNISATION_PLAN.md) — the phased plan (single source of truth for executor passes)
- Client reference: <https://github.com/OpenManifest/openmanifest/blob/staging/docs/reference/README.md>

---

## 1. What the system does

OpenManifest is a **skydiving dropzone management ("manifest") system**. A dropzone (a skydiving centre) uses it to:

- run the **manifest board**: create aircraft **loads** for the day, put jumpers in **slots** on loads, assign a pilot,
  ground-control assistant (GCA) and load master, give the load a **call** ("20-minute call", "10-minute call", custom
  time), and finalise the load as **landed** or **cancelled**;
- keep a **credit wallet** per jumper (prepaid "credits" that are deducted when a jumper is manifested and refunded when
  they are taken off or the load is cancelled);
- check **eligibility** before manifesting: licence (via the national **federation**, e.g. APF in Australia), membership
  expiry, rig (parachute equipment) inspection and reserve repack date, enough credits, not already on another load;
- record **rig inspections** using a per-dropzone inspection form template;
- capture **weather** (winds aloft, temperature, jump run heading, exit spot offset) for the day;
- produce a regulatory **master log** per day (APF Operational Regulations 12.3.3 is quoted in `app/models/master_log.rb:24-35`);
- send **notifications** (in-app and Expo push) to jumpers: manifested, taken off, boarding call, credits, permissions.

### User roles

Roles are **per dropzone** (`user_roles` table, one set of roles created for each dropzone from `config/seed/access.yml`).
A `User` joins a dropzone as a `DropzoneUser` with one `UserRole` plus optional individually granted permissions.

| Role slug (`config/seed/access.yml`) | Intended person | Notes |
|---|---|---|
| `tandem_passenger` | First-time tandem customer | `readLoad` only |
| `student` | Student in training (AFF etc.) | default role for users without a licence (`UserRole::DEFAULT`, `app/models/user_role.rb:15`) |
| `pilot` | Aircraft pilot | |
| `fun_jumper` | Licensed jumper | default for licensed users (`UserRole::DEFAULT_LICENSED`) |
| `coach`, `aff_instructor`, `tandem_instructor` | Instructors | |
| `manifest` | Manifest staff | can create loads, manifest others, add credits |
| `chief_instructor`, `admin`, `owner` | Dropzone management | `owner` is assigned to the creator of a dropzone |

"Acting" permissions (`actAsPilot`, `actAsGCA`, `actAsLoadMaster`, `actAsDZSO`, `actAsRigInspector`) are granted per user,
never per role (`app/interactions/setup/dropzones/access/create_defaults.rb:90-93`). They decide who appears in the pilot /
GCA / load-master pickers.

Platform-wide, `users.moderation_role` (`user`, `support`, `moderator`, `administrator`, `app/models/user.rb:56`) gives
moderators visibility of all dropzones (`Dropzone.for`, `app/models/dropzone.rb:85-90`) and the right to publish
dropzones (`app/interactions/setup/dropzones/update_visibility.rb`).

---

## 2. Architecture

```
Expo app (iOS / Android / web)  ──HTTPS POST /graphql (batched)──▶  Rails 7.0 API (GraphQL, graphql-ruby)
        │                       ◀──JSON──                               │  ├─ PostgreSQL (all data)
        └──WebSocket /subscriptions (ActionCable, GraphqlChannel)──▶    │  ├─ Redis (ActionCable pub/sub, prod cache)
                                                                        │  ├─ ActiveStorage: Disk (dev/fly) or GCS (prod)
                                                                        │  └─ outbound HTTP: Expo push, APF, winds aloft,
                                                                        │       Google geocoder, Apple/Facebook token checks
```

Full diagram: [`diagrams.md` §1](diagrams.md#1-system-context).

| Concern | Implementation | Files |
|---|---|---|
| API style | Single GraphQL endpoint, Relay-classic mutations, Apollo batching supported (`params[:_json]`) | `config/routes.rb:10`, `app/controllers/graphql_controller.rb` |
| Schema | `DzSchema` with `GraphqlDevise::SchemaPlugin` (auth), `GraphQL::Dataloader`, AppSignal tracing, ActionCable subscriptions | `app/graphql/dz_schema.rb` |
| Auth | `devise` + `devise_token_auth` tokens via `graphql_devise`; client sends `access-token`, `client`, `uid` headers. Facebook and Apple sign-in mutations | `app/models/user.rb:46-50`, `app/graphql/mutations/users/login/*`, `app/interactions/login/*` |
| Business logic | `active_interaction` classes ("interactions") with a custom `steps`/`allow` DSL | `app/interactions/application_interaction*.rb` |
| Real-time | `GraphqlChannel` over ActionCable at `/subscriptions`; subscriptions `loadCreated(dropzoneId)`, `loadUpdated(loadId)`, `userUpdated(dropzoneUserId)`; triggered from model callbacks | `app/channels/graphql_channel.rb`, `app/graphql/subscriptions/*`, `app/models/load.rb:115-136`, `app/models/dropzone_user.rb:219-228` |
| Background jobs | ActiveJob with the **default adapter** (no Sidekiq/GoodJob configured → Rails 7.0 default `:async`, in-process). Jobs: `NotifyJob` (Expo push), `RequestRigInspectionJob` (called synchronously), `WindsAloftJob` (empty) | `app/jobs/*` |
| Scheduled tasks | Rake tasks `dropzone:master_log:generate` and `dropzone:loads:finalize`; **no scheduler is configured in either repo** (presumably Heroku Scheduler/cron once) | `lib/tasks/dropzone.rake` |
| Push notifications | `Notification` row → `NotifyJob` → HTTP POST to `https://exp.host/--/api/v2/push/send` with the user's Expo push token | `app/models/notification.rb:31-49` |
| File storage | ActiveStorage; base64 uploads via `active_storage_base64`; images resized via `image_processing` (vips); services `local`, `test`, `flyio` (`/data`), `google` (GCS) | `config/storage.yml`, `app/models/concerns/image/resizer.rb` |
| Payments | Internal credit ledger only (Order → Receipt → 2 Transactions). **No external payment provider.** | `app/interactions/transactions/*` |
| Third-party services | AppSignal (APM, both repos), Google Geocoding (`geocode` query), markschulze.net winds aloft API (`WeatherCondition#from_coordinates`), APF member API (`Federations::ApfSync`), randomuser.me / picsum.photos (demo seeds only) | |
| Static web app | The API also serves a **stale 2021 web build** at `/` (`app/views/web-build/index.html`, `public/static/js/*`) | `app/controllers/application_controller.rb:7-9` (removed in P2.1) |

### How the two repos interact

- The client has a committed copy of the server schema (`schema.graphql` in the client repo) and generated TypeScript /
  Apollo hooks (`app/api/schema.d.ts`, `operations.ts`, `reflection.tsx`) produced by `graphql-codegen` (`codegen.yml`).
- Pass 1 validated **every client `.gql` document** (41 mutations, 32 queries, 3 subscriptions across
  `app/api/{queries,mutations,subscriptions,fragments}`) against the schema printed by the running server: **0 validation
  errors**, and `graphql-js findBreakingChanges` between the client's `schema.graphql` and the live schema: **0 changes**.
  Contract problems are therefore semantic (wrong arguments for authorization, missing optional arguments, wrong types of
  value), not structural — see BUGS.md (`BUG-040`, `BUG-008`, `BUG-037`).
- Server URLs are compiled into the client (`build/constants.ts`: `local` = `http://local.openmanifest.org:5000/graphql`,
  `staging` = `https://stg.openmanifest.org/graphql`, `production` = `https://prod.openmanifest.org/graphql`), selected
  by `EXPO_ENV` at build time (`app.config.ts`).
- The websocket URL is derived from the GraphQL URL (`ws(s)://<host>/subscriptions`, client
  `app/api/client/links/websockets.ts`). Auth headers are sent as ActionCable channel params and checked in
  `GraphqlChannel#current_resource` (`find_by(email: uid)` — breaks for social logins whose `uid` is not an email).

---

## 3. Multi-tenancy model

- The tenant is the **`Dropzone`**. There is no database-level isolation (no `tenant_id` on every table, no row-level
  security, no Apartment-style schemas).
- Tenant ownership is expressed through foreign keys: `planes.dropzone_id`, `ticket_types.dropzone_id`, `extras.dropzone_id`,
  `user_roles.dropzone_id`, `dropzone_users.dropzone_id`, `rigs.dropzone_id` (dropzone-owned rigs), `master_logs`,
  `weather_conditions`, `form_templates`, `orders`, `events`. **`loads` has no `dropzone_id`**: a load belongs to a dropzone
  only via `loads.plane_id → planes.dropzone_id` (`app/models/load.rb:27-28`). Slots reach the dropzone via
  `slot → load → plane → dropzone`.
- A `User` is global; membership is `DropzoneUser` (`user_id`, `dropzone_id`, role, credits, membership `expires_at`,
  `license_id`, `jump_count`).
- Authorization is checked in three inconsistent places:
  1. `authorized?` methods on some mutations, usually via `context[:current_resource].can?(perm, dropzone_id:)`
     (`app/models/user.rb:84-86`) — which **creates a membership** in that dropzone as a side effect (`BUG-005`);
  2. `allow :permission` on interactions, checked by `ApplicationInteraction::Access#authorize!` against the
     `ApplicationInteraction::AccessContext` built from the request's dropzone;
  3. ad-hoc checks inside interactions/resolvers.
- **Query resolvers do not check tenancy at all** except `dropzones`/`dropzone` (which use `Dropzone.for(user)`). Any
  authenticated user can read loads, users (with email/phone), planes, tickets, activity logs and blobs of any dropzone
  (`BUG-002`, `BUG-003`, `BUG-004`). The request-scoped access context is a process-wide **Singleton**
  (`app/graphql/access_context/current_user.rb:2`) that leaks between requests and threads (`BUG-001`).

Conclusion: tenant isolation must be treated as **absent** until the Phase 6 security tasks land.

---

## 4. Domain model

ER diagram: [`diagrams.md` §2](diagrams.md#2-entity-relationship-diagram). Schema source: `db/schema.rb` (version
`2023_04_09_034757`, 111 migrations in `db/migrate`).

| Entity (table) | Meaning | Key fields | Invariants / notes |
|---|---|---|---|
| `Dropzone` (`dropzones`) | Tenant: a skydiving centre | `name`, `federation_id`, `lat`/`lng`, `time_zone` (default `Australia/Brisbane`), `state` (visibility state machine), `settings` jsonb, `is_credit_system_enabled`, `credits` (**integer**), colours, `rig_inspection_template_id`, counters `users_count`, `loads_count`, `slots_count` | Soft-deleted (`discarded_at`). Settings defaults in `app/models/concerns/dropzones/configuration.rb:29-50` are all "strict" (`require_membership: true` …) |
| `Federation` | National parachuting body (e.g. APF) | `name`, `slug` (unique) | Seeded from `config/seed/global.yml` |
| `License` | Licence level within a federation | `name`, `federation_id`; unique (`name`, `federation_id`) | |
| `JumpType` | Kind of skydive (freefly, angle, hop-n-pop, tandem, AFF…) | `name`, `slug` (unique) | Global, seeded |
| `LicensedJumpType` | Which jump types a licence allows | `license_id`, `jump_type_id` (unique pair) | |
| `Qualification`, `UserFederation`, `UserFederationQualification` | A user's membership/licence number/qualifications in a federation | `uid` (e.g. APF number), `license_id` | `UserFederation` after_save copies the licence to the user's `DropzoneUser`s in that federation (`app/models/user_federation.rb:17-24`) |
| `User` | Global person account (devise) | `email`, `name`, `phone`, `exit_weight` (kg, float), `push_token`, `time_zone`, `moderation_role`, `jump_count`, `dropzone_count`, `apf_number`, `tokens` | Unique email; `provider`/`uid` unique |
| `DropzoneUser` (`dropzone_users`) | Membership of a user at a dropzone | `user_role_id`, `credits` (**float**), `expires_at` (membership expiry), `license_id`, `jump_count`, `discarded_at` | `validates :user_id, uniqueness: { scope: :dropzone_id }` but **no unique index** (`BUG-050`) |
| `UserRole`, `Permission`, `UserRolePermission`, `UserPermission` | RBAC per dropzone | `permissions.name` unique | Role hierarchy is implied by role **id order** (`UserRole.below/above`, `app/models/user_role.rb:26-27`) |
| `Plane` (`planes`) | Aircraft | `name`, `registration`, `min_slots`, `max_slots`, `hours`, `next_maintenance_hours` | Soft-deleted |
| `Load` (`loads`) | One aircraft lift | `plane_id`, `load_number` (per dropzone per day), `name`, `max_slots`, `state` (enum), `dispatch_at` (call/take-off time), `has_landed`, `is_open`, `pilot_id`, `gca_id`, `load_master_id` (all `DropzoneUser`), counters `slots_count`, `ready_slots_count` | `validates :gca, :pilot` presence. Counters are wrong (`BUG-019`). See lifecycle below |
| `Slot` (`slots`) | A seat on a load | `load_id`, `dropzone_user_id` **or** `passenger_id`, `ticket_type_id`, `jump_type_id`, `rig_id`, `exit_weight`, `group_number`, `passenger_slot_id` (tandem instructor → passenger slot), `created_by_id` | Validations on create: capacity, double manifest, licence/jump type, membership, credits (`app/models/slot.rb:57-62`). No unique (`load_id`, `dropzone_user_id`) index |
| `Passenger` | Non-member tandem passenger | `name`, `exit_weight`, `dropzone_id` | |
| `TicketType` | Product sold per slot ("Full altitude", "Tandem") | `cost` (float), `currency`, `altitude` (int, feet by convention), `allow_manifesting_self`, `is_tandem` | Soft-deleted |
| `Extra`, `TicketTypeExtra`, `SlotExtra` | Add-ons (video, photo) | `cost` | `SlotExtra` rows are **never created** by any code path (`BUG-028`) |
| `Rig` | Parachute system | `make`, `model`, `serial`, `canopy_size` (sq ft), `repack_expires_at`, `rig_type` (`student`/`sport`/`tandem`), `is_public`, `user_id` or `dropzone_id`, `packing_card` attachment | Soft-deleted |
| `FormTemplate` | Rig inspection form (JSON definition) | `definition` (JSON text), `dropzone_id` | Default form in `RigInspection.default_form` |
| `RigInspection` | Result of inspecting a rig at a dropzone | `rig_id`, `dropzone_user_id` (owner), `inspected_by_id`, `is_ok`, `definition` | |
| `Pack` | Pack job (rig packed by user) | `rig_id`, `user_id` | No API exposes it (only `Transactions::Purchase` price stub) |
| `WeatherCondition` | Weather for a day | `winds` (JSON text: altitude/speed/direction/temperature), `temperature`, `jump_run` (degrees), `exit_spot_miles`, `offset_miles` (**integer** columns), `offset_direction` | Created on first read of `Dropzone#current_conditions`, which calls an external API in `before_create` |
| `MasterLog` | Daily regulatory log | `date`, `dzso_id`, `notes`, attached JSON file | `after_create :store!` |
| `Order`, `Receipt`, `Transaction` | Credit ledger | `orders`: polymorphic `buyer`/`seller` (Dropzone or DropzoneUser), polymorphic `item`, `amount` (float), `state` (pending/completed/refunded/cancelled), `order_number` per dropzone; `receipts.amount_cents` (int); `transactions`: `sender`/`receiver`, `amount`, `status` (reserved/completed/cancelled), `transaction_type` (purchase/sale/deposit/withdrawal/refund) | Wallet balance is the denormalised `credits` column, updated with `increment!`/`decrement!` |
| `Notification` | In-app + push notification | `received_by_id` (DropzoneUser), `sent_by_id`, polymorphic `resource`, `notification_type` enum (14 values), `is_seen` | `after_create` enqueues `NotifyJob` |
| `Activity::Event` (`events`) | Audit/activity log | `resource`, `action`, `level`, `access_level`, `message`, `details`, `dropzone_id`, `dropzone_user_id` | Written by almost every interaction's `success`/`error` block |
| `AuthenticationProvider` | Facebook/Apple identity link | `provider`, `uid`, `token` | |
| `Admin` | Unused second devise model | | No routes or mutations use it |

### Lifecycles

**Load** (`app/models/load.rb`, `app/models/concerns/state_machines/load_state.rb`, `app/interactions/manifest/*`).
`state` is both a Rails `enum` and a `state_machines` machine on the same integer column. Effective behaviour:

| From | To | Trigger (code path) |
|---|---|---|
| (new) | `open` | `createLoad` (`Manifest::CreateLoad`) |
| `open` | `boarding_call` | `updateLoad(dispatchAt: <time>, state: BOARDING_CALL)` — client "20/15/10-minute call" or custom time (`useLoad.dispatchInMinutes`, client `app/api/crud/useLoad.tsx:136-149`). `Load#notify!` sends "call changed to take off at HH:MM" push to everyone with a slot |
| `boarding_call` | `open` | `updateLoad(dispatchAt: null, state: OPEN)` — "Cancel boarding call" |
| `open` | `cancelled` | `finalizeLoad(state: CANCELLED)` → `Manifest::CancelLoad` (refunds every slot's order); also `dropzone:loads:finalize` for undispatched past loads |
| `boarding_call`/`in_flight` | `landed` | `finalizeLoad(state: LANDED)` → `Manifest::FinalizeLoad` (confirms every slot's reserved transactions); also auto-finalize for dispatched past loads |
| `cancelled`/`landed` | `open` | client "Re-open load" → `updateLoad(state: OPEN, dispatchAt: null)` (only same day) |
| any | `in_flight` | **No code path sets it** (enum value exists, client renders it) |

`updateLoad` accepts any `state` value without transition rules (`app/interactions/manifest/update_load.rb:19,116`), so the
table above is what the client does, not what the server enforces (`BUG-035`). State diagram:
[`diagrams.md` §6](diagrams.md#6-state-diagrams).

**Dropzone visibility** (`app/models/concerns/state_machines/dropzone_state.rb`): `private → in_review`
(request_publication), `any → public` (publish, moderator only), `any → private` (unpublish), `any → archived`,
`any → demo`.

**Order/Transaction**: Purchase creates order `pending` + 2 transactions `reserved`; Confirm marks transactions
`completed` and the order `completed`; Refund creates a negative receipt + reversed transactions, confirms both, marks
order `refunded`. Credits move immediately at purchase time (not at confirmation).

---

## 5. Feature inventory

Status legend: **complete** = works end-to-end in pass-1 testing or reading; **partial** = works with notable gaps;
**broken** = a primary path fails.

| Feature | Client screens / components | API operations | Status | Evidence |
|---|---|---|---|---|
| Email sign-up / login / logout | `screens/unauthenticated/*`, `forms/sign_up/*`, `components/drawer/Drawer.tsx` | `userRegister`, `userLogin` | partial | Login works on web (pass-1 run). Logout breaks all later requests in the same app session (`BUG-063`) |
| Email confirmation, password recovery | `screens/wizards/confirm_user`, `recover_password`, `change_password` | `userConfirmRegistrationWithToken`, `userSendPasswordResetWithToken`, `userUpdatePasswordWithToken` | partial (unverified: needs SMTP) | |
| Facebook / Apple login | `login/form/FacebookButton*.tsx`, `AppleButton*.tsx` | `loginWithFacebook`, `loginWithApple` | broken/unverifiable | `expo-facebook` is not part of Expo SDK 47 (absent from its `bundledNativeModules.json`); Apple error path raises the wrong exception (`BUG-054`) |
| Dropzone selection & switching | `screens/limbo/dropzone_select/*`, drawer | `dropzones`, `dropzone` | complete | pass-1 web run |
| Dropzone setup wizard | `screens/wizards/dropzone_wizard/*` | `createDropzone`, `updateDropzone`, `geocode` | partial | Banner upload on update raises (`BUG-041`); wizard layout overflows on 360 dp (`BUG-070`) |
| Dropzone settings | `configuration/dropzone_settings`, `settings_menu` | `updateDropzone(settings)` | partial | Default settings block manifesting for users without membership dates (`BUG-033`) |
| Publication / visibility | `overview/AdminOverview.tsx`, `DropzonesTable.tsx` | `updateVisibility` | complete (reading) | |
| Manifest board (today's loads) | `dropzone/manifest/ManifestScreen.tsx`, `LoadCard/*`, `Weather/*` | `loads`, `loadCreated` subscription | partial | Works on web; counters wrong (`BUG-019`); pull-to-refresh refreshes the wrong query (`BUG-065`); date is device-local (`BUG-068`) |
| Load detail & calls | `dropzone/load/*` | `load`, `updateLoad`, `finalizeLoad`, `loadUpdated` | partial | Changing max slots inverted (`BUG-025`) |
| Manifest self / others | `forms/manifest_user/*` | `createSlot` | partial | No server-side check of "manifest others" permission (`BUG-006`) |
| Group manifest | `components/dialogs/ManifestGroup/*`, `forms/manifest_group` | `createSlots` | partial | Group split across group numbers (`BUG-027`); dialog only mounted on LoadScreen (`BUG-066`) |
| Move slot (drag & drop, web) | `components/slots_table/DragAndDrop/*.web.tsx` | `moveSlot` | broken | crashes with target slot (`BUG-031`), no authorization (`BUG-007`) |
| Take off load | slot row delete | `deleteSlot` | partial | Slots without orders crash (`BUG-032`) |
| Tandem passengers | manifest form passenger fields | `createSlot(passengerName, passengerExitWeight)` | partial | Finalising a load with a tandem crashes (`BUG-030`) |
| Credits (wallet) | `forms/credits/*`, profile transactions tab, `configuration/transactions` | `createOrder`, `dropzone.orders` | partial | Money stored as floats (`BUG-048`); peer-to-peer credit minting (`BUG-008`) |
| Users list / profile / edit | `screens/authenticated/user/*` | `dropzoneUsers`, `dropzoneUser`, `updateUser`, `updateDropzoneUser`, `deleteUser` | broken | `updateDropzoneUser` always errors after saving (`BUG-037`); editing other users' profiles raises (`BUG-038`) |
| Create user ("ghost") | `forms/create_user/*` | `createGhost` | partial | GitHub issue client#126 "Create Ghost doesn't fire submit button" |
| Permissions & roles | `configuration/permissions/PermissionsScreen.tsx`, profile badges | `grantPermission`, `revokePermission`, `updateRole` | complete (reading) | |
| Equipment (rigs) | `user/equipment`, `configuration/rigs`, `components/dialogs/Rig.tsx` | `createRig`, `updateRig`, `archiveRig`, `availableRigs` | partial | Packing card upload raises (`BUG-041`); `archiveRig` crashes for others (`BUG-039`) |
| Rig inspections | `user/rig_inspection`, `configuration/rig_inspection_template` | `createRigInspection`, `updateFormTemplate` | partial | Notifications never sent (`BUG-042`) |
| Aircraft, ticket types, add-ons | `configuration/aircrafts`, `ticket_types`, `extras`, `forms/aircraft`, `ticket_type*` | `createPlane`, `updatePlane`, `deletePlane`, `createTicketType`, `updateTicketType`, `archiveTicketType`, `createExtra`, `updateExtra` | partial | `archiveTicketType` crashes (`BUG-039`); add-ons never charged (`BUG-028`) |
| Weather / winds / jump run | `dropzone/weather_conditions/*`, `manifest/Weather/*` | `dropzone.currentConditions`, `createWeatherCondition`, `reloadWeatherCondition` | broken | Reload fails (`BUG-040`); external HTTP in model callback (`BUG-045`) |
| Master log | `configuration/master_log/*` | `masterLog`, `updateMasterLog` | partial | Scheduled generation crashes and is not scheduled (`BUG-044`) |
| Notifications (in-app & push) | `screens/authenticated/notifications/*`, `entrypoint/providers/PushNotificationProvider.tsx` | `dropzone.currentUser.notifications`, `updateUser(pushToken)` | partial | In-process async jobs, errors swallowed (`BUG-052`) |
| Activity feed / statistics | `overview/*`, `components/activity/*` | `activity`, `dropzone.statistics` | partial | Activity leaks across tenants (`BUG-003`) |
| Federation / licence sync (APF) | `forms/user_wizard/steps/Federation*.tsx`, `License.tsx` | `joinFederation`, `federations`, `licenses` | partial (external API unverified) | |
| Demo data generator | — | `Mutations::Setup::Demo::Generate` | dead | Not mounted in `MutationType` |
| Pack jobs | — | — | not implemented | model only |

---

## 6. Client summary

Full client reference: client repo `docs/reference/README.md` (navigation map, screen list, store shape, platform files).
Key facts needed from the backend side:

- Expo SDK 47.0.13, React Native 0.70.8, React 18.1.0, TypeScript 4.9.4 (installed), Apollo Client 3.7.11,
  Redux Toolkit 1.9.3 + redux-persist 6, React Navigation 6, react-native-paper 4.12.
- State: Redux holds the session (credentials, current dropzone snapshot), theme, and ~14 form/screen slices; server data
  lives in the Apollo cache, with a duplicated snapshot of the current dropzone/user in Redux (persisted).
- Auth: `userLogin` credentials (`accessToken`, `client`, `uid`, `expiry`, `tokenType`) are persisted in Redux
  (AsyncStorage on native, `localStorage` on web) and sent as headers by `app/api/client/links/authentication.ts`.

---

## 7. Backend detail

### GraphQL entry points

Query fields (`app/graphql/types/query_type.rb`): `image`, `federations`, `jumpTypes`, `licenses`, `currentUser`,
`dropzoneUser`, `dropzoneUsers`, `masterLog`, `dropzones`, `dropzone`, `loads`, `load`, `planes`, `ticketTypes`,
`extras`, `availableRigs`, `activity`, `geocode`. Every field requires authentication (graphql_devise default) — pass 1
confirmed `federations` returns `AUTHENTICATION_ERROR` when anonymous.

Mutation fields (`app/graphql/types/mutation_type.rb`) plus graphql_devise's `userLogin`, `userLogout`, `userRegister`
(overridden by `Mutations::Users::SignUp`), `userSendPasswordResetWithToken`, `userUpdatePasswordWithToken`,
`userConfirmRegistrationWithToken`, `userResendConfirmationWithToken`.

| Mutation | Server authorization actually enforced | Interaction |
|---|---|---|
| `createLoad` | `allow :createLoad` (the mutation's `authorized?` is defined **outside the class**, `app/graphql/mutations/manifest/create_load.rb:33-36`, so it never runs) | `Manifest::CreateLoad` |
| `updateLoad` | `allow :updateLoad` | `Manifest::UpdateLoad` |
| `finalizeLoad` | `updateLoad` via `authorized?` | `Manifest::FinalizeLoad` / `CancelLoad` |
| `deleteLoad` | `allow deleteLoad` | `Manifest::DeleteLoad` (not used by client) |
| `createSlot` | `allow :createSlot` only | `Manifest::CreateSlot` |
| `createSlots` | `authorized?` mixing user ids and dropzone-user ids (`create_slots.rb:25-71`) | `Manifest::CreateMultipleSlots` |
| `moveSlot` | none | `Manifest::MoveSlot` |
| `deleteSlot` | `deleteSlot`/`deleteUserSlot` inside interaction | `Manifest::DeleteSlot` |
| `updateSlot` | `authorized?` raises `NoMethodError` (`update_slot.rb:47`) | inline (not used by client) |
| `createOrder` | buyer==self peer-to-peer allowed with no balance check, else `createUserTransaction` | `Transactions::CreateOrder` |
| `grantPermission` / `revokePermission` | `grantPermission`/`revokePermission` + must hold the permission (except `actAs*`) | `Access::*` |
| `updateRole` | `updatePermissions` | inline |
| `updateVisibility` | owner/moderator inside interaction | `Setup::Dropzones::UpdateVisibility` |
| `createDropzone` | any authenticated user | `Setup::Dropzones::CreateDropzone` |
| `updateDropzone` | `updateDropzone`; publication change requires moderator | inline |
| `deleteDropzone` | crashes (`context[:current_user]`) | inline |
| `createPlane` / `updatePlane` / `deletePlane` | `createPlane` / `updatePlane` / `deletePlane` | `Setup::Aircrafts::CreateAircraft` / inline |
| `createTicketType` / `updateTicketType` / `archiveTicketType` | `createTicketType` / `updateTicketType` / crashes | inline |
| `createExtra` / `updateExtra` | `createExtra` against **client-supplied** `dropzoneId` / `updateExtra` | inline |
| `createRig` / `updateRig` / `archiveRig` | self or `createRig` / self or `updateDropzoneRig` / self only (others crash) | inline |
| `createRigInspection` | `allow actAsRigInspector` | `Setup::Equipment::CreateRigInspection` |
| `updateRigInspection` / `updateFormTemplate` | `actAsRigInspector` / `updateFormTemplate` against **client-supplied** `dropzoneId` | inline |
| `createWeatherCondition` / `reloadWeatherCondition` | `updateWeatherConditions` against client-supplied `dropzoneId` | inline |
| `updateMasterLog` | `allow updateDropzone` | `MasterLog::Update` |
| `createGhost` | `allow :createUser` | `Setup::Users::CreateGhost` |
| `updateUser` | self, or crashes for others | `Users::UpdateUser` |
| `updateDropzoneUser` | `updateUser`; role change needs `grantPermission` and a lower role id | inline (crashes on success) |
| `deleteUser` | self or `deleteUser` | inline |
| `updateNotification` | recipient only | inline |
| `joinFederation` | self | `Federations::AssignUser` |
| `loginWithFacebook` / `loginWithApple` | none (public) | `Login::*` |

### Jobs and scheduled tasks

| Name | What it does | How it runs | Status |
|---|---|---|---|
| `NotifyJob` | Sends Expo push for a `Notification` | `perform_later` from `Notification#after_create` → `:async` adapter | Works when the process stays up; no retries; errors swallowed |
| `RequestRigInspectionJob` | Notifies rig inspectors | `perform_now(rig, self)` but expects ids; errors swallowed | Dead (`BUG-042`) |
| `WindsAloftJob` | Empty | never | Dead |
| `dropzone:master_log:generate` | Generates yesterday's master log for dropzones where it is midnight | Rake; needs hourly cron | Crashes (`BUG-044`); no scheduler configured |
| `dropzone:loads:finalize` | Auto-lands dispatched / auto-cancels undispatched past loads | Rake; needs daily cron | Crashes on tandem loads (`BUG-030`); no scheduler configured |

### Seeds

- `db/seeds.rb` → `Setup::Global::Seeds.run!`: jump types, federations, licences, licensed jump types (from
  `config/seed/global.yml`) and permissions (from `config/seed/access.yml`). Idempotent.
- `db/seeds/demo.rb`, `db/seeds/demoloads.rb` (run with `bin/rails db:seed:demo`): demo dropzone using
  **randomuser.me and picsum.photos** — both blocked in the cloud VM. Phase 0 adds an offline seed (`P0.5`).

---

## 8. Build, run and deploy (as configured in 2023)

### Backend

- Ruby **3.1.3** (`.ruby-version`, `Gemfile:6`), Bundler 2.3.26, Rails 7.0.4, Puma 6 (`config/puma.rb`, 2 workers by
  default via `WEB_CONCURRENCY`).
- Deploy targets (all four workflow families exist; which one was live in 2023 is unknown):
  - Fly.io: `.github/workflows/release-staging.yml` (push to `staging`) and `release-production.yml` (push to `main`),
    `fly.toml` / `fly-production.toml`, `lib/tasks/fly.rake` (adds a swapfile, runs `db:migrate` as release command).
    **There is no Dockerfile at the repo root**, so the Fly build relied on a builder/buildpack configuration that is not in the repo.
  - Dokku on `dangertechnologies.com`: `release-dokku-*.yml` (push to `staging` / `main`).
  - Heroku: `release-heroku-*.yml` (push branches list empty → manual only), `Procfile`, `Aptfile`.
  - Docker image for local/other use: `docker/Dockerfile` (Ruby 3.1.3 Alpine + nginx), `docker/Procfile`, `docker/nginx.conf.tmpl`.
- CI: `.github/workflows/specs.yml` (Rubocop + parallel RSpec on Postgres; `continue-on-error: true` on the RSpec step,
  so red specs never failed the build). A CircleCI badge is in the README but there is no `.circleci` directory.

Environment variables (names only):

| Variable | Used by |
|---|---|
| `SECRET_KEY_BASE`, `RAILS_MASTER_KEY` | Rails / devise secret (`config/initializers/devise.rb:2`) |
| `BACKEND_URL` | `default_url_options` host, ActionCable URL (**required** — boot fails in development/production if unset) |
| `FRONTEND_URL` | mailer URLs, confirmation redirect (**required in production**) |
| `PGUSER`, `PGPASSWORD`, `DBNAME`, `DATABASE_URL` (production via platform) | database |
| `REDIS_URL` | ActionCable, production cache |
| `RAILS_MAX_THREADS`, `RAILS_MIN_THREADS`, `WEB_CONCURRENCY`, `PORT`, `PIDFILE` | Puma |
| `RAILS_ENV`, `RAILS_LOG_TO_STDOUT`, `RAILS_SERVE_STATIC_FILES`, `BACKTRACE` | Rails |
| `SMTP_SERVER`, `SMTP_PORT`, `SMTP_DOMAIN`, `SMTP_USERNAME`, `SMTP_PASSWORD` | mail |
| `GOOGLE_PROJECT`, `GOOGLE_BUCKET`, `GOOGLE_BUCKET_CREDENTIALS` (base64 JSON) | ActiveStorage GCS |
| `GOOGLE_MAPS_KEY` | Geocoding |
| `APPSIGNAL_PUSH_API_KEY`, `APPSIGNAL_DISABLE_INTERACTION_METRICS` | AppSignal |
| GitHub secrets: `FLY_API_TOKEN`, `DOKKU_DEPLOY_KEY`, `HEROKU_API_KEY`, `HEROKU_EMAIL` | deploy workflows |

### Client

See the client reference. Summary: `yarn` 1, Expo CLI via `npx expo`, `EXPO_ENV` ∈ {`local`,`staging`,`production`}
chooses the API URL; EAS Build profiles `development`/`staging`/`production` (`eas.json`); EAS Update channel per
environment; web built with `expo export:web` (webpack) and pushed to GitHub Pages repos
`OpenManifest/openmanifest-web` / `openmanifest-web-staging` (`.github/workflows/publish.yml`).

---

## 9. Local setup notes (what pass 1 had to do in the cloud VM)

Nothing below was committed. Each item becomes a Phase 0 task.

| Step | What happened | Resolution used in pass 1 |
|---|---|---|
| Ruby | Project pins 3.1.3; VM has 3.1.6 / 3.2.6 / 3.3.6 via rbenv. `cache.ruby-lang.org` is **blocked**, so `rbenv install` cannot download other versions | Patched `Gemfile` `ruby "3.1.6"` and `.ruby-version` in a scratch copy; `RBENV_VERSION=3.1.6` |
| Bundler | `gem install bundler -v 2.3.26` | worked |
| `pg` gem | Failed: `libpq-fe.h` missing | `apt-get install -y libpq-dev` |
| Images | `image_processing` needs libvips | `apt-get install -y libvips42 imagemagick` |
| AppSignal | Native extension download blocked (`appsignal-agent-releases.global.ssl.fastly.net`); gem prints `LoadError: cannot load such file -- appsignal_extension` but the app boots | Ignored |
| Services | `service postgresql start; service redis-server start`; `CREATE ROLE root SUPERUSER LOGIN PASSWORD 'root'` | |
| Env | `PGHOST=localhost PGUSER=root PGPASSWORD=root SECRET_KEY_BASE=dummy BACKEND_URL=http://local.openmanifest.org:5000/ DISABLE_SPRING=1 WEB_CONCURRENCY=0` | |
| Test DB | `RAILS_ENV=test bin/rails db:create db:schema:load` (database name is `openmanifest_test_` + `TEST_ENV_NUMBER`) | |
| Specs | `bundle exec rspec`: **187 examples, 64 failures, 6 pending** in 43 s. 55 failures are "membership has expired" (dropzone default settings, `BUG-033`), 8 are `created_by` nil (`BUG-034`), 2 are slots without orders (`BUG-030`), 1 is order-dependent (`spec/graphql/resolvers/users/dropzone_users_spec.rb`) | Baseline recorded in `P0.3` |
| Rubocop | Clean on the repo (`bundle exec rubocop --parallel`) | |
| `bundle-audit` | 133 advisories in 32 gems, incl. `graphql` (critical), `rack` (12 high), `puma`, `nokogiri`, `jwt`, `geokit-rails`, `activerecord` | Inventory in §10 |
| Dev boot | `bin/rails db:create db:schema:load db:seed`, offline seed script (users, dropzone, plane, tickets, two loads), `bin/rails s -p 5000` → `/graphql` 200, `userLogin` works | Seed script content is the basis of `P0.5` |
| Host name | Client `local` endpoint is `local.openmanifest.org:5000`; added `127.0.0.1 local.openmanifest.org` to `/etc/hosts` (it is also in `config.hosts`, `config/environments/development.rb:5-7`) | |
| Websocket from headless Chromium | 403 because Chromium routes `ws://local.openmanifest.org` through the agent proxy | Launch Chromium with `--proxy-bypass-list=local.openmanifest.org` or add the host to `NO_PROXY` |

Client-side notes (yarn, Node 20, `SENTRYCLI_SKIP_DOWNLOAD=1`, web export) are in the client reference §8.

---

## 10. Dependency inventory

Checked 2026-10-08 against RubyGems API (`rubygems.org/api/v1|v2`), `npm view`, `nodejs.org/dist/index.json`,
`raw.githubusercontent.com/nodejs/Release/main/schedule.json`, `ruby-lang.org/en/downloads/branches/`, and Expo's
`bundledNativeModules.json` from each `expo@<sdk>` npm tarball. "Verified = yes" means the current/latest numbers came from
those live sources in pass 1; EOL/breaking-change notes marked *(web)* came from official pages found by web search and
are summarised, not exhaustively checked.

### Runtimes and frameworks

| Package | Current | Latest stable | Gap | EOL / deprecated | Breaking-change notes | Verified |
|---|---|---|---|---|---|---|
| Ruby | 3.1.3 | 4.0.7 (3.4.11 latest 3.x) | 1 major, 3 minors | 3.1 EOL 2025-03-26; 3.2 EOL 2026-04-01; 3.3 security-only until 2027-03-31 | Ruby 3.4: frozen string literal warnings, `it` block param; 4.0: check gem native extensions | yes |
| Rails | 7.0.4 | 8.1.4 (2026-09-24) | 1 major + 3 minors | 7.0 and 7.1 EOL (final 7.0.10, 7.1.6 — *web*: rubyonrails.org 2025-10-29); 7.2 security support ended 2026-08-09 *(web)*; 8.0 security until 2026-11-07 *(web)*; 8.1 security until 2027-10-10 *(web)* | Step 7.0→7.1→7.2→8.0→8.1 with `new_framework_defaults_*`; 8.0 requires Ruby ≥ 3.2 | yes |
| Node (client tooling) | CI used 16/18 | 24.21.0 LTS "Krypton" (EOL 2028-04-30); 26.x becomes LTS 2026-10-28 | — | 16, 18 EOL; 20 EOL 2026-04-30; 22 EOL 2027-04-30 | | yes |
| PostgreSQL | 16 in VM (prod unknown) | — | — | — | `pg` gem 1.4.5 → 1.7.0 | partial |
| Redis | 7 in VM | — | — | — | `redis` gem 4.8 → 6.0 (ActionCable on Rails ≥ 7.1 supports redis-client) | partial |

### Backend gems (Gemfile.lock)

| Gem | Current | Latest | Gap | EOL / security | Notes | Verified |
|---|---|---|---|---|---|---|
| rails | 7.0.4 | 8.1.4 | 1 major | see above; bundle-audit lists advisories in actionpack, activerecord (SQL injection via comments, PG DoS), activestorage, activesupport, actionview, actiontext, actionmailer | | yes |
| graphql | 2.0.16 | 2.6.11 | 6 minors | **critical** advisory (RCE when loading crafted schema), unsafe Marshal in parser cache | graphql_devise caps graphql (see next row) | yes |
| graphql_devise | 1.2.0 | 2.4.0 | 1 major | — | Compatibility: 1.2 → rails < 7.1, graphql < 2.1; 1.5.0 → rails < 7.2, graphql < 2.4; 2.0.0 → rails < 7.3, graphql < 2.5; 2.1.0 → rails < 8.1, graphql < 2.6; 2.4.0 → rails < 8.2, graphql < 2.7 | yes |
| devise_token_auth | 1.2.1 | 1.3.0 | minor | — | 1.3.0: rails < 8.3, devise < 6 | yes |
| devise | 4.8.1 | 5.0.4 | 1 major | 2 medium advisories (confirmable race, open redirect) | | yes |
| puma | 6.0.2 | 8.0.2 | 2 majors | 2 high + 3 medium advisories | | yes |
| rack | 2.2.5 | (follows rails) | — | 12 high, 11 medium advisories | Rails 7.1+ allows Rack 3 | yes |
| pg | 1.4.5 | 1.7.0 | minor | — | needs `libpq-dev` to build | yes |
| redis | 4.8.0 | 6.0.0 | 2 majors | — | | yes |
| active_interaction | 5.2.0 | 5.5.0 | minor | — | activesupport < 9 | yes |
| active_interaction-extras | 1.0.4 | 1.1.0 | minor | — | | yes |
| counter_culture | 3.3.0 | 3.14.0 | minor | — | | yes |
| state_machines-activerecord | 0.8.0 | 0.200.0 | — | — | 0.200.0 requires activerecord ≥ 7.2 and Ruby ≥ 3.2 | yes |
| discard | 1.2.1 | 2.0.0 | 1 major | — | activerecord ≥ 7.0, < 9 | yes |
| appsignal | 3.3.1 | 5.0.2 | 2 majors | — | native agent download blocked in VM | yes |
| geokit-rails | 2.3.2 | 2.5.0 | minor | **high**: command injection | | yes |
| httparty | 0.21.0 | 0.24.3 | minor | high: SSRF/API key leakage | | yes |
| jwt | 2.6.0 | 3.3.0 | 1 major | high: empty-key HMAC bypass | used by Apple login (`JWT.decode`, `JWT::JWK.import`) | yes |
| rack-cors | 1.1.1 | 3.0.0 | 2 majors | — | | yes |
| bootsnap | 1.15.0 | 1.26.0 | minor | — | | yes |
| search_cop | 1.2.3 | 1.6.0 | minor | — | | yes |
| activerecord-import | 1.4.1 | 2.3.0 | 1 major | — | used by seeds/defaults | yes |
| active_storage_base64 | 2.0.0 | 3.0.1 | 1 major | — | activestorage > 7.0 | yes |
| image_processing | 1.12.2 | 2.2.0 | 1 major | — | | yes |
| google-cloud-storage | 1.44.0 | 1.62.1 | minor | — | | yes |
| sprockets | 4.2.0 | 4.4.1 | minor | — | only needed for graphiql-rails assets | yes |
| graphiql-rails | 1.8.0 | 1.10.5 | minor | — | | yes |
| dotenv-rails | 2.8.1 | 3.2.0 | 1 major | — | | yes |
| bcrypt | 3.1.18 | 3.1.22 | patch | JRuby-only advisory | | yes |
| nokogiri | 1.14.3 | (follows rails) | — | 2 high + many | | yes |
| faker | 3.1.0 | 3.8.0 | minor | — | runtime dependency (Gemfile top level) | yes |
| rspec-rails | 5.1.2 | 8.0.4 | 3 majors | — | | yes |
| factory_bot_rails | 6.2.0 | 6.5.1 | minor | — | | yes |
| rubocop | 1.50.2 | 1.91.0 | minor | — | | yes |
| yard | 0.9.24 (pinned) | — | — | high + 2 medium | dev only; remove | partial |
| selenium-webdriver, webdrivers, capybara | locked | — | — | selenium high | no system specs exist; removed in P2.1 | partial |

### Client packages

See the client reference §10 for the full table (Expo SDK 47 → 57, React Native 0.70 → 0.86, React 18.1 → 19.2, etc.).
Headline numbers:

| Package | Current | Latest stable | Gap | Verified |
|---|---|---|---|---|
| expo | 47.0.13 | 57.0.27 (`latest` tag; 58 is `next`) | 10 SDKs | yes |
| react-native | 0.70.8 | 0.86.3 (pinned by SDK 57) | 16 minors | yes |
| react | 18.1.0 | 19.2.3 (pinned by SDK 57) | 1 major | yes |
| @apollo/client | 3.7.11 | 4.3.2 | 1 major | yes |
| yarn audit | 715 advisories (61 critical, 452 high, 161 moderate, 41 low) in 2078 packages | | | yes (historical: the backend's `package.json`/`yarn.lock` were removed in P2.1) |
