import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/dart/auth_services.dart';
import '../../services/dart/location_services.dart';
import 'package:image_cropper/image_cropper.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});


  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
   Color kPrimaryPurple = Color(0xFF671DD1);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _panController = TextEditingController();
  final _ethicsController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _email, _phone;
  String? _gender;
  int? _age;
  String? _city;
  String? _state;
  String? _influencerType;
  String? _category;
  List<String> _targetAudience = [];

  List<String> genderOptions = ['male', 'female', 'other'];
  List<int> ageOptions = List.generate(85, (index) => 16 + index);
  List<String> stateOptions = [];
  List<String> cityOptions = [];
  List<String> influencerTypeOptions = [];
  List<String> categoryOptions = [];
  List<String> targetAudienceOptions = [];

  bool loading = true;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final authService = AuthServices();
    final profile = await authService.getProfile();
    final metadata = await authService.getMetadata();
    final states = await LocationServices().fetchStates();
    stateOptions = states.map((e) => e['name'] as String).toList();

    if (profile != null) {
      _nameController.text = profile['profileData']['influencerName'] ?? '';
      _email = profile['profileData']['email'];
      _phone = profile['profileData']['phone'];
      _bioController.text = profile['profileData']['bio'] ?? '';
      _panController.text = profile['profileData']['influencerPan'] ?? '';
      _tagsController.text = (profile['profileData']['tags'] as List<dynamic>?)?.join(', ') ?? '';
      _ethicsController.text = profile['profileData']['ethics'] ?? '';
      _gender = profile['profileData']['gender'];
      _age = profile['profileData']['age'];
      _city = profile['profileData']['city'];
      _state = profile['profileData']['state'];
      _influencerType = profile['profileData']['influencerType'];
      _category = profile['profileData']['category'];
      _targetAudience = List<String>.from(profile['profileData']['targetAudience'] ?? []);
      profileImageUrl = profile['profileData']['profileImage'];

      if (_state != null) {
        final stateObj = states.firstWhere((e) => e['name'] == _state, orElse: () => {});
        if (stateObj.isNotEmpty) {
          final cities = await LocationServices().fetchCities(stateObj['iso2']);
          cityOptions = cities.map((e) => e['name'] as String).toList();
        }
      }
    }

    influencerTypeOptions = List<String>.from(metadata?['InfluencerType'].map((e) => e['influencerTypeName']));
    categoryOptions = List<String>.from(metadata?['InfluencerCategory'].map((e) => e['influencerCategoryName']));
    targetAudienceOptions = List<String>.from(metadata?['TargentAudience'].map((e) => e['targetAudienceName']));

    setState(() {
      loading = false;
    });
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImagePick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImagePick(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text.split(',').map((e) => e.trim()).toList();
    final updatedData = {
      "influencerName": _nameController.text.trim(),
      "bio": _bioController.text.trim(),
      "influencerPan": _panController.text.trim(),
      "ethics": _ethicsController.text.trim(),
      "tags": tags,
      "gender": _gender,
      "age": _age,
      "state": _state,
      "city": _city,
      "profileImage": profileImageUrl,
      "influencerType": _influencerType,
      "category": _category,
      "targetAudience": _targetAudience
    };

    final authService = AuthServices();
    await authService.updateProfile(updatedData);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 4,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                          child: profileImageUrl == null ? const Icon(Icons.person, size: 40) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: kPrimaryPurple,
                              child: const Icon(Icons.edit, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoDisplay("Email", _email),
                          _infoDisplay("Phone", _phone),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(_nameController, 'Name'),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('Gender', _gender, genderOptions, (val) => setState(() => _gender = val))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdownField('Age', _age?.toString(), ageOptions.map((e) => e.toString()).toList(), (val) => setState(() => _age = int.tryParse(val!)))),
                  ],
                ),
                _buildTextField(_bioController, 'Bio'),
                _buildTextField(_panController, 'PAN'),
                _buildTextField(_tagsController, 'Hashtags (comma separated)'),
                _buildTextField(_ethicsController, 'Ethics'),
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
                _buildDropdownField('Influencer Type', _influencerType, influencerTypeOptions, (val) => setState(() => _influencerType = val)),
                _buildDropdownField('Category', _category, categoryOptions, (val) => setState(() => _category = val)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  
                ),
                const SizedBox(height: 6),
                _buildMultiSelectDropdown(
                  label: "Target Audience",
                  selectedItems: _targetAudience,
                  allItems: targetAudienceOptions,
                  onSelectionChanged: (selected) {
                    setState(() {
                      _targetAudience = selected;
                    });
                  },
                  maxSelection: 5,
                ),


                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Profile', style: TextStyle(fontSize: 16)),
                  ),
                )
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

   Widget _buildMultiSelectDropdown({
     required String label,
     required List<String> selectedItems,
     required List<String> allItems,
     required Function(List<String>) onSelectionChanged,
     int maxSelection = 5,
   }) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
         const SizedBox(height: 6),
         Wrap(
           spacing: 6,
           runSpacing: 4,
           children: [
             // Selected items as chips
             ...selectedItems.map((e) => Chip(
               label: Text(e),
               onDeleted: () {
                 final newList = List<String>.from(selectedItems)..remove(e);
                 onSelectionChanged(newList);
               },
             )),

             // Add More Button
             if (selectedItems.length < maxSelection)
               ActionChip(
                 label: const Text("+ Add More"),
                 onPressed: () async {
                   final List<String> tempSelected = List.from(selectedItems);

                   await showDialog(
                     context: context,
                     builder: (_) {
                       return StatefulBuilder(
                         builder: (context, setStateDialog) {
                           return AlertDialog(
                             shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(16)),
                             title: Text("Select $label"),
                             content: SizedBox(
                               width: double.maxFinite,
                               child: ListView(
                                 shrinkWrap: true,
                                 children: allItems.map((item) {
                                   final isSelected = tempSelected.contains(item);
                                   return CheckboxListTile(
                                     title: Text(item),
                                     value: isSelected,
                                     onChanged: (bool? checked) {
                                       if (checked == true) {
                                         if (tempSelected.length < maxSelection) {
                                           tempSelected.add(item);
                                         } else {
                                           ScaffoldMessenger.of(context)
                                               .showSnackBar(const SnackBar(
                                             content: Text(
                                                 "Max 5 selections allowed."),
                                           ));
                                         }
                                       } else {
                                         tempSelected.remove(item);
                                       }
                                       setStateDialog(() {});
                                     },
                                   );
                                 }).toList(),
                               ),
                             ),
                             actions: [
                               TextButton(
                                 onPressed: () => Navigator.pop(context),
                                 child: const Text("Cancel"),
                               ),
                               ElevatedButton(
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: const Color(0xFF671DD1),
                                   foregroundColor: Colors.white,
                                   shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(8)),
                                 ),
                                 onPressed: () {
                                   onSelectionChanged(tempSelected);
                                   Navigator.pop(context);
                                 },
                                 child: const Text("OK"),
                               ),
                             ],
                           );
                         },
                       );
                     },
                   );
                 },
               ),
           ],
         ),
       ],
     );
   }


   void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "You have permanently denied storage/gallery access. "
              "Please open settings and allow permission to upload your profile image.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }


   Future<void> _handleImagePick(ImageSource source) async {
     PermissionStatus permission;

     if (source == ImageSource.camera) {
       permission = await Permission.camera.request();
     } else {
       // Gallery permission handling (cross-platform)
       if (Platform.isIOS) {
         permission = await Permission.photos.request();
       } else {
         // For Android 13+ use Permission.photos or Permission.mediaLibrary
         if (await Permission.photos.isGranted || await Permission.photos.request().isGranted) {
           permission = PermissionStatus.granted;
         } else {
           permission = await Permission.photos.request();
         }
       }
     }

     // Handle denied or permanently denied
     if (permission.isPermanentlyDenied) {
       _showPermissionDialog();
       return;
     }

     if (!permission.isGranted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Permission denied. Please enable it in settings.')),
       );
       return;
     }

     final picker = ImagePicker();
     final pickedFile = await picker.pickImage(source: source);
     if (pickedFile == null) return;

     // Crop the image
     final croppedFile = await ImageCropper().cropImage(
       sourcePath: pickedFile.path,
       compressFormat: ImageCompressFormat.jpg,
       compressQuality: 85,
       aspectRatioPresets: [
         CropAspectRatioPreset.square,
         CropAspectRatioPreset.original,
         CropAspectRatioPreset.ratio4x3,
         CropAspectRatioPreset.ratio16x9,
       ],
       uiSettings: [
         AndroidUiSettings(
           toolbarTitle: 'Crop Image',
           toolbarColor: Colors.purple,
           toolbarWidgetColor: Colors.white,
           initAspectRatio: CropAspectRatioPreset.original,
           lockAspectRatio: false,
         ),
         IOSUiSettings(title: 'Crop Image'),
       ],
     );

     if (croppedFile == null) return;

     final authService = AuthServices();
     final imageUrl = await authService.uploadProfileImage(File(croppedFile.path));
     if (imageUrl != null) {
       setState(() {
         profileImageUrl = imageUrl;
       });
     }
   }



  }

  Widget _infoDisplay(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value ?? '', overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

