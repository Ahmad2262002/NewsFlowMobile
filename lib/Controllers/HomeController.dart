import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide Feedback;
import 'package:get/get.dart';
import 'package:newsflow/Core/Network/DioClient.dart';
import 'package:newsflow/Models/Article.dart';
import 'package:newsflow/Models/Comment.dart';
import 'package:newsflow/Models/Feedback.dart';
import 'package:newsflow/Routes/AppRoute.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

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

  // Track counts for each article
  var articleCounts = <String, Map<String, int>>{}.obs;

  @override
  void onInit() async {
    super.onInit();
    await _loadSharedPreferences();
    _loadArguments();
    await getArticles();

    _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
      await getArticles();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _loadSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  void _loadArguments() {
    final arguments = Get.arguments;
    if (arguments != null) {
      staff.value = arguments['staff'] ?? {};
      userProfile.value = arguments['userProfile'] ?? {};
    }
  }

  Future<void> getArticles() async {
    try {
      isLoading(true);
      articles.clear();
      final token = prefs.getString('token');
      if (token == null) {
        Get.snackbar('Error', 'No token found. Please log in again.');
        return;
      }

      final response = await DioClient(token: token).getInstance().get('/user/articles');
      if (response.statusCode == 200) {
        final articlesData = response.data['data'] as List;
        articles.value = articlesData
            .map((json) => Article.fromJson(json))
            .where((article) => article.status == 1)
            .toList();

        // Fetch counts for all articles
        await Future.wait(
          articles.map((article) => fetchCounts(article.articleId.toString())),
        );
      } else {
        throw Exception('Failed to load articles: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load articles: $e');
    } finally {
      isLoading(false);
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
      print('Error fetching counts for article $articleId: $e');
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
        prefs.remove('token');
        prefs.remove('userProfile');
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

  Future<void> likeArticle(String articleId) async {
    try {
      final userId = userProfile['user_id'];
      if (userId == null) throw Exception('User ID is null');

      final response = await DioClient(token: prefs.getString('token')).getInstance().post(
        '/user/articles/likes',
        data: {'user_id': userId, 'article_id': articleId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Article liked!');
        await fetchCounts(articleId);
      } else if (response.statusCode == 400) {
        Get.snackbar('Info', response.data['message']);
      } else {
        throw Exception('Failed to like article: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to like article: $e');
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
        options: Options(
          headers: {
            'Authorization': 'Bearer ${prefs.getString('token')}',
            'Content-Type': 'application/json',
          },
        ),
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
}