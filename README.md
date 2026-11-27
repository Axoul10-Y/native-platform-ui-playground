# Native Platform UI Playground

A small Flutter playground for the documented `native_platform_ui` components.

## Included
- Native UIKit button (`NativeUi.button`)
- Native UISwitch (`NativeUi.switchWidget`)
- Native glass containers (`NativeUi.glassContainer`)
- Native SF Symbol rendering (`NativeUi.sfSymbol`)
- Native iOS alert (`showIosAlert`)
- Native iOS popover menu (`showIosPopover`)
- Native bottom navigation (`NativeUi.bottomNavigationBar`)
- Light / dark app appearance toggle

## Important
- The package requires iOS 15+.
- Liquid Glass is used when available (iOS 26+).
- Web is not supported by this package.
- This is a starter playground, not a full catalog of every iOS system control.
- Build and run it on an iOS Simulator to inspect the native implementations.

## Create the iOS project files (Windows)
From this folder, run:

```powershell
flutter create --platforms=ios .
flutter pub get
```

This generates the platform scaffolding. You can edit Dart code on Windows, but a local iOS build requires macOS + Xcode. Revyl's remote build flow can build the Flutter iOS simulator app in its cloud environment if the account/build profile supports it.

## Revyl cloud build
Install and authenticate the Revyl CLI using the current instructions:
https://docs.revyl.com/install/

Then:

```bash
revyl auth login
revyl init
```

Review `.revyl/config.yaml`, especially the iOS build profile and app ID, then validate:

```bash
revyl config validate
```

Build and upload:

```bash
revyl build --platform ios --build-profile development
```

The exact profile name may differ depending on the generated config. Use the profile that contains the iOS recipe.

When the build succeeds, start a session from Revyl's dashboard (Sessions > Start session) and select the uploaded app/build. Revyl runs the simulator session in the browser.

## If building outside Revyl
The iOS artifact required by Revyl is a simulator `.app` (or zipped `.app`), not an `.ipa`.
