# lid v0.3.1 (Flutter, Android)
1. Install Flutter (>=3.19). Di folder kosong: `flutter create --org id.misyi --project-name lid .`
2. Salin `lib/` dan `pubspec.yaml` dari proyek ini (timpa), lalu `flutter pub get`
3. Android: `android/app/build.gradle` -> `minSdkVersion 24`.
   `android/app/src/main/AndroidManifest.xml` -> tambahkan isi `android_manifest/permissions.xml` sebelum <application>.
4. `flutter run` atau `flutter build apk --release`
