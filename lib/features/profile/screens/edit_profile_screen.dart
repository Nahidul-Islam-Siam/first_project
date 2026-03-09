import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;

  String? _photoBase64;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: profileNameNotifier.value);
    _locationController = TextEditingController(
      text: profileLocationNotifier.value,
    );
    _photoBase64 = profilePhotoBase64Notifier.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Uint8List? _decodePhoto(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  InputDecoration _fieldDecoration({
    required NoorifyGlassTheme glass,
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: glass.textMuted),
      hintText: hint,
      hintStyle: TextStyle(color: glass.textSecondary),
      filled: true,
      fillColor: glass.isDark
          ? const Color(0x3F122634)
          : const Color(0xECFFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: glass.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: glass.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: glass.accent.withValues(alpha: 0.75),
          width: 1.4,
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 720,
      maxHeight: 720,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _photoBase64 = base64Encode(bytes));
  }

  void _removePhoto() {
    setState(() => _photoBase64 = null);
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    if (location.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location is required')));
      return;
    }

    setState(() => _isSaving = true);
    profileNameNotifier.value = name;
    profileLocationNotifier.value = location;
    profilePhotoBase64Notifier.value = _photoBase64;
    await saveAppPreferences();
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final photoBytes = _decodePhoto(_photoBase64);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Row(
                  children: [
                    Material(
                      color: glass.isDark
                          ? const Color(0x332EB8E6)
                          : const Color(0x221EA8B8),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: glass.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: glass.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                  child: NoorifyGlassCard(
                    radius: BorderRadius.circular(18),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: glass.isDark
                                  ? const Color(0xFF2A3A4A)
                                  : const Color(0xFFD9DEE3),
                              backgroundImage: photoBytes == null
                                  ? null
                                  : MemoryImage(photoBytes),
                              child: photoBytes == null
                                  ? Icon(
                                      Icons.person,
                                      size: 46,
                                      color: glass.textSecondary,
                                    )
                                  : null,
                            ),
                            InkWell(
                              onTap: _pickPhoto,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: glass.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: glass.isDark
                                      ? const Color(0xFF072734)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickPhoto,
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                              ),
                              label: const Text('Choose Photo'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: glass.textPrimary,
                                side: BorderSide(color: glass.glassBorder),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _removePhoto,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Remove'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: glass.textPrimary,
                                side: BorderSide(color: glass.glassBorder),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: glass.textPrimary),
                          decoration: _fieldDecoration(
                            glass: glass,
                            label: 'Full Name',
                            hint: 'Enter your name',
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _locationController,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(color: glass.textPrimary),
                          decoration: _fieldDecoration(
                            glass: glass,
                            label: 'Location',
                            hint: 'Example: Sylhet, Bangladesh',
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            backgroundColor: glass.accent,
                            foregroundColor: glass.isDark
                                ? const Color(0xFF072734)
                                : Colors.white,
                          ),
                          onPressed: _isSaving ? null : _saveChanges,
                          child: _isSaving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: glass.isDark
                                        ? const Color(0xFF072734)
                                        : Colors.white,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
