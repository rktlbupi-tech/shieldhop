# Presshop Enterprise — API Integration Status & Roadmap

This document outlines the current state of API integration across the features of the **Presshop Enterprise** Flutter application, with a detailed breakdown of the **Documents ("Doc") Section** and what is remaining to be integrated.

---

## 📊 Overview of Features Status

Below is the high-level integration status of all modules defined under `lib/features/`:

| Feature / Module | Status | Integrated Endpoints | Remaining Steps / Notes |
| :--- | :---: | :--- | :--- |
| **Auth** | 🟢 Fully Integrated | `auth/loginEnterpriseEmployee`<br>`auth/registerEnterpriseEmployee`<br>`auth/forgotPassword`<br>`auth/resetPassword` | None. |
| **Profile** | 🟢 Fully Integrated | `hopper/getEnterpriseUserProfile`<br>`hopper/updateEnterpriseUserProfile`<br>`hopper/uploadUserMedia` (avatar) | None. |
| **Attendance** | 🟢 Fully Integrated | `enterprise/attendance/check-in`<br>`enterprise/attendance/check-out`<br>`enterprise/attendance/log` | None. |
| **Tasks** | 🟢 Fully Integrated | `enterprise/tasks`<br>`enterprise/tasks/:id` (fetch & details updates) | None. |
| **Earnings** | 🟢 Fully Integrated | `enterprise/earnings`<br>`enterprise/earnings?ytd=true` | None. |
| **Notifications** | 🟢 Fully Integrated | `enterprise/devices/fcm-token`<br>`enterprise/notifications`<br>`enterprise/notifications/unread-count`<br>`enterprise/notifications/read-all` | None. |
| **Settings & Support**| 🟢 Fully Integrated | `hopper/verifyAndDeleteAccount`<br>`hopper/Addcontact_us`<br>`hopper/getGenralMgmtApp`<br>`hopper/getCategory`<br>`users/changePassword` | None. |
| **SOS & Heatmaps** | 🟡 Partially Integrated | `enterprise/heatmap/location`<br>`enterprise/heatmap/workers`<br>`enterprise/heatmap/alerts`<br>`enterprise/sos/start`<br>`enterprise/sos/stop`<br>`enterprise/sos/me` | SOS functions directly bypass standard repository/bloc architecture. Needs Clean Architecture refactoring. |
| **Documents** | 🟡 Partially Integrated | `enterprise/documents` (GET list only) | **Upload, Delete, and Download are currently mock/simulated** in the presentation layer. Details below. |
| **Duties** | 🔴 Mock Only | None | Needs Data & Domain layers. Shift info, list, task checklist, and history filter (previous 1 year) are mock. |
| **Mileage & Expense** | 🔴 Mock Only | None | Needs Data & Domain layers. Tracker and claim forms are mock. |
| **Chat & Team Chat** | 🔴 Mock Only | None | Sockets/Endpoints for messaging rooms and chat logs are mock. |
| **Submit Forms** | 🔴 Mock Only | None | General form/evidence submissions are mock. |

---

## 📂 Detailed Focus: Documents ("Doc") Section

The Documents feature located in [lib/features/documents](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents) is structurally prepared using Clean Architecture (with a Bloc, Entity, Model, Repository, and Datasource) but only the **fetching** of documents is integrated. 

### 1. Current State
* **Fetch Documents**: Calls `GET enterprise/documents` through `DocumentsRemoteDatasource` via `DocumentsBloc`.
* **Mock Merging**: In [documents_screen.dart](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents/presentation/screens/documents_screen.dart#L546-L565), the UI merges the fetched documents with `_defaultMockDocuments` to show placeholder items if the API returns an empty list.

### 2. Remaining API Integrations in Documents Feature

#### A. Document Upload
* **Current Mock Code**: Inside `_DocumentsViewState`, file selection via camera/gallery/picker triggers `_simulateUpload` ([documents_screen.dart:L162-217](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents/presentation/screens/documents_screen.dart#L162-L217)) which uses a mock timer to increment upload progress, then inserts a local model into the view state.
* **API Integration Needed**:
  1. Add `uploadDocument` to `DocumentsRemoteDatasource`.
     * Step 1: Upload the file binary to `hopper/uploadUserMedia` as `MultipartFile` (similar to how profile uploads images) to obtain the public `mediaurl`.
     * Step 2: Post the document metadata (name, type, category, and file URL) to `enterprise/documents` (POST).
  2. Define `UploadDocument` event, repository method, and update `DocumentsBloc` to handle state transitions (`DocumentsUploading`, `DocumentsUploaded`, `DocumentsUploadError`).

#### B. Document Delete
* **Current Mock Code**: Inside `_showDocumentActions` ([documents_screen.dart:L503-522](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents/presentation/screens/documents_screen.dart#L503-L522)), the delete action removes the item from the local UI array state directly.
* **API Integration Needed**:
  1. Add `deleteDocument(String id)` to `DocumentsRemoteDatasource` using `DELETE enterprise/documents/:id`.
  2. Implement repository method, add `DeleteDocument` event to `DocumentsBloc`, and emit loading/loaded states to trigger a refresh.

#### C. Document Download & Preview
* **Current Mock Code**: Clicking download ([documents_screen.dart:L493-501](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents/presentation/screens/documents_screen.dart#L493-L501)) only pops up a snackbar: *"Downloading document..."*.
* **API Integration Needed**:
  1. Integrate a downloading service (such as using `dio` to download the file by URL, or `flutter_downloader`).
  2. Save the file to the local device storage using `path_provider` and display a local success notification or open the file directly.

---

## 🛠️ Code Files To Modify

To implement the remaining API integrations in the Documents section, modify the following files:

### Data & Domain Layers
1. **[documents_remote_datasource.dart](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents/data/datasources/documents_remote_datasource.dart)**:
   * Add:
     ```dart
     Future<bool> uploadDocument(String name, String type, String category, String filePath) async {
       // 1. Upload media to hopper/uploadUserMedia
       // 2. POST metadata to enterprise/documents
     }
     Future<bool> deleteDocument(String id) async {
       // DELETE enterprise/documents/$id
     }
     ```
2. **[documents_repository.dart](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents/domain/repositories/documents_repository.dart)** and **[documents_repository_impl.dart](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents/data/repositories/documents_repository_impl.dart)**:
   * Expose contract and implementation for `uploadDocument` and `deleteDocument`.

### State Management
3. **[documents_bloc.dart](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents/presentation/bloc/documents_bloc.dart)**:
   * Add `UploadDocument` and `DeleteDocument` event definitions.
   * Implement event handlers that call repository functions and yield states.

### Presentation UI
4. **[documents_screen.dart](file:///Users/rajesh/Documents/PresshopComplete/Presshop+/presshop_enterprise/lib/features/documents/presentation/screens/documents_screen.dart)**:
   * Replace `_simulateUpload` with dispatching the `UploadDocument` event to the Bloc.
   * Replace local `_documents?.remove(doc)` in `_showDocumentActions` with dispatching `DeleteDocument` event.
   * Handle BLoC state updates for upload/delete progress and screen refresh.
