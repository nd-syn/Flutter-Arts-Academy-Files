import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  static late Directory _tempDirectory;

  static void setMockPathProviderPlatform() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    _tempDirectory = await Directory.systemTemp.createTemp('fake_docs_');
    return _tempDirectory.path;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    _tempDirectory = await Directory.systemTemp.createTemp('fake_external_');
    return _tempDirectory.path;
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    final dir = await Directory.systemTemp.createTemp('fake_external_');
    return [dir.path];
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    _tempDirectory = await Directory.systemTemp.createTemp('fake_support_');
    return _tempDirectory.path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    _tempDirectory = await Directory.systemTemp.createTemp('fake_temp_');
    return _tempDirectory.path;
  }

  @override
  Future<String?> getLibraryPath() async {
    _tempDirectory = await Directory.systemTemp.createTemp('fake_library_');
    return _tempDirectory.path;
  }

  @override
  Future<String?> getDownloadsPath() async {
    _tempDirectory = await Directory.systemTemp.createTemp('fake_downloads_');
    return _tempDirectory.path;
  }
}
