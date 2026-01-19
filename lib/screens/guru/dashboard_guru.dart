import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'edit_materi_screen.dart';
import 'detail_materi_screen.dart'; // Pastikan file ini sudah dibuat
import '../../services/materi_service.dart';

class GuruDashboard extends StatefulWidget {
  const GuruDashboard({super.key});

  @override
  State<GuruDashboard> createState() => _GuruDashboardState();
}

class _GuruDashboardState extends State<GuruDashboard> {
  final MateriService _materiService = MateriService();
  final _storage = GetStorage();
  late Future<List<dynamic>> _materiList;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _materiList = _materiService.getMateri();
    });
  }

  void _handleLogout() {
    _storage.erase();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Materi?"),
        content: const Text(
          "Seluruh modul dan kuis di dalamnya akan dihapus permanen.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await _materiService.deleteMateri(id);
              if (success) {
                _refreshData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Materi berhasil dihapus")),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard Guru",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: FutureBuilder<List<dynamic>>(
          future: _materiList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("Belum ada materi. Silakan tambah baru."),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final materi = snapshot.data![index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      // Masuk ke Detail untuk kelola Modul & Kuis
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailMateriScreen(materi: materi),
                        ),
                      ).then((_) => _refreshData());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Thumbnail Preview
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: materi['thumbnail'] != null
                                ? Image.network(
                                    "http://10.0.2.2:8000/storage/${materi['thumbnail']}",
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.broken_image,
                                              ),
                                            ),
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.blue[100],
                                    child: const Icon(Icons.book, size: 40),
                                  ),
                          ),
                          const SizedBox(width: 15),
                          // Info Teks
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  materi['judul_materi'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Kategori: ${materi['kategori']}",
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.library_books,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${materi['moduls']?.length ?? 0} Modul",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      Icons.quiz,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${materi['kuis']?.length ?? 0} Kuis",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Tombol Aksi
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditMateriScreen(materi: materi),
                                    ),
                                  );
                                  if (res == true) _refreshData();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(materi['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.pushNamed(context, '/add-materi');
          if (res == true) _refreshData();
        },
        label: const Text("Materi Baru"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
