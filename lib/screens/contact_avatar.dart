import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/meya_message_service.dart';
import '../services/meya_profile_service.dart';

/// A contact's round picture: the photo they shared, or their initial.
/// Updates by itself when they share a new photo.
class ContactAvatar extends StatefulWidget {
  final String contactId;
  final String name;
  final double radius;

  const ContactAvatar({
    super.key,
    required this.contactId,
    required this.name,
    this.radius = 24,
  });

  @override
  State<ContactAvatar> createState() => _ContactAvatarState();
}

class _ContactAvatarState extends State<ContactAvatar> {
  Uint8List? _photo;
  final List<StreamSubscription<String>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _load();
    _subscriptions
      ..add(MeyaProfileService.instance.changes.listen((contactId) {
        if (contactId == widget.contactId) _load();
      }))
      // A photo whose pieces were still arriving.
      ..add(MeyaMessageService.instance.mediaArrived.listen((_) {
        if (_photo == null) _load();
      }));
  }

  @override
  void didUpdateWidget(ContactAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contactId != widget.contactId) {
      _photo = null;
      _load();
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final photo = await MeyaProfileService.instance.photoOf(widget.contactId);
    if (mounted && !identical(photo, _photo)) setState(() => _photo = photo);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = widget.name.trim();
    final photo = _photo;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      foregroundImage: photo == null ? null : MemoryImage(photo),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: widget.radius * 0.75,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
