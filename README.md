# Gambaran Umum
MONOCHROME merupakan aplikasi toko digital berbasis Android yang dikembangkan untuk menyediakan platform penjualan berbagai produk digital, seperti template, preset, dan file digital lainnya.

Aplikasi ini dirancang untuk memberikan pengalaman berbelanja yang praktis, terstruktur, dan mudah digunakan. Pengguna dapat menjelajahi katalog produk, melihat detail produk, menambahkan produk ke keranjang, melakukan checkout, serta memantau status pesanan melalui satu aplikasi.

MONOCHROME menggabungkan proses pembelian digital dengan sistem konfirmasi pembayaran melalui WhatsApp dan penyimpanan data transaksi menggunakan database terpusat.

# Pengembang
Dimas Adji Yoga Saputra
230103221
Universitas Duta Bangsa

## Fitur utama
1. User Authentication
Registrasi dan login pengguna menggunakan akun yang tersimpan di database.

2. Product Catalog
Menampilkan daftar produk digital yang tersedia.

3. Product Detail
Menampilkan informasi dan harga produk yang dipilih.

4. Shopping Cart
Menambahkan produk ke keranjang, mengatur kuantitas, dan menghapus produk.

5. Checkout
Menampilkan ringkasan pesanan dan total harga sebelum konfirmasi.

6. Order Management
Menyimpan data pesanan ke database Supabase.

7. WhatsApp Payment Confirmation
Mengarahkan pengguna ke WhatsApp setelah pesanan dikonfirmasi untuk proses pembayaran.

8. Order History
Menampilkan riwayat pesanan dan memungkinkan pengguna membuka kembali halaman pembayaran pesanan.

## Alur pengguna utama
- Customer
Membuka aplikasi MONOCHROME.
Melakukan registrasi atau login.
Melihat katalog produk.
Memilih produk dan melihat detailnya.
Menambahkan produk ke keranjang.
Mengatur isi keranjang.
Melakukan checkout dan memeriksa ringkasan pesanan.
Mengonfirmasi pesanan.
Data pesanan disimpan ke Supabase.
Aplikasi membuka WhatsApp untuk konfirmasi pembayaran.
Customer dapat melihat pesanan melalui Order History dan membuka kembali halaman pembayaran.

- Admin
Menerima informasi pesanan dari customer.
Memeriksa detail pesanan dan nominal pembayaran.
Memeriksa konfirmasi serta bukti pembayaran.
Melakukan klarifikasi jika pembayaran belum sesuai.
Memproses pesanan setelah pembayaran dinyatakan valid.
Menyiapkan produk digital sesuai pesanan.
Mengirimkan produk kepada customer.
Menyelesaikan proses pemesanan.

## Batasan pengujian
- Customer
No.	Area Pengujian	Skenario
1	Registrasi	Mengisi data akun dan validasi input
2	Login	Memasukkan email dan password
3	Product Catalog	Menampilkan daftar produk
4	Product Detail	Membuka detail produk
5	Shopping Cart	Menambah, mengurangi, dan menghapus produk
6	Checkout	Memeriksa ringkasan dan total pesanan
7	Order Submission	Menyimpan pesanan ke Supabase
8	WhatsApp	Membuka WhatsApp setelah konfirmasi pesanan
9	Order History	Menampilkan pesanan yang tersimpan
10	Payment Page	Membuka kembali halaman pembayaran dari riwayat pesanan

- Admin
1   Menerima informasi pesanan melalui WhatsApp.
2   Memeriksa kesesuaian detail dan nominal pesanan.
3   Memeriksa konfirmasi pembayaran.
4   Menyiapkan dan mengirim produk digital.

- Autentikasi
1   Sistem autentikasi menggunakan tabel users pada database Supabase.
2   Proses registrasi dan login menggunakan mekanisme yang dikembangkan di dalam aplikasi.
3   Supabase Auth tidak digunakan dalam tahap pengembangan ini.
4   Pengujian autentikasi dibatasi pada fungsi registrasi dan login sesuai implementasi yang tersedia.
5   Integrasi autentikasi eksternal dan pengujian fitur Supabase Auth tidak termasuk dalam ruang lingkup pengujian.

## User Acceptance Testing (UAT)
https://docs.google.com/spreadsheets/d/1xig_gM2iNPv7-fRPRLmvSt6vJ5l7xsoN/edit?usp=drive_link&ouid=114986319142893396779&rtpof=true&sd=true

## Struktur Repository

```text
Monochrome/
├── maestro/
│   └── flows/
│       ├── 01_home_screen.yaml
│       ├── 02_category_filter.yaml
│       ├── 03_search_input.yaml
│       ├── 04_sign_in_validation.yaml
│       └── 05_registration_validation.yaml
├── lib/
│   ├── config/
│   │   └── supabase_config.dart
│   ├── data/
│   │   └── sample_products.dart
│   ├── models/
│   │   ├── cart_item.dart
│   │   ├── order.dart
│   │   └── product.dart
│   ├── screens/
│   │   ├── admin_dashboard_screen.dart
│   │   ├── auth_gate.dart
│   │   ├── cart_screen.dart
│   │   ├── checkout_screen.dart
│   │   ├── home_screen.dart
│   │   ├── library_screen.dart
│   │   ├── login_screen.dart
│   │   ├── order_history_screen.dart
│   │   ├── payment_screen.dart
│   │   ├── product_detail_screen.dart
│   │   └── register_screen.dart
│   ├── services/
│   │   ├── app_session.dart
│   │   ├── order_service.dart
│   │   ├── product_service.dart
│   │   └── storage_service.dart
│   └── wigets/
│       ├── bottom_nav.dart
│       ├── cart_item_tile.dart
│       ├── category_chip.dart
│       ├── category_filter.dart
│       ├── floating_cart_button.dart
│       └── product_card.dart
├── supabase/
│   └── supabase.aql
├── pubspec.yaml
└── README.md
```

## Persiapan dan Penggunaan Aplikasi MONOCHROME

### Perangkat dan perangkat lunak
- Komputer dengan sistem operasi Windows.
- Android Studio.
- Flutter SDK dan Dart.
- Android SDK serta emulator atau perangkat Android fisik.
- Koneksi internet.
- Akun Supabase untuk menyediakan database.
- WhatsApp untuk proses konfirmasi pesanan.

### Menyiapkan database Supabase
- Buka Supabase dan login ke akun.
- Buat project baru untuk MONOCHROME.
- Tentukan nama project, password database, dan region.
- Setelah project selesai dibuat, buka menu SQL Editor.
- Jalankan SQL untuk membuat tabel database yang diperlukan aplikasi.repository.

### Menghubungkan aplikasi dengan Supabase
- Buka project Flutter MONOCHROME.
- Cari file Dart yang berfungsi sebagai penghubung Supabase.
- Ganti URL Supabase lama dengan URL project yang baru.
- Ganti Supabase Anon/Publishable Key dengan key dari project yang sama.
- Simpan perubahan dan pastikan konfigurasi mengarah ke project database yang benar.

### Menjalankan aplikasi
- Buka folder project MONOCHROME melalui Android Studio.
- Pastikan Flutter SDK dan Android SDK sudah terdeteksi.
- Hubungkan perangkat Android atau jalankan emulator.
- Jalankan perintah berikut melalui terminal pada direktori project:

```powershell
flutter pub
flutter run
```
akses admin hanya bisa diberikan melalui supabase

### Membuat APK
```powershell
flutter build apk --release
```
akses admin hanya bisa diberikan melalui supabase

## Pengujian Maestro

Flow Maestro disimpan pada `Monochrome/.maestro/flows/`. Enam flow yang tersedia mencakup pembukaan aplikasi, login, validasi, transaksi pesanan, dan navigasi.

| Flow | Tujuan |
|---|---|
| `01_home_screen.yaml` | Membuka aplikasi dan memeriksa elemen halaman login |
| `02_category_filter.yaml` | Memfilter produk berdasarkan kategori |
| `03_search_input.yaml` | Menggunakan fitur pencarian |
| `04_sign_in_validation.yaml` | Memeriksa validasi login |
| `05_registration_validation.yaml` | Memeriksa validasi pendaftaran |

### Menjalankan flow

Gunakan **Maestro Studio Desktop** (bukan Maestro CLI) untuk membuka dan menjalankan flow YAML. Flow berada di folder `Monochrome/.maestro/flows/`.

## Video Penjelasan dan File APK

**Tautan video**

**Tentang aplikasi** https://drive.google.com/file/d/1eEgulwuJrkG49qvyq9TAZOLfERavi957/view?usp=drive_link

**Pengujian APK** https://drive.google.com/file/d/16LlVEDl36mw_rHUhepciBjFZqMawZc29/view?usp=drive_link

**Tautan APK:** https://drive.google.com/file/d/18yUvaXsbJjLMPIH3CiAvfOPn2Z3ySgUL/view?usp=drive_link

## Repository

**GitHub:** https://github.com/iwobako/Monochrome
