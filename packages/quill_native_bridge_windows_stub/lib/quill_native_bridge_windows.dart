import 'package:quill_native_bridge_platform_interface/quill_native_bridge_platform_interface.dart';

/// Mobile-only stub; Windows clipboard APIs are not used on Android/iOS.
class QuillNativeBridgeWindows extends QuillNativeBridgePlatform {
  static void registerWith() {
    QuillNativeBridgePlatform.instance = QuillNativeBridgeWindows();
  }
}
