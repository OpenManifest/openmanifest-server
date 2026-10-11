# Feature plans

Draft plans for the first features built on the modernised stack. They are written in the same task format as
[`../MODERNISATION_PLAN.md`](../MODERNISATION_PLAN.md) and follow its **Executor instructions**, with the differences
listed below.

Drafted 2026-10-11 against backend `0774b40` and client `dcc46d1` (both `staging`). **Status: draft.** Every task is
`blocked (awaiting decision …)` until the owner records the decisions it depends on.

| Order | Plan | Task IDs | What it delivers |
|---|---|---|---|
| 1 | [COMMERCE_FOUNDATION.md](COMMERCE_FOUNDATION.md) | `C1.x`, `C2.x` | Money gem, double-entry ledger (Plutus), Stripe Connect, the platform transaction fee, customers, sales orders, checkout, refunds, coupons, Apple Pay / Google Pay. First vertical slice: members top up credits online. |
| 2 | [BOOKING_PLAN.md](BOOKING_PLAN.md) | `B1.x`–`B3.x` | Bookable services (tandems, tours, dive trips), availability and slots, guest booking with captcha + email OTP + deposits, no double-booking, staff calendar, check-in to manifest. |
| 3 | [WEBSHOP_PLAN.md](WEBSHOP_PLAN.md) | `S1.x`–`S4.x` | Products, variants, stock, media, markdown, storefront, shipping, virtual products (credit packages, gift vouchers), order dashboard, reports. |

Why three files when the owner asked for two plans: double-entry accounting, the payment provider, the platform fee,
checkout and coupons are needed by **both** booking and the webshop, and the platform fee is the product's revenue.
Building them once, first, avoids two half-implementations. Booking comes before the webshop because it depends only
on the foundation, and it is the feature operators are most likely to pay for (tandem and trip bookings are the
operator's highest-value sales). The first booking and webshop tasks both depend only on `C2.9`, so when booking is
blocked on a decision the executor can continue with the webshop; the few cross-links are explicit `Depends on` lines
(gift vouchers need booking checkout, reports include booking statistics).

## Prerequisites

- Phase 6 of the modernisation plan is `done` (tenant isolation, money in cents, locks, Solid Queue). `C1.1` depends on
  `P6.27`, which is `owner-check` today, so these plans cannot start before the owner signs Phase 6 off.
- Phase 7 (industry profiles) is **not** a prerequisite. Booking uses neutral names ("service", "session", "resource")
  so it works for any profile. The only Phase 7 overlap is `B3.2` (check-in to manifest), which is skydiving-only until
  P7.4/P7.9 land.
- Real payments need a deployed API with a public HTTPS URL for webhooks (P8.4). Until then, cloud-VM acceptance uses
  the fake payment adapter (`C2.1`) and recorded Stripe fixtures; Stripe test-mode checks are owner checks on staging.

## Executor rules (differences from the modernisation plan)

- **Picking the task**: only when no modernisation-plan task qualifies, read the feature plans in the order of the
  table above and pick the first qualifying task.
- **Branch**: `feature/{id}-{short-slug}`, e.g. `feature/c1-3-ledger`. Use the `Branch:` value from the task.
- **Commit subject**: Conventional Commits with the task ID, e.g. `feat(ledger): add chart of accounts [C1.3]`.
- **Status**: update the task's `Status:` line in the feature plan that contains it (backend repo only).
- **Decisions**: written in the decision table of the plan that owns them ("Decision: …, date"). The executor unblocks the
  dependent tasks in the next task's PR, as in the modernisation plan.
- **External services**: `api.stripe.com`, `js.stripe.com` and `challenges.cloudflare.com` are not reachable from the
  VM. Specs stub HTTP with WebMock and recorded fixtures under `spec/fixtures/stripe/` and `spec/fixtures/turnstile/`.
  Never put real keys in fixtures. If the owner later allowlists Stripe (CLOUD_ENV §2) with test-mode keys, tasks may
  add an opt-in `STRIPE_LIVE_TESTS=1` spec group; CI never runs it.
- **Secrets**: new server variables (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `TURNSTILE_SECRET_KEY`) go into the
  environment-variable table of [`../reference/README.md`](../reference/README.md) §8 by name only. Publishable keys
  (`EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY`, `EXPO_PUBLIC_TURNSTILE_SITE_KEY`) are not secrets and go into the client's
  per-environment config.

## Decisions across the three plans

| ID | Topic | Plan | Blocks |
|---|---|---|---|
| CD1 | Payment provider and Connect charge model | Commerce | C2.1 onward |
| CD2 | Ledger library (Plutus vs alternatives) | Commerce | C1.3 onward |
| CD3 | Platform fee schedule and which sales it applies to | Commerce | C2.2 |
| CD4 | Platform fee on refunds and disputes | Commerce | C2.5 |
| CD5 | Sales tax handling | Commerce | C1.2 |
| CD6 | In-app sale of credits and vouchers (App Store / Play policy) | Commerce | C2.4, S3.1, S3.2 |
| BD1–BD7 | Guest channel, verification, deposits, balance, resources, cancellation policy, manifest link | Booking | B-tasks |
| SD1–SD4 | Video hosting, shipping, shop visibility, paying with credits | Webshop | S-tasks |
