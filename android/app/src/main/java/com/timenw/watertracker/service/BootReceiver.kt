package com.timenw.watertracker.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.timenw.watertracker.data.repository.WaterRepository

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            val repo = WaterRepository(context)
            val settings = repo.getSettings()
            if (settings.reminderEnabled) {
                ReminderReceiver.scheduleNextReminder(context, settings.reminderIntervalMinutes)
            }
        }
    }
}
