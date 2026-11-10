import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model người dùng - CHỈ có đúng 4 trường dữ liệu theo đề:
/// email, matkhau, hoten, hinhanh.
/// `id` là ID của document trên Firestore (dùng để Sửa/Xóa),
/// KHÔNG phải trường dữ liệu và KHÔNG được đưa vào toMap().
class UserModel {
  final String? id;
  final String email;
  final String matkhau;
  final String hoten;
  final String hinhanh; // chuỗi Base64 của ảnh hoặc URL ảnh (rỗng nếu chưa có)

  UserModel({
    this.id,
    required this.email,
    required this.matkhau,
    required this.hoten,
    this.hinhanh = '',
  });

  /// Đọc dữ liệu từ Map + id document
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: (map['email'] ?? '').toString(),
      matkhau: (map['matkhau'] ?? '').toString(),
      hoten: (map['hoten'] ?? '').toString(),
      hinhanh: (map['hinhanh'] ?? '').toString(),
    );
  }

  /// Đọc dữ liệu trực tiếp từ DocumentSnapshot của Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return UserModel.fromMap(data, doc.id);
  }

  /// Ghi lên Firestore - CHỈ đúng 4 key
  Map<String, dynamic> toMap() => {
    'email': email,
    'matkhau': matkhau,
    'hoten': hoten,
    'hinhanh': hinhanh,
  };

  /// true nếu hinhanh là link ảnh (http/https)
  bool get isImageUrl =>
      hinhanh.startsWith('http://') || hinhanh.startsWith('https://');

  /// Giải mã Base64 (hỗ trợ cả dạng "data:image/png;base64,....")
  static Uint8List? decodeBase64(String s) {
    if (s.isEmpty) return null;
    try {
      final raw = s.contains(',') ? s.substring(s.indexOf(',') + 1) : s;
      return base64Decode(raw.trim());
    } catch (_) {
      return null;
    }
  }
}

/// Widget ảnh đại diện tròn: tự nhận diện URL (Image.network) hoặc Base64 (Image.memory).
class UserAvatar extends StatelessWidget {
  final String hinhanh;
  final double radius;
  const UserAvatar({super.key, required this.hinhanh, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final placeholder = Icon(Icons.person, size: radius);
    Widget? img;

    if (hinhanh.startsWith('http://') || hinhanh.startsWith('https://')) {
      img = Image.network(
        hinhanh,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder,
      );
    } else {
      final bytes = UserModel.decodeBase64(hinhanh);
      if (bytes != null) {
        img = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => placeholder,
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      child: img == null ? placeholder : ClipOval(child: img),
    );
  }
}
