import 'dart:io';

import 'package:flutter/material.dart';

import '../database/account_repository.dart';
import '../database/meya_database.dart';
import '../services/meya_account_storage.dart';
import '../services/meya_profile_service.dart';
import '../services/profile_photo_service.dart';
import '../theme/meya_theme.dart';
import 'qr_page.dart';
import 'status_page.dart';
import '../l10n/meya_strings.dart';

/// Your profile on one page: photo, name, MEYA ID and About.
class ProfilePage extends StatefulWidget {
  final MeyaDatabase database;

  const ProfilePage({super.key, required this.database});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _about = TextEditingController();

  String? _photoPath;
  int _photoVersion = 0;
  String? _usernameError;
  String _savedName = '';
  String _savedUsername = '';
  String _savedAbout = '';
  String? _identityId;
  String? _identityPublicKey;
  bool _loading = true;
  bool _saving = false;

  bool get _changed =>
      _name.text.trim() != _savedName ||
      _username.text.trim().toLowerCase() != _savedUsername ||
      _about.text.trim() != _savedAbout;

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _username, _about]) {
      controller.addListener(() => setState(() {}));
    }
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = await MeyaAccountStorage.loadUser();
    final about = await MeyaAccountStorage.loadAbout();
    final photo = await ProfilePhotoService.getPhotoPath();
    final account = await AccountRepository(widget.database).getActiveAccount();
    if (!mounted) return;
    setState(() {
      _savedName = account?.name ?? user?.name ?? '';
      _savedUsername = account?.username ?? user?.username ?? '';
      _savedAbout = about;
      _name.text = _savedName;
      _username.text = _savedUsername;
      _about.text = about;
      _photoPath = photo;
      _identityId = account?.identityId ?? account?.accountId;
      _identityPublicKey = account?.identityPublicKey;
      _loading = false;
    });
  }

  Future<void> _changePhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.tr('Take a photo')),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.tr('Choose from gallery')),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            if (_photoPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: context.meya.error),
                title: Text(
                  context.tr('Remove photo'),
                  style: TextStyle(color: context.meya.error),
                ),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    try {
      String? path = _photoPath;
      if (choice == 'camera') {
        path = await ProfilePhotoService.takePhoto() ?? path;
      } else if (choice == 'gallery') {
        path = await ProfilePhotoService.pickFromGallery() ?? path;
      } else {
        await ProfilePhotoService.removePhoto();
        path = null;
      }
      if (!mounted) return;
      // The file name stays the same, so evict the old picture from memory.
      if (path != null) await FileImage(File(path)).evict();
      setState(() {
        _photoPath = path;
        _photoVersion++;
      });
      _shareQuietly();
    } catch (error) {
      _show(context.tr('Could not change the photo: {0}', [error]));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = await MeyaAccountStorage.loadUser();
    if (user == null) {
      _show(context.tr('Your account could not be found on this device.'));
      return;
    }
    final name = _name.text.trim();
    final username = _username.text.trim().toLowerCase();
    final about = _about.text.trim();

    setState(() => _saving = true);
    final repository = AccountRepository(widget.database);
    if (username != _savedUsername) {
      final existing = await repository.getAccountByUsername(username);
      if (existing != null && existing.accountId != user.userId) {
        setState(() {
          _usernameError = context.tr('This MEYA ID is already used on this device');
          _saving = false;
        });
        _formKey.currentState!.validate();
        return;
      }
    }

    await repository.updateAccountProfile(
      accountId: user.userId,
      name: name,
      username: username,
    );
    await MeyaAccountStorage.saveUser(
      MeyaUser(userId: user.userId, name: name, username: username),
    );
    await MeyaAccountStorage.saveAbout(about);

    if (!mounted) return;
    setState(() {
      _savedName = name;
      _savedUsername = username;
      _savedAbout = about;
      _saving = false;
    });
    _show(context.tr('Profile saved.'));
    _shareQuietly();
  }

  /// Sends the updated profile to connections in the background.
  void _shareQuietly() {
    MeyaProfileService.instance.share().catchError((Object error) {
      debugPrint('MEYA profile: sharing failed ($error).');
      return 0;
    });
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openQr() {
    final identityId = _identityId;
    final identityPublicKey = _identityPublicKey;
    if (identityId == null || identityPublicKey == null || identityPublicKey.isEmpty) {
      _show(context.tr('Your MEYA identity is not ready yet.'));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MeyaQrPage(
          name: _savedName,
          username: _savedUsername,
          identityId: identityId,
          identityPublicKey: identityPublicKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.meya;
    final photoPath = _photoPath;
    final initial = _name.text.trim().isEmpty
        ? 'M'
        : _name.text.trim()[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Profile')),
        actions: [
          TextButton(
            onPressed: _changed && !_saving ? _save : null,
            child: Text(context.tr('Save')),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    Center(
                      child: Semantics(
                        button: true,
                        label: photoPath == null
                            ? context.tr('Add a profile photo')
                            : context.tr('Change profile photo'),
                        excludeSemantics: true,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _changePhoto,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                key: ValueKey(_photoVersion),
                                radius: 56,
                                backgroundColor: colors.navy,
                                foregroundImage: photoPath == null
                                    ? null
                                    : FileImage(File(photoPath)),
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    color: colors.onNavy,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colors.card,
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    size: 20,
                                    color: colors.navy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _changePhoto,
                        child: Text(photoPath == null ? context.tr('Add photo') : context.tr('Change photo')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      maxLength: 60,
                      decoration: InputDecoration(
                        labelText: context.tr('Name'),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? context.tr('Please enter your name')
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _username,
                      autocorrect: false,
                      maxLength: 32,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.tr('MEYA ID'),
                        prefixText: '@',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      onChanged: (_) {
                        if (_usernameError != null) {
                          setState(() => _usernameError = null);
                        }
                      },
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return context.tr('Please enter your MEYA ID');
                        if (text.length < 3) return context.tr('Use at least 3 characters');
                        if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(text)) {
                          return context.tr('Use letters, numbers, dots, dashes or underscores');
                        }
                        return _usernameError;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _about,
                      maxLength: 160,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: context.tr('About'),
                        hintText: context.tr('A few words about yourself'),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('Your name, photo and About are shared, end-to-end encrypted, with your MEYA connections only.'),
                      style: TextStyle(color: colors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _changed && !_saving ? _save : null,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : Text(context.tr('Save profile')),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.qr_code_2_outlined),
                            title: Text(context.tr('My QR code')),
                            subtitle: Text(context.tr('Let someone you meet connect with you')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _openQr,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.auto_awesome_outlined),
                            title: Text(context.tr('Status')),
                            subtitle: Text(context.tr('Share text, a photo or a video')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    StatusHubPage(database: widget.database),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
