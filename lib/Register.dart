import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isUser = true;
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бүх талбарыг бөглөнө үү')),
      );
      return;
    }

    // Нэвтрэх нэрт зай байж болохгүй
    if (username.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нэвтрэх нэрт зай байж болохгүй')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нууц үг тохирохгүй байна')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нууц үг багадаа 6 тэмдэгт байна')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Нэвтрэх нэрийг email хэлбэрт хувиргах
    final fakeEmail = '$username@hospital.mn';

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: fakeEmail,
        password: password,
        data: {
          'username': username,
          'full_name': lastName,
          'phone': phone,
          'role': isUser ? 'patient' : 'staff',
        },
      );

      if (!mounted) return;

      if (response.user != null) {
        final userId = response.user!.id;

        if (isUser) {
          await Supabase.instance.client.from('patients').insert({
            'profile_id': userId,
          });
        } else {
          await Supabase.instance.client.from('staff').insert({
            'profile_id': userId,
          });
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бүртгэл амжилттай! Нэвтэрнэ үү.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа гарлаа: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_outlined,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text('Эмнэлгийн Систем',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B47))),
                const Text('Бүртгүүлэх',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 30),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9ECEF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTab('Үйлчлүүлэгч', true),
                      _buildTab('Дотоод ажилтан', false),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                _buildInputField(
                  label: 'Нэвтрэх нэр *',
                  icon: Icons.person_outline,
                  hint: 'жишээ: boldoo123',
                  controller: _usernameController,
                ),
                const SizedBox(height: 8),
                // Нэвтрэх нэрийн тайлбар
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '* Зөвхөн үсэг, тоо ашиглана уу. Зай байж болохгүй.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Овог нэр *',
                  icon: Icons.badge_outlined,
                  hint: 'О.Мөнхлөн',
                  controller: _lastNameController,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Утасны дугаар *',
                  icon: Icons.phone_outlined,
                  hint: '99001122',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Нууц үг *',
                  icon: Icons.lock_outline,
                  hint: 'Нууц үг (багадаа 6 тэмдэгт)',
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Нууц үг давтах *',
                  icon: Icons.lock_outline,
                  hint: 'Нууц үг давтах',
                  isPassword: true,
                  controller: _confirmPasswordController,
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Бүртгүүлэх',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Аль хэдийн бүртгэлтэй юу? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('Нэвтрэх',
                          style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool tabIsUser) {
    final isActive = isUser == tabIsUser;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isUser = tabIsUser),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4)
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF1F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }
}
