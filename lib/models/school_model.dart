import 'package:hive/hive.dart';

part 'school_model.g.dart';

@HiveType(typeId: 2)
class School extends HiveObject {
  @HiveField(0)
  final int? id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final DateTime createdAt;
  
  @HiveField(3)
  final bool isActive;

  School({
    this.id,
    required this.name,
    required this.createdAt,
    this.isActive = true,
  });

  School copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      isActive: map['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  static School fromJson(Map<String, dynamic> json) {
    return School.fromMap(json);
  }

  @override
  String toString() {
    return 'School(id: $id, name: $name, createdAt: $createdAt, isActive: $isActive)';
  }
}
