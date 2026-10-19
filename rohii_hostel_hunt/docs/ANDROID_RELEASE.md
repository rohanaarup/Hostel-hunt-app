# Android release: one-time setup and every release

The release build reads its secrets and its application id from environment variables. Nothing secret is in git.
Backend release, backups and rollback are in `RELEASE.md` in the backend repository.

## What the build does now

| | Before | Now |
|---|---|---|
| Plain HTTP | Allowed in every build | Allowed only in debug and profile builds (`src/debug` and `src/profile` manifests). A release build is HTTPS only. |
| Signing | Debug key | Your upload key, from `HH_KEYSTORE_PATH` and friends. A **Play bundle cannot be built** without it. A release APK without it is still debug-signed, so `flutter run --release` works on your own phone (never upload that). |
| Application id | `com.example.rohii_hostel_hunt` | `HH_APPLICATION_ID`. A **Play bundle cannot be built** while it still starts with `com.example`. |
| Shrinking | None | R8 code shrinking and resource shrinking on, with `proguard-rules.pro` (Razorpay keep rules). |
| App name | `rohii_hostel_hunt` | `Hostel Hunt` |
| Backup of app data | Allowed (saved logins could be restored on another phone) | Off |
| Links to UPI apps and websites | `canLaunchUrl` reported "no app" on Android 11+ because the manifest did not declare them | `upi` and `https` declared under `<queries>` |
| Logos | 4.7 MB of images | 2.0 MB (resized to the largest size the app draws, same look) |

The code's package name (`namespace`) stays `com.example.rohii_hostel_hunt`. That is fine: it does not have to match the
application id, so choosing the id needs no code change.

## One-time setup (you)

1. **Choose the application id.** Reverse-domain style, lowercase, letters and digits, at least two parts, for example
   `app.<yourname>.hostelhunt`. You do not need to own a domain. It **cannot change after the first upload to Play**, and
   Play only tells you whether it is free when you create the app. `com.example...` is refused by Play.
2. **Make the upload keystore**, outside both repositories (for example `C:\Users\<you>\hh-keys\`):
   ```
   & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -storetype PKCS12 `
     -keystore C:\Users\<you>\hh-keys\upload-keystore.p12 -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```
   It asks for the passwords and your details. **You** type the passwords; nobody else needs to see them.
   Keep the file and the passwords in a password manager and make **two copies of the file in different places**.
   If you lose them you can ask Play to reset the upload key, but it takes days. Never put either in git or chat.
3. **Turn on Play App Signing** when you create the app in Play Console (it is the default for new apps). Google keeps
   the real app-signing key; the keystore above is only your upload key, so a lost upload key is recoverable.
4. Set these in PowerShell for the window you build in (they disappear when you close it):
   ```
   $env:HH_APPLICATION_ID    = "<your id>"
   $env:HH_KEYSTORE_PATH     = "C:\Users\<you>\hh-keys\upload-keystore.p12"
   $env:HH_KEYSTORE_PASSWORD = "<store password>"
   $env:HH_KEY_ALIAS         = "upload"
   $env:HH_KEY_PASSWORD      = "<key password>"
   ```

## Build a release

```
cd "C:\PROJECTS DEV\HH CORE\ROHIIs_hostel_hunt\rohii_hostel_hunt"
flutter test
flutter build appbundle --release `
  --dart-define=API_BASE_URL=https://<the production API host>/api/v1 `
  --dart-define=SENTRY_DSN=<dsn, once Sentry exists> --dart-define=SENTRY_RELEASE=<git short hash>
```
The file is `build\app\outputs\bundle\release\app-release.aab`. Raise the number after the `+` in `pubspec.yaml`
(`version: 1.0.0+N`) before every upload. The default API host inside the app is the production host, so
`API_BASE_URL` is only needed for another server (a staging build for testers, for example).

**The production backend still runs old code (KNOWN_GAPS X-01). Do not publish an app that points at it until production has been deployed.**

If the build says "Cannot build a Play bundle", it lists what is missing.

### Size (measured on 2026-10-19 with a throwaway key and test id)

The bundle is 59.2 MB, but a phone downloads far less: 29.2 MB of it is debug symbols that are not delivered to users, and Play
sends only the phone's own processor type (about 9 MB of native code for each of arm64, armv7 and x86_64 inside the bundle),
plus about 3.3 MB of assets and 1.3 MB of code. Expect a download of roughly 14 to 15 MB (derived from the bundle's contents,
not measured on Play).

Warnings in that build: Flutter's notice that three plugins apply the Kotlin plugin in a way a future Flutter will reject
(KNOWN_GAPS F2-06), and Java "source value 8 is obsolete" notices from plugins. None came from this project's code.
R8 finished without a missing-class error. **Whether shrinking broke anything at run time is not proven: run the checks
below on a phone with the bundle installed from Play's internal testing.**

## Play Console (only you can do these)

1. Create a Google Play developer account (identity verification; the one-time registration fee is on Google's page,
   please read the current amount there).
2. **Read Google's current rules for new accounts before planning the date.** I recall a closed-testing requirement for
   new personal accounts before production access; I could not verify it from here.
3. Create the app with your application id. Upload `app-release.aab` to **Internal testing** first.
4. Store listing: name, short and full description, a 512 x 512 icon, a 1024 x 500 feature graphic, phone screenshots.
5. **Privacy policy URL.** Play requires one, as the app collects email or phone, name and profile photos. A page on
   GitHub Pages is free and needs no domain.
6. **Data safety form.** Declare what the app collects: name, email and phone (account), profile photo (optional), booking
   details, payment is handled by Razorpay (the app does not hold card details), and the microphone for voice search
   (permission `RECORD_AUDIO`).
7. Content rating questionnaire, target audience, ads declaration (none).
8. Roll out to production as a **staged rollout**.

## Checks on a phone with the Play build (internal testing)

* Opens, shows the Hostel Hunt name, and the list loads (not a blank or crash: that would mean shrinking removed something).
* Voice search works (microphone permission prompt appears).
* Pay with a Razorpay TEST payment: the UPI app opens (this was likely broken by missing `<queries>`), and the card sheet opens.
* WhatsApp button on the booking screen opens WhatsApp.
* Log in, restart the app, still logged in; Log Out works.
* Plain `http://` addresses do not work (release is HTTPS only), which is the intended behaviour.

## Not done

* **Launcher icon.** It is still Flutter's default. `images/logos/logo_icon_dark_bg.png` looks suitable; say so and it
  can be turned into the icon files, or send your own artwork.
* **No "update required" screen**, so an old app cannot be forced to update.
* **iOS** was not looked at.
* The Play listing assets, privacy policy page and the Play account (above).
