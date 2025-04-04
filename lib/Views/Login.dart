import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newsflow/Controllers/LoginController.dart';
import 'package:newsflow/Routes/AppRoute.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LoginController controller = Get.put(LoginController());
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
            "Login",
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
          child: Form(
            key: _formKey, // Form key for validation
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Email Field
                Text(
                  "Email",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: controller.email,
                  focusNode: _emailFocusNode,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: "Enter your email",
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (value) {
                    _emailFocusNode.unfocus();
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!GetUtils.isEmail(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Password Field
                Text(
                  "Password",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: controller.password,
                  focusNode: _passwordFocusNode,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: "Enter your password",
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                  style: TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (value) {
                    _passwordFocusNode.unfocus();
                    _submitForm();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Login Button
                Center(
                  child: Obx(() {
                    return ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => _submitForm(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                      ),
                      child: controller.isLoading.value
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Login",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 12),

                // Register Button
                Center(
                  child: TextButton(
                    onPressed: () {
                      Get.toNamed(AppRoute.register); // Navigate to registration screen
                    },
                    child: Text(
                      "Register",
                      style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Submit form and trigger login
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      controller.login();
    }
  }
}