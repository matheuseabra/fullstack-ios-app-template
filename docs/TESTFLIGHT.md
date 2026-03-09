# TestFlight Guide

Use this guide for internal and external beta distribution.

## Prerequisites

- Production bundle id is final.
- Signing, certificates, and provisioning profiles are valid.
- Release build archives locally.
- Privacy policy, terms, support URL, and review notes exist.

## 1. Authenticate asc

Initialize or update the App Store Connect API key profile:

```bash
asc auth login
asc auth status
```

If you use repo-local config, keep it outside source control unless it contains no secrets.

## 2. Confirm App Store Connect App State

```bash
asc apps list
asc builds list --app <APP_ID>
```

Verify the target app id, bundle id, and latest processed builds.

## 3. Archive The App

From Xcode Organizer or the command line, create the release archive and export an IPA.

Recommended checks before upload:

- Release scheme selected.
- Production environment values injected.
- Release entitlements contain push and any required capabilities.
- Dev-only ATS exceptions are absent from the shipped build.

## 4. Upload To TestFlight

Preferred asc workflow:

```bash
asc publish testflight --app <APP_ID> --ipa <PATH_TO_IPA> --group <GROUP_ID>
```

Useful follow-up commands:

```bash
asc builds list --app <APP_ID>
asc testflight groups list --app <APP_ID>
asc beta-build-localizations list --build <BUILD_ID>
```

## 5. Validate Readiness Before Inviting Testers

```bash
asc validate testflight --app <APP_ID> --build <BUILD_ID>
```

Do not invite testers until this passes and the processed build is visible.

## 6. Internal Test Plan

Run this on at least one physical iPhone and one additional device class if supported.

- [ ] Install the TestFlight build cleanly.
- [ ] Complete sign-in with every shipped auth provider.
- [ ] Complete onboarding and verify gating logic.
- [ ] Reach the paywall and verify the displayed plans match the products and entitlements created via RevenueCat MCP.
- [ ] Purchase and restore using sandbox accounts.
- [ ] Create, edit, delete, and sync core objects.
- [ ] Validate push notifications on a real device.
- [ ] Verify support, privacy, and terms links open successfully.
- [ ] Confirm analytics and backend logs receive the expected events.

## 7. External Testing

Before moving to external testers:

- [ ] Internal testers signed off on blocking issues.
- [ ] Crash-free baseline is acceptable.
- [ ] Beta notes are written.
- [ ] Support channel for tester feedback is staffed.

Useful commands:

```bash
asc testflight groups list --app <APP_ID>
asc feedback list --app <APP_ID>
asc crashes list --app <APP_ID>
```

## 8. Exit Criteria Before App Store Submission

- [ ] No release-blocking crash or purchase issues remain.
- [ ] TestFlight feedback has been triaged.
- [ ] Backend production environment is stable.
- [ ] App Store metadata and screenshots are ready.