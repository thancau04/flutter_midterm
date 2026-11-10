import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'user_model.dart';
import 'user_service.dart';

/// Form dùng chung cho Thêm (user == null) và Sửa (user != null)
class UserFormPage extends StatefulWidget {
  final UserModel? user;
  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = UserService();
  late final TextEditingController _hoten;
  late final TextEditingController _email;
  late final TextEditingController _matkhau;
  late final TextEditingController _hinhanh; // Base64 hoặc URL
  bool _saving = false;
  bool _hide = true;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _hoten = TextEditingController(text: u?.hoten ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _matkhau = TextEditingController(text: u?.matkhau ?? '');
    _hinhanh = TextEditingController(text: u?.hinhanh ?? '');
  }

  @override
  void dispose() {
    _hoten.dispose();
    _email.dispose();
    _matkhau.dispose();
    _hinhanh.dispose();
    super.dispose();
  }

  void _msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  /// Chọn ảnh từ thiết bị -> nén -> mã hóa Base64 -> gán vào hinhanh
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 300, // thu nhỏ để không vượt giới hạn 1MB/document của Firestore
        imageQuality: 70,
      );
      if (x == null) return;
      final Uint8List bytes = await x.readAsBytes(); // chạy được cả Web & Android
      setState(() => _hinhanh.text = base64Encode(bytes));
    } catch (e) {
      _msg('Không chọn được ảnh: $e');
    }
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_hinhanh.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Xóa ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _hinhanh.clear());
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final email = _email.text.trim();
      if (await _service.emailExists(email, exceptId: widget.user?.id)) {
        _msg('Email đã tồn tại');
        return;
      }
      final u = UserModel(
        email: email,
        matkhau: _matkhau.text,
        hoten: _hoten.text.trim(),
        hinhanh: _hinhanh.text.trim(),
      );
      if (_isEdit) {
        await _service.updateUser(widget.user!.id!, u);
      } else {
        await _service.addUser(u);
      }
      if (!mounted) return;
      _msg(_isEdit ? 'Đã cập nhật người dùng' : 'Đã thêm người dùng');
      Navigator.pop(context);
    } catch (e) {
      _msg('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBase64 =
        _hinhanh.text.isNotEmpty && !_hinhanh.text.startsWith('http');
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa người dùng' : 'Thêm người dùng'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Ảnh xem trước (preview)
                  GestureDetector(
                    onTap: _showPickOptions,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        UserAvatar(hinhanh: _hinhanh.text, radius: 60),
                        const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.camera_alt, size: 18),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showPickOptions,
                    icon: const Icon(Icons.image),
                    label: const Text('Chọn ảnh từ thiết bị'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _hoten,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Nhập email';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _matkhau,
                    obscureText: _hide,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hide ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mật khẩu tối thiểu 6 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hinhanh,
                    maxLines: 1,
                    onChanged: (_) => setState(() {}), // cập nhật preview
                    decoration: InputDecoration(
                      labelText: 'Hình ảnh (URL hoặc Base64)',
                      helperText: isBase64
                          ? 'Đang dùng ảnh từ thiết bị (Base64, ${_hinhanh.text.length} ký tự)'
                          : 'Dán link ảnh hoặc bấm "Chọn ảnh từ thiết bị"',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEdit ? 'Cập nhật' : 'Lưu'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
