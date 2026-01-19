import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MateriService {
  final Dio _dio = Dio();
  // GUNAKAN 10.0.2.2 jika pakai Emulator Android, gunakan IP PC jika pakai HP fisik
  final String _baseUrl = 'http://127.0.0.1:8000/api';
  final _storage = GetStorage();

  Options _getOptions() {
    String? token = _storage.read('token');
    return Options(
      headers: {
        "Authorization": "Bearer $token",
        "Accept":
            "application/json", // Penting agar Laravel mengirim error dalam bentuk JSON
      },
    );
  }

  // PERBAIKAN: Ubah return type menjadi Future<List<dynamic>>
  Future<List<dynamic>> getMateri() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/materi',
        options: _getOptions(),
      );

      // Karena Laravel Controller Anda mengembalikan langsung array [materi1, materi2]
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Gagal memuat data');
      }
    } on DioException catch (e) {
      throw Exception('Kesalahan koneksi: ${e.message}');
    }
  }

  // Tambah Materi
  // lib/services/materi_service.dart

  Future<bool> storeMateri({
    required String judul,
    required String deskripsi,
    required String kategori,
    File? fileModul,
    dynamic thumbnail, // Bisa berupa File (Mobile) atau XFile (Web)
  }) async {
    try {
      Map<String, dynamic> dataMap = {
        "judul_materi": judul,
        "deskripsi": deskripsi,
        "kategori": kategori,
      };

      // Logika pengiriman Thumbnail
      if (thumbnail != null) {
        if (kIsWeb) {
          // Khusus WEB: Gunakan Bytes dari XFile
          dataMap["thumbnail"] = await MultipartFile.fromBytes(
            await thumbnail.readAsBytes(),
            filename: thumbnail.name,
          );
        } else {
          // Khusus MOBILE: Gunakan Path dari File
          dataMap["thumbnail"] = await MultipartFile.fromFile(
            thumbnail.path,
            filename: thumbnail.path.split('/').last,
          );
        }
      }

      FormData formData = FormData.fromMap(dataMap);

      final response = await _dio.post(
        '$_baseUrl/guru/materi',
        data: formData,
        options: _getOptions(),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error di MateriService: $e");
      return false;
    }
  }

  // Update Materi
  Future<bool> updateMateri({
    required int id,
    required String judul,
    required String deskripsi,
    required String kategori,
    dynamic thumbnail, // Bisa berupa File atau XFile
  }) async {
    try {
      Map<String, dynamic> dataMap = {
        "judul_materi": judul,
        "deskripsi": deskripsi,
        "kategori": kategori,
        "_method":
            "PUT", // PENTING: Laravel butuh ini untuk Multipart di POST request
      };

      if (thumbnail != null) {
        if (kIsWeb) {
          dataMap["thumbnail"] = await MultipartFile.fromBytes(
            await thumbnail.readAsBytes(),
            filename: thumbnail.name,
          );
        } else {
          dataMap["thumbnail"] = await MultipartFile.fromFile(
            thumbnail.path,
            filename: thumbnail.path.split('/').last,
          );
        }
      }

      FormData formData = FormData.fromMap(dataMap);

      // Tetap gunakan POST tapi kirim field _method: PUT
      final response = await _dio.post(
        '$_baseUrl/guru/materi/$id',
        data: formData,
        options: _getOptions(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error Update: $e");
      return false;
    }
  }

  // Hapus Materi
  Future<bool> deleteMateri(int id) async {
    try {
      final response = await _dio.delete(
        '$_baseUrl/guru/materi/$id',
        options: _getOptions(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Tambah Modul (Video/PDF)
  Future<bool> storeModul({
    required int materiId,
    required String judul,
    required String tipe,
    required dynamic konten, // Bisa String, File, atau PlatformFile
  }) async {
    try {
      Map<String, dynamic> dataMap = {
        "materi_id": materiId,
        "judul_modul": judul,
        "tipe_konten": tipe,
      };

      if (tipe == 'PDF' && konten != null) {
        if (kIsWeb) {
          // PERBAIKAN UNTUK WEB: PlatformFile menyimpan bytes langsung di properti .bytes
          dataMap["konten"] = MultipartFile.fromBytes(
            konten.bytes!,
            filename: konten.name,
          );
        } else {
          // UNTUK MOBILE: Gunakan path dari objek File
          dataMap["konten"] = await MultipartFile.fromFile(
            konten.path,
            filename: konten.path.split('/').last,
          );
        }
      } else {
        dataMap["konten"] = konten; // Link YouTube (String)
      }

      FormData formData = FormData.fromMap(dataMap);
      final response = await _dio.post(
        '$_baseUrl/guru/modul',
        data: formData,
        options: _getOptions(),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error Store Modul: $e");
      return false;
    }
  }

  // Update Modul (Video/PDF)
  Future<bool> updateModul({
    required int id,
    required String judul,
    required String tipe,
    required dynamic konten,
  }) async {
    try {
      Map<String, dynamic> dataMap = {
        "judul_modul": judul,
        "tipe_konten": tipe,
        "_method": "PUT", // Spoofing untuk Laravel
      };

      if (tipe == 'PDF' && konten is! String) {
        if (kIsWeb) {
          dataMap["konten"] = MultipartFile.fromBytes(
            konten.bytes!,
            filename: konten.name,
          );
        } else {
          dataMap["konten"] = await MultipartFile.fromFile(
            konten.path,
            filename: konten.path.split('/').last,
          );
        }
      } else {
        dataMap["konten"] = konten; // Link YouTube
      }

      FormData formData = FormData.fromMap(dataMap);
      final response = await _dio.post(
        '$_baseUrl/guru/modul/$id',
        data: formData,
        options: _getOptions(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Hapus Modul
  Future<bool> deleteModul(int id) async {
    try {
      final response = await _dio.delete(
        '$_baseUrl/guru/modul/$id',
        options: _getOptions(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Tambah Kuis
  Future<bool> storeKuis({
    required int materiId,
    required String pertanyaan,
    required String a,
    required String b,
    required String c,
    required String d,
    required String kunci,
    dynamic imageFile, // XFile atau File
  }) async {
    try {
      Map<String, dynamic> dataMap = {
        "materi_id": materiId,
        "pertanyaan": pertanyaan,
        "jawaban_a": a,
        "jawaban_b": b,
        "jawaban_c": c,
        "jawaban_d": d,
        "jawaban_benar": kunci,
      };

      if (imageFile != null) {
        if (kIsWeb) {
          dataMap["image"] = await MultipartFile.fromBytes(
            await imageFile.readAsBytes(),
            filename: imageFile.name,
          );
        } else {
          dataMap["image"] = await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          );
        }
      }

      FormData formData = FormData.fromMap(dataMap);
      final response = await _dio.post(
        '$_baseUrl/guru/kuis',
        data: formData,
        options: _getOptions(),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Update Kuis
  Future<bool> updateKuis({
    required int id,
    required String pertanyaan,
    required String a,
    required String b,
    required String c,
    required String d,
    required String kunci,
    dynamic imageFile,
  }) async {
    try {
      Map<String, dynamic> dataMap = {
        "pertanyaan": pertanyaan,
        "jawaban_a": a,
        "jawaban_b": b,
        "jawaban_c": c,
        "jawaban_d": d,
        "jawaban_benar": kunci,
        "_method": "PUT", // Penting untuk Spoofing Multipart di Laravel
      };

      if (imageFile != null) {
        if (kIsWeb) {
          dataMap["image"] = MultipartFile.fromBytes(
            await imageFile.readAsBytes(),
            filename: imageFile.name,
          );
        } else {
          dataMap["image"] = await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          );
        }
      }

      FormData formData = FormData.fromMap(dataMap);

      final response = await _dio.post(
        '$_baseUrl/guru/kuis/$id',
        data: formData,
        options: _getOptions(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      // Tambahkan log ini untuk melihat apa yang salah di console
      print("Dio Error Update Kuis: ${e.response?.data ?? e.message}");
      return false;
    } catch (e) {
      print("General Error Update Kuis: $e");
      return false;
    }
  }

  // Hapus Kuis
  Future<bool> deleteKuis(int id) async {
    try {
      final response = await _dio.delete(
        '$_baseUrl/guru/kuis/$id',
        options: _getOptions(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete Kuis: $e");
      return false;
    }
  }
}
