# lid v1.2.0 (Flutter: Android + Web)

Produk Misyi. Satu kode untuk APK dan web. Data lokal (shared_preferences + Hive/IndexedDB).

## Build cepat (sudah ada Flutter di komputer)
    bash tool/build_all.sh
Hasil: `build/app/outputs/flutter-apk/app-release.apk` dan folder `build/web`.

Atau manual:
    bash tool/setup.sh           # membuat android/ web/, izin, ikon (sekali saja)
    flutter build apk --release
    flutter build web --release --pwa-strategy=none

## Build tanpa Flutter di perangkat (HP/Termux)
Upload folder ini ke repo GitHub, lalu buka tab Actions -> "build-lid" -> Run workflow.
APK dan web otomatis jadi di bagian Artifacts (lid-apk, lid-web).

## Catatan web
- Kamera dan mikrofon di web butuh HTTPS (localhost juga boleh). Upload isi `build/web` ke hosting HTTPS mana pun.
- Peramban lid di web menampilkan kartu tautan lalu membuka tab baru (banyak situs memblokir iframe). Di Android, link dibuka di WebView dalam aplikasi.
- Data web tersimpan di peramban (tidak berpindah antar perangkat).

## Build lewat CircleCI
Repo sudah berisi `.circleci/config.yml` (image Flutter + Android SDK). Hubungkan repo ke CircleCI, jalankan pipeline `build-lid`;
`lid.apk` dan `lid-web.tar.gz` muncul di tab Artifacts.

## Link di dalam aplikasi
Semua link (post, komentar, bio) selalu dibuka di peramban lid, tanpa pindah aplikasi/tab.
Android: WebView penuh (tombol kembali, maju, muat ulang, salin, bagikan). Web: bingkai tertanam;
situs yang melarang ditanam (mis. beberapa sosmed/bank) akan tampil kosong, itu batasan peramban, bukan bug.
Link `lid://post/...` membuka postingan langsung.
