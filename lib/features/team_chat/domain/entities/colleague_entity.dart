import 'package:equatable/equatable.dart';

class ColleagueEntity extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final String designation;
  final String department;

  const ColleagueEntity({
    required this.id,
    required this.name,
    this.avatarUrl = '',
    this.designation = '',
    this.department = '',
  });

  String get subtitle {
    if (designation.isNotEmpty && department.isNotEmpty) {
      return '$designation · $department';
    }
    return designation.isNotEmpty ? designation : department;
  }

  @override
  List<Object?> get props => [id, name, avatarUrl, designation, department];
}

class ColleaguesPage extends Equatable {
  final List<ColleagueEntity> items;
  final int page;
  final int totalPages;
  final int totalCount;

  const ColleaguesPage({
    required this.items,
    this.page = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, totalPages, totalCount];
}
