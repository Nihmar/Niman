import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/spinning_sync_icon.dart';
import 'package:niman/src/ui/sync/sync_flow.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
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
      if (mounted) setState(() => _saving = false);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('sync-trust-dialog'),
        title: Text(AppStrings.syncCertTrustTitle),
        content: Text(AppStrings.syncCertTrustBody(result.host, fingerprint)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            key: const Key('sync-trust-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.syncCertTrustAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _trustedFingerprint = fingerprint);
    await _test();
  }

  /// Forgets the certificate trusted for this destination (#454); the
  /// destination and its password stay. Confirmed first, because the next
  /// sync will need the certificate confirmed again.
  Future<void> _forgetCertificate() async {
    final fingerprint = _sync.status.destination?.trustedCertFingerprint;
    if (fingerprint == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('sync-forget-certificate-dialog'),
        title: Text(AppStrings.syncCertForgetTitle),
        content: Text(AppStrings.syncCertForgetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            key: const Key('sync-forget-certificate-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.syncCertForgetAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _sync.forgetCertificate();
    if (mounted) setState(() => _trustedFingerprint = null);
  }

  Future<void> _setTriggers({
    bool? autoSync,
    int? intervalSeconds,
    bool? wifiOnly,
  }) async {
    try {
      await _sync.setTriggers(
        autoSync: autoSync,
        intervalSeconds: intervalSeconds,
        wifiOnly: wifiOnly,
      );
    } on Object catch (e) {
      _log.error('settings: trigger options not saved: $e');
    }
  }

  Future<void> _chooseInterval() async {
    final destination = _sync.status.destination;
    if (destination == null) return;
    final seconds = await showSettingsChoice<int>(
      context,
      dialogKey: const Key('sync-interval-dialog'),
      title: AppStrings.syncIntervalTitle,
      subtitle: AppStrings.syncIntervalDialogBody,
      current: destination.intervalSeconds,
      options: [
        for (final choice in syncIntervalChoices)
          SettingsOption(choice, syncIntervalLabel(choice)),
      ],
    );
    if (seconds != null) await _setTriggers(intervalSeconds: seconds);
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('sync-disconnect-dialog'),
        title: Text(AppStrings.syncDisconnectConfirmTitle),
        content: Text(AppStrings.syncDisconnectConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            key: const Key('sync-disconnect-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.syncDisconnectConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
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
      body: _formShown ? _form(theme) : _overview(theme),
    );
  }

  Widget _hint(ThemeData theme, IconData icon, String text, {Color? color}) {
    final tint = color ?? theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: tint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: tint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(ThemeData theme) {
    final insecure = _url.text.trim().toLowerCase().startsWith('http://');
    final result = _result;
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('sync-url'),
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: AppStrings.syncUrlLabel,
              hintText: 'https://nas.local/webdav/Notes/',
              errorText: _urlError,
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ),
        if (insecure)
          _hint(
            theme,
            Icons.lock_open,
            AppStrings.syncHttpWarning,
            color: theme.colorScheme.tertiary,
          ),
        _hint(theme, Icons.info_outline, AppStrings.syncUrlHint),
        if (_editing)
          _hint(theme, Icons.restart_alt, AppStrings.syncRetargetWarning),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('sync-user'),
            controller: _user,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: AppStrings.syncUserLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        _hint(theme, Icons.info_outline, AppStrings.syncUserHint),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('sync-password'),
            controller: _password,
            obscureText: !_showPassword,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: AppStrings.syncPasswordLabel,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? AppStrings.syncHidePassword
                    : AppStrings.syncShowPassword,
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
        ),
        _hint(
          theme,
          Icons.key,
          _configured
              ? AppStrings.syncPasswordKeepHint
              : AppStrings.syncPasswordHint,
        ),
        // Test and Save ride side by side in the form (issue #131):
        // the bottom full-width Save existed nowhere else, and both
        // buttons opened greyed with no reason in sight. Test stays
        // enabled and complains at the field; Save unlocks for the
        // tested address, next to the result card that says why.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('sync-test'),
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check),
                  label: Text(
                    _testing
                        ? AppStrings.syncTesting
                        : AppStrings.syncTestAction,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('sync-save'),
                  onPressed: _canSave ? _save : null,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(AppStrings.actionSave),
                ),
              ),
            ],
          ),
        ),
        if (result != null) _resultCard(theme, result),
      ],
    );
  }

  Widget _resultCard(ThemeData theme, SyncTestResult result) {
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final caps = result.capabilities;
    if (!result.ok || caps == null) {
      final failure = syncTestFailure(result.outcome);
      final fingerprint = result.fingerprint;
      // The fingerprint belongs to the address this result was measured
      // against. A result left over from another one still says what went
      // wrong there, but it is not offered for trust: what would be stored
      // is the certificate of an address the form no longer holds (#454).
      final trustable = fingerprint != null && _tested == _fields;
      return Card.filled(
        key: const Key('sync-test-result'),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ListTile(
          leading: Icon(failure.icon, color: scheme.error),
          title: Text(failure.title),
          subtitle: failure.hint.isEmpty && !trustable
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (failure.hint.isNotEmpty) Text(failure.hint),
                    // The certificate the user may trust, by its
                    // fingerprint, for this one destination (#454).
                    if (trustable) ...[
                      const SizedBox(height: 6),
                      SelectableText(
                        fingerprint,
                        key: const Key('sync-test-fingerprint'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FilledButton.icon(
                          key: const Key('sync-trust-certificate'),
                          onPressed: _testing
                              ? null
                              : () => _trustCertificate(result),
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(AppStrings.syncCertTrustAction),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      );
    }
    final compatible = syncIsCompatibleMode(caps);
    return Card.filled(
      key: const Key('sync-test-result'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.syncTestOk,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        AppStrings.syncTestOkSubtitle(
                          compatible
                              ? AppStrings.syncModeCompatible
                              : AppStrings.syncModeFull,
                          result.elapsedMs,
                        ),
                        style: muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final line in syncCapabilityLines(caps))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      line.has ? Icons.check : Icons.remove,
                      size: 18,
                      color: line.has
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.label),
                          if (line.detail != null)
                            Text(line.detail!, style: muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (compatible) ...[
              const SizedBox(height: 10),
              Text(AppStrings.syncCompatibleNote, style: muted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _overview(ThemeData theme) {
    final status = _sync.status;
    final destination = status.destination!;
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final caps = status.capabilities;
    final url = Uri.tryParse(destination.url);
    final shortUrl = url == null
        ? destination.url
        : '${url.host}${url.hasPort ? ':${url.port}' : ''}${url.path}';
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Card.filled(
          key: const Key('sync-overview-card'),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // A run in flight turns, here as everywhere else: a
                    // still glyph over "comparing with the server…" reads
                    // as a sync that stopped.
                    if (status.running)
                      SpinningSyncIcon(color: syncStatusColor(status, scheme))
                    else
                      Icon(
                        syncStatusIcon(status),
                        color: syncStatusColor(status, scheme),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            syncStatusLine(status, now),
                            key: const Key('sync-status-line'),
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            shortUrl,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (syncQueueLine(status, now) case final queue?) ...[
                  const SizedBox(height: 8),
                  Text(
                    queue,
                    key: const Key('sync-overview-queue'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (status.aborted != null &&
                    status.aborted != SyncAbort.notConfirmed) ...[
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.syncAbortNothingTouched,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('sync-now'),
                  onPressed: status.running ? null : _syncNow,
                  icon: status.running
                      ? SpinningSyncIcon(
                          color: scheme.onSurface.withValues(alpha: 0.38),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    status.running
                        ? AppStrings.syncRunning
                        : AppStrings.syncNowAction,
                  ),
                ),
              ],
            ),
          ),
        ),
        SettingsSection(AppStrings.syncSectionWhen),
        SettingsSwitchRow(
          key: const Key('sync-auto'),
          title: AppStrings.syncAutoTitle,
          description: AppStrings.syncAutoSubtitle,
          value: destination.autoSync,
          onChanged: (on) => _setTriggers(autoSync: on),
        ),
        SettingsValueRow(
          key: const Key('sync-interval'),
          title: AppStrings.syncIntervalTitle,
          subtitle: AppStrings.syncIntervalSubtitle,
          value: syncIntervalLabel(destination.intervalSeconds),
          enabled: destination.autoSync,
          onTap: _chooseInterval,
        ),
        if (_sync.offersWifiOnly)
          SettingsSwitchRow(
            key: const Key('sync-wifi-only'),
            title: AppStrings.syncWifiOnlyTitle,
            description: AppStrings.syncWifiOnlySubtitle,
            value: destination.wifiOnly,
            onChanged: destination.autoSync
                ? (on) => _setTriggers(wifiOnly: on)
                : null,
          ),
        SettingsSection(AppStrings.syncSectionServer),
        SettingsValueRow(
          key: const Key('sync-edit-server'),
          title: AppStrings.syncServerRow,
          subtitle: [
            if (destination.username.isNotEmpty) destination.username,
            if (caps != null && syncIsCompatibleMode(caps))
              AppStrings.syncModeCompatible
            else if (caps != null)
              AppStrings.syncModeFull,
          ].join(' · '),
          onTap: status.running ? () {} : _startEditing,
        ),
        SettingsActionRow(
          key: const Key('sync-retest'),
          enabled: !status.running,
          busy: _testing,
          title: AppStrings.syncRetestTitle,
          description: caps == null
              ? null
              : AppStrings.syncProbedAgo(historyWhen(caps.probedAt, now)),
          onTap: _retest,
        ),
        // The one certificate this destination may present, and the way
        // back out of trusting it (#454).
        if (destination.trustedCertFingerprint case final fingerprint?)
          SettingsActionRow(
            key: const Key('sync-forget-certificate'),
            enabled: !status.running,
            title: AppStrings.syncCertTrustedTitle,
            description: AppStrings.syncCertTrustedSubtitle(fingerprint),
            onTap: _forgetCertificate,
          ),
        const Divider(height: 24),
        SettingsActionRow(
          key: const Key('sync-disconnect'),
          enabled: !status.running,
          destructive: true,
          title: AppStrings.syncDisconnectTitle,
          description: AppStrings.syncDisconnectSubtitle,
          onTap: _disconnect,
        ),
      ],
    );
  }
}
