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
    required int steps,
    required int stepGoal,
    required int calories,
    required int waterGlasses,
    required int targetWater,
    int streak = 1,
  }) async {
    if (kIsWeb) return true;
    try {
      await HomeWidget.saveWidgetData<int>('steps', steps);
      await HomeWidget.saveWidgetData<int>('stepGoal', stepGoal);
      await HomeWidget.saveWidgetData<int>('calories', calories);
      await HomeWidget.saveWidgetData<int>('waterGlasses', waterGlasses);
      await HomeWidget.saveWidgetData<int>('waterTarget', targetWater);
      await HomeWidget.saveWidgetData<int>('streak', streak);
      await HomeWidget.saveWidgetData<String>(
        'lastUpdated',
        DateFormat('hh:mm a').format(DateTime.now()),
      );

      await HomeWidget.updateWidget(
        name: androidWidgetProvider,
        iOSName: iOSWidgetProvider,
      );

      debugPrint(
        '📲 [HomeWidgetService] Synced telemetry to OS: $steps steps, $calories kcal, $waterGlasses water, streak: $streak',
      );
      return true;
    } catch (e) {
      debugPrint('📲 [HomeWidgetService] Widget sync error: $e');
      return false;
    }
  }
}
