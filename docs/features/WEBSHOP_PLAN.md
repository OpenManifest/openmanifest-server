# Webshop plan

Operators sell physical goods (merchandise, gear, packing supplies) and virtual products (credit packages, gift
vouchers, memberships) to signed-in members on the web and in the app, manage stock and fulfilment, and see sales
reports. Index: [README.md](README.md). Tasks and executor rules: [`../MODERNISATION_PLAN.md`](../MODERNISATION_PLAN.md). Builds on [COMMERCE_FOUNDATION.md](COMMERCE_FOUNDATION.md):
double-entry ledger, Money gem, Stripe with Apple Pay / Google Pay, platform fee, coupons, refunds.

Drafted 2026-10-11 against backend `0774b40` and client `dcc46d1`. Owner decisions recorded 2026-10-11 (§2).

## 1. Requirements coverage

| Owner requirement | Where |
|---|---|
| 1. Double-entry accounting with the Money gem | COMMERCE §3.1–3.2 (`double_entry`, CD2), C1.1–C1.3; every shop entry in §3.6 |
| 2. Products, stock, visibility | §3.1, §3.3; S1.1, S1.3, S1.4 |
| 3. Logged-in purchases on web and mobile with Google Pay / Apple Pay | §3.4; S2.1, S2.2 (payments from COMMERCE C2.5) |
| 4. Virtual products such as credit recharge | §3.5; S3.1–S3.3 (free-amount top-up already in COMMERCE C2.3) |
| 5. Coupon codes, also usable for booking | COMMERCE C2.7–C2.8 (one coupon system for both) |
| 6. Image/video upload, markdown product info | §3.2; S1.1, S1.2 |
| 7. Shipping | §3.4; S2.2, S4.1 |
| 8. Statistics and reports | §3.7; S4.3 |
| 9. Dashboard for pending orders | §3.7; S4.2 |
| Transaction fee | Every card payment goes through COMMERCE checkout (fee automatic); paying with credits per SD4 |

## 2. Decisions

Decided by the owner on 2026-10-11 (SD3 follows directly from requirement 3 and was not asked separately).

| ID | Decision | Decided | Notes | Tasks |
|---|---|---|---|---|
| SD1 | Video | **Direct uploads to the object store, MP4 (H.264/AAC), ≤ 200 MB and ≤ 3 minutes, poster frame generated with ffmpeg, no transcoding** | Needs ffmpeg in the production image (P8.4 Dockerfile) and CORS on the bucket. A video service (Mux, Cloudflare Stream) only if operators upload long or 4K video | S1.2 |
| SD2 | Shipping | **Zones with flat, weight-tiered and free-over-amount rates, local pickup, tracking numbers typed by staff** | Carrier labels and live rates (Shippo, EasyPost, Sendle) later, when an operator ships enough to want them | S2.2, S4.1 |
| SD3 | Who sees the shop | **Anyone can browse published products of an operator; buying requires sign-in**; per-product visibility `members` and `staff` for restricted items | | S1.1, S2.1 |
| SD4 | Paying with wallet credits | **Allowed when the operator uses the credit system; one tender per order** (all credits or all card) | No platform fee on credit spends (the fee was taken when the credits were bought, online or at the desk) | S2.3 |

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

The tasks (S1.1–S4.4) are Phase S of the plan, [`../MODERNISATION_PLAN.md`](../MODERNISATION_PLAN.md), where their status
is tracked and the Execution order places them. They use the renamed code (GENERALISATION §3: `Operator`,
`Membership`, `Vehicle`, `Guest`); this design's prose predates the rename and reads through that map.
