# App Store Submission Guide

Use this guide for the first live submission and every major release.

## 1. Authenticate asc

```bash
asc auth login
asc auth status
```

Use the correct profile before mutating live metadata.

## 2. Confirm App, Version, And Build

```bash
asc apps list
asc versions list --app <APP_ID>
asc builds list --app <APP_ID>
```

Before submission:

- App record exists.
- The intended App Store version exists or is created.
- A processed build is attached to the version.

## 3. Metadata And Localization

Populate or verify:

- App name
- Subtitle
- Description
- Keywords
- Support URL
- Marketing URL
- Privacy policy URL
- Promotional text
- Age rating
- Category

Common command groups:

```bash
asc app-info --help
asc localizations --help
asc age-rating --help
asc categories --help
asc review --help
```

## 4. Screenshots

Inspect supported sizes:

```bash
asc screenshots sizes
```

Upload screenshots after metadata localizations exist:

```bash
asc screenshots upload --version-localization <LOCALIZATION_ID> --path ./screenshots/iphone --device-type IPHONE_65
asc screenshots upload --version-localization <LOCALIZATION_ID> --path ./screenshots/ipad --device-type IPAD_PRO_3GEN_129
```

Minimum expectations for this repo:

- iPhone 6.5-inch screenshot set for the primary locale.
- iPad set if the shipped app supports iPad.
- Screenshots match the actual paywall, tasks flow, and branding.


## 5. Subscriptions And In-App Purchases

**Automate RevenueCat setup with RevenueCat MCP.**

1. Use RevenueCat MCP to create the project, products, entitlements, and webhook:
	- Project: Create a new RevenueCat project for this app.
	- Products: Define all subscription products (monthly, yearly, lifetime) using MCP, ensuring product IDs match App Store Connect exactly.
	- Entitlements: Set up entitlements (e.g., "Pro") via MCP.
	- Webhook: Use MCP to configure the webhook to point to your backend endpoint (`/auth/webhook/revenuecat`).
	- Webhook secret: Store the generated secret in your backend and Fly.io secrets.

2. Do **not** create products or entitlements manually in the RevenueCat dashboard—let MCP manage all resources for consistency and agent-driven automation.

3. After MCP setup, verify:
	- RevenueCat products and entitlements match App Store Connect product IDs.
	- The webhook is active and delivers events to your backend.
	- The webhook secret is set and validated in production.

Useful command groups:

```bash
asc subscriptions --help
asc iap --help
asc validate subscriptions --app <APP_ID>
```

Checklist:

- [ ] Subscription group exists in App Store Connect.
- [ ] RevenueCat project, products, and entitlements are created via MCP.
- [ ] Product IDs match between App Store Connect and RevenueCat (enforced by MCP).
- [ ] Webhook is configured via MCP and secret is set in backend.
- [ ] Trial wording matches App Store Connect setup.
- [ ] Restore purchases works.
- [ ] Terms and privacy links are available in-app and in App Store metadata.

## 6. Review Details

Prepare the App Review payload:

- Contact first name and last name
- Contact email and phone
- Demo account or review bypass instructions
- Notes for reviewers about auth, subscriptions, notifications, or gated features
- Encryption declaration status

Useful command groups:

```bash
asc review --help
asc encryption --help
```

## 7. Validate Before Submission

Run a strict readiness check:

```bash
asc validate --app <APP_ID> --version <VERSION> --platform IOS --strict
```

Do not submit until this succeeds.

## 8. Submit The Build

If you already uploaded the IPA and attached the build, use submit or publish.

```bash
asc submit --help
asc publish appstore --app <APP_ID> --ipa <PATH_TO_IPA> --version <VERSION> --submit --confirm
```

If you prefer a staged manual review step, upload first, validate, and then submit separately.

## 9. After Submission

- Monitor review status in App Store Connect.
- Watch for reviewer messages and respond quickly.
- Keep the release owner available for the first 24 hours after approval.
- Prepare a hotfix branch and rollback plan if a blocking issue appears.