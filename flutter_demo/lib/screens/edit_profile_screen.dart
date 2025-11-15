import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/auth_controller.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../utils/image_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const route = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _avatarUrl;
  File? _pickedImage;
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Try to load data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadUserData();
      _isInitialized = true;
    }
  }

  Future<void> _loadUserData() async {
    final user = context.read<AuthController>().user;
    if (user != null) {
      // Always update the fields
      _nameController.text = user.displayName;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
      _avatarUrl = user.avatarUrl;

      // Also check for locally saved image
      if (!kIsWeb) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final localImagePath = prefs.getString('profile_image_path');
          if (localImagePath != null) {
            final file = File(localImagePath);
            if (file.existsSync()) {
              _avatarUrl = localImagePath;
              _pickedImage = file;
            }
          }
        } catch (e) {
          debugPrint('Error loading local image: $e');
        }
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<String?> _saveImageLocally(File imageFile) async {
    try {
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/profile_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'avatar_$timestamp.jpg';
      final savedImage = File('${imageDir.path}/$fileName');
      
      // Copy the image to the app's directory
      await imageFile.copy(savedImage.path);
      
      // Save the path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', savedImage.path);
      
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // If user picked an image, save it locally
    String? finalAvatarUrl = _avatarUrl;
    if (_pickedImage != null && !kIsWeb) {
      // Save the image locally and use the file path
      final savedPath = await _saveImageLocally(_pickedImage!);
      if (savedPath != null) {
        // Use the local file path as the avatar URL
        // This will be displayed using FileImage
        finalAvatarUrl = savedPath;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image saved successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save image. Using current avatar.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else if (_pickedImage != null && kIsWeb) {
      // On web, we can't save files locally, so keep using the URL
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected. Note: Full upload requires backend support.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // Ensure we don't save SVG URLs - convert to PNG if it's SVG
    if (finalAvatarUrl != null && finalAvatarUrl.toLowerCase().endsWith('.svg')) {
      // If it's an SVG URL, generate a PNG avatar instead
      _generateRandomAvatar();
      finalAvatarUrl = _avatarUrl;
    }

    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthController>();
      await auth.updateProfile(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        avatarUrl: finalAvatarUrl,
      );

      if (!mounted) return;

      if (auth.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage ?? 'Failed to update profile')),
        );
        setState(() => _isSaving = false);
        return;
      }

      // Reset saving state
      setState(() => _isSaving = false);

      // Wait for AuthController to finish updating
      if (auth.status == AuthStatus.authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );

        // Wait a frame to ensure state is updated before popping
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (!mounted) return;
        // Pop back to profile screen
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else {
        // If status is not authenticated, wait a bit and check again
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        
        if (auth.status == AuthStatus.authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated, but please refresh to see changes')),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't update state in build method - let didChangeDependencies handle it
    // This prevents flickering from unnecessary rebuilds

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary),
        ),
        title: const Text('Edit profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _buildAvatarCircle(),
              ),
              const SizedBox(height: 32),
              Text(
                'Personal information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              AppInput(
                controller: _nameController,
                label: 'Full name',
                hintText: 'Enter your full name',
                leading: const Icon(Icons.person_outline_rounded),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _emailController,
                label: 'Email address',
                hintText: 'Enter your email',
                leading: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email typically can't be changed
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                controller: _phoneController,
                label: 'Mobile number',
                hintText: 'Enter your mobile number',
                leading: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    // Basic phone validation
                    final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{1,4}[)]?[-\s]?[(]?[0-9]{1,4}[)]?[-\s]?[0-9]{1,9}$');
                    if (!phoneRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _isSaving ? 'Saving...' : 'Save changes',
                onPressed: _isSaving ? null : _saveProfile,
                fullWidth: true,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        setState(() {
          if (kIsWeb) {
            // On web, we can't use File, so we'll use the path as URL
            // In a real app, you'd upload the image and get a URL
            _avatarUrl = image.path;
            _pickedImage = null;
          } else {
            _pickedImage = File(image.path);
            _avatarUrl = null; // Clear URL when using local image
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera is not available on web. Please use gallery or random avatar.')),
        );
      }
      return;
    }
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
          _avatarUrl = null; // Clear URL when using local image
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _viewPhoto() {
    if (!mounted) return;
    
    ImageProvider? imageProvider;
    if (_pickedImage != null && !kIsWeb) {
      imageProvider = FileImage(_pickedImage!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      // Filter out SVG URLs
      if (!_avatarUrl!.toLowerCase().endsWith('.svg')) {
        imageProvider = getImageProviderFromUrl(_avatarUrl);
      }
    }
    
    if (imageProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photo to view')),
      );
      return;
    }
    
    final screenSize = MediaQuery.of(context).size;
    final maxSize = screenSize.width < screenSize.height 
        ? screenSize.width * 0.9 
        : screenSize.height * 0.8;
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Container(
                  width: maxSize,
                  height: maxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: imageProvider!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: AppColors.textSecondary,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateRandomAvatar() {
    // Generate a random avatar using DiceBear API (using PNG format)
    final randomSeed = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _avatarUrl = 'https://api.dicebear.com/7.x/avataaars/png?seed=$randomSeed&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
      _pickedImage = null; // Clear picked image when using URL
    });
  }

  Future<void> _showImagePickerOptions() async {
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            if (_avatarUrl != null || _pickedImage != null)
              ListTile(
                leading: const Icon(Icons.visibility, color: AppColors.accent),
                title: const Text('View Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _viewPhoto();
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.accent),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.accent),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: AppColors.accent),
              title: const Text('Generate Random Avatar'),
              onTap: () {
                Navigator.pop(context);
                _generateRandomAvatar();
              },
            ),
            if (_avatarUrl != null || _pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Remove Avatar'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _avatarUrl = null;
                    _pickedImage = null;
                  });
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle() {
    // Determine the image provider to use
    ImageProvider? imageProvider;
    
    // Filter out SVG URLs
    final validUrl = _avatarUrl != null && _avatarUrl!.isNotEmpty
        ? (_avatarUrl!.toLowerCase().endsWith('.svg') ? null : _avatarUrl)
        : null;
    
    if (_pickedImage != null && !kIsWeb) {
      // Use picked local image (not available on web)
      imageProvider = FileImage(_pickedImage!);
    } else if (validUrl != null) {
      // Use URL image (only if not SVG)
      imageProvider = getImageProviderFromUrl(validUrl);
    }
    
    // Use default if no provider or provider is null
    imageProvider ??= const AssetImage('assets/images/default_avatar.webp');

    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.surface,
            backgroundImage: imageProvider,
            onBackgroundImageError: (exception, stackTrace) {
              // Just log the error, don't trigger rebuilds
              debugPrint('Avatar image error: $exception');
            },
            child: null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
