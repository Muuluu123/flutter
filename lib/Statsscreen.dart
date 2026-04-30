import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedPeriod = 0;
  int _totalCount = 0;
  int _doneCount = 0;
  int _pendingCount = 0;
  int _cancelledCount = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 1:
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
      case 2:
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('appointments')
          .select('status, appointment_date')
          .gte('appointment_date', _startDate.toIso8601String())
          .lt('appointment_date', _endDate.toIso8601String());

      final list = List<Map<String, dynamic>>.from(data);

      List<Map<String, dynamic>> chartData;

      if (_selectedPeriod == 2) {
        // ── 1 САР: 7 хоног тутам нэгтгэх (4 баганa) ──
        // Долоо хоног: 22-28, 15-21, 8-14, 1-7 (буцаан)
        final Map<int, Map<String, int>> byWeek = {
          0: {'done': 0, 'pending': 0, 'cancelled': 0},
          1: {'done': 0, 'pending': 0, 'cancelled': 0},
          2: {'done': 0, 'pending': 0, 'cancelled': 0},
          3: {'done': 0, 'pending': 0, 'cancelled': 0},
        };

        final today = DateTime.now();

        for (final appt in list) {
          final dt = DateTime.parse(appt['appointment_date']).toLocal();
          final daysAgo = today.difference(dt).inDays;
          final weekIndex = (daysAgo / 7).floor().clamp(0, 3);
          final status = appt['status'] ?? 'pending';
          if (status == 'done') {
            byWeek[weekIndex]!['done'] = byWeek[weekIndex]!['done']! + 1;
          } else if (status == 'cancelled') {
            byWeek[weekIndex]!['cancelled'] =
                byWeek[weekIndex]!['cancelled']! + 1;
          } else {
            byWeek[weekIndex]!['pending'] =
                byWeek[weekIndex]!['pending']! + 1;
          }
        }

        // Хуучнаас шинэ рүү (3-р долоо хоноос 0 руу) — зүүнээс баруун
        chartData = List.generate(4, (i) {
          final weekIdx = 3 - i;
          final startDay = today.subtract(Duration(days: (weekIdx + 1) * 7 - 1));
          final endDay = today.subtract(Duration(days: weekIdx * 7));
          final label =
              '${startDay.month}/${startDay.day}-${endDay.month}/${endDay.day}';
          final d = byWeek[weekIdx]!;
          return {
            'label': label,
            'done': d['done']!,
            'pending': d['pending']!,
            'cancelled': d['cancelled']!,
            'total': d['done']! + d['pending']! + d['cancelled']!,
          };
        });
      } else {
        // ── ӨНӨӨДӨР / 7 ХОНОГ: Өдрөөр ──
        final Map<String, Map<String, int>> byDay = {};
        final days = _selectedPeriod == 0 ? 1 : 7;

        for (int i = days - 1; i >= 0; i--) {
          final day = DateTime.now().subtract(Duration(days: i));
          final key = '${day.month}/${day.day}';
          byDay[key] = {'done': 0, 'pending': 0, 'cancelled': 0};
        }

        for (final appt in list) {
          final dt = DateTime.parse(appt['appointment_date']).toLocal();
          final key = '${dt.month}/${dt.day}';
          if (byDay.containsKey(key)) {
            final status = appt['status'] ?? 'pending';
            if (status == 'done') {
              byDay[key]!['done'] = byDay[key]!['done']! + 1;
            } else if (status == 'cancelled') {
              byDay[key]!['cancelled'] = byDay[key]!['cancelled']! + 1;
            } else {
              byDay[key]!['pending'] = byDay[key]!['pending']! + 1;
            }
          }
        }

        chartData = byDay.entries
            .map((e) => {
                  'label': e.key,
                  'done': e.value['done']!,
                  'pending': e.value['pending']!,
                  'cancelled': e.value['cancelled']!,
                  'total': e.value['done']! +
                      e.value['pending']! +
                      e.value['cancelled']!,
                })
            .toList();
      }

      setState(() {
        _totalCount = list.length;
        _doneCount = list.where((a) => a['status'] == 'done').length;
        _pendingCount = list
            .where(
                (a) => a['status'] == 'pending' || a['status'] == 'confirmed')
            .length;
        _cancelledCount = list.where((a) => a['status'] == 'cancelled').length;
        _chartData = chartData;
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2B47)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.bar_chart, color: Color(0xFF6B21A8)),
            SizedBox(width: 8),
            Text('Статистик',
                style: TextStyle(
                    color: Color(0xFF1A2B47), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Хугацаа сонгох
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Color(0xFF6B21A8), size: 18),
                  const SizedBox(width: 8),
                  const Text('Хугацаа:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  _buildPeriodTab('Өнөөдөр', 0),
                  const SizedBox(width: 8),
                  _buildPeriodTab('7 хоног', 1),
                  const SizedBox(width: 8),
                  _buildPeriodTab('1 сар', 2),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Статистик картууд
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child:
                          CircularProgressIndicator(color: Color(0xFF6B21A8)),
                    ),
                  )
                : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard(Icons.people_alt_rounded, 'Нийт цаг авсан',
                          _totalCount, const Color(0xFF1D61FF)),
                      _buildStatCard(Icons.check_circle_outline, 'Үйлчлүүлсэн',
                          _doneCount, const Color(0xFF22C55E)),
                      _buildStatCard(Icons.access_time_rounded, 'Хүлээж байгаа',
                          _pendingCount, const Color(0xFFFF6B35)),
                      _buildStatCard(Icons.cancel_outlined, 'Цуцалсан',
                          _cancelledCount, const Color(0xFFEF4444)),
                    ],
                  ),
            const SizedBox(height: 16),

            // Chart хэсэг — Horizontal progress bars
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Үйлчилгээний харьцаа',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A2B47))),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _totalCount == 0
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    Icon(Icons.bar_chart,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                        'Тухайн хугацаанд өгөгдөл байхгүй байна',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                _buildProgressRow(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: 'Үйлчлүүлсэн',
                                  count: _doneCount,
                                  color: const Color(0xFF22C55E),
                                ),
                                const SizedBox(height: 20),
                                _buildProgressRow(
                                  icon: Icons.access_time_rounded,
                                  label: 'Хүлээж байгаа',
                                  count: _pendingCount,
                                  color: const Color(0xFFFF6B35),
                                ),
                                const SizedBox(height: 20),
                                _buildProgressRow(
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
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, int index) {
    final isActive = _selectedPeriod == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = index);
        _loadStats();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6B21A8) : const Color(0xFFE9ECEF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, int count, Color color) {
    return Container(
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    final percent = _totalCount == 0 ? 0.0 : count / _totalCount;
    final percentText = '${(percent * 100).round()}%';

    return Column(
      children: [
        // Гарчиг мөр: icon + нэр | тоо (хувь)
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2B47),
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count хүн ($percentText)',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 14,
            backgroundColor: const Color(0xFFE9ECEF),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}