import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'file_helper.dart' if (dart.library.html) 'file_helper_web.dart';

/// Helper to get ImageProvider from XFile, works on both web and mobile
ImageProvider? getImageProviderFromXFile(XFile? xFile) {
  if (xFile == null) return null;
  
  if (kIsWeb) {
    // On web, XFile.path is a blob URL that can be used with NetworkImage
    return NetworkImage(xFile.path);
  } else {
    // On mobile, use FileImage with dart:io File
    return FileImage(getFile(xFile.path));
  }
}

/// Helper to pad base64 string to make it a multiple of 4
String _padBase64(String base64) {
  final remainder = base64.length % 4;
  if (remainder == 0) return base64;
  return base64 + '=' * (4 - remainder);
}

/// Helper to clean base64 string by removing all invalid characters
String _cleanBase64(String base64) {
  // Remove all whitespace characters (spaces, tabs, newlines, etc.)
  base64 = base64.replaceAll(RegExp(r'\s'), '');
  // Remove any characters that are not valid base64 characters
  // Base64 uses: A-Z, a-z, 0-9, +, /, and = for padding
  base64 = base64.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
  return base64;
}

/// Helper to get ImageProvider from URL string (supports both HTTP URLs and data URLs)
ImageProvider? getImageProviderFromUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  
  // Check if it's a local file path (starts with / and doesn't start with http)
  if (!kIsWeb && url.startsWith('/') && !url.startsWith('http')) {
    try {
      final file = File(url);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (e) {
      debugPrint('Error loading local file: $e');
    }
  }
  
  // Check if it's a data URL (data:image/...;base64,...)
  if (url.startsWith('data:image/')) {
    // Check if the data URL appears to be truncated (common issue with VARCHAR(191) limits)
    // A complete base64 image should be much longer than 191 characters
    if (url.length <= 191) {
      debugPrint('Warning: Data URL appears truncated (length: ${url.length}). Please re-upload the image.');
      return null; // Return null to show fallback (initials)
    }
    
    // On web, try using NetworkImage directly with the data URL first
    // Browsers can handle data URLs natively, which is more reliable
    if (kIsWeb) {
      try {
        // Use NetworkImage directly - browsers handle data URLs natively
        return NetworkImage(url);
      } catch (e) {
        debugPrint('Error using NetworkImage with data URL: $e');
        // Fall through to try MemoryImage approach
      }
    }
    
    // For mobile or if NetworkImage fails on web, decode to bytes
    try {
      // Extract the base64 part after the comma
      final commaIndex = url.indexOf(',');
      if (commaIndex == -1) return null;
      
      var base64String = url.substring(commaIndex + 1);
      // Clean the base64 string - remove all invalid characters
      base64String = _cleanBase64(base64String);
      
      // Validate base64 string length (should be a multiple of 4 after cleaning)
      if (base64String.isEmpty) {
        debugPrint('Warning: Base64 string is empty after cleaning.');
        return null;
      }
      
      // Pad the base64 string if needed (but preserve existing padding)
      // Only pad if the string doesn't already end with padding
      if (!base64String.endsWith('=')) {
        base64String = _padBase64(base64String);
      }
      
      // Try to decode the base64 string
      final bytes = base64Decode(base64String);
      
      // Validate that we got some bytes
      if (bytes.isEmpty) {
        debugPrint('Warning: Decoded bytes are empty.');
        return null;
      }
      
      // Use MemoryImage for mobile or as fallback
      return MemoryImage(Uint8List.fromList(bytes));
    } catch (e) {
      debugPrint('Error decoding data URL: $e');
      debugPrint('URL length: ${url.length}');
      if (url.length > 50) {
        debugPrint('URL preview: ${url.substring(0, 50)}...');
      }
      final commaIndex = url.indexOf(',');
      if (commaIndex != -1) {
        debugPrint('Base64 string length: ${url.substring(commaIndex + 1).length}');
      }
      debugPrint('This data URL may be corrupted or truncated. Please re-upload your profile photo.');
      return null;
    }
  }
  
  // Regular HTTP/HTTPS URL
  return NetworkImage(url);
}
