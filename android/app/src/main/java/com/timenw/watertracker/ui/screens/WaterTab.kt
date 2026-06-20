package com.timenw.watertracker.ui.screens

import androidx.compose.animation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.LocalDrink
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import com.timenw.watertracker.data.model.DailyWaterGoal
import com.timenw.watertracker.data.model.WaterRecord
import com.timenw.watertracker.ui.components.CircularProgressIndicator
import com.timenw.watertracker.ui.components.EmptyStateView
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WaterTab(
    dailyGoal: DailyWaterGoal,
    records: List<WaterRecord>,
    onAddWater: (Int) -> Unit,
    onRemoveRecord: (Long) -> Unit
) {
    var showCustomDialog by remember { mutableStateOf(false) }
    var customAmount by remember { mutableStateOf("") }
    val formatter = remember { DateTimeFormatter.ofPattern("HH:mm") }

    Column(modifier = Modifier.fillMaxSize()) {
        // Top bar
        CenterAlignedTopAppBar(
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.LocalDrink, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("喝水记录", fontWeight = FontWeight.Bold)
                }
            },
            colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        )

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Progress circle
            item {
                Spacer(modifier = Modifier.height(16.dp))
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    CircularProgressIndicator(
                        progress = dailyGoal.progress,
                        size = 180,
                        strokeWidth = 14
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "${dailyGoal.currentAmount} / ${dailyGoal.targetAmount} ml",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    if (dailyGoal.isCompleted) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "🎉 今日目标已完成！",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.tertiary
                        )
                    }
                }
            }

            // Quick add buttons
            item {
                Text(
                    text = "快速添加",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf(100, 200, 250, 300, 500).forEach { amount ->
                        FilledTonalButton(
                            onClick = { onAddWater(amount) },
                            modifier = Modifier
                                .weight(1f)
                                .height(48.dp),
                            colors = ButtonDefaults.filledTonalButtonColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        ) {
                            Text(
                                text = "+${amount}ml",
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }

            // Custom add button
            item {
                OutlinedButton(
                    onClick = { showCustomDialog = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                ) {
                    Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("自定义水量")
                }
            }

            // Today's records
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "今日记录",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            if (records.isEmpty()) {
                item {
                    EmptyStateView(
                        emoji = "💧",
                        title = "还没有喝水记录",
                        subtitle = "点击上方按钮记录你的第一杯水吧"
                    )
                }
            } else {
                items(records.reversed(), key = { it.id }) { record ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                        )
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "💧",
                                fontSize = 20.sp,
                                modifier = Modifier.padding(end = 12.dp)
                            )
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "${record.amount} ml",
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = FontWeight.Medium
                                )
                                Text(
                                    text = record.timestamp.format(formatter),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            IconButton(onClick = { onRemoveRecord(record.id) }) {
                                Icon(
                                    Icons.Default.Delete,
                                    contentDescription = "删除",
                                    tint = MaterialTheme.colorScheme.error
                                )
                            }
                        }
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(16.dp)) }
        }
    }

    // Custom amount dialog
    if (showCustomDialog) {
        AlertDialog(
            onDismissRequest = { showCustomDialog = false },
            title = { Text("自定义水量") },
            text = {
                OutlinedTextField(
                    value = customAmount,
                    onValueChange = { customAmount = it.filter { c -> c.isDigit() } },
                    label = { Text("水量 (ml)") },
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        val amount = customAmount.toIntOrNull()
                        if (amount != null && amount > 0) {
                            onAddWater(amount)
                            customAmount = ""
                            showCustomDialog = false
                        }
                    }
                ) {
                    Text("添加")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    showCustomDialog = false
                    customAmount = ""
                }) {
                    Text("取消")
                }
            }
        )
    }
}
