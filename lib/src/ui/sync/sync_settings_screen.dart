import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/ui/floating_window.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_flow.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
import 'package:niman/src/ui/sync/sync_overview.dart';
import 'package:niman/src/ui/sync/sync_server_form.dart';
import 'package:niman/src/ui/sync/sync_settings_dialogs.dart';
import 'package:niman/src/ui/sync/sync_test_result_card.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

const _log = AppLogger(name: 'sync');

/// The library's WebDAV settings (mockups S2–S5): the server form with its
/// connection test while nothing is configured (or while editing), the
/// status, "Sync now" and disconnect once it is.
final class SyncSettingsScreen extends StatefulWidget {
  /// The settings of [sync] for the library named [libraryName].
  const new({
    required this.sync,
    required this.libraryName,
    this.unsaved,
    this.onShowTrash,
    this.embedded = false,
    super.key,
  });

  /// The library's sync.
  final SyncService sync;

  /// Shown under the title.
  final String libraryName;

  /// Open editors to save before a sync.
  final UnsavedTracker? unsaved;

  /// Opens the trash (from the snackbar after a sync).
  final VoidCallback? onShowTrash;

  /// Whether the screen is drawn inside a floating window (#712): the
  /// window's header carries the title, so the body brings the subtitle
  /// line and no app bar.
  final bool embedded;

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

final class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();
  bool _editing = false;
  bool _showPassword = false;
  bool _testing = false;
  bool _saving = false;
  SyncTestResult? _result;

  /// The address field's error: testing needs an address first, and the
  /// field says so instead of the button greying out unexplained.
  String? _urlError;

  /// The certificate the user confirmed while setting this address up
  /// (#454), or null. Scoped to the form and the address in its field: it
  /// is dropped the moment that address changes, so a trust confirmed for
  /// one server is never offered to another, and when the form closes —
  /// saved, or the destination disconnected — so that past that point the
  /// stored destination is the only trust there is, and forgetting it
  /// there forgets it.
  String? _trustedFingerprint;

  /// The fields as they were when [_result] was measured: "Save" is only
  /// offered for what was tested.
  ({String url, String user, String password})? _tested;

  SyncService get _sync => widget.sync;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onSync);
    unawaited(_sync.load());
    _url.addListener(_onUrlField);
    _user.addListener(_onField);
    _password.addListener(_onField);
  }

  @override
  void dispose() {
    _sync.removeListener(_onSync);
    _url.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onSync() {
    if (mounted) setState(() {});
  }

  void _onField() {
    if (mounted) {
      setState(() {
        // Typing clears the address error: the complaint is answered.
        _urlError = null;
      });
    }
  }

  /// A change in the address: it also drops any certificate trust, which
  /// belongs to the address it was confirmed for and not to a new one.
  void _onUrlField() {
    if (mounted) {
      setState(() {
        _urlError = null;
        _trustedFingerprint = null;
      });
    }
  }

  bool get _configured => _sync.status.configured;

  bool get _formShown => !_configured || _editing;

  ({String url, String user, String password}) get _fields => (
    url: _url.text.trim(),
    user: _user.text.trim(),
    password: _password.text,
  );

  bool get _canSave {
    final result = _result;
    return !_saving &&
        !_testing &&
        result != null &&
        result.ok &&
        _tested == _fields;
  }

  void _startEditing() {
    final destination = _sync.status.destination;
    setState(() {
      _editing = true;
      _url.text = destination?.url ?? '';
      _user.text = destination?.username ?? '';
      _password.clear();
      _result = null;
      _tested = null;
      // After the address is set: filling the field fires [_onUrlField],
      // which would otherwise drop the trust the destination already has.
      _trustedFingerprint = destination?.trustedCertFingerprint;
    });
  }

  /// With a destination stored and the password field left empty, the
  /// test and the save use the stored password.
  String? get _typedPassword =>
      _configured && _password.text.isEmpty ? null : _password.text;

  Future<void> _test() async {
    final fields = _fields;
    if (fields.url.isEmpty) {
      setState(() => _urlError = AppStrings.syncUrlRequired);
      return;
    }
    setState(() {
      _testing = true;
      _result = null;
    });
    final result = await _sync.testConnection(
      url: fields.url,
      username: fields.user,
      password: _typedPassword,
      trustedFingerprint: _trustedFingerprint,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = result;
      _tested = fields;
    });
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null) return;
    setState(() => _saving = true);
    final fields = _fields;
    final wasConfigured = _configured;
    try {
      await _sync.save(
        url: fields.url,
        username: fields.user,
        password: _typedPassword,
        capabilities: result.capabilities,
        trustedFingerprint: _trustedFingerprint,
      );
    } on Object catch (e) {
      _log.error('settings: save failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      // Nothing was stored: the form stays, and the failure is said out
      // loud instead of leaving "Save" to be pressed over and over (#1244).
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppStrings.syncSaveFailed)));
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
      _result = null;
      _tested = null;
      _trustedFingerprint = null;
      _password.clear();
    });
    // A fresh destination goes straight to its first sync, which shows
    // its own summary before touching anything (mockup S4).
    if (!wasConfigured || _sync.status.lastSyncAt == null) {
      await _syncNow();
    }
  }

  Future<void> _syncNow() => runSyncFromUi(
    context,
    _sync,
    unsaved: widget.unsaved,
    onShowTrash: widget.onShowTrash,
  );

  Future<void> _retest() async {
    final destination = _sync.status.destination;
    if (destination == null) return;
    setState(() => _testing = true);
    final result = await _sync.testConnection(
      url: destination.url,
      username: destination.username,
      // The stored destination is the one this address is; its confirmed
      // certificate is the one this test may use (#454), and only that
      // one: a trust the form held is not the destination's.
      trustedFingerprint: destination.trustedCertFingerprint,
    );
    if (result.ok) {
      await _sync.save(
        url: destination.url,
        username: destination.username,
        capabilities: result.capabilities,
      );
    }
    if (!mounted) return;
    setState(() => _testing = false);
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(syncTestFailure(result.outcome).title)),
      );
    }
  }

  /// Confirms the certificate a failed test reported (#454): shows its
  /// fingerprint, remembers it for the address just tested, and tests
  /// again with that one certificate trusted. Nothing is stored until the
  /// destination is saved.
  Future<void> _trustCertificate(SyncTestResult result) async {
    final fingerprint = result.fingerprint;
    if (fingerprint == null) return;
    final confirmed = await confirmSyncCertificateTrust(
      context,
      host: result.host,
      fingerprint: fingerprint,
    );
    if (!confirmed || !mounted) return;
    setState(() => _trustedFingerprint = fingerprint);
    await _test();
  }

  /// Forgets the certificate trusted for this destination (#454); the
  /// destination and its password stay. Confirmed first, because the next
  /// sync will need the certificate confirmed again.
  Future<void> _forgetCertificate() async {
    final fingerprint = _sync.status.destination?.trustedCertFingerprint;
    if (fingerprint == null) return;
    if (!await confirmSyncCertificateForget(context)) return;
    await _sync.forgetCertificate();
    if (mounted) setState(() => _trustedFingerprint = null);
  }

  Future<void> _disconnect() async {
    if (!await confirmSyncDisconnect(context)) return;
    await _sync.disconnect();
    if (mounted) {
      setState(() {
        _editing = false;
        _trustedFingerprint = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = _formShown
        ? _form()
        : SyncOverview(
            sync: _sync,
            testing: _testing,
            onSyncNow: _syncNow,
            onEditServer: _startEditing,
            onRetest: _retest,
            onForgetCertificate: _forgetCertificate,
            onDisconnect: _disconnect,
          );
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              AppStrings.syncScreenSubtitle(widget.libraryName),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.syncWebDavTitle),
            Text(
              AppStrings.syncScreenSubtitle(widget.libraryName),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _form() {
    final result = _result;
    return SyncServerForm(
      url: _url,
      user: _user,
      password: _password,
      urlError: _urlError,
      editing: _editing,
      configured: _configured,
      showPassword: _showPassword,
      onToggleShowPassword: () =>
          setState(() => _showPassword = !_showPassword),
      testing: _testing,
      saving: _saving,
      onTest: _test,
      onSave: _canSave ? _save : null,
      resultCard: result == null
          ? null
          : SyncTestResultCard(
              result: result,
              current: _tested == _fields,
              onTrust: _testing ? null : () => _trustCertificate(result),
            ),
    );
  }
}

/// Opens the sync settings: a floating window where a pointer aims (#712),
/// the page a phone keeps.
Future<void> openSyncSettings(
  BuildContext context, {
  required SyncService sync,
  required String libraryName,
  UnsavedTracker? unsaved,
  VoidCallback? onShowTrash,
}) {
  if (pointerDense(Theme.of(context))) {
    return showFloatingWindow(
      context,
      title: AppStrings.syncWebDavTitle,
      panelKey: const Key('sync-settings-window'),
      builder: (context) => SyncSettingsScreen(
        sync: sync,
        libraryName: libraryName,
        unsaved: unsaved,
        onShowTrash: onShowTrash,
        embedded: true,
      ),
    );
  }
  return Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => SyncSettingsScreen(
        sync: sync,
        libraryName: libraryName,
        unsaved: unsaved,
        onShowTrash: onShowTrash,
      ),
    ),
  );
}
