import 'package:flutter/material.dart' hide Feedback;
import 'package:get/get.dart';
import 'package:newsflow/Controllers/HomeController.dart';
import 'package:newsflow/Models/Article.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Center(
          child: Text(
            "NewsFlow".tr,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: controller.toggleTheme,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (controller.articles.isEmpty) {
          return Center(
            child: Text(
              'no_articles'.tr,
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${'welcome'.tr}, ${controller.staff['username'] ?? 'User'}!",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    controller.staff['email'] ?? 'user@email.com',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryButton(context, 'categories.all'.tr),
                    _buildCategoryButton(context, 'categories.politics'.tr),
                    _buildCategoryButton(context, 'categories.technology'.tr),
                    _buildCategoryButton(context, 'categories.sports'.tr),
                    _buildCategoryButton(context, 'categories.entertainment'.tr),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => controller.getArticles(),
                child: ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: controller.articles.length,
                  separatorBuilder: (context, index) => SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final Article article = controller.articles[index];
                    return _buildArticleCard(context, article, controller);
                  },
                ),
              ),
            ),
          ],
        );
      }),
      drawer: _buildDrawer(context, controller),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.snackbar('Coming Soon', 'add_article'.tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context, String category) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          category,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Article article, HomeController controller) {
    return Hero(
      tag: 'article-${article.articleId}',
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.to(() => ArticleDetails(article: article)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  article.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 16),
                Obx(() => Row(
                  children: [
                    _buildInteractionButton(
                      context,
                      icon: Icons.thumb_up_outlined,
                      label: controller.getLikeCount(article.articleId.toString()).toString(),
                      onPressed: () => controller.likeArticle(article.articleId.toString()),
                    ),
                    _buildInteractionButton(
                      context,
                      icon: Icons.comment_outlined,
                      label: controller.getCommentCount(article.articleId.toString()).toString(),
                      onPressed: () => controller.showCommentDialog(article.articleId.toString()),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () async => await controller.shareArticle(
                        article.articleId.toString(),
                        article.title,
                      ),
                      icon: Icon(Icons.share),
                    ),
                    IconButton(
                      icon: Icon(Icons.feedback_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      onPressed: () => _showFeedbackDialog(context, article, controller),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, Article article, HomeController controller) {
    final feedbackController = TextEditingController();
    double rating = 3.0;

    Get.dialog(
      AlertDialog(
        title: Text('share_feedback'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'how_would_you_rate_this_article'.tr,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = (index + 1).toDouble();
                          });
                        },
                      );
                    }),
                  );
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                decoration: InputDecoration(
                  hintText: 'share_your_thoughts'.tr,
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                minLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('cancel'.tr),
            onPressed: () => Get.back(),
          ),
          Obx(() => controller.isSubmittingFeedback.value
              ? CircularProgressIndicator()
              : ElevatedButton(
            child: Text('submit'.tr),
            onPressed: () async {
              if (feedbackController.text.isEmpty) {
                Get.snackbar('error'.tr, 'feedback_cannot_be_empty'.tr);
                return;
              }

              final result = await controller.submitFeedback(
                article.articleId.toString(),
                feedbackController.text,
                rating.toInt(),
              );

              if (result != null) {
                Get.back();
                Get.snackbar('success'.tr, 'thanks_for_your_feedback'.tr);
              }
            },
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Function() onPressed,
      }) {
    return TextButton.icon(
      icon: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface),
      label: Text(label, style: GoogleFonts.poppins(fontSize: 14)),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, HomeController controller) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              controller.staff['username'] ?? 'Username',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            accountEmail: Text(
              controller.staff['email'] ?? 'user@email.com',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                controller.staff['username']?.substring(0, 1) ?? 'U',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
            title: Text("settings".tr, style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(
              Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text("dark_mode".tr, style: GoogleFonts.poppins(fontSize: 16)),
            trailing: Switch(
              value: Get.isDarkMode,
              onChanged: (value) => controller.toggleTheme(),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.onSurface),
            title: Text("preferences".tr, style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.language, color: Theme.of(context).colorScheme.onSurface),
            title: Text("Language", style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () {
              Get.bottomSheet(
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text("English", style: GoogleFonts.poppins(fontSize: 16)),
                        onTap: () {
                          Get.updateLocale(Locale('en', 'US'));
                          Get.back();
                        },
                      ),
                      ListTile(
                        title: Text("العربية", style: GoogleFonts.poppins(fontSize: 16)),
                        onTap: () {
                          Get.updateLocale(Locale('ar', 'AR'));
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Spacer(),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              "logout".tr,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: controller.logout,
          ),
        ],
      ),
    );
  }
}

class ArticleDetails extends StatelessWidget {
  final Article article;

  const ArticleDetails({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          article.title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.content,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}