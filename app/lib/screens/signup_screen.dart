import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/design/clean_card.dart';
import '../theme/colors.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  
  bool _isLoading = false;

  void _signup() async {
    FocusScope.of(context).unfocus();
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (email.isEmpty || password.isEmpty || nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await ApiService.register(email, password, nickname);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 성공! 로그인해주세요.')),
      );
      // Auto login or just pop?
      // For now, let's just navigate to Home directly if API logs in (it usually saves token)
      // But ApiService.signup might not save token.
      // Let's assume we need to login or it returns true.
      // If server returns token on signup, we can go to Home.
      // Assuming signup doesn't auto-login in this API wrapper logic (checking ApiService is not visible but assuming standard).
      // Let's just pop.
      Navigator.of(context).pop(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 실패. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimaryDay),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "회원가입",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "새로운 계정을 만들어보세요.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryDay,
                  ),
                ),
                const SizedBox(height: 40),

                CleanCard(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nicknameController,
                        decoration: _buildInputDecoration('닉네임', Icons.person_outline),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        decoration: _buildInputDecoration('이메일', Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _passwordController,
                        decoration: _buildInputDecoration('비밀번호', Icons.lock_outline),
                        obscureText: true,
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusOnline,
                                  foregroundColor: Colors.white,
                                  shape: ContinuousRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '가입하기',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
     return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondaryDay),
      prefixIcon: Icon(icon, color: AppColors.textSecondaryDay),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.borderDay),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.statusOnline),
      ),
    );
  }
}
