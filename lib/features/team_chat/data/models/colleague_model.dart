import '../../domain/entities/colleague_entity.dart';

class ColleagueModel extends ColleagueEntity {
  const ColleagueModel({
    required super.id,
    required super.name,
    super.avatarUrl,
    super.designation,
    super.department,
  });

  factory ColleagueModel.fromJson(Map<String, dynamic> j) {
    return ColleagueModel(
      id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      avatarUrl: j['avatar_url']?.toString() ?? j['avatarUrl']?.toString() ?? '',
      designation: j['designation']?.toString() ?? '',
      department: j['department']?.toString() ?? '',
    );
  }

  ColleagueEntity toEntity() => ColleagueEntity(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
        designation: designation,
        department: department,
      );
}

/// Parses the double-nested `data.data` payload of `GET chat-v2/app/colleagues`.
class ColleaguesPageModel extends ColleaguesPage {
  const ColleaguesPageModel({
    required super.items,
    super.page,
    super.totalPages,
    super.totalCount,
  });

  /// [data] is the inner object: `{ data: [...], totalCount, page, limit, totalPages }`.
  factory ColleaguesPageModel.fromJson(Map<String, dynamic> data) {
    final rawList = data['data'] as List<dynamic>? ?? const [];
    final items = rawList
        .whereType<Map>()
        .map((e) => ColleagueModel.fromJson(Map<String, dynamic>.from(e)).toEntity())
        .toList();
    return ColleaguesPageModel(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? 1,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }
}
