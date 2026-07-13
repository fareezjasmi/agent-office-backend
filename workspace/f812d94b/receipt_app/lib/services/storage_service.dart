import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class StorageService {
  static const _uuid = Uuid();

  /// Save an image file to the app's documents directory under /receipts/
  /// Returns the absolute path where the file was saved.
  static Future<String> saveImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) await receiptsDir.create(recursive: true);
    final ext = p.extension(sourcePath);
    final newName = '${_uuid.v4()}$ext';
    final newPath = '${receiptsDir.path}/$newName';
    await File(sourcePath).copy(newPath);
    return newPath;
  }

  /// Delete an image file by its path.
  static Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
