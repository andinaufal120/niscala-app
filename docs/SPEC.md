# SPEC.md — Niscala mobile app

> **Audience:** coding agents working in this repository.
> **Scope:** the Flutter Android app only. The backend lives in a separate repository (`andinaufal120/niscala-api`) and owns all business rules and the API contract.
> **Status:** self-contained, together with `docs/ACCESSIBILITY.md`. Everything an agent needs to know about required app behaviour is in these two files. Do not look for requirements elsewhere.

Traceability IDs (`FR-xx`, `NFR-xx`, `UC-xx`, `TBD-x`, `U-x`) are stable keys shared with the project's requirements baseline (v1.1, 16-10-2026), the backend repository and Jira. Use them in commit messages and PR descriptions, never in source code or test names.

Blocks between `<!-- shared:begin -->` and `<!-- shared:end -->` are identical in the backend repository's `docs/SPEC.md`. Change them in both repositories together (see `CLAUDE.md`, "Shared sections").

---

## 1. Product

*Shared with niscala-api.*

<!-- shared:begin -->
Niscala ("Kelola Kost Tanpa Ribet") helps boarding-house (kos) owners and managers handle properties, rooms, tenants, rent payments and maintenance complaints in one Android app.

- Rent is paid **outside** the app (cash or bank transfer). The app records, verifies and tracks payment status. It never moves rent money.
- Two AI features set the product apart. Both are available only when the property owner has an active paid subscription (plan Basic or Pro):
    1. classification of maintenance complaints (category, urgency, suggested action);
    2. a natural-language summary of each tenant's payment pattern.
- Owners choose a plan: Gratis (1 property, 15 rooms, no AI), Basic (3 properties, unlimited rooms, AI) or Pro (unlimited properties, everything in Basic). Subscriptions are bought and renewed through Google Play Billing in the app; the backend verifies the purchase with Google.
- An AI failure never blocks saving data.
- Out of scope for v1.0: in-app rent payment, OAuth providers other than Google, iOS and web apps.
<!-- shared:end -->

## 2. Boundary of this repository

| The app does                                            | The backend does (not this repo)                                    |
|---------------------------------------------------------|---------------------------------------------------------------------|
| Render screens, forms, lists and states                 | Store data, enforce permissions                                     |
| Validate input before sending (format, required fields) | Re-validate everything; it is the authority                         |
| Show results the API returns                            | Compute billing dates, due dates, payment-pattern facts, risk flags |
| Show subscription-gated content as the API reports it   | Decide subscription gating (FR-25, NFR-15)                          |
| Show AI results or their pending/unavailable state      | Call Gemini, retries, fallback (FR-28)                              |
| Pick files, share links, display QR codes               | Generate bills (FR-31), invitations, notifications                  |

**Invariant:** the app never re-implements a backend rule. If a screen needs a value the API does not provide, that is a contract gap. Raise it in Plan mode; do not compute it locally.

## 3. Glossary

*Shared with niscala-api.*

<!-- shared:begin -->
Markdown docs use the format *Original term (English term)*. Code uses the English **code name** only.

| Term                                                | Code name                 | Meaning                                                                            |
|-----------------------------------------------------|---------------------------|------------------------------------------------------------------------------------|
| Niscala                                             | —                         | This product.                                                                      |
| Properti (Property)                                 | `Property`                | One kos location with rooms, owned by one Owner.                                   |
| Kamar (Room)                                        | `Room`                    | A rentable unit in a property. Occupancy is Terisi or Kosong.                      |
| Masa sewa (Lease)                                   | `Lease`                   | A tenant's occupancy of a room: start date, end date, rent, billing cycle, grace period. |
| Penyewa (Tenant)                                    | `Tenant`                  | User who occupies a room; joins through an invitation link.                        |
| Pemilik Kost (Owner)                                | `Owner`                   | User who owns one or more properties and holds the subscription.                   |
| Pengelola Kost (Manager)                            | `Manager`                 | Optional user assigned by an Owner to specific properties.                         |
| Admin (Admin)                                       | `Admin`                   | Internal user who manages all user accounts.                                       |
| Akun pengguna (User account)                        | `UserAccount`             | Any user's login identity: name, email, role and status. Admins manage all of them. |
| Manajemen kost (Management)                         | `management` (role group) | Owner and Manager together.                                                        |
| Rekening bank (Bank account)                        | `BankAccount`             | Optional per-property account for rent transfers: bank name, account number, account holder name. |
| Tarif dasar (Base rate)                             | `baseRate`                | A room's monthly price. Only pre-fills the rent of a new monthly lease.            |
| Tarif sewa (Rent)                                   | `rent`                    | The amount of one bill of a lease, per billing cycle. A change applies from the next bill onward. |
| Ukuran kamar (Room dimensions)                      | `lengthM`, `widthM`       | Optional, in metres. Area is length × width, for display only, never stored.       |
| Fasilitas (Facilities)                              | `facilities`              | Free-form tags on a room, normalized on save.                                      |
| Undangan (Invitation)                               | `Invitation`              | Lets a Tenant or Manager activate an account.                                      |
| Laporan keluhan (Complaint)                         | `Complaint`               | Free-text maintenance report from a Tenant.                                        |
| Klasifikasi AI (AI classification)                  | `ComplaintClassification` | Category, urgency and suggested action for a complaint, set by AI or by management (UC-36). |
| Catatan penanganan (Handling note)                  | `handlingNote`            | Optional note on a complaint status change. Visible to the Tenant.                 |
| Tagihan sewa (Rent bill)                            | `RentBill`                | Rent owed for one billing period. Generated by the backend (FR-31).                |
| Pembayaran (Payment)                                | `Payment`                 | The payment record attached to a rent bill.                                        |
| Siklus penagihan (Billing cycle)                    | `BillingCycle`            | Weekly, monthly, 3, 6 or 12 months. Default: monthly from the lease start date.    |
| Masa tenggang (Grace period)                        | `gracePeriodDays`         | Days after the bill date before a payment is late. Default: 0.                     |
| Jatuh tempo (Due date)                              | `dueDate`                 | Bill date + grace period. Computed by the backend.                                 |
| Ringkasan pola pembayaran (Payment-pattern summary) | `PaymentPatternSummary`   | AI-written sentence built from rule-computed payment facts.                        |
| Langganan (Subscription)                            | `Subscription`            | The Owner's paid plan that unlocks AI features and raises the property limit.     |
| Paket (Subscription plan)                           | `SubscriptionPlan`        | Gratis (`free`), Basic (`basic`) or Pro (`pro`): property and room limits, AI availability and prices. |
| Pesanan langganan (Subscription order)              | `SubscriptionOrder`       | One attempt to buy a paid plan through Google Play; tracks the purchase until it succeeds, fails or expires. |
| Sesi (Session)                                      | `Session`                 | One logged-in device of a user.                                                    |
| Notifikasi (Notification)                           | `Notification`            | In-app message about an event: bill, payment, complaint or account. Kept even when its push is off. |
| Pengaturan notifikasi (Notification settings)       | `NotificationSettings`    | Per-user push on/off switch per notification category.                             |
| Soft delete (Soft delete)                           | —                         | Marked inactive; history is kept.                                                  |
<!-- shared:end -->

UI copy is in **Indonesian**. Menu and button names in this spec are given as *Indonesian (English)*. The English is for understanding only and must not appear in the UI.

## 4. Roles and permissions

*Shared with niscala-api.*

<!-- shared:begin -->
`✓` allowed · `A` only on properties assigned to the Manager · `—` not allowed

| Capability                                                   | Tenant | Owner | Manager | Admin |
|--------------------------------------------------------------|:------:|:-----:|:-------:|:-----:|
| View own room, lease, payments, complaints                   |   ✓   |   —   |    —    |   —   |
| Submit complaint, upload transfer receipt                    |   ✓   |   —   |    —    |   —   |
| Add / edit / delete property                                 |   —    |  ✓   |    —    |   —   |
| View property                                                |   —    |  ✓   |    A    |   —   |
| Add / view / edit / delete room                              |   —    |  ✓   |    A    |   —   |
| Add / view / edit / delete tenant                            |   —    |  ✓   |    A    |   —   |
| Verify/reject receipts, record cash, change payment status   |   —    |  ✓   |    A    |   —   |
| Occupancy dashboard, complaint list, change complaint status, classify complaint manually |   —    |  ✓   |    A    |   —   |
| Payment status of all tenants, payment-pattern view          |   —    |  ✓   |    A    |   —   |
| Add / view / edit / delete managers                          |   —    |  ✓   |    —    |   —   |
| Choose and pay for a subscription                            |   —    |  ✓   |    —    |   —   |
| View / edit / delete any user account                        |   —    |   —   |    —    |  ✓   |
| View / end own sessions, change own password                 |   ✓   |  ✓   |    ✓    |  ✓   |
| View own notifications, change own notification settings     |   ✓   |  ✓   |    ✓    |   —   |

Each role sees only the menus it is allowed to use. The backend enforces permissions; the app hides what a role cannot do.
<!-- shared:end -->

## 5. Status vocabularies

Show statuses with the same label, colour and icon on every screen.

*Shared with niscala-api.*

<!-- shared:begin -->
| Entity                           | Statuses — Indonesian label (English, `codeName`)                                                                                                                                                                     |
|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Room occupancy                   | Terisi (Occupied, `occupied`) · Kosong (Vacant, `vacant`)                                                                                                                                                             |
| Payment                          | Belum Bayar (Unpaid, `unpaid`) · Menunggu Verifikasi (Awaiting verification, `awaitingVerification`) · Lunas (Paid, `paid`) · Ditolak (Rejected, `rejected`)                                                          |
| Payment method                   | Transfer (Bank transfer, `transfer`) · Tunai (Cash, `cash`)                                                                                                                                                           |
| Login method                     | Google (Google, `google`) · Kata sandi (Password, `password`)                                                                                                                                                         |
| Billing cycle                    | Mingguan (Weekly, `weekly`) · Bulanan (Monthly, `monthly`) · 3 Bulan (Quarterly, `quarterly`) · 6 Bulan (Semiannual, `semiannual`) · 12 Bulan (Annual, `annual`) |
| Complaint                        | Baru (New, `new_`) · Diproses (In progress, `inProgress`) · Selesai (Done, `done`) |
| Complaint classification         | Sedang Diklasifikasi (Classifying, `classifying`) · Menunggu Klasifikasi (Awaiting classification, `awaitingClassification`) · Belum Diklasifikasi (Not classified, `notClassified`) |
| Complaint urgency                | Rendah (Low, `low`) · Sedang (Medium, `medium`) · Tinggi (High, `high`) |
| Tenant account                   | Belum Diaktifkan (Not activated, `notActivated`) · Aktif (Active, `active`)                                                                                                                                           |
| Manager account                  | Belum Diaktifkan (Not activated, `notActivated`) · Aktif (Active, `active`)                                                                                                                                           |
| User account (Admin view)        | Aktif (Active, `active`) · Nonaktif (Suspended, `inactive`) · Dihapus (Deleted, `deleted`)                                                                                                                            |
| Subscription order / transaction | Menunggu Pembayaran (Awaiting payment, `awaitingPayment`) · Berhasil (Succeeded, `succeeded`) · Gagal (Failed, `failed`) · Kedaluwarsa (Expired, `expired`)                                                           |
| Subscription                     | Gratis (Free, `free`) · Aktif (Active, `active`) |
| Subscription plan                | Gratis (Free, `free`) · Basic (Basic, `basic`) · Pro (Pro, `pro`) |
| Subscription billing period      | Bulanan (Monthly, `monthly`) · Tahunan (Yearly, `yearly`) |

Complaint status moves forward one step at a time: *Baru* → *Diproses* → *Selesai*. Nothing changes after *Selesai*.

Classification state is separate from status. *Sedang Diklasifikasi* = the complaint is saved and the AI is still working on it; it ends as a classification or as *Menunggu Klasifikasi*. *Menunggu Klasifikasi* = AI was attempted and failed or timed out. *Belum Diklasifikasi* = the Owner had no active subscription when the complaint was saved, so AI was skipped. A classified complaint has neither.

Order status maps to Google Play like this: the order starts as *Menunggu Pembayaran*; a verified purchase in state purchased makes it *Berhasil*; a purchase Google reports as pending (for example pay at a convenience store) keeps it *Menunggu Pembayaran*; a purchase Google reports as failed or canceled makes it *Gagal*; an order whose purchase never completes within its time limit becomes *Kedaluwarsa*. Subscription *Gratis* means no paid period is running; *Aktif* means a paid period is running.

A *Nonaktif* account is suspended: it cannot log in and can be reactivated. A *Dihapus* account is soft-deleted, hidden from the default account list, and can never be reactivated. *Dihapus* is shown, never set, through the edit endpoint.

`new_` is only the Dart identifier, because `new` is reserved in Dart. The wire value is `"new"`.
<!-- shared:end -->

## 6. Cross-cutting UI rules

These apply to every use case below. Use cases do not repeat them.

1. **Expired session** → go to the login screen.
2. **Validation errors** state the cause next to the field (for example "Nomor telepon tidak valid"), never a generic message. The text is Indonesian, mapped from the error code the API returns; the API's English message is never shown. An unknown code shows a generic Indonesian message (for example "Terjadi kesalahan. Coba lagi."); this is the only case where a generic message is allowed.
3. **Destructive actions** (delete property, room, tenant, manager, account) always ask for confirmation. Cancelling returns to the previous detail screen with nothing changed.
4. **Conflict** ("already changed by another user") → show a message and reload the current detail or list.
5. **Server or network failure** → show an error message. Nothing is saved, and the user can retry.
6. **Empty lists** show an explanatory empty state, not a blank screen.
7. **Subscription-gated content** (AI classification, payment-pattern summary) is replaced by a note that it needs an active subscription. The rest of the screen still works.
8. **AI unavailable** never blocks a flow. Show the pending or unavailable state and continue.
9. **Accessibility:** WCAG 2.2 Level A (NFR-14), plus the project rules in `docs/ACCESSIBILITY.md`, which defines how both apply and how they are verified.
10. **Transport:** HTTPS only (NFR-08).
11. **AI output** always shows a short disclaimer.
12. **Lists:** filter chips sit in the page body, not the header. Default filters are given per use case.
13. **Money** is shown as "Rp800.000", with no space between "Rp" and the number.

## 6a. Navigation

Bottom navigation:
- Management: *Beranda*, *Keluhan*, *Pembayaran*, *Properti*, *Akun*.
- Tenant: *Beranda*, *Keluhan*, *Pembayaran*, *Akun*.

*Akun (Account)*, for every role: profile; security (Google and local password, active devices (UC-37), change password (UC-38)); help; notifications; log out. In addition:
- Owner: *Langganan (Subscription)*.
- Manager: their assigned properties, read-only.
- Tenant: room and lease details (UC-01).

## 7. Account access

*Shared with niscala-api.*

<!-- shared:begin -->
Login and sign-up are preconditions, not use cases. All use cases assume a valid session. The account identifier is **email**.

- **Owner** signs up and logs in with Google or a local password (FR-20).
- **Tenant** activates through an invitation link shared by management. During activation the tenant completes whatever data management left empty, including email and at least 2 emergency contacts if management gave none, then chooses Google or a local password (FR-01).
- **Manager** activates through an invitation link shared by the Owner, enters their own email, and chooses Google or a local password; a person who already has a Manager account can accept the link with that account (FR-26).
- **Profile menu (FR-30):** a Google-only user can add a local password. A password user can link Google, but only after logging in with the password. The app never links accounts automatically by matching email.
- **Local password rules (NFR-11, NIST SP 800-63B Rev. 3, AAL1).** These apply only to accounts with a local password:
    - minimum 8 characters, and at least 64 accepted;
    - no composition rules and no forced periodic change;
    - a show-password toggle while typing;
    - the backend rejects common passwords (a local list), a single repeated character or an ascending/descending run, and passwords containing "niscala" or the user's email local part or name (when ≥ 4 characters). It also rate-limits failed logins. The app's strength meter is a hint only. The app shows these errors in Indonesian, mapped from the error code the API returns.
- **Sessions (FR-33, NFR-18):**
    - a user may be logged in on several devices at once;
    - a user can list their sessions and end the session of one other device or of all other devices (UC-37);
    - after a password change, the user is offered to log out all other devices (UC-38);
    - a session ends after 90 days without use, and at most 1 year after the last authentication regardless of activity; refreshing restarts the 90 days but never the 1 year (longer than the 30-day reauthentication that NIST SP 800-63B Rev. 3, AAL1 recommends, so that tenants who open the app only around due dates are not logged out between visits);
    - a session ended by the user or by Admin stops working within 15 minutes at most.
<!-- shared:end -->

## 8. Use cases

Format: actor · entry point · flow · outcomes. Menu names are *Indonesian (English)*.

### 8.1 Tenant (Penyewa)

**UC-01 View room and lease** (FR-02) · Tenant · *Akun (Account)*
Shows room number, property address, lease start and end dates, rent, room dimensions and facilities. If there is no room or lease → message to contact management.

**UC-02 Submit maintenance complaint** (FR-03, FR-04, FR-25, FR-28) · Tenant with an active lease · *Keluhan (Complaints)* tab → complaint list → new complaint
Free-text description → submit → confirmation. An empty or too-short description gets a field error (minimum length: see §10). After saving, the complaint is *Baru* and its classification state is one of: classified, *Menunggu Klasifikasi*, or *Belum Diklasifikasi*. The app shows the confirmation as soon as the save succeeds; it does not wait for the AI.

**UC-03 View complaint status and history** (FR-05) · Tenant · *Keluhan (Complaints)* tab
List of own complaints, opening on the *Aktif (Active)* filter (*Baru* and *Diproses*). Each shows its status and marks complaints still *Menunggu Klasifikasi* or *Belum Diklasifikasi*. Detail shows category and urgency if classified, and the handling note of each status change. Empty state if none.

**UC-04 View rent payment history and status** (FR-06) · Tenant with an active lease · *Pembayaran (Payments)* tab
List of bills/payments with status (§5), period, amount and due date. Filters: *Tagihan aktif (Active bill)*, the default, and *Riwayat (History)*. A rejected payment shows the reason management entered.

**UC-05 Upload transfer receipt** (FR-07) · Tenant · from a current-period bill that is *Belum Bayar* or *Ditolak*, on *Pembayaran* or *Beranda* → *Unggah Bukti (Upload receipt)*
The screen shows the property's bank account and the amount to transfer. Pick an image from the gallery or the camera → submit. Images only: JPG or PNG, at most 5 MB; anything else gets a field error. Camera photos are re-encoded to JPEG before upload, because many Android cameras save HEIC. On success the status becomes *Menunggu Verifikasi*.
If the property has no bank account, the transfer and upload actions are hidden and the tenant is told to pay cash to management.

**UC-06 View notifications** (FR-08) · Tenant · *Notifikasi (Notifications)*
In-app list only, newest first, unread ones marked. Two types: due-date reminder and payment-status change. Opening one marks it read and shows type, period and status, with a path to UC-04. Empty state if none.

### 8.2 Management (Pemilik Kost and Pengelola Kost)

Managers see only their assigned properties. The selected property becomes the **active management context** for the property-scoped menus.

**UC-07 Verify or reject receipt** (FR-08, FR-09) · *Pembayaran → Menunggu Verifikasi (Payments → Awaiting verification)*
List of payments awaiting verification → detail with tenant, room, period, amount and receipt image (with a reload option if the image fails to load).
- *Verifikasi (Verify)* → *Lunas*.
- *Tolak (Reject)* → a rejection reason is required → *Ditolak*, and the tenant can upload again.
  The tenant is notified. If the notification fails, the status change still stands.

**UC-08 Record cash payment** (FR-08, FR-10) · *Pembayaran → Catat Pembayaran Tunai (Payments → Record cash)*
Pick a tenant with an unpaid bill (*Belum Bayar* or *Ditolak*) → pick the period → enter the date received → confirm the cash was received → *Lunas*, method *Tunai*. An invalid date gets a field error. Only management can start this flow.

**UC-09 Change payment status manually** (FR-08, FR-11) · *Pembayaran → [payment] → Ubah Status (Change status)*
Choose *Belum Bayar*, *Lunas* or *Ditolak* and enter a **required** reason. Choosing the current status or leaving the reason empty gets a field error.

**UC-10 Add property** (FR-12, FR-21) · **Owner only** · *Properti → Tambah Properti (Properties → Add)*
Fields: name and address, both required, and an optional bank account (bank name, account number, account holder name). The name must be unique within the Owner's account (the error comes from the API).

**UC-11 View properties** (FR-12, FR-21) · *Properti (Properties)*
List with room count and assigned managers. Selecting one shows its detail (name, address, bank account if set, room count, assigned Manager) and sets it as the active context. A Manager can view but not edit or delete. With access to exactly one property, skip the list and open its detail directly.

**UC-12 Edit property** (FR-12) · **Owner only** · *Properti → [property] → Ubah Properti (Edit)*
Form pre-filled with name, address and bank account.

**UC-13 Delete property** (FR-12) · **Owner only** · *Properti → [property] → Hapus Properti (Delete)*
Rejected if the property has an active lease. On success the property's rooms and manager assignments are removed too.

**UC-14 Add room** (FR-12) · *[property] → Kamar → Tambah Kamar (Rooms → Add)*
Fields:
- room number: required, unique within the property;
- base rate: required, per month;
- length and width in metres: optional, each 0 < x ≤ 20 with at most 2 decimals, a comma decimal accepted ("3,5"); both or neither, otherwise a field error;
- facilities: free-form tags, at most 30 characters per tag and 15 tags per room, with suggestions from the API (tags the same Owner has used before). The API normalizes tags on save.

**UC-15 View rooms** (FR-12) · *[property] → Kamar (Rooms)*
List with number, base rate and occupancy; default filter *Semua (All)*. Detail adds dimensions with the area (length × width, computed for display only), facilities, plus the tenant, lease dates and that lease's rent if occupied.

**UC-16 Edit room** (FR-12) · *[room] → Ubah Kamar (Edit)* · same fields and rules as UC-14. Tell the user that changing the base rate does not change the rent of existing leases.

**UC-17 Delete room** (FR-12) · *[room] → Hapus Kamar (Delete)* · rejected if the room has an active lease.

**UC-18 Add tenant** (FR-13) · *[property] → Penyewa → Tambah Penyewa (Tenants → Add)*
Required fields: room (vacant rooms only), name, phone number. Optional fields: occupation, emergency contacts (2 to 4, or none for the tenant to complete during activation), lease dates, billing cycle (§3, default monthly), grace period (default 0), rent (per billing cycle; pre-filled with the room's base rate for a monthly lease, editable).
On save, the room becomes *Terisi* and an **invitation link** is shown. The link can be shared via WhatsApp or shown as a QR code. If link creation fails, the tenant is still saved, and the link can be regenerated in UC-20.

**UC-19 View tenants** (FR-13) · *[property] → Penyewa (Tenants)*
List with room, lease and account status. Detail shows personal data, room, lease and activation status.

**UC-20 Edit tenant** (FR-13) · *[tenant] → Ubah Data Penyewa (Edit)*
Editable: name, phone, occupation, emergency contacts, lease dates, rent, billing cycle, grace period. The lease end date must not be before the start date. Tell the user that a rent or billing-cycle change applies **from the next bill onward**.
Alternative: *Buat Ulang Tautan Undangan (Regenerate invitation link)* for an unused or expired invitation. It creates a new link, invalidates the old one and shows the new one for sharing. If regeneration fails, the old link stays valid.

**UC-21 Delete tenant** (FR-13) · *[tenant] → Hapus Penyewa (Delete)*
Soft delete: the lease ends, account access is revoked and the room becomes *Kosong*. Payment and complaint history is kept.

**UC-22 Occupancy dashboard** (FR-14) · *Beranda (Home)*
Per property: occupied count, vacant count, occupancy percentage and each room's status. With several properties, show a summary of all of them first, then per-property detail. All figures come from the API. A Manager sees a restricted version (content: U-22).

**UC-23 Complaint list with AI classification** (FR-15, FR-25) · *Keluhan (Complaints)*
Complaints across accessible properties, sorted by urgency, then time; default filter *Semua (All)*. Shows category, urgency and suggested action when available. Unclassified complaints show their classification state instead. Without an active subscription, hide AI classification results and show the subscription note; manual classifications (UC-36) are still shown.
Detail order: status first, then the AI classification, then the tenant's message with tenant name, room and timestamp.

**UC-24 Change complaint status** (FR-16) · *[complaint] → Ubah Status (Change status)*
Offers only the next status (*Baru* → *Diproses*, *Diproses* → *Selesai*) and asks for confirmation. The optional handling note is labelled as visible to the tenant. No status action remains once a complaint is *Selesai*.

**UC-36 Classify complaint manually** (FR-32) · from the complaint detail
Set category and urgency on a complaint that is *Menunggu Klasifikasi* or *Belum Diklasifikasi*, or correct an AI classification (category list: U-16). Available without an active subscription; it is not an AI feature. A later AI result never overwrites the manual values. Submitting the current values changes nothing.

**UC-25 Payment status of all tenants** (FR-17) · *Pembayaran (Payments)*
Pick a property and a period (default: current) → list of tenants with room, amount and status; default filter *Belum lunas (Unpaid)*, meaning every status except *Lunas*. Selecting a tenant shows their payment history.

**UC-26 Payment-pattern summary** (FR-18, FR-19, FR-25, FR-28) · *Pembayaran → Risiko Pembayaran (Payments → Payment risk)*
Every tenant is listed with:
- rule-computed facts (for example average days paid relative to the due date, and late frequency);
- an at-risk flag;
- the stored AI summary, or "belum tersedia" (not yet available).
  Without an active subscription, show facts and flags only, plus the subscription note. Opening this screen never triggers AI generation; summaries are regenerated by the backend when a payment status changes.

### 8.3 Owner only (Pemilik Kost)

**UC-27 Add manager** (FR-22) · *Properti → [property] → Pengelola → Tambah Pengelola (Managers → Add)*
Fields: name, email, and at least one property. The email must not be registered already. An invitation is emailed. If sending fails, the account is saved as *Belum Terkirim* and can be resent in UC-29.

**UC-28 View managers** (FR-22) · *Properti → [property] → Pengelola (Managers)*
List with name, email, assigned properties and account status. The empty state includes the *Tambah Pengelola* button.

**UC-29 Edit manager** (FR-22) · *[manager] → Ubah (Edit)*
Change name, email or assigned properties, with at least one property. Access to properties that were removed is revoked. Alternative: *Kirim Ulang Undangan (Resend invitation)* for accounts that are not yet active.

**UC-30 Delete manager** (FR-22) · *[manager] → Hapus (Delete)*
Soft delete: assignments are revoked and active sessions end. The manager's action history is kept.

**UC-31 Choose subscription plan** (FR-23, FR-25) · *Akun → Langganan (Account → Subscription)*
Shows the current status and the available plans (features, price). With an active plan, also show the end date and offer renewal or a plan change. Pick a plan → order summary → confirm → order *Menunggu Pembayaran* → UC-32.

**UC-32 Pay for subscription** (FR-24, FR-25, FR-27) · from a pending order → *Bayar (Pay)*
Opens the payment gateway page (provider: TBD-3). Results:
- *Berhasil* → subscription active, with confirmation;
- *Gagal* or *Kedaluwarsa* → offer to pay again;
- still pending → stays *Menunggu Pembayaran* and can be re-checked from *Langganan*.
  If the gateway is unreachable, show an error; no transaction is created.

### 8.4 Admin

**UC-33 View user accounts** (FR-29) · *Akun Pengguna (User accounts)*
List with name, email, role and status. Search by email, filter by role, open a detail view. Shows "not found" when the search or filter matches nothing.

**UC-34 Edit user account** (FR-29) · *[account] → Ubah (Edit)*
Change name, email (must be unique) and status (*Aktif*/*Nonaktif*). Deactivating an account ends its sessions.

**UC-35 Delete user account** (FR-29) · *[account] → Hapus (Delete)*
Soft delete that ends sessions. Rejected, with the reason shown, if the account is an Owner with a property that has an active lease.

### 8.5 All roles

**UC-37 Manage active sessions** (FR-33, NFR-18) · *Akun → Keamanan → Perangkat Aktif (Account → Security → Active devices)*
List of the user's sessions with device name, platform, login method and last activity; the current device is marked. End the session of one other device, or of all other devices, after confirmation. The current device logs out through the normal logout.

**UC-38 Change password** (FR-33, NFR-11) · *Akun → Keamanan → Ubah Kata Sandi (Account → Security → Change password)*
Fields: current password, new password with a strength meter, confirm new password. One show-password toggle applies to all three. The strength meter is a hint only; the API decides. After a successful change, if the user has other sessions, offer to log out all other devices (*log out others* / *stay logged in*); with no other sessions, skip the prompt.

## 9. API contract

The backend repository (`andinaufal120/niscala-api`) owns the contract. Its OpenAPI document is the source; the app consumes a **Dart client generated from it** and committed to this repo. Regenerate the client to pick up contract changes, and never hand-edit generated code.

Until the generated client exists, the only endpoint is:

| Method | Path      | Purpose                                                   | Used by                                                   |
|--------|-----------|-----------------------------------------------------------|-----------------------------------------------------------|
| `GET`  | `/health` | Confirms the API is up and its database connection works. | Walking skeleton (NKMA-6): the app displays the response. |

The response shape of `/health` is undecided (see U-1 in §10).

## 10. Undecided — do not implement by assumption

When work touches one of these items, stop and raise it in Plan mode. Items that also affect the backend are listed in its `docs/SPEC.md` §10 with the same ID.

| ID    | Item                                                                                                                             | Affects             |
|-------|----------------------------------------------------------------------------------------------------------------------------------|---------------------|
| TBD-2 | Minimum Android version (minSdk). Tracked in NKMA-24.                                                                            | Build config        |
| TBD-3 | Google Play server-side integration: how the backend learns of renewals, cancellations, expiry and refunds (real-time developer notifications endpoint, its authentication, scheduled reconciliation), service account, test environment. | UC-31, UC-32 |
| U-1   | `/health` response shape.                                                                                                        | §9, NKMA-22         |
| U-3   | Complaint description minimum length.                                                                                            | UC-02               |
| U-4   | Invitation and password-reset link handling: how a link opens the app (Android App Links / deep link) and what happens if the app is not installed. | UC-18, UC-20, FR-01, NFR-11 |
| U-5   | Date display format in the UI.                                                                                                   | All dates           |
| U-9   | Error response shape and the list of error codes.                                                                                | §6, §7              |
| U-10  | Wire formats: enum values, JSON field casing, and date/time format. Decided: complaint status *Baru* is `"new"`.                 | §3, §5, §9          |
| U-16  | Complaint category list (the prototype list is placeholder data).                                                                | UC-02, UC-23, UC-36 |
| U-22  | Content of the Manager's restricted dashboard.                                                                                   | UC-22               |

## 11. Changelog

| Date       | Change                                                                                                          | Decided in |
|------------|-----------------------------------------------------------------------------------------------------------------|------------|
| 12-10-2026 | Initial version, derived from requirements baseline v1.1 (11-10-2026).                                          | NKMA-14    |
| 13-10-2026 | Traceability IDs kept out of source and test names; TBD-2 marked open (NKMA-24); `/health` shape points to U-1. | NKMA-14    |
| 13-10-2026 | Accessibility requirements live in `docs/ACCESSIBILITY.md`; §6 rule 9 points to it.                             | NKMA-14    |
| 15-10-2026 | Backend repository named; §1, §3, §4, §5 and §7 blocks shared with it; U-9 and U-10 added.                      | NKMA-14    |
| 15-10-2026 | U-9 partly decided: API messages are English with error codes; the app maps codes to Indonesian.                | NKMA-14    |
| 16-10-2026 | SRS v1.1 revision: Owner-only property writes and per-property bank account; room base rate, dimensions, facilities; rent per lease; complaint status split from classification state, one-step flow, urgency values, handling note, manual classification (UC-36); receipt JPG/PNG up to 5 MB; sessions (UC-37, UC-38); password blocklist; navigation and *Akun*, list defaults, AI disclaimer, money format. U-2 decided; U-10 narrowed; U-16, U-21, U-22 added. | NKMA-96 |
| 17-10-2026 | U-21 decided: rent is per billing cycle; base rate pre-fills monthly leases only. Billing cycle values added to §5. Activation requires 2 to 4 emergency contacts (§7). UC-18 and UC-20 name occupation and emergency contacts. | NKMA-8 |
| 17-10-2026 | Backend decided invitation expiry (U-13) and token format (U-14); neither row is in this file. U-4 extended to password-reset links. No shared block changed. | NKMA-15 |
| 17-10-2026 | Login method values (Google, Kata sandi) added to the §5 shared block. | NKMA-15 |
| 17-10-2026 | Manager account statuses in §5 reduced to *Belum Diaktifkan* and *Aktif*; §7 Manager bullet now says the Owner shares the invitation link, the Manager enters their own email, and an existing Manager account can accept it. | NKMA-7 |
| 17-10-2026 | `Notification` and `NotificationSettings` added to the §3 shared glossary; §4 shared table moves viewing own notifications out of the Tenant-only row and adds a row for viewing own notifications and changing own notification settings (Tenant, Owner, Manager). U-12 decided in the backend (row not in this file). | NKMA-63 |
| 17-10-2026 | `UserAccount` added to the §3 shared glossary. §5 user account statuses now Aktif, Nonaktif (suspended, reversible) and Dihapus (soft-deleted, never reactivated), with a paragraph explaining them. | NKMA-18 |
| 17-10-2026 | Subscription plans Gratis, Basic and Pro with Google Play Billing: §1 bullets updated; `SubscriptionPlan` and `SubscriptionOrder` added to §3 and `Subscription` reworded; §5 adds Subscription, Subscription plan and Subscription billing period vocabularies and the Google Play order status mapping. TBD-3 rewritten; U-11 decided in the backend (row not in this file). | NKMA-17 |
| 18-10-2026 | Session lifetime relaxed: a session ends after 90 days without use or 1 year after the last authentication, instead of a fixed 30 days, so that users are not forced to log in about once a month. | NKMA-15 |
| 18-10-2026 | New complaint classification state *Sedang Diklasifikasi* (`classifying`) in the §5 shared block: the backend saves a complaint first and classifies it afterwards (decided in niscala-api, which also decided U-8 for complaint classification). The app's own use-case text (UC-02, UC-03) still has to be reworded when the screens are built. | NKMA-64 |
