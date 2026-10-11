# OpenManifest diagrams

Mermaid diagrams for the system as it is at backend `b8dc33a` / client `3112795` (pass 1, 2026-10-08).
Client-only diagrams (navigation map, Redux data flow) are in the client repo:
<https://github.com/OpenManifest/openmanifest/blob/staging/docs/reference/diagrams.md>.

Contents: [1 System context](#1-system-context) · [2 ER diagram](#2-entity-relationship-diagram) ·
[3 Sequence diagrams](#3-sequence-diagrams) · [4 Client navigation map](#4-client-navigation-map) ·
[5 Redux data flow](#5-redux-data-flow) · [6 State diagrams](#6-state-diagrams)

## 1. System context

```mermaid
flowchart LR
  subgraph Devices
    IOS[iOS app<br/>Expo SDK 47 / RN 0.70]
    AND[Android app<br/>Expo SDK 47 / RN 0.70]
    WEB[Web app<br/>expo export --platform web, Metro<br/>GitHub Pages]
  end
  subgraph Expo[Expo services]
    EAS[EAS Build / Submit]
    UPD[EAS Update<br/>u.expo.dev]
    PUSH[Expo Push API<br/>exp.host]
  end
  subgraph API[Rails 7.0 API]
    GQL[POST /graphql<br/>GraphqlController + DzSchema]
    CABLE[/subscriptions<br/>ActionCable GraphqlChannel/]
    INT[Interactions<br/>app/interactions]
    JOBS[ActiveJob :async<br/>NotifyJob]
    RAKE[rake dropzone:*<br/>not scheduled]
    STALE[GET /<br/>stale 2021 web build]
  end
  PG[(PostgreSQL)]
  REDIS[(Redis<br/>cable pub/sub)]
  STORE[(ActiveStorage<br/>Disk /data or GCS)]
  APF[APF member API]
  WINDS[markschulze.net<br/>winds aloft]
  GEO[Google Geocoding]
  APPLE[Apple ID keys]
  FB[Facebook Graph API]
  APPSIG[AppSignal]

  IOS & AND & WEB -->|GraphQL over HTTPS, batched| GQL
  IOS & AND & WEB -->|WebSocket| CABLE
  IOS & AND -->|OTA bundles| UPD
  GQL --> INT --> PG
  INT --> JOBS -->|HTTP| PUSH --> IOS & AND
  CABLE <--> REDIS
  INT -->|model callbacks trigger subscriptions| CABLE
  GQL --> STORE
  INT --> APF
  INT --> WINDS
  GQL --> GEO
  INT --> APPLE
  INT --> FB
  API --> APPSIG
  WEB --> APPSIG
  RAKE --> INT
```

## 2. Entity relationship diagram

Derived from `db/schema.rb` (version `2023_04_09_034757`). Only key columns shown; `created_at`/`updated_at` omitted.
`admins` and the ActiveStorage tables are omitted.

```mermaid
erDiagram
  FEDERATIONS ||--o{ LICENSES : has
  FEDERATIONS ||--o{ QUALIFICATIONS : has
  FEDERATIONS ||--o{ DROPZONES : "federation_id"
  LICENSES ||--o{ LICENSED_JUMP_TYPES : allows
  JUMP_TYPES ||--o{ LICENSED_JUMP_TYPES : ""
  USERS ||--o{ USER_FEDERATIONS : ""
  FEDERATIONS ||--o{ USER_FEDERATIONS : ""
  LICENSES ||--o{ USER_FEDERATIONS : "license_id"
  USER_FEDERATIONS ||--o{ USER_FEDERATION_QUALIFICATIONS : ""
  QUALIFICATIONS ||--o{ USER_FEDERATION_QUALIFICATIONS : ""
  USERS ||--o{ AUTHENTICATION_PROVIDERS : ""
  USERS ||--o{ DROPZONE_USERS : "membership"
  DROPZONES ||--o{ DROPZONE_USERS : ""
  USER_ROLES ||--o{ DROPZONE_USERS : "user_role_id"
  LICENSES ||--o{ DROPZONE_USERS : "license_id"
  DROPZONES ||--o{ USER_ROLES : ""
  USER_ROLES ||--o{ USER_ROLE_PERMISSIONS : ""
  PERMISSIONS ||--o{ USER_ROLE_PERMISSIONS : ""
  DROPZONE_USERS ||--o{ USER_PERMISSIONS : ""
  PERMISSIONS ||--o{ USER_PERMISSIONS : ""
  DROPZONES ||--o{ PLANES : ""
  PLANES ||--o{ LOADS : "plane_id (only link load->dropzone)"
  DROPZONE_USERS ||--o{ LOADS : "pilot_id / gca_id / load_master_id"
  LOADS ||--o{ SLOTS : ""
  DROPZONE_USERS ||--o{ SLOTS : "dropzone_user_id / created_by_id"
  PASSENGERS ||--o{ SLOTS : "passenger_id"
  SLOTS ||--o| SLOTS : "passenger_slot_id"
  TICKET_TYPES ||--o{ SLOTS : ""
  JUMP_TYPES ||--o{ SLOTS : ""
  RIGS ||--o{ SLOTS : ""
  DROPZONES ||--o{ PASSENGERS : ""
  DROPZONES ||--o{ TICKET_TYPES : ""
  DROPZONES ||--o{ EXTRAS : ""
  TICKET_TYPES ||--o{ TICKET_TYPE_EXTRAS : ""
  EXTRAS ||--o{ TICKET_TYPE_EXTRAS : ""
  SLOTS ||--o{ SLOT_EXTRAS : "never written"
  EXTRAS ||--o{ SLOT_EXTRAS : ""
  USERS ||--o{ RIGS : "user_id (personal rig)"
  DROPZONES ||--o{ RIGS : "dropzone_id (DZ rig)"
  RIGS ||--o{ PACKS : ""
  USERS ||--o{ PACKS : ""
  RIGS ||--o{ RIG_INSPECTIONS : ""
  DROPZONE_USERS ||--o{ RIG_INSPECTIONS : "owner / inspected_by_id"
  FORM_TEMPLATES ||--o{ RIG_INSPECTIONS : ""
  DROPZONES ||--o{ FORM_TEMPLATES : ""
  DROPZONES |o--o| FORM_TEMPLATES : "rig_inspection_template_id"
  DROPZONES ||--o{ WEATHER_CONDITIONS : ""
  DROPZONES ||--o{ MASTER_LOGS : ""
  DROPZONE_USERS ||--o{ MASTER_LOGS : "dzso_id"
  DROPZONES ||--o{ ORDERS : "dropzone_id"
  ORDERS ||--o{ RECEIPTS : ""
  RECEIPTS ||--o{ TRANSACTIONS : ""
  DROPZONE_USERS ||--o{ NOTIFICATIONS : "received_by_id / sent_by_id"
  DROPZONES ||--o{ EVENTS : ""
  DROPZONE_USERS ||--o{ EVENTS : "dropzone_user_id"

  DROPZONES {
    bigint id PK
    string name
    bigint federation_id FK
    float lat
    float lng
    string time_zone "default Australia/Brisbane"
    string state "private|in_review|public|demo|archived"
    jsonb settings
    boolean is_credit_system_enabled
    integer credits "money as integer"
    integer users_count
    integer loads_count
    integer slots_count
    datetime discarded_at
  }
  USERS {
    bigint id PK
    string email UK
    string name
    string phone
    float exit_weight "kg"
    string push_token
    integer moderation_role
    integer jump_count
    string provider
    string uid
  }
  DROPZONE_USERS {
    bigint id PK
    bigint user_id FK
    bigint dropzone_id FK
    bigint user_role_id FK
    bigint license_id FK
    float credits "money as float"
    datetime expires_at "membership expiry"
    integer jump_count
    datetime discarded_at
  }
  PLANES {
    bigint id PK
    bigint dropzone_id FK
    string name
    string registration
    integer min_slots
    integer max_slots
    datetime discarded_at
  }
  LOADS {
    bigint id PK
    bigint plane_id FK
    integer load_number
    string name
    integer max_slots
    integer state "open|boarding_call|in_flight|landed|cancelled"
    datetime dispatch_at
    boolean has_landed
    boolean is_open
    bigint pilot_id FK
    bigint gca_id FK
    bigint load_master_id FK
    bigint slots_count "double counted"
    bigint ready_slots_count
    datetime discarded_at
  }
  SLOTS {
    bigint id PK
    bigint load_id FK
    bigint dropzone_user_id FK
    bigint passenger_id FK
    bigint passenger_slot_id FK
    bigint ticket_type_id FK
    bigint jump_type_id FK
    bigint rig_id FK
    float exit_weight
    integer group_number
    bigint created_by_id FK
  }
  TICKET_TYPES {
    bigint id PK
    bigint dropzone_id FK
    string name
    float cost
    string currency
    integer altitude "feet"
    boolean allow_manifesting_self
    boolean is_tandem
  }
  EXTRAS {
    bigint id PK
    bigint dropzone_id FK
    string name
    float cost
  }
  RIGS {
    bigint id PK
    bigint user_id FK
    bigint dropzone_id FK
    integer rig_type "student|sport|tandem"
    integer canopy_size "sq ft"
    datetime repack_expires_at
    boolean is_public
  }
  ORDERS {
    bigint id PK
    bigint dropzone_id FK
    string buyer_type
    bigint buyer_id
    string seller_type
    bigint seller_id
    string item_type
    bigint item_id
    integer order_number
    integer state
    float amount
  }
  TRANSACTIONS {
    bigint id PK
    bigint receipt_id FK
    string sender_type
    bigint sender_id
    string receiver_type
    bigint receiver_id
    float amount
    integer status
    integer transaction_type
  }
  WEATHER_CONDITIONS {
    bigint id PK
    bigint dropzone_id FK
    text winds "JSON altitude/speed/direction"
    integer temperature
    integer jump_run "degrees"
    integer exit_spot_miles
    integer offset_miles
    integer offset_direction
  }
  NOTIFICATIONS {
    bigint id PK
    bigint received_by_id FK
    bigint sent_by_id FK
    string resource_type
    bigint resource_id
    integer notification_type
    boolean is_seen
  }
  EVENTS {
    bigint id PK
    bigint dropzone_id FK
    bigint dropzone_user_id FK
    string resource_type
    bigint resource_id
    integer action
    integer level
    integer access_level
    text message
  }
```

## 3. Sequence diagrams

### 3.1 Login and session bootstrap

```mermaid
sequenceDiagram
  actor U as User
  participant C as Client (LoginForm, Redux, Apollo)
  participant API as POST /graphql
  participant D as graphql_devise / devise_token_auth
  U->>C: email + password
  C->>API: mutation Login { userLogin(email, password) { authenticatable, credentials } }
  API->>D: authenticate, create token in users.tokens
  D-->>C: credentials { accessToken, client, uid, expiry, tokenType }
  C->>C: dispatch global.setCredentials (persisted by redux-persist)
  C->>C: authentication link adds headers access-token, client, uid
  Note over C: RootNavigator: credentials && !currentDropzone -> Limbo
  C->>API: query Dropzones { dropzones { edges { node { ...dropzoneEssentials } } } }
  API-->>C: Dropzone.for(user): staff dropzones + public dropzones
  U->>C: taps a dropzone card
  C->>C: dispatch global.setDropzone(dropzone) -> RootNavigator shows Authenticated
  C->>API: query Dropzone(dropzoneId) + CurrentUserPermissions(dropzoneId)
  Note over API: dropzone.currentUser calls User#at -> creates a DropzoneUser if missing (BUG-005)
  API-->>C: dropzone, currentUser { permissions }
```

### 3.2 Creating a load

```mermaid
sequenceDiagram
  actor M as Manifest staff
  participant C as Client (LoadDialog, useManifest)
  participant API as createLoad mutation
  participant I as Manifest::CreateLoad
  participant DB as PostgreSQL
  participant AC as ActionCable
  M->>C: FAB "New load", choose plane, pilot, GCA, max slots
  C->>C: useManifestValidator.canManifest() for the staff member (BUG-067)
  C->>API: createLoad(attributes: { plane, pilot, gca, maxSlots, state: OPEN })
  API->>I: run(access_context for plane.dropzone)  [allow :createLoad]
  I->>DB: INSERT loads (load_number = today.count + 1, BUG-022)
  DB-->>I: load
  I->>AC: broadcast loadCreated(dropzoneId) x3 (BUG-036)
  I->>DB: INSERT events (activity)
  API-->>C: { load { ...loadDetails } }
  C->>C: updateQuery Loads(date: device date) prepends the load
  AC-->>C: other devices: subscription LoadCreated -> cache.updateQuery Loads
```

### 3.3 Adding a jumper to a load (manifest user)

```mermaid
sequenceDiagram
  actor S as Staff or jumper
  participant C as Client (ManifestUserDialog / forms/manifest_user)
  participant API as createSlot mutation
  participant CS as Manifest::CreateSlot
  participant P as Transactions::Purchase
  participant DB as PostgreSQL
  S->>C: pick ticket type, jump type, rig, exit weight (+ passenger for tandem)
  C->>API: createSlot(attributes: { load, dropzoneUser, ticketType, jumpType, rig, exitWeight, extras, passengerName? })
  API->>CS: run  [allow :createSlot only - BUG-006]
  CS->>DB: find_or_initialize slot(load, dropzone_user)
  opt tandem ticket with passenger
    CS->>DB: Passenger.find_or_create + Slot.create(passenger) (no order)
  end
  CS->>DB: validate: available? (slots_count double counted, BUG-019), double_manifest?, allowed_jump_type?, membership_in_date?, affordable? (no locks, BUG-020/023)
  CS->>P: compose Purchase(buyer: dropzone_user, seller: dropzone, purchasable: slot)
  P->>DB: INSERT orders(pending), receipts, 2 transactions(reserved)
  P->>DB: UPDATE dropzones.credits += cost, dropzone_users.credits -= cost
  opt ticket is tandem
    P->>P: compose Refund (tandem slots are free in the credit system)
  end
  CS->>DB: INSERT slots, counter_culture updates, Notification "You have been manifested"
  CS-->>API: slot
  API-->>C: { slot } or { errors, fieldErrors }
  Note over CS: broadcast loadUpdated(loadId) to subscribers
```

### 3.4 Boarding call (departure call) and take-off

```mermaid
sequenceDiagram
  actor M as Manifest staff
  participant C as Client (ActionButton, useLoad)
  participant API as updateLoad mutation
  participant UL as Manifest::UpdateLoad
  participant L as Load model callbacks
  participant N as Notification + NotifyJob
  participant E as Expo push
  M->>C: "20 minute call"
  C->>C: dispatchAt = DateTime.local().plus(20 min) (device clock, BUG-068)
  C->>API: updateLoad(id, { dispatchAt: ISO, state: BOARDING_CALL }) with optimistic response
  API->>UL: run [allow :updateLoad]
  UL->>L: assign dispatch_at + state, save
  L->>N: notify! (dispatch_at changed from nil): one Notification per slot "Load #n call changed to take off at HH:MM" (DZ time zone)
  N->>E: NotifyJob.perform_later (in-process :async)
  L->>L: change_state! -> dispatch event (no-op, state already boarding_call)
  L-->>C: loadUpdated subscription, Countdown shows time to dispatch_at
  M->>C: "Mark as Landed"
  C->>API: finalizeLoad(id, state: LANDED)
  API->>API: Manifest::FinalizeLoad: state landed, Transactions::Confirm for each slot order (crashes for slots without order, BUG-030)
```

### 3.5 Credits top-up and refund on cancellation

```mermaid
sequenceDiagram
  actor M as Manifest staff
  participant C as Client (Credits sheet, useUserProfile)
  participant API as createOrder mutation
  participant CO as Transactions::CreateOrder
  participant FL as finalizeLoad(CANCELLED)
  participant R as Transactions::Refund
  M->>C: add 100 credits to a jumper
  C->>API: createOrder(attributes: { dropzone, seller: <jumper walletId>, buyer: <dropzone walletId>, amount: 100, title })
  API->>API: authorized? buyer==self peer-to-peer OR createUserTransaction (BUG-008)
  API->>CO: run
  CO->>CO: order(pending) -> receipt -> 2 transactions(reserved)
  CO->>CO: seller.credits += 100, buyer.credits -= 100, Confirm -> completed
  API-->>C: { order }
  M->>FL: cancel load
  FL->>R: for each slot.order: Refund
  R->>R: negative receipt, reversed transactions, buyer.credits_cents += receipt amount_cents (exact since P6.23)
```

## 4. Client navigation map

See client repo `docs/reference/diagrams.md` §1.

## 5. Redux data flow

See client repo `docs/reference/diagrams.md` §2.

## 6. State diagrams

### 6.1 Load (effective behaviour)

```mermaid
stateDiagram-v2
  [*] --> open: createLoad
  open --> boarding_call: updateLoad(dispatchAt, state BOARDING_CALL)\n"10/15/20-minute call", custom call
  boarding_call --> open: updateLoad(dispatchAt null, state OPEN)\n"Cancel boarding call"
  open --> cancelled: finalizeLoad(CANCELLED)\nrefund all slot orders\nor auto-finalize (undispatched past load)
  boarding_call --> landed: finalizeLoad(LANDED)\nconfirm all slot orders\nor auto-finalize (dispatched past load)
  in_flight --> landed: finalizeLoad(LANDED)
  landed --> open: updateLoad(state OPEN) "Re-open load" (same day only, client rule)
  cancelled --> open: updateLoad(state OPEN) "Re-open load"
  note right of in_flight
    No code path enters in_flight.
    updateLoad accepts any state value
    without server-side transition rules (BUG-035).
  end note
```

### 6.2 Dropzone visibility (`state_machines`, `app/models/concerns/state_machines/dropzone_state.rb`)

```mermaid
stateDiagram-v2
  [*] --> private
  private --> in_review: request_publication (owner or moderator)
  private --> public: publish (moderator)
  in_review --> public: publish (moderator)
  public --> private: unpublish (owner or moderator)
  in_review --> private: unpublish
  private --> archived: archive (moderator)
  public --> archived: archive (moderator)
  in_review --> archived: archive
  private --> demo: demo
  public --> demo: demo
  demo --> private: unpublish
```

### 6.3 Order and transactions

```mermaid
stateDiagram-v2
  [*] --> pending: Purchase / CreateOrder\n(credits already moved)
  pending --> completed: Confirm interaction<br/>(all transactions completed)
  pending --> refunded: Refund interaction<br/>(slot deleted, load cancelled, slot moved)
  completed --> refunded: Refund interaction
  pending --> cancelled: DeleteSlot.cancel_order
  refunded --> cancelled: DeleteSlot after refund
```
