import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../models/data_models.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  UserProfile _profile = UserProfile();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _dataService.getUserProfile();
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    await _dataService.saveUserProfile(_profile);
    // 重新安排提醒
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
    final time = await showTimePicker(
      context: context,
      initialTime: isWakeUp
          ? TimeOfDay(hour: 8, minute: 0)
          : TimeOfDay(hour: 23, minute: 0),
    );
    if (time != null) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (isWakeUp) {
        setState(() => _profile.wakeUpTime = timeStr);
      } else {
        setState(() => _profile.sleepTime = timeStr);
      }
      _saveProfile();
    }
  }

  Future<void> _showPremiumDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🌟 升级到高级版'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('解锁全部功能：'),
            SizedBox(height: 8),
            Text('✅ 无限喝水提醒'),
            Text('✅ 详细数据分析'),
            Text('✅ 多设备同步'),
            Text('✅ 无广告体验'),
            Text('✅ 更多主题'),
            SizedBox(height: 16),
            Text('¥12/月 或 ¥68/年', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('稍后再说')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 接入内购
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('内购功能即将上线')),
              );
            },
            child: const Text('立即升级'),
          ),
        ],
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
          if (!_profile.isPremium)
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.amber.shade50,
              child: InkWell(
                onTap: _showPremiumDialog,
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

          // ===== 关于 =====
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('关于', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
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
            onTap: () {
              // TODO: 打开隐私政策
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('给我们评分'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 打开 App Store 评分
            },
          ),

          const SizedBox(height: 32),

          // 底部版权
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
