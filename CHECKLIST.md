# Production Launch Checklist

This checklist is the release gate for any B2C app built from this repo. Every box should be checked before TestFlight broadening or App Store submission.

## Product Identity

- [ ] Final app name is locked across Xcode, App Store Connect, RevenueCat, analytics, and support docs.
- [ ] Production bundle identifier is set and no longer uses template values.
- [ ] Apple Developer team, certificates, and provisioning profile ownership are confirmed.
- [ ] Marketing version and build number strategy are defined for every release.

## iOS Signing And Capabilities

- [ ] Release target signs successfully with the production team and profile.
- [ ] Push Notifications capability is enabled and `aps-environment` is present in release entitlements.
- [ ] Sign in with Apple capability is enabled if the app offers third-party sign-in.
- [ ] Associated domains, background modes, and any extra capabilities are explicitly reviewed.
- [ ] Dev-only ATS exceptions are removed from Release builds.
- [ ] Privacy manifest is present and matches the shipped SDK surface.

## App Metadata

- [ ] App name, subtitle, keywords, description, and promotional text are ready.
- [ ] Primary category and age rating are set.
- [ ] Support URL, marketing URL, privacy policy URL, and terms URL are live.
- [ ] App Review notes are written with a clear test path for reviewers.
- [ ] Demo credentials or reviewer instructions are ready when login is required.

## App Store Assets

- [ ] 1024x1024 production app icon is final.
- [ ] Required iPhone screenshots are captured for the supported device class.
- [ ] Required iPad screenshots are captured if the app ships on iPad.
- [ ] Screenshot copy matches the actual app behavior and subscription offer.
- [ ] Release notes are drafted for TestFlight and App Store release.

## Subscriptions And Monetization

- [ ] Subscription groups and products exist in App Store Connect.
- [ ] RevenueCat project, products, and entitlements are created via RevenueCat MCP (see docs/APP_STORE.md).
- [ ] RevenueCat webhook is set up using MCP and points to the backend endpoint.
- [ ] RevenueCat products match App Store Connect product ids exactly (MCP enforces this).
- [ ] Intro offers, trial copy, restore purchases, and paywall wording are accurate.
- [ ] Subscription Terms and Privacy links are reachable from the app.
- [ ] `asc validate subscriptions --app <APP_ID>` passes without blocking warnings.

## Backend And Data

- [ ] Supabase production project exists and all migrations are applied.
- [ ] Backups, retention, and restore path are documented.
- [ ] Fly.io production app is deployed and healthy.
- [ ] Production env vars are set for backend and iOS builds.
- [ ] RevenueCat webhook secret is created and managed via MCP, and webhook delivery is verified.
- [ ] CORS allowlist is production-safe and does not rely on localhost defaults.
- [ ] Rate limiting, auth, and logging behave correctly in production.

## Security And Compliance

- [ ] No production or development secrets are committed in the repo or exposed in history.
- [ ] Crash reporting, analytics, and data collection are disclosed correctly.
- [ ] Legal copy matches actual data handling and subscription behavior.
- [ ] Support contact path is staffed for launch week.
- [ ] Rollback and incident response owners are identified.

## Quality Gate

- [ ] Backend CI passes.
- [ ] iOS CI passes.
- [ ] Release build archives successfully.
- [ ] Internal TestFlight testing passes on physical devices.
- [ ] Push notifications are validated on a real device.
- [ ] Subscription purchase, restore, cancel, and grace-period behavior are validated.
- [ ] Offline and reconnect flows are validated for core user actions.

## TestFlight With asc

- [ ] `asc auth login` has been completed with the correct App Store Connect API key.
- [ ] `asc apps list` shows the target app in the active profile.
- [ ] `asc validate testflight --app <APP_ID> --build <BUILD_ID>` passes before inviting testers.
- [ ] `asc publish testflight --app <APP_ID> --ipa <PATH_TO_IPA> --group <GROUP_ID>` is documented or executed for the release.
- [ ] TestFlight feedback, crashes, and build notes are monitored after rollout.

## App Store Submission With asc

- [ ] `asc validate --app <APP_ID> --version <VERSION> --platform IOS --strict` passes.
- [ ] `asc screenshots upload` has been completed for required localizations and device types.
- [ ] `asc app-info`, `asc localizations`, and `asc review` data are complete.
- [ ] `asc submit` or `asc publish appstore` command is prepared with the final build.
- [ ] Release owner is assigned to monitor review status and respond quickly.

## Post-Launch

- [ ] Health checks, logs, analytics, and crash dashboards are monitored during rollout.
- [ ] Subscription webhook events are confirmed in production.
- [ ] First-day support triage channel is active.
- [ ] Rollback decision point and owner are clear if a critical issue appears.
- [ ] A post-launch retro is scheduled.