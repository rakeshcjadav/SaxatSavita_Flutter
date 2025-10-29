package com.farenidham.books.saxatsavita.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * Reading Progress Widget Provider for Sakshat Savita App
 */
class ReadingProgressWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }
    
    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
    
    companion object {
        internal fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.reading_progress_widget)
            
            // Update widget content with active plan data
            val progressTitle = widgetData.getString("progress_title", "Reading Progress")
            val dailyTargetMinutes = widgetData.getInt("daily_target_minutes", 30)
            val completedMinutes = widgetData.getInt("completed_minutes", 0)
            val targetKirans = widgetData.getInt("target_kirans", 3)
            val completedKirans = widgetData.getInt("completed_kirans", 0)
            // Get progress percentage safely
            val progressPercentage = try {
                val progressStr = widgetData.getString("progress_percentage", "0")
                if (progressStr != null) {
                    progressStr.toDouble().toInt()
                } else {
                    0
                }
            } catch (e: Exception) {
                0
            }
            val streakDays = widgetData.getString("streak_days", "0 days")
            val goalAchieved = widgetData.getBoolean("goal_achieved", false)
            
            views.setTextViewText(R.id.progress_title, progressTitle)
            views.setTextViewText(R.id.daily_target_minutes, dailyTargetMinutes.toString())
            views.setTextViewText(R.id.completed_minutes, completedMinutes.toString())
            views.setTextViewText(R.id.target_kirans, targetKirans.toString())
            views.setTextViewText(R.id.completed_kirans, completedKirans.toString())
            views.setProgressBar(R.id.progress_bar, 100, progressPercentage, false)
            views.setTextViewText(R.id.streak_days, streakDays)
            
            // Set click intents
            val progressIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.progress_title, progressIntent)
            
            val startReadingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.progress_bar, startReadingIntent)
            
            // Tell the AppWidgetManager to perform an update on the current app widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}