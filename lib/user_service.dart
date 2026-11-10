import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';

/// Đóng gói toàn bộ thao tác với collection `users` trên Cloud Firestore.
class UserService {
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore
      .instance
      .collection('users');

  /// Tài khoản Admin mặc định - chỉ dùng khi CSDL đang trống
  static const String defaultEmail = 'admin@gmail.com';
  static const String defaultPassword = '123456';

  /// READ - danh sách người dùng realtime
  Stream<List<UserModel>> getUsersStream() {
    return _col.snapshots().map(
      (snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList(),
    );
  }

  /// CREATE - thêm document mới (Firestore tự sinh id)
  Future<void> addUser(UserModel user) => _col.add(user.toMap());

  /// UPDATE - ghi đè document theo id, đảm bảo chỉ còn đúng 4 trường
  Future<void> updateUser(String id, UserModel user) =>
      _col.doc(id).set(user.toMap());

  /// DELETE - xóa document theo id
  Future<void> deleteUser(String id) => _col.doc(id).delete();

  /// Kiểm tra email đã tồn tại (bỏ qua chính document đang sửa)
  Future<bool> emailExists(String email, {String? exceptId}) async {
    final q = await _col.where('email', isEqualTo: email).get();
    return q.docs.any((d) => d.id != exceptId);
  }

  /// LOGIN - so khớp email + matkhau trong Firestore.
  /// Nếu CSDL trống: cho phép đăng nhập bằng tài khoản mặc định
  /// (admin@gmail.com / 123456) và tạo luôn tài khoản đó (đúng 4 trường).
  Future<UserModel?> login(String email, String matkhau) async {
    final q = await _col
        .where('email', isEqualTo: email)
        .where('matkhau', isEqualTo: matkhau)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return UserModel.fromFirestore(q.docs.first);

    if (email == defaultEmail && matkhau == defaultPassword) {
      final any = await _col.limit(1).get();
      if (any.docs.isEmpty) {
        final admin = UserModel(
          email: defaultEmail,
          matkhau: defaultPassword,
          hoten: 'Administrator',
        );
        final ref = await _col.add(admin.toMap());
        return UserModel.fromMap(admin.toMap(), ref.id);
      }
    }
    return null;
  }

  /// Xuất toàn bộ collection `users` ra chuỗi JSON (chỉ 4 trường) để lưu users.json
  Future<String> exportUsersJson() async {
    final snap = await _col.get();
    final list = snap.docs
        .map((d) => UserModel.fromFirestore(d).toMap())
        .toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }
}
