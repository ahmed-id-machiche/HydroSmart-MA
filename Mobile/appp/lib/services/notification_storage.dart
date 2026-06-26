import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NotificationStorage {
  static const String _filename = "read_notifications.json";

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$_filename");
  }

  static Future<List<String>> getReadIds() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> json = jsonDecode(contents);
      return json.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> markAsRead(String id) async {
    try {
      final file = await _getFile();
      final ids = await getReadIds();
      if (!ids.contains(id)) {
        ids.add(id);
        await file.writeAsString(jsonEncode(ids));
      }
    } catch (_) {}
  }

  static Future<void> markAllAsRead(List<String> idsToMark) async {
    try {
      final file = await _getFile();
      final ids = await getReadIds();
      for (final id in idsToMark) {
        if (!ids.contains(id)) {
          ids.add(id);
        }
      }
      await file.writeAsString(jsonEncode(ids));
    } catch (_) {}
  }
}
