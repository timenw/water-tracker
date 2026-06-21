package com.timenw.watertracker.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.timenw.watertracker.MainActivity
import com.timenw.watertracker.R
import com.timenw.watertracker.data.repository.WaterRepository
import java.util.Calendar

class ReminderReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val repo = WaterRepository(context)
        val settings = repo.getSettings()

        if (!settings.reminderEnabled) return

        // 检查是否在睡眠时间段
        val now = Calendar.getInstance()
        val hour = now.get(Calendar.HOUR_OF_DAY)
        if (hour >= settings.sleepHour || hour < settings.wakeUpHour) return

        // 检查今日目标是否已完成
        val todayTotal = repo.getDailyWaterTotal()
        if (todayTotal >= settings.dailyWaterTarget) return

        showNotification(context, todayTotal, settings.dailyWaterTarget)

        // 设置下一次提醒
        scheduleNextReminder(context, settings.reminderIntervalMinutes)
    }

    private fun showNotification(context: Context, current: Int, target: Int) {
        val channelId = "water_reminder"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // 创建通知渠道（Android 8.0+）
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "喝水提醒",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "定时提醒你喝水"
            }
            notificationManager.createNotificationChannel(channel)
        }

        // 点击通知打开应用
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val remaining = (target - current).coerceAtLeast(0)
        val progress = (current.toFloat() / target * 100).toInt()

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("💧 该喝水啦！")
            .setContentText("今日已喝 ${current}ml / ${target}ml，还差 ${remaining}ml")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("今日已喝 ${current}ml / ${target}ml，还差 ${remaining}ml\n进度：${progress}%"))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setProgress(100, progress, false)
            .build()

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    companion object {
        fun scheduleNextReminder(context: Context, intervalMinutes: Int) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val intent = Intent(context, ReminderReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val triggerTime = System.currentTimeMillis() + intervalMinutes * 60 * 1000L

            try {
                alarmManager.setAndAllowWhileIdle(
                    android.app.AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } catch (e: SecurityException) {
                // 某些设备需要 SCHEDULE_EXACT_ALARM 权限
                alarmManager.set(
                    android.app.AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
        }

        fun cancelReminder(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
            val intent = Intent(context, ReminderReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
    }
}
