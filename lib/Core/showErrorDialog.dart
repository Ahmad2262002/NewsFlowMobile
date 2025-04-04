import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showErrorDialog(String title, String message) {
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
          color: Colors.red, // Red color for errors
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(), // Close the dialog
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