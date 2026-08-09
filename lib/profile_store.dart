import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileStore {
  static String _name = 'User';
  static String? _email;
  static String? _photoUrl;
  static Uint8List? _imageBytes;

  static String get name => _name;
  static String? get email => _email;
  static String? get photoUrl => _photoUrl;
  static Uint8List? get imageBytes => _imageBytes;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('profile_name') ?? 'User';
    _email = prefs.getString('profile_email');
    _photoUrl = prefs.getString('profile_photo_url');
    final imgBase64 = prefs.getString('profile_image_bytes');
    if (imgBase64 != null) {
      _imageBytes = base64Decode(imgBase64);
    }
  }

  static Future<void> save({
    required String name,
    String? email,
    String? photoUrl,
    Uint8List? imageBytes,
  }) async {
    _name = name;
    _email = email;
    _photoUrl = photoUrl;
    _imageBytes = imageBytes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    if (email != null) {
      await prefs.setString('profile_email', email);
    } else {
      await prefs.remove('profile_email');
    }
    if (photoUrl != null) {
      await prefs.setString('profile_photo_url', photoUrl);
    } else {
      await prefs.remove('profile_photo_url');
    }
    if (imageBytes != null) {
      await prefs.setString('profile_image_bytes', base64Encode(imageBytes));
    } else {
      await prefs.remove('profile_image_bytes');
    }
  }

  static Future<void> clear() async {
    _name = 'User';
    _email = null;
    _photoUrl = null;
    _imageBytes = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_name');
    await prefs.remove('profile_email');
    await prefs.remove('profile_photo_url');
    await prefs.remove('profile_image_bytes');
  }
}

