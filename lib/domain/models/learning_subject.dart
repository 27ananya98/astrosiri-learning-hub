class LearningSubject {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String? iconUrl;
  final String? imageUrl;
  final bool active;
  final int eligibilityThreshold;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LearningSubject({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.iconUrl,
    this.imageUrl,
    this.active = true,
    this.eligibilityThreshold = 100,
    this.order = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory LearningSubject.fromJson(Map<String, dynamic> json) {
    final title = json['title']?.toString() ?? json['name']?.toString() ?? '';
    return LearningSubject(
      id: json['id']?.toString() ?? '',
      slug:
          json['slug']?.toString() ??
          json['code']?.toString() ??
          title.toLowerCase().replaceAll(' ', '-'),
      title: title,
      description:
          json['description']?.toString() ?? json['summary']?.toString() ?? '',
      iconUrl:
          json['iconUrl']?.toString() ??
          json['icon_url']?.toString() ??
          json['icon']?.toString(),
      imageUrl:
          json['imageUrl']?.toString() ??
          json['image_url']?.toString() ??
          json['image']?.toString(),
      active: json['active'] as bool? ?? true,
      eligibilityThreshold:
          (json['eligibilityThreshold'] as num?)?.toInt() ?? 100,
      order: (json['order'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'active': active,
      'eligibilityThreshold': eligibilityThreshold,
      'order': order,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isBase64Icon => iconUrl != null && iconUrl!.startsWith('data:image');

  String? get resolvedImageUrl => imageUrl ?? (isBase64Icon ? null : iconUrl);
}
