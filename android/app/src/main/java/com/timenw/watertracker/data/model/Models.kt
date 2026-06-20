package com.timenw.watertracker.data.model

import java.time.LocalDate
import java.time.LocalDateTime

data class WaterRecord(
    val id: Long = System.currentTimeMillis(),
    val amount: Int, // ml
    val timestamp: LocalDateTime = LocalDateTime.now(),
    val date: LocalDate = LocalDate.now()
)

data class WeightRecord(
    val id: Long = System.currentTimeMillis(),
    val weight: Float, // kg
    val timestamp: LocalDateTime = LocalDateTime.now(),
    val date: LocalDate = LocalDate.now()
)

data class DailyWaterGoal(
    val date: LocalDate = LocalDate.now(),
    val targetAmount: Int = 2000, // ml
    val currentAmount: Int = 0
) {
    val progress: Float get() = (currentAmount.toFloat() / targetAmount).coerceIn(0f, 1f)
    val isCompleted: Boolean get() = currentAmount >= targetAmount
}

data class UserSettings(
    val dailyWaterTarget: Int = 2000, // ml
    val reminderEnabled: Boolean = true,
    val reminderIntervalMinutes: Int = 60,
    val wakeUpHour: Int = 8,
    val sleepHour: Int = 22,
    val weightUnit: WeightUnit = WeightUnit.KG
)

enum class WeightUnit(val label: String, val symbol: String) {
    KG("公斤", "kg"),
    LB("磅", "lb")
}
