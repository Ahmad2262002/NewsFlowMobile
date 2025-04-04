class Comment {
  final String commentId;
  final String userId;
  final String userName;
  final String articleId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.commentId,
    required this.userId,
    required this.userName,
    required this.articleId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['user']['username']?.toString() ?? 'Unknown User',
      articleId: json['article_id'].toString(),
      content: json['content'].toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'user_id': userId,
      'article_id': articleId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': {
        'user_id': userId,
        'username': userName,
      }
    };
  }
}