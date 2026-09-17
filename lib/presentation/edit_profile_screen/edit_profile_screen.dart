import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  bool _isSaving = false;

  XFile? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _nameController = TextEditingController(text: appState.userName);
    _phoneController = TextEditingController(text: appState.userPhone);
    _cityController = TextEditingController(text: appState.userCity);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image != null) {
        setState(() => _pickedImageFile = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open gallery. Please try again.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? newAvatarUrl;

      // Upload avatar to Supabase Storage if a new image was picked
      if (_pickedImageFile != null) {
        newAvatarUrl = await SupabaseService.instance.uploadAvatar(
          _pickedImageFile!,
        );
      }

      final appState = context.read<AppState>();
      final success = await appState.saveProfileToSupabase(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile updated successfully!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile. Please try again.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An error occurred. Please try again.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAvatarPreview(AppState appState) {
    // Priority: locally picked > Supabase avatar_url > local path > initial letter
    if (_pickedImageFile != null) {
      final bool isWebBlobOrNetwork =
          kIsWeb ||
          _pickedImageFile!.path.startsWith('http://') ||
          _pickedImageFile!.path.startsWith('https://') ||
          _pickedImageFile!.path.startsWith('blob:');

      return ClipOval(
        child: isWebBlobOrNetwork
            ? Image.network(
                _pickedImageFile!.path,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialAvatar(appState),
              )
            : Image.file(
                File(_pickedImageFile!.path),
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialAvatar(appState),
              ),
      );
    }

    final effectiveUrl = appState.effectiveProfileImageUrl;
    if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      final bool isNetworkUrl =
          effectiveUrl.startsWith('http://') ||
          effectiveUrl.startsWith('https://') ||
          effectiveUrl.startsWith('blob:');

      if (isNetworkUrl) {
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: effectiveUrl,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialAvatar(appState),
            errorWidget: (_, __, ___) => _initialAvatar(appState),
          ),
        );
      } else if (!kIsWeb) {
        return ClipOval(
          child: Image.file(
            File(effectiveUrl),
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialAvatar(appState),
          ),
        );
      }
    }

    return _initialAvatar(appState);
  }

  Widget _initialAvatar(AppState appState) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        color: AppTheme.tealAccent,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          appState.userName.isNotEmpty
              ? appState.userName[0].toUpperCase()
              : 'M',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryNavy,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImageFromGallery,
                          child: Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.tealAccent.withAlpha(100),
                                    width: 3,
                                  ),
                                ),
                                child: _buildAvatarPreview(appState),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppTheme.tealAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap camera icon to select photo from gallery',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_pickedImageFile != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '✓ New photo selected',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Name field
                  _buildLabel('Full Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppTheme.inputTextColor(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: AppTheme.tealAccent,
                        size: 20,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Phone field
                  _buildLabel('Phone Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppTheme.inputTextColor(context),
                    ),
                    decoration: InputDecoration(
                      hintText: '+91 XXXXX XXXXX',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: AppTheme.tealAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // City field
                  _buildLabel('City / Location'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cityController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppTheme.inputTextColor(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Satna, Madhya Pradesh',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.tealAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
