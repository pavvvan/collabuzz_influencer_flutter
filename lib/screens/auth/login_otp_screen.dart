import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/dart/auth_services.dart';
import '../dashboard_screen.dart';

const Color kPrimaryPurple = Color(0xFF671DD1);

class LoginOtpScreen extends StatefulWidget {
  final String phoneNumber;
  const LoginOtpScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
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
    if (mounted) {
      setState(() {
        _timer = 30;
        _resendEnabled = false;
      });
    }
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timer == 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _resendEnabled = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _timer--;
          });
        }
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

    final response = await _authServices.influencerLogin(widget.phoneNumber, otp);

    setState(() => _loading = false);

    if (response['status'] == true) {
      await _authServices.saveUserData(response);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP validated',
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

      await Future.delayed(Duration(seconds: 1));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
            (route) => false,
      );
    } else {
      final message = response['message'] ?? 'OTP did not match or login failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _onResend() {
    Navigator.pop(context);
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
          Positioned.fill(
            child: Container(), // Removed opacity layer to keep background vivid
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                          ? const Center(child: CircularProgressIndicator())
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
          )
        ],
      ),
    );
  }
}
