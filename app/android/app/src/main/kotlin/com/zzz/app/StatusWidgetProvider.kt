package com.zzz.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import com.joo.zzz.app.R

class StatusWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val title = widgetData.getString("title", "My Partner")
                val status = widgetData.getString("status", "Waiting...")
                val updatedAt = widgetData.getString("updatedAt", "")

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_status_text, status)
                setTextViewText(R.id.widget_updated_at, updatedAt)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
