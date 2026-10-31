import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  static final HomeWidgetService _instance = HomeWidgetService._internal();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._internal();

  static HomeWidgetService get instance => _instance;

  static const String androidWidgetProvider = 'FitHostWidgetProvider';
  static const String iOSWidgetProvider = 'FitHostWidget';

  /// Syncs real telemetry data to the native Android AppWidget and iOS WidgetKit
  Future<bool> syncData({
    int? steps,
    int? stepGoal,
    int? calories,
    int? waterGlasses,
    int? targetWater,
    int? streak,
  }) async {
    if (kIsWeb) return true;
    try {
      if (steps != null) await HomeWidget.saveWidgetData<int>('steps', steps);
      if (stepGoal != null) {
        await HomeWidget.saveWidgetData<int>('stepGoal', stepGoal);
      }
      if (calories != null) {
        await HomeWidget.saveWidgetData<int>('calories', calories);
      }
      if (waterGlasses != null) {
        await HomeWidget.saveWidgetData<int>('waterGlasses', waterGlasses);
      }
      if (targetWater != null) {
        await HomeWidget.saveWidgetData<int>('waterTarget', targetWater);
      }
      if (streak != null) {
        await HomeWidget.saveWidgetData<int>('streak', streak);
      }
      await HomeWidget.saveWidgetData<String>(
        'lastUpdated',
        DateFormat('hh:mm a').format(DateTime.now()),
      );

      await HomeWidget.updateWidget(
        name: androidWidgetProvider,
        iOSName: iOSWidgetProvider,
      );

      debugPrint(
        '📲 [HomeWidgetService] Synced telemetry to OS: steps=$steps, cal=$calories, water=$waterGlasses, streak=$streak',
      );
      return true;
    } catch (e) {
      debugPrint('📲 [HomeWidgetService] Widget sync error: $e');
      return false;
    }
  }
}
