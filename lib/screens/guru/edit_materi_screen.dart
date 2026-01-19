import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/materi_service.dart';

class EditMateriScreen extends StatefulWidget {
  final Map<String, dynamic> materi; // Menerima data materi yang akan diedit

  const EditMateriScreen({super.key, required this.materi});

  @override
  State<EditMateriScreen> createState() => _EditMateriScreenState();
}

class _EditMateriScreenState extends State<EditMateriScreen> {
  final _materiService = MateriService();
  late TextEditingController _judulController;
  late TextEditingController _descController;
  late TextEditingController _kategoriManualController;

  String _selectedKategori = 'Umum';
  bool _isKategoriLainnya = false;
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

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data yang sudah ada
    _judulController = TextEditingController(
      text: widget.materi['judul_materi'],
    );
    _descController = TextEditingController(text: widget.materi['deskripsi']);

    // Logika pengecekan kategori
    if (_kategoriList.contains(widget.materi['kategori'])) {
      _selectedKategori = widget.materi['kategori'];
    } else {
      _selectedKategori = 'Lainnya';
      _isKategoriLainnya = true;
      _kategoriManualController = TextEditingController(
        text: widget.materi['kategori'],
      );
    }

    if (!_isKategoriLainnya) {
      _kategoriManualController = TextEditingController();
    }
  }

  Future<void> _pickThumbnail() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _pickedFile = image);
  }

  void _updateMateri() async {
    setState(() => _isLoading = true);

    String kategoriFinal = _isKategoriLainnya
        ? _kategoriManualController.text.trim()
        : _selectedKategori;

    // Memanggil fungsi update di service
    bool success = await _materiService.updateMateri(
      id: widget.materi['id'],
      judul: _judulController.text,
      deskripsi: _descController.text,
      kategori: kategoriFinal,
      thumbnail: _pickedFile,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Materi diperbarui!")));
      Navigator.pop(context, true); // Kembali ke dashboard dan refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Materi")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Preview Thumbnail (Lama vs Baru)
            GestureDetector(
              onTap: _pickThumbnail,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _pickedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: kIsWeb
                            ? Image.network(
                                _pickedFile!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_pickedFile!.path),
                                fit: BoxFit.cover,
                              ),
                      )
                    : (widget.materi['thumbnail'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                'http://10.0.2.2:8000/storage/${widget.materi['thumbnail']}',
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.add_a_photo, size: 50)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                labelText: "Judul",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedKategori,
              decoration: const InputDecoration(
                labelText: "Kategori",
                border: OutlineInputBorder(),
              ),
              items: _kategoriList
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedKategori = val!;
                _isKategoriLainnya = (val == 'Lainnya');
              }),
            ),
            if (_isKategoriLainnya) ...[
              const SizedBox(height: 15),
              TextField(
                controller: _kategoriManualController,
                decoration: const InputDecoration(
                  labelText: "Kategori Baru",
                  border: OutlineInputBorder(),
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
                onPressed: _isLoading ? null : _updateMateri,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Simpan Perubahan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
