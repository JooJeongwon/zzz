package com.zzz.android.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.Toast
import com.zzz.android.R
import com.zzz.android.data.remote.dto.UserStatusUpdateRequest
import com.zzz.android.di.NetworkModule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class StatusWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_UPDATE_STATUS = "com.zzz.android.widget.UPDATE_STATUS"
        const val EXTRA_STATUS = "com.zzz.android.widget.STATUS"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_UPDATE_STATUS) {
            val status = intent.getStringExtra(EXTRA_STATUS)
            if (status != null) {
                updateStatus(context, status)
            }
        }
    }

    private fun updateStatus(context: Context, status: String) {
        val goAsync = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val api = NetworkModule.provideUserApi(context.applicationContext)
                val response = api.updateStatus(UserStatusUpdateRequest(status))
                withContext(Dispatchers.Main) {
                    if (response.isSuccessful) {
                        Toast.makeText(context, "Status: $status", Toast.LENGTH_SHORT).show()
                        // Update UI text to reflect change (Optional, complex for simple widget without local storage)
                        updateAllWidgets(context, status)
                    } else {
                        Toast.makeText(context, "Failed: ${response.code()}", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(context, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            } finally {
                goAsync.finish()
            }
        }
    }

    private fun updateAllWidgets(context: Context, statusText: String) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, StatusWidgetProvider::class.java))
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_status)
            views.setTextViewText(R.id.widget_status_text, "Current: $statusText")
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_status)

        views.setOnClickPendingIntent(R.id.btn_status_online, getPendingIntent(context, "ONLINE"))
        views.setOnClickPendingIntent(R.id.btn_status_sleep, getPendingIntent(context, "SLEEP"))
        views.setOnClickPendingIntent(R.id.btn_status_study, getPendingIntent(context, "STUDY"))
        views.setOnClickPendingIntent(R.id.btn_status_busy, getPendingIntent(context, "BUSY"))

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getPendingIntent(context: Context, status: String): PendingIntent {
        val intent = Intent(context, StatusWidgetProvider::class.java).apply {
            action = ACTION_UPDATE_STATUS
            putExtra(EXTRA_STATUS, status)
        }
        return PendingIntent.getBroadcast(
            context,
            status.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
