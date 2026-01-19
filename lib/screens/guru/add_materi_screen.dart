import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Digunakan untuk cek platform
import '../../services/materi_service.dart';

class AddMateriScreen extends StatefulWidget {
  const AddMateriScreen({super.key});

  @override
  State<AddMateriScreen> createState() => _AddMateriScreenState();
}

class _AddMateriScreenState extends State<AddMateriScreen> {
  final _judulController = TextEditingController();
  final _descController = TextEditingController();
  final _kategoriManualController = TextEditingController();
  final _materiService = MateriService();

  String _selectedKategori = 'Umum';
  bool _isKategoriLainnya = false;

  // Gunakan XFile agar lebih kompatibel dengan web dan mobile secara bersamaan
  XFile? _pickedFile;
  bool _isLoading = false;

  final List<String> _kategoriList = [
    'Umum',
    'Fisika',
    'Biologi',
    'Kimia',
    'Matematika',
    'Lainnya',
  ];

  Future<void> _pickThumbnail() async {
    final ImagePicker picker = ImagePicker();
    // ImageSource.gallery tetap berfungsi di web (membuka file picker browser)
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedFile = image;
      });
    }
  }

  void _saveMateri() async {
    if (_judulController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Judul wajib diisi")));
      return;
    }

    String kategoriFinal = _isKategoriLainnya
        ? _kategoriManualController.text.trim()
        : _selectedKategori;

    if (kategoriFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kategori tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Konversi XFile ke File hanya jika di mobile (platform non-web)
    File? thumbnailFile = (_pickedFile != null && !kIsWeb)
        ? File(_pickedFile!.path)
        : null;

    bool success = await _materiService.storeMateri(
      judul: _judulController.text,
      deskripsi: _descController.text,
      kategori: kategoriFinal,
      thumbnail: thumbnailFile,
      fileModul: null,
    );

    setState(() => _isLoading = false);
    if (success && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Materi Baru"),
        // Pastikan 'leading' ada di dalam AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Tombol kembali manual
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Thumbnail dengan proteksi platform web
            Center(
              child: GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.5),
                    ),
                  ),
                  child: _pickedFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.blueAccent,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Pilih Thumbnail Materi",
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: kIsWeb
                              ? Image.network(
                                  _pickedFile!.path,
                                  fit: BoxFit.cover,
                                ) // Web menggunakan path network/blob
                              : Image.file(
                                  File(_pickedFile!.path),
                                  fit: BoxFit.cover,
                                ), // Mobile menggunakan File
                        ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                labelText: "Judul Materi",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedKategori,
              decoration: const InputDecoration(
                labelText: "Pilih Kategori",
                border: OutlineInputBorder(),
              ),
              items: _kategoriList
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedKategori = val!;
                  _isKategoriLainnya = (val == 'Lainnya');
                });
              },
            ),

            if (_isKategoriLainnya) ...[
              const SizedBox(height: 15),
              TextField(
                controller: _kategoriManualController,
                decoration: const InputDecoration(
                  labelText: "Ketik Kategori Baru",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
            ],
            const SizedBox(height: 20),

            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMateri,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Simpan & Publikasikan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
