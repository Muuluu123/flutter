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
  bool _isEditMode = false; // засах горим

  @override
  void initState() {
    super.initState();
    final notes = _parseNotes(widget.appointment['notes']);
    // Одоо байгаа утгыг controller-д ачааллах
    _diagnosisController.text = notes['diagnosis'] ?? '';
    _prescriptionController.text = notes['prescription'] ?? '';
    _isDone = widget.appointment['status'] == 'done';
  }

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

      String newStatus = widget.appointment['status'];
      if (_isDone) newStatus = 'done';

      await Supabase.instance.client.from('appointments').update({
        'status': newStatus,
        'notes': updatedNotes,
      }).eq('id', widget.appointment['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Амжилттай хадгалагдлаа!'),
            backgroundColor: Colors.green),
      );
      setState(() => _isEditMode = false);
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
    final isPending = status == 'pending' || status == 'confirmed';
    final isDone = status == 'done';

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
        actions: [
          // done статустай үед засах товч
          if (isDone)
            TextButton.icon(
              onPressed: () => setState(() => _isEditMode = !_isEditMode),
              icon: Icon(
                _isEditMode ? Icons.visibility : Icons.edit_outlined,
                size: 18,
                color: const Color(0xFF7C3AED),
              ),
              label: Text(
                _isEditMode ? 'Харах' : 'Засах',
                style: const TextStyle(color: Color(0xFF7C3AED)),
              ),
            ),
        ],
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
                  _buildInfoRow(
                      Icons.person_outline, 'Өвчтний нэр', patientName),
                  const Divider(height: 24),
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
                  _buildInfoRow(
                    Icons.local_hospital_outlined,
                    'Тасаг / Эмч',
                    '${notes['department'] ?? '-'}${notes['doctor'] != null ? ' - ${notes['doctor']}' : ''}',
                  ),
                  if (notes['reason'] != null) ...[
                    const Divider(height: 24),
                    _buildInfoRow(Icons.description_outlined, 'Шалтгаан',
                        notes['reason']!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pending үед checkbox
            if (isPending)
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
            if (isPending) const SizedBox(height: 16),

            // DONE + харах горим: оношлогоо, жор уншигдах байдлаар
            if (isDone && !_isEditMode) ...[
              // Оношлогоо харах
              Container(
                width: double.infinity,
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
                            color: Color(0xFF22C55E), size: 18),
                        SizedBox(width: 8),
                        Text('Оношлогоо',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A2B47))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: notes['diagnosis'] != null
                            ? const Color(0xFFF0FFF4)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: notes['diagnosis'] != null
                            ? Border.all(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Text(
                        notes['diagnosis'] ?? 'Оношлогоо бичигдээгүй байна',
                        style: TextStyle(
                          fontSize: 14,
                          color: notes['diagnosis'] != null
                              ? const Color(0xFF1A2B47)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Жор харах
              Container(
                width: double.infinity,
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
                            color: Color(0xFF1D61FF), size: 18),
                        SizedBox(width: 8),
                        Text('Жор',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A2B47))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: notes['prescription'] != null
                            ? const Color(0xFFF0F4FF)
                            : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: notes['prescription'] != null
                            ? Border.all(
                                color: const Color(0xFF1D61FF)
                                    .withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Text(
                        notes['prescription'] ?? 'Жор бичигдээгүй байна',
                        style: TextStyle(
                          fontSize: 14,
                          color: notes['prescription'] != null
                              ? const Color(0xFF1A2B47)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Буцах товч
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Буцах',
                      style: TextStyle(color: Color(0xFF7C3AED), fontSize: 16)),
                ),
              ),
            ],

            // Pending үед эсвэл done + засах горим: бичих талбарууд
            if (isPending || (isDone && _isEditMode)) ...[
              // Оношлогоо бичих
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

              // Жор бичих
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
                      onPressed: () {
                        if (isDone && _isEditMode) {
                          setState(() => _isEditMode = false);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isDone && _isEditMode ? 'Болих' : 'Буцах',
                        style: const TextStyle(
                            color: Color(0xFF7C3AED), fontSize: 16),
                      ),
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
