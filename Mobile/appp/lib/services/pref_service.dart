import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PrefService {
  static Future<void> setKeepSignedIn(bool value) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/keep_signed_in.txt');
      await file.writeAsString(value ? 'true' : 'false');
    } catch (_) {}
  }

  static Future<bool> getKeepSignedIn() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/keep_signed_in.txt');
      if (await file.exists()) {
        final val = await file.readAsString();
        return val.trim() == 'true';
      }
    } catch (_) {}
    return true; // Default to true
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/notifications_enabled.txt');
      await file.writeAsString(value ? 'true' : 'false');
    } catch (_) {}
  }

  static Future<bool> getNotificationsEnabled() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/notifications_enabled.txt');
      if (await file.exists()) {
        final val = await file.readAsString();
        return val.trim() == 'true';
      }
    } catch (_) {}
    return true; // Default to true
  }
}
