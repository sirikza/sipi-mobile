import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();
  final _storage = GetStorage();

  Future<void> loginUser(
    BuildContext context,
    String email,
    String password,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final response = await _authService.login(email, password);

    if (context.mounted) Navigator.pop(context);

    // DEBUG: Cek isi response di console
    print("Response Data: ${response.data}");

    if (response.statusCode == 200 && response.data['success'] == true) {
      String token = response.data['token'];
      // Gunakan toString().toLowerCase() untuk menghindari error case-sensitive (GURU vs guru)
      String levelAkses = response.data['data']['level_akses']
          .toString()
          .toLowerCase();

      _storage.write('token', token);
      _storage.write('level_akses', levelAkses);
      _storage.write('user_name', response.data['data']['name']);

      if (context.mounted) {
        if (levelAkses == 'guru') {
          // Gunakan pushNamedAndRemoveUntil agar user tidak bisa tekan 'back' ke login
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/guru-dashboard',
            (route) => false,
          );
        } else if (levelAkses == 'admin') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin-dashboard',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Level akses tidak dikenali')),
          );
        }
      }
    } else {
      String message = response.data['message'] ?? 'Email atau Password salah';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }
}
