import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:presshop_enterprise/config/routes/app_router.dart';
import 'package:presshop_enterprise/config/di/injection.dart';
import 'package:presshop_enterprise/core/network/api_client.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';

import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import 'package:presshop_enterprise/common/widgets/loading_widget.dart';

// Real conversations endpoint chat modes (mirrors the legacy app).
const String _kTeamChatModes =
    'enterprise-task-group,enterprise-task-direct,hopper-direct,hopper-group,enterprise-org-team';

class TeamChatController extends ChangeNotifier {
  TeamChatController({ApiClient? apiClient})
    : _apiClient = apiClient ?? getIt<ApiClient>();

  final ApiClient _apiClient;

  List<TeamChatItem> conversations = [];
  bool hasMore = true;
  bool isLoading = false;
  String? nextCursor;

  Future<void> fetchConversations({bool refresh = false}) async {
    if (refresh) {
      nextCursor = null;
      hasMore = true;
    }

    if (!hasMore || (isLoading && !refresh)) return;

    if (conversations.isEmpty) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final queryParameters = <String, dynamic>{
        'chatMode': _kTeamChatModes,
        'limit': 20,
      };
      if (nextCursor != null) {
        queryParameters['cursor'] = nextCursor;
      }

      final response = await _apiClient.get(
        'chat-v2/conversations',
        queryParameters: queryParameters,
      );

      final data = response.data;
      if (data is Map &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        final parsed = TeamChatData.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
        if (refresh) {
          conversations = parsed.items;
        } else {
          conversations.addAll(parsed.items);
        }
        nextCursor = parsed.nextCursor;
        if (nextCursor == null) {
          hasMore = false;
        }
      }
    } catch (e) {
      debugPrint('Error fetching team conversations: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class RefreshController {
  RefreshController({bool initialRefresh = false});
  void refreshCompleted() {}
  void loadComplete() {}
}

class SmartRefresher extends StatelessWidget {
  final dynamic controller;
  final bool enablePullDown;
  final bool enablePullUp;
  final VoidCallback onRefresh;
  final VoidCallback onLoading;
  final Widget footer;
  final Widget child;

  const SmartRefresher({
    Key? key,
    this.controller,
    this.enablePullDown = false,
    this.enablePullUp = false,
    required this.onRefresh,
    required this.onLoading,
    required this.footer,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => child;
}

class CustomFooter extends StatelessWidget {
  final dynamic builder;
  const CustomFooter({Key? key, this.builder}) : super(key: key);
  @override
  Widget build(BuildContext context) => const SizedBox();
}

Widget commonRefresherFooter(BuildContext context, dynamic mode) =>
    const SizedBox();

class TeamChatData {
  final List<TeamChatItem> items;
  final String? nextCursor;

  TeamChatData({required this.items, this.nextCursor});

  factory TeamChatData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((x) => TeamChatItem.fromJson(Map<String, dynamic>.from(x)))
              .toList()
        : <TeamChatItem>[];
    return TeamChatData(
      items: items,
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class TeamChatItem {
  final Display display;
  final Conversation conversation;
  final Membership membership;

  TeamChatItem({
    required this.display,
    required this.conversation,
    required this.membership,
  });

  factory TeamChatItem.fromJson(Map<String, dynamic> json) => TeamChatItem(
    display: Display.fromJson(
      json['display'] is Map
          ? Map<String, dynamic>.from(json['display'] as Map)
          : const {},
    ),
    conversation: Conversation.fromJson(
      json['conversation'] is Map
          ? Map<String, dynamic>.from(json['conversation'] as Map)
          : const {},
    ),
    membership: Membership.fromJson(
      json['membership'] is Map
          ? Map<String, dynamic>.from(json['membership'] as Map)
          : const {},
    ),
  );
}

class Display {
  String title;
  String subtitle;
  String avatarImage;

  Display({this.title = "", this.subtitle = "", this.avatarImage = ""});

  factory Display.fromJson(Map<String, dynamic> json) => Display(
    title: json['title'] as String? ?? "",
    subtitle: json['subtitle'] as String? ?? "",
    avatarImage: json['avatarImage'] as String? ?? "",
  );
}

class Conversation {
  String id;
  String? lastMessagePreview;
  String? lastMessageAt;
  Settings settings;

  Conversation({
    this.id = "",
    this.lastMessagePreview,
    this.lastMessageAt,
    Settings? settings,
  }) : settings = settings ?? Settings();

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: (json['_id'] ?? json['id'] ?? "").toString(),
    lastMessagePreview: json['lastMessagePreview'] as String?,
    lastMessageAt: json['lastMessageAt'] as String?,
    settings: Settings.fromJson(
      json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : const {},
    ),
  );
}

class Settings {
  Map<String, dynamic>? metadata;

  Settings({this.metadata});

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
    metadata: json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : null,
  );
}

class Membership {
  int unreadCount;

  Membership({this.unreadCount = 0});

  factory Membership.fromJson(Map<String, dynamic> json) =>
      Membership(unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0);
}

final _sharedPreferences = _MockPrefs();

class _MockPrefs {
  String? getString(String key) => "";
}

const String employeeMediaHouseLogoKey = "employeeMediaHouseLogoKey";
const String employeeMediaHouseNameKey = "employeeMediaHouseNameKey";
const double appBarHeadingFontSize = 0.04;
const Color colorOnlineGreen = Colors.green;

class PresshopColors {
  static const Color presshop_grey_dark = Colors.grey;
}

Widget showAnimatedLoader(Size size) => LoadingWidget(size: size.width * 0.25);

// Mock userRoleProvider since Riverpod is removed
enum UserRole { employee, enterprise }

class UserRoleProvider {
  UserRole role = UserRole.employee;
}

final userRoleProvider = UserRoleProvider();

class Ref {
  UserRoleProvider watch(dynamic provider) => provider;
}

final ref = Ref();

class TeamChatListPage extends StatefulWidget {
  const TeamChatListPage({super.key});

  @override
  State<TeamChatListPage> createState() => _TeamChatListPageState();
}

class _TeamChatListPageState extends State<TeamChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  final TeamChatController _controller = TeamChatController();
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void initState() {
    super.initState();
    _controller.fetchConversations();
  }

  void _onRefresh() async {
    await _controller.fetchConversations(refresh: true);
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await _controller.fetchConversations();
    _refreshController.loadComplete();
  }

  String _getTimeAgo(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "";
    try {
      DateTime? parsed = DateTime.tryParse(timeStr);
      if (parsed == null) return "";

      final difference = DateTime.now().difference(parsed.toLocal());
      if (difference.inDays > 7) {
        return DateFormat("dd MMM").format(parsed);
      } else if (difference.inDays > 0) {
        return "${difference.inDays}d ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes} min ago";
      } else {
        return "Just now";
      }
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final double responsiveWidth = size.width > 600 ? 650 : size.width;
    final role = ref.watch(userRoleProvider).role;
    final primaryColor = role == UserRole.employee
        ? colorEmployeeGreen1
        : colorThemePink;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        title: "Team chat",
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        showBack: true,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            children: [
              // Search Bar
              Container(
                padding: EdgeInsets.all(responsiveWidth * 0.03),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search teammates...",
                    prefixIcon: Icon(LucideIcons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  enablePullUp: _controller.hasMore,
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  footer: const CustomFooter(builder: commonRefresherFooter),
                  child: () {
                    final orgTeamChats = _controller.conversations.where((
                      item,
                    ) {
                      final chatMode =
                          item.conversation.settings.metadata?["chatMode"];
                      return chatMode == "enterprise-org-team";
                    }).toList();

                    final otherChats = _controller.conversations.where((item) {
                      final chatMode =
                          item.conversation.settings.metadata?["chatMode"];
                      return chatMode != "enterprise-org-team";
                    }).toList();

                    return ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsiveWidth * 0.045,
                      ),
                      children: [
                        Text(
                          "DEFAULT TEAM CHAT",
                          style: TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontSize: responsiveWidth * 0.028,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...orgTeamChats.map(
                          (item) => _buildBroadcastCard(
                            item,
                            responsiveWidth,
                            primaryColor,
                          ),
                        ),
                        if (orgTeamChats.isEmpty)
                          _buildBroadcastCard(
                            null,
                            responsiveWidth,
                            primaryColor,
                          ),
                        const SizedBox(height: 12),
                        Text(
                          "CHAT",
                          style: TextStyle(
                            fontFamily: 'AirbnbCereal',
                            fontSize: responsiveWidth * 0.028,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_controller.isLoading &&
                            _controller.conversations.isEmpty)
                          showAnimatedLoader(size)
                        else if (otherChats.isEmpty)
                          const Center(child: Text("No conversations found"))
                        else
                          ...otherChats.map(
                            (item) => _buildChatTile(
                              item,
                              responsiveWidth,
                              primaryColor,
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBroadcastCard(
    TeamChatItem? item,
    double responsiveWidth,
    Color primaryColor,
  ) {
    String title;
    String subtitle;
    String avatarUrl;
    String taskId;
    int unreadCount = 0;
    String? lastMessageAt;

    if (item != null) {
      title =
          item.conversation.settings.metadata?["chatListTitle"] ??
          item.display.title;
      if (!title.toLowerCase().contains("team chat")) {
        title = "$title Team chat";
      }

      // If there's a last message preview, use it, otherwise use the fallback text
      if (item.conversation.lastMessagePreview != null &&
          item.conversation.lastMessagePreview!.isNotEmpty) {
        subtitle = item.conversation.lastMessagePreview!;
      } else {
        subtitle = "Important: Please upload your field evidence.";
      }

      avatarUrl = item.display.avatarImage;
      taskId = item.conversation.id;
      unreadCount = item.membership.unreadCount;
      lastMessageAt = item.conversation.lastMessageAt;
    } else {
      String mediaHouse =
          _sharedPreferences.getString(employeeMediaHouseNameKey) ??
          "Times of India";
      title = "$mediaHouse Team chat";
      subtitle = "Important: Please upload your field evidence.";
      avatarUrl = _sharedPreferences.getString(employeeMediaHouseLogoKey) ?? "";
      taskId = "";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 0,
            ),
            onTap: () {
              context
                  .push(
                    AppRoutes.teamChatMessage,
                    extra: {
                      'conversationId': taskId,
                      'title': title,
                      'image': avatarUrl,
                    },
                  )
                  .then((_) {
                    _controller.fetchConversations(refresh: true);
                  });
            },
            leading: Container(
              height: responsiveWidth * 0.115,
              width: responsiveWidth * 0.115,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              "assets/logo/cmplogo2.png",
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        "assets/logo/cmplogo2.png",
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontWeight: FontWeight.w500,
                fontSize: responsiveWidth * 0.036,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontWeight: FontWeight.w400,
                fontSize: responsiveWidth * 0.029,
                color: Colors.grey.shade500,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessageAt != null)
                  Text(
                    _getTimeAgo(lastMessageAt),
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontWeight: FontWeight.w400,
                      fontSize: responsiveWidth * 0.028,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unreadCount > 0)
                      Container(
                        constraints: BoxConstraints(
                          minWidth: responsiveWidth * 0.055,
                          minHeight: responsiveWidth * 0.055,
                        ),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: responsiveWidth * 0.025,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(width: responsiveWidth * 0.015),
                    Icon(
                      LucideIcons.chevron_right,
                      color: Colors.grey.shade300,
                      size: responsiveWidth * 0.042,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildChatTile(
    TeamChatItem item,
    double responsiveWidth,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 0,
            ),
            onTap: () {
              context
                  .push(
                    AppRoutes.teamChatMessage,
                    extra: {
                      'conversationId': item.conversation.id,
                      'title': item.display.title,
                      'image': item.display.avatarImage,
                    },
                  )
                  .then((_) {
                    _controller.fetchConversations(refresh: true);
                  });
            },
            leading: Container(
              height: responsiveWidth * 0.115,
              width: responsiveWidth * 0.115,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: ClipOval(
                child: item.display.avatarImage.isNotEmpty
                    ? Image.network(
                        item.display.avatarImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              "assets/logo/cmplogo2.png",
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        "assets/logo/cmplogo2.png",
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            title: Text(
              item.display.title,
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontWeight: FontWeight.w500,
                fontSize: responsiveWidth * 0.036,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              item.display.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontWeight: FontWeight.w400,
                fontSize: responsiveWidth * 0.029,
                color: PresshopColors.presshop_grey_dark,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.conversation.lastMessageAt != null)
                  Text(
                    _getTimeAgo(item.conversation.lastMessageAt),
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontWeight: FontWeight.w400,
                      fontSize: responsiveWidth * 0.028,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.membership.unreadCount > 0)
                      Container(
                        constraints: BoxConstraints(
                          minWidth: responsiveWidth * 0.055,
                          minHeight: responsiveWidth * 0.055,
                        ),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            item.membership.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: responsiveWidth * 0.025,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(width: responsiveWidth * 0.015),
                    Icon(
                      LucideIcons.chevron_right,
                      color: Colors.grey.shade300,
                      size: responsiveWidth * 0.042,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }
}
