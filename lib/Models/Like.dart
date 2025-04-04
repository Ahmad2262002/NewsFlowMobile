class Like {
  final String likeId;
  final String userId;
  final String articleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Like({
    required this.likeId,
    required this.userId,
    required this.articleId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      likeId: json['like_id'],
      userId: json['user_id'],
      articleId: json['article_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'like_id': likeId,
      'user_id': userId,
      'article_id': articleId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}