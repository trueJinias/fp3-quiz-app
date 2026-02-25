import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  // Replace these with your actual Ad Unit IDs from AdMob Console
  
  // ANDROID IDs
  static String get androidBannerAdUnitId {
    return 'ca-app-pub-3940256099942544/6300978111'; 
  }

  // iOS IDs
  static String get iosBannerAdUnitId {
     return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
     // return 'YOUR_IOS_BANNER_AD_UNIT_ID';
  }

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return iosBannerAdUnitId;
    } else {
      return ''; 
    }
  }

  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
}
