---
name: implement-api-doc
description: Implement a backend API doc into the presshop_enterprise Flutter app following its clean architecture. Use when given an API spec / endpoint doc (markdown, pasted text, or a file) and asked to "wire it up", "implement these APIs", "connect this screen to the API", or replace mock/dummy data with a real endpoint. Saves the doc, plans the gap, then wires endpoint → model → entity → datasource → repository → bloc → screen.
---

# Implement an API doc into the app

This project (`presshop_enterprise/`) is a Flutter app on **clean architecture** with
`flutter_bloc` + `get_it` + Dio. When the user hands you an API doc and asks to implement
it, follow this workflow. Do **not** skip the planning step — confirm scope before writing code.

## Step 1 — Save the doc

1. Write the doc verbatim to `docs/api/<kebab-name>.md` (create `docs/api/` if missing).
   Add a one-line note at the bottom if any path needs clarifying (e.g. the full path
   including the `enterprise/` base).
2. Add a memory entry (`metadata.type: reference`) pointing at the repo doc + the key
   endpoints, and a one-line pointer in `MEMORY.md`.

## Step 2 — Read the target feature and find the gap

Identify the feature folder under `lib/features/<feature>/`. Read its existing layers
before changing anything:

- `data/datasources/*_remote_datasource.dart`
- `data/models/*_model.dart`
- `domain/entities/*_entity.dart`
- `domain/repositories/*_repository.dart` + `data/repositories/*_repository_impl.dart`
- `presentation/bloc/*_bloc.dart`
- `presentation/screens/*_screen.dart`
- `lib/core/network/api_endpoints.dart`

Common reality: the screen is **already built but serves mock/dummy data** (hardcoded lists
in the bloc, `AppConstantData.*` in the screen, hardcoded stat fallbacks). Your job is to
replace those three mock sources with the real endpoints.

Then **explain the plan to the user**: list the endpoints, the current mock sources, and a
file-by-file change list. Call out any field/shape/enum mismatches between the doc and the
existing model. If anything is ambiguous (scope, whether to rename fields, implement now vs
plan only), ask with `AskUserQuestion` before coding.

## Step 3 — Implement, layer by layer (outside-in)

1. **Endpoints** — add `static const String` paths to `ApiEndpoints` in
   `lib/core/network/api_endpoints.dart`, grouped with a comment and a `// See docs/api/<name>.md` ref.
2. **Entities** (`domain/entities/`) — pure Dart + `Equatable`. Field names should match the
   doc's semantics (camelCase). Add new entities for new resources.
3. **Models** (`data/models/`) — `fromJson` parses the doc's **exact** JSON keys
   (e.g. `in`/`out`/`hours`, `hours_this_week.worked`). Keep a `toEntity()`. Be defensive:
   `(j['x'] as num?)?.toDouble()`, `DateTime.tryParse`, fall back across `_id`/`id`.
4. **Datasource** — one method per endpoint via the injected `ApiClient`
   (`_client.get/post/...`). Unwrap the `{success, data}` envelope: read `res.data['data']`.
   Pass query params (`days`, `limit`) and POST bodies per the doc.
5. **Repository** — add the method to the abstract interface, then the impl. Return
   `(T, Failure?)` records, wrapping calls in `try / on Failure / catch` exactly like the
   sibling methods. Treat `NotFoundFailure` as an empty result where it makes sense.
6. **Bloc** — add events + handlers; **delete the dummy-data generator**. Fetch independent
   calls in parallel with `Future.wait`. States follow `Initial → Loading → Loaded(data) | Error`.
   Cache loaded data in private fields if a write action (e.g. submit) must re-emit `Loaded`
   without blanking the screen. For one-shot feedback (snackbars), emit a transient state that
   **extends `Loaded`** so the builder keeps rendering while a `listenWhen` listener fires once.
7. **Screen** — read from the bloc state, drop hardcoded fallbacks and `AppConstantData`.
   Map API enums to badges/labels with small helper methods. Use `BlocConsumer` when you need
   both rendering and snackbar/navigation side-effects.

## Step 4 — Verify

Run `flutter analyze lib/features/<feature> lib/core/network/api_endpoints.dart` and fix any
**errors/warnings** you introduced. Pre-existing `info` lints (e.g. `withOpacity`
deprecations) are fine to leave — match the surrounding code's style, don't mass-fix.

Report: a table of changed files, the new bloc events/states, any enum/field renames, and
anything left for the user (device smoke test, commit). Do not commit unless asked.

## Project conventions (must follow)

- Response envelope is `{ "success": true, "data": ... }`; errors `{ success:false, code, message }`.
  Read `data` from `res.data['data']`. The `ApiClient` already maps 401/404/timeouts to typed `Failure`s.
- Self-scoped employee endpoints: auth is the bearer token (injected by `AuthInterceptor`) —
  never send an employee id.
- Repos return Dart **records** `(value, Failure?)`, never throw to the bloc.
- DI: datasources/repos = `registerLazySingleton`, blocs = `registerFactory`, in
  `lib/config/di/injection.dart`. New feature graphs get registered there.
- UI: `flutter_screenutil` (`.w/.h/.r/.sp`), colors from `AppColors`, fonts `AirbnbCereal`/`Poppins`,
  shared widgets (`AppAppBar`, `LoadingWidget`, `EmptyState`, `CustomDropdown`, `SlidingTabs`).
- Worked example to copy patterns from: the **attendance** feature
  (`docs/api/attendance-log.md` → summary/log/issues wired through every layer).
