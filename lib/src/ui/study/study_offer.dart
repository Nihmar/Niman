import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';

/// After a deck is made (#533, decision 1): offers, once, to show Study in
/// the navigation, where it starts hidden.
///
/// Once means while the layout has never placed Study: the offer writes it
/// in, hidden, and **Show** turns it on. A layout that places it already —
/// shown, hidden by hand, offered before — is not asked again, so the offer
/// needs no setting of its own.
Future<void> offerStudy(BuildContext context, LibrarySession session) async {
  final ops = session.ops;
  if (ops == null) return;
  final navigation = await ops.navigation;
  final onDevice = navigation.device != null;
  final layout =
      navigation.device ?? navigation.library ?? const NavigationLayout();
  if (layout.order.contains(_study)) return;
  final placed = placedDestinations(layout);
  NavigationLayout withStudy({required bool hidden}) => layout.keep([
    for (final p in placed)
      (
        name: p.destination.name,
        hidden: p.destination.name == _study ? hidden : p.hidden,
      ),
  ]);
  await ops.setNavigation(withStudy(hidden: true), onDevice: onDevice);
  session.notify();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('study-offer'),
      // An action would keep it up until it is dismissed by hand.
      persist: false,
      content: Text(AppStrings.studyOfferBody),
      action: SnackBarAction(
        key: const Key('study-offer-show'),
        label: AppStrings.studyOfferAction,
        onPressed: () async {
          await ops.setNavigation(withStudy(hidden: false), onDevice: onDevice);
          session.notify();
        },
      ),
    ),
  );
}

const String _study = 'study';
