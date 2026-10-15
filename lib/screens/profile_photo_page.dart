import 'dart:io';

import 'package:flutter/material.dart';

import '../services/profile_photo_service.dart';
import '../theme/meya_theme.dart';

class ProfilePhotoPage extends StatefulWidget {
  const ProfilePhotoPage({super.key});

  @override
  State<ProfilePhotoPage> createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends State<ProfilePhotoPage> {
  String? _photoPath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final path = await ProfilePhotoService.getPhotoPath();

    if (!mounted) {
      return;
    }

    setState(() {
      _photoPath = path;
      _loading = false;
    });
  }

  Future<void> _chooseFromGallery() async {
    final path = await ProfilePhotoService.pickFromGallery();

    if (!mounted || path == null) {
      return;
    }

    setState(() {
      _photoPath = path;
    });
  }

  Future<void> _takePhoto() async {
    final path = await ProfilePhotoService.takePhoto();

    if (!mounted || path == null) {
      return;
    }

    setState(() {
      _photoPath = path;
    });
  }

  Future<void> _removePhoto() async {
    setState(() {
      _saving = true;
    });

    await ProfilePhotoService.removePhoto();

    if (!mounted) {
      return;
    }

    setState(() {
      _photoPath = null;
      _saving = false;
    });
  }

  Future<void> _saveAndClose() async {
    setState(() {
      _saving = true;
    });

    if (!mounted) {
      return;
    }

    Navigator.pop(context, _photoPath);
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile photo',
                  style: TextStyle(
                    color: context.meya.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take a photo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.meya.navy,
                      foregroundColor: context.meya.onNavy,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _chooseFromGallery();
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose from gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.meya.navy,
                      minimumSize: const Size.fromHeight(54),
                      side: BorderSide(color: context.meya.navy),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                if (_photoPath != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _removePhoto();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove photo'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.meya.navy,
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoPreview() {
    if (_photoPath == null) {
      return Semantics(
        label: 'No profile photo selected',
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: context.meya.navy,
            borderRadius: BorderRadius.circular(56),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_outline,
            color: context.meya.onNavy,
            size: 82,
          ),
        ),
      );
    }

    return Semantics(
      label: 'Current profile photo',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(56),
        child: Image.file(
          File(_photoPath!),
          width: 180,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: context.meya.navy,
                borderRadius: BorderRadius.circular(56),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_outline,
                color: context.meya.onNavy,
                size: 82,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile photo'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveAndClose,
            child: const Text('Done'),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: context.meya.navy))
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                children: [
                  Text(
                    'Your profile photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.meya.text,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose a photo that people in your private MEYA space can recognize you by.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.meya.muted,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Center(child: _buildPhotoPreview()),
                  const SizedBox(height: 28),
                  Semantics(
                    button: true,
                    label: _photoPath == null
                        ? 'Add profile photo'
                        : 'Change profile photo',
                    hint: 'Opens options to take a photo or choose one',
                    child: SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _showPhotoOptions,
                        icon: Icon(
                          _photoPath == null
                              ? Icons.add_a_photo_outlined
                              : Icons.edit_outlined,
                        ),
                        label: Text(
                          _photoPath == null
                              ? 'Add Profile Photo'
                              : 'Change Profile Photo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.meya.navy,
                          foregroundColor: context.meya.onNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_photoPath != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      button: true,
                      label: 'Remove profile photo',
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _removePhoto,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text(
                          'Remove Profile Photo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.meya.navy,
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: context.meya.navy),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.meya.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline, color: context.meya.navy, size: 24),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Your profile photo is stored locally in MEYA on this device. It is not uploaded by this feature.',
                            style: TextStyle(
                              color: context.meya.muted,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
