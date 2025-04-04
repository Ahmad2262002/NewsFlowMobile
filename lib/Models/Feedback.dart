class Feedback {
  final String feedbackId;
  final String userId;
  final String articleId;
  final String content;
  final int rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feedback({
    required this.feedbackId,
    required this.userId,
    required this.articleId,
    required this.content,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      feedbackId: json['feedback_id'].toString(),
      userId: json['user_id'].toString(),
      articleId: json['article_id'].toString(),
      content: json['content'].toString(),
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating'].toString()) ?? 0,
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedback_id': feedbackId,
      'user_id': userId,
      'article_id': articleId,
      'content': content,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}