import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:newsflow/Core/Network/DioClient.dart';
import 'package:newsflow/Models/Article.dart';
import 'package:newsflow/Models/Comment.dart';
import 'package:newsflow/Models/Feedback.dart';
import 'package:newsflow/Routes/AppRoute.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mime_type/mime_type.dart';

import 'ThemeController.dart';

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
  var selectedCategoryId = RxString('all');
  var isLoadingCategories = false.obs;

  // Pagination variables
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var hasMore = true.obs;

  var filteredCategories = <Map<String, dynamic>>[].obs;
  var categorySearchQuery = ''.obs;

  String? get profilePicturePath => _profilePicturePath.value.isEmpty ? null : _profilePicturePath.value;
  set profilePicturePath(String? value) => _profilePicturePath.value = value ?? '';
  String get userId {
    if (userProfile['user_id'] != null) {
      return userProfile['user_id'].toString();
    }
    if (staff['staff_id'] != null) {
      return staff['staff_id'].toString();
    }
    throw Exception('User ID not available. Please login again.');
  }


  @override
  void onInit() async {
    super.onInit();
    await loadSharedPreferences();
    _loadArguments();
    await fetchCategories();
    filterCategories('');
    await getArticles();
    await fetchLikedArticles();
    await _loadProfilePicture(); // Add this line


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

  Future<void> _loadProfilePicture() async {
    try {
      // First check SharedPreferences
      final userData = prefs.getString('userProfile');
      if (userData != null) {
        final storedProfile = jsonDecode(userData);
        final storedPath = storedProfile['profile_picture'] ?? '';
        if (storedPath.isNotEmpty) {
          profilePicturePath = storedPath.startsWith('http')
              ? storedPath
              : 'http://172.20.10.3:8000/storage/$storedPath';
          return;
        }
      }

      // If not in prefs, fetch from API
      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .get('/profile');

      if (response.statusCode == 200) {
        // Updated to match actual API response structure
        final userData = response.data['user_profile'] ?? {};
        final picturePath = userData['profile_picture'] ?? '';

        if (picturePath.isNotEmpty) {
          // Store the original path (relative or absolute)
          userProfile['profile_picture'] = picturePath;

          // Set the full URL for display
          profilePicturePath = picturePath.startsWith('http')
              ? picturePath
              : 'http://172.20.10.3:8000/storage/$picturePath';

          // Save to SharedPreferences
          await prefs.setString('userProfile', jsonEncode({
            ...userData,
            'profile_picture': picturePath,
            'user_id': staff['staff_id']?.toString() // Ensure user_id is set
          }));
        }
      }
    } catch (e) {
      debugPrint('Error loading profile picture: $e');
      profilePicturePath = '';
    }
  }
  Future<void> loadSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    final staffData = prefs.getString('staff');
    final userData = prefs.getString('userProfile');

    if (staffData != null) {
      staff.value = jsonDecode(staffData);
      tempUsername.value = staff['username'];
      tempEmail.value = staff['email'] ?? '';
    }
    if (userData != null) {
      userProfile.value = jsonDecode(userData);
      // Ensure user_id exists
      userProfile['user_id'] = userProfile['user_id'] ?? staff['staff_id']?.toString();
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

  Future<void> fetchCategories() async {
    try {
      isLoadingCategories(true);
      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .get('/user/categories');

      if (response.statusCode == 200) {
        categories.value = (response.data['data'] as List)
            .map((category) => {
          'category_id': category['category_id']?.toString() ?? '',
          'name': category['name'] ?? 'Unnamed Category',
        })
            .where((category) => category['category_id'].isNotEmpty)
            .toList();
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

  Future<void> getArticles({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        isLoading(true);
        currentPage.value = 1;
        articles.clear();
      } else {
        if (!hasMore.value) return;
        currentPage.value += 1;
      }

      final token = prefs.getString('token');
      if (token == null) {
        Get.snackbar('Error', 'No token found. Please log in again.');
        return;
      }

      final dio = DioClient(token: token).getInstance();
      Response response;

      if (selectedCategoryId.value == 'all') {
        response = await dio.get('/user/articles?page=${currentPage.value}');
      } else {
        response = await dio.get('/user/articles/categories/${selectedCategoryId.value}?page=${currentPage.value}');
      }

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        final articlesData = responseData['data'] as List;

        final newArticles = articlesData
            .map((json) {
          if (json['article_photo'] != null &&
              !json['article_photo'].toString().startsWith('http')) {
            json['image_url'] = 'http://172.20.10.3:8000/storage/${json['article_photo']}';
          }
          return Article.fromJson(json);
        })
            .where((article) => article.status == 1)
            .toList();

        articles.addAll(newArticles);

        // Update pagination info
        totalPages.value = responseData['last_page'] ?? 1;
        hasMore.value = currentPage.value < totalPages.value;

        await Future.wait(
          newArticles.map((article) => fetchCounts(article.articleId.toString())),
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load articles: ${e.toString()}');
      selectedCategoryId.value = 'all';
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshArticles() async {
    await getArticles();
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
    Get.find<ThemeController>().toggleDarkMode();
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
        // Handle both possible response formats
        final likeId = response.data['data']['id'] ??
            response.data['data']['like_id'] ??
            response.data['id'];

        if (likeId != null) {
          likedArticles[articleId] = likeId is int ? likeId : int.tryParse(likeId.toString()) ?? 0;
          await fetchCounts(articleId);
          Get.snackbar('Success', 'Article liked successfully');
        } else {
          await fetchLikedArticles(); // Sync with server if ID not returned
        }
      } else if (response.statusCode == 400) {
        if (response.data['message']?.toLowerCase().contains('already liked') ?? false) {
          await fetchLikedArticles();
          Get.snackbar('Info', 'Article was already liked');
        } else {
          Get.snackbar('Error', response.data['message'] ?? 'Failed to like article');
        }
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
          Get.snackbar('Info', 'Article is not liked'.tr);
          return;
        }
      }

      final response = await DioClient(token: prefs.getString('token'))
          .getInstance()
          .delete('/user/articles/likes/${likedArticles[articleId]}');

      if (response.statusCode == 200) {
        likedArticles.remove(articleId);
        Get.snackbar('Success', 'Article unliked successfully'.tr);
        await fetchCounts(articleId);
      } else if (response.statusCode == 404) {
        // Like not found - sync with server
        likedArticles.remove(articleId);
        await fetchLikedArticles();
        Get.snackbar('Info', 'Article was already unliked'.tr);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to unlike article'.tr);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      debugPrint('Error in unlikeArticle: $e'.tr);
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

      if (response.statusCode == 200) {
        likedArticles.clear();
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          for (var article in data) {
            final likeId = article['like_id'] ?? article['id'];
            if (likeId != null && article['id'] != null) {
              likedArticles[article['id'].toString()] = likeId is int ? likeId : int.parse(likeId.toString());
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching liked articles: $e'.tr);
      Get.snackbar('Error', 'Failed to load liked articles'.tr);
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
        throw Exception('Failed to fetch comments: ${response.statusCode}'.tr);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch comments: $e'.tr);
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
      if (userId == null) throw Exception('User not authenticated'.tr);

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
        throw Exception(response.data['message'] ?? 'Failed to delete comment'.tr);
      }
    } on DioException catch (e) {
      Get.back();
      String errorMessage = e.response?.data['message'] ?? 'Failed to delete comment'.tr;
      Get.snackbar('Error'.tr, errorMessage, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.back();
      Get.snackbar('Error'.tr, e.toString(), snackPosition: SnackPosition.BOTTOM);
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
              Text('Comments'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (isLoadingComments.value) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (comments.isEmpty) {
                    return Center(child: Text('No comments yet.'.tr));
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final isCurrentUserComment = comment.userId == userProfile['user_id']?.toString();

                      return ListTile(
                        title: Text(comment.content),
                        subtitle: Text('Posted by: ${comment.userName}'.tr),
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
                  hintText: 'Add a comment...'.tr,
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
                    child: Text('Close'.tr),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    child: Text('Post'),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        addComment(articleId, commentController.text);
                        commentController.clear();
                      } else {
                        Get.snackbar('Error', 'Please enter a comment'.tr);
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
        title: Text('Confirm Delete'.tr),
        content: Text('Are you sure you want to delete this comment?'.tr),
        actions: [
          TextButton(
            child: Text('Cancel'.tr),
            onPressed: () => Get.back(result: false),
          ),
          TextButton(
            child: Text('Delete'.tr, style: TextStyle(color: Colors.red)),
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
      if (userId == null) throw Exception('User ID is null'.tr);
      if (content.isEmpty) throw Exception('Comment cannot be empty'.tr);

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
        Get.snackbar('Success', 'Comment added!'.tr);
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}'.tr);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add comment: $e'.tr);
    }
  }

  Future<Feedback?> submitFeedback(String articleId, String content, int rating) async {
    try {
      isSubmittingFeedback(true);

      if (content.isEmpty) {
        Get.snackbar('Error', 'Feedback content cannot be empty'.tr);
        return null;
      }

      if (rating < 1 || rating > 5) {
        Get.snackbar('Error', 'Rating must be between 1 and 5'.tr);
        return null;
      }

      final userId = userProfile['user_id'];
      if (userId == null) {
        Get.snackbar('Error', 'User not authenticated'.tr);
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
        Get.snackbar('Success', 'Feedback submitted!'.tr);
        return feedback;
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}'.tr);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit feedback: ${e.toString()}'.tr);
      return null;
    } finally {
      isSubmittingFeedback(false);
    }
  }

  Future<void> shareArticle(String articleId, String articleTitle) async {
    try {
      final userId = userProfile['user_id'];
      if (userId == null) throw Exception('User ID is null'.tr);

      final response = await DioClient(token: prefs.getString('token')).getInstance().post(
        '/user/articles/$articleId/shares',
        data: {'user_id': userId, 'article_id': articleId},
      );

      if (response.statusCode == 201) {
        final shareableUrl = response.data['shareable_url'];
        await Share.share('Check out: $articleTitle\n$shareableUrl');
      } else {
        throw Exception('Failed to share: ${response.statusCode}'.tr);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to share article: $e'.tr);
    }
  }



  Future<Map<String, dynamic>?> updateUserProfile({XFile? imageFile}) async {
    try {
      isUpdatingProfile(true);
      final dio = DioClient(token: prefs.getString('token')!).getInstance();
      final Map<String, dynamic> requestData = {};

      // Add username and email if they've changed
      if (tempUsername.value != staff['username']) {
        requestData['username'.tr] = tempUsername.value;
      }
      if (tempEmail.value != staff['email'.tr]) {
        requestData['email'.tr] = tempEmail.value;
      }

      // Handle image file
      if (imageFile != null) {
        final sizeInMB = (await imageFile.length()) / (1024 * 1024);
        if (sizeInMB > 5) {
          throw Exception('Image must be less than 5MB'.tr);
        }

        // Convert image to base64
        final bytes = await imageFile.readAsBytes();
        final mimeType = mime(imageFile.path) ?? 'image/jpeg';
        final base64Image = base64Encode(bytes);
        requestData['profile_picture'] = 'data:$mimeType;base64,$base64Image'.tr;
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
        final data = response.data['data'.tr];
        // Update local data
        staff.value = data['staff'.tr];
        userProfile.value = data['user'.tr];

        // Handle the profile picture path - ensure it's a full URL
        final picturePath = data['user']['profile_picture'.tr];
        if (picturePath != null && picturePath.isNotEmpty) {
          profilePicturePath = picturePath.startsWith('http')
              ? picturePath
              : 'http://172.20.10.3:8000/storage/$picturePath';
        } else {
          profilePicturePath = '';
        }

        // Force refresh the profile picture
        _profilePicturePath.refresh();

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
        throw Exception('New passwords do not match'.tr);
      }

      final token = prefs.getString('token');
      if (token == null) throw Exception('No token found'.tr);

      final response = await DioClient(token: token).getInstance().put(
        '/profile/password',
        data: {
          'current_password'.tr: currentPassword,
          'password'.tr: newPassword,
          'password_confirmation'.tr: confirmPassword,
        },
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'.tr] ?? 'Failed to change password'.tr);
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
      if (token == null) throw Exception('No token found'.tr);

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
        Get.snackbar('Success', 'Your account has been deleted successfully'.tr);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete account'.tr);
      }
    } on DioException catch (e) {
      Get.back();
      final errorMessage = e.response?.data['message'] ?? 'Failed to delete account'.tr;
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