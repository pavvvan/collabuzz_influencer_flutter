import 'package:flutter/material.dart';
import 'package:influencer_dashboard/services/dart/auth_services.dart';
import 'package:influencer_dashboard/services/dart/location_services.dart';

class BillingAddressPage extends StatefulWidget {
  const BillingAddressPage({super.key});

  @override
  State<BillingAddressPage> createState() => _BillingAddressPageState();
}

class _BillingAddressPageState extends State<BillingAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _pinController = TextEditingController();
  final _panController = TextEditingController();

  String? _state;
  String? _city;
  List<String> stateOptions = [];
  List<String> cityOptions = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndStates();
  }

  Future<void> _fetchProfileAndStates() async {
    final authService = AuthServices();
    final profile = await authService.getProfile();
    final states = await LocationServices().fetchStates();

    stateOptions = states.map((e) => e['name'] as String).toList();

    final billingAddresses = profile?['profileData']?['billingAddresses'];

    if (billingAddresses != null && billingAddresses.isNotEmpty) {
      final address = billingAddresses[0];

      _nameController.text = address['name'] ?? '';
      _address1Controller.text = address['address1'] ?? '';
      _address2Controller.text = address['address2'] ?? '';
      _pinController.text = address['pin'] ?? '';
      _panController.text = address['pan'] ?? '';
      _state = address['state'];
      _city = address['city'];

      if (_state != null && states.isNotEmpty) {
        final stateObj = states.firstWhere(
              (e) => e['name'] == _state,
          orElse: () => {},
        );

        if (stateObj.isNotEmpty) {
          final cities = await LocationServices().fetchCities(stateObj['iso2']);
          cityOptions = cities.map((e) => e['name'] as String).toList();
        }
      }
    } else {
      // handle case where no billing address exists
      debugPrint("No billing address found in profile");
    }


    setState(() => loading = false);
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final billingAddress = {
      "name": _nameController.text.trim(),
      "address1": _address1Controller.text.trim(),
      "address2": _address2Controller.text.trim(),
      "city": _city,
      "state": _state,
      "country": "India",
      "pin": _pinController.text.trim(),
      "pan": _panController.text.trim(),
    };

    final authService = AuthServices();
    await authService.updateProfile({"billingAddresses": [billingAddress]});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Billing Address'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField(_nameController, 'Full Name'),
                _buildTextField(_address1Controller, 'Address Line 1'),
                _buildTextField(_address2Controller, 'Address Line 2'),
                _buildDropdownField('State', _state, stateOptions, (val) async {
                  setState(() {
                    _state = val;
                    _city = null;
                    cityOptions = [];
                  });
                  final states = await LocationServices().fetchStates();
                  final stateObj = states.firstWhere((e) => e['name'] == val, orElse: () => {});
                  if (stateObj.isNotEmpty) {
                    final cities = await LocationServices().fetchCities(stateObj['iso2']);
                    setState(() {
                      cityOptions = cities.map((e) => e['name'] as String).toList();
                    });
                  }
                }),
                _buildDropdownField('City', _city, cityOptions, (val) => setState(() => _city = val)),
                _buildTextField(_pinController, 'PIN Code'),
                _buildTextField(_panController, 'PAN Number'),
                const SizedBox(height: 10),
                _buildReadOnlyField('Country', 'India'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF671DD1),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Address'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        value: items.contains(value) ? value : null,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      ),
    );
  }
}
