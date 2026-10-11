# Feature designs

Designs for the first features built on the modernised stack. Their tasks are Phases C, B and S of
[`../MODERNISATION_PLAN.md`](../MODERNISATION_PLAN.md).

Drafted 2026-10-11 against backend `0774b40` and client `dcc46d1` (both `staging`). All owner decisions were recorded
on 2026-10-11.

| Design | Plan phase | What it delivers |
|---|---|---|
| [COMMERCE_FOUNDATION.md](COMMERCE_FOUNDATION.md) | Phase C (`C1.x`, `C2.x`) | Money gem (replacing the app's own `Money` class), double-entry ledger (`double_entry` gem), Stripe Connect, the platform transaction fee on online and offline sales, customers, sales orders, checkout, refunds, coupons, Apple Pay / Google Pay. First vertical slice: members top up credits online. |
| [BOOKING_PLAN.md](BOOKING_PLAN.md) | Phase B (`B1.x`–`B3.x`) | Bookable services (tandems, tours, dive trips), availability and sessions, guest booking with captcha + email OTP + deposits, no double-booking, staff calendar, check-in to manifest. |
| [WEBSHOP_PLAN.md](WEBSHOP_PLAN.md) | Phase S (`S1.x`–`S4.x`) | Products, variants, stock, media, markdown, storefront, shipping, virtual products (credit packages, gift vouchers), order dashboard, reports. |

**Tasks are in the plan.** Since 2026-10-11 every task of these three designs is in
[`../MODERNISATION_PLAN.md`](../MODERNISATION_PLAN.md) (Phases C, B and S), with one set of executor instructions and one
Execution order for the whole project. Status is tracked there only. The plan places these phases after Phase 7 and the
UI modernisation (Phase U), so their tasks use the renamed code and the new UI layer; the prose in these designs
predates the rename and reads through GENERALISATION §3.

Why three designs: double-entry accounting, the payment provider, the platform fee, checkout and coupons are needed by
**both** booking and the webshop, and the platform fee is the product's revenue. Building them once, first, avoids two
half-implementations. Booking comes before the webshop because it depends only on the foundation and it is the feature
operators are most likely to pay for; the first booking and webshop tasks both depend only on `C2.9`, so when booking is
blocked on a decision the executor continues with the webshop.

## Decisions across the three plans

Recorded 2026-10-11; details and rejected options in each plan's §2.

| ID | Decided | Plan |
|---|---|---|
| CD1 | Stripe Connect, direct charges on operator ("Standard") accounts, fee via `application_fee_amount`; no ActiveMerchant | Commerce |
| CD2 | `double_entry` gem behind a `Ledger` wrapper (instead of Plutus), with a journal outbox | Commerce |
| CD3 | Fees are configurable plans assigned per operator (optionally until a date); free operators and fee-free deployments supported. Default plan: online 1.5 % + A$0.30 (min A$0.50), offline 1 %; operator absorbs the fee | Commerce |
| CD4 | Fee refunded in proportion to refunds and lost disputes | Commerce |
| CD5 | One tax rate per operator, tax-inclusive prices; stored value taxed on redemption (accountant to confirm) | Commerce |
| CD6 | Credits and vouchers sold in-app via Apple Pay / Google Pay, with a switch to hide them on iOS | Commerce |
| CD7 | Offline fees carried forward into later application fees (≤ 5 % of a payment), remainder invoiced monthly | Commerce |
| BD1–BD7 | Guests book on the web only; Turnstile + email code; full prepayment by default; balance at the desk or by link; individual resource units; 72 h / 24 h cancellation tiers with reschedule-or-refund on weather; check-in puts bookings on a load | Booking |
| SD1–SD4 | MP4 uploads ≤ 200 MB, no transcoding; zones/rates/pickup shipping; browse public, buy signed in; pay with credits, one tender | Webshop |
