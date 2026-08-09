import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

const _backupFileName = 'mileaged_backup.json';

class DriveSync {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Sign in silently (if previously signed in) or interactively.
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      // Try silent sign-in first
      var account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Check if signed in
  static Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// Upload backup JSON to Google Drive appDataFolder
  static Future<bool> uploadBackup(String jsonStr) async {
    try {
      final account = _googleSignIn.currentUser ?? await signIn();
      if (account == null) return false;

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      final driveApi = drive.DriveApi(httpClient);

      // Check if backup file already exists
      final existingFileId = await _findBackupFileId(driveApi);

      final media = drive.Media(
        Stream.value(utf8.encode(jsonStr)),
        utf8.encode(jsonStr).length,
      );

      if (existingFileId != null) {
        // Update existing file
        await driveApi.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
      } else {
        // Create new file in appDataFolder
        final file = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        await driveApi.files.create(file, uploadMedia: media);
      }

      httpClient.close();
      return true;
    } catch (e) {
      debugPrint('Drive upload error: $e');
      return false;
    }
  }

  /// Download backup JSON from Google Drive appDataFolder
  static Future<String?> downloadBackup() async {
    try {
      final account = _googleSignIn.currentUser ?? await signIn();
      if (account == null) return null;

      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return null;

      final driveApi = drive.DriveApi(httpClient);

      final fileId = await _findBackupFileId(driveApi);
      if (fileId == null) {
        httpClient.close();
        return null; // No backup found
      }

      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      httpClient.close();
      return utf8.decode(bytes);
    } catch (e) {
      debugPrint('Drive download error: $e');
      return null;
    }
  }

  /// Find the backup file ID in appDataFolder
  static Future<String?> _findBackupFileId(drive.DriveApi driveApi) async {
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
      $fields: 'files(id, name)',
    );
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id;
    }
    return null;
  }
}

