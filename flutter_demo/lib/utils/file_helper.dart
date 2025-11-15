import 'dart:io';

/// Platform-agnostic file helper for mobile platforms
/// This file is only imported on non-web platforms
/// On mobile, it uses dart:io File
dynamic getFile(String path) {
  return File(path);
}
