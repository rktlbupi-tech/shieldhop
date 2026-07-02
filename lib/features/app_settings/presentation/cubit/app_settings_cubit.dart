import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/repositories/app_settings_repository.dart';

/// SharedPreferences key prefix for cached menu-visibility flags. The router
/// reads these (via [AppSettingsPrefs]) to make hidden routes unreachable.
const String _kMenuPrefix = 'app_settings_menu_';

/// Menu flag keys that map to a guardable route. `legalTerms` / `privacyPolicy`
/// share the `/term-check` route, so they are intentionally omitted here and
/// gated at the menu-item level only.
class AppSettingsMenuKeys {
  static const String form = 'form';
  static const String mileage = 'mileage';
  static const String claimExpenses = 'claimExpenses';
  static const String payslip = 'payslip';
  static const String viewEarnings = 'viewEarnings';
  static const String faq = 'faq';
}

/// Static helper so the router can read cached flags without the cubit.
class AppSettingsPrefs {
  /// Returns the cached menu flag, defaulting to `true` (visible) when unknown.
  static bool menuVisible(SharedPreferences prefs, String key) =>
      prefs.getBool('$_kMenuPrefix$key') ?? true;
}

abstract class AppSettingsState extends Equatable {
  const AppSettingsState();
  @override
  List<Object?> get props => [];
}

class AppSettingsInitial extends AppSettingsState {
  const AppSettingsInitial();
}

class AppSettingsLoading extends AppSettingsState {
  const AppSettingsLoading();
}

/// Always carries a usable config — the real one, or [AppSettingsEntity.allVisible]
/// when the fetch failed (fail-open).
class AppSettingsLoaded extends AppSettingsState {
  final AppSettingsEntity settings;
  const AppSettingsLoaded(this.settings);
  @override
  List<Object?> get props => [settings];
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  final AppSettingsRepository _repo;
  final SharedPreferences _prefs;

  AppSettingsCubit(this._repo, this._prefs)
      : super(const AppSettingsInitial());

  /// Current config, falling back to all-visible before the first successful load.
  AppSettingsEntity get current => state is AppSettingsLoaded
      ? (state as AppSettingsLoaded).settings
      : const AppSettingsEntity.allVisible();

  /// Fetch (login / launch). Set [silent] on resume so we don't flash a loader.
  Future<void> fetch({bool silent = false}) async {
    if (!silent) emit(const AppSettingsLoading());
    final (settings, failure) = await _repo.fetch();
    // Fail-open: any error (including 403) keeps every surface visible.
    final resolved = (failure != null || settings == null)
        ? const AppSettingsEntity.allVisible()
        : settings;
    await _cacheMenuFlags(resolved.menu);
    emit(AppSettingsLoaded(resolved));
  }

  Future<void> _cacheMenuFlags(MenuVisibility m) async {
    await _prefs.setBool('$_kMenuPrefix${AppSettingsMenuKeys.form}', m.form);
    await _prefs.setBool(
        '$_kMenuPrefix${AppSettingsMenuKeys.mileage}', m.mileage);
    await _prefs.setBool(
        '$_kMenuPrefix${AppSettingsMenuKeys.claimExpenses}', m.claimExpenses);
    await _prefs.setBool(
        '$_kMenuPrefix${AppSettingsMenuKeys.payslip}', m.payslip);
    await _prefs.setBool(
        '$_kMenuPrefix${AppSettingsMenuKeys.viewEarnings}', m.viewEarnings);
    await _prefs.setBool('$_kMenuPrefix${AppSettingsMenuKeys.faq}', m.faq);
  }
}
