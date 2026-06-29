enum AppFlavor { dev, staging, prod }

class AppConfig {
  AppConfig._();

  static AppFlavor _flavor = AppFlavor.dev;

  static void init(AppFlavor flavor) => _flavor = flavor;

  static AppFlavor get flavor => _flavor;

  static String get _apiHost => switch (_flavor) {
        AppFlavor.dev => 'dev-api.presshop.news',
        AppFlavor.staging => 'staging-api.presshop.news',
        AppFlavor.prod => 'api.presshop.news',
      };

  static String get _cdnHost => switch (_flavor) {
        AppFlavor.dev => 'dev-cdn.presshop.news',
        AppFlavor.staging => 'staging-cdn.presshop.news',
        AppFlavor.prod => 'cdn.presshop.news',
      };

  // ── API ─────────────────────────────────────────────────
  static String get apiBaseUrl => 'https://$_apiHost:5019/';

  // ── Socket ───────────────────────────────────────────────
  static String get socketBaseUrl => 'https://$_apiHost:3005';
  static String get chatSocketUrl => '$socketBaseUrl/chat-v2';
  static String get liveSocketUrl => '$socketBaseUrl/enterprise-live';

  // ── Images (CDN) ─────────────────────────────────────────
  static String get _cdnBase => 'https://$_cdnHost/public';

  static String contentImage(String path) => '$_cdnBase/contentData/$path';
  static String taskMedia(String path) => '$_cdnBase/uploadContent/$path';
  static String thumbnail(String path) => '$_cdnBase/thumbnail/$path';
  static String avatarImage(String path) => '$_cdnBase/avatarImages/$path';
  static String profileImage(String path) => '$_cdnBase/userImages/$path';

  static bool get isDev => _flavor == AppFlavor.dev;
}
