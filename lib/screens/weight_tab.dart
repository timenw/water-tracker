import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/data_models.dart';

class WeightTab extends StatefulWidget {
  const WeightTab({super.key});

  @override
  State<WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends State<WeightTab> {
  final DataService _dataService = DataService();
  List<WeightRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _dataService.getWeightRecords();
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _showAddWeightDialog() async {
    final controller = TextEditingController();
    final noteController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记录体重'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '体重',
                suffixText: 'kg',
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0 && val < 500) {
                Navigator.pop(ctx, {
                  'weight': val,
                  'note': noteController.text.isEmpty ? null : noteController.text,
                });
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null) {
      final record = WeightRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weight: result['weight'],
        date: DateTime.now(),
        note: result['note'],
      );
      await _dataService.addWeightRecord(record);
      _loadData();
    }
  }

  Future<void> _deleteRecord(String id) async {
    await _dataService.deleteWeightRecord(id);
    _loadData();
  }

  double? get _latestWeight {
    if (_records.isEmpty) return null;
    return _records.last.weight;
  }

  double? get _weightChange {
    if (_records.length < 2) return null;
    return _records.last.weight - _records.first.weight;
  }

  double? get _bmi {
    if (_records.isEmpty) return null;
    // 需要身高数据
    return null; // 在统计页面计算
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚖️ 体重追踪'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 当前体重卡片 =====
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('当前体重', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    _latestWeight != null ? '${_latestWeight!.toStringAsFixed(1)} kg' : '--',
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                  ),
                  if (_weightChange != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _weightChange! <= 0 ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _weightChange! <= 0 ? Icons.trending_down : Icons.trending_up,
                            size: 16,
                            color: _weightChange! <= 0 ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_weightChange! >= 0 ? '+' : ''}${_weightChange!.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              color: _weightChange! <= 0 ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== 添加按钮 =====
          FilledButton.icon(
            onPressed: _showAddWeightDialog,
            icon: const Icon(Icons.add),
            label: const Text('记录今日体重'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 24),

          // ===== 历史记录 =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '历史记录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_records.length} 条',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_records.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.monitor_weight_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      '还没有体重记录\n点击上方按钮开始记录吧！',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
            else
              ..._records.reversed.map((record) {
                return Dismissible(
                  key: Key(record.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteRecord(record.id),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: const Text('⚖️'),
                      ),
                      title: Text(
                        '${record.weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(record.date),
                      ),
                      trailing: record.note != null
                          ? const Icon(Icons.note, size: 16, color: Colors.grey)
                          : null,
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }
}
