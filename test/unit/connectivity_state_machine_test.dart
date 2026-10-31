import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/connectivity/connectivity_state_machine.dart';

void main() {
  group('connectivityStatusFor', () {
    test('reports offline when no transport or internet is available', () {
      expect(
        connectivityStatusFor(
          results: [ConnectivityResult.none],
          hasInternet: true,
        ),
        ConnectivityStatus.offline,
      );
      expect(
        connectivityStatusFor(
          results: [ConnectivityResult.wifi],
          hasInternet: false,
        ),
        ConnectivityStatus.offline,
      );
    });

    test('reports metered for a reachable mobile connection', () {
      expect(
        connectivityStatusFor(
          results: [ConnectivityResult.mobile],
          hasInternet: true,
        ),
        ConnectivityStatus.metered,
      );
    });

    test('reports online for a reachable non-metered connection', () {
      expect(
        connectivityStatusFor(
          results: [ConnectivityResult.wifi],
          hasInternet: true,
        ),
        ConnectivityStatus.online,
      );
    });
  });
}
