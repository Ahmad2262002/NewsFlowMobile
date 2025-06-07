import 'Employee.dart';

class Article {
  final String articleId;
  final String title;
  final String content;
  final String sourceName;
  final DateTime publishedDate;
  final String authorName;
  final int status;
  final int employeeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Employee employee;
  final String? url; // Make this nullable
  final String? imageUrl; // Add this for the image URL
  final String? articlePhoto; // Add this for the original photo path

  Article({
    required this.articleId,
    required this.title,
    required this.content,
    required this.sourceName,
    required this.publishedDate,
    required this.authorName,
    required this.status,
    required this.employeeId,
    required this.createdAt,
    required this.updatedAt,
    required this.employee,
    this.url, // Make this nullable
    this.imageUrl, // Initialize in constructor
    this.articlePhoto, // Initialize in constructor
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    print("Parsing article: $json");
    return Article(
      articleId: json['article_id'].toString(),
      title: json['title'] ?? 'No Title',
      content: json['content'] ?? 'No Content',
      url: json['url'], // This can be null
      sourceName: json['source_name'] ?? 'Unknown Source',
      publishedDate: DateTime.parse(json['published_date'] ?? DateTime.now().toString()),
      authorName: json['author_name'] ?? 'Unknown Author',
      status: json['status'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
      employee: Employee.fromJson(json['employee'] ?? {}),
      imageUrl: json['image_url'], // Map the image URL from JSON
      articlePhoto: json['article_photo'], // Map the original photo path
    );
  }
}