import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:influencer_dashboard/screens/auth/login_otp_screen.dart';
import 'package:influencer_dashboard/screens/auth/signup_screen.dart';
import '../../services/dart/auth_services.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Color purpleColor = const Color(0xFF671DD1);
  final TextEditingController _phoneController = TextEditingController();
  bool _keepSignedIn = true;
  bool _loading = false;

  final AuthServices _authServices = AuthServices();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _navigateToOtp() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() => _loading = true);
    final response = await _authServices.sendOtpLogin(phoneNumber);
    setState(() => _loading = false);

    if (response['status'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginOtpScreen(phoneNumber: phoneNumber),
        ),
      );
    } else {
      final message = response['message'] ??
          'Failed to send OTP. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/login_bg.png',
            fit: BoxFit.cover,
          ),

          // Optional overlay for contrast
          Container(
            color: Colors.black.withOpacity(0.05),
          ),

          // Foreground login UI
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    // Centered Logo
                    Center(
                      child: Image.asset(
                        'assets/logo.png',
                        height: 25,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 100),
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        fontSize: 35,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enter your phone number',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            color: Colors.grey.shade100,
                          ),
                          child: Text(
                            '+91',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            ),
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Phone number',
                                hintStyle: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _keepSignedIn,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _keepSignedIn = value);
                            }
                          },
                          activeColor: purpleColor,
                        ),
                        Text(
                          'Keep me signed in',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _loading
                          ? Center(child: CircularProgressIndicator(color: purpleColor))
                          : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purpleColor,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _navigateToOtp,
                        child: const Text(
                          'Get OTP',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: purpleColor, width: 2),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignupScreen()),
                          );
                        },
                        child: Text(
                          'Create New Account',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: purpleColor,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}