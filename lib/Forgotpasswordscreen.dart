import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final bool isStaff;
  const ForgotPasswordScreen({super.key, required this.isStaff});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final username = _usernameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Inline validation
    if (username.isEmpty || lastName.isEmpty || phone.isEmpty ||
        newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Бүх талбарыг бөглөнө үү!');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Нууц үг тохирохгүй байна!');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Нууц үг багадаа 6 тэмдэгт байна!');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final result = await Supabase.instance.client.rpc(
        'change_password_by_identity',
        params: {
          'p_username': username,
          'p_lastname': lastName,
          'p_phone': phone,
          'p_new_password': newPassword,
          'p_is_staff': widget.isStaff,
        },
      );

      if (!mounted) return;

      final success = result['success'] as bool;
      final message = result['message'] as String;

      if (success) {
        // Success хуудас харуулаад login руу буцах
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Color(0xFF22C55E), size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('Амжилттай!',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2B47))),
                  const SizedBox(height: 10),
                  const Text(
                    'Нууц үг амжилттай солигдлоо. Нэвтрэх хуудас руу шилжиж байна...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.of(context)
          ..pop() // dialog
          ..pop(); // forgot screen
      } else {
        setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Уучлаарай, таны оруулсан мэдээлэл буруу байна!');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isStaff ? const Color(0xFF6B21A8) : const Color(0xFF1D61FF);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FF),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_reset_outlined,
                      color: color, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Нууц үг сэргээх',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B47)),
                ),
                const Text(
                  'Мэдээллээ оруулж нууц үгээ солино уу',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),

                _buildField('Нэвтрэх нэр', Icons.person_outline,
                    'Нэвтрэх нэр', _usernameController),
                const SizedBox(height: 14),
                _buildField('Овог', Icons.badge_outlined,
                    'Овог', _lastNameController),
                const SizedBox(height: 14),
                _buildField('Утасны дугаар', Icons.phone_outlined,
                    'Утасны дугаар', _phoneController,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildField('Шинэ нууц үг', Icons.lock_outline,
                    'Шинэ нууц үг', _newPasswordController,
                    isPassword: true),
                const SizedBox(height: 14),
                _buildField('Нууц үг дахин оруулах', Icons.lock_outline,
                    'Нууц үг дахин оруулах', _confirmPasswordController,
                    isPassword: true),

                // Inline алдааны мэдэгдэл
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade400, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Нууц үг солих',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 14),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('← Нэвтрэх хуудас руу буцах',
                      style: TextStyle(color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1A2B47))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          onChanged: (_) {
            if (_errorMessage.isNotEmpty) {
              setState(() => _errorMessage = '');
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            filled: true,
            fillColor: const Color(0xFFF1F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}