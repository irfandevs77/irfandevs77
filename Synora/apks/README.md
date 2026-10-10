# Synora APK releases

Copy each Android APK into this folder, for example:

- `Synora-v1.0.0.apk`
- `Synora-v1.1.0.apk`

The Firebase Hosting Spark plan blocks standalone APK uploads. The predeploy
step builds the Flutter web app, puts each APK into a ZIP bundle in the Hosting
output, and generates the version list automatically. Visitors download the
ZIP, extract it, and open the APK on their Android device. Deploy Hosting to
publish new downloads:

```powershell
firebase deploy --only hosting --project irfandevs77-d9520
```

The website offers ZIP downloads because Hosting does not serve executable APK
files on the Spark plan. Visitors must extract the ZIP, then open the APK and
approve installation on Android; a website cannot install an app silently.
