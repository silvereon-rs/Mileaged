import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

void exportJsonFile(String jsonStr, String filename) async {
  final dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(jsonStr);
}

void importJsonFile(void Function(String jsonStr) onLoaded, void Function(String error) onError) {
  onError('Import not supported on this platform without file_picker');
}

void pickImageFile(void Function(Uint8List bytes) onLoaded, void Function(String error) onError) async {
  try {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      onLoaded(bytes);
    } else {
      onError('Image selection cancelled');
    }
  } catch (e) {
    onError('Failed to pick image: ${e.toString()}');
  }
}

