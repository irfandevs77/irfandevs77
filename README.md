# irfandevs77

Hi, I'm Irfan 👋

Student Developer | Technology • AI • Computer Science

A responsive Flutter portfolio with Home, Skills, Projects, and Social
navigation. The About section is below the home-page content, and Social groups
GitHub, Instagram, WhatsApp, and the contact form.

## Run

```powershell
flutter run -d chrome
```

The Firebase web app configuration for `irfandevs77-d9520` is already set up.
The GitHub page reads public repositories live from Firestore. Other website
pages remain available if a Firestore query fails; the GitHub page displays the
connection error rather than hiding it.
The home-page portrait and local profile-avatar fallback use
`assets/images/dp.png`; replace that asset to update the displayed photo.
Route changes use a shared fade-and-slide transition, and entrance animations
respect the device's reduced-motion setting.

The public repository query reads only documents in `repositories` where
`isPublic` is `true`. Firestore rules are deployed from `firestore.rules`:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project irfandevs77-d9520
```

## Contact workflow

The contact form validates name, email, and message before opening the visitor's
email application with a prefilled message to `irfandevs77@gmail.com`. The
site does not claim the message was sent, and it does not store messages in
Firestore.

## Synora APK releases

Open Synora from the Projects page to see its Android releases and GitHub
source link. Put each APK directly in `Synora/apks`, using versioned filenames
such as `Synora-v1.0.0.apk`. Firebase Hosting Spark blocks standalone APK
uploads, so the deploy hook packages each APK into a ZIP; visitors extract the
downloaded ZIP on Android before installing. Deploy Hosting to publish the site
and sync releases:

```powershell
firebase deploy --only hosting --project irfandevs77-d9520
```

The Hosting predeploy hook builds the Flutter web app, creates ZIP downloads,
and generates the version catalog automatically. Installation must be approved
on the Android device.

## Admin

The desktop/mobile header Login button opens `/login`, where visitors can sign
in or create a regular Firebase email/password account. Regular accounts return
to the public website. Admin accounts with the `admin` custom claim are
routed to `/admin`; `/admin/login` only accepts users with that claim. Firestore
authorization remains enforced by the existing rules.

### Granting admin access

The admin claim must be a boolean Firebase Authentication custom claim
(`admin: true`), not a Firestore profile field or a `role: "admin"` claim. To
grant it to an existing user, install the Admin SDK dependency:

```powershell
npm install
```

Create a service-account key for project `irfandevs77-d9520` in Firebase
Console → Project settings → Service accounts. Store the downloaded JSON
outside this repository. In PowerShell, point the credential environment
variable at that file and run the script with the user's Authentication UID:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\secure\serviceAccountKey.json"
npm run set-admin -- "SVPSKsMNgteROsOxVyIHB3NGbqT2"
```

The script verifies the account in the configured project and preserves its
existing custom claims while adding `admin: true`. Never commit or share the
service-account key. After success, sign out and sign back in to the website,
then open `/admin`.

## Screens

- `lib/screens/home_page.dart`: hero, social links, and featured intro.
- `lib/screens/about_page.dart`: biography and journey.
- `lib/screens/skills_page.dart`: categorized technology cards and skill bars.
- `lib/screens/projects_page.dart`: responsive project cards and source links;
  the Synora card opens its APK releases and source-code page.
- `lib/screens/synora_details_page.dart`: APK version downloads and GitHub link.
- `lib/screens/github_page.dart`: profile card and live Firestore repositories.
- `lib/screens/instagram_page.dart`: social profile link and inspiration grid.
- `lib/screens/contact_page.dart`: validated contact form that opens a
  pre-addressed email draft.

Project descriptions and skill-bar values are editable presentation content;
review them for accuracy before publishing.

## Verification

```powershell
flutter analyze
flutter test
flutter build web
```

### Interests

- Software Development
- Artificial Intelligence
- Computer Science
- Automation
- App Development

### Current Projects

- **Synora** — A modern messaging and social platform
- **AI Assistant** — Exploring voice-controlled computer automation

### Goal

> Learn. Build. Improve. Repeat.

📫 Instagram: [@irfandevs77](https://www.instagram.com/irfandevs77/)
