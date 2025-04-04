class Share {
  final int shareId;
  final int userId;
  final int articleId;
  final String shareableUrl;

  Share({
    required this.shareId,
    required this.userId,
    required this.articleId,
    required this.shareableUrl,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      shareId: json['share_id'],
      userId: json['user_id'],
      articleId: json['article_id'],
      shareableUrl: json['shareable_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'share_id': shareId,
      'user_id': userId,
      'article_id': articleId,
      'shareable_url': shareableUrl,
    };
  }
}