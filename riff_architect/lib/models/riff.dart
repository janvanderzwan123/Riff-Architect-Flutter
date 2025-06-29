class Riff {
  final int? id;
  final String name;
  final String category;
  final String filePath;

  Riff({this.id, required this.name, required this.category, required this.filePath});

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
}
