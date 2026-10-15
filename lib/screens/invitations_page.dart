import 'package:flutter/material.dart';

import '../database/connection_request_repository.dart';
import '../database/meya_database.dart';
import '../services/meya_connection_service.dart';
import '../services/device_identity_service.dart';
import '../l10n/meya_strings.dart';

class InvitationsPage extends StatefulWidget {
  final MeyaDatabase database;

  const InvitationsPage({super.key, required this.database});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  late final ConnectionRequestRepository _repository;
  List<ConnectionRequest> _requests = [];
  bool _loading = true;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _repository = ConnectionRequestRepository(widget.database);
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final deviceId = await DeviceIdentityService.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final requests = await _repository.getIncomingPendingRequests(deviceId);

    if (!mounted) return;
    setState(() {
      _requests = requests;
      _loading = false;
    });
  }

  Future<void> _accept(ConnectionRequest request) async {
    if (_busy.contains(request.requestId)) return;
    setState(() => _busy.add(request.requestId));

    try {
      await MeyaConnectionService.instance.acceptRequest(request.requestId);
      if (!mounted) return;
      setState(() {
        _requests.removeWhere((item) => item.requestId == request.requestId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('{0} is now a MEYA contact.', [request.senderUsername])),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not accept this request: {0}', [error]))),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(request.requestId));
    }
  }

  Future<void> _decline(ConnectionRequest request) async {
    if (_busy.contains(request.requestId)) return;
    setState(() => _busy.add(request.requestId));

    try {
      await MeyaConnectionService.instance.declineRequest(request.requestId);
      if (!mounted) return;
      setState(() {
        _requests.removeWhere((item) => item.requestId == request.requestId);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Could not decline this request: {0}', [error]))),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(request.requestId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Invitations'))),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRequests,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _requests.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 80, 28, 32),
                  children: [
                    Icon(Icons.person_add_alt_1_outlined, size: 56),
                    SizedBox(height: 18),
                    Text(
                      context.tr('No pending invitations'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      context.tr('Connection requests from people you trust will appear here.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  itemCount: _requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    final busy = _busy.contains(request.requestId);
                    final displayName = request.senderUsername;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  child: Text(
                                    displayName.isEmpty
                                        ? 'M'
                                        : displayName[0].toUpperCase(),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.tr('Wants to connect with you on MEYA.'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: busy
                                        ? null
                                        : () => _decline(request),
                                    child: Text(context.tr('Decline')),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: busy
                                        ? null
                                        : () => _accept(request),
                                    child: busy
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(context.tr('Accept')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
