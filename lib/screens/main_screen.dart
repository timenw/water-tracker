import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _WaterTab(),
          _WeightTab(),
          _StatsTab(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: '喝水',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: '体重',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class _WaterTab extends StatelessWidget {
  const _WaterTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💧 喝水记录'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('喝水功能开发中...', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _WeightTab extends StatelessWidget {
  const _WeightTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚖️ 体重追踪'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('体重功能开发中...', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 数据统计'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('统计功能开发中...', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ 设置'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('设置功能开发中...', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
