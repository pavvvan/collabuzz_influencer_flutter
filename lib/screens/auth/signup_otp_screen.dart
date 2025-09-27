import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/dart/auth_services.dart';
import '../dashboard_screen.dart'; // Adjust this import as needed

const Color kPrimaryPurple = Color(0xFF671DD1);

class SignupOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String name;
  final String email;
  final String state;
  final String city;

  const SignupOtpScreen({
    Key? key,
    required this.phoneNumber,
    required this.name,
    required this.email,
    required this.state,
    required this.city,
  }) : super(key: key);

  @override
  State<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends State<SignupOtpScreen> {
  static const int _otpLength = 6;
  int _timer = 30;
  Timer? _countdownTimer;
  bool _resendEnabled = false;
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;

  final AuthServices _authServices = AuthServices();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _timer = 30;
      _resendEnabled = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timer == 0) {
        timer.cancel();
        setState(() => _resendEnabled = true);
      } else {
        setState(() => _timer--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a $_otpLength-digit OTP")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await _authServices.signupVerify(
        widget.phoneNumber,
        otp,
        name: widget.name,
        email: widget.email,
        city: widget.city,
        state: widget.state,
      );

      setState(() => _loading = false);

      if (response['status'] == true) {
        await _authServices.saveUserData(response);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Signup successful',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
        );
      } else {
        final message = response['message'] ?? 'OTP verification failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred, please try again.')),
      );
    }
  }

  void _onResend() {
    Navigator.pop(context);
    // The parent Signup screen can handle re-sending OTP as before
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: kPrimaryPurple, size: 28),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            const Text(
                              'OTP Verification',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Enter the verification code sent to ${widget.phoneNumber}",
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(_otpLength),
                              ],
                              maxLength: _otpLength,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryPurple,
                                letterSpacing: 32,
                              ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                counterText: '',
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: kPrimaryPurple.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: kPrimaryPurple, width: 2),
                                ),
                                hintText: 'OTP',
                                hintStyle: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 22,
                                  color: Colors.grey[400],
                                  letterSpacing: 16,
                                ),
                              ),
                              autofocus: true,
                              autofillHints: const [AutofillHints.oneTimeCode],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: _loading
                                  ? const Center(child: CircularProgressIndicator(color: kPrimaryPurple))
                                  : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryPurple,
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: _onVerify,
                                child: const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: _resendEnabled
                                  ? TextButton(
                                onPressed: _onResend,
                                child: const Text(
                                  "Resend OTP",
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    color: kPrimaryPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                                  : Text(
                                "Resend OTP in $_timer s",
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
