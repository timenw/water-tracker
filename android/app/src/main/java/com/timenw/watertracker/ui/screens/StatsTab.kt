package com.timenw.watertracker.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.timenw.watertracker.data.model.DailyWaterGoal
import com.timenw.watertracker.data.model.WeightRecord
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun StatsTab(
    weeklyWaterData: List<DailyWaterGoal>,
    monthlyWeightData: List<WeightRecord>
) {
    Column(modifier = Modifier.fillMaxSize()) {
        CenterAlignedTopAppBar(
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.BarChart, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("数据统计", fontWeight = FontWeight.Bold)
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
            item { Spacer(modifier = Modifier.height(8.dp)) }

            // Water weekly chart
            item {
                Text(
                    text = "本周喝水情况",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        if (weeklyWaterData.all { it.currentAmount == 0 }) {
                            Text(
                                text = "暂无数据，开始记录喝水吧 💧",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(vertical = 24.dp)
                            )
                        } else {
                            WaterBarChart(weeklyWaterData)
                        }
                    }
                }
            }

            // Water summary
            item {
                val totalWater = weeklyWaterData.sumOf { it.currentAmount }
                val avgWater = if (weeklyWaterData.isNotEmpty()) totalWater / weeklyWaterData.size else 0
                val completedDays = weeklyWaterData.count { it.isCompleted }

                Row(modifier = Modifier.fillMaxWidth()) {
                    SummaryCard(
                        title = "总饮水量",
                        value = "${totalWater}ml",
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    SummaryCard(
                        title = "日均饮水",
                        value = "${avgWater}ml",
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    SummaryCard(
                        title = "达标天数",
                        value = "${completedDays}天",
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // Weight section
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "体重趋势",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }

            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        if (monthlyWeightData.isEmpty()) {
                            Text(
                                text = "暂无数据，开始记录体重吧 ⚖️",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(vertical = 24.dp)
                            )
                        } else {
                            WeightLineChart(monthlyWeightData)
                            Spacer(modifier = Modifier.height(12.dp))
                            val firstWeight = monthlyWeightData.first().weight
                            val lastWeight = monthlyWeightData.last().weight
                            val diff = lastWeight - firstWeight
                            Text(
                                text = if (diff > 0) "📈 较月初 +${String.format("%.1f", diff)} kg"
                                else if (diff < 0) "📉 较月初 ${String.format("%.1f", diff)} kg"
                                else "➡️ 体重持平",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium,
                                color = if (diff > 0) Color(0xFFF44336)
                                else if (diff < 0) Color(0xFF4CAF50)
                                else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(16.dp)) }
        }
    }
}

@Composable
fun WaterBarChart(data: List<DailyWaterGoal>) {
    val maxAmount = data.maxOfOrNull { it.targetAmount } ?: 2000
    val dayFormatter = SimpleDateFormat("E", Locale.getDefault())
    val parseFormatter = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(160.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.Bottom
    ) {
        data.forEach { goal ->
            val barHeight = (goal.currentAmount.toFloat() / maxAmount).coerceIn(0f, 1f)
            val isCompleted = goal.isCompleted

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Bottom,
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = "${goal.currentAmount}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(4.dp))
                Canvas(
                    modifier = Modifier
                        .fillMaxWidth(0.7f)
                        .height(100.dp)
                ) {
                    val barWidth = size.width
                    val barH = size.height * barHeight

                    // Target line
                    val targetY = size.height * (goal.targetAmount.toFloat() / maxAmount)
                    drawLine(
                        color = Color.Gray.copy(alpha = 0.3f),
                        start = Offset(0f, size.height - targetY),
                        end = Offset(barWidth, size.height - targetY),
                        strokeWidth = 2f
                    )

                    // Bar
                    drawRect(
                        color = if (isCompleted) Color(0xFF4CAF50) else Color(0xFF1A73E8),
                        topLeft = Offset(0f, size.height - barH),
                        size = androidx.compose.ui.geometry.Size(barWidth, barH)
                    )
                }
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = try {
                        dayFormatter.format(parseFormatter.parse(goal.date) ?: Date())
                    } catch (e: Exception) {
                        goal.date
                    },
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun WeightLineChart(data: List<WeightRecord>) {
    if (data.size < 2) {
        Text(
            text = "至少需要2条记录才能显示趋势",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        return
    }

    val minWeight = data.minOf { it.weight } - 1f
    val maxWeight = data.maxOf { it.weight } + 1f
    val weightRange = maxWeight - minWeight

    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(120.dp)
    ) {
        val stepX = size.width / (data.size - 1).coerceAtLeast(1)
        val path = Path()

        data.forEachIndexed { index, record ->
            val x = index * stepX
            val y = size.height - ((record.weight - minWeight) / weightRange) * size.height

            if (index == 0) path.moveTo(x, y) else path.lineTo(x, y)

            // Draw point
            drawCircle(
                color = Color(0xFF1A73E8),
                radius = 4f,
                center = Offset(x, y)
            )
        }

        // Draw line
        drawPath(
            path = path,
            color = Color(0xFF1A73E8),
            style = Stroke(width = 3f)
        )
    }
}

@Composable
fun SummaryCard(
    title: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = value,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
