import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../services/premium_service.dart';
import '../models/data_models.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  final PremiumService _premiumService = PremiumService();
  
  UserProfile _profile = UserProfile();
  bool _loading = true;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _dataService.getUserProfile();
    final isPremium = await _premiumService.isPremium();
    setState(() {
      _profile = profile;
      _isPremium = isPremium;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    await _dataService.saveUserProfile(_profile);
    await _notificationService.scheduleWaterReminders(
      wakeUp: _profile.wakeUpTime ?? '08:00',
      sleepTime: _profile.sleepTime ?? '23:00',
      intervalMinutes: 60,
    );
  }

  Future<void> _showGoalDialog() async {
    final controller = TextEditingController(text: _profile.dailyWaterGoal.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('每日喝水目标'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '目标水量',
            suffixText: 'ml',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _profile.dailyWaterGoal = result);
      _saveProfile();
    }
  }

  Future<void> _showTimeDialog(bool isWakeUp) async {
    final parts = (isWakeUp ? _profile.wakeUpTime : _profile.sleepTime)?.split(':') ?? ['08', '00'];
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (time != null) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isWakeUp) _profile.wakeUpTime = timeStr;
        else _profile.sleepTime = timeStr;
      });
      _saveProfile();
    }
  }

  Future<void> _showPremiumSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PremiumSheet(
        premiumService: _premiumService,
        onPurchased: () {
          setState(() => _isPremium = true);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ 设置'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ===== 高级版卡片 =====
          if (!_isPremium)
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.amber.shade50,
              child: InkWell(
                onTap: _showPremiumSheet,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('升级到高级版', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('解锁全部功能，无广告'),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            )
          else
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('✅', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('高级版已激活', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('感谢您的支持！'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ===== 喝水设置 =====
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('喝水设置', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('每日目标'),
            subtitle: Text('${_profile.dailyWaterGoal} ml'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showGoalDialog,
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny),
            title: const Text('起床时间'),
            subtitle: Text(_profile.wakeUpTime ?? '08:00'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimeDialog(true),
          ),
          ListTile(
            leading: const Icon(Icons.nightlight_round),
            title: const Text('睡觉时间'),
            subtitle: Text(_profile.sleepTime ?? '23:00'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimeDialog(false),
          ),

          const Divider(),

          // ===== 通知设置 =====
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('通知设置', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('喝水提醒'),
            subtitle: const Text('定时提醒您喝水'),
            value: true,
            onChanged: (val) {
              if (val) {
                _notificationService.scheduleWaterReminders(
                  wakeUp: _profile.wakeUpTime ?? '08:00',
                  sleepTime: _profile.sleepTime ?? '23:00',
                  intervalMinutes: 60,
                );
              } else {
                _notificationService.cancelAll();
              }
            },
          ),

          const Divider(),

          // ===== 其他 =====
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('其他', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          if (_isPremium)
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('恢复购买'),
              onTap: () async {
                await _premiumService.restorePurchases();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('购买已恢复')),
                  );
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            subtitle: const Text('v1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('给我们评分'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Water Tracker v1.0.0\nMade with ❤️',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// 高级版订阅底部弹窗
class _PremiumSheet extends StatefulWidget {
  final PremiumService premiumService;
  final VoidCallback onPurchased;

  const _PremiumSheet({
    required this.premiumService,
    required this.onPurchased,
  });

  @override
  State<_PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<_PremiumSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final products = widget.premiumService.products;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text('🌟', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            '升级到高级版',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '解锁全部功能，支持我们持续开发',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // 功能列表
          const _FeatureItem(icon: '✅', text: '移除所有广告'),
          const _FeatureItem(icon: '✅', text: '无限喝水提醒'),
          const _FeatureItem(icon: '✅', text: '详细数据分析'),
          const _FeatureItem(icon: '✅', text: '多设备同步'),
          const _FeatureItem(icon: '✅', text: '更多主题和图标'),
          const SizedBox(height: 24),

          // 订阅选项
          if (products.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('正在加载订阅信息...'),
              ),
            )
          else
            ...products.map((product) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(product.title.isEmpty ? product.id : product.title),
                  subtitle: Text(product.description),
                  trailing: Text(
                    product.price,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onTap: _loading ? null : () => _buy(product),
                ),
              );
            }),

          const SizedBox(height: 12),
          
          // 恢复购买
          TextButton(
            onPressed: () async {
              await widget.premiumService.restorePurchases();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('购买已恢复')),
                );
              }
            },
            child: const Text('恢复购买'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _buy(ProductDetails product) async {
    setState(() => _loading = true);
    final success = await widget.premiumService.buy(product);
    setState(() => _loading = false);
    
    if (success && mounted) {
      widget.onPurchased();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 感谢购买！高级版已激活'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final String icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
