import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart'; // Tambahkan ini
import 'screens/auth/login_screen.dart';
import 'screens/guru/dashboard_guru.dart';
import 'screens/admin/dashboard_admin.dart';
import 'screens/guru/add_materi_screen.dart';

void main() async {
  // Wajib inisialisasi GetStorage sebelum runApp
  await GetStorage.init();
  runApp(const SipiaApp());
}

class SipiaApp extends StatelessWidget {
  const SipiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Logika Auto-Login: Cek apakah token sudah ada
    final box = GetStorage();
    String? token = box.read('token');
    String? role = box.read('level_akses');

    // Tentukan halaman awal secara dinamis
    String initialRoute = '/login';
    if (token != null) {
      if (role == 'guru') initialRoute = '/guru-dashboard';
      if (role == 'siswa') initialRoute = '/siswa-dashboard';
      if (role == 'admin') initialRoute = '/admin-dashboard';
    }

    return MaterialApp(
      title: 'SIPI - Sistem Informasi Pembelajaran',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      // Menggunakan rute dinamis hasil pengecekan token
      initialRoute: initialRoute,

      routes: {
        '/login': (context) => const LoginScreen(),

        // Pastikan nama rute di sini SAMA PERSIS dengan yang ada di AuthController
        '/guru-dashboard': (context) => const GuruDashboard(),

        '/admin-dashboard': (context) => const AdminDashboard(),

        '/add-materi': (context) => const AddMateriScreen(), // Daftarkan di sini
      },
    );
  }
}
