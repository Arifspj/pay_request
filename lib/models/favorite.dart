class Favorite {
  final int? id;
  final String name;
  final String mobile;
  final String? photo;

  Favorite({
    this.id,
    required this.name,
    required this.mobile,
    this.photo,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'mobile': mobile,
      'photo': photo ?? '',
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      name: map['name'] as String,
      mobile: map['mobile'] as String,
      photo: map['photo'] as String?,
    );
  }
}
