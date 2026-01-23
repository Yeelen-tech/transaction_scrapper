import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }
}
