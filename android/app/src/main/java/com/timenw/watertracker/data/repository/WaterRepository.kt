package com.timenw.watertracker.data.repository

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.timenw.watertracker.data.model.*
import java.time.LocalDate

class WaterRepository(private val context: Context) {
    private val prefs = context.getSharedPreferences("water_tracker", Context.MODE_PRIVATE)
    private val gson = Gson()

    // Water records
    fun getWaterRecords(date: LocalDate = LocalDate.now()): List<WaterRecord> {
        val key = "water_${date}"
        val json = prefs.getString(key, "[]") ?: "[]"
        val type = object : TypeToken<List<WaterRecord>>() {}.type
        return gson.fromJson(json, type) ?: emptyList()
    }

    fun addWaterRecord(amount: Int, date: LocalDate = LocalDate.now()) {
        val records = getWaterRecords(date).toMutableList()
        records.add(WaterRecord(amount = amount))
        saveWaterRecords(records, date)
    }

    fun removeWaterRecord(id: Long, date: LocalDate = LocalDate.now()) {
        val records = getWaterRecords(date).toMutableList()
        records.removeAll { it.id == id }
        saveWaterRecords(records, date)
    }

    fun getDailyWaterTotal(date: LocalDate = LocalDate.now()): Int {
        return getWaterRecords(date).sumOf { it.amount }
    }

    private fun saveWaterRecords(records: List<WaterRecord>, date: LocalDate) {
        val key = "water_${date}"
        prefs.edit().putString(key, gson.toJson(records)).apply()
    }

    // Weight records
    fun getWeightRecords(): List<WeightRecord> {
        val json = prefs.getString("weight_records", "[]") ?: "[]"
        val type = object : TypeToken<List<WeightRecord>>() {}.type
        return gson.fromJson(json, type) ?: emptyList()
    }

    fun getWeightRecordsForDate(date: LocalDate): List<WeightRecord> {
        return getWeightRecords().filter { it.date == date.toString() }
    }

    fun addWeightRecord(weight: Float) {
        val records = getWeightRecords().toMutableList()
        records.add(WeightRecord(weight = weight))
        prefs.edit().putString("weight_records", gson.toJson(records)).apply()
    }

    fun removeWeightRecord(id: Long) {
        val records = getWeightRecords().toMutableList()
        records.removeAll { it.id == id }
        prefs.edit().putString("weight_records", gson.toJson(records)).apply()
    }

    fun getLatestWeight(): Float? {
        return getWeightRecords().maxByOrNull { it.timestamp }?.weight
    }

    // Settings
    fun getSettings(): UserSettings {
        val json = prefs.getString("settings", null)
        return if (json != null) {
            gson.fromJson(json, UserSettings::class.java)
        } else {
            UserSettings()
        }
    }

    fun saveSettings(settings: UserSettings) {
        prefs.edit().putString("settings", gson.toJson(settings)).apply()
    }

    // Stats
    fun getWeeklyWaterData(): List<DailyWaterGoal> {
        val settings = getSettings()
        val today = LocalDate.now()
        return (0..6).map { daysAgo ->
            val date = today.minusDays(daysAgo.toLong())
            val total = getDailyWaterTotal(date)
            DailyWaterGoal(date = date.toString(), targetAmount = settings.dailyWaterTarget, currentAmount = total)
        }.reversed()
    }

    fun getMonthlyWeightData(): List<WeightRecord> {
        val today = LocalDate.now()
        val monthAgo = today.minusDays(30).toString()
        return getWeightRecords().filter { it.date >= monthAgo }.sortedBy { it.timestamp }
    }
}
