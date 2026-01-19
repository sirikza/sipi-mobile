import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

class UserService {
  final Dio _dio = Dio();
  // Gunakan 127.0.0.1 untuk emulator, atau IP PC jika menggunakan HP fisik
  final String _baseUrl = "http://127.0.0.1:8000/api";
  final _storage = GetStorage();

  // Helper untuk mendapatkan Options (Header dengan Token)
  Options _getOptions() {
    String? token = _storage.read('token');
    return Options(
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
  }

  // Get Semua User
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/users',
        options: _getOptions(),
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Gagal memuat data users');
      }
    } on DioException catch (e) {
      throw Exception('Kesalahan koneksi: ${e.message}');
    }
  }

  // Tambah User Baru
  Future<bool> storeUser(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        '$_baseUrl/users',
        data: data,
        options: _getOptions(),
      );
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      print("Error storeUser: $e");
      return false;
    }
  }

  // Update User
  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put(
        '$_baseUrl/users/$id',
        data: data,
        options: _getOptions(),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Error updateUser: $e");
      return false;
    }
  }

  // Delete User
  Future<bool> deleteUser(int id) async {
    try {
      final res = await _dio.delete(
        '$_baseUrl/users/$id',
        options: _getOptions(),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("Error deleteUser: $e");
      return false;
    }
  }
}
