import 'dart:math';

import 'package:flutter/material.dart' hide Feedback;
import 'package:get/get.dart';
import 'package:newsflow/Controllers/HomeController.dart';
import 'package:newsflow/Models/Article.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Services/weather_location_service.dart';
import 'ProfileSettingsScreen.dart';
import 'package:newsflow/Controllers/ThemeController.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());
    final ThemeController themeController = Get.find<ThemeController>();

    return GetBuilder<ThemeController>(
      builder: (themeController) {
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
                icon: Icon(
                  themeController.isDarkMode.value
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: themeController.toggleDarkMode,
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
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(16, 20, 16, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      if (controller.isLoadingCategories.value) {
                        return SizedBox(
                          height: 40,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor:
                          Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 4,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                          value: controller.selectedCategoryId.value,
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text(
                                'all categories'.tr,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            ...controller.categories.map((category) {
                              return DropdownMenuItem(
                                value: category['category_id'].toString(),
                                child: Text(
                                  category['name'] ?? 'Category'.tr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) async {
                            if (value != null) {
                              controller.selectedCategoryId.value = value;
                              await controller.getArticles();

                              if (controller.articles.isEmpty && value != 'all') {
                                await Future.delayed(Duration(milliseconds: 500));
                                controller.selectedCategoryId.value = 'all';
                                await controller.getArticles();
                                Get.snackbar(
                                  'Info'.tr,
                                  'No articles found for this category'.tr,
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: Duration(seconds: 2),
                                  backgroundColor:
                                  Theme.of(context).colorScheme.surfaceVariant,
                                  colorText:
                                  Theme.of(context).colorScheme.onSurface,
                                );
                              }
                            }
                          },
                          hint: Text(
                            'Select category'.tr,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await controller.fetchCategories();
                      await controller.getArticles();
                    },
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
          drawer: _buildDrawer(context, controller, themeController),
        );
      },
    );
  }

  Widget _buildCategoryButton(BuildContext context, String name,
      String categoryId, HomeController controller) {
    return Obx(() => ChoiceChip(
      label: Text(
        name,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: controller.selectedCategoryId.value == categoryId
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: controller.selectedCategoryId.value == categoryId,
      onSelected: (selected) {
        controller.selectedCategoryId.value = categoryId;
        controller.getArticles();
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor:
      Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      labelPadding: EdgeInsets.symmetric(horizontal: 4),
    ));
  }

  Widget _buildArticleCard(
      BuildContext context, Article article, HomeController controller) {
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
                if (article.imageUrl != null)
                  ClipRRect(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      article.imageUrl!,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Center(
                            child: Icon(Icons.broken_image,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
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
                      SizedBox(height: 16),
                      Obx(() => Row(
                        children: [
                          Obx(() => TextButton.icon(
                            icon: Icon(
                              controller.isArticleLiked(
                                  article.articleId.toString())
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              size: 20,
                              color: controller.isArticleLiked(
                                  article.articleId.toString())
                                  ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  : Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                            label: Text(
                              controller
                                  .getLikeCount(
                                  article.articleId.toString())
                                  .toString(),
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface),
                            ),
                            onPressed: () async {
                              if (controller.isArticleLiked(
                                  article.articleId.toString())) {
                                await controller.unlikeArticle(
                                    article.articleId.toString());
                              } else {
                                await controller.likeArticle(
                                    article.articleId.toString());
                              }
                            },
                          )),
                          SizedBox(width: 8),
                          _buildInteractionButton(
                            context,
                            icon: Icons.comment_outlined,
                            label: controller
                                .getCommentCount(
                                article.articleId.toString())
                                .toString(),
                            onPressed: () => controller.showCommentDialog(
                                article.articleId.toString()),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () async =>
                            await controller.shareArticle(
                              article.articleId.toString(),
                              article.title,
                            ),
                            icon: Icon(Icons.share,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface),
                          ),
                          IconButton(
                            icon: Icon(Icons.feedback_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary),
                            onPressed: () => _showFeedbackDialog(
                                context, article, controller),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(
      BuildContext context, Article article, HomeController controller) {
    final feedbackController = TextEditingController();
    double rating = 3.0;

    Get.dialog(
      Theme(
        data: Theme.of(context),
        child: AlertDialog(
          title: Text('share feedback'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How would you rate this article'.tr,
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
                    hintText: 'share your thoughts'.tr,
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
            Obx(
                  () => controller.isSubmittingFeedback.value
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
                    Get.snackbar(
                        'success'.tr, 'thanks for your feedback'.tr);
                  }
                },
              ),
            ),
          ],
        ),
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
      icon: Icon(icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface),
      label: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface)),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, HomeController controller,
      ThemeController themeController) {
    final WeatherLocationService weatherService =
    Get.find<WeatherLocationService>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() => UserAccountsDrawerHeader(
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
              controller.staff['username'] ?? 'Username'.tr,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            accountEmail: Text(
              controller.staff['email'] ?? 'user@email.com'.tr,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withOpacity(0.8),
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              backgroundImage:
              (controller.profilePicturePath ?? '').isNotEmpty
                  ? NetworkImage(
                controller.profilePicturePath!,
                headers: {
                  'Authorization':
                  'Bearer ${controller.prefs.getString('token')}'
                },
              )
                  : null,
              child: controller.profilePicturePath == null
                  ? Text(
                controller.staff['username']
                    ?.substring(0, 1)
                    .toUpperCase() ??
                    'U'.tr,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              )
                  : null,
            ),
          )),

          Obx(() => Card(
            margin: EdgeInsets.all(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  if (weatherService.isLoading.value)
                    CircularProgressIndicator(),
                  if (!weatherService.isLoading.value)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weatherService.weatherIcon.value,
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(width: 8),
                        Text(
                          weatherService.temperature.value,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 16),
                      SizedBox(width: 4),
                      Text(
                        weatherService.location.value,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),

          ListTile(
            leading: Icon(Icons.settings,
                color: Theme.of(context).colorScheme.onSurface),
            title:
            Text("settings".tr, style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () {
              Get.to(() => ProfileSettingsScreen());
            },
          ),
          ListTile(
            leading: Icon(
              themeController.isDarkMode.value
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text("dark_mode".tr, style: GoogleFonts.poppins(fontSize: 16)),
            trailing: Obx(() => Switch(
              value: themeController.isDarkMode.value,
              onChanged: (value) => themeController.toggleDarkMode(),
              activeColor: Theme.of(context).colorScheme.primary,
            )),
          ),
          ListTile(
            leading: Icon(Icons.language,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text("Language".tr, style: GoogleFonts.poppins(fontSize: 16)),
            onTap: () {
              Get.bottomSheet(
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text("English",
                            style: GoogleFonts.poppins(fontSize: 16)),
                        onTap: () {
                          Get.updateLocale(Locale('en', 'US'));
                          Get.back();
                        },
                      ),
                      ListTile(
                        title: Text("العربية",
                            style: GoogleFonts.poppins(fontSize: 16)),
                        onTap: () {
                          Get.updateLocale(Locale('ar', 'AR'));
                          Get.back();
                        },
                      ),
                      ListTile(
                        title: Text("Français",
                            style: GoogleFonts.poppins(fontSize: 16)),
                        onTap: () {
                          Get.updateLocale(Locale('fr', 'FR'));
                          Get.back();
                        },
                      ),
                      ListTile(
                        title: Text("Español",
                            style: GoogleFonts.poppins(fontSize: 16)),
                        onTap: () {
                          Get.updateLocale(Locale('es', 'ES'));
                          Get.back();
                        },
                      ),
                      ListTile(
                        title: Text("Italiano",
                            style: GoogleFonts.poppins(fontSize: 16)),
                        onTap: () {
                          Get.updateLocale(Locale('it', 'IT'));
                          Get.back();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.color_lens,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text("Theme".tr, style: GoogleFonts.poppins(fontSize: 16)),
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: themeController.themeNames.length,
                  itemBuilder: (context, index) {
                    final themeKey = themeController.themeNames[index];
                    return RadioListTile<String>(
                      value: themeKey,
                      groupValue: themeController.selectedTheme.value,
                      onChanged: (value) => themeController.changeTheme(value!),
                      title: Text(themeKey.capitalizeFirst!),
                    );
                  },
                ),
              ),
            ],
          ),
          Spacer(),
          Divider(),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text(
              "Delete Account".tr,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            onTap: controller.showDeleteAccountConfirmation,
          ),
          ListTile(
            leading:
            Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
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
          article.title.tr,
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
              article.content.tr,
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