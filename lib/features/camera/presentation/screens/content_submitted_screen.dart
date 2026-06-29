import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/camera_data.dart';
import '../../utils/camera_constants.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../settings/presentation/screens/faq_screen.dart';
import '../../../settings/presentation/screens/contact_us_screen.dart';

class ContentSubmittedScreen extends StatelessWidget {
  final PublishData? publishData;

  const ContentSubmittedScreen({super.key, this.publishData});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    int imageCount = 0;
    int videoCount = 0;
    int audioCount = 0;
    int docCount = 0;
    int pdfCount = 0;

    if (publishData != null) {
      for (final media in publishData!.mediaList) {
        if (media.mimeType == 'image') imageCount++;
        if (media.mimeType == 'video') videoCount++;
        if (media.mimeType == 'audio') audioCount++;
        if (media.mimeType == 'doc') docCount++;
        if (media.mimeType == 'pdf') pdfCount++;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(initialIndex: 2),
            ),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: size.width * numD04,
          title: Text(
            "Content Submitted",
            style: TextStyle(
              color: Colors.black,
              fontSize: size.width * appBarHeadingFontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'AirbnbCereal',
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: size.width * numD04),
              // Media Card
              Padding(
                padding: EdgeInsets.zero,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * numD04,
                    vertical: size.width * numD04,
                  ),
                  decoration: const BoxDecoration(
                    color: colorLightGrey,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(size.width * numD06),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            _buildThumbnail(size),
                            Image.asset(
                              "assets/images/watermark1.png",
                              width: size.width * numD30,
                              height: size.width * numD35,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              margin: EdgeInsets.only(
                                top: size.width * numD02,
                                bottom: size.width * numD02,
                                right: size.width * numD02,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(
                                      size.width * numD013),
                                ),
                                child: Text(
                                  (imageCount + videoCount + audioCount).toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: size.width * numD03,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'AirbnbCereal',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: size.width * numD04),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: size.width * numD04),
                          child: Text(
                            "Your Submission Has Been Received",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: size.width * numD032,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: size.width * numD04),
              // Note Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * numD04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your content or evidence has been securely uploaded and shared with your organisation for review and further action. All submissions are automatically processed through PressHop's AI moderation tools to detect manipulated, AI-generated, or non-compliant content.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: size.width * numD03,
                        color: Colors.black,
                        height: 1.5,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                    SizedBox(height: size.width * numD04),
                    RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: size.width * numD03,
                          color: Colors.black,
                          height: 1.5,
                          fontFamily: 'AirbnbCereal',
                        ),
                        children: [
                          const TextSpan(
                            text:
                                "If any additional information is required, your team manager or organisation may contact you directly. Need help? Please review the ",
                          ),
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FAQScreen(
                                      priceTipsSelected: false,
                                      type: 'FAQ',
                                      index: 0,
                                    ),
                                  ),
                                );
                              },
                            text: "FAQs",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colorEmployeeGreen1,
                            ),
                          ),
                          const TextSpan(text: " or "),
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ContactUsScreen(),
                                  ),
                                );
                              },
                            text: "Contact Support",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colorEmployeeGreen1,
                            ),
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Bottom Action Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * numD06),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: size.width * numD15,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  size.width * numD03),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DashboardScreen(initialIndex: 0),
                              ),
                              (route) => false,
                            );
                          },
                          child: Text(
                            "Evidence",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * numD035,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * numD04),
                    Expanded(
                      child: SizedBox(
                        height: size.width * numD15,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorEmployeeGreen1,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  size.width * numD03),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DashboardScreen(initialIndex: 2),
                              ),
                              (route) => false,
                            );
                          },
                          child: Text(
                            "Home",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * numD035,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.width * numD04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Size size) {
    final mList = publishData?.mediaList ?? [];
    final mimeType = publishData?.mimeType ?? '';

    if (mList.isNotEmpty &&
        mList.first.mimeType == 'image' &&
        mList.first.isLocalMedia) {
      return Image.file(
        File(mList.first.mediaPath),
        width: size.width * numD30,
        height: size.width * numD35,
        fit: BoxFit.cover,
      );
    }
    if (mList.isNotEmpty && mList.first.mimeType == 'video') {
      final thumb = mList.first.thumbnail;
      if (thumb.isNotEmpty && File(thumb).existsSync()) {
        return Image.file(
          File(thumb),
          width: size.width * numD30,
          height: size.width * numD35,
          fit: BoxFit.cover,
        );
      }
    }
    if (mList.isNotEmpty && mList.first.mimeType == 'audio') {
      return Container(
        width: size.width * numD30,
        height: size.width * numD35,
        color: colorEmployeeGreen1,
        child: Icon(Icons.play_arrow_rounded,
            size: size.width * numD18, color: Colors.white),
      );
    }
    if (mimeType.contains('pdf')) {
      return Container(
        width: size.width * numD30,
        height: size.width * numD35,
        color: colorLightGrey,
        child: Icon(Icons.picture_as_pdf,
            size: size.width * numD18, color: Colors.red),
      );
    }
    if (mimeType.contains('doc')) {
      return Container(
        width: size.width * numD30,
        height: size.width * numD35,
        color: colorLightGrey,
        child: Icon(Icons.description,
            size: size.width * numD18, color: Colors.blue),
      );
    }
    return Container(
      width: size.width * numD30,
      height: size.width * numD35,
      color: colorLightGrey,
      child: Icon(Icons.image, size: size.width * numD18, color: Colors.grey),
    );
  }
}
