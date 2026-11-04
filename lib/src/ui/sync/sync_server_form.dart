import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The WebDAV server form of the sync settings (mockups S2–S3): address,
/// user and password with their hints, "Test" and "Save" side by side,
/// and the test's result under them.
final class SyncServerForm extends StatelessWidget {
  /// The form over the given fields.
  const new({
    required this.url,
    required this.user,
    required this.password,
    required this.urlError,
    required this.editing,
    required this.configured,
    required this.showPassword,
    required this.onToggleShowPassword,
    required this.testing,
    required this.saving,
    required this.onTest,
    required this.onSave,
    required this.resultCard,
    super.key,
  });

  /// The address field.
  final TextEditingController url;

  /// The user field.
  final TextEditingController user;

  /// The password field.
  final TextEditingController password;

  /// The address field's error, or null.
  final String? urlError;

  /// Whether a stored destination is being edited: changing it retargets
  /// the library.
  final bool editing;

  /// Whether a destination is stored: an empty password keeps its own.
  final bool configured;

  /// Whether the password is shown in clear.
  final bool showPassword;

  /// Shows or hides the password.
  final VoidCallback onToggleShowPassword;

  /// Whether a connection test runs.
  final bool testing;

  /// Whether the destination is being saved.
  final bool saving;

  /// Tests the connection.
  final VoidCallback onTest;

  /// Saves the destination; null while it cannot be saved.
  final VoidCallback? onSave;

  /// The last test's result, or null.
  final Widget? resultCard;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insecure = url.text.trim().toLowerCase().startsWith('http://');
    final resultCard = this.resultCard;
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('sync-url'),
            controller: url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: AppStrings.syncUrlLabel,
              hintText: 'https://nas.local/webdav/Notes/',
              errorText: urlError,
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
        if (editing)
          _hint(theme, Icons.restart_alt, AppStrings.syncRetargetWarning),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('sync-user'),
            controller: user,
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
            controller: password,
            obscureText: !showPassword,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: AppStrings.syncPasswordLabel,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: showPassword
                    ? AppStrings.syncHidePassword
                    : AppStrings.syncShowPassword,
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onToggleShowPassword,
              ),
            ),
          ),
        ),
        _hint(
          theme,
          Icons.key,
          configured
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
                  onPressed: testing ? null : onTest,
                  icon: testing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check),
                  label: Text(
                    testing
                        ? AppStrings.syncTesting
                        : AppStrings.syncTestAction,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('sync-save'),
                  onPressed: onSave,
                  icon: saving
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
        ?resultCard,
      ],
    );
  }
}
