class Favorite {
  final int? id;
  final String name;
  final String mobile;
  final String? photo;
  final bool isStarred;

  Favorite({
    this.id,
    required this.name,
    required this.mobile,
    this.photo,
    this.isStarred = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'mobile': mobile,
      'photo': photo ?? '',
      'is_starred': isStarred ? 1 : 0,
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      name: map['name'] as String,
      mobile: map['mobile'] as String,
      photo: map['photo'] as String?,
      isStarred: (map['is_starred'] as int? ?? 0) == 1,
    );
  }
}
