import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化通知服务
  await NotificationService().init();
  await NotificationService().requestPermissions();
  
  // 初始化 AdMob
  await AdService().init();
  
  // 预加载广告
  AdService().loadBanner();
  AdService().loadInterstitial();
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const WaterTrackerApp());
}

class WaterTrackerApp extends StatelessWidget {
  const WaterTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '喝水提醒',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
      ),
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final profile = await DataService().getUserProfile();
    setState(() {
      _hasSeenOnboarding = profile.dailyWaterGoal != 2000 || profile.height != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_hasSeenOnboarding == false) {
      return const OnboardingScreen();
    }
    
    return const MainScreen();
  }
}
