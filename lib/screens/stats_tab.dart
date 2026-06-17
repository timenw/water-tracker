import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/data_models.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final DataService _dataService = DataService();
  Map<String, int> _weeklyWater = {};
  List<WeightRecord> _monthlyWeight = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final waterStats = await _dataService.getWeeklyWaterStats();
    final weightStats = await _dataService.getMonthlyWeightRecords();
    
    setState(() {
      _weeklyWater = waterStats;
      _monthlyWeight = weightStats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 数据统计'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 喝水周统计 =====
          const Text(
            '本周喝水趋势',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _weeklyWater.isEmpty
                    ? const Center(child: Text('暂无数据'))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (_weeklyWater.values.isEmpty ? 2000 : _weeklyWater.values.reduce((a, b) => a > b ? a : b)).toDouble() * 1.2,
                          barGroups: _weeklyWater.entries.toList().asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.value.toDouble(),
                                  color: Colors.blue,
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final keys = _weeklyWater.keys.toList();
                                  if (value.toInt() < keys.length) {
                                    return Text(keys[value.toInt()], style: const TextStyle(fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text('${(value / 1000).toStringAsFixed(1)}L', style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ===== 体重月趋势 =====
          const Text(
            '体重变化趋势',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _monthlyWeight.isEmpty
                    ? const Center(child: Text('暂无数据'))
                    : LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: _monthlyWeight.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value.weight);
                              }).toList(),
                              isCurved: true,
                              color: Colors.purple,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.purple.withOpacity(0.1),
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < _monthlyWeight.length) {
                                    final date = _monthlyWeight[value.toInt()].date;
                                    return Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}kg', style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ===== 健康摘要 =====
          const Text(
            '健康摘要',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow(
                    icon: '💧',
                    title: '本周平均喝水',
                    value: _getAverageWater(),
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    icon: '⚖️',
                    title: '体重变化',
                    value: _getWeightChange(),
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    icon: '📅',
                    title: '记录天数',
                    value: '${_monthlyWeight.length} 天',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({required String icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _getAverageWater() {
    if (_weeklyWater.isEmpty) return '--';
    final total = _weeklyWater.values.fold(0, (a, b) => a + b);
    final avg = total / _weeklyWater.length;
    return '${(avg / 1000).toStringAsFixed(1)} L/天';
  }

  String _getWeightChange() {
    if (_monthlyWeight.length < 2) return '--';
    final change = _monthlyWeight.last.weight - _monthlyWeight.first.weight;
    return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg';
  }
}
