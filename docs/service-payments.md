# Admin workspace and service payments

The `/Manage` dashboard provides a responsive sidebar for overview, dispatch, invoices, services, products, users, approvals and settings. Administration routes remain restricted to the Admin role. The mobile menu supports keyboard navigation, Escape and an overlay close button.

## Record a service payment

1. A customer creates a service request through the existing dispatch workflow.
2. Open **Payments & invoices**, select the request and enter the agreed total and notes. Visit fees are not automatically charged or added twice. Invoice currency is copied from business settings when issued.
3. After money is received, open the invoice and record the amount and method. Supported records are Cash, EVC Plus, ZAAD, Sahal, bank transfer and externally received card payments. A transaction reference is required except for cash. Enter a receipt/transaction identifier, never card details.
4. Partial payments reduce the balance. The invoice becomes Paid when receipts equal the total. Each entry creates a numbered receipt and audit event. Repeated submission of the same payment key does not duplicate it; conflicting amounts and concurrent overpayments are rejected.
5. Customers can open **Invoice & payments** from request tracking on web and Flutter. Only the customer and administrators can access the invoice; assigned professionals and other users cannot view this financial record.

Invoice totals and received payment records are immutable. An invoice without payments can be voided; paid or partially paid invoices cannot be voided. The initial version does not support refunds, adjustments or reissuing a voided request invoice. Do not record a refund as a negative payment.

## Gateway status

This implementation records received payments. It does not transfer funds, initiate card charges or verify a mobile-money transaction automatically. It does not store card data, merchant API secrets or mobile-money PINs. Live EVC Plus/ZAAD/Sahal and card checkout need the business's provider accounts, API credentials, provider-specific callback verification and reconciliation before enabling transactions. No payment is marked received by a customer action or a browser redirect.

## Data and validation

`ServicePayments` creates the invoice and payment tables with EF Core. One invoice is allowed per request; amounts use decimal(12,2), and the service rejects sub-cent values and overpayments. MySQL row locks serialize changes on an invoice. Historical invoices retain their currency when branding/settings change; totals are never combined across currencies.

`tests/payments_test.py` runs against a disposable, demo-seeded MySQL database and covers access control, CSRF protection, duplicate invoices, idempotency, concurrent overpayments, partial and full receipts, void rules, currency preservation and all six supported record methods. Existing dispatch and configuration tests cover the shared layout/navigation changes.
