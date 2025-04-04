import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSuccessDialog(String title, String body, VoidCallback? callback) {
  Get.dialog(
    AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey, // Green color for success
        ),
      ),
      content: Text(
        body,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back(); // Close the dialog
            callback?.call(); // Invoke the callback if it exists
          },
          child: const Text(
            "OK",
            style: TextStyle(color: Colors.blue), // Button text color
          ),
        ),
      ],
    ),
    barrierDismissible: false, // Prevent dismissal by tapping outside
  );
}