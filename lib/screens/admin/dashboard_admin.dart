import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'package:get_storage/get_storage.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final UserService _userService = UserService();
  final _storage = GetStorage();
  late Future<List<dynamic>> _userList;

  // --- FUNGSI LOGOUT ---
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              // Sekarang _storage sudah terdefinisi
              _storage.erase();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _userList = _userService.getUsers();
    });
  }

  // --- FORM MODAL (TAMBAH & EDIT) ---
  void _showUserForm({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final nameCtrl = TextEditingController(text: isEdit ? user['name'] : '');
    final emailCtrl = TextEditingController(text: isEdit ? user['email'] : '');
    final passCtrl = TextEditingController(); // Password opsional saat edit
    String selectedLevel = isEdit ? user['level_akses'] : 'siswa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                Text(
                  isEdit ? "Edit User" : "Tambah User Baru",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? "Password Baru (Kosongkan jika tetap)"
                        : "Password",
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: const InputDecoration(
                    labelText: "Level Akses",
                    border: OutlineInputBorder(),
                  ),
                  items: ['admin', 'guru', 'siswa'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedLevel = val!),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: isEdit ? Colors.orange : Colors.redAccent,
                  ),
                  onPressed: () async {
                    Map<String, dynamic> data = {
                      "name": nameCtrl.text,
                      "email": emailCtrl.text,
                      "level_akses": selectedLevel,
                    };

                    // Hanya tambahkan password jika diisi
                    if (passCtrl.text.isNotEmpty) {
                      data["password"] = passCtrl.text;
                    }

                    bool success;
                    if (isEdit) {
                      success = await _userService.updateUser(user['id'], data);
                    } else {
                      success = await _userService.storeUser(data);
                    }

                    if (success && mounted) {
                      Navigator.pop(context);
                      _refreshData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit ? "Data diperbarui" : "User ditambahkan",
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEdit ? "Update Data" : "Simpan User",
                    style: const TextStyle(color: Colors.white),
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

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus User?"),
        content: Text("Apakah Anda yakin ingin menghapus user '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await _userService.deleteUser(id);
              if (success) {
                _refreshData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User berhasil dihapus")),
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
          "Admin - Kelola Users",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        actions: [
          // TOMBOL REFRESH
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
          // --- TAMBAHKAN TOMBOL LOGOUT DI SINI ---
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed:
                _handleLogout, // Memanggil fungsi logout yang sudah Anda buat
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _userList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tidak ada data user."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var user = snapshot.data![index];
              String displayName =
                  user['name'] ?? user['username'] ?? "No Name";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user['level_akses'] == 'guru'
                        ? Colors.teal
                        : Colors.blue,
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${user['email']}\nRole: ${user['level_akses'].toString().toUpperCase()}",
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showUserForm(user: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _confirmDelete(user['id'], displayName),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () => _showUserForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
