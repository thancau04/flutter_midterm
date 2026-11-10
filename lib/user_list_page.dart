import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_page.dart';
import 'user_form_page.dart';
import 'user_model.dart';
import 'user_service.dart';

/// Màn hình chính phân hệ Admin: hiển thị, tìm kiếm, sửa, xóa, xuất JSON.
class UserListPage extends StatefulWidget {
  final UserModel current; // tài khoản đang đăng nhập
  const UserListPage({super.key, required this.current});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final _service = UserService();
  late final Stream<List<UserModel>> _stream;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _stream = _service.getUsersStream(); // tạo 1 lần, tránh subscribe lại mỗi lần gõ tìm kiếm
  }

  void _msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _confirmDelete(UserModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Bạn có chắc muốn xóa "${u.hoten}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || u.id == null) return;
    try {
      await _service.deleteUser(u.id!);
      if (!mounted) return;
      _msg('Đã xóa "${u.hoten}"');
      if (u.id == widget.current.id) _logout(); // tự xóa chính mình
    } catch (e) {
      _msg('Lỗi xóa: $e');
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _exportJson() async {
    try {
      final json = await _service.exportUsersJson();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('users.json'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: SingleChildScrollView(
              child: SelectableText(
                json,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Sao chép'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (ctx.mounted) Navigator.pop(ctx);
                _msg('Đã sao chép JSON - dán vào file users.json');
              },
            ),
          ],
        ),
      );
    } catch (e) {
      _msg('Lỗi xuất JSON: $e');
    }
  }

  void _openDetail(UserModel u) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(hinhanh: u.hinhanh, radius: 56),
            const SizedBox(height: 12),
            Text(
              u.hoten,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Email: ${u.email}'),
            Text('Mật khẩu: ${u.matkhau}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin: ${widget.current.hoten}'),
        actions: [
          IconButton(
            tooltip: 'Xuất JSON (users.json)',
            icon: const Icon(Icons.download),
            onPressed: _exportJson,
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm theo họ tên hoặc email',
                filled: true,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  setState(() => _keyword = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Thêm người dùng',
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserFormPage()),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!
              .where(
                (u) =>
                    u.hoten.toLowerCase().contains(_keyword) ||
                    u.email.toLowerCase().contains(_keyword),
              )
              .toList();
          if (list.isEmpty) {
            return const Center(child: Text('Không có người dùng'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final u = list[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  onTap: () => _openDetail(u),
                  leading: UserAvatar(hinhanh: u.hinhanh),
                  title: Text(u.hoten),
                  subtitle: Text('${u.email}\nMật khẩu: ${u.matkhau}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Sửa',
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserFormPage(user: u),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(u),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
