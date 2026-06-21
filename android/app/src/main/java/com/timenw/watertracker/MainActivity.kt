package com.timenw.watertracker

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.timenw.watertracker.data.repository.WaterRepository
import com.timenw.watertracker.data.model.DailyWaterGoal
import com.timenw.watertracker.service.ReminderReceiver
import com.timenw.watertracker.ui.screens.*
import com.timenw.watertracker.ui.theme.WaterTrackerTheme
import java.time.LocalDate

class MainActivity : ComponentActivity() {

    private lateinit var repository: WaterRepository

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        if (isGranted) {
            setupReminder()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        repository = WaterRepository(applicationContext)

        // 请求通知权限并设置提醒
        requestNotificationPermission()

        setContent {
            WaterTrackerTheme {
                MainScreen(repository) { setupReminder() }
            }
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            } else {
                setupReminder()
            }
        } else {
            setupReminder()
        }
    }

    private fun setupReminder() {
        val settings = repository.getSettings()
        if (settings.reminderEnabled) {
            ReminderReceiver.scheduleNextReminder(this, settings.reminderIntervalMinutes)
        } else {
            ReminderReceiver.cancelReminder(this)
        }
    }
}

sealed class Screen(val route: String, val label: String, val selectedIcon: @Composable () -> Unit, val unselectedIcon: @Composable () -> Unit) {
    object Water : Screen("water", "喝水", { Icon(Icons.Filled.WaterDrop, contentDescription = null) }, { Icon(Icons.Outlined.WaterDrop, contentDescription = null) })
    object Weight : Screen("weight", "体重", { Icon(Icons.Filled.MonitorWeight, contentDescription = null) }, { Icon(Icons.Outlined.MonitorWeight, contentDescription = null) })
    object Stats : Screen("stats", "统计", { Icon(Icons.Filled.BarChart, contentDescription = null) }, { Icon(Icons.Outlined.BarChart, contentDescription = null) })
    object Settings : Screen("settings", "设置", { Icon(Icons.Filled.Settings, contentDescription = null) }, { Icon(Icons.Outlined.Settings, contentDescription = null) })
}

@Composable
fun MainScreen(repository: WaterRepository, onSettingsChanged: () -> Unit = {}) {
    val navController = rememberNavController()
    val screens = listOf(Screen.Water, Screen.Weight, Screen.Stats, Screen.Settings)

    // Data states
    val settings = remember { mutableStateOf(repository.getSettings()) }
    val today = remember { LocalDate.now() }
    val waterRecords = remember { mutableStateOf(repository.getWaterRecords(today)) }
    val weightRecords = remember { mutableStateOf(repository.getWeightRecords()) }
    val weeklyWaterData = remember { mutableStateOf(repository.getWeeklyWaterData()) }
    val monthlyWeightData = remember { mutableStateOf(repository.getMonthlyWeightData()) }

    val dailyGoal = remember(waterRecords.value, settings.value) {
        DailyWaterGoal(
            date = today.toString(),
            targetAmount = settings.value.dailyWaterTarget,
            currentAmount = waterRecords.value.sumOf { it.amount }
        )
    }

    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination
                screens.forEach { screen ->
                    NavigationBarItem(
                        icon = {
                            if (currentDestination?.hierarchy?.any { it.route == screen.route } == true) {
                                screen.selectedIcon()
                            } else {
                                screen.unselectedIcon()
                            }
                        },
                        label = { Text(screen.label) },
                        selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                        onClick = {
                            navController.navigate(screen.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Water.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Water.route) {
                WaterTab(
                    dailyGoal = dailyGoal,
                    records = waterRecords.value,
                    onAddWater = { amount ->
                        repository.addWaterRecord(amount, today)
                        waterRecords.value = repository.getWaterRecords(today)
                        weeklyWaterData.value = repository.getWeeklyWaterData()
                    },
                    onRemoveRecord = { id ->
                        repository.removeWaterRecord(id, today)
                        waterRecords.value = repository.getWaterRecords(today)
                        weeklyWaterData.value = repository.getWeeklyWaterData()
                    }
                )
            }
            composable(Screen.Weight.route) {
                WeightTab(
                    records = weightRecords.value,
                    latestWeight = repository.getLatestWeight(),
                    onAddWeight = { weight ->
                        repository.addWeightRecord(weight)
                        weightRecords.value = repository.getWeightRecords()
                        monthlyWeightData.value = repository.getMonthlyWeightData()
                    },
                    onRemoveRecord = { id ->
                        repository.removeWeightRecord(id)
                        weightRecords.value = repository.getWeightRecords()
                        monthlyWeightData.value = repository.getMonthlyWeightData()
                    }
                )
            }
            composable(Screen.Stats.route) {
                StatsTab(
                    weeklyWaterData = weeklyWaterData.value,
                    monthlyWeightData = monthlyWeightData.value
                )
            }
            composable(Screen.Settings.route) {
                SettingsTab(
                    settings = settings.value,
                    onSettingsChanged = { newSettings ->
                        repository.saveSettings(newSettings)
                        settings.value = newSettings
                        onSettingsChanged()
                    }
                )
            }
        }
    }
}
