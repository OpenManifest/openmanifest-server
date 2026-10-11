# Commerce foundation plan

Shared money, accounting and payment layer for the [booking](BOOKING_PLAN.md) and [webshop](WEBSHOP_PLAN.md) plans, and
the home of the platform's revenue: a transaction fee on purchases. Index and executor rules: [README.md](README.md).

Drafted 2026-10-11 against backend `0774b40` and client `dcc46d1`. Owner decisions recorded 2026-10-11 (§2).

## 1. What this plan delivers

At the end of this plan an operator (dropzone) can connect its own Stripe account, and its members can top up their
credit wallet online by card, Apple Pay or Google Pay, on web and in the app. Every online payment carries the
OpenManifest platform fee, offline sales recorded at the desk accrue a smaller fee that is collected automatically or
invoiced, every money movement (online, wallet, desk) is posted to a per-operator double-entry ledger, and the
building blocks the other plans need exist: customers (including guests), sales orders with lines, checkout, payments,
refunds, disputes and coupons.

| Owner requirement | Where |
|---|---|
| Double-entry accounting with the Money gem | §3.1, §3.2 (`double_entry` gem, see CD2); C1.1–C1.3 |
| Replace the app's own `Money` class with the Money gem | §3.1; C1.1 |
| Transaction fee on purchases, including offline sales (monetisation) | §3.4; C2.2, C2.9, C2.10 |
| Purchases on web and mobile with Apple Pay / Google Pay | §3.3; C2.4, C2.5 |
| Coupon codes usable for shop and bookings | §3.7; C2.7, C2.8 |
| Virtual product: credit recharge | C2.3 (first slice: free-amount top-up); packages with bonuses in WEBSHOP S3.1 |

## 2. Decisions

All decided by the owner on 2026-10-11. The options that were weighed are kept short for the record.

| ID | Decision | Decided | Notes | Tasks |
|---|---|---|---|---|
| CD1 | Payment provider and charge model | **Stripe Connect, direct charges** on operator accounts with the full Stripe Dashboard (the "Standard" equivalent: `controller.stripe_dashboard.type = full`, `fees.payer = account`, `losses.payments = stripe`); platform fee via `application_fee_amount` | The operator is the merchant of record and handles its own refunds and disputes; OpenManifest never holds customer money, so the credit wallet is the operator's liability. Rejected: destination charges (platform becomes merchant of record), other providers. **ActiveMerchant is not used**: it abstracts server-side card gateways, while this design needs Stripe-hosted payment UI confirmed on the client, Connect onboarding, application fees, webhooks and Apple Pay domain registration, none of which it covers (last release 1.137.0, 2024-08-02). A thin adapter over the official `stripe` gem (§3.3) keeps provider code in one place instead | C2.1–C2.11 |
| CD2 | Ledger library | **`double_entry` 2.0.2** (Envato), behind a `Ledger` wrapper | The owner asked for Plutus or something better. `double_entry` is tested against Ruby 4.0 and Rails 8.1 (this stack), stores integer cents through the Money gem, keeps running balances with per-account locking and only allows transfers declared in configuration. Plutus 0.18 was the alternative: no release between 2020-09 and 2025-03, untested on Ruby 4.0, decimal amounts, no locking, an unscoped account lookup by name and editable entries. There is no default Rails ledger gem. `double_entry`'s limits and how §3.2 handles them are listed there | C1.2, C1.3 |
| CD3 | Platform fee schedule and scope | **Online: 1.5 % + A$0.30, minimum A$0.50. Offline sales recorded in OpenManifest: 1 %, no fixed part. The operator absorbs the fee** (customers see the operator's price only) | Offline means cash/EFTPOS/bank-transfer top-ups at the desk, booking balances paid on arrival, desk shop sales. Complimentary credits and wallet spends carry no fee; complimentary top-ups are listed on the fee statement. Only AUD has a plan at launch; an operator in another currency cannot take payments until a plan exists for it | C2.2, C2.9, C2.10 |
| CD4 | Platform fee on refunds and disputes | **Refunded in proportion to every refund and on lost disputes**: the fee follows the money the operator keeps | Applies to offline fees too (a desk refund reduces the accrued fee) | C2.6 |
| CD5 | Sales tax | **One tax rate per operator, prices tax-inclusive by default**, tax lines in the ledger and on receipts; credits and gift vouchers taxed when redeemed, not when sold | The owner's accountant confirms the stored-value treatment and whether OpenManifest's own fee carries GST; fee statements (C2.9) show a tax line either way | C1.1, C2.9 |
| CD6 | Selling credits and gift vouchers in the iOS/Android apps | **Sell in-app with Apple Pay / Google Pay via Stripe**, under App Store guideline 3.1.3(e) (credits only spendable on real-world services at that operator), with a remote switch that hides top-ups in the iOS app if review rejects it | Ask App Review before the first submission that includes top-ups (owner check in C2.11) | C2.5, WEBSHOP S3.1, S3.2 |
| CD7 | Collecting offline fees (Standard accounts cannot be debited by the platform) | **Carry forward, invoice the rest**: owed offline fees are added to the application fee of the operator's next online payments (capped per payment, §3.4); whatever is still owed at month end is invoiced through Stripe Billing on the platform account | Rejected: invoice only (more invoices, slower cash); carry forward only (operators with few online payments never pay) | C2.10 |

## 3. Design

### 3.1 Money and currency

- Add the `money` gem (7.1.1, 2026-07-31) and **delete the app's own value object** `app/models/money.rb` (P6.23); the
  gem's `::Money` replaces it everywhere. Do not add `money-rails`: P6.23's `MoneyAttributes`
  (`app/models/concerns/money_attributes.rb`, integer `*_cents` columns, atomic `add_cents!`) already maps columns and
  stays.
- The two helpers the app class had move: `Money.cents_of(units)` becomes `MoneyAttributes.cents_of` (same BigDecimal
  rounding) and `Money#to_s` call sites use `Money#format`. `Money.rounding_mode = BigDecimal::ROUND_HALF_UP` keeps
  today's rounding.
- **One currency per operator**: `dropzones.currency` (ISO 4217, default `AUD`), immutable once the operator has a
  ledger entry or a payment. Every amount on an operator's orders, payments, coupons and ledger is in that currency;
  `Ledger` rejects anything else. Multi-currency operators are out of scope.
- Tax settings on the operator (CD5): `tax_rate_bps`, `prices_include_tax`, `tax_label`, `tax_registration_number`,
  `legal_name` (for receipts). Tax per line: inclusive `tax = round(total × r / (10000 + r))`, exclusive
  `tax = round(total × r / 10000)`; rounding half-up per line.

### 3.2 Ledger (`double_entry`)

**How `double_entry` works.** Accounts are declared in an initializer by identifier, with a scope (here: the operator)
and a currency. Money moves only by `DoubleEntry.transfer(amount, from:, to:, code:, detail:, metadata:)`, and only for
`(from, to, code)` combinations declared in the same initializer. Each transfer writes two lines with running
balances (integer cents) and updates a cached balance per account; `DoubleEntry.lock_accounts(...)` locks the accounts
for multi-transfer operations. `DoubleEntry::Validation::LineCheck` re-verifies running balances.

**Sign convention.** A transfer from A to B decreases A and increases B. The ledger treats an increase as a debit and a
decrease as a credit, so "debit X, credit Y" is a transfer from Y to X. Asset and expense accounts carry positive
balances, liability, equity and revenue accounts negative ones (reports negate them for display), and the sum of all
balances is zero by construction.

**Journal entries and the outbox.** `lock_accounts` must be the **outermost** database transaction, but the wallet code
already runs inside transactions (manifesting composes `Transactions::Purchase` inside `Manifest::CreateSlot`, with the
P6.10 locks). So business code never calls `double_entry` directly:

1. Inside the business transaction, `Ledger.record!(dropzone:, description:, document:, lines:)` validates the lines
   (one currency, debits = credits, accounts known, no zero lines) and inserts one `ledger_entries` row
   (`dropzone_id`, `description`, polymorphic `document`, `occurred_on` in the operator's time zone, `lines` jsonb,
   `posted_at` null). Either the business change and its entry both commit, or neither does.
2. After commit, `PostLedgerEntryJob` (enqueued by `after_commit`, plus a sweep every minute for anything missed) posts
   the entry: inside `DoubleEntry.lock_accounts` for all its accounts it re-checks `posted_at`, splits the lines into
   transfers (largest debit against largest credit, deterministic) with `detail: ledger_entry`, and sets `posted_at`.
   Posting is idempotent.
3. Corrections are new entries (`Ledger.reverse!(entry)`); `ledger_entries` and `double_entry_lines` are never updated
   or deleted (a DB trigger rejects `UPDATE`/`DELETE` on both, except the single `posted_at` write).

Balances (`Ledger.balance(dropzone, :customer_wallets, as_of:)`) read `double_entry`; reports first assert there are no
unposted entries older than five minutes.

**Chart of accounts** (`Ledger::ChartOfAccounts`; the initializer declares every key once per supported currency, e.g.
`customer_wallets_aud`, scoped by operator):

| Key | Type | Meaning |
|---|---|---|
| `stripe_receivable` | Asset | Money held for the operator at Stripe (connected-account balance) |
| `cash` | Asset | Desk takings: cash, EFTPOS terminal, bank transfer |
| `customer_wallets` | Liability | Control account for all member credit balances. The subsidiary ledger is the existing `transactions` table and `dropzone_users.credits_cents` |
| `customer_deposits` | Liability | Paid for but not yet delivered: booking payments before the session, wallet charges for slots on loads that have not landed |
| `gift_vouchers` | Liability | Outstanding voucher balances |
| `tax_payable` | Liability | Tax collected |
| `platform_fees_payable` | Liability | Offline fees owed to OpenManifest, not yet collected (CD7) |
| `service_revenue`, `product_revenue`, `shipping_revenue`, `cancellation_revenue` | Revenue | Jumps/bookings, shop goods, shipping charged, forfeited deposits |
| `discounts` | Revenue (contra) | Coupon discounts, so reports show gross and net |
| `platform_fees`, `payment_processing_fees`, `chargebacks`, `promotional_expense` | Expense | OpenManifest fee, Stripe fees, lost disputes, bonus credits and complimentary top-ups |
| `opening_balance_equity` | Equity | Balances that existed before the ledger (C1.3) |
| `platform_fee_revenue`, `platform_fee_receivable` | Revenue / Asset | OpenManifest's own books: fee income and offline fees owed to it. Also scoped by operator (an unscoped account would make every payment on the platform wait for one lock); platform reports sum across scopes |

**Posting rules** (every flow in all three plans maps to one of these; each row is also a declared transfer code;
amounts illustrative, A$, tax 10 % inclusive, fee 1.5 % + 0.30):

| Event | Debit | Credit |
|---|---|---|
| Card payment for goods, 110.00 | `stripe_receivable` 110.00 | `product_revenue` 100.00, `tax_payable` 10.00 |
| … platform fee on it, 1.95 | `platform_fees` 1.95 | `stripe_receivable` 1.95 (platform side: `platform_fee_receivable` / `platform_fee_revenue`, settled at once because Stripe collected it) |
| … Stripe processing fee (from the balance transaction) | `payment_processing_fees` | `stripe_receivable` |
| Coupon of 10.00 on goods | `discounts` 10.00 | (revenue is credited gross, the receivable is 10.00 lower) |
| Online wallet top-up, 100.00 (+ 10.00 bonus) | `stripe_receivable` 100.00, `promotional_expense` 10.00 | `customer_wallets` 110.00 |
| Desk top-up in cash, 100.00 | `cash` 100.00 | `customer_wallets` 100.00 |
| … offline fee on it (1 %), 1.00 | `platform_fees` 1.00 | `platform_fees_payable` 1.00 (platform side: `platform_fee_receivable` / `platform_fee_revenue`) |
| Offline fee collected through a later application fee or invoice | `platform_fees_payable` | `stripe_receivable` (application fee) or `cash` (invoice paid) |
| Member manifested (credits reserved, existing `Transactions::Purchase`) | `customer_wallets` | `customer_deposits` |
| Load landed (existing `Transactions::Confirm`) | `customer_deposits` | `service_revenue`, `tax_payable` |
| Taken off load / load cancelled (existing `Transactions::Refund`) | reversal of the purchase entry | |
| Booking payment online | `stripe_receivable` | `customer_deposits` |
| Booking delivered (check-in or session end) | `customer_deposits` | `service_revenue`, `tax_payable` |
| Late cancellation, deposit forfeited | `customer_deposits` | `cancellation_revenue`, `tax_payable` |
| Gift voucher sold / redeemed | `stripe_receivable` / `gift_vouchers` | `gift_vouchers` / revenue or `customer_deposits` |
| Refund (any) | reversal of the refunded share, including the proportional fee (CD4) | |
| Dispute lost | `chargebacks` | `stripe_receivable` |

**Invariants**, checked daily by `LedgerReconciliationJob` (C1.3) and reported as error-level activity events plus an
AppSignal error: `DoubleEntry::Validation::LineCheck` finds no errors; no entry has stayed unposted for more than an
hour; `customer_wallets` equals `SUM(dropzone_users.credits_cents)` per operator; `customer_deposits` equals reserved
wallet transactions plus undelivered booking payments; per payment, ledger receipts equal
`payments.amount_cents − refunded_cents`; `platform_fees_payable` equals uncollected offline fees.

**`double_entry` limits and how the wrapper handles them:**

| Limit | Handling |
|---|---|
| `lock_accounts` must be the outermost transaction | Outbox (`ledger_entries` + `PostLedgerEntryJob`) above. Specs set `DoubleEntry::Locking.configuration.running_inside_transactional_fixtures = true` |
| Transfers have exactly two sides | `ledger_entries` is the multi-line journal entry; its transfers share `detail` |
| Currency is fixed per account identifier, not per scope | One identifier per key and supported currency (`SUPPORTED_CURRENCIES`, `AUD` at launch); the wrapper maps `(key, dropzone.currency)` to it |
| No account types | `Ledger::ChartOfAccounts` holds type and normal side for reports (trial balance, profit and loss) |
| Unscoped accounts contend for one lock | Every account, platform ones included, is scoped by operator |
| Only declared transfers are allowed | Transfer codes are generated from the posting-rule table, which doubles as a safety net: an undeclared money movement raises |

The wallet stays where it is (`credits_cents` updated atomically, P6.10 locks). The ledger is the book of record and
the control total; it is not on the hot path of manifesting.

### 3.3 Payments

- **Provider adapter** `PaymentProviders::Stripe` and `PaymentProviders::Fake` behind one interface (create connected
  account and onboarding link, create/cancel PaymentIntent, refund with `refund_application_fee`, refund an
  application fee, fetch balance transaction, register payment-method domain, create platform invoice, verify webhook),
  built on the official `stripe` gem. `Fake` is the default in development and test, so the VM, CI and the client
  smoke test can complete a checkout without Stripe (a development-only `simulatePayment` mutation drives it).
- **Connected accounts** (CD1): `payment_accounts` (one per operator: provider account id, `charges_enabled`,
  `payouts_enabled`, `details_submitted`, `requirements` jsonb, `billing_customer_id` for platform invoices (CD7)).
  Onboarding through Stripe-hosted account links; status kept current by `account.updated`.
- **Charges**: PaymentIntents created on the operator's account (`Stripe-Account` header) with
  `application_fee_amount` and metadata `sales_order_id`, `payment_id`, `dropzone_id`; Stripe idempotency key
  `payment-<id>`. Automatic payment methods, so cards, Apple Pay and Google Pay come from one integration.
- **Truth comes from webhooks**, never from the client: one Connect webhook endpoint `POST /webhooks/stripe`
  (signature verified), every event stored once in `provider_events` (unique provider + event id) and handled by a
  Solid Queue job. Handled: `payment_intent.succeeded|payment_failed|canceled`, `charge.refunded`,
  `charge.dispute.created|closed`, `account.updated`, and for platform invoices `invoice.paid|payment_failed`. A
  recurring job re-fetches PaymentIntents stuck in `processing` for more than 15 minutes, covering lost webhooks.
- **Client**: native uses `@stripe/stripe-react-native` (Expo config plugin with `merchantIdentifier` and
  `enableGooglePay`; install with `npx expo install` to get the SDK 57 version, 0.64.0 per Expo's docs) and PaymentSheet,
  which includes Apple Pay and Google Pay; the provider is initialised with the operator's `stripeAccountId`. Web uses
  `@stripe/stripe-js` + `@stripe/react-stripe-js` (Payment Element and Express Checkout Element) in `.web.tsx` files,
  loaded with `{ stripeAccount }`. Neither needs Expo Go support (EAS development builds are already the workflow).
- **Apple Pay on the web** with direct charges needs the web app's domain registered for each connected account
  (payment method domains), and the domain-association file served by the web host. C2.1 registers the domain when an
  operator finishes onboarding. Google Pay in the Android app needs production access in the Google Pay & Wallet
  Console; Apple Pay needs a merchant ID and the Stripe-issued certificate. All three are owner checks.
- **PCI**: card data never reaches the API (Stripe-hosted UI elements only), which keeps OpenManifest at the lightest
  self-assessment level.

### 3.4 Platform fee (monetisation)

- `platform_fee_plans` (`currency`, online `percent_bps`, `fixed_cents`, `min_cents`, optional `max_cents`, offline
  `offline_percent_bps`, `carry_forward_cap_bps`); one default plan per currency, optional per-operator plan
  (`dropzones.platform_fee_plan_id`), editable only by platform administrators (`users.moderation_role =
  administrator`). Seeded default (CD3): AUD, 150 bps + 30 cents, minimum 50 cents, no maximum, offline 100 bps,
  carry-forward cap 500 bps.
- Online: `fee = max(min_cents, round_half_up(amount × percent_bps / 10000) + fixed_cents)`, capped at `max_cents` when
  set, never more than the amount, 0 for a 0 amount. Offline: `round_half_up(amount × offline_percent_bps / 10000)`.
  Computed when the payment is recorded and snapshotted on the payment and in `platform_fees` (`kind`: `online`,
  `offline`; plan values copied, so a plan change never rewrites history).
- **Online fees** are collected by Stripe as `application_fee_amount`. **Offline fees** accrue in
  `platform_fees_payable` (CD7) and are collected two ways:
  1. **Carry forward**: each new online payment's application fee is its own fee plus as much owed offline fee as fits
     under `carry_forward_cap_bps` of that payment (5 %: a A$400 booking can collect at most A$20 of backlog). The
     collected part is recorded in `platform_fee_collections` against the oldest owed fees first.
  2. **Monthly invoice**: after each month ends (operator time zone), for each operator still owing for it or earlier
     months, a Stripe Billing invoice on
     the platform account (the operator is a billing customer, `billing_customer_id`), itemised by month, with the tax
     line per CD5. `invoice.paid` settles the owed fees; unpaid invoices show on the operator's Payments screen and in
     platform reporting.
- Refunds (CD4): online fees through `refund_application_fee` (proportional) and the application-fee refund API on lost
  disputes; offline fees by reducing the accrual (or crediting the next invoice if already collected). Carried-forward
  amounts are never refunded with the payment that carried them, only with the offline sale they belong to.

Where the fee applies:

| Money path | Fee |
|---|---|
| Online payment (top-up, shop order, booking deposit or balance, gift voucher) | 1.5 % + A$0.30 (min A$0.50), collected by Stripe |
| Offline sale recorded in OpenManifest (desk top-up, balance paid on arrival, desk shop sale) | 1 %, accrued, collected by carry-forward or monthly invoice |
| Complimentary credits | None; listed on the statement |
| Spending wallet credits (manifesting, shop with credits) | None (the fee was taken when the credits were bought) |
| Refunds, lost disputes | Fee refunded proportionally (CD4) |

Reporting (C2.9): operators see a monthly statement (online fees, offline fees accrued, collected by carry-forward,
invoiced, refunded, complimentary credits given, net); platform administrators see fees by operator and month, payment
volume, offline volume, outstanding offline fees, refunds and disputes.

### 3.5 Customers, sales orders and checkout

New tables are named `sales_orders` / `sales_order_lines` because `orders` is the existing wallet order table (kept,
unchanged, and posted to the ledger).

- `customers`: per operator, `email` (case-insensitive unique per operator), `name`, `phone`, optional `user_id`,
  `email_verified_at`. A logged-in user gets a customer row linked to their user; a guest (booking plan) gets one by
  verified email; when a guest later signs up with that verified email, the rows are linked.
- `sales_orders`: per-operator `number` (same locking as `Order#set_order_number`), `customer_id`, `currency`,
  `state` (`pending_payment` → `paid` | `expired` | `cancelled`), `payment_state` (`unpaid`, `paid`,
  `partially_refunded`, `refunded`, `disputed`), `fulfilment_state` (`unfulfilled`, `partially_fulfilled`, `fulfilled`,
  `not_required`), totals (`subtotal`, `discount`, `shipping`, `tax`, `total`, `platform_fee`, all `*_cents`),
  `idempotency_key` (unique per operator), `expires_at`, `channel` (`web`, `app`, `desk`), address snapshot.
- `sales_order_lines`: polymorphic `purchasable`, `description`, `quantity`, `unit_price_cents`, `discount_cents`,
  `tax_cents`, `total_cents`, `fulfilled_quantity`, `refunded_quantity`, `metadata`.
- `payments` (`provider`: `stripe`, `fake`, `wallet`, `cash`, `card_terminal`, `bank_transfer`, `voucher`, `none`;
  the desk providers are the offline ones), `refunds`, `platform_fees`, `platform_fee_collections`.
- **`Sellable` contract**: anything sold implements `price_for(customer, quantity)`, `reserve!(line)` (raises
  `Commerce::SoldOut`), `release!(line)`, `on_paid!(line)`, `on_refunded!(line, quantity)`, `ledger_account(line)`
  (revenue, deposit, wallet or voucher account), `coupon_category` and `stored_value?`. This plan implements
  `WalletTopUp`; booking adds `Booking`; the webshop adds `ProductVariant`, `CreditPackage`, `GiftVoucherProduct`.
- **Checkout** (`Commerce::Checkout`): one transaction creates the order, reserves every line, applies the coupon,
  computes totals and creates the payment; outside the transaction the PaymentIntent is created and its client secret
  returned. Orders that stay unpaid past `expires_at` (30 minutes; holds in the booking plan may be shorter) are expired
  by a recurring job, which cancels the PaymentIntent and releases lines and coupon. A `payment_intent.succeeded` that
  arrives for an expired order re-reserves; if that fails, the payment is refunded in full (fee included) and the
  customer is emailed. A zero total (100 % coupon) skips the provider (`provider: none`).
- **Desk payments** (`recordDeskPayment`, staff): settle an order or a booking balance with `cash`, `card_terminal` or
  `bank_transfer`; post to `cash` and accrue the offline fee.

### 3.6 Refunds and disputes

Full or partial refunds by line and quantity (`refundSalesOrder`, permission `refundOrders`), with optional restock and
reason. Wallet payments refund to the wallet, card payments through Stripe, desk payments are recorded as paid out in
cash. Each refund calls `on_refunded!` on the affected lines, reverses the ledger proportionally and refunds the platform
fee proportionally (CD4). Disputes set `payment_state = disputed`, notify staff with `refundOrders`, and on
`charge.dispute.closed` post a chargeback and refund the fee if lost.

### 3.7 Coupons

- `coupons`: per operator, `code` (stored upper-case, unique per operator), `kind` (`percent`, `fixed_amount`,
  `free_shipping`), `value`, `min_subtotal_cents`, `starts_at`/`ends_at`, `max_redemptions`, `max_per_customer`,
  `first_order_only`, `applies_to` (`everything`, `products`, `services`, specific targets through `coupon_targets`),
  `active`.
- **Stored value is never discounted**: coupons do not apply to wallet top-ups, credit packages or gift vouchers
  (otherwise a 20 % coupon on credits is a cash machine). Bonus credits are a property of credit packages instead.
- Redemptions are reserved at checkout with a conditional update (`redemptions_count < max_redemptions`) and a row in
  `coupon_redemptions`, released when the order expires or is cancelled, kept when the order is refunded.
- The discount is allocated across eligible lines in proportion to line totals (remainder cents to the largest line)
  so tax, refunds and per-product reports stay exact. One coupon per order.

### 3.8 Permissions

Added to `config/seed/access.yml`, granted to `owner` and `admin` by default (data migration for existing roles), and
listed in the permissions screen: `managePayments` (Stripe onboarding, fee statements, platform invoices),
`readOrders`, `refundOrders`, `recordDeskPayments`, `manageCoupons`, `readReports`. `manifest` role defaults:
`readOrders`, `recordDeskPayments`. Platform fee plans: platform administrators only.

### 3.9 Data model

```mermaid
erDiagram
  dropzones ||--o| payment_accounts : "connects"
  dropzones }o--o| platform_fee_plans : "charged by"
  dropzones ||--o{ customers : ""
  customers }o--o| users : "linked when verified"
  customers ||--o{ sales_orders : ""
  sales_orders ||--|{ sales_order_lines : ""
  sales_order_lines }o--|| SELLABLE : "purchasable (WalletTopUp, Booking, ProductVariant, ...)"
  sales_orders ||--o{ payments : ""
  payments ||--o{ refunds : ""
  payments ||--o{ platform_fees : "own fee, plus carried-forward collections"
  platform_fees ||--o{ platform_fee_collections : "offline fee collected by"
  sales_orders ||--o| coupon_redemptions : ""
  coupons ||--o{ coupon_redemptions : ""
  coupons ||--o{ coupon_targets : ""
  dropzones ||--o{ ledger_entries : ""
  ledger_entries ||--|{ double_entry_lines : "detail (posted transfers)"
  ledger_entries }o--|| DOCUMENT : "document (payment, refund, order, wallet transaction)"
  provider_events }o--o| payment_accounts : ""
```

## 4. Tasks

Rules for every task in this plan: money is integer cents in the database and API (`*Cents: Int!` fields plus the
operator `currency`); every interaction that moves money records a ledger entry with `Ledger.record!` in the same
database transaction; every new mutation has a tenant-isolation spec (P1.7 style) and an authorization spec; webhook
handlers are idempotent and have a duplicate-delivery spec.

### C1.1 — Replace the app's Money class with the money gem; operator currency and tax settings
Status: todo
Repo: both
Depends on: P6.27
Branch: feature/c1-1-money-currency
Goal: `::Money` is the money gem everywhere and the app's own class is gone; each operator has an immutable-once-used
currency and tax settings, shown and formatted correctly in the client.
Context: §3.1, CD5. `app/models/money.rb` (app value object, collides with the gem), `MoneyAttributes`, call sites
(`grep -rn "Money\." app lib spec`), `Transaction#notification_message`. Client P6.23 formats with a default `AUD`.
Steps:
  1. backend: add `gem "money", "~> 7.1"`; `config/initializers/money.rb` (`rounding_mode` half-up, `locale_backend
     :currency`, no default currency); delete `app/models/money.rb` and its spec (port the behaviour assertions to
     the new helpers); move `cents_of` to `MoneyAttributes.cents_of`; add `<name>_money` readers to `MoneyAttributes`
     that return `Money.new(cents, currency)` with the operator's currency; replace `to_s` call sites with `format`.
  2. Migration: `dropzones.currency` string not null default `"AUD"` (backfill from the operator's most common valid
     `ticket_types.currency`), `tax_rate_bps` integer not null default 0, `prices_include_tax` boolean default true,
     `tax_label`, `tax_registration_number`, `legal_name`. Validation: ISO currency; currency cannot change once the
     operator has payments or ledger entries (guard written now, checked against tables added later).
  3. GraphQL: `Dropzone.currency`, `taxSettings`; `updateDropzone` accepts them (permission `updateDropzone`).
  4. client: `formatMoney(cents, currency)` uses the dropzone currency everywhere; tax fields in dropzone settings.
  5. Specs: formatting parity with the old class for AUD (`"$12.50"`, `"-$3.00"`), currency immutability, tax maths
     table (inclusive/exclusive, rounding).
Acceptance criteria (cloud VM):
  - Backend `bundle exec rspec` green, rubocop clean; `test ! -e app/models/money.rb`; client checks, `check:graphql`,
    web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: ledger.
Risk / rollback: revert; the migration is additive.
Size: M
Fixes: none

### C1.2 — Ledger: double_entry, chart of accounts, journal outbox
Status: todo
Repo: backend
Depends on: C1.1
Branch: feature/c1-2-ledger
Goal: `Ledger.record!`, posting, `reverse!`, `balance` and `trial_balance` work per operator on `double_entry`, with
append-only entries.
Context: §3.2 (all of it, including the limits table).
Steps:
  1. `gem "double_entry", "~> 2.0"`; `bin/rails generate double_entry:install` (json metadata); migration for
     `ledger_entries`; DB triggers rejecting `UPDATE`/`DELETE` on `double_entry_lines` and on `ledger_entries` (except
     setting `posted_at` once).
  2. `Ledger::ChartOfAccounts` and `Ledger::PostingRules` (the two tables in §3.2) drive
     `config/initializers/double_entry.rb`: accounts per key × `SUPPORTED_CURRENCIES`, scoped by operator; transfer
     codes per posting rule.
  3. `app/models/ledger.rb`: `record!` (validation), `PostLedgerEntryJob` (lock, idempotent split into transfers),
     sweep every minute in `config/recurring.yml`, `reverse!`, `balance`, `trial_balance`, `profit_and_loss(from, to)`.
  4. Specs: valid and invalid entries (unbalanced, foreign currency, unknown account, zero line), posting splits multi-line
     entries correctly, double posting is a no-op, an undeclared transfer raises, reversal, trial balance zero, triggers
     block edits, entry recorded inside a rolled-back transaction leaves nothing behind.
Acceptance criteria (cloud VM):
  - Backend rspec green; rubocop clean.
Acceptance criteria (owner, real device):
  - none
Out of scope: posting existing flows (C1.3).
Risk / rollback: new tables only.
Size: L
Fixes: none

### C1.3 — Record the wallet flows in the ledger and reconcile daily
Status: todo
Repo: both
Depends on: C1.2
Branch: feature/c1-3-wallet-ledger
Goal: Every existing credit movement records a balanced entry; existing balances get opening entries; desk top-ups
accrue the offline fee; a daily job proves the ledger and the wallets agree.
Context: §3.2 posting rules (wallet and desk rows), §3.4 (offline fee). `app/interactions/transactions/{purchase,
confirm,refund,create_order}.rb`; staff top-ups go through `createOrder` (client `app/forms/credits`).
Steps:
  1. Record entries in `Purchase` (reserve), `Confirm` (recognise revenue and tax), `Refund` (reverse), staff top-up
     and withdrawal. Staff top-ups gain `paymentMethod` (`cash` default, `card_terminal`, `bank_transfer`,
     `complimentary`); complimentary posts to `promotional_expense` and carries no fee. client: payment-method select
     in the credits form.
  2. Offline fee accrual on desk top-ups: the `platform_fees` table and calculator arrive in C2.2, so this task only
     records the ledger entry with a fee computed from a constant (100 bps) in `Ledger::OfflineFee`; C2.2 replaces the
     constant with the plan and backfills `platform_fees` rows from these entries.
  3. Rake task `ledger:opening_balances` (idempotent, prints counts): per operator, wallets and reserved transactions
     against `opening_balance_equity`; also run from a data migration so every environment is consistent.
  4. `LedgerReconciliationJob` daily in `config/recurring.yml` (invariants in §3.2); mismatches create error-level
     activity events and report to AppSignal.
  5. Specs: each flow records the expected lines; opening balances on the P0.5 seed make reconciliation pass; a forced
     mismatch is reported.
Acceptance criteria (cloud VM):
  - Backend rspec green; on the dev seed, `bin/rails ledger:opening_balances` then the reconciliation job report no
    mismatch; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: online payments.
Risk / rollback: recording is additive; the opening-balance task is idempotent by `document`.
Size: L
Fixes: none

### C2.1 — Stripe Connect onboarding and webhooks
Status: todo
Repo: both
Depends on: C1.3
Branch: feature/c2-1-stripe-connect
Goal: An operator with `managePayments` connects a Stripe account from the app; account status stays current from
webhooks; the fake provider covers development and tests.
Context: §3.3, CD1. Stripe API is not reachable from the VM (README "External services").
Steps:
  1. backend: `gem "stripe"` (latest stable 20.x); `PaymentProviders::Base`, `::Stripe`, `::Fake`; provider chosen by
     `PAYMENT_PROVIDER` (default `fake` outside production).
  2. `payment_accounts`, `provider_events` tables; mutation `startPaymentOnboarding(dropzoneId)` returns an account-link
     URL; `Dropzone.paymentAccount { chargesEnabled payoutsEnabled requirementsDue }`.
  3. `Webhooks::StripeController#create` (`POST /webhooks/stripe`, CSRF-free, signature verified with
     `STRIPE_WEBHOOK_SECRET`), stores the event, enqueues `ProcessProviderEventJob`; handler registry; `account.updated`.
     On first `charges_enabled`, register the web app's domain for Apple Pay on the connected account.
  4. Permissions from §3.8 with the role backfill.
  5. client: Settings → Payments screen (status, "Connect Stripe" opening the link with `expo-web-browser`, refresh on
     return).
  6. Specs with WebMock and fixtures: onboarding authz and tenancy, bad signature → 400, duplicate event handled once,
     `account.updated` updates flags.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks and web export pass.
Acceptance criteria (owner, real device):
  - Owner, on staging with test-mode keys: connect a test operator account and see "charges enabled".
Out of scope: charges (C2.4).
Risk / rollback: new tables and endpoint. Revert both.
Size: L
Fixes: none

### C2.2 — Platform fee plans and calculation
Status: todo
Repo: backend
Depends on: C2.1
Branch: feature/c2-2-platform-fee
Goal: Online and offline fees are computed from versioned plans, snapshotted, and recorded on the operator's and the
platform's books.
Context: §3.4, CD3.
Steps:
  1. `platform_fee_plans`, `dropzones.platform_fee_plan_id`, `platform_fees` (`kind` online/offline, owed and
     collected amounts); seed the AUD default plan from CD3 (150 bps + 30 cents, min 50 cents, offline 100 bps,
     carry-forward cap 500 bps).
  2. `PlatformFees::Calculator` (online and offline formulas in §3.4); administrator-only mutations to create plans and
     assign them; replace C1.3's constant and backfill `platform_fees` rows for offline fees already recorded.
  3. Ledger entries for fees charged and refunded.
  4. Specs: rounding table (amounts 0, 1, 33, 34, 100, 12 345, below the minimum, at a maximum when set), offline
     formula, plan change does not alter existing fees, operator in a currency without a plan cannot take payments,
     non-administrators rejected.
Acceptance criteria (cloud VM):
  - Backend rspec green.
Acceptance criteria (owner, real device):
  - none
Out of scope: carry-forward and invoices (C2.10), statements (C2.9).
Risk / rollback: additive.
Size: M
Fixes: none

### C2.3 — Customers, sales orders and the wallet top-up sellable
Status: todo
Repo: backend
Depends on: C2.2
Branch: feature/c2-3-sales-orders
Goal: The order model, totals, the `Sellable` contract and `WalletTopUp` exist; `createCheckout` creates an order with a
pending payment through the fake provider; staff can settle orders at the desk.
Context: §3.5.
Steps:
  1. Tables `customers`, `sales_orders`, `sales_order_lines`, `payments`; models, state machines (`state_machines`
     already in the Gemfile), `Sellable` concern, `Commerce::Totals` (tax per §3.1).
  2. `WalletTopUp` sellable: amount chosen by the member within operator limits (`settings.top_up_min_cents`,
     `top_up_max_cents`); `on_paid!` credits the wallet through the existing wallet code and records the entry.
  3. `Commerce::Checkout` and mutation `createCheckout(input: {dropzoneId, lines, idempotencyKey})` (logged-in
     members); query `salesOrder(id)` (buyer or `readOrders`); subscription `salesOrderUpdated(salesOrderId)`;
     `recordDeskPayment` (`recordDeskPayments`) with offline fee accrual.
  4. `ExpireSalesOrdersJob` every minute (`config/recurring.yml`).
  5. Specs: totals, idempotency (same key twice → same order; parallel requests → one order), expiry releases lines,
     desk payment accrues 1 %, tenant isolation.
Acceptance criteria (cloud VM):
  - Backend rspec green; schema dump diff additive.
Acceptance criteria (owner, real device):
  - none
Out of scope: Stripe charges (C2.4), coupons (C2.7).
Risk / rollback: additive.
Size: L
Fixes: none

### C2.4 — Charge through Stripe and confirm from webhooks
Status: todo
Repo: backend
Depends on: C2.3
Branch: feature/c2-4-payment-intents
Goal: Checkout creates a PaymentIntent on the operator's account with the platform fee; orders become paid only from
webhooks; late and lost webhooks are handled.
Context: §3.3, §3.5 (late payment rule).
Steps:
  1. `Payments::CreateIntent` (outside the checkout DB transaction, idempotency key `payment-<id>`); `createCheckout`
     returns `clientSecret`, `stripeAccountId`, `publishableKey`; checkout fails clearly when the operator's account
     cannot take charges.
  2. Handlers: `payment_intent.succeeded` (mark paid, `on_paid!`, ledger, fee record, staff/customer notification),
     `payment_failed` (record message), `canceled`; late success on an expired order → re-reserve or full refund.
  3. `Payments::RecordProcessingFeeJob` reads the balance transaction and records the Stripe fee.
  4. `ReconcileStuckPaymentsJob` (every 15 minutes) re-fetches intents in `processing`.
  5. Development-only `simulatePayment(paymentId, outcome)` for the fake provider.
  6. Specs with fixtures: happy path, duplicate webhook, failure then retry, late success both ways, processing-fee
     entry, stuck-payment recovery.
Acceptance criteria (cloud VM):
  - Backend rspec green.
Acceptance criteria (owner, real device):
  - none (end-to-end in C2.11)
Out of scope: client UI, carry-forward (C2.10).
Risk / rollback: revert; no data migration.
Size: L
Fixes: none

### C2.5 — Client payments and online credit top-up
Status: todo
Repo: both
Depends on: C2.4
Branch: feature/c2-5-client-payments
Goal: Members top up credits from the app and the web with card, Apple Pay or Google Pay; the payment components are
reusable by the other plans.
Context: §3.3 (client), CD6. Client platform-file convention (`*.web.tsx`), Apollo hooks via codegen.
Steps:
  1. client: `npx expo install @stripe/stripe-react-native`; config plugin in `app.config.ts` (`merchantIdentifier`
     per environment, `enableGooglePay: true`); `@stripe/stripe-js` and `@stripe/react-stripe-js` for web.
  2. `app/components/payments/`: `PaymentProvider(.web).tsx` (keyed by `stripeAccountId`), `PayButton(.web).tsx`
     (PaymentSheet natively; Express Checkout Element + Payment Element on web), `OrderStatus` (waits for
     `salesOrderUpdated`, falls back to polling).
  3. "Top up credits" screen from the drawer balance and the profile; remote switch `topUpsInIosApp` (backend: a
     platform setting exposed on `currentUser` or app config; default on) per CD6.
  4. With the fake provider, a development "Simulate payment" button replaces the Stripe UI so the web smoke test can
     complete a top-up.
  5. Tests: top-up form validation, status transitions with mocked subscription, iOS switch hides the entry; extend
     `docs/SMOKE_TEST.md` with "top up credits".
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export, smoke test with the fake provider pass.
Acceptance criteria (owner, real device):
  - Owner, staging test mode: top up with a test card on web, with Apple Pay on an iPhone (development build), with
    Google Pay on Android; balances and the ledger agree.
Out of scope: credit packages with bonuses (WEBSHOP S3.1).
Risk / rollback: revert; feature hidden when the operator has no connected account.
Size: L
Fixes: none

### C2.6 — Refunds and disputes
Status: todo
Repo: both
Depends on: C2.5
Branch: feature/c2-6-refunds
Goal: Staff refund orders fully or partly; fees (online and offline), ledger and wallet follow; disputes are tracked
and recorded.
Context: §3.6, CD4.
Steps:
  1. `refunds` table; `refundSalesOrder(input: {salesOrderId, lines: [{lineId, quantity}], amountCents?, reason,
     restock})` with `refundOrders`; provider refund with `refund_application_fee: true`; wallet refunds; desk refunds
     reduce the offline fee accrual; ledger reversal; `on_refunded!`.
  2. Handlers `charge.refunded` (refunds made in the Stripe Dashboard are mirrored), `charge.dispute.created|closed`
     (lost: chargeback entry and application-fee refund).
  3. client: refund action on the transactions screen for top-ups (shop and booking screens reuse it later).
  4. Specs: partial and full refund maths, fee refund proportional (online and offline), Dashboard-initiated refund
     mirrored once, lost dispute records a chargeback and refunds the fee, carried-forward fees untouched by the
     carrying payment's refund.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - Owner, staging test mode: refund a test top-up half, then fully; check the Stripe Dashboard shows the fee refunds.
Out of scope: return shipping (WEBSHOP S4.1).
Risk / rollback: revert.
Size: M
Fixes: none

### C2.7 — Coupons (backend)
Status: todo
Repo: backend
Depends on: C2.6
Branch: feature/c2-7-coupons
Goal: Coupons can be created, validated and redeemed in checkout with exact allocation and safe limits.
Context: §3.7.
Steps:
  1. Tables `coupons`, `coupon_targets`, `coupon_redemptions`; CRUD mutations (`manageCoupons`); `previewCoupon(code,
     lines)` for the client; `createCheckout` accepts `couponCode`.
  2. Conditional-update redemption reservation; release on expiry/cancel.
  3. Stored-value sellables (`stored_value? == true`) never discounted.
  4. Specs: each kind, date window, per-customer and total limits under 20 parallel checkouts (no over-redemption),
     allocation remainder, zero-total order paid without provider (and no fee), ledger `discounts` line.
Acceptance criteria (cloud VM):
  - Backend rspec green.
Acceptance criteria (owner, real device):
  - none
Out of scope: UI (C2.8).
Risk / rollback: additive.
Size: M
Fixes: none

### C2.8 — Coupons (client)
Status: todo
Repo: client
Depends on: C2.7
Branch: feature/c2-8-coupons-client
Goal: Staff manage coupons; checkout accepts a code and shows the discount.
Context: configuration screens pattern (`app/screens/authenticated/configuration/*`, react-hook-form from P4.5).
Steps:
  1. Configuration → Coupons list and form (kind, value, window, limits, targets).
  2. Coupon field in the shared checkout summary component (`previewCoupon`).
  3. Tests: form validation; discount display.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: none

### C2.9 — Platform fee statements and platform reporting
Status: todo
Repo: both
Depends on: C2.8
Branch: feature/c2-9-fee-statements
Goal: Operators see what they paid and owe OpenManifest; platform administrators see fee revenue, payment volume and
outstanding offline fees.
Context: §3.4 reporting, CD5 (tax line).
Steps:
  1. Queries: `dropzone.platformFeeStatement(month)` (`managePayments`): online fees, offline fees accrued, collected,
     owed, refunded, complimentary credits, tax line; CSV download. `platformRevenue(from, to)` (administrators): per
     operator and currency: online and offline volume, fees, outstanding, refunds, disputes.
  2. client: statement screen under Settings → Payments; administrator screen beside the existing admin overview
     (`app/screens/authenticated/overview/AdminOverview.tsx`).
  3. Specs: statement totals equal the platform-side ledger accounts for the month (operator time zone boundaries).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: collection (C2.10).
Risk / rollback: read-only.
Size: M
Fixes: none

### C2.10 — Collect offline fees: carry-forward and monthly invoices
Status: todo
Repo: both
Depends on: C2.9
Branch: feature/c2-10-offline-fee-collection
Goal: Offline fees owed by an operator are collected automatically from its next online payments, and any remainder is
invoiced monthly through Stripe Billing.
Context: §3.4 (collection), CD7.
Steps:
  1. `platform_fee_collections`; in `Payments::CreateIntent`, add owed offline fees (oldest first) to
     `application_fee_amount` up to `carry_forward_cap_bps` of the payment, reserving them so two concurrent payments
     cannot collect the same fee; settle on `payment_intent.succeeded`, release on failure/expiry.
  2. Billing customer per operator on the platform account (`billing_customer_id`, billing email collected on the
     Payments screen); `MonthlyPlatformInvoicesJob` daily, invoicing each operator once its month has ended in its own
     time zone (the same month boundaries as the C2.9 statement), itemised by month; handlers `invoice.paid` (settle, ledger) and `invoice.payment_failed` (notify
     `managePayments` holders, show on the Payments screen).
  3. client: "Owed to OpenManifest" and invoices on the Payments screen.
  4. Specs: cap arithmetic, oldest-first allocation, concurrent payments, failed payment releases the reservation,
     invoice amounts equal owed fees, paid invoice settles, nothing invoiced when nothing is owed.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - Owner, staging test mode: record a desk top-up, make an online top-up and see the larger application fee in the
    Stripe Dashboard; run the invoice job for an operator with no online payments and pay the test invoice.
Out of scope: dunning beyond Stripe Billing's own retries; suspending operators that do not pay (owner policy, later).
Risk / rollback: revert; owed fees stay recorded and can be invoiced manually.
Size: L
Fixes: none

### C2.11 — Verify the commerce foundation
Status: todo
Repo: both
Depends on: C2.10
Branch: feature/c2-11-verify
Goal: The foundation works end to end and is documented.
Context: all of this plan.
Steps:
  1. Run every check in both repos; record results in `docs/verification/commerce-foundation.md`.
  2. Update `docs/reference/README.md` (payments row, domain model, env vars, jobs) and `diagrams.md` (ER for §3.9,
     sequence for checkout → webhook → ledger outbox).
Acceptance criteria (cloud VM):
  - All checks exit 0.
Acceptance criteria (owner, real device):
  - Owner on staging (needs P8.4 or an equivalent public URL for webhooks): test-mode top-ups on web, iPhone and
    Android; a desk top-up collected by carry-forward; a refund; a fee statement matching the Stripe Dashboard; App
    Review's answer on in-app top-ups (CD6) recorded here.
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none
