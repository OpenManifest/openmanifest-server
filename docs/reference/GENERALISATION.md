# Generalisation analysis: from "skydiving dropzone" to "dispatching loads of people on vehicles"

The owner wants OpenManifest to serve any business that dispatches **loads of people (and possibly cargo) on vehicles to
destinations at scheduled times**: skydiving dropzones, dive-boat operators, tour-bus companies and similar. This document
inventories every skydiving-specific concept in both repos, proposes generic abstractions, a configuration model
("industry profiles"), unit and terminology handling, a data-migration path and a naming strategy, and lists the
questions only the owner can answer.

Code described: backend `b8dc33a`, client `3112795` (pass 1, 2026-10-08). Phase 7 of
[`../MODERNISATION_PLAN.md`](../MODERNISATION_PLAN.md) implements this after the stack is modern and secure.

## 1. Inventory of skydiving-specific concepts

| # | Concept (code name) | What it is in skydiving | Where it lives |
|---|---|---|---|
| 1 | **Dropzone** (`Dropzone`, `dropzones`, `dropzoneId` everywhere) | The business/site: the tenant | backend `app/models/dropzone.rb`, ~every resolver/mutation argument (`dropzone`, `dropzoneId`); client `app/providers/dropzone/*`, `screens/limbo/dropzone_select/*`, route paths `/dropzone/...` (`app/screens/routes.tsx:28-66`), copy "Create dropzone", "No dropzones?" |
| 2 | **Plane / Aircraft** (`Plane`, `planes`, GraphQL `Aircraft`, `createPlane`) | Vehicle | backend `app/models/plane.rb`, `app/graphql/types/dropzone/aircraft.rb`, `mutations/setup/aircrafts/*`; client `screens/authenticated/configuration/aircrafts/*`, `forms/aircraft/*` (FIXME "Should be AVGAS/Jetfuel", `app/forms/aircraft/useForm.tsx:22`), `components/chips/PlaneChip.tsx`, icon `airplane` on the Manifest tab (`screens/authenticated/routes.tsx:263`) |
| 3 | **Load** (`Load`, `load_number`, "Load #n") | One trip of the vehicle | backend `app/models/load.rb`, `mutations/manifest/*`; client `screens/authenticated/dropzone/load/*`, `manifest/LoadCard/*`, notification copy "Load ##{n} take off at …" (`app/models/load.rb:83`, `load_state.rb:16,29`) |
| 4 | **Altitude** (`ticket_types.altitude` integer, implied feet; UI `/1000 + "k"`) | The destination: exit height | backend `db/schema.rb` `ticket_types.altitude`, master log `altitude` (`concerns/master_log_entry/slot.rb:12`); client `components/slots_table/UserRow.tsx:159,191` (`(altitude \|\| 14000) / 1000}k`), `components/input/dropdown_select/AltitudeSelect.tsx` (hard-coded 4000 "Hop n Pop" / 14000 "Height"), `configuration/ticket_types/TicketTypesScreen.tsx:70,91`, `configuration/master_log/MasterLogScreen.tsx:136,143` |
| 5 | **Slot** (`Slot`) | A seat on the load | backend `app/models/slot.rb`; client "Available" rows (`components/slots_table/AvailableRow.tsx`), `SlotCard*` |
| 6 | **Jumper / DropzoneUser** ("jumper", "fun jumper", `exit_weight`) | Participant | backend `DropzoneUser`, `users.exit_weight`, role `fun_jumper`; client copy "Jumper", profile wizard steps |
| 7 | **Exit weight** (`users.exit_weight`, `slots.exit_weight`, kg) | Participant body weight + gear, for wing loading and aircraft weight & balance | backend `app/models/slot.rb:95-104`, `app/graphql/types/manifest/load.rb:19-23` (`weight`); client `forms/user_wizard/steps/Wingloading.tsx`, load header "kg" (`dropzone/load/LoadScreen.tsx:249`) |
| 8 | **Wing loading** (lbs/sq ft) | Safety metric: exit weight ÷ canopy size | backend `Slot#wing_loading` (kg→lb ×2.20462); client `app/utils/calculateWingLoading.ts`, `slots_table/UserRow.tsx`, `SlotCardUser.tsx`, `forms/manifest_group/UserRigCard.tsx` |
| 9 | **Rig** (`Rig`, `rig_type` student/sport/tandem, `canopy_size`, `repack_expires_at`, packing card) | Personal/rental equipment needed to participate | backend `app/models/rig.rb`, `mutations/setup/equipment/*`; client `screens/authenticated/user/equipment/*`, `configuration/rigs/*`, `forms/user_wizard/steps/Rig.tsx`, `ReserveRepack.tsx`, `AskForRig.tsx` |
| 10 | **Rig inspection** (`RigInspection`, `FormTemplate`, `actAsRigInspector`) | Equipment check before participation | backend `app/models/rig_inspection.rb` (default form is all parachute questions, lines 38-106); client `screens/authenticated/user/rig_inspection/*`, `configuration/rig_inspection_template/*` |
| 11 | **Federation, licence, licensed jump types, qualifications, APF number** | National body certification gating what a participant may do | backend `Federation`, `License`, `LicensedJumpType`, `Qualification`, `UserFederation*`, `users.apf_number`, `Federations::ApfSync` (APF API), `config/seed/global.yml`; client `forms/user_wizard/steps/Federation*.tsx`, `License.tsx`, `components/input/card_select/FederationCardSelect.tsx`, `LicenseCardSelect.tsx` |
| 12 | **Jump type** (`JumpType`: Angle, Freefly, Camera, Hop 'n Pop, High Pull, Flat, Wingsuit, …) | Activity performed at the destination; restricted by licence | backend `app/models/jump_type.rb`, `config/seed/global.yml:1-16`; client `components/input/chip_select/JumpTypeChipSelect.tsx`, `dropdown_select/JumpTypeSelect.tsx` |
| 13 | **Ticket type** (`TicketType`: cost, altitude, `is_tandem`, `allow_manifesting_self`) | Fare/product for a seat; doubles as destination | backend `app/models/ticket_type.rb`; client `configuration/ticket_types/*`, `forms/ticket_type/*` |
| 14 | **Extras / add-ons** (`Extra`) | Video, photos | backend `app/models/extra.rb`; client `configuration/extras/*`, `forms/ticket_type_addon/*` |
| 15 | **Tandem / passenger** (`is_tandem`, `Passenger`, `passenger_slot_id`, role `tandem_passenger`, `tandem_instructor`, `rig_type: tandem`) | A participant who is accompanied by a staff member occupying a linked seat | backend `app/models/slot.rb:39,99,106-118`, `app/interactions/manifest/create_slot.rb:91-114`, `app/models/passenger.rb`; client manifest form passenger fields, "Tandem Passenger:" row (`slots_table/UserRow.tsx:185`) |
| 16 | **Student / AFF / coach / instructor roles** | Participant categories and staff roles | backend `config/seed/access.yml` (`student`, `fun_jumper`, `coach`, `aff_instructor`, `tandem_instructor`, `chief_instructor`), `UserRole::DEFAULT`, `DEFAULT_LICENSED` (`app/models/user_role.rb:15-16`), `DropzoneUser.staff` scope (`app/models/dropzone_user.rb:48`) |
| 17 | **Staff duties: pilot, GCA, load master, DZSO** (`loads.pilot_id`, `gca_id`, `load_master_id`, `master_logs.dzso_id`, `actAsPilot/GCA/LoadMaster/DZSO`) | Per-trip crew roles required by regulation | backend `app/models/load.rb:30-35` (`validates :gca`, `:pilot`), `config/seed/access.yml` acting permissions; client `components/chips/PilotChip.tsx`, `GcaChip.tsx`, `LoadMasterChip.tsx`, load form |
| 18 | **Calls: 10/15/20-minute call, boarding call, "take off"** (`dispatch_at`, state `boarding_call`, `in_flight`, `landed`) | Departure call schedule and trip status | client `screens/authenticated/dropzone/load/ActionButton.tsx:48-69` (hard-coded 20/15/10), `LoadCard/Countdown.tsx`; backend `load_state.rb`, notification copy |
| 19 | **Landed / finalise** | Trip completed; charges confirmed; jump counts | backend `Manifest::FinalizeLoad`, `jump_count` columns |
| 20 | **Weather: winds aloft, jump run, exit spot, offset (miles), temperature** | Destination-specific operating conditions | backend `app/models/weather_condition.rb` (altitudes 0–14000 ft, knots, miles), client `screens/authenticated/dropzone/weather_conditions/*`, `manifest/Weather/*`, `components/input/jump_run_select/*` |
| 21 | **Master log** (APF Operational Regulations 12.3.3) | Regulatory daily log | backend `app/models/master_log.rb:24-35`, `concerns/master_log_entry/*`; client `configuration/master_log/*` |
| 22 | **Membership expiry** (`dropzone_users.expires_at`, `require_membership`) | Club membership | backend `app/models/slot.rb:125-131`, `dropzones/configuration.rb` |
| 23 | **Credits / wallet** | Prepaid balance | backend `transactions/*`; client `forms/credits/*`, "$" literals (`AppBar.tsx:50`, `Drawer.tsx:111`, `OrderCard.tsx:43`, `TicketTypeChipSelect.tsx:44`) |
| 24 | **Dropzone settings** (`require_rig_inspection`, `require_license`, `require_reserve_in_date`, `require_equipment`, `allow_double_manifesting`, …) | Eligibility rules | backend `app/models/concerns/dropzones/configuration.rb`; client `configuration/dropzone_settings/*`, `components/forms/dropzone/*`, `app/hooks/useManifestValidator.ts` |
| 25 | **Time zone default `Australia/Brisbane`, AUD-style `$`** | Original market | `db/schema.rb` defaults on `dropzones.time_zone`, `users.time_zone`; client `$` literals |
| 26 | **Location: lat/lng of the dropzone** | Base location | `dropzones.lat/lng`, maps in client |
| 27 | **Group manifest / group number** | Participants who travel and act together | `slots.group_number`, `CreateMultipleSlots` |

## 2. Generic abstractions

| Skydiving concept | Generic abstraction | Notes |
|---|---|---|
| Dropzone | **Operator** (tenant) with an **industry profile** | Keeps lat/lng (home base), time zone, currency, unit system, settings |
| Plane | **Vehicle** (`vehicle_kind`: aircraft, boat, bus, …; `capacity`, `min_capacity`, registration) | Optional cargo capacity (mass/volume) if D6 says cargo |
| Load | **Trip** (a scheduled departure of a vehicle) | `trip_number` per operator per local day; status lifecycle below |
| Altitude on ticket type | **Destination** with a typed value: `altitude` (metres), `named_location` (place id + name, e.g. dive site), `route` (ordered list of stops / circuit) | A trip has one destination by default; multi-leg only if D6 |
| Slot | **Seat** (booking of one participant on a trip) | Keeps `group_number` as **party** |
| Jumper / DropzoneUser | **Participant** (membership of a person at an operator) | Staff are participants with roles |
| Tandem passenger + instructor | **Accompanied participant**: a seat linked to an escort seat (`escort_seat_id`) | Divers with a guide, children with an adult |
| Jump type | **Activity** (per profile catalogue) | e.g. "Fun dive", "Night dive", "Hop-on" |
| Ticket type | **Fare** (price, currency, default destination, allowed activities, self-booking flag, "requires escort") | |
| Extras | **Add-ons** | unchanged |
| Rig + rig inspection + repack | **Equipment** with **equipment checks** (form templates already generic JSON) and an **expiry** (`next_service_due_at`) | Profile decides whether equipment is required |
| Federation / licence / jump-type allowance / qualifications | **Certification scheme** → **certification level** → **permitted activities** | Dive: PADI/SSI levels; bus: none |
| Exit weight, wing loading | **Participant measurements** declared by the profile (`body_mass`), with optional derived **safety metrics** (wing loading) implemented as profile plug-ins | |
| Pilot, GCA, load master, DZSO | **Crew roles per trip** defined by the profile (`trip_crew_roles`: required/optional, which acting permission qualifies) | Dive boat: skipper, divemaster; bus: driver, guide |
| 10/15/20-minute calls, boarding call | **Departure call schedule** (profile default list of minutes; per-operator override) | Notification copy from the profile's terminology |
| Landed / cancelled | Trip `completed` / `cancelled` | |
| Weather (winds aloft, jump run) | **Conditions** module per profile: `winds_aloft` (skydiving), `marine` (dive: swell, visibility, water temperature), none (bus) | Keep skydiving module as-is behind the profile flag |
| Master log | **Trip log / regulatory daily log** with profile-specific export template | |
| Membership | **Membership** (generic) | |
| Credits | **Wallet** (generic) | Money in integer minor units + ISO currency |

### Trip lifecycle (generic)

`scheduled` (was `open`) → `called` (was `boarding_call`) → `departed` (was `in_flight`, now reachable) →
`completed` (was `landed`) | `cancelled`. Calls are driven by the profile's departure call schedule.

## 3. Configuration model: industry profiles

An **IndustryProfile** is code-defined configuration (YAML files in the backend, e.g. `config/industry_profiles/skydiving.yml`,
`diving.yml`, `bus_tour.yml`), loaded at boot and versioned with the app. Each operator (dropzone) stores
`industry_profile` (slug) plus `profile_overrides` (jsonb) for per-operator changes. Database-stored profiles are not
recommended until there is a profile editor.

```yaml
# config/industry_profiles/skydiving.yml (illustrative)
slug: skydiving
terminology:            # keys used by the client i18n layer (section 5)
  operator: { one: "Dropzone", other: "Dropzones" }
  vehicle:  { one: "Aircraft", other: "Aircraft" }
  trip:     { one: "Load", other: "Loads" }
  seat:     { one: "Slot", other: "Slots" }
  participant: { one: "Jumper", other: "Jumpers" }
  activity: { one: "Jump type", other: "Jump types" }
  destination: { one: "Altitude", other: "Altitudes" }
  escort:   { one: "Tandem instructor", other: "Tandem instructors" }
  call:     { one: "Call", other: "Calls" }
destination_types: [altitude]
default_destinations:
  - { label: "Hop n Pop", type: altitude, value_m: 1219.2 }
  - { label: "Full altitude", type: altitude, value_m: 4267.2 }
vehicle_kinds: [aircraft]
default_call_schedule_minutes: [20, 15, 10]
trip_crew_roles:
  - { key: pilot, required: true, acting_permission: actAsPilot }
  - { key: gca, required: true, acting_permission: actAsGCA }
  - { key: load_master, required: false, acting_permission: actAsLoadMaster }
participant_fields:
  - { key: body_mass, type: mass, required: true }
equipment: { required: true, check_template: rig_inspection, expiry_field: reserve_repack }
certification: { enabled: true, schemes: [apf] }
safety_metrics: [wing_loading]
conditions_module: winds_aloft
units: { altitude: ft, distance: nmi, mass: kg, speed: kn, temperature: c }
daily_log_template: apf_master_log
```

What the profile controls:

| Area | Profile key | Server effect | Client effect |
|---|---|---|---|
| Terminology | `terminology` | Notification/push copy, activity messages | All UI labels (section 5) |
| Destinations | `destination_types`, `default_destinations` | Validation of `Destination.kind` | Destination pickers replace `AltitudeSelect` |
| Calls | `default_call_schedule_minutes` | Default operator setting | ActionButton call actions generated from it |
| Crew | `trip_crew_roles` | Required crew validation on trip create (replaces `validates :gca, :pilot`) | Crew chips generated per role |
| Participant fields | `participant_fields` | Required-field validation on seat create | Profile wizard steps |
| Equipment / certification | `equipment`, `certification` | Eligibility rules (replaces hard-coded `require_rig_inspection`, `require_license`) | Hide equipment/licence screens when disabled |
| Units | `units` | none (server stores SI) | Display conversion (section 4) |
| Conditions | `conditions_module` | Which weather service runs | Which weather board renders |

Skydiving becomes one profile (`skydiving`) and every existing dropzone is assigned it in the data migration.

## 4. Units

Rule: **store canonical SI values; convert only at the display/input layer** according to the operator's unit settings
(profile default, overridable per operator, optionally per user later).

| Quantity | Canonical storage (new columns) | Display options | Current storage → migration |
|---|---|---|---|
| Altitude / height | `*_m` decimal(10,2) metres | ft, m | `ticket_types.altitude` (int, feet) → `destination value_m = altitude * 0.3048` |
| Distance | `*_m` decimal metres | km, nmi, mi, m | `weather_conditions.exit_spot_miles`, `offset_miles` (int, statute miles per `WeatherCondition#guesstimate_jumprun`) → `* 1609.344` |
| Mass | `*_kg` decimal(6,2) | kg, lb | `users.exit_weight`, `slots.exit_weight`, `passengers.exit_weight` (float kg) → rename/copy to `body_mass_kg` |
| Area | `*_m2` decimal | ft², m² | `rigs.canopy_size` (int, ft²) → `* 0.09290304` (only if equipment is generalised; can stay ft² inside the skydiving module) |
| Speed | `*_mps` decimal | kn, km/h, mph | winds JSON `speed` (knots) → `* 0.514444` |
| Temperature | `*_c` decimal | °C, °F | `temperature` (int, assumed °C) |
| Money | `*_cents` bigint + `currency` (ISO 4217) on operator | locale currency format | floats (BUG-048) → `round(x * 100)` |
| Time | `timestamptz` UTC + operator `time_zone` | operator local time | unchanged; fix day boundaries (BUG-046/047) |

Implementation:

- Backend: a `Units` module with `to_si(value, unit)` / `from_si(value, unit)`; GraphQL exposes SI fields
  (`altitudeMeters`) plus, for convenience, a `displayValue(unit:)` resolver is **not** added — conversion lives in the
  client to keep the API canonical. Input mutations accept SI only.
- Client: `app/i18n/units.ts` with `formatQuantity(valueSi, quantity, unitSystem)` and `parseQuantity(input, quantity,
  unitSystem)`, using `Intl.NumberFormat` with `style: 'unit'` (supported by Hermes in RN ≥ 0.70 via the existing
  `@formatjs/intl-numberformat` polyfill imported in the client). Unit system comes from `dropzone.settings.units`
  (operator) returned by the API.
- Altitude display keeps the skydiving convention ("14k") via a profile-specific formatter `compactAltitude`.

## 5. Terminology (labels from the profile, not hard-coded strings)

- Introduce i18n in the client with **i18next + react-i18next** (namespaces: `common`, `terms`). `terms` is built at
  runtime from the operator's profile: the API returns `dropzone { industryProfile { terminology } }` and the client
  calls `i18n.addResourceBundle(locale, 'terms', terminology, true, true)` whenever the current operator changes.
- UI strings reference terms by key with pluralisation: `t('terms:trip', { count: 1 })` → "Load" / "Dive" / "Tour";
  composite copy in `common`: `"newTrip": "New {{trip}}"` with `t('common:newTrip', { trip: t('terms:trip') })`.
- Backend copy (notifications, activity messages, emails) uses Rails I18n with the same keys, interpolating
  `I18n.t("terms.trip.one", default: …)` from the operator's profile (`Operator#term(:trip)`).
- Route paths (`/dropzone/manifest`, `/dropzone/load/:loadId`) become neutral (`/manifest`, `/trips/:tripId`) with
  redirects from old paths kept for one release.
- Extraction is mechanical: Phase 7 has one task per client area to replace literals with `t()`; a lint rule
  (`i18next/no-literal-string` from `eslint-plugin-i18next`) prevents regressions in converted directories.

## 6. Data migration path and naming strategy

### Options

| Option | What changes | Pros | Cons |
|---|---|---|---|
| A. Rename now | Tables, models, GraphQL types/fields and client code renamed (`loads`→`trips`, `Plane`→`Vehicle`, `DropzoneUser`→`Membership`, …) | Clean vocabulary for future contributors | Touches ~every file in both repos at once; breaks deployed clients; high regression risk with a weak test net; large migration on production data |
| B. Alias at the API, keep schema | Keep DB tables and Ruby model names; add generic GraphQL types/fields alongside existing ones (`Trip` implemented by `Load`), deprecate old fields with `deprecation_reason` | Backwards compatible; incremental | Two vocabularies during transition; internal names stay skydiving |
| C. Keep names everywhere, generalise via profile labels only | Only UI labels and new generic concepts (Destination, call schedule, crew roles) | Smallest change | Code vocabulary stays skydiving-specific forever |

### Recommendation: **B, then selectively A for internal names after one release**

Reasons:

1. The only API consumer is the OpenManifest client, but released mobile apps keep running old binaries for months;
   additive GraphQL changes plus deprecations avoid forcing an update on day one.
2. Most generalisation value comes from **new concepts** (Destination, IndustryProfile, call schedule, crew roles, units),
   not from renaming. Option B lets Phase 7 add those without a big-bang rename.
3. Renaming tables is cheap later (Rails `rename_table` + model rename) once the request specs from Phase 1 cover every
   operation; doing it before that net exists is the riskiest move available.

Concrete migration steps (each is a Phase 7 task):

1. Add `dropzones.industry_profile` (string, default `"skydiving"`, not null) and `profile_overrides` (jsonb, default `{}`);
   backfill all rows with `skydiving`.
2. Add `loads.dropzone_id` (backfilled from `planes.dropzone_id`, not null, indexed) — also fixes BUG-050/BUG-022 scoping.
3. Create `destinations` (`dropzone_id`, `kind` enum `altitude|named_location|route`, `label`, `altitude_m`,
   `location` jsonb, `stops` jsonb, `discarded_at`); for each distinct `(dropzone_id, altitude)` in `ticket_types`, create an
   altitude destination with `altitude_m = altitude * 0.3048`; add `ticket_types.destination_id` and `slots.destination_id`
   (backfilled from the ticket type). Keep `ticket_types.altitude` until clients stop reading it; GraphQL `TicketType.altitude`
   becomes a deprecated field computed from the destination.
4. Add `dropzones.settings.call_schedule_minutes` default `[20, 15, 10]`; client reads it.
5. Add crew roles: `trip_crew_assignments` (`load_id`, `role_key`, `dropzone_user_id`); backfill from `pilot_id`, `gca_id`,
   `load_master_id`; keep the old columns/fields as deprecated mirrors for one release.
6. Money to cents (also BUG-048) and units to SI columns as listed in section 4, each with a reversible migration that keeps
   the old column until the next release.
7. GraphQL: add generic types (`Operator`, `Vehicle`, `Trip`, `Seat`, `Destination`) as **interfaces implemented by the
   existing object types** or as additional fields (`trip: Load`), never removing old ones in the same release.

Rollback for each step: the old columns remain populated; migrations are reversible (`down` drops the new
columns/tables); the client keeps working against old fields.

## 7. Questions only the owner can answer

These are recorded as Open Decisions D5 and D6 in the plan; Phase 7 tasks are blocked on them.

1. **Target industries for the first generalised release**: skydiving + dive boats? Bus tours? Which one is the second profile
   used to prove the abstraction?
2. **Cargo**: do vehicles carry cargo (mass/volume capacity, cargo items as bookable seats), or people only?
3. **Recurring trips**: timetables (e.g. daily 09:00 bus tour) vs ad-hoc trips created on the day (skydiving style)?
4. **Multi-leg routes / circuits**: can one trip have several destinations or stops, and can participants board/leave at
   intermediate stops?
5. **Booking ahead and capacity per day**: should customers book future trips (date picker, reservations), or is it
   same-day manifesting only?
6. **Payments**: keep the internal prepaid-credit wallet only, or integrate a payment provider (Stripe etc.) per industry?
   Per-seat payment at booking vs post-trip settlement?
7. **Certification schemes**: which non-skydiving schemes matter (PADI/SSI for diving)? Is there an API to verify them like APF?
8. **Regulatory logs**: what daily/trip log does each industry need (dive logs, passenger manifests for boats)?
9. **Units default per market**: metric everywhere with per-operator overrides, or market-specific defaults
   (ft for skydiving in AU/US, m for diving)?
10. **Naming strategy**: accept recommendation B (API aliases, rename internals later), or rename everything now (A)?
11. **Branding**: does the product keep the "OpenManifest" name and skydiving branding (logo, Lottie animations, airplane
    icons) or become neutral?
12. **Multi-operator users**: should one person's profile data (body mass, certifications, equipment) be shared across
    operators of different industries?
