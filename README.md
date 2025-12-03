# Toko Ban - Aplikasi Manajemen Penjualan Ban

Aplikasi Flutter untuk manajemen toko ban dengan sistem multi-role (Admin, Karyawan, Pelanggan).

## Fitur Utama

### 🔐 Autentikasi & Role Management
- Login/Register dengan Firebase Authentication
- 3 Role: Admin, Karyawan, Pelanggan
- Approval system untuk user baru

### 👥 Admin
- Dashboard dengan statistik
- Manajemen data ban (CRUD)
- Manajemen karyawan
- Laporan penjualan & stok
- Approval user baru

### 👨‍💼 Karyawan
- Dashboard karyawan
- Tambah & edit data ban
- Konfirmasi pembelian pelanggan
- Laporan stok ban

### 🛒 Pelanggan
- Browse & cari ban
- Keranjang belanja
- Multiple metode pembayaran:
  - Tunai (Cash)
  - QRIS (dengan upload bukti pembayaran)
- Riwayat pembelian

## 💳 Sistem Pembayaran

### Metode Pembayaran

**Tunai (Cash):**
- Pembayaran langsung di toko
- Konfirmasi otomatis oleh karyawan

**QRIS:**
- Scan QR Code yang disediakan
- Upload bukti pembayaran (screenshot/foto)
- Input nama pengirim untuk verifikasi
- Karyawan/Admin verifikasi bukti sebelum menerima pesanan

## 🎨 Animasi

- Splash screen dengan fade animation
- Navigation panel dengan slide & stagger animation
- Dashboard cards dengan fade + scale animation
- Button press feedback dengan scale animation

## 📱 Installation

```bash
# Clone repository
git clone <repository-url>

# Install dependencies
flutter pub get

# Run app
flutter run
```

## 🔧 Tech Stack

- Flutter 3.x
- Firebase Authentication
- Cloud Firestore
- Firebase Storage (untuk bukti pembayaran)
- Image Picker (untuk upload foto/screenshot)

## 📝 Model Data

### Tire (Ban)
- Brand (merk)
- Series (seri)
- Size (ukuran)
- Price (harga)
- Stock (stok)

### Sale (Penjualan)
- Invoice Number
- Customer Name
- Date
- Total
- Items (list ban yang dibeli)
- Status (pending/diproses/selesai/ditolak)
- Payment Method (tunai/qris)
- Sender Name (untuk QRIS)
- Payment Proof URL (bukti pembayaran untuk QRIS)

## 📧 Contact

GD Mitra - Toko Ban Mobil
