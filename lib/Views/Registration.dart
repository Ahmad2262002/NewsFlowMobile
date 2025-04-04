import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newsflow/Controllers/RegistrationController.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final RegistrationController controller = Get.put(RegistrationController());
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Center(
          child: Text(
            "Registration",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTextField("Name", controller.name, focusNode: _nameFocusNode),
              _buildTextField("Email", controller.email, focusNode: _emailFocusNode),
              _buildTextField("Password", controller.password, obscureText: true, focusNode: _passwordFocusNode),
              _buildTextField("Confirm Password", controller.passwordConfirm, obscureText: true, focusNode: _confirmPasswordFocusNode),

              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    controller.register();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                  ),
                  child: Text(
                    "Register",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: Text(
                    "Back",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false, FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          focusNode: focusNode,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: "Enter your ${label.toLowerCase()}",
            hintStyle: TextStyle(color: Colors.white38),
          ),
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}