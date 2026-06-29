// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_html/flutter_html.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:presshop/main.dart';
// import 'package:presshop/utils/CommonAppBar.dart';
// import 'package:presshop/utils/CommonExtensions.dart';
// import 'package:presshop/utils/my_common.dart';
// import 'package:presshop/utils/networkOperations/NetworkResponse.dart';
// import 'package:presshop/view/employee/controller/role_controller.dart';

// import '../../utils/Common.dart';
// import '../../utils/CommonWigdets.dart';
// import '../../utils/networkOperations/NetworkClass.dart';
// import '../dashboard/Dashboard.dart';

// class TermCheckScreen extends ConsumerStatefulWidget {
//   String type = "";

//   TermCheckScreen({Key? key, required this.type}) : super(key: key);

//   @override
//   ConsumerState<TermCheckScreen> createState() => _TermCheckScreenState();
// }

// class _TermCheckScreenState extends ConsumerState<TermCheckScreen>
//     implements NetworkResponse {
//   bool check1Value = false,
//       check2Value = false,
//       check3Value = false,
//       check4Value = false,
//       isSelectUpArrow = false;

//   String updatedDate = "";
//   var scrollController = ScrollController();
//   List<String> htmlDataList = [];

//   scrollToBottom() {
//     scrollController.jumpTo(scrollController.position.maxScrollExtent);
//   }

//   @override
//   void initState() {
//     super.initState();
//     debugPrint("class==> $runtimeType::::${widget.type}");
//     debugPrint("rememberMe:::::::::::$rememberMe");

//     if (widget.type == "legal") {
//       WidgetsBinding.instance
//           .addPostFrameCallback((timeStamp) => callSignUpLegalApi());
//     } else {
//       WidgetsBinding.instance.addPostFrameCallback((timeStamp) => callCMSAPi());
//     }
//   }

//   void _scrollDown() {
//     if (scrollController.hasClients) {
//       scrollController.animateTo(
//         !isSelectUpArrow
//             ? scrollController.position.maxScrollExtent
//             : scrollController.position.minScrollExtent,
//         duration: const Duration(seconds: 2),
//         curve: Curves.fastOutSlowIn,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     var size = MediaQuery.of(context).size;
//     return Scaffold(
//       floatingActionButton: AnimatedSize(
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//         child: Padding(
//           padding: const EdgeInsets.only(bottom: 80.0),
//           child: InkWell(
//             onTap: () {
//               _scrollDown();
//               setState(() {
//                 isSelectUpArrow = !isSelectUpArrow;
//               });
//             },
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(40),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.3),
//                     blurRadius: 5,
//                     offset: Offset(0, 3),
//                   ),
//                 ],
//               ),
//               padding: EdgeInsets.only(top: 6, bottom: 6, left: 15, right: 5),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   AnimatedSwitcher(
//                     duration: Duration(milliseconds: 300),
//                     transitionBuilder: (child, animation) {
//                       return FadeTransition(opacity: animation, child: child);
//                     },
//                     child: Text(
//                       'Scroll ${!isSelectUpArrow ? "Down" : "Up"}',
//                       key: ValueKey<bool>(isSelectUpArrow),
//                       style: TextStyle(
//                         fontWeight: FontWeight.w500,
//                         color: const Color(0xFF4F4F4F),
//                         fontSize: size.width * numD04,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   AnimatedRotation(
//                     turns: isSelectUpArrow ? 0.5 : 0,
//                     duration: Duration(milliseconds: 300),
//                     child: Container(
//                       width: 46,
//                       height: 46,
//                       decoration: BoxDecoration(
//                         color: ref.watch(userRoleProvider).activeColor,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.keyboard_arrow_down_sharp,
//                         color: Colors.white,
//                         size: size.width * numD085,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//       appBar: CommonAppBar(
//         elevation: 0,
//         hideLeading: false,
//         title: Text(
//             widget.type == "privacy_policy"
//                 ? privacyPolicyText
//                 : "$legalText $tcText",
//             style: TextStyle(
//                 color: Colors.black,
//                 fontWeight: FontWeight.bold,
//                 fontSize: size.width * appBarHeadingFontSize)),
//         centerTitle: false,
//         titleSpacing: 0,
//         size: size,
//         showActions: true,
//         leadingFxn: () {
//           Navigator.pop(context);
//         },
//         actionWidget: [
//           InkWell(
//             onTap: () {
//               Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => Dashboard(initialPosition: 2)));
//             },
//             child: ref.watch(userRoleProvider).role == UserRole.employee
//                 ? emilyLogoWidgetForPagesForEmployee(
//                     MyCommon.responsiveWidth(size))
//                 : emilyLogoWidgetForPages(MyCommon.responsiveWidth(size)),
//           ),
//           SizedBox(
//             width: size.width * numD02,
//           ),
//         ],
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           SizedBox(
//             height: size.width * numD02,
//           ),
//           htmlDataList.isNotEmpty
//               ? Flexible(
//                   child: SingleChildScrollView(
//                   controller: scrollController,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       !rememberMe
//                           ? Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: size.width * numD04),
//                               child: Text(
//                                 "PLEASE READ THESE LICENCE TERMS CAREFULLY. BY CLICKING ON THE ${"ACCEPT"} BUTTON BELOW YOU AGREE TO THESE TERMS WHICH WILL BIND YOU. IF YOU DO NOT AGREE TO THESE TERMS, CLICK ON THE REJECT BUTTON BELOW.",
//                                 style: TextStyle(
//                                     color: Colors.black,
//                                     fontSize: size.width * numD035,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             )
//                           : Container(),
//                       /*   SizedBox(
//                         height: size.width * numD06,
//                       ),
//                       Padding(
//                         padding: EdgeInsets.symmetric(
//                             horizontal: size.width * numD06),
//                         child: Text(
//                           "Updated on : $updatedDate",
//                           style: commonTextStyle(
//                               size: size,
//                               fontSize: size.width * numD035,
//                               color: colorHint,
//                               fontWeight: FontWeight.w500),
//                         ),
//                       ),*/
//                       ListView.separated(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: size.width * numD02),
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemBuilder: (context, index) {
//                             return Html(
//                               data: htmlDataList[index],
//                               style: {
//                                 "span": Style(
//                                   color: colorTextFieldIcon,
//                                   fontSize: FontSize(size.width * numD01),
//                                 ),
//                                 "h1": Style(
//                                     color: colorGreyNew,
//                                     fontSize: FontSize(size.width * numD02),
//                                     padding: HtmlPaddings.symmetric(
//                                         vertical: size.width * numD01)),
//                                 "h2": Style(
//                                     color: Colors.black,
//                                     fontSize: FontSize(size.width * numD04),
//                                     padding: HtmlPaddings.symmetric(
//                                         vertical: size.width * numD01)),
//                                 "h3": Style(
//                                     color: Colors.black,
//                                     fontSize: FontSize(size.width * numD035),
//                                     padding: HtmlPaddings.symmetric(
//                                         vertical: size.width * numD01)),
//                                 "h4": Style(
//                                     color: Colors.black,
//                                     fontSize: FontSize(size.width * numD035),
//                                     padding: HtmlPaddings.symmetric(
//                                         vertical: size.width * numD01)),
//                                 "td": Style(
//                                     color: colorGreyNew,
//                                     fontSize: FontSize(size.width * numD02),
//                                     padding: HtmlPaddings.symmetric(
//                                         vertical: size.width * numD01)),
//                                 "th": Style(
//                                     color: colorGreyNew,
//                                     fontSize: FontSize(size.width * numD02),
//                                     fontWeight: FontWeight.w600,
//                                     padding: HtmlPaddings.zero),
//                                 "div": Style(
//                                   backgroundColor: colorLightGrey,
//                                 )
//                               },
//                             );
//                           },
//                           separatorBuilder: (context, index) {
//                             return const SizedBox(
//                               height: 0,
//                             );
//                           },
//                           itemCount: htmlDataList.length),
//                       !rememberMe ? checkBoxWidget(size) : Container(),
//                       !rememberMe
//                           ? Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: size.width * numD06),
//                               child: buttonWidget(size),
//                             )
//                           : Container(),
//                     ],
//                   ),
//                 ))
//               : Container()
//         ],
//       ),
//     );
//   }

//   Widget termCheckWidget(Size size) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: size.width * numD15),
//       child: const Column(
//         children: [
//           Text(
//             legalDescText,
//             style: TextStyle(fontWeight: FontWeight.w300),
//           )
//         ],
//       ),
//     );
//   }

//   //termAndCondition
//   Widget termsAndConditions(Size size) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         Text(
//           legalDummyText,
//           style: commonTextStyle(
//               size: size,
//               fontSize: size.width * numD02,
//               color: colorHint,
//               fontWeight: FontWeight.w400),
//         ),
//         SizedBox(
//           height: size.width * numD02,
//         ),
//         Text(
//           termsAndConditionText,
//           style: commonTextStyle(
//               size: size,
//               fontSize: size.width * numD04,
//               color: Colors.black,
//               fontWeight: FontWeight.w400),
//         ),
//         SizedBox(
//           height: size.width * numD02,
//         ),
//         Container(
//           decoration: const BoxDecoration(color: colorLightGrey),
//           padding: EdgeInsets.all(size.width * numD04),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "What & Why",
//                 style: commonTextStyle(
//                     size: size,
//                     fontSize: size.width * numD05,
//                     color: colorTextFieldIcon,
//                     fontWeight: FontWeight.w500),
//               ),
//               SizedBox(
//                 height: size.width * numD01,
//               ),
//               Text(
//                 dummyTermText,
//                 style: commonTextStyle(
//                     size: size,
//                     fontSize: size.width * numD035,
//                     color: colorGreyNew,
//                     fontWeight: FontWeight.w400),
//               ),
//               SizedBox(
//                 height: size.width * numD06,
//               ),
//               Text(
//                 userConductDummyText,
//                 style: commonTextStyle(
//                     size: size,
//                     fontSize: size.width * numD05,
//                     color: colorTextFieldIcon,
//                     fontWeight: FontWeight.w500),
//               ),
//               SizedBox(
//                 height: size.width * numD01,
//               ),
//               Text(
//                 dummyPrivacyText,
//                 style: commonTextStyle(
//                     size: size,
//                     fontSize: size.width * numD035,
//                     color: colorGreyNew,
//                     fontWeight: FontWeight.w400),
//               )
//             ],
//           ),
//         )
//       ],
//     );
//   }

//   //copyRight
//   Widget copyRightWidget(Size size) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         SizedBox(
//           height: size.width * numD06,
//         ),
//         Text(
//           copyRightText,
//           style: commonTextStyle(
//               size: size,
//               fontSize: size.width * numD04,
//               color: Colors.black,
//               fontWeight: FontWeight.w400),
//         ),
//         SizedBox(
//           height: size.width * numD02,
//         ),
//         Container(
//           decoration: const BoxDecoration(color: colorLightGrey),
//           padding: EdgeInsets.all(size.width * numD04),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "What & Why",
//                 style: commonTextStyle(
//                     size: size,
//                     fontSize: size.width * numD05,
//                     color: colorTextFieldIcon,
//                     fontWeight: FontWeight.w500),
//               ),
//               SizedBox(
//                 height: size.width * numD01,
//               ),
//               Text(
//                 dummyTermText,
//                 style: commonTextStyle(
//                     size: size,
//                     fontSize: size.width * numD035,
//                     color: colorGreyNew,
//                     fontWeight: FontWeight.w400),
//               ),
//               SizedBox(
//                 height: size.width * numD06,
//               ),
//               Text(
//                 userConductDummyText,
//                 style: commonTextStyle(
//                     size: size,
//                     fontSize: size.width * numD05,
//                     color: colorTextFieldIcon,
//                     fontWeight: FontWeight.w500),
//               ),
//               SizedBox(
//                 height: size.width * numD01,
//               ),
//               Text(
//                 dummyPrivacyText,
//                 style: commonTextStyle(
//                     size: size,
//                     fontSize: size.width * numD035,
//                     color: colorGreyNew,
//                     fontWeight: FontWeight.w400),
//               )
//             ],
//           ),
//         )
//       ],
//     );
//   }

//   //Privacy
//   Widget privacyWidget(Size size) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         SizedBox(
//           height: size.width * numD06,
//         ),
//         Padding(
//           padding: EdgeInsets.only(
//               left: size.width * numD05,
//               bottom: size.width * numD05,
//               right: size.width * numD05),
//           child: Text(
//             privacyPolicyText,
//             style: TextStyle(
//                 color: Colors.black,
//                 fontWeight: FontWeight.bold,
//                 fontSize: size.width * numD05),
//           ),
//         ),
//         SizedBox(
//           height: size.width * numD02,
//         ),
//         ListView.separated(
//             padding: EdgeInsets.symmetric(horizontal: size.width * numD04),
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemBuilder: (context, index) {
//               return Html(
//                 data: htmlDataList[index],
//                 style: {
//                   "span": Style(
//                     color: colorTextFieldIcon,
//                     fontSize: FontSize(size.width * numD01),
//                   ),
//                   "h1": Style(
//                       color: colorGreyNew,
//                       fontSize: FontSize(size.width * numD02),
//                       padding: HtmlPaddings.symmetric(
//                           vertical: size.width * numD01)),
//                   "h2": Style(
//                       color: Colors.black,
//                       fontSize: FontSize(size.width * numD04),
//                       padding: HtmlPaddings.symmetric(
//                           vertical: size.width * numD01)),
//                   "h3": Style(
//                       color: Colors.black,
//                       fontSize: FontSize(size.width * numD035),
//                       padding: HtmlPaddings.symmetric(
//                           vertical: size.width * numD01)),
//                   "h4": Style(
//                       color: Colors.black,
//                       fontSize: FontSize(size.width * numD035),
//                       padding: HtmlPaddings.symmetric(
//                           vertical: size.width * numD01)),
//                   "td": Style(
//                       color: colorGreyNew,
//                       fontSize: FontSize(size.width * numD02),
//                       padding: HtmlPaddings.symmetric(
//                           vertical: size.width * numD01)),
//                   "th": Style(
//                       color: colorGreyNew,
//                       fontSize: FontSize(size.width * numD02),
//                       fontWeight: FontWeight.w600,
//                       padding: HtmlPaddings.zero),
//                   "div": Style(
//                     backgroundColor: colorLightGrey,
//                   )
//                 },
//               );
//             },
//             separatorBuilder: (context, index) {
//               return const SizedBox(
//                 height: 0,
//               );
//             },
//             itemCount: htmlDataList.length),
//       ],
//     );
//   }

//   //please confirm
//   Widget checkBoxWidget(Size size) {
//     return Container(
//       decoration: const BoxDecoration(color: colorLightGrey),
//       padding: EdgeInsets.all(size.width * numD04),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           InkWell(
//             onTap: () {
//               check1Value = !check1Value;
//               setState(() {});
//             },
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 check1Value
//                     ? Container(
//                         margin: EdgeInsets.only(top: size.width * numD008),
//                         child: Image.asset(
//                           "${iconsPath}ic_checkbox_filled.png",
//                           height: size.width * numD05,
//                         ),
//                       )
//                     : Container(
//                         margin: EdgeInsets.only(top: size.width * numD008),
//                         child: Image.asset("${iconsPath}ic_checkbox_empty.png",
//                             height: size.width * numD05),
//                       ),
//                 SizedBox(
//                   width: size.width * numD02,
//                 ),
//                 Expanded(
//                   child: RichText(
//                     textAlign: TextAlign.start,
//                     text: TextSpan(
//                       text: "I have read and agree to Press",
//                       style: TextStyle(
//                           fontSize: size.width * numD038,
//                           color: Colors.black,
//                           fontFamily: "AirbnbCereal",
//                           fontWeight: FontWeight.w400,
//                           height: 1.5),
//                       children: [
//                         TextSpan(
//                           text: "Hop's",
//                           style: TextStyle(
//                               fontSize: size.width * numD038,
//                               color: Colors.black,
//                               fontFamily: "AirbnbCereal",
//                               fontWeight: FontWeight.w400,
//                               height: 1.5),
//                         ),
//                         TextSpan(
//                           text:
//                               "  terms & conditions as set out in the user agreement.",
//                           style: TextStyle(
//                               fontSize: size.width * numD038,
//                               color: Colors.black,
//                               fontFamily: "AirbnbCereal",
//                               fontWeight: FontWeight.w400,
//                               height: 1.5),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(
//             height: size.width * numD03,
//           ),
//           InkWell(
//             onTap: () {
//               check2Value = !check2Value;
//               setState(() {});
//             },
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 check2Value
//                     ? Container(
//                         margin: EdgeInsets.only(top: size.width * numD008),
//                         child: Image.asset(
//                           "${iconsPath}ic_checkbox_filled.png",
//                           height: size.width * numD05,
//                         ),
//                       )
//                     : Container(
//                         margin: EdgeInsets.only(top: size.width * numD008),
//                         child: Image.asset("${iconsPath}ic_checkbox_empty.png",
//                             height: size.width * numD05),
//                       ),
//                 SizedBox(
//                   width: size.width * numD02,
//                 ),
//                 Expanded(
//                   child: RichText(
//                     textAlign: TextAlign.start,
//                     text: TextSpan(
//                       text: "I have read and agree to Press",
//                       style: TextStyle(
//                           fontSize: size.width * numD038,
//                           color: Colors.black,
//                           fontFamily: "AirbnbCereal",
//                           fontWeight: FontWeight.w400,
//                           height: 1.5),
//                       children: [
//                         TextSpan(
//                           text: "Hop's",
//                           style: TextStyle(
//                               fontSize: size.width * numD038,
//                               color: Colors.black,
//                               fontFamily: "AirbnbCereal",
//                               fontWeight: FontWeight.w400,
//                               height: 1.5),
//                         ),
//                         TextSpan(
//                           text: " privacy policy.",
//                           style: TextStyle(
//                               fontSize: size.width * numD038,
//                               color: Colors.black,
//                               fontFamily: "AirbnbCereal",
//                               fontWeight: FontWeight.w400,
//                               height: 1.5),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(
//             height: size.width * numD03,
//           ),
//           InkWell(
//             onTap: () {
//               check3Value = !check3Value;
//               setState(() {});
//             },
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 check3Value
//                     ? Container(
//                         margin: EdgeInsets.only(top: size.width * numD008),
//                         child: Image.asset(
//                           "${iconsPath}ic_checkbox_filled.png",
//                           height: size.width * numD05,
//                         ),
//                       )
//                     : Container(
//                         margin: EdgeInsets.only(top: size.width * numD008),
//                         child: Image.asset("${iconsPath}ic_checkbox_empty.png",
//                             height: size.width * numD05),
//                       ),
//                 SizedBox(
//                   width: size.width * numD02,
//                 ),
//                 Expanded(
//                   child: RichText(
//                     textAlign: TextAlign.start,
//                     text: TextSpan(
//                       text: "By uploading content on the Press",
//                       style: TextStyle(
//                           fontSize: size.width * numD038,
//                           color: Colors.black,
//                           fontFamily: "AirbnbCereal",
//                           fontWeight: FontWeight.w400,
//                           height: 1.5),
//                       children: [
//                         TextSpan(
//                           text: "Hop",
//                           style: TextStyle(
//                               fontSize: size.width * numD038,
//                               color: Colors.black,
//                               fontFamily: "AirbnbCereal",
//                               fontWeight: FontWeight.w400,
//                               height: 1.5),
//                         ),
//                         TextSpan(
//                           text:
//                               " app and platform, you are warranting that you own all proprietary rights, or are the authorised representative of the applicable copyright owner(s) of such content, including copyright.",
//                           style: TextStyle(
//                               fontSize: size.width * numD038,
//                               color: Colors.black,
//                               fontFamily: "AirbnbCereal",
//                               fontWeight: FontWeight.w400,
//                               height: 1.5),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(
//             height: size.width * numD03,
//           ),
//           InkWell(
//             onTap: () {
//               check4Value = !check4Value;
//               setState(() {});
//             },
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 check4Value
//                     ? Container(
//                         margin: EdgeInsets.only(top: size.width * numD008),
//                         child: Image.asset(
//                           "${iconsPath}ic_checkbox_filled.png",
//                           height: size.width * numD05,
//                         ),
//                       )
//                     : Container(
//                         margin: EdgeInsets.only(top: size.width * numD008),
//                         child: Image.asset("${iconsPath}ic_checkbox_empty.png",
//                             height: size.width * numD05),
//                       ),
//                 SizedBox(
//                   width: size.width * numD02,
//                 ),
//                 Expanded(
//                   child: RichText(
//                     textAlign: TextAlign.start,
//                     text: TextSpan(
//                       text: "By using the Press",
//                       style: TextStyle(
//                           fontSize: size.width * numD038,
//                           color: Colors.black,
//                           fontFamily: "AirbnbCereal",
//                           fontWeight: FontWeight.w400,
//                           height: 1.5),
//                       children: [
//                         TextSpan(
//                           text: "Hop",
//                           style: TextStyle(
//                               fontSize: size.width * numD038,
//                               color: Colors.black,
//                               fontFamily: "AirbnbCereal",
//                               fontWeight: FontWeight.w400,
//                               height: 1.5),
//                         ),
//                         TextSpan(
//                           text:
//                               " app and platform, you warrant that you are 18 years of age or older, and have the legal authority to enter into these Terms.",
//                           style: TextStyle(
//                               fontSize: size.width * numD038,
//                               color: Colors.black,
//                               fontFamily: "AirbnbCereal",
//                               fontWeight: FontWeight.w400,
//                               height: 1.5),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget buttonWidget(Size size) {
//     return Container(
//       padding: EdgeInsets.only(
//           top: size.width * numD05, bottom: size.width * numD05),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           Expanded(
//               child: SizedBox(
//             height: size.width * numD15,
//             child: commonElevatedButton(
//                 declineText.toTitleCase(),
//                 size,
//                 commonButtonTextStyle(size),
//                 commonButtonStyle(size, Colors.black), () {
//               declinedDialog("", size, () {});
//             }),
//           )),
//           SizedBox(
//             width: size.width * numD04,
//           ),
//           Expanded(
//               child: SizedBox(
//             height: size.width * numD15,
//             child: commonElevatedButton(
//                 acceptText,
//                 size,
//                 commonButtonTextStyle(size),
//                 commonButtonStyle(size, colorThemePink), () {
//               if (check1Value && check2Value && check3Value && check4Value) {
//                 Navigator.pop(context, true);
//               } else {
//                 showSnackBar(
//                     "Error",
//                     "Please select all the boxes to confirm your acceptance of our Terms & Conditions.",
//                     Colors.red);
//               }
//             }),
//           )),
//         ],
//       ),
//     );
//   }

//   void declinedDialog(String message, Size size, VoidCallback pressed) {
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               contentPadding: EdgeInsets.zero,
//               insetPadding:
//                   EdgeInsets.symmetric(horizontal: size.width * numD04),
//               content: StatefulBuilder(
//                 builder: (BuildContext context, StateSetter setState) {
//                   return Container(
//                     decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius:
//                             BorderRadius.circular(size.width * numD045)),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Padding(
//                           padding: EdgeInsets.only(left: size.width * numD04),
//                           child: Row(
//                             children: [
//                               Text(
//                                 "$tcText $declinedText?",
//                                 style: TextStyle(
//                                     color: Colors.black,
//                                     fontSize: size.width * numD05,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               const Spacer(),
//                               IconButton(
//                                   onPressed: () {
//                                     Navigator.pop(context);
//                                   },
//                                   icon: Icon(
//                                     Icons.close,
//                                     color: Colors.black,
//                                     size: size.width * numD06,
//                                   ))
//                             ],
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: size.width * numD04),
//                           child: const Divider(
//                             color: Colors.black,
//                             thickness: 0.5,
//                           ),
//                         ),
//                         SizedBox(
//                           height: size.width * numD02,
//                         ),
//                         Padding(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: size.width * numD04),
//                           child: Text(
//                             tcDeclinedNoteText,
//                             style: TextStyle(
//                                 color: Colors.black,
//                                 fontSize: size.width * numD04,
//                                 fontWeight: FontWeight.w400),
//                           ),
//                         ),
//                         SizedBox(
//                           height: size.width * numD02,
//                         ),
//                         Padding(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: size.width * numD04,
//                               vertical: size.width * numD04),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceAround,
//                             children: [
//                               Expanded(
//                                   child: SizedBox(
//                                 height: size.width * numD12,
//                                 child: commonElevatedButton(
//                                     declineText.toTitleCase(),
//                                     size,
//                                     commonButtonTextStyle(size),
//                                     commonButtonStyle(size, Colors.black), () {
//                                   Navigator.pop(context);
//                                   Navigator.pop(context, false);
//                                 }),
//                               )),
//                               SizedBox(
//                                 width: size.width * numD04,
//                               ),
//                               Expanded(
//                                   child: SizedBox(
//                                 height: size.width * numD12,
//                                 child: commonElevatedButton(
//                                     "$acceptText $tcText",
//                                     size,
//                                     commonButtonTextStyle(size),
//                                     commonButtonStyle(size, colorThemePink),
//                                     () {
//                                   Navigator.pop(context);
//                                   Navigator.pop(context, true);
//                                 }),
//                               )),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ));
//         });
//   }

//   callCMSAPi() {
//     final bool isEmployee =
//         ref.read(userRoleProvider).role == UserRole.employee;
//     Map<String, String> map = {
//       "type": widget.type,
//       if (isEmployee) 'role': 'enterprise',
//     };
//     debugPrint("type==> $map");
//     NetworkClass(getAllCmsUrl, this, getAllCmsUrlRequest)
//         .callRequestServiceHeader(true, "get", map);
//   }

//   callSignUpLegalApi() {
//     final bool isEmployee =
//         ref.read(userRoleProvider).role == UserRole.employee;
//     Map<String, String>? map =
//         isEmployee ? {'role': 'enterprise'} : null;
//     NetworkClass(signupLegalApi, this, signupLegalReq)
//         .callRequestServiceHeader(true, "get", map);
//   }

//   @override
//   void onError({required int requestCode, required String response}) {
//     try {
//       switch (requestCode) {
//         case getAllCmsUrlRequest:
//           var map = jsonDecode(response);
//           debugPrint("CheckUserNameResponseError:$map");

//           break;
//         case signupLegalReq:
//           var map = jsonDecode(response);
//           debugPrint("signupLegalReq:$map");

//           break;
//       }
//     } on Exception catch (e) {
//       debugPrint("$e");
//     }
//   }

//   @override
//   void onResponse({required int requestCode, required String response}) {
//     try {
//       switch (requestCode) {
//         case getAllCmsUrlRequest:
//           var map = jsonDecode(response);
//           debugPrint("CheckUserNameResponse:$map");
//           if (map["status"] != null) {
//             if (map["status"]["description"] != null) {
//               htmlDataList.add(map["status"]["description"]);
//               updatedDate = map["status"]["updatedAt"];
//               updatedDate = changeDateFormat(
//                   "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", updatedDate, "dd MMMM, yyyy");
//             }
//           }

//           setState(() {});
//           break;

//         case signupLegalReq:
//           var map = jsonDecode(response);
//           setState(() {
//             if (map["status"]["description"] != null) {
//               htmlDataList.add(map["status"]["description"]);
//               updatedDate = map["status"]["updatedAt"];
//               updatedDate = changeDateFormat(
//                   "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", updatedDate, "dd MMMM, yyyy");
//             }
//           });

//           break;
//       }
//     } on Exception catch (e) {
//       debugPrint("$e");
//     }
//   }
// }
