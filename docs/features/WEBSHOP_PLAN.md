# Webshop plan

Operators sell physical goods (merchandise, gear, packing supplies) and virtual products (credit packages, gift
vouchers, memberships) to signed-in members on the web and in the app, manage stock and fulfilment, and see sales
reports. Index and executor rules: [README.md](README.md). Builds on [COMMERCE_FOUNDATION.md](COMMERCE_FOUNDATION.md):
double-entry ledger, Money gem, Stripe with Apple Pay / Google Pay, platform fee, coupons, refunds.

Drafted 2026-10-11 against backend `0774b40` and client `dcc46d1`. **Status: draft.**

## 1. Requirements coverage

| Owner requirement | Where |
|---|---|
| 1. Double-entry accounting (Money gem, Plutus) | COMMERCE §3.1–3.2, C1.1–C1.4; every shop posting in §3.6 |
| 2. Products, stock, visibility | §3.1, §3.3; S1.1, S1.3, S1.4 |
| 3. Logged-in purchases on web and mobile with Google Pay / Apple Pay | §3.4; S2.1, S2.2 (payments from COMMERCE C2.5) |
| 4. Virtual products such as credit recharge | §3.5; S3.1–S3.3 (free-amount top-up already in COMMERCE C2.3) |
| 5. Coupon codes, also usable for booking | COMMERCE C2.7–C2.8 (one coupon system for both) |
| 6. Image/video upload, markdown product info | §3.2; S1.1, S1.2 |
| 7. Shipping | §3.4; S2.2, S4.1 |
| 8. Statistics and reports | §3.7; S4.3 |
| 9. Dashboard for pending orders | §3.7; S4.2 |
| Transaction fee | Every card payment goes through COMMERCE checkout (fee automatic); paying with credits per SD4 |

## 2. Open decisions

| ID | Decision | Options | Recommendation | Blocks |
|---|---|---|---|---|
| SD1 | Video | (a) **direct uploads to the object store, MP4 (H.264/AAC) only, ≤ 200 MB and ≤ 3 minutes, poster frame generated with ffmpeg, no transcoding**; (b) a video service (Mux, Cloudflare Stream: adaptive streaming, per-minute cost, another vendor); (c) links to YouTube/Vimeo only | (a). Product videos are short clips; phones record H.264 MP4 already. Move to (b) if operators upload long or 4K video. Needs ffmpeg in the production image (P8.4 Dockerfile) and CORS on the bucket for direct uploads | S1.2 |
| SD2 | Shipping | (a) **zones with flat, weight-tiered and free-over-amount rates, local pickup, manual tracking numbers**; (b) carrier integration now (live rates and labels via Shippo, EasyPost or Sendle) | (a). Operators ship small volumes of T-shirts and gear; manual tracking is fine. (b) as a later task once an operator ships enough to want labels | S2.2, S4.1 |
| SD3 | Who sees the shop | (a) **anyone can browse published products of a public operator; buying requires sign-in** (owner requirement 3); (b) members only | (a), with per-product visibility `members` and `staff` for restricted items | S1.1, S2.1 |
| SD4 | Paying with wallet credits | (a) **allowed when the operator uses the credit system**, single tender per order (all credits or all card); (b) card only | (a): members expect it. It carries no platform fee (fee was taken when the credits were bought online; CD3 covers desk-bought credits) | S2.3 |

## 3. Design

### 3.1 Catalogue

| Table | Purpose |
|---|---|
| `product_categories` | Per operator, nested one level (`parent_id`), position, slug |
| `products` | `kind` (`physical`, `credit_package`, `gift_voucher`, `membership`), `title`, `slug`, `summary`, `description_md` (≤ 20 000 characters, raw HTML disabled), `status` (`draft`, `active`, `archived`), `visibility` (`public`, `members`, `staff`), `available_from`/`available_until`, `tax_exempt`, `category_id`, `position`, `featured` |
| `product_options` | Up to 3 option names per product ("Size", "Colour") |
| `product_variants` | One sellable item: `sku` (unique per operator), option values, `price_cents`, `compare_at_price_cents`, `track_stock`, `stock_on_hand`, `stock_reserved`, `allow_backorder`, `low_stock_threshold`, `weight_g`, `active`. Products without options have one default variant |
| `product_media` | Ordered media of a product (and of booking services): `kind` (`image`, `video`), `alt_text`, `position`, ActiveStorage `file` (+ `poster` for video), optional `variant_id` (variant image) |

Markdown: the client renders `description_md` with a maintained React Native markdown renderer (S1.1 chooses between
`react-native-marked` 8.3 and `@ronradtke/react-native-markdown-display` 9.0 after checking Expo SDK 57 / New
Architecture support), with raw HTML off and links opened externally. Staff edit in a plain multiline field with a
preview tab; no WYSIWYG editor.

### 3.2 Media uploads

Today uploads are base64 strings through GraphQL (`active_storage_base64`, P6.21). That is acceptable for photos but not
for video. S1.2 adds **ActiveStorage direct uploads**: mutation `createDirectUpload(filename, byteSize, checksum,
contentType)` returns the signed URL and headers; the client `PUT`s the file straight to storage (Disk service in
development, S3-compatible bucket in production per P8.4) and then attaches the signed blob id. Limits: images JPEG,
PNG, WebP, HEIC (converted to JPEG variants), ≤ 15 MB; video per SD1. Variants: 400 px thumb, 1200 px display, WebP.
Blobs not attached within 24 hours are purged by a job.

### 3.3 Stock

- `stock_movements` is the append-only history (`variant_id`, `quantity` ±, `reason`: `received`, `adjusted`, `sold`,
  `returned`, `damaged`, `reserved`, `released`, `reference` polymorphic, `created_by`, `note`). `stock_on_hand` and
  `stock_reserved` on the variant are counters maintained in the same transaction.
- Reservation at checkout uses the same pattern as booking capacity:
  `UPDATE product_variants SET stock_reserved = stock_reserved + :q WHERE id = :id AND (NOT track_stock OR allow_backorder OR stock_on_hand - stock_reserved >= :q)`,
  backed by `CHECK (allow_backorder OR NOT track_stock OR stock_reserved <= stock_on_hand)`. On payment, on-hand and
  reserved both drop by the quantity; on order expiry the reservation is released. Carts do not reserve stock; only
  checkout does (the order's 30-minute window).
- Low stock (`available ≤ low_stock_threshold`) shows on the dashboard and notifies staff with `manageInventory` once per
  crossing.
- Inventory **valuation** (cost of goods, margins) is out of scope: the ledger records sales, not stock at cost.

### 3.4 Storefront, checkout and shipping

- Storefront per operator: categories, product list (search by title, filter by category), product detail with media
  gallery, variant picker, stock state ("3 left", "sold out"), markdown description.
- Cart: server-side `carts` / `cart_items` per user and operator (survives app restarts, shared between web and app).
  Prices are re-read at checkout; the cart shows when a price changed.
- Checkout (signed-in only): cart → address (physical items) → shipping method → coupon → pay with card / Apple Pay /
  Google Pay (COMMERCE C2.5 components) or credits (SD4). The order captures address, rate and price snapshots.
- Shipping (SD2 a): `shipping_zones` (countries, optional postcode patterns), `shipping_rates` (`flat`,
  `weight_tiers` by total `weight_g`, `free_over_cents`, estimated days), and local **pickup** at the operator (free).
  Shipping is charged as a separate order amount (`shipping_cents`, ledger `shipping_revenue`, taxed with the
  operator's rate) and is discountable by `free_shipping` coupons.
- Fulfilment: `shipments` (`sales_order_id`, lines and quantities, `carrier`, `tracking_number`, `tracking_url`,
  `state`: `pending`, `shipped`, `delivered`, `returned`; timestamps) and pickup (`ready_for_pickup` → `picked_up`).
  Partial fulfilment is supported. Customers get emails and push on shipped and ready-for-pickup.

### 3.5 Virtual products

| Kind | On paid | Ledger (COMMERCE §3.2) | Notes |
|---|---|---|---|
| `credit_package` | Adds `credits_cents + bonus_cents` to the buyer's wallet | `stripe_receivable` → `customer_wallets`; bonus `promotional_expense` → `customer_wallets` | e.g. "Pay A$500, get A$550 of credits". Never discounted by coupons. App-store policy: CD6 |
| `gift_voucher` | Issues a `gift_vouchers` row with a code (12 characters, unambiguous alphabet), balance, expiry (operator setting, default 36 months; check local consumer law on minimum voucher expiry), recipient name/email/message; emails it | `stripe_receivable` → `gift_vouchers`; redemption `gift_vouchers` → revenue or `customer_deposits` | Redeemable at checkout in the shop **and for bookings** (a voucher is a tender, `payments.provider = voucher`), and convertible to wallet credits by staff. Partial use keeps the remaining balance. Not discountable |
| `membership` | Extends the buyer's `dropzone_users.expires_at` by the product's duration (from today or from the current expiry, whichever is later) | `stripe_receivable` → `service_revenue` | Optional task (S3.3); useful because `require_membership` blocks manifesting when expired |

Virtual products need no shipping and are fulfilled immediately on payment (`fulfilment_state = fulfilled`).

### 3.6 Accounting summary

Shop sale: `stripe_receivable` (or `customer_wallets` with SD4, or `gift_vouchers`) debited; `product_revenue`,
`shipping_revenue`, `tax_payable` credited; `discounts` debited for coupons; platform and processing fees as in
COMMERCE §3.2. Refunds reverse proportionally; restocked items write a `returned` stock movement.

### 3.7 Order dashboard and reports

**Dashboard** (new "Shop" area for staff with `readOrders`; the default staff landing card shows its counts):

| Panel | Content |
|---|---|
| To fulfil | Paid orders with physical items not yet shipped or ready for pickup, oldest first, with age |
| Ready for pickup | Waiting for the customer |
| Needs attention | Failed or stuck payments, disputes, refunds requested by customers, late-payment auto-refunds |
| Low stock | Variants at or below threshold, sold-out variants still visible |
| Today | Orders, revenue and (with the booking plan) today's bookings |

Live updates through a subscription `salesOrderUpdated(dropzoneId)`; push to staff with `readOrders` on new paid
orders (per-user opt-out).

**Reports** (`readReports`, operator time zone, date range, CSV export of every table):

- Sales summary: gross sales, discounts, net sales, shipping, tax, refunds, platform fees, processing fees, net
  receipts; by day/week/month.
- By product and variant (units, revenue, refunds), by category, by coupon (redemptions, discount given, revenue
  generated), by channel (web/app/desk), by payment method (card/wallet/voucher).
- Stored value: credits sold (incl. bonuses), credits outstanding (`customer_wallets` balance), gift vouchers sold,
  redeemed, outstanding, expired.
- Booking figures from B3.3 in the same screen.
- Accounting: trial balance and profit-and-loss for the period, straight from the ledger, for the operator's accountant.
  Exports to Xero/MYOB are out of scope (CSV is the interface).

### 3.8 Permissions

`manageProducts` (catalogue and media), `manageInventory` (stock movements), `updateOrders` (fulfilment), plus
COMMERCE's `readOrders`, `refundOrders`, `manageCoupons`, `readReports`. Defaults: owner/admin all; `manifest` role
`readOrders`, `updateOrders`.

## 4. Tasks

Rules for every task: same as COMMERCE §4 (cents, ledger in the same transaction, tenant-isolation and authz specs);
stock claims are proven with parallel-thread specs like B1.4.

### S1.1 — Catalogue: products, variants, categories, markdown
Status: blocked (awaiting decision SD3)
Repo: both
Depends on: C2.9
Branch: feature/s1-1-catalogue
Goal: Staff create products with variants, categories, visibility and a markdown description; the public and members
can read what they are allowed to see.
Context: §3.1, §3.8, SD3.
Steps:
  1. backend: tables `product_categories`, `products`, `product_options`, `product_variants` (stock columns created
     here, used in S1.3); validations; mutations (`manageProducts`); queries `products(dropzoneId, filter)` (staff),
     `shopProducts(operatorSlug, categorySlug, search)` and `shopProduct(operatorSlug, slug)` (`authenticate: false`,
     filtered by visibility: `public` for everyone, `members` for members of that operator, `staff` for staff).
  2. client: choose the markdown renderer (see §3.1; record the choice and why in the PR), add `MarkdownView` and
     `MarkdownEditor` (field + preview) components.
  3. Permissions with role backfill.
  4. Specs: visibility matrix (anonymous, other operator's member, member, staff) × (draft, active, archived, window),
     SKU uniqueness, markdown length.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql` pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: media (S1.2), staff screens (S1.4).
Risk / rollback: additive.
Size: M
Fixes: none

### S1.2 — Media: direct uploads for images and video
Status: blocked (awaiting decision SD1)
Repo: both
Depends on: S1.1
Branch: feature/s1-2-media
Goal: Staff attach ordered images and videos to products and services from a phone or the web, uploading straight to
storage.
Context: §3.2, SD1. `config/storage.yml`; P6.21 upload fixes; `expo-image-picker` is installed.
Steps:
  1. backend: `product_media` (polymorphic owner: product or service); `createDirectUpload`; `attachMedia`,
     `reorderMedia`, `updateMedia` (alt text), `removeMedia`; content-type and size validation on the blob; ffmpeg
     poster generation (skip with a warning when ffmpeg is missing); `PurgeUnattachedBlobsJob` daily.
  2. Document bucket CORS and ffmpeg in `docs/reference/README.md` §8 (for P8.4).
  3. client: `MediaManager` component (pick from library/camera, upload progress, reorder by drag on web and
     move buttons on native, alt text), `MediaGallery` (swipe, video playback with `expo-video` if bundled with SDK 57,
     otherwise the SDK's video module).
  4. Specs: direct upload round trip on the Disk service, rejected types and sizes, ordering, tenant isolation.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks and web export pass.
Acceptance criteria (owner, real device):
  - Owner uploads 3 photos and a 1-minute phone video to a product on an iPhone and on Android; both play on web.
Out of scope: transcoding (SD1 b).
Risk / rollback: additive.
Size: L
Fixes: none

### S1.3 — Stock movements and reservations
Status: blocked (awaiting decision SD3)
Repo: backend
Depends on: S1.2
Branch: feature/s1-3-stock
Goal: Stock changes are recorded as movements; checkout reserves stock atomically; overselling is impossible unless
backorders are allowed.
Context: §3.3.
Steps:
  1. `stock_movements`; `Inventory::Move` (receive, adjust with reason, damage); check constraint on variants.
  2. `ProductVariant` implements `Sellable` (`reserve!`, `release!`, `on_paid!` decrements, `on_refunded!` with optional
     restock).
  3. Low-stock crossing notification.
  4. Specs: 20 threads buying the last 3 units → 3 succeed; backorder variant never blocks; expiry releases; counters
     equal movement sums after the scenarios.
Acceptance criteria (cloud VM):
  - Backend rspec green; the stock concurrency spec passes 20 consecutive runs.
Acceptance criteria (owner, real device):
  - none
Out of scope: valuation.
Risk / rollback: additive.
Size: M
Fixes: none

### S1.4 — Staff catalogue and stock screens
Status: blocked (awaiting decision SD3)
Repo: client
Depends on: S1.3
Branch: feature/s1-4-catalogue-screens
Goal: Staff manage the whole catalogue and stock from the app.
Context: configuration screen patterns; S1.1–S1.3 API.
Steps:
  1. Shop → Products: list with status/visibility/stock badges and search; product form (details, markdown editor,
     options and variants grid, prices, visibility and dates, media manager); categories screen.
  2. Stock: per-variant movement history, receive/adjust dialog with reason.
  3. Tests for forms and the variants grid.
Acceptance criteria (cloud VM):
  - Client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - Owner creates a T-shirt with sizes and colours, photos and stock on a small Android phone.
Out of scope: none.
Risk / rollback: revert.
Size: L
Fixes: none

### S2.1 — Storefront and cart
Status: blocked (awaiting decision SD3)
Repo: both
Depends on: S1.4
Branch: feature/s2-1-storefront
Goal: Anyone can browse an operator's shop; signed-in users keep a cart across web and app.
Context: §3.4. Public routes like B2.1 (`/:operatorSlug/shop`, `/:operatorSlug/shop/:productSlug`).
Steps:
  1. backend: `carts`, `cart_items`; mutations `addToCart`, `updateCartItem`, `removeCartItem`; query `cart(dropzoneId)`
     with current prices and availability flags.
  2. client: shop home (categories, featured), product list, product detail (gallery, variant picker, stock state,
     markdown), cart screen; "sign in to buy" for anonymous visitors, returning to the product after login.
  3. Tests; smoke test step "browse shop, add to cart".
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export, smoke test pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: checkout (S2.2).
Risk / rollback: revert.
Size: L
Fixes: none

### S2.2 — Checkout with shipping and pickup
Status: blocked (awaiting decision SD2)
Repo: both
Depends on: S2.1
Branch: feature/s2-2-shop-checkout
Goal: Signed-in users buy physical goods with card, Apple Pay or Google Pay, choosing delivery or pickup.
Context: §3.4; COMMERCE checkout (C2.3–C2.5) and coupons (C2.7–C2.8).
Steps:
  1. backend: `shipping_zones`, `shipping_rates`, pickup setting; `shippingOptions(cartId, address)`; checkout from a
     cart (lines from cart items, address and rate snapshot); shipping in totals, tax and ledger; staff configuration
     mutations (`manageProducts`).
  2. client: address form (saved addresses per user), shipping option list, order summary with coupon, payment with
     the C2.5 components, order confirmation; shipping configuration screen for staff.
  3. Specs: rate selection by zone/postcode/weight, free-over threshold after discounts, tax on shipping, stock
     reserved and released, order emails (receipt with tax details from C1.2).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, web export, smoke test (checkout with the fake provider) pass.
Acceptance criteria (owner, real device):
  - Owner buys with Apple Pay on an iPhone and Google Pay on Android (staging test mode); the order, stock, ledger and
    fee agree.
Out of scope: carrier rates (SD2 b).
Risk / rollback: revert.
Size: L
Fixes: none

### S2.3 — Pay with wallet credits
Status: blocked (awaiting decision SD4)
Repo: both
Depends on: S2.2
Branch: feature/s2-3-wallet-tender
Goal: Members pay shop orders with credits when the operator uses the credit system.
Context: SD4; wallet code (`add_cents!`, P6.10 locks), `allow_negative_credits` setting.
Steps:
  1. backend: `payments.provider = wallet`; balance check under the wallet lock; ledger `customer_wallets` →
     revenue; refunds back to the wallet; no platform fee.
  2. client: "Pay with credits (balance A$…)" option in checkout.
  3. Specs: insufficient balance, concurrent wallet spend (manifest + shop at once) never overdraws, refund.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: split tender.
Risk / rollback: revert.
Size: M
Fixes: none

### S3.1 — Credit packages
Status: blocked (awaiting decision CD6)
Repo: both
Depends on: S2.3
Branch: feature/s3-1-credit-packages
Goal: Operators sell fixed credit packages with optional bonus credits, in the shop and on the top-up screen.
Context: §3.5; COMMERCE C2.3 `WalletTopUp`, C2.5 top-up screen, CD6 (iOS flag).
Steps:
  1. backend: product kind `credit_package` with `credits_cents`, `bonus_cents`; `Sellable` posting per §3.5; never
     discountable.
  2. client: packages shown on the top-up screen above the free-amount option; product form fields.
  3. Specs: bonus posting, coupon rejected, refund removes credits (refusing if the member already spent them, unless
     staff force it into a negative balance with a reason).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: none.
Risk / rollback: revert.
Size: M
Fixes: none

### S3.2 — Gift vouchers
Status: blocked (awaiting decision CD6)
Repo: both
Depends on: S3.1, B1.6
Branch: feature/s3-2-gift-vouchers
Goal: Customers buy gift vouchers for someone else; vouchers pay for shop orders and bookings.
Context: §3.5. Booking checkout (B1.6) accepts the voucher as a tender too.
Steps:
  1. backend: `gift_vouchers` (code, initial and remaining balance, expiry, purchaser, recipient, message, state),
     `gift_voucher_redemptions`; product kind `gift_voucher` (fixed amounts or a custom amount in a range); voucher
     email with code; `redeemGiftVoucher` in shop and booking checkout (partial redemption, the rest by card);
     staff `convertVoucherToCredits`; expiry job posting breakage per the accountant's advice (CD5).
  2. client: voucher product page (recipient fields), voucher field in checkout and booking payment, staff voucher
     lookup.
  3. Specs: concurrent redemption of one voucher never exceeds its balance, partial use, expiry, refund of a voucher
     purchase only while unused.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, web export pass.
Acceptance criteria (owner, real device):
  - Owner buys a voucher on the web and redeems half of it on a tandem booking.
Out of scope: printed vouchers (PDF) — add if operators ask.
Risk / rollback: revert.
Size: L
Fixes: none

### S3.3 — Membership products
Status: blocked (awaiting decision SD3)
Repo: both
Depends on: S3.2
Branch: feature/s3-3-memberships
Goal: Members renew their operator membership online.
Context: §3.5; `dropzone_users.expires_at`, `require_membership` eligibility rule.
Steps:
  1. backend: product kind `membership` with `duration_months`; `on_paid!` extends expiry; notification; ledger.
  2. client: "Renew membership" entry where an expired membership blocks manifesting.
  3. Specs: extension from today vs from a future expiry; refund does not shorten (staff adjust manually).
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: recurring subscriptions.
Risk / rollback: revert.
Size: M
Fixes: none

### S4.1 — Fulfilment, pickup and order emails
Status: blocked (awaiting decision SD2)
Repo: both
Depends on: S3.3
Branch: feature/s4-1-fulfilment
Goal: Staff ship or hand over orders, partially or fully, and customers are told at each step.
Context: §3.4 fulfilment.
Steps:
  1. backend: `shipments`; `createShipment(salesOrderId, lines, carrier, trackingNumber, trackingUrl)`,
     `markShipmentDelivered`, `markReadyForPickup`, `markPickedUp` (`updateOrders`); order `fulfilment_state`; emails
     and push; customer "My orders" query with shipments.
  2. client: fulfilment actions in the order detail; customer order history and tracking link.
  3. Specs: partial shipment states, refund of an unshipped line, notification sent once.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: labels and live carrier tracking (SD2 b), return authorisations.
Risk / rollback: revert.
Size: M
Fixes: none

### S4.2 — Orders dashboard
Status: blocked (awaiting decision SD2)
Repo: both
Depends on: S4.1
Branch: feature/s4-2-dashboard
Goal: Staff see at a glance what needs doing in the shop and act on it.
Context: §3.7 dashboard.
Steps:
  1. backend: `shopDashboard(dropzoneId)` (counts and first items per panel), `salesOrders(dropzoneId, filter)` with
     search by number, customer, product; subscription `salesOrderUpdated(dropzoneId)`; push on paid orders with a
     per-user opt-out setting.
  2. client: Shop dashboard (panels from §3.7), orders list with filters, order detail (lines, payments, refunds,
     shipments, notes, actions), staff landing card with counts.
  3. Tests: panels with mocked data, live update.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks, `check:graphql`, web export pass.
Acceptance criteria (owner, real device):
  - Owner places an order on one phone and sees it arrive on another phone's dashboard without refreshing.
Out of scope: none.
Risk / rollback: revert.
Size: L
Fixes: none

### S4.3 — Reports and statistics
Status: blocked (awaiting decision CD5)
Repo: both
Depends on: S4.2, B3.3
Branch: feature/s4-3-reports
Goal: Operators get the sales, stored-value and accounting reports in §3.7, with CSV export.
Context: §3.7 reports; ledger SQL aggregates (COMMERCE C1.3); booking statistics (B3.3); `react-native-chart-kit` is
already a client dependency.
Steps:
  1. backend: report queries (`readReports`), each returning rows plus totals, in the operator's time zone; CSV
     endpoint per report (signed, short-lived URL); trial balance and P&L from the ledger.
  2. client: Reports screen with date range, tabs (Sales, Products, Coupons, Stored value, Bookings, Accounting),
     charts for time series, CSV download.
  3. Specs: a fixed scenario (sales, discounts, refunds, vouchers, wallet spend, bookings) whose report totals equal
     the ledger; month boundary in a non-UTC zone.
Acceptance criteria (cloud VM):
  - Backend rspec green; client checks and web export pass.
Acceptance criteria (owner, real device):
  - none
Out of scope: accounting-software integrations.
Risk / rollback: read-only.
Size: L
Fixes: none

### S4.4 — Verify the webshop
Status: blocked (awaiting decision SD2)
Repo: both
Depends on: S4.3
Branch: feature/s4-4-verify
Goal: The webshop works end to end and is documented.
Context: all of this plan.
Steps:
  1. Run all checks; `docs/verification/webshop.md`.
  2. Update `docs/reference/README.md` (feature inventory, domain model, jobs, permissions) and `diagrams.md` (shop ER and
     order state diagram).
Acceptance criteria (cloud VM):
  - All checks exit 0.
Acceptance criteria (owner, real device):
  - Owner, on staging: buys a physical product (ship) and a voucher on web, a credit package on iPhone, pays with
    credits on Android; ships, refunds one line; reports and the fee statement match the Stripe Dashboard.
Out of scope: none.
Risk / rollback: none.
Size: S
Fixes: none
