<!-- 95f2c221-5b1e-40dc-a78d-0f73c7b0b0fe 897e1470-5567-41cc-b58c-40789a7589db -->
# Payment & Admin Enablement

## Milestone A – Payment Experience (User App)

- **checkout-ui**: Design multi-step checkout (seat summary, payment options, promo) connected to booking context.
- **payment-gateways**: Implement UPI/Card/Wallet flows via unified payment service (mock driver + ready hooks for Razorpay/Stripe); handle success/failure states.
- **receipt-confirmation**: Generate confirmation page with QR ticket, email/SMS stub, download/share actions.
- **booking-audit**: Persist payment intents, transactions, and booking state transitions in backend; add retries & refund flag support.

## Milestone B – Admin Portal Access

- **admin-auth-ui**: Build dedicated admin login page (admin@developer.com / 12345) with role-based guard and session handling.
- **admin-shell**: Create responsive layout with sidebar nav, top bar, breadcrumb, dark theme toggle.
- **access-control**: Extend JWT payload with admin flag, middleware for admin routes, and protected Flutter web screens.

## Milestone C – Admin Management UIs

- **movies-manager-ui**: CRUD tables/forms for movies, poster upload widget, cast/genre editors, publish toggle.
- **showtimes-pricing-ui**: Management screens for showtimes, auditorium assignment, seat pricing tiers, availability rules.
- **seat-editor-ui**: Visual seat map editor (drag/drop, seat type palette, aisle toggle) with preview + save.
- **booking-ops-ui**: Admin bookings table, filters, detail modal with refund/cancel actions and audit log.
- **payments-settlement-ui**: Transaction ledger view, settlement reports, gateway log viewer, export controls.

### To-dos

- [ ] Upgrade splash/onboarding flows with production assets and analytics
- [ ] Replace mock data with movie discovery APIs and watchlist support
- [ ] Implement full booking flow: cinema, seats, payments, confirmation
- [ ] Build bookings hub with upcoming/past, cancel/refund, QR share
- [ ] Backend-powered search with filters, trending, history
- [ ] Persist preferences/watchlist, personalize carousels
- [ ] Offers page and notification center with backend support
- [ ] Help & support hub with FAQ, contact form, live chat placeholder
- [x] Secure admin login (admin@developer.com / 12345) with role guard
- [ ] Analytics dashboard with metrics, charts, alerts, top movies
- [x] Admin CRUD for movies with poster upload and metadata
- [x] Admin showtime scheduling with pricing tiers
- [x] Visual seat editor with seat types and aisle toggles
- [ ] Dynamic pricing rules and promo code management
- [x] Admin booking moderation with refund/cancel workflows
- [x] Transaction ledger and settlement reports
- [x] Admin notification composer with segmentation
- [ ] Advanced analytics: revenue, occupancy, heatmaps
- [x] Global platform settings form with validation
- [x] Expand Postgres schema for all new entities
- [x] Implement REST endpoints with role-based auth and docs
- [x] Add automated tests and CI coverage for backend/front
- [ ] Docker, environment scripts, CI/CD, release checklist