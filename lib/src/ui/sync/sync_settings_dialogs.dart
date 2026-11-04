import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks whether to trust the certificate [host] presented, by its
/// [fingerprint] (#454). True only on a confirmation.
Future<bool> confirmSyncCertificateTrust(
  BuildContext context, {
  required String host,
  required String fingerprint,
}) => _confirm(
  context,
  dialogKey: const Key('sync-trust-dialog'),
  confirmKey: const Key('sync-trust-confirm'),
  title: AppStrings.syncCertTrustTitle,
  body: AppStrings.syncCertTrustBody(host, fingerprint),
  action: AppStrings.syncCertTrustAction,
);

/// Asks whether to forget the certificate trusted for the destination
/// (#454). True only on a confirmation.
Future<bool> confirmSyncCertificateForget(BuildContext context) => _confirm(
  context,
  dialogKey: const Key('sync-forget-certificate-dialog'),
  confirmKey: const Key('sync-forget-certificate-confirm'),
  title: AppStrings.syncCertForgetTitle,
  body: AppStrings.syncCertForgetBody,
  action: AppStrings.syncCertForgetAction,
);

/// Asks whether to disconnect the library from its destination. True only
/// on a confirmation.
Future<bool> confirmSyncDisconnect(BuildContext context) => _confirm(
  context,
  dialogKey: const Key('sync-disconnect-dialog'),
  confirmKey: const Key('sync-disconnect-confirm'),
  title: AppStrings.syncDisconnectConfirmTitle,
  body: AppStrings.syncDisconnectConfirmBody,
  action: AppStrings.syncDisconnectConfirm,
);

Future<bool> _confirm(
  BuildContext context, {
  required Key dialogKey,
  required Key confirmKey,
  required String title,
  required String body,
  required String action,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: dialogKey,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppStrings.actionCancel),
        ),
        TextButton(
          key: confirmKey,
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed == true;
}
