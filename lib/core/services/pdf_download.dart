/// PDF download platform interface
/// Exports platform-specific implementation based on compilation target

export 'pdf_download_stub.dart' if (dart.library.html) 'pdf_download_web.dart';
