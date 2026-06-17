import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../models/data_models.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 用户设置
  int _dailyGoal = 2000;
  double? _height;
  double? _weight;
  double? _targetWeight;
  String _wakeUp = '08:00';
  String _sleep = '23:00';

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final profile = UserProfile(
      dailyWaterGoal: _dailyGoal,
      height: _height,
      targetWeight: _targetWeight,
      wakeUpTime: _wakeUp,
      sleepTime: _sleep,
    );
    
    await DataService().saveUserProfile(profile);
    
    // 安排喝水提醒
    await NotificationService().scheduleWaterReminders(
      wakeUp: _wakeUp,
      sleepTime: _sleep,
      intervalMinutes: 60,
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部进度指示器
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: _prevPage,
                      icon: const Icon(Icons.arrow_back),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / 4,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 页面内容
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildGoalPage(),
                  _buildBodyInfoPage(),
                  _buildTimePage(),
                ],
              ),
            ),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_currentPage < 3 ? '下一步' : '开始使用'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💧', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          const Text(
            '欢迎使用喝水提醒',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            '养成健康喝水习惯\n记录体重变化\n让生活更美好',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            '设置每日喝水目标',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '建议成年人每天饮水 1500-2500ml',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(
                  '$_dailyGoal ml',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _dailyGoal.toDouble(),
                  min: 1000,
                  max: 4000,
                  divisions: 30,
                  onChanged: (val) => setState(() => _dailyGoal = val.round()),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1000ml'),
                    Text('4000ml'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyInfoPage() {
    final heightCtrl = TextEditingController(text: _height?.toString() ?? '');
    final weightCtrl = TextEditingController(text: _weight?.toString() ?? '');
    final targetCtrl = TextEditingController(text: _targetWeight?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            '身体信息（可选）',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '用于计算 BMI 和个性化建议',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: heightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '身高 (cm)',
              prefixIcon: Icon(Icons.height),
            ),
            onChanged: (val) => _height = double.tryParse(val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '当前体重 (kg)',
              prefixIcon: Icon(Icons.monitor_weight),
            ),
            onChanged: (val) => _weight = double.tryParse(val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: targetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '目标体重 (kg)',
              prefixIcon: Icon(Icons.flag),
            ),
            onChanged: (val) => _targetWeight = double.tryParse(val),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏰', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            '作息时间',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '我们会在您醒着的时间段内提醒您喝水',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.wb_sunny),
            title: const Text('起床时间'),
            subtitle: Text(_wakeUp),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 8, minute: 0),
              );
              if (time != null) {
                setState(() {
                  _wakeUp = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.nightlight_round),
            title: const Text('睡觉时间'),
            subtitle: Text(_sleep),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 23, minute: 0),
              );
              if (time != null) {
                setState(() {
                  _sleep = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
