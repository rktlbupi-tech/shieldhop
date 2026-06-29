# Google Play Console Location Permission Declaration

This document contains the required text drafts and compliance instructions for submitting the **PressHop Enterprise** location permission declaration to the Google Play Console.

---

## 1. App Purpose
**Question in Play Console:** *What is the main purpose of your app?* (Max 500 characters)

### Copy-Paste Text (447 Characters):
```text
PressHop Enterprise is a workforce management app for field service operations. It helps businesses assign shifts, coordinate tasks, manage evidence collection, and track mileage. Field staff can view their daily schedule, report status, and coordinate with the dispatch office. Background location is required to ensure accurate shift log reports, live safety tracking (including an SOS trigger), and automated mileage logs, enabling teams to operate safely and efficiently.
```

---

## 2. Location Access Feature
**Question in Play Console:** *Describe one location-based feature in your app that needs access to location in the background.* (Max 500 characters)

### Copy-Paste Text (439 Characters):
```text
The app includes a live tracking feature that maps teammate locations and tracks shift mileage. When a worker starts a duty shift, background location allows the app to calculate task distances for mileage reimbursement and displays active staff on a secure company map for coordinator safety and SOS response. This continues running in the background while the screen is off or another app is open, ending immediately when the worker ends their shift.
```

---

## 3. Compliance Requirements

To secure approval for background location permission, the app must meet the following Google guidelines:

### A. Prominent Disclosure (In-App Popup Dialog)
Before showing the Android system runtime permission prompt, the app must show a custom dialog explaining how background location is used.
* **Key Requirement:** It must explicitly contain the words: **"...even when the app is closed or not in use."**
* **Example Dialog Text:**
  > *"PressHop Enterprise collects location data to enable live shift tracking, mileage calculation, and teammate SOS safety coordination even when the app is closed or not in use."*

### B. YouTube Walkthrough Video
Provide a link to an Unlisted YouTube video demonstrating the background location usage.
* **Duration:** Recommended 30 seconds or shorter.
* **Must show:**
  1. The user starting a shift or triggering a location-dependent task.
  2. The custom **Prominent Disclosure** popup appearing *first*.
  3. The user tapping the consent option (e.g., "Accept" or "Agree").
  4. The Android system location permission dialog appearing.
  5. The user selecting **"Allow all the time"** (background permission).
  6. The app running and successfully tracking location.

---

## 4. Foreground Service Location Permission

For Android 14+ (API 34+), Google requires declaring why the app uses a Foreground Service for location (`FOREGROUND_SERVICE_LOCATION`).

### Which options to select:
You should check the following two boxes on the form:

1. **[x] Background location updates**
   * **Why:** The app runs a foreground service during an active duty shift to receive periodic location updates for task distance tracking and automated mileage calculation.
2. **[x] User-initiated location sharing**
   * **Why:** The user explicitly initiates location sharing with their team/office by starting a shift, which maps teammate coordinates on the live office dispatcher portal.

### Description to use if prompted for text:
If Google Play Console requests a text explanation for these selections, you can use:
```text
PressHop Enterprise uses a location-based foreground service when a worker starts an active duty shift. This service is visible to the user via a persistent status bar notification. It allows the app to perform background location updates for automated task mileage calculations and user-initiated location sharing so that teammate safety maps are kept up-to-date in real time.
```
