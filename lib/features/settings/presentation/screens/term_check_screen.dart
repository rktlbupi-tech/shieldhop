import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:presshop_enterprise/core/constants/app_colors.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import 'package:presshop_enterprise/common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';

import '../../data/datasources/settings_remote_datasource.dart';

class TermCheckScreen extends StatefulWidget {
  final String type; // e.g. "legal" or "privacy_policy"
  const TermCheckScreen({super.key, required this.type});

  @override
  State<TermCheckScreen> createState() => _TermCheckScreenState();
}

class _TermCheckScreenState extends State<TermCheckScreen> {
  bool isSelectUpArrow = false;
  String updatedDate = "";
  final ScrollController scrollController = ScrollController();
  List<String> htmlDataList = [];
  bool isLoading = true;

  final SettingsRemoteDatasource _datasource =
      getIt<SettingsRemoteDatasource>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => callCMSAPi());
  }

  void _scrollDown() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        !isSelectUpArrow
            ? scrollController.position.maxScrollExtent
            : scrollController.position.minScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Future<void> callCMSAPi() async {
    try {
      final html = await _datasource.fetchLegalTerms(widget.type);
      if (html != null && html.isNotEmpty) {
        htmlDataList.add(html);
        // Note: The date formatting logic can be added if backend provides it alongside description.
        // Currently we fetch just the description string from datasource.
      }
    } catch (e) {
      debugPrint("callCMSAPi error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      floatingActionButton: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: InkWell(
            onTap: () {
              _scrollDown();
              setState(() {
                isSelectUpArrow = !isSelectUpArrow;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                top: 6,
                bottom: 6,
                left: 15,
                right: 5,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      'Scroll ${!isSelectUpArrow ? "Down" : "Up"}',
                      key: ValueKey<bool>(isSelectUpArrow),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4F4F4F),
                        fontSize: size.width * 0.04,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: isSelectUpArrow ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_sharp,
                        color: Colors.white,
                        size: size.width * 0.085,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      appBar: AppAppBar(
        title: widget.type == "privacy_policy"
            ? "Privacy policy"
            : "Legal T&Cs",
        showBack: true,
        showLogo: true,
      ),
      body: isLoading
          ? const LoadingWidget()
          : htmlDataList.isNotEmpty
          ? SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.02,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Html(
                        data: htmlDataList[index],
                        style: {
                          "span": Style(
                            color: const Color(0xFF909090),
                            fontSize: FontSize(size.width * 0.035),
                          ),
                          "h1": Style(
                            color: const Color(0xFF333333),
                            fontSize: FontSize(size.width * 0.045),
                            padding: HtmlPaddings.symmetric(
                              vertical: size.width * 0.01,
                            ),
                          ),
                          "h2": Style(
                            color: Colors.black,
                            fontSize: FontSize(size.width * 0.04),
                            padding: HtmlPaddings.symmetric(
                              vertical: size.width * 0.01,
                            ),
                          ),
                          "h3": Style(
                            color: Colors.black,
                            fontSize: FontSize(size.width * 0.035),
                            padding: HtmlPaddings.symmetric(
                              vertical: size.width * 0.01,
                            ),
                          ),
                          "h4": Style(
                            color: Colors.black,
                            fontSize: FontSize(size.width * 0.035),
                            padding: HtmlPaddings.symmetric(
                              vertical: size.width * 0.01,
                            ),
                          ),
                          "td": Style(
                            color: const Color(0xFF666666),
                            fontSize: FontSize(size.width * 0.035),
                            padding: HtmlPaddings.symmetric(
                              vertical: size.width * 0.01,
                            ),
                          ),
                          "th": Style(
                            color: const Color(0xFF666666),
                            fontSize: FontSize(size.width * 0.035),
                            fontWeight: FontWeight.w600,
                            padding: HtmlPaddings.zero,
                          ),
                          "div": Style(
                            backgroundColor: const Color(0xFFF9F9F9),
                          ),
                        },
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 0),
                    itemCount: htmlDataList.length,
                  ),
                  const SizedBox(height: 120), // Padding for floating button
                ],
              ),
            )
          : const Center(child: Text("No data found")),
    );
  }
}
