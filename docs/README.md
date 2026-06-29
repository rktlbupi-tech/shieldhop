# Presshop Enterprise — Documentation Index

This folder documents the `presshop_enterprise` Flutter app. Start with `../CLAUDE.md` for build commands and a quick orientation, then dive into the topic docs below.

| Document | Contents |
|---|---|
| [architecture.md](architecture.md) | Folder structure, Clean Architecture layers, DI graph, error handling, WebSocket setup |
| [features.md](features.md) | Every feature folder — what it does, key files, noteworthy behaviour |
| [routes.md](routes.md) | GoRouter routes, redirect guard logic, all navigation flows, how to add new routes |
| [api.md](api.md) | All REST endpoints, HTTP client usage, WebSocket events, CDN URL helpers |
| [state-management.md](state-management.md) | BLoC vs Cubit decision rules, standard state pattern, registered BLoCs, consumption patterns |
| [ui-conventions.md](ui-conventions.md) | ScreenUtil sizing rules, color tokens, typography, shared widgets, asset folders |

## Project at a Glance

- **Stack**: Flutter 3.x · Dart 3.x
- **Architecture**: Clean Architecture (data / domain / presentation per feature)
- **State**: `flutter_bloc` (Bloc + Cubit) · `equatable`
- **DI**: `get_it`
- **Navigation**: `go_router`
- **HTTP**: `dio` (via `ApiClient`)
- **Sockets**: `socket_io_client` (via `SocketManager` + `MapSocketClient`)
- **Local storage**: `shared_preferences` (session) · `hive_flutter` (available, not yet widely used)
- **Design size**: 390 × 844 · Font families: Poppins, AirbnbCereal
- **Flavors**: dev · staging · prod (switch in `AppConfig.init()` in `main.dart`)
