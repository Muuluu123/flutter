import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'StatsScreen.dart';
import 'Todayappointmentsscreen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  int _totalCount = 0;
  int _doneCount = 0;
  int _pendingCount = 0;
  int _cancelledCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final data = await Supabase.instance.client
          .from('appointments')
          .select('status')
          .gte('appointment_date', startOfDay.toIso8601String())
          .lt('appointment_date', endOfDay.toIso8601String());

      final list = List<Map<String, dynamic>>.from(data);

      setState(() {
        _totalCount = list.length;
        _doneCount = list.where((a) => a['status'] == 'done').length;
        _pendingCount = list
            .where(
                (a) => a['status'] == 'pending' || a['status'] == 'confirmed')
            .length;
        _cancelledCount = list.where((a) => a['status'] == 'cancelled').length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Дээд хэсэг
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B21A8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.business,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Эмнэлгийн\nлого',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2B47),
                        ),
                      ),
                      const Text(
                        'Дотоод ажилтан',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  // Гарах товч
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFF6B21A8), size: 28),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Өнөөдрийн цаг авалтууд том карт
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TodayAppointmentsScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_alt_outlined,
                          color: Colors.white, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'Өнөөдрийн цаг авалтууд',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Статистик гарчиг
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart, color: Color(0xFF6B21A8), size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Өнөөдрийн статистик',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A2B47)),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => StatsScreen()));
                    },
                    child: const Text('Дэлгэрэнгүй →',
                        style: TextStyle(color: Color(0xFF6B21A8))),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Статистик картууд
              _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF6B21A8)))
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          icon: Icons.people_alt_rounded,
                          label: 'Нийт',
                          count: _totalCount,
                          color: const Color(0xFF1D61FF),
                        ),
                        _buildStatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Үйлчлүүлсэн',
                          count: _doneCount,
                          color: const Color(0xFF22C55E),
                        ),
                        _buildStatCard(
                          icon: Icons.access_time_rounded,
                          label: 'Хүлээж байгаа',
                          count: _pendingCount,
                          color: const Color(0xFFFF6B35),
                        ),
                        _buildStatCard(
                          icon: Icons.cancel_outlined,
                          label: 'Цуцалсан',
                          count: _cancelledCount,
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
