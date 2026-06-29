import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:presshop_enterprise/main.dart' show navigatorKey;
import 'package:presshop_enterprise/features/splash/data/repositories/force_update_repository.dart';
import 'package:presshop_enterprise/features/camera/utils/camera_constants.dart';

class ForceUpdateManager {
  static bool isForceUpdateDialogShowing = false;
  static DateTime? _lastManualCheckTime;

  static void _openStore() async {
    final url = Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=com.cerebera.shieldhop'
        : 'https://apps.apple.com/app/id6744651614';

    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not open store: $e");
    }
  }

  static Future<bool?> showForceUpdateAlertGlobal(
    BuildContext context,
    bool allowCancel,
  ) async {
    if (isForceUpdateDialogShowing) return null;
    isForceUpdateDialogShowing = true;

    final size = MediaQuery.of(context).size;
    final dialogContext = navigatorKey.currentContext ?? context;

    final result = await showDialog<bool?>(
      context: dialogContext,
      barrierDismissible: allowCancel,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => allowCancel,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            contentPadding: EdgeInsets.zero,
            insetPadding: EdgeInsets.symmetric(horizontal: size.width * numD04),
            content: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size.width * numD045),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: size.width * numD04,
                      top: size.width * numD02,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "Update Required",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: size.width * numD04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * numD04,
                    ),
                    child: const Divider(color: Colors.black, thickness: 0.5),
                  ),
                  SizedBox(height: size.width * numD02),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * numD04,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              size.width * numD04,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              size.width * numD04,
                            ),
                            child: Image.asset(
                              "assets/rabbits/update_rabbit.png",
                              height: size.width * numD25,
                              width: size.width * numD35,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * numD04),
                        Expanded(
                          child: Text(
                            "A newer version of PressHop is available. Please update the app to continue using all features smoothly.",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: size.width * numD035,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.width * numD08),
                  SizedBox(
                    height: size.width * 0.12,
                    width: size.width * numD35,
                    child: commonElevatedButton(
                      "Update Now",
                      size,
                      commonButtonTextStyle(size),
                      commonButtonStyle(size, colorEmployeeGreen1),
                      _openStore,
                    ),
                  ),
                  SizedBox(height: size.width * numD05),
                ],
              ),
            ),
          ),
        );
      },
    );
    isForceUpdateDialogShowing = false;
    return result;
  }

  static Future<void> checkAndShowForceUpdate({
    bool forceRefresh = false,
  }) async {
    if (isForceUpdateDialogShowing) return;

    final now = DateTime.now();
    if (forceRefresh) {
      if (_lastManualCheckTime != null &&
          now.difference(_lastManualCheckTime!) < const Duration(seconds: 15)) {
        debugPrint("Skipping manual/tab force update check (cooldown active)");
        return;
      }
      _lastManualCheckTime = now;
    }

    try {
      final force = await ForceUpdateRepository.checkForceUpdate(
        forceRefresh: forceRefresh,
      );
      if (force) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showForceUpdateAlertGlobal(context, false);
          });
        }
      }
    } catch (e) {
      debugPrint("Force update check failed: $e");
    }
  }
}
