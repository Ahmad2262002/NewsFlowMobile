import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart'; // Explicitly hide Response from Dio
import 'package:flutter/material.dart' hide Feedback;
import 'package:get/get.dart' hide FormData, MultipartFile, Response; // Hide Response from Get too
import 'package:image_picker/image_picker.dart';
import 'package:newsflow/Core/Network/DioClient.dart';
import 'package:newsflow/Models/Article.dart';
import 'package:newsflow/Models/Comment.dart';
import 'package:newsflow/Models/Feedback.dart';
import 'package:newsflow/Routes/AppRoute.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mime_type/mime_type.dart';

class HomeController extends GetxController {
  late SharedPreferences prefs;
  var articles = <Article>[].obs;
  var isLoading = true.obs;
  Timer? _timer;

  var staff = <String, dynamic>{}.obs;
  var userProfile = <String, dynamic>{}.obs;
  var comments = <Comment>[].obs;
  var isLoadingComments = false.obs;
  var isSubmittingFeedback = false.obs;
  var articleCounts = <String, Map<String, int>>{}.obs;
  var isUpdatingProfile = false.obs;
  final RxString _profilePicturePath = ''.obs;

  var categories = <Map<String, dynamic>>[].obs;
  var selectedCategoryId = RxString('all'); // 'all' means no category filter
  var isLoadingCategories = false.obs;

  // Add these new variables for search functionality
  var filteredCategories = <Map<String, dynamic>>[].obs;
  var categorySearchQuery = ''.obs;

  String? get profilePicturePath => _profilePicturePath.value.isEmpty ? null : _profilePicturePath.value;
  set profilePicturePath(String? value) => _profilePicturePath.value = value ?? '';


  @override
  void onInit() async {
    super.onInit();
    await loadSharedPreferences();
    _loadArguments();
    await fetchCategories();
    // Initialize filtered categories with all categories
    filterCategories('');
    await getArticles();
    await fetchLikedArticles();

    _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
      await getArticles();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  final tempUsername = RxString('');
  final tempEmail = RxString('');

// Update loadSharedPreferences method
  Future<void> loadSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    final staffData = prefs.getString('staff');
    final userData = prefs.getString('userProfile');

    if (staffData != null) {
      staff.value = jsonDecode(staffData);
      tempUsername.value = staff['username'];
      tempEmail.value = staff['email'] ?? ''; //  to handle email
    }
    if (userData != null) {
      userProfile.value = jsonDecode(userData);
      tempEmail.value = staff['email'];
      profilePicturePath = userProfile['profile_picture'];
    }
  }

  void _loadArguments() {
    final arguments = Get.arguments;
    if (arguments != null) {
      staff.value = arguments['staff'] ?? {};
      userProfile.value = arguments['userProfile'] ?? {};
      profilePicturePath = userProfile['profile_picture'];

    }
  }

  Future<XFile?> pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      return pickedFile;
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
      return null;
    }
  }

  // In fetchCategories method - ensure we're accessing the correct field
  Future<void> fetchCategories() async {
    try {
      isLoadingCategories(true);
      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .get('/user/categories');

      if (response.statusCode == 200) {
        categories.value = (response.data['data'] as List)
            .map((category) => {
          'category_id': category['category_id']?.toString() ?? '', // Ensure ID is string
          'name': category['name'] ?? 'Unnamed Category',
          // Add other fields if needed
        })
            .where((category) => category['category_id'].isNotEmpty) // Filter out empty IDs
            .toList();

        debugPrint('Loaded categories: ${categories.length}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load categories: $e');
      categories.value = [];
    } finally {
      isLoadingCategories(false);
    }
  }

  void filterCategories(String query) {
    categorySearchQuery.value = query.toLowerCase();
    if (query.isEmpty) {
      filteredCategories.assignAll(categories);
    } else {
      filteredCategories.assignAll(categories.where((category) =>
          category['name'].toString().toLowerCase().contains(query)));
    }
    filteredCategories.refresh();
  }

// In getArticles method - improve category handling
  Future<void> getArticles() async {
    try {
      isLoading(true);
      articles.clear();

      final token = prefs.getString('token');
      if (token == null) {
        Get.snackbar('Error', 'No token found. Please log in again.');
        return;
      }

      // Ensure categories are loaded
      if (categories.isEmpty) {
        await fetchCategories();
      }

      final dio = DioClient(token: token).getInstance();
      Response response;
      bool fallbackToAll = false;

      if (selectedCategoryId.value == 'all') {
        response = await dio.get('/user/articles');
      } else {
        try {
          // First try the direct category endpoint
          response = await dio.get('/user/articles/categories/${selectedCategoryId.value}');

          // If empty response but category exists
          if (response.data['data'].isEmpty) {
            final categoryExists = categories.any((c) => c['category_id'] == selectedCategoryId.value);
            if (!categoryExists) {
              fallbackToAll = true;
              Get.snackbar('Info', 'Category not found, showing all articles');
            }
          }
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            fallbackToAll = true;
            Get.snackbar('Info', 'Category endpoint not found, trying client-side filter');

            // Fallback to client-side filtering
            response = await dio.get('/user/articles');
            final filtered = response.data['data']
                .where((article) => article['category_id']?.toString() == selectedCategoryId.value)
                .toList();

            if (filtered.isEmpty) {
              Get.snackbar('Info', 'No articles found for this category');
            } else {
              response.data['data'] = filtered;
            }
          } else {
            rethrow;
          }
        }

        if (fallbackToAll) {
          selectedCategoryId.value = 'all';
          response = await dio.get('/user/articles');
        }
      }

      if (response.statusCode == 200) {
        final articlesData = response.data['data'] as List;

        articles.value = articlesData
            .map((json) {
          if (json['article_photo'] != null &&
              !json['article_photo'].toString().startsWith('http')) {
            json['image_url'] = 'http://172.20.10.3:8000/storage/${json['article_photo']}';
          }
          return Article.fromJson(json);
        })
            .where((article) => article.status == 1)
            .toList();

        await Future.wait(
          articles.map((article) => fetchCounts(article.articleId.toString())),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load articles: ${e.toString()}');
      selectedCategoryId.value = 'all'; // Fallback to all on error
    } finally {
      isLoading(false);
    }
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString('user_profile');
    if (profileString != null) {
      userProfile = json.decode(profileString);
      profilePicturePath = userProfile['profile_picture'] ?? '';
    }
  }

  Future<void> fetchCounts(String articleId) async {
    try {
      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .get('/user/articles/$articleId/counts');

      if (response.statusCode == 200) {
        articleCounts[articleId] = {
          'likes': response.data['data']['like_count'] ?? 0,
          'comments': response.data['data']['comment_count'] ?? 0,
        };
        articleCounts.refresh();
      }
    } catch (e) {
      debugPrint('Error fetching counts for article $articleId: $e');
    }
  }

  int getLikeCount(String articleId) {
    return articleCounts[articleId]?['likes'] ?? 0;
  }

  int getCommentCount(String articleId) {
    return articleCounts[articleId]?['comments'] ?? 0;
  }

  Future<void> logout() async {
    try {
      final token = prefs.getString('token');
      if (token == null) {
        Get.snackbar('Error', 'No token found. Please log in again.');
        return;
      }

      final response = await DioClient(token: token).getInstance().post('/logout');
      if (response.statusCode == 200) {
        await prefs.clear();
        articles.clear();
        Get.offNamed(AppRoute.login);
        Get.snackbar('Success', 'Logged out successfully!');
      } else {
        throw Exception('Failed to logout: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout: $e');
    }
  }

  void toggleTheme() {
    Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
// Update these variables at the top of your controller
  var likedArticles = <String, int>{}.obs; // Stores articleId -> likeId mapping
  var isLoadingLikedArticles = false.obs;
  var isLikeActionInProgress = false.obs;

// Updated isArticleLiked method
  bool isArticleLiked(String articleId) {
    return likedArticles.containsKey(articleId);
  }

// Optimized like article method
  Future<void> likeArticle(String articleId) async {
    if (isLikeActionInProgress.value) return;
    isLikeActionInProgress.value = true;

    try {
      final userId = userProfile['user_id'];
      if (userId == null) throw Exception('User ID is null');

      // Check local state first
      if (likedArticles.containsKey(articleId)) {
        Get.snackbar('Info', 'Article is already liked');
        return;
      }

      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .post(
        '/user/articles/likes',
        data: {'user_id': userId, 'article_id': articleId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          // Update local state with the new like ID
          likedArticles[articleId] = response.data['data']['id'];
          Get.snackbar('Success', 'Article liked successfully');
          await fetchCounts(articleId);
        }
      } else if (response.statusCode == 400) {
        // If server says already liked, sync with server
        if (response.data['message']?.toLowerCase().contains('already liked') ?? false) {
          await fetchLikedArticles(); // Force sync with server
        }
        Get.snackbar('Info', response.data['message']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to like article');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      debugPrint('Error in likeArticle: $e');
    } finally {
      isLikeActionInProgress.value = false;
    }
  }

// Optimized unlike article method
  Future<void> unlikeArticle(String articleId) async {
    if (isLikeActionInProgress.value) return;
    isLikeActionInProgress.value = true;

    try {
      final userId = userProfile['user_id'];
      if (userId == null) throw Exception('User ID is null');

      // Check local state first
      if (!likedArticles.containsKey(articleId)) {
        Get.snackbar('Info', 'Article is not currently liked');
        return;
      }

      final likeId = likedArticles[articleId];
      if (likeId == null) {
        await fetchLikedArticles(); // Sync with server
        if (!likedArticles.containsKey(articleId)) {
          Get.snackbar('Info', 'Article is not liked');
          return;
        }
      }

      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .delete('/user/articles/likes/${likedArticles[articleId]}');

      if (response.statusCode == 200) {
        likedArticles.remove(articleId);
        Get.snackbar('Success', 'Article unliked successfully');
        await fetchCounts(articleId);
      } else if (response.statusCode == 404) {
        // Like not found - sync with server
        likedArticles.remove(articleId);
        await fetchLikedArticles();
        Get.snackbar('Info', 'Article was already unliked');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to unlike article');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      debugPrint('Error in unlikeArticle: $e');
    } finally {
      isLikeActionInProgress.value = false;
    }
  }

// Improved fetch liked articles method
  Future<void> fetchLikedArticles() async {
    try {
      isLoadingLikedArticles(true);

      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .get('/user/articles/liked-articles');

      if (response.statusCode == 200 && response.data['success'] == true) {
        likedArticles.clear();
        for (var article in response.data['data']) {
          likedArticles[article['id'].toString()] = article['like_id'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching liked articles: $e');
      Get.snackbar('Error', 'Failed to load liked articles');
    } finally {
      isLoadingLikedArticles(false);
    }
  }


  Future<void> fetchComments(String articleId) async {
    try {
      isLoadingComments(true);
      final response = await DioClient(token: prefs.getString('token')).getInstance().get(
        '/user/articles/$articleId/comments',
      );

      if (response.statusCode == 200) {
        comments.value = (response.data['data'] as List)
            .map((json) => Comment.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to fetch comments: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch comments: $e');
    } finally {
      isLoadingComments(false);
    }
  }

  Future<void> deleteComment(String commentId, String articleId) async {
    try {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final userId = userProfile['user_id'];
      if (userId == null) throw Exception('User not authenticated');

      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .delete(
        '/user/articles/comments/$commentId',
        data: {'user_id': userId},
      );

      Get.back();

      if (response.statusCode == 200) {
        comments.removeWhere((c) => c.commentId == commentId);
        await fetchCounts(articleId);
        Get.snackbar('Success', 'Comment deleted!', snackPosition: SnackPosition.BOTTOM);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete comment');
      }
    } on DioException catch (e) {
      Get.back();
      String errorMessage = e.response?.data['message'] ?? 'Failed to delete comment';
      Get.snackbar('Error', errorMessage, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.back();
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  void showCommentDialog(String articleId) {
    fetchComments(articleId);
    final commentController = TextEditingController();

    Get.dialog(
      Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.7,
            maxWidth: Get.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (isLoadingComments.value) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (comments.isEmpty) {
                    return Center(child: Text('No comments yet.'));
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final isCurrentUserComment = comment.userId == userProfile['user_id']?.toString();

                      return ListTile(
                        title: Text(comment.content),
                        subtitle: Text('Posted by: ${comment.userName}'),
                        trailing: isCurrentUserComment
                            ? IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteComment(comment.commentId, articleId),
                        )
                            : null,
                      );
                    },
                  );
                }),
              ),
              SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: Get.back,
                    child: Text('Close'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    child: Text('Post'),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        addComment(articleId, commentController.text);
                        commentController.clear();
                      } else {
                        Get.snackbar('Error', 'Please enter a comment');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteComment(String commentId, String articleId) async {
    final confirm = await Get.dialog(
      AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Get.back(result: false),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteComment(commentId, articleId);
    }
  }

  Future<void> addComment(String articleId, String content) async {
    try {
      final userId = userProfile['user_id'];
      if (userId == null) throw Exception('User ID is null');
      if (content.isEmpty) throw Exception('Comment cannot be empty');

      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .post(
        '/user/articles/$articleId/comments',
        data: {
          'user_id': userId,
          'content': content,
          'article_id': articleId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchComments(articleId);
        await fetchCounts(articleId);
        Get.snackbar('Success', 'Comment added!');
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add comment: $e');
    }
  }

  Future<Feedback?> submitFeedback(String articleId, String content, int rating) async {
    try {
      isSubmittingFeedback(true);

      if (content.isEmpty) {
        Get.snackbar('Error', 'Feedback content cannot be empty');
        return null;
      }

      if (rating < 1 || rating > 5) {
        Get.snackbar('Error', 'Rating must be between 1 and 5');
        return null;
      }

      final userId = userProfile['user_id'];
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated');
        return null;
      }

      final response = await DioClient(token: prefs.getString('token')).getInstance().post(
        '/user/articles/$articleId/feedbacks',
        data: {
          'user_id': userId,
          'article_id': articleId,
          'content': content,
          'rating': rating,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final feedback = Feedback.fromJson(response.data);
        Get.snackbar('Success', 'Feedback submitted!');
        return feedback;
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit feedback: ${e.toString()}');
      return null;
    } finally {
      isSubmittingFeedback(false);
    }
  }

  Future<void> shareArticle(String articleId, String articleTitle) async {
    try {
      final userId = userProfile['user_id'];
      if (userId == null) throw Exception('User ID is null');

      final response = await DioClient(token: prefs.getString('token')).getInstance().post(
        '/user/articles/$articleId/shares',
        data: {'user_id': userId, 'article_id': articleId},
      );

      if (response.statusCode == 201) {
        final shareableUrl = response.data['shareable_url'];
        await Share.share('Check out: $articleTitle\n$shareableUrl');
      } else {
        throw Exception('Failed to share: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share article: $e');
    }
  }



  Future<Map<String, dynamic>?> updateUserProfile({XFile? imageFile}) async {
    try {
      isUpdatingProfile(true);
      final dio = DioClient(token: prefs.getString('token')!).getInstance();
      final Map<String, dynamic> requestData = {};

      // Add username and email if they've changed
      if (tempUsername.value != staff['username']) {
        requestData['username'] = tempUsername.value;
      }
      if (tempEmail.value != staff['email']) {
        requestData['email'] = tempEmail.value;
      }

      // Handle image file
      if (imageFile != null) {
        final sizeInMB = (await imageFile.length()) / (1024 * 1024);
        if (sizeInMB > 5) {
          throw Exception('Image must be less than 5MB');
        }

        // Convert image to base64
        final bytes = await imageFile.readAsBytes();
        final mimeType = mime(imageFile.path) ?? 'image/jpeg';
        final base64Image = base64Encode(bytes);
        requestData['profile_picture'] = 'data:$mimeType;base64,$base64Image';
      }

      // Don't send empty requests
      if (requestData.isEmpty) {
        return null;
      }

      final response = await dio.put(
        '/profile',
        data: requestData,
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        // Update local data
        staff.value = data['staff'];
        userProfile.value = data['user'];
        profilePicturePath = data['user']['profile_picture'];

        // Update temp values
        tempUsername.value = data['staff']['username'];
        tempEmail.value = data['staff']['email'];

        // Save to shared preferences
        await prefs.setString('staff', jsonEncode(data['staff']));
        await prefs.setString('userProfile', jsonEncode(data['user']));

        return data;
      }
      return null;
    } catch (e) {
      // Revert temp values on error
      tempUsername.value = staff['username'];
      tempEmail.value = staff['email'];
      rethrow;
    } finally {
      isUpdatingProfile(false);
    }
  }







  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (newPassword != confirmPassword) {
        throw Exception('New passwords do not match');
      }

      final token = prefs.getString('token');
      if (token == null) throw Exception('No token found');

      final response = await DioClient(token: token).getInstance().put(
        '/profile/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to change password');
    }
  }

  handleResponse(Response response)  {
    if (response.statusCode == 200) {
      // Handle successful response
    } else {
      // Handle error response
    }
  }

  // Add this method to delete the account
  Future<void> deleteAccount() async {
    try {
      final token = prefs.getString('token');
      if (token == null) throw Exception('No token found');

      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final dio = DioClient(token: token).getInstance();
      final response = await dio.delete('/delete-account');

      // Close loading dialog
      Get.back();

      if (response.statusCode == 200) {
        // Clear all local data
        await prefs.clear();
        articles.clear();

        // Navigate to login screen
        Get.offAllNamed(AppRoute.login);
        Get.snackbar('Success', 'Your account has been deleted successfully');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete account');
      }
    } on DioException catch (e) {
      Get.back();
      final errorMessage = e.response?.data['message'] ?? 'Failed to delete account';
      Get.snackbar('Error', errorMessage);
    } catch (e) {
      Get.back();
      Get.snackbar('Error', e.toString());
    }
  }

// Add this method to show confirmation dialog
  void showDeleteAccountConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              deleteAccount();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}