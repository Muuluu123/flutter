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

      // Өдөр тус бүрээр группэлэх — status-аар ялгана
      final Map<String, Map<String, int>> byDay = {};
      final days = _selectedPeriod == 0 ? 1 : (_selectedPeriod == 1 ? 7 : 30);

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
            byDay[key]!['done'] = (byDay[key]!['done'] ?? 0) + 1;
          } else if (status == 'cancelled') {
            byDay[key]!['cancelled'] = (byDay[key]!['cancelled'] ?? 0) + 1;
          } else {
            byDay[key]!['pending'] = (byDay[key]!['pending'] ?? 0) + 1;
          }
        }
      }

      final chartData = byDay.entries
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

            // Chart хэсэг
            Container(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 12),

                  // Тайлбар (legend)
                  Row(
                    children: [
                      _buildLegend(const Color(0xFF22C55E), 'Үйлчлүүлсэн'),
                      const SizedBox(width: 16),
                      _buildLegend(const Color(0xFFFF6B35), 'Хүлээж байгаа'),
                      const SizedBox(width: 16),
                      _buildLegend(const Color(0xFFEF4444), 'Цуцалсан'),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                          : SizedBox(
                              height: 120,
                              child: ClipRect(child: _buildStackedBarChart()),
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

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildStackedBarChart() {
    final maxTotal = _chartData
        .map((d) => (d['total'] as int))
        .fold(0, (a, b) => a > b ? a : b);
    final displayMax = maxTotal == 0 ? 1 : maxTotal;
    const barHeight = 80.0;

    return SizedBox(
      height: barHeight + 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _chartData.map((data) {
          final total = data['total'] as int;
          final done = data['done'] as int;
          final pending = data['pending'] as int;
          final cancelled = data['cancelled'] as int;
          final totalHeight = (total / displayMax) * barHeight;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (total > 0)
                    Text('$total',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B21A8))),
                  const SizedBox(height: 2),
                  // Stacked bar
                  SizedBox(
                    height: totalHeight,
                    child: Column(
                      children: [
                        // Цуцалсан — дээд
                        if (cancelled > 0)
                          SizedBox(
                            height: totalHeight * cancelled / total,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.vertical(
                                  top: const Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        // Хүлээж байгаа — дунд
                        if (pending > 0)
                          SizedBox(
                            height: totalHeight * pending / total,
                            child: Container(
                              color: const Color(0xFFFF6B35),
                            ),
                          ),
                        // Үйлчлүүлсэн — доод
                        if (done > 0)
                          SizedBox(
                            height: totalHeight * done / total,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                borderRadius: BorderRadius.vertical(
                                  bottom: const Radius.circular(4),
                                  top: Radius.circular(
                                      pending == 0 && cancelled == 0 ? 4 : 0),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(data['label'],
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
