import 'package:dio/dio.dart';

class AuthService {
  // Gunakan 10.0.2.2 jika menggunakan Emulator Android, atau IP asli jika HP fisik
  final String _baseUrl = 'http://127.0.0.1:8000/api';
  final Dio _dio = Dio();

  Future<Response> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/login',
        data: {'email': email, 'password': password},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return response;
    } on DioException catch (e) {
      // Mengambil pesan error dari Laravel
      return e.response!;
    }
  }
}
