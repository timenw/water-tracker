import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';
import '../models/data_models.dart';

class WaterTab extends StatefulWidget {
  const WaterTab({super.key});

  @override
  State<WaterTab> createState() => _WaterTabState();
}

class _WaterTabState extends State<WaterTab> {
  final DataService _dataService = DataService();
  List<WaterRecord> _todayRecords = [];
  int _todayTotal = 0;
  int _dailyGoal = 2000;
  bool _loading = true;
  bool _isPremium = false;

  final List<int> _quickAmounts = [150, 250, 350, 500];

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final premium = await PremiumService().isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  Future<void> _loadData() async {
    final records = await _dataService.getTodayWaterRecords();
    final total = await _dataService.getTodayWaterTotal();
    final profile = await _dataService.getUserProfile();
    
    setState(() {
      _todayRecords = records;
      _todayTotal = total;
      _dailyGoal = profile.dailyWaterGoal;
      _loading = false;
    });
  }

  Future<void> _addWater(int amount) async {
    final record = WaterRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      time: DateTime.now(),
    );
    await _dataService.addWaterRecord(record);
    
    // 非付费用户，记录喝水次数，适时展示插屏广告
    if (!_isPremium) {
      AdService().showInterstitial();
    }
    
    _loadData();

    if (_todayTotal + amount >= _dailyGoal && _todayTotal < _dailyGoal) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 恭喜！今日喝水目标已达成！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteRecord(String id) async {
    await _dataService.deleteWaterRecord(id);
    _loadData();
  }

  Future<void> _showCustomAmountDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('自定义水量'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '水量 (ml)',
            suffixText: 'ml',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
    if (result != null) {
      _addWater(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progress = (_todayTotal / _dailyGoal).clamp(0.0, 1.0);
    final remaining = (_dailyGoal - _todayTotal).clamp(0, 99999);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💧 喝水记录'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== 今日进度卡片 =====
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      height: 180,
                      width: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 180,
                            width: 180,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: Colors.blue.shade50,
                              valueColor: AlwaysStoppedAnimation(
                                progress >= 1.0 ? Colors.green : Colors.blue,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_todayTotal',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '/ $_dailyGoal ml',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                progress >= 1.0 ? '✅ 目标达成！' : '还需 $remaining ml',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: progress >= 1.0 ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== 快速添加按钮 =====
            const Text(
              '快速添加',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: _quickAmounts.map((amount) {
                final icons = {150: '🥤', 250: '🥛', 350: '🫗', 500: '🍶'};
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilledButton.tonal(
                      onPressed: () => _addWater(amount),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Column(
                        children: [
                          Text(icons[amount] ?? '💧', style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text('${amount}ml', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _showCustomAmountDialog,
              icon: const Icon(Icons.add),
              label: const Text('自定义水量'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            // ===== 今日记录列表 =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '今日记录',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_todayRecords.length} 次',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_todayRecords.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.water_drop_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        '今天还没有喝水记录\n点击上方按钮开始记录吧！',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._todayRecords.reversed.map((record) {
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
                        backgroundColor: Colors.blue.shade100,
                        child: const Text('💧'),
                      ),
                      title: Text('${record.amount} ml'),
                      subtitle: Text(
                        DateFormat('HH:mm').format(record.time),
                      ),
                      trailing: Text(
                        '${record.amount}ml',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),

            // ===== Banner 广告（仅非付费用户） =====
            if (!_isPremium) ...[
              const SizedBox(height: 16),
              AdService().getBannerWidget(),
            ],
          ],
        ),
      ),
    );
  }
}
