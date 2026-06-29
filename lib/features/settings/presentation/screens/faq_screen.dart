import 'package:flutter/material.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../data/datasources/settings_remote_datasource.dart';

// ── Models ────────────────────────────────────────────────────────
class FAQPriceTipsData {
  String id = "";
  String question = "";
  String answer = "";
  String category = "";
  bool selected = false;

  FAQPriceTipsData.fromJson(Map<String, dynamic> json) {
    id = json["_id"] ?? '';
    question = json["ques"] ?? "";
    answer = json["ans"] ?? "";
    category = json['category'] ?? "";
  }
}

class CategoryDataModel {
  String id = "";
  String name = "";
  bool selected = false;

  CategoryDataModel.fromJson(Map<String, dynamic> json) {
    id = json["_id"] ?? '';
    name = json["name"] ?? "";
  }
}

// ── Screen ────────────────────────────────────────────────────────
class FAQScreen extends StatefulWidget {
  final bool priceTipsSelected;
  final String type;
  final String benefits;
  final int index;

  const FAQScreen({
    super.key,
    required this.priceTipsSelected,
    required this.type,
    this.benefits = "",
    required this.index,
  });

  @override
  State<StatefulWidget> createState() => FAQScreenState();
}

class FAQScreenState extends State<FAQScreen> {
  final ScrollController listController = ScrollController();

  int selectedCategoryIndex = 0;
  int _offset = 0;

  bool isApiSuccess = false;
  bool isSearch = false;

  List<FAQPriceTipsData> questionAnswerList = [];
  List<FAQPriceTipsData> searchResult = [];
  List<CategoryDataModel> categoryList = [];

  final SettingsRemoteDatasource _datasource =
      getIt<SettingsRemoteDatasource>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => callFAQCategoryAPI());
  }

  Future<void> _onRefresh() async {
    setState(() {
      _offset = 0;
    });
    await _loadData();
  }

  Future<void> _loadData() async {
    if (categoryList.isEmpty) return;
    if (widget.priceTipsSelected) {
      await callFAQAPI(categoryList[selectedCategoryIndex].name);
    } else {
      await callFAQAPI(categoryList[selectedCategoryIndex].name);
    }
  }

  Future<void> callFAQCategoryAPI() async {
    try {
      final typeStr = widget.priceTipsSelected ? 'priceTip' : 'FAQ';
      final dataList = await _datasource.fetchCategories(typeStr);

      if (dataList.isNotEmpty) {
        categoryList = dataList
            .map((e) => CategoryDataModel.fromJson(e))
            .toList();
        String categoryName = "";
        if (categoryList.isNotEmpty) {
          if (widget.benefits.isEmpty) {
            categoryName = categoryList.first.name;
            int idx = categoryList.indexWhere(
              (element) => element.name == categoryName,
            );
            if (idx >= 0) categoryList[idx].selected = true;
          } else {
            categoryName = categoryList.last.name;
            int idx = categoryList.lastIndexWhere(
              (element) => element.name.contains(categoryName),
            );
            if (idx >= 0) categoryList[idx].selected = true;
          }
        }
        if (widget.index == 1 && categoryList.length > 1) {
          for (var item in categoryList) {
            item.selected = false;
          }
          categoryList[1].selected = true;
        }

        if (widget.priceTipsSelected) {
          await callFAQAPI(categoryList.first.name);
        } else {
          if (widget.benefits.isNotEmpty) {
            for (var item in categoryList) {
              item.selected = false;
            }
            if (categoryList.length > 5) categoryList[5].selected = true;
            await callFAQAPI("PRO benefits");
          } else {
            await callFAQAPI(
              widget.index == 1 && categoryList.length > 1
                  ? "Emergency"
                  : categoryList.first.name,
            );
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("callFAQCategoryAPI Error: $e");
    }
  }

  Future<void> callFAQAPI(String category) async {
    try {
      final list = await _datasource.fetchFaqs(widget.type, category, _offset);
      if (list.isNotEmpty) {
        if (_offset == 0) {
          questionAnswerList = list
              .map((e) => FAQPriceTipsData.fromJson(e))
              .toList();
        } else {
          questionAnswerList.addAll(
            list.map((e) => FAQPriceTipsData.fromJson(e)).toList(),
          );
        }
        isApiSuccess = true;
      } else if (_offset == 0) {
        questionAnswerList = [];
        isApiSuccess = true;
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("callFAQAPI Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final Color themeColor = AppColors.primary;

    return Scaffold(
      appBar: AppAppBar(
        title: widget.priceTipsSelected ? "Price Tips" : "FAQs",
        showBack: true,
        showLogo: true,
      ),
      body: SafeArea(
        child: isApiSuccess
            ? RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.width * 0.03,
                        ),
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: "Search here...",
                            filled: true,
                            fillColor: const Color(0xFFF1F1F1),
                            hintStyle: TextStyle(
                              color: Colors.black,
                              fontSize: size.width * 0.035,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.03,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.03,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.03,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.03,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.03,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: Padding(
                              padding: EdgeInsets.only(
                                right: size.width * 0.04,
                              ),
                              child: const Icon(
                                Icons.search,
                                color: Colors.black,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04,
                              vertical: size.width * 0.015,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              searchResult = questionAnswerList
                                  .where(
                                    (element) => element.question
                                        .toLowerCase()
                                        .contains(value.toLowerCase()),
                                  )
                                  .toList();
                              isSearch = true;
                            } else {
                              isSearch = false;
                            }
                            setState(() {});
                          },
                        ),
                      ),
                      categoryList.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text("No Category found"),
                              ),
                            )
                          : Container(
                              height: size.width * 0.15,
                              margin: EdgeInsets.only(left: size.width * 0.035),
                              child: ListView.separated(
                                controller: listController,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  return InkWell(
                                    onTap: () {
                                      int pos = categoryList.indexWhere(
                                        (element) => element.selected,
                                      );
                                      if (pos >= 0) {
                                        categoryList[pos].selected = false;
                                      }
                                      categoryList[index].selected =
                                          !categoryList[index].selected;
                                      if (categoryList[index].selected) {
                                        selectedCategoryIndex = index;
                                        _offset = 0;
                                        callFAQAPI(
                                          categoryList[selectedCategoryIndex]
                                              .name,
                                        );
                                      }

                                      listController.animateTo(
                                        index * 100.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.ease,
                                      );

                                      setState(() {});
                                    },
                                    child: Chip(
                                      backgroundColor:
                                          categoryList[index].selected
                                          ? Colors.black
                                          : const Color(0xFFF1F1F1),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: size.width * 0.025,
                                        vertical: size.width * 0.02,
                                      ),
                                      label: Text(
                                        categoryList[index].name,
                                        style: TextStyle(
                                          color: categoryList[index].selected
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: size.width * 0.036,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return SizedBox(width: size.width * 0.04);
                                },
                                itemCount: categoryList.length,
                              ),
                            ),
                      questionAnswerList.isNotEmpty
                          ? ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.035,
                                vertical: 10,
                              ),
                              itemBuilder: (context, index) {
                                var item = isSearch
                                    ? searchResult[index]
                                    : questionAnswerList[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      size.width * 0.02,
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: ExpansionTile(
                                    title: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(
                                            top: size.width * 0.01,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: size.width * 0.02,
                                            vertical: size.width * 0.01,
                                          ),
                                          decoration: BoxDecoration(
                                            color: themeColor,
                                            borderRadius: BorderRadius.circular(
                                              size.width * 0.01,
                                            ),
                                          ),
                                          child: Text(
                                            "Q",
                                            style: TextStyle(
                                              fontSize: size.width * 0.036,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: size.width * 0.02),
                                        Expanded(
                                          child: Text(
                                            item.question,
                                            style: TextStyle(
                                              fontSize: size.width * 0.035,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    iconColor: Colors.black,
                                    onExpansionChanged: (value) {
                                      item.selected = value;
                                      setState(() {});
                                    },
                                    children: [
                                      Container(
                                        height: 1,
                                        margin: EdgeInsets.only(
                                          bottom: size.width * 0.04,
                                          left: size.width * 0.04,
                                          right: size.width * 0.04,
                                        ),
                                        width: size.width,
                                        color: Colors.grey.shade300,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: size.width * 0.04,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(
                                                top: size.width * 0.01,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: size.width * 0.02,
                                                vertical: size.width * 0.01,
                                              ),
                                              decoration: BoxDecoration(
                                                color: themeColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      size.width * 0.01,
                                                    ),
                                              ),
                                              child: Text(
                                                "A",
                                                style: TextStyle(
                                                  fontSize: size.width * 0.035,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: size.width * 0.02),
                                            Expanded(
                                              child: Text(
                                                item.answer,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: size.width * 0.035,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: size.width * 0.04),
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) {
                                return SizedBox(height: size.width * 0.04);
                              },
                              itemCount: isSearch
                                  ? searchResult.length
                                  : questionAnswerList.length,
                            )
                          : const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("No FAQ found"),
                            ),
                    ],
                  ),
                ),
              )
            : const LoadingWidget(),
      ),
    );
  }
}
