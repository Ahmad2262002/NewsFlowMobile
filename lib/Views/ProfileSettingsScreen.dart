import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newsflow/Controllers/HomeController.dart';
import 'change_password.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final HomeController _controller = Get.find();
  final _formKey = GlobalKey<FormState>();
  XFile? _pickedImage;
  bool _isUploading = false;

  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: _controller.staff['username']);
    _emailController = TextEditingController(text: _controller.staff['email']);

    // ✅ Initialize temp values
    _controller.tempUsername.value = _controller.staff['username'];
    _controller.tempEmail.value = _controller.staff['email'];
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);
    try {
      final response = await _controller.updateUserProfile(imageFile: _pickedImage);

      if (response != null) {
        _usernameController.text = _controller.staff['username'];
        _emailController.text = _controller.staff['email'];
        if (_pickedImage != null) setState(() => _pickedImage = null);

        Get.snackbar('Success', 'Profile updated successfully', snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Info', 'No changes were made', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      _usernameController.text = _controller.staff['username'];
      _emailController.text = _controller.staff['email'];
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}', snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  ImageProvider? _getProfileImage() {
    try {
      if (_pickedImage != null) return FileImage(File(_pickedImage!.path));

      final profilePic = _controller.profilePicturePath;
      if (profilePic != null && profilePic.isNotEmpty) {
        // Check if it's already a full URL
        if (profilePic.startsWith('http')) {
          return NetworkImage(
            profilePic,
            headers: {'Authorization': 'Bearer ${_controller.prefs.getString('token')}'},
          );
        }
        // Otherwise construct the full URL
        return NetworkImage(
          'http://172.20.10.3:8000/storage/$profilePic',
          headers: {'Authorization': 'Bearer ${_controller.prefs.getString('token')}'},
        );
      }
      return null;
    } catch (e) {
      debugPrint('Image load error: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        final fileSize = (await File(pickedFile.path).length()) / (1024 * 1024);
        if (fileSize > 5) {
          Get.snackbar('Error', 'Image must be less than 5MB');
          return;
        }
        setState(() => _pickedImage = pickedFile);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : () => Get.to(() => const ChangePasswordScreen()),
            child: const Text('Change Password'),
          )
        ],
      ),
      body: Obx(() => Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getProfileImage(),
                            child: _getProfileImage() == null
                                ? Icon(Icons.camera_alt, size: 40, color: Colors.blue[800])
                                : null,
                          ),
                          if (_isUploading)
                            const Positioned.fill(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _usernameController,
                    onChanged: (value) => _controller.tempUsername.value = value,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter username';
                      if (value.length < 3) return 'At least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    onChanged: (value) => _controller.tempEmail.value = value,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter email';
                      if (!GetUtils.isEmail(value)) return 'Invalid email format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[700],
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Blurred loading overlay
          if (_isUploading)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isUploading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      )),
    );
  }
}
