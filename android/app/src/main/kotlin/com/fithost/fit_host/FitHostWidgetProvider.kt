package com.fithost.fit_host

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class FitHostWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.fithost_widget).apply {
                val steps = widgetData.getInt("steps", 0)
                val calories = widgetData.getInt("calories", 0)
                val water = widgetData.getInt("waterGlasses", 0)

                setTextViewText(R.id.widget_steps, "$steps")
                setTextViewText(R.id.widget_calories, "$calories kcal")
                setTextViewText(R.id.widget_water, "$water glasses")

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
