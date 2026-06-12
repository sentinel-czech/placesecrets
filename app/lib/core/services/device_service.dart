import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';

class DeviceService {
  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(AppConstants.prefDeviceId);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(AppConstants.prefDeviceId, id);
    }
    return id;
  }
}
