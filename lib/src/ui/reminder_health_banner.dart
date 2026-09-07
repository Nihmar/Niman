/// The Todo tab's warning that reminders cannot reach the user (T-TD-07).
///
/// A scheduled reminder is silent about everything that happens after
/// scheduling: the app is usually not running when it comes due, so a
/// blocked notification or an OEM battery manager shows up only as a
/// reminder that never arrived. This says so while there is still time to
/// fix it, and (where a system screen exists) opens it.
library;

import 'dart:async';

import 'package:copist/src/todo/reminder_health.dart';
import 'package:copist/src/todo/reminders.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// A banner over the todo list describing [ReminderService.health].
///
/// Renders nothing while healthy, and nothing after the user dismisses
/// it — the state is per-mount, so it comes back next time the tab opens
/// if the problem is still there.
final class ReminderHealthBanner extends StatefulWidget {
  /// Creates the banner for [service].
  const ReminderHealthBanner({required this.service, super.key});

  /// The service whose health is reported.
  final ReminderService service;

  @override
  State<ReminderHealthBanner> createState() => _ReminderHealthBannerState();
}

final class _ReminderHealthBannerState extends State<ReminderHealthBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ReminderHealth>(
      valueListenable: widget.service.health,
      builder: (context, health, _) {
        if (health == ReminderHealth.ok || _dismissed) {
          return const SizedBox.shrink();
        }
        final scheme = Theme.of(context).colorScheme;
        return MaterialBanner(
          key: const Key('todo-reminder-health'),
          backgroundColor: scheme.errorContainer,
          leading: Icon(
            Icons.notifications_off,
            color: scheme.onErrorContainer,
          ),
          content: Text(
            _message(health),
            style: TextStyle(color: scheme.onErrorContainer),
          ),
          actions: [
            if (_fixable(health))
              TextButton(
                key: const Key('todo-reminder-health-fix'),
                onPressed: () =>
                    unawaited(widget.service.openHealthSettings()),
                child: const Text(AppStrings.todoReminderFixAction),
              ),
            TextButton(
              key: const Key('todo-reminder-health-dismiss'),
              onPressed: () => setState(() => _dismissed = true),
              child: const Text(AppStrings.todoReminderDismissAction),
            ),
          ],
        );
      },
    );
  }

  /// Whether a system screen can fix [health].
  ///
  /// Exact alarms cannot: the privilege is auto-granted, so a build that
  /// still refuses it offers no toggle either.
  static bool _fixable(ReminderHealth health) =>
      health != ReminderHealth.inexactOnly;

  static String _message(ReminderHealth health) => switch (health) {
    ReminderHealth.notificationsBlocked => AppStrings.todoReminderBlocked,
    ReminderHealth.batteryRestricted => AppStrings.todoReminderBattery,
    ReminderHealth.inexactOnly => AppStrings.todoReminderInexact,
    ReminderHealth.ok => '',
  };
}
