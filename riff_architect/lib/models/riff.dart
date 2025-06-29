class Riff {
  int? id;
  String name;
  String category;
  String filePath;

  Riff({
    this.id,
    required this.name,
    required this.category,
    required this.filePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'file_path': filePath,
    };
  }

  static Riff fromMap(Map<String, dynamic> map) {
    return Riff(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      filePath: map['file_path'],
    );
  }

  Riff copyWith({
    int? id,
    String? name,
    String? category,
    String? filePath,
  }) {
    return Riff(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
    );
  }
}
