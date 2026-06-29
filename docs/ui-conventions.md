# UI Conventions — Presshop Enterprise

## Design Baseline

`ScreenUtil` is initialised with design size **390 × 844** (iPhone 14 logical resolution).

Every layout value must use a ScreenUtil suffix — never bare `double`:

| Suffix | Use for |
|---|---|
| `.w` | Widths, horizontal padding/margin |
| `.h` | Heights, vertical padding/margin |
| `.sp` | Font sizes, icon sizes |
| `.r` | Border radii, circular values |

---

## Colors

All colors come from `AppColors` (`lib/core/constants/app_colors.dart`). Never hardcode hex values.

| Token | Hex | Use |
|---|---|---|
| `AppColors.primary` | `#1877F2` | Brand blue — buttons, selected tab, links |
| `AppColors.accent` | `#4FAA4B` | Secondary green (on-duty, success accents) |
| `AppColors.hopperPink` | `#EC4E54` | Alert/SOS/danger |
| `AppColors.surface` | `#FFFFFF` | Card and scaffold backgrounds |
| `AppColors.background` | `#F5F5F5` | Page background |
| `AppColors.textPrimary` | `#212121` | Body text |
| `AppColors.textSecondary` | `#757575` | Captions, subtitles |
| `AppColors.textHint` | `#BDBDBD` | Placeholder text |
| `AppColors.border` | `#E0E0E0` | Input borders, dividers |
| `AppColors.error` | `#D32F2F` | Validation errors |
| `AppColors.success` | `#388E3C` | Success states |
| `AppColors.warning` | `#F57C00` | Warning states |
| `AppColors.shimmerBase` | `#E0E0E0` | Shimmer loading base |
| `AppColors.shimmerHighlight` | `#F5F5F5` | Shimmer loading highlight |

---

## Typography

Two font families are registered:

| Family | Weights available | Used for |
|---|---|---|
| `Poppins` | 400, 500, 600, 700 | Body copy, labels, form fields |
| `AirbnbCereal` | 400, 500, 700 | Navigation labels, section headers |

Shared presets live in `AppTextStyles` (`lib/core/constants/app_text_styles.dart`). Use these instead of writing inline `TextStyle`.

---

## Shared Widgets

Located in `lib/presentation/widgets/`. Always use these before creating a new one.

| Widget | File | Purpose |
|---|---|---|
| `EmployeeAppBar` | `employee_app_bar.dart` | Top app bar with avatar, company logo, online badge |
| `AppAppBar` | `app_app_bar.dart` | Generic app bar for non-dashboard screens |
| `CompanyLogoWidget` | `company_logo_widget.dart` | Cached network image for company logo |
| `EmptyState` | `empty_state.dart` | Empty list/error illustration + message |
| `LoadingWidget` | `loading_widget.dart` | Centered `CircularProgressIndicator` |
| `SlidingTabs` | `sliding_tabs.dart` | Horizontal tab strip (Today / Week / Month) |
| `StatCard` | `stat_card.dart` | KPI card with icon, label, value |
| `ComingSoonScreen` | `coming_soon_screen.dart` | Placeholder for unimplemented features |

---

## Theme

`AppTheme.light` is defined in `lib/core/theme/app_theme.dart` and applied in `main.dart`. The app is light-mode only (no dark mode implemented).

---

## Icons & Images

Assets are declared in `pubspec.yaml`:

| Folder | Content |
|---|---|
| `assets/icons/` | PNG/SVG UI icons |
| `assets/images/` | Illustrations, brand images |
| `assets/animations/` | Lottie or other animation files |
| `assets/audio/` | Sound effects (SOS alert, etc.) |
| `assets/markers/` | Google Maps marker PNGs (full, BG-removed, GIFs, icons) |
| `assets/fonts/` | Poppins and AirbnbCereal font files |
| `assets/rabbits/` | Onboarding / mascot illustrations |

SVG icons use `flutter_svg` (`SvgPicture.asset`). PNG icons use `ImageIcon` or `Image.asset`. Cached network images use `cached_network_image`.

---

## Responsive Patterns

The `Responsive` utility in `lib/core/utils/responsive.dart` provides screen-size helpers. Use it for breakpoint-aware layouts if the design calls for tablet support (currently portrait-only mobile).

`SystemChrome.setPreferredOrientations` in `main.dart` locks to portrait up/down.
