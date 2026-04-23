import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VisitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const VisitDetailScreen({super.key, required this.appointment});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  bool _isDone = false;
  bool _isLoading = false;

  Map<String, String> _parseNotes(String? notes) {
    if (notes == null) return {};
    final result = <String, String>{};
    for (final line in notes.split('\n')) {
      if (line.startsWith('Тасаг: '))
        result['department'] = line.replaceFirst('Тасаг: ', '');
      if (line.startsWith('Эмч: '))
        result['doctor'] = line.replaceFirst('Эмч: ', '');
      if (line.startsWith('Шалтгаан: '))
        result['reason'] = line.replaceFirst('Шалтгаан: ', '');
      if (line.startsWith('Оношлогоо: '))
        result['diagnosis'] = line.replaceFirst('Оношлогоо: ', '');
      if (line.startsWith('Жор: '))
        result['prescription'] = line.replaceFirst('Жор: ', '');
    }
    return result;
  }

  String _formatDate(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final notes = _parseNotes(widget.appointment['notes']);
      String updatedNotes = 'Тасаг: ${notes['department'] ?? ''}';
      if ((notes['doctor'] ?? '').isNotEmpty)
        updatedNotes += '\nЭмч: ${notes['doctor']}';
      if ((notes['reason'] ?? '').isNotEmpty)
        updatedNotes += '\nШалтгаан: ${notes['reason']}';
      if (_diagnosisController.text.isNotEmpty)
        updatedNotes += '\nОношлогоо: ${_diagnosisController.text}';
      if (_prescriptionController.text.isNotEmpty)
        updatedNotes += '\nЖор: ${_prescriptionController.text}';

      await Supabase.instance.client.from('appointments').update({
        'status': _isDone ? 'done' : widget.appointment['status'],
        'notes': updatedNotes,
      }).eq('id', widget.appointment['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Амжилттай хадгалагдлаа!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _parseNotes(widget.appointment['notes']);
    final patientName = widget.appointment['patients']?['profiles']
            ?['full_name'] ??
        'Тодорхойгүй';
    final status = widget.appointment['status'] ?? 'pending';

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
            Icon(Icons.description_rounded, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Үйлчилгээний дэлгэрэнгүй',
                style: TextStyle(
                    color: Color(0xFF1A2B47),
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Үндсэн мэдээлэл карт
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Өвчтний нэр
                  _buildInfoRow(
                      Icons.person_outline, 'Өвчтний нэр', patientName),
                  const Divider(height: 24),

                  // Огноо & Цаг
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          Icons.calendar_today,
                          'Огноо',
                          _formatDate(widget.appointment['appointment_date']),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoRow(
                          Icons.access_time,
                          'Цаг',
                          _formatTime(widget.appointment['appointment_date']),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Тасаг / Эмч
                  _buildInfoRow(
                    Icons.local_hospital_outlined,
                    'Тасаг / Эмч',
                    '${notes['department'] ?? '-'}${notes['doctor'] != null ? ' - ${notes['doctor']}' : ''}',
                  ),

                  // Шалтгаан
                  if (notes['reason'] != null) ...[
                    const Divider(height: 24),
                    _buildInfoRow(Icons.description_outlined, 'Шалтгаан',
                        notes['reason']!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Үйлчлүүлсэн эсэх checkbox — зөвхөн pending үед
            if (status == 'pending' || status == 'confirmed')
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8)
                  ],
                ),
                child: CheckboxListTile(
                  value: _isDone,
                  onChanged: (val) => setState(() => _isDone = val ?? false),
                  title: const Text('Үйлчлүүлсэн эсэх',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2B47))),
                  activeColor: const Color(0xFF7C3AED),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const SizedBox(height: 16),

            // Оношлогоо
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description_outlined,
                          color: Color(0xFF7C3AED), size: 18),
                      SizedBox(width: 8),
                      Text('Оношлогоо',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A2B47))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _diagnosisController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Оношлогоо бичих...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF1F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Жор
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          color: Color(0xFF7C3AED), size: 18),
                      SizedBox(width: 8),
                      Text('Жор',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A2B47))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _prescriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Жор, зөвлөмж бичих...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF1F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Товчлуурууд
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Буцах',
                        style:
                            TextStyle(color: Color(0xFF7C3AED), fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Хадгалах',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A2B47))),
            ],
          ),
        ),
      ],
    );
  }
}
