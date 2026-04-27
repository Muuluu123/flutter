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

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final days = _selectedPeriod == 0 ? 1 : (_selectedPeriod == 1 ? 7 : 30);
      final localStart = todayStart.subtract(Duration(days: days - 1));
      final localEnd = todayStart.add(const Duration(days: 1));

      final data = await Supabase.instance.client
          .from('appointments')
          .select('status, appointment_date')
          .gte('appointment_date', localStart.toUtc().toIso8601String())
          .lt('appointment_date', localEnd.toUtc().toIso8601String());

      final list = List<Map<String, dynamic>>.from(data);

      final Map<String, Map<String, int>> byDay = {};
      for (int i = days - 1; i >= 0; i--) {
        final d = todayStart.subtract(Duration(days: i));
        final key = '${d.month}/${d.day}';
        byDay[key] = {'done': 0, 'pending': 0, 'cancelled': 0};
      }

      for (final appt in list) {
        final dt = DateTime.parse(appt['appointment_date']).toLocal();
        final key = '${dt.month}/${dt.day}';
        if (byDay.containsKey(key)) {
          final status = appt['status']?.toString() ?? '';
          if (status == 'done') {
            byDay[key]!['done'] = byDay[key]!['done']! + 1;
          } else if (status == 'cancelled') {
            byDay[key]!['cancelled'] = byDay[key]!['cancelled']! + 1;
          } else {
            byDay[key]!['pending'] = byDay[key]!['pending']! + 1;
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
            // ── Хугацаа сонгох ──
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
                  const SizedBox(width: 6),
                  const Text('Хугацаа:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildPeriodTab('Өнөөдөр', 0)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildPeriodTab('7 хоног', 1)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildPeriodTab('1 сар', 2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Статистик картууд ──
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

            // ── Chart ──
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildLegend(const Color(0xFF22C55E), 'Үйлчлүүлсэн'),
                      _buildLegend(const Color(0xFFFF6B35), 'Хүлээж байгаа'),
                      _buildLegend(const Color(0xFFEF4444), 'Цуцалсан'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_totalCount == 0)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Тухайн хугацаанд өгөгдөл байхгүй байна',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildChart(),
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
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6B21A8) : const Color(0xFFE9ECEF),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 12,
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
      mainAxisSize: MainAxisSize.min,
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

  Widget _buildChart() {
    final maxVal = _chartData
        .map((d) => [
              d['done'] as int,
              d['pending'] as int,
              d['cancelled'] as int,
            ].fold(0, (a, b) => a > b ? a : b))
        .fold(0, (a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 220,
          child: CustomPaint(
            painter: GroupedBarPainter(
              data: _chartData,
              maxVal: maxVal == 0 ? 1 : maxVal,
              colorDone: const Color(0xFF22C55E),
              colorPending: const Color(0xFFFF6B35),
              colorCancelled: const Color(0xFFEF4444),
              colorEmpty: const Color(0xFFE9ECEF),
              colorLabel: Colors.grey,
            ),
            size: Size(constraints.maxWidth, 220),
          ),
        );
      },
    );
  }
}

// ── Grouped Bar Chart Painter ──
// Өдөр бүр 3 тусдаа багана: ногоон | улбар шар | улаан
class GroupedBarPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int maxVal;
  final Color colorDone;
  final Color colorPending;
  final Color colorCancelled;
  final Color colorEmpty;
  final Color colorLabel;

  static const double labelH = 18.0;
  static const double countH = 14.0;
  static const double topPad = 6.0;
  static const double barRadius = 3.0;
  static const double groupGap = 3.0; // багана хоорондын зай
  static const double slotGap = 4.0; // өдөр хоорондын зай

  const GroupedBarPainter({
    required this.data,
    required this.maxVal,
    required this.colorDone,
    required this.colorPending,
    required this.colorCancelled,
    required this.colorEmpty,
    required this.colorLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double barAreaH = size.height - labelH - countH - topPad;
    final int n = data.length;
    final double slotW = size.width / n;
    // Нэг өдрийн 3 багана + 2 зай
    final double barW = (slotW - slotGap * 2 - groupGap * 2) / 3;

    for (int i = 0; i < n; i++) {
      final d = data[i];
      final int done = d['done'] as int;
      final int pending = d['pending'] as int;
      final int cancelled = d['cancelled'] as int;
      final int total = d['total'] as int;
      final String label = d['label'] as String;

      final double slotLeft = slotW * i + slotGap;
      final double barBottom = topPad + countH + barAreaH;
      final double cx = slotW * i + slotW / 2;

      if (total == 0) {
        // Хоосон өдөр — нимгэн саарал зураас
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(slotLeft, barBottom - 2, slotW - slotGap * 2, 2),
            const Radius.circular(1),
          ),
          Paint()..color = colorEmpty,
        );
      } else {
        // Багана 1: Done (ногоон) — зүүн
        final double x0 = slotLeft;
        // Багана 2: Pending (улбар шар) — дунд
        final double x1 = slotLeft + barW + groupGap;
        // Багана 3: Cancelled (улаан) — баруун
        final double x2 = slotLeft + (barW + groupGap) * 2;

        _drawBar(canvas,
            x: x0,
            barBottom: barBottom,
            barW: barW,
            barAreaH: barAreaH,
            value: done,
            color: colorDone);

        _drawBar(canvas,
            x: x1,
            barBottom: barBottom,
            barW: barW,
            barAreaH: barAreaH,
            value: pending,
            color: colorPending);

        _drawBar(canvas,
            x: x2,
            barBottom: barBottom,
            barW: barW,
            barAreaH: barAreaH,
            value: cancelled,
            color: colorCancelled);
      }

      // Огноо шошго
      _txt(
        canvas,
        label,
        TextStyle(color: colorLabel, fontSize: 9, fontWeight: FontWeight.w400),
        Offset(cx, size.height - labelH / 2),
      );
    }
  }

  void _drawBar(
    Canvas canvas, {
    required double x,
    required double barBottom,
    required double barW,
    required double barAreaH,
    required int value,
    required Color color,
  }) {
    if (value == 0) {
      // 0 үед нимгэн саарал зураас
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, barBottom - 2, barW, 2),
          const Radius.circular(1),
        ),
        Paint()..color = colorEmpty,
      );
      return;
    }

    final double h = (value / maxVal) * barAreaH;
    final double top = barBottom - h;

    // Багана
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top, barW, h),
        topLeft: const Radius.circular(barRadius),
        topRight: const Radius.circular(barRadius),
        bottomLeft: const Radius.circular(1),
        bottomRight: const Radius.circular(1),
      ),
      Paint()..color = color,
    );

    // Тоо — баганын дээд талд
    final style = TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );
    final tp = TextPainter(
      text: TextSpan(text: '$value', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(x + barW / 2 - tp.width / 2, top - tp.height - 2),
    );
  }

  void _txt(Canvas canvas, String text, TextStyle style, Offset center) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(
        canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(GroupedBarPainter old) =>
      old.data != data || old.maxVal != maxVal;
}
