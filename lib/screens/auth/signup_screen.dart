import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:influencer_dashboard/screens/auth/signup_otp_screen.dart';
import 'package:influencer_dashboard/screens/webview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/dart/auth_services.dart';
import '../../services/dart/location_services.dart';

const Color kPrimaryPurple = Color(0xFF671DD1);

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthServices _authServices = AuthServices();
  final LocationServices _locationServices = LocationServices();

  bool _loading = false;
  bool _agreed = false;
  bool _submitted = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<Map<String, dynamic>> _allStates = [];
  Map<String, dynamic>? _selectedState;
  List<Map<String, dynamic>> _allCities = [];
  Map<String, dynamic>? _selectedCity;

  @override
  void initState() {
    super.initState();
    _fetchStates();
  }

  Future<void> _fetchStates() async {
    try {
      final states = await _locationServices.fetchStates();
      if (!mounted) return;
      setState(() {
        _allStates = states.where((s) => s['name'] != null).toList();
      });
    } catch (e) {
      // Optionally show a SnackBar for error
    }
  }

  Future<void> _fetchCities(String stateIso) async {
    setState(() {
      _allCities = [];
      _selectedCity = null;
    });
    try {
      final cities = await _locationServices.fetchCities(stateIso);
      if (!mounted) return;
      setState(() {
        _allCities = cities.where((c) => c['name'] != null).toList();
      });
    } catch (e) {
      // Optionally show a SnackBar for error
    }
  }

  void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WebViewScreen(title: "Terms and Conditions",url: 'https://collabuzz.com/terms.html'),
      ),
    );
  }

  Future<void> _sendOtp() async {
    setState(() => _submitted = true);

    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions')),
      );
      return;
    }

    setState(() => _loading = true);
    final phone = _phoneController.text.trim();

    try {
      final response = await _authServices.sendOtpSignup(phone);

      setState(() => _loading = false);

      if (response['status'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignupOtpScreen(
              phoneNumber: phone,
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              city: _selectedCity?['name'] ?? '',
              state: _selectedState?['name'] ?? '',
            ),
          ),
        );
      } else {
        final msg = response['message'] ?? 'Failed to send OTP.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      String errorMessage = 'Something went wrong';
      if (e is DioError) {
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic> && responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
      }
      // Optionally remove print in production.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose(); // Call at end
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: kPrimaryPurple),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Image.asset(
                                      'assets/logo.png',
                                      height: 30,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              onChanged: (_) {
                                if (_submitted) _formKey.currentState!.validate();
                              },
                              decoration: InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(fontFamily: 'Nunito'),
                              validator: (val) => !_submitted || val!.trim().isNotEmpty ? null : "Enter your name",
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              onChanged: (_) {
                                if (_submitted) _formKey.currentState!.validate();
                              },
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(fontFamily: 'Nunito'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (!_submitted) return null;
                                if (val == null || val.trim().isEmpty) return "Enter your email";
                                if (!val.contains('@')) return "Enter valid email";
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              onChanged: (_) {
                                if (_submitted) _formKey.currentState!.validate();
                              },
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(fontFamily: 'Nunito'),
                              validator: (val) {
                                if (!_submitted) return null;
                                if (val == null || val.trim().isEmpty) return "Enter phone number";
                                if (val.trim().length != 10) return "Enter valid 10-digit phone";
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              initialValue: "India",
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: 'Country',
                                labelStyle: const TextStyle(fontFamily: 'Nunito'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: TextStyle(fontFamily: 'Nunito', color: Colors.grey[800]),
                            ),
                            const SizedBox(height: 16),
                            DropdownSearch<Map<String, dynamic>>(
                              popupProps: const PopupProps.menu(showSearchBox: true),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "Select State",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              items: _allStates,
                              itemAsString: (item) => item['name'],
                              selectedItem: _selectedState,
                              onChanged: (value) {
                                setState(() {
                                  _selectedState = value;
                                  _selectedCity = null;
                                });
                                if (value != null && value['iso2'] != null) {
                                  _fetchCities(value['iso2']);
                                }
                              },
                              validator: (val) => !_submitted || val != null ? null : "Select a state",
                            ),
                            const SizedBox(height: 16),
                            DropdownSearch<Map<String, dynamic>>(
                              popupProps: const PopupProps.menu(showSearchBox: true),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "Select City",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              items: _allCities,
                              itemAsString: (item) => item['name'],
                              selectedItem: _selectedCity,
                              onChanged: (val) {
                                setState(() => _selectedCity = val);
                                if (_submitted) _formKey.currentState!.validate();
                              },
                              validator: (val) => !_submitted || val != null ? null : "Select a city",
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreed,
                                  activeColor: kPrimaryPurple,
                                  onChanged: (val) => setState(() => _agreed = val ?? false),
                                ),
                                GestureDetector(
                                  onTap: _openTerms,
                                  child: const Text(
                                    "I agree to Terms & Conditions",
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimaryPurple,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _loading
                                ? const Center(child: CircularProgressIndicator(color: kPrimaryPurple))
                                : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _agreed ? _sendOtp : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryPurple,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text('Send OTP',
                                    style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 36),
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
