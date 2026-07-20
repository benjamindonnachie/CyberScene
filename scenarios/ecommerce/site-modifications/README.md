# Offline checkout modification

The simulation used the credited `oretnom23/PHP-eCommerce-Site` application with a small change to `sales.php` so checkout did not require connectivity to PayPal.

The retained implementation replaces the PayPal callback check with `rand(0, 9) > 0`:

- nine outcomes out of ten create a local fake payment identifier beginning `PAYID-FAKE-XQWEDES`, insert the sale and line-item records, clear the cart, and set the normal success message;
- one outcome out of ten skips the sale, leaves the cart unchanged, and redirects to the profile page.

The JMeter checkout journey requests `/sales.php` directly, so the branch models payment success or failure without making a PayPal request.

Apply `offline-paypal-random-outcome.patch` from the root of the upstream application. The patch was verified against upstream commit `59d085a9accbda883ae718c017a4cd77cbdad549`:

```bash
git apply /path/to/offline-paypal-random-outcome.patch
```

The patch contains only the simulation-specific change. It does not redistribute the third-party application.
