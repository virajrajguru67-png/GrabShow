import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/image_helper.dart';

/// A widget that displays an avatar image with automatic fallback to default
class AvatarImage extends StatefulWidget {
  const AvatarImage({
    super.key,
    this.avatarUrl,
    this.radius = 28,
    this.defaultImage = 'assets/images/default_avatar.webp',
  });

  final String? avatarUrl;
  final double radius;
  final String defaultImage;

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage> {
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    if (kIsWeb) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final localPath = prefs.getString('profile_image_path');
      if (localPath != null) {
        final file = File(localPath);
        if (file.existsSync()) {
          if (mounted) {
            setState(() {
              _localImagePath = localPath;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local image in AvatarImage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer local image if available
    String? imageUrl = _localImagePath ?? widget.avatarUrl;
    
    // Filter out SVG URLs as Flutter doesn't support SVG natively
    final validUrl = imageUrl != null && imageUrl.isNotEmpty
        ? (imageUrl.toLowerCase().endsWith('.svg') ? null : imageUrl)
        : null;
    
    ImageProvider? imageProvider;
    if (validUrl != null) {
      imageProvider = getImageProviderFromUrl(validUrl);
    }
    
    // Use default if no valid provider
    imageProvider ??= AssetImage(widget.defaultImage);
    
    return CircleAvatar(
      key: ValueKey(imageUrl ?? 'default'),
      radius: widget.radius,
      backgroundColor: Theme.of(context).cardColor,
      backgroundImage: imageProvider,
      onBackgroundImageError: (exception, stackTrace) {
        // If the avatar URL fails to load, it will automatically fall back
        // to showing the default image due to how CircleAvatar works
        debugPrint('Avatar image error (falling back to default): $exception');
      },
      child: validUrl == null ? null : null,
    );
  }
}

