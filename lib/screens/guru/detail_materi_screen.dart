import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/materi_service.dart';

class DetailMateriScreen extends StatefulWidget {
  final Map<String, dynamic> materi;
  const DetailMateriScreen({super.key, required this.materi});

  @override
  State<DetailMateriScreen> createState() => _DetailMateriScreenState();
}

class _DetailMateriScreenState extends State<DetailMateriScreen> {
  final MateriService _materiService = MateriService();

  List<dynamic> _moduls = [];
  List<dynamic> _kuisList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _moduls = widget.materi['moduls'] ?? [];
    _kuisList = widget.materi['kuis'] ?? [];
  }

  // Fungsi refresh data modul
  Future<void> _refreshDetail() async {
    setState(() => _isLoading = true);
    try {
      final list = await _materiService.getMateri();
      final updatedMateri = list.firstWhere(
        (m) => m['id'] == widget.materi['id'],
      );
      setState(() {
        _moduls = updatedMateri['moduls'] ?? [];
        _kuisList = updatedMateri['kuis'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- UI MODUL ---
  void _showAddModulSheet() {
    final judulController = TextEditingController();
    final linkController = TextEditingController();
    dynamic selectedFile;
    String selectedTipe = 'Video';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tambah Modul",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: judulController,
                decoration: const InputDecoration(labelText: "Judul Modul"),
              ),
              DropdownButton<String>(
                value: selectedTipe,
                isExpanded: true,
                items: ['Video', 'PDF']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedTipe = val!),
              ),
              if (selectedTipe == 'Video')
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(labelText: "Link YouTube"),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? r = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                      withData:
                          kIsWeb, // PENTING: Wajib true agar bytes terbaca di Web
                    );

                    if (r != null) {
                      setModalState(() {
                        if (kIsWeb) {
                          // Di Web, simpan objek PlatformFile-nya langsung
                          selectedFile = r.files.first;
                        } else {
                          // Di Mobile, simpan sebagai File
                          selectedFile = File(r.files.single.path!);
                        }
                      });
                    }
                  },
                  child: Text(
                    selectedFile == null ? "Pilih PDF" : "PDF Terpilih",
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Gunakan variabel _materiService
                  bool success = await _materiService.storeModul(
                    materiId: widget.materi['id'],
                    judul: judulController.text,
                    tipe: selectedTipe,
                    konten: selectedTipe == 'Video'
                        ? linkController.text
                        : selectedFile,
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                    _refreshDetail();
                  }
                },
                child: const Text("Simpan"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditModulSheet(Map<String, dynamic> modul) {
    final judulController = TextEditingController(text: modul['judul_modul']);
    final linkController = TextEditingController(
      text: modul['tipe_konten'] == 'Video' ? modul['konten'] : "",
    );
    dynamic selectedFile;
    String selectedTipe = modul['tipe_konten'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Modul: ${modul['judul_modul']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: judulController,
                decoration: const InputDecoration(labelText: "Judul Modul"),
              ),
              DropdownButton<String>(
                value: selectedTipe,
                isExpanded: true,
                items: ['Video', 'PDF']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedTipe = val!),
              ),
              if (selectedTipe == 'Video')
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(labelText: "Link YouTube"),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    FilePickerResult? r = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                      withData: kIsWeb,
                    );
                    if (r != null)
                      setModalState(
                        () => selectedFile = kIsWeb
                            ? r.files.first
                            : File(r.files.single.path!),
                      );
                  },
                  child: Text(
                    selectedFile == null
                        ? "Ganti PDF (Opsional)"
                        : "PDF Baru Terpilih",
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Jika tipe PDF tapi tidak pilih file baru, kirim konten lama (path string)
                  var kontenFinal =
                      (selectedTipe == 'PDF' && selectedFile == null)
                      ? modul['konten']
                      : (selectedTipe == 'Video'
                            ? linkController.text
                            : selectedFile);

                  bool success = await _materiService.updateModul(
                    id: modul['id'],
                    judul: judulController.text,
                    tipe: selectedTipe,
                    konten: kontenFinal,
                  );
                  if (success && mounted) {
                    Navigator.pop(context);
                    _refreshDetail();
                  }
                },
                child: const Text("Simpan Perubahan"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteModul(int id, String judul) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Modul"),
        content: Text("Apakah Anda yakin ingin menghapus modul '$judul'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Menutup dialog
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Menutup dialog sebelum proses

              setState(() => _isLoading = true);
              bool success = await _materiService.deleteModul(id);

              if (success) {
                _refreshDetail();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Modul berhasil dihapus")),
                  );
                }
              } else {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Gagal menghapus modul"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- UI KUIS ---
  void _showAddKuisSheet() {
    final pertanyannCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final bCtrl = TextEditingController();
    final cCtrl = TextEditingController();
    final dCtrl = TextEditingController();
    String kunci = 'a';
    XFile? imageSoal; // Variabel penampung gambar

    void _showEditKuisSheet(Map<String, dynamic> itemKuis) {
      // Mengubah nama parameter agar tidak bentrok
      final pertanyannCtrl = TextEditingController(
        text: itemKuis['pertanyaan'],
      );
      final aCtrl = TextEditingController(text: itemKuis['jawaban_a']);
      final bCtrl = TextEditingController(text: itemKuis['jawaban_b']);
      final cCtrl = TextEditingController(text: itemKuis['jawaban_c']);
      final dCtrl = TextEditingController(text: itemKuis['jawaban_d']);
      String kunci = itemKuis['jawaban_benar'];

      // DEFINISIKAN VARIABLE INI AGAR BISA DIAKSES OLEH ONPRESSED
      XFile? selectedImage;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Edit Soal Kuis",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: pertanyannCtrl,
                    decoration: const InputDecoration(
                      labelText: "Pertanyaan",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),

                  // Bagian Pilih Gambar
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedImage == null
                              ? "Ganti gambar? (Opsional)"
                              : "Gambar Baru: ${selectedImage!.name}",
                          style: TextStyle(
                            color: selectedImage == null
                                ? Colors.grey
                                : Colors.green,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setModalState(() => selectedImage = image);
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Pilih"),
                      ),
                    ],
                  ),

                  TextField(
                    controller: aCtrl,
                    decoration: const InputDecoration(labelText: "Opsi A"),
                  ),
                  TextField(
                    controller: bCtrl,
                    decoration: const InputDecoration(labelText: "Opsi B"),
                  ),
                  TextField(
                    controller: cCtrl,
                    decoration: const InputDecoration(labelText: "Opsi C"),
                  ),
                  TextField(
                    controller: dCtrl,
                    decoration: const InputDecoration(labelText: "Opsi D"),
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: kunci,
                    decoration: const InputDecoration(
                      labelText: "Jawaban Benar",
                      border: OutlineInputBorder(),
                    ),
                    items: ['a', 'b', 'c', 'd']
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Text("Opsi ${k.toUpperCase()}"),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setModalState(() => kunci = val!),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () async {
                      // SEKARANG itemKuis dan selectedImage SUDAH TERDEFINISI
                      bool success = await _materiService.updateKuis(
                        id: itemKuis['id'], // Menggunakan nama parameter yang baru
                        pertanyaan: pertanyannCtrl.text,
                        a: aCtrl.text,
                        b: bCtrl.text,
                        c: cCtrl.text,
                        d: dCtrl.text,
                        kunci: kunci,
                        imageFile:
                            selectedImage, // Menggunakan variabel yang didefinisikan di atas
                      );

                      if (success && mounted) {
                        Navigator.pop(context);
                        _refreshDetail();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Kuis diperbarui"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Update Kuis",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showEditKuisSheet(Map<String, dynamic> kuis) {
    final pertanyannCtrl = TextEditingController(text: kuis['pertanyaan']);
    final aCtrl = TextEditingController(text: kuis['jawaban_a']);
    final bCtrl = TextEditingController(text: kuis['jawaban_b']);
    final cCtrl = TextEditingController(text: kuis['jawaban_c']);
    final dCtrl = TextEditingController(text: kuis['jawaban_d']);
    String kunci = kuis['jawaban_benar'];
    XFile? selectedImage; // Menggunakan XFile? agar konsisten

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Soal Kuis",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: pertanyannCtrl,
                  decoration: const InputDecoration(
                    labelText: "Pertanyaan",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                // --- BAGIAN INPUT GAMBAR (SAMA SEPERTI ADD KUIS) ---
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (kuis['image'] != null && selectedImage == null)
                            const Text(
                              "Gambar saat ini sudah terpasang",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            selectedImage == null
                                ? "Ganti gambar? (Opsional)"
                                : "Gambar baru: ${selectedImage!.name}",
                            style: TextStyle(
                              color: selectedImage == null
                                  ? Colors.grey
                                  : Colors.green,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );

                        if (image != null) {
                          setModalState(() {
                            selectedImage = image;
                          });
                        }
                      },
                      icon: const Icon(Icons.image_search),
                      label: const Text("Pilih Gambar"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ---------------------------------------------------
                TextField(
                  controller: aCtrl,
                  decoration: const InputDecoration(labelText: "Opsi A"),
                ),
                TextField(
                  controller: bCtrl,
                  decoration: const InputDecoration(labelText: "Opsi B"),
                ),
                TextField(
                  controller: cCtrl,
                  decoration: const InputDecoration(labelText: "Opsi C"),
                ),
                TextField(
                  controller: dCtrl,
                  decoration: const InputDecoration(labelText: "Opsi D"),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: kunci,
                  decoration: const InputDecoration(
                    labelText: "Jawaban Benar",
                    border: OutlineInputBorder(),
                  ),
                  items: ['a', 'b', 'c', 'd']
                      .map(
                        (k) => DropdownMenuItem(
                          value: k,
                          child: Text("Opsi ${k.toUpperCase()}"),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setModalState(() => kunci = val!),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.orange, // Warna berbeda untuk edit
                  ),
                  onPressed: () async {
                    bool success = await _materiService.updateKuis(
                      id: kuis['id'],
                      pertanyaan: pertanyannCtrl.text,
                      a: aCtrl.text,
                      b: bCtrl.text,
                      c: cCtrl.text,
                      d: dCtrl.text,
                      kunci: kunci,
                      imageFile: selectedImage, // Mengirim gambar baru jika ada
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                      _refreshDetail();
                    }
                  },
                  child: const Text(
                    "Update Kuis",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteKuis(int id, String pertanyaan) {
    // Potong teks pertanyaan agar tidak terlalu panjang di dialog
    String previewTeks = pertanyaan.length > 50
        ? "${pertanyaan.substring(0, 50)}..."
        : pertanyaan;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Soal Kuis?"),
        content: Text(
          "Apakah Anda yakin ingin menghapus soal: \n\n'$previewTeks'",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog

              setState(() => _isLoading = true);
              bool success = await _materiService.deleteKuis(id);

              if (success) {
                _refreshDetail();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Soal kuis berhasil dihapus")),
                  );
                }
              } else {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Gagal menghapus kuis"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.materi['judul_materi']),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.library_books), text: "Modul"),
              Tab(icon: Icon(Icons.quiz), text: "Kuis"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab Modul
                  _buildModulList(),
                  // Tab Kuis
                  _buildKuisList(),
                ],
              ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final tabIndex = DefaultTabController.of(context).index;
                if (tabIndex == 0)
                  _showAddModulSheet();
                else
                  _showAddKuisSheet();
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModulList() {
    if (_moduls.isEmpty) return const Center(child: Text("Belum ada modul."));
    return ListView.builder(
      itemCount: _moduls.length,
      itemBuilder: (context, index) {
        final m = _moduls[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: Icon(
              m['tipe_konten'] == 'Video'
                  ? Icons.play_circle
                  : Icons.picture_as_pdf,
              color: m['tipe_konten'] == 'Video' ? Colors.red : Colors.blue,
            ),
            title: Text(m['judul_modul']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showEditModulSheet(m),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      _confirmDeleteModul(m['id'], m['judul_modul']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKuisList() {
    if (_kuisList.isEmpty)
      return const Center(child: Text("Belum ada soal kuis."));
    return ListView.builder(
      itemCount: _kuisList.length,
      itemBuilder: (context, index) {
        final k = _kuisList[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.help_outline)),
            title: Text(
              k['pertanyaan'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text("Kunci: ${k['jawaban_benar']?.toUpperCase()}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showEditKuisSheet(k),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteKuis(k['id'], k['pertanyaan']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
