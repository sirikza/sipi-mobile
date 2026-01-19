import 'package:flutter/material.dart';
import '../../services/user_service.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final UserService _userService = UserService();
  late Future<List<dynamic>> _users;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _users = _userService.getUsers();
    });
  }

  // --- MODAL FORM (TAMBAH & EDIT) ---
  void _showUserForm({Map<String, dynamic>? user}) {
    final nameCtrl = TextEditingController(text: user?['name']);
    final emailCtrl = TextEditingController(text: user?['email']);
    final passwordCtrl = TextEditingController();
    String selectedLevel = user?['level_akses'] ?? 'siswa';
    bool isEdit = user != null;

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
                  decoration: const InputDecoration(labelText: "Nama Lengkap"),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? "Password Baru (Kosongkan jika tetap)"
                        : "Password",
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: const InputDecoration(labelText: "Level Akses"),
                  items: ['guru', 'siswa', 'admin'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedLevel = val!),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    Map<String, dynamic> data = {
                      "name": nameCtrl.text,
                      "email": emailCtrl.text,
                      "level_akses": selectedLevel,
                    };
                    if (passwordCtrl.text.isNotEmpty)
                      data["password"] = passwordCtrl.text;

                    bool success = isEdit
                        ? await _userService.updateUser(user['id'], data)
                        : await _userService.storeUser(data);

                    if (success && mounted) {
                      Navigator.pop(context);
                      _refreshData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit ? "User diperbarui" : "User ditambahkan",
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(isEdit ? "Update Data" : "Simpan User"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- KONFIRMASI HAPUS ---
  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus User?"),
        content: Text("Apakah Anda yakin ingin menghapus $name?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              if (await _userService.deleteUser(id)) {
                Navigator.pop(context);
                _refreshData();
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
        title: const Text("Kelola User"),
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(child: Text("Data user kosong"));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user['level_akses'] == 'guru'
                        ? Colors.teal
                        : Colors.indigo,
                    child: Icon(
                      user['level_akses'] == 'guru'
                          ? Icons.school
                          : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(user['name']),
                  subtitle: Text(
                    "${user['email']} • ${user['level_akses'].toString().toUpperCase()}",
                  ),
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
                            _confirmDelete(user['id'], user['name']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        label: const Text("User Baru"),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}
