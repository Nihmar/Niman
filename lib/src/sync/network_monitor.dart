import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:niman/src/core/logging.dart';

/// What the device's network allows the automatic sync to do.
enum SyncNetwork {
  /// No network at all.
  offline,

  /// Wi-Fi or Ethernet.
  unmetered,

  /// Mobile data (a VPN over it included).
  mobile,

  /// Connected some other way, or the platform cannot tell (a VPN alone,
  /// a desktop without a network manager): never blocks a sync.
  unknown,
}

/// The network as the sync scheduler sees it.
abstract interface class NetworkMonitor {
  /// The network now.
  Future<SyncNetwork> current();

  /// Every change, as it happens.
  Stream<SyncNetwork> get changes;
}

/// [NetworkMonitor] over `connectivity_plus`.
final class ConnectivityNetworkMonitor implements NetworkMonitor {
  /// The monitor for this device.
  new() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  static const _log = AppLogger(name: 'sync');

  /// The network the platform's [results] describe.
  static SyncNetwork classify(List<ConnectivityResult> results) {
    if (results.isEmpty) return SyncNetwork.unknown;
    if (results.every((r) => r == ConnectivityResult.none)) {
      return SyncNetwork.offline;
    }
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return SyncNetwork.unmetered;
    }
    if (results.contains(ConnectivityResult.mobile)) return SyncNetwork.mobile;
    return SyncNetwork.unknown;
  }

  @override
  Future<SyncNetwork> current() async {
    try {
      return classify(await _connectivity.checkConnectivity());
    } on Object catch (e) {
      _log.warning('network: cannot read the connectivity: $e');
      return SyncNetwork.unknown;
    }
  }

  @override
  Stream<SyncNetwork> get changes =>
      _connectivity.onConnectivityChanged.map(classify).handleError((Object e) {
        _log.warning('network: connectivity stream failed: $e');
      });
}
