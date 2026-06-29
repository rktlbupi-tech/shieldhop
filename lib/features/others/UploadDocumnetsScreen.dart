// import 'dart:convert';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:presshop/main.dart';
// import 'package:presshop/utils/Common.dart';
// import 'package:presshop/utils/CommonSharedPrefrence.dart';
// import 'package:presshop/utils/CommonWigdets.dart';
// import 'package:presshop/utils/networkOperations/NetworkClass.dart';
// import 'package:presshop/utils/networkOperations/NetworkResponse.dart';
// import 'package:presshop/view/dashboard/Dashboard.dart';
// import 'package:presshop/view/menuScreen/FAQScreen.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../utils/AnalyticsHelper.dart';
// import '../../utils/CommonAppBar.dart';
// import '../menuScreen/MyProfile.dart';
// import 'WelcomeScreen.dart';

// class UploadDocumentsScreen extends StatefulWidget {
//   final bool menuScreen;
//   final bool hideLeading;

//   const UploadDocumentsScreen(
//       {super.key, required this.menuScreen, required this.hideLeading});

//   @override
//   State<StatefulWidget> createState() => UploadDocumentsScreenState();
// }

// class UploadDocumentsScreenState extends State<UploadDocumentsScreen>
//     with SingleTickerProviderStateMixin
//     implements NetworkResponse {
//   late AnimationController controller;
//   bool govIdUploaded = false,
//       photoLicenseUploaded = false,
//       incorporateLicenseUploaded = false,
//       isFirst = false,
//       isSecond = false,
//       isThird = false,
//       isFourth = false,
//       isFifth = false,
//       uploadComplete = false,
//       networkData = false;

//   File? file;
//   File? file1;
//   File? file2;
//   File? file3;

//   List<File> selectedImages = [];
//   List<DocumentInstructionModel> docInstructionList = [];
//   final picker = ImagePicker();

//   String selectedType = "",
//       doc1 = "",
//       doc2 = "",
//       doc3 = "",
//       doc1Name = "",
//       doc2Name = "",
//       doc3Name = "",
//       stripe1 = "",
//       stripe2 = "",
//       type = "";
//   List<DocumentDataModel> docList = [];

//   List<String> selectedDocument = [];
//   MyProfileData? myProfileData;
//   bool isLoading = false;

//   @override
//   void initState() {
//     debugPrint("class:::::::: $runtimeType");
//     debugPrint("menuScreen:::::::: ${widget.menuScreen}");
//     debugPrint("file1:::::::: $file1");
//     debugPrint("file2:::::::: $file2");
//     debugPrint("file3:::::::: $file3");

//     controller = AnimationController(
//         duration: const Duration(milliseconds: 700), vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//       callGetUploadDocAPI();
//       callGetCertificatesAPI();
//     });
//     super.initState();
//     /*sharedPreferences?.remove(file1Key);
//     sharedPreferences?.remove(file1NameKey);
//     sharedPreferences?.remove(file2Key);
//     sharedPreferences?.remove(file2NameKey);
//     sharedPreferences?.remove(file3Key);
//     sharedPreferences?.remove(file3NameKey);*/
//     //addFileData();
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     var size = MediaQuery.of(context).size;
//     final Animation<double> offsetAnimation = Tween(begin: 0.0, end: 24.0)
//         .chain(CurveTween(curve: Curves.elasticIn))
//         .animate(controller)
//       ..addStatusListener((status) {
//         if (status == AnimationStatus.completed) {
//           controller.reverse();
//         }
//       });
//     debugPrint("file1:::::::: $file1");
//     debugPrint("file2:::::::: $file2");
//     debugPrint("file3:::::::: $file3");
//     return Scaffold(
//         appBar: CommonAppBar(
//           elevation: 0,
//           hideLeading: widget.hideLeading,
//           title: Text(
//             "",
//             style: commonBigTitleTextStyle(size, Colors.black),
//           ),
//           centerTitle: false,
//           titleSpacing: 0,
//           size: size,
//           showActions: false,
//           leadingFxn: () {
//             Navigator.pop(context);
//           },
//           actionWidget: null,
//         ),
//         bottomNavigationBar: Padding(
//           padding: EdgeInsets.all(size.width * numD04),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               (docList.length >= 3)
//                   ? Expanded(
//                       child: SizedBox(
//                       height: size.width * numD13,
//                       child: commonElevatedButton(
//                           "Save",
//                           size,
//                           commonButtonTextStyle(size),
//                           commonButtonStyle(size, colorThemePink), () {
//                         callUploadDocApi();
//                       }),
//                     ))
//                   : Expanded(
//                       child: SizedBox(
//                       height: size.width * numD13,
//                       child: commonElevatedButton(
//                           uploadText,
//                           size,
//                           commonButtonTextStyle(size),
//                           commonButtonStyle(size, colorThemePink), () {
//                         if (docList.length == docInstructionList.length) {
//                           showSnackBar("Error",
//                               "You can upload all the document. ", Colors.red);
//                         } else {
//                           showUploadBottomSheet();
//                         }
//                       }),
//                     )),
//               SizedBox(width: size.width * numD04),
//               Expanded(
//                   child: SizedBox(
//                 height: size.width * numD13,
//                 child: commonElevatedButton(
//                     "Exit",
//                     size,
//                     commonButtonTextStyle(size),
//                     commonButtonStyle(size, Colors.black), () {
//                   Navigator.pop(context);
//                 }),
//               )),
//             ],
//           ),
//         ),
//         body: isLoading
//             ? SafeArea(
//                 child: ListView(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: size.width * numD04,
//                   ),
//                   children: [
//                     Text(
//                       uploadDocsHeadingText,
//                       style: TextStyle(
//                           color: Colors.black,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: "AirbnbCereal",
//                           fontSize: size.width * numD07),
//                     ),
//                     SizedBox(
//                       height: size.width * numD02,
//                     ),
//                     RichText(
//                       text: TextSpan(children: [
//                         TextSpan(
//                             text: "$uploadDocsSubHeading1Text ",
//                             style: TextStyle(
//                                 color: Colors.black,
//                                 fontFamily: "AirbnbCereal",
//                                 fontSize: size.width * numD035)),
//                         WidgetSpan(
//                             alignment: PlaceholderAlignment.middle,
//                             child: Image.asset("${iconsPath}ic_pro.png",
//                                 height: size.width * numD06)),
//                         TextSpan(
//                             text: " $uploadDocsSubHeading2Text",
//                             style: TextStyle(
//                                 color: Colors.black,
//                                 fontFamily: "AirbnbCereal",
//                                 fontSize: size.width * numD035)),
//                       ]),
//                     ),
//                     SizedBox(
//                       height: size.width * numD02,
//                     ),
// /*
//                   RichText(
//                     text: TextSpan(children: [
//                       TextSpan(
//                           text:
//                               "If you are an amateur, simply press next to enter your banking details.",
//                           style: TextStyle(
//                               color: Colors.black,
//                               fontSize: size.width * numD035)),
//                     ]),
//                   ),
//                   SizedBox(
//                     height: size.width * numD02,
//                   ),*/

//                     RichText(
//                       text: TextSpan(children: [
//                         TextSpan(
//                             text: "$uploadDocsSubHeading3Text ",
//                             style: TextStyle(
//                                 color: Colors.black,
//                                 fontFamily: "AirbnbCereal",
//                                 fontSize: size.width * numD035)),
//                         WidgetSpan(
//                             alignment: PlaceholderAlignment.middle,
//                             child: Image.asset("${iconsPath}ic_pro.png",
//                                 height: size.width * numD06)),
//                         TextSpan(
//                             text: " $uploadDocsSubHeading4Text",
//                             style: TextStyle(
//                                 color: Colors.black,
//                                 fontFamily: "AirbnbCereal",
//                                 fontSize: size.width * numD035)),
//                         WidgetSpan(
//                             alignment: PlaceholderAlignment.middle,
//                             child: SizedBox(
//                               width: size.width * numD01,
//                             )),
//                         WidgetSpan(
//                             alignment: PlaceholderAlignment.middle,
//                             child: InkWell(
//                               onTap: () {
//                                 Navigator.of(context).push(MaterialPageRoute(
//                                     builder: (context) => FAQScreen(
//                                           priceTipsSelected: false,
//                                           type: 'faq',
//                                           benefits: "benefits",
//                                           index: 5,
//                                         )));
//                               },
//                               child: Text(benefitText,
//                                   style: TextStyle(
//                                       color: Colors.red,
//                                       fontWeight: FontWeight.bold,
//                                       fontFamily: "AirbnbCereal",
//                                       fontSize: size.width * numD035)),
//                             )),
//                       ]),
//                     ),
//                     SizedBox(
//                       height: size.width * numD08,
//                     ),
//                     !widget.menuScreen
//                         ? Text(uploadDocsSubHeading5Text,
//                             style: TextStyle(
//                                 color: Colors.black,
//                                 fontFamily: "AirbnbCereal",
//                                 fontSize: size.width * numD035))
//                         : Container(),
//                     SizedBox(
//                       height: !widget.menuScreen ? size.width * numD08 : 0,
//                     ),
//                     Text("Upload your documents for verification (any 2)",
//                         style: TextStyle(
//                             fontSize: size.width * numD038,
//                             color: Colors.black,
//                             fontFamily: "AirbnbCereal",
//                             fontWeight: FontWeight.w400)),
//                     SizedBox(
//                       height: size.width * numD025,
//                     ),
//                     Container(
//                       padding: EdgeInsets.all(size.width * numD04),
//                       decoration: BoxDecoration(
//                           color: colorLightGrey,
//                           border: Border.all(color: Colors.black),
//                           borderRadius:
//                               BorderRadius.circular(size.width * numD03)),
//                       child: ListView.separated(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount: docInstructionList.length,
//                         itemBuilder: (context, index) {
//                           return Row(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   margin: EdgeInsets.only(
//                                     top: size.width * numD009,
//                                   ),
//                                   child: Icon(
//                                     Icons.circle,
//                                     color: colorThemePink,
//                                     size: size.width * numD035,
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   width: size.width * numD02,
//                                 ),
//                                 Expanded(
//                                   child: Text(
//                                       docInstructionList[index].documentName,
//                                       style: TextStyle(
//                                           fontSize: size.width * numD036,
//                                           color: Colors.black,
//                                           fontFamily: "AirbnbCereal",
//                                           fontWeight: FontWeight.w400)),
//                                 ),
//                               ]);
//                         },
//                         separatorBuilder: (BuildContext context, int index) {
//                           return SizedBox(
//                             height: size.width * numD025,
//                           );
//                         },
//                       ),
//                     ),
//                     SizedBox(
//                       height: size.width * numD04,
//                     ),
//                     GridView.builder(
//                       physics: const NeverScrollableScrollPhysics(),
//                       shrinkWrap: true,
//                       gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         childAspectRatio: 1,
//                         crossAxisSpacing: 12,
//                         mainAxisSpacing: 12,
//                       ),
//                       itemCount: docList.length,
//                       itemBuilder: (context, index) {
//                         return Container(
//                           padding: EdgeInsets.all(size.width * numD025),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.black),
//                             borderRadius:
//                                 BorderRadius.circular(size.width * numD04),
//                           ),
//                           child: Column(
//                             children: [
//                               Stack(
//                                 alignment: Alignment.topRight,
//                                 children: [
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(
//                                         size.width * numD03),
//                                     child: docList[index]
//                                             .documentName
//                                             .endsWith(".pdf")
//                                         ? Image.asset(
//                                             "${iconsPath}pdfIcon.png",
//                                             height: size.width * numD28,
//                                             width: size.width * numD38,
//                                           )
//                                         : docList[index].id.isNotEmpty
//                                             ? Image.network(
//                                                 docImageUrl +
//                                                     docList[index].documentName,
//                                                 height: size.width * numD28,
//                                                 width: size.width * numD38,
//                                                 fit: BoxFit.cover,
//                                               )
//                                             : Image.file(
//                                                 File(
//                                                   docList[index].documentName,
//                                                 ),
//                                                 height: size.width * numD28,
//                                                 width: size.width * numD38,
//                                                 fit: BoxFit.cover,
//                                               ),
//                                   ),
//                                   InkWell(
//                                     onTap: () {
//                                       docInstructionList[index].isSelected =
//                                           false;
//                                       deleteDocDialog(docList[index].id, index);
//                                       setState(() {});
//                                     },
//                                     child: Align(
//                                       alignment: Alignment.topRight,
//                                       child: Padding(
//                                         padding: EdgeInsets.all(
//                                             size.width * numD018),
//                                         child: Image.asset(
//                                             "${iconsPath}ic_deleteIcon.png",
//                                             height: size.width * numD05),
//                                       ),
//                                     ),
//                                   )
//                                 ],
//                               ),
//                               SizedBox(
//                                 height: size.width * numD02,
//                               ),
//                               Text(
//                                 docList[index].id.isEmpty
//                                     ? docList[index]
//                                         .documentName
//                                         .split("/")
//                                         .last
//                                     : docList[index].documentName,
//                                 textAlign: TextAlign.center,
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: commonTextStyle(
//                                     size: size,
//                                     fontSize: size.width * numD03,
//                                     color: Colors.black,
//                                     fontWeight: FontWeight.w400),
//                               ),
//                               SizedBox(
//                                 height:
//                                     Platform.isIOS ? size.width * numD02 : 0,
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                     SizedBox(
//                       height: file1 != null ? 0.0 : size.width * numD06,
//                     ),
//                   ],
//                 ),
//               )
//             : showLoader());
//   }

//   void addFileData() {
//     int count = 0;
//     if (sharedPreferences!.getString(file1Key) != null) {
//       doc1 = sharedPreferences!.getString(file1Key)!;
//       if (sharedPreferences!.getString(file1NameKey) != null) {
//         debugPrint(
//             "docName:::::: ${sharedPreferences!.getString(file1NameKey)}");
//         doc1Name = sharedPreferences!.getString(file1NameKey)!;
//       }
//       govIdUploaded = true;
//       count = count + 1;
//       networkData = true;
//       setState(() {});
//     }
//     if (sharedPreferences!.getString(file2Key) != null) {
//       doc2 = sharedPreferences!.getString(file2Key)!;
//       if (sharedPreferences!.getString(file2NameKey) != null) {
//         doc2Name = sharedPreferences!.getString(file2NameKey).toString();
//       }
//       photoLicenseUploaded = true;
//       count = count + 1;
//       networkData = true;
//       setState(() {});
//     }

//     if (sharedPreferences!.getString(file3Key) != null) {
//       doc3 = sharedPreferences!.getString(file3Key)!;
//       if (sharedPreferences!.getString(file2NameKey) != null) {
//         doc3Name = sharedPreferences!.getString(file3NameKey)!;
//       }
//       incorporateLicenseUploaded = true;
//       count = count + 1;
//       networkData = true;
//       setState(() {});
//     }

//     if (count > 1) {
//       uploadComplete = true;
//     }

//     setState(() {});
//   }

//   void showUploadBottomSheet() {
//     var size = MediaQuery.of(context).size;
//     showModalBottomSheet(
//       isScrollControlled: true,
//       useSafeArea: true,
//       isDismissible: false,
//       enableDrag: false,
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(size.width * numD07),
//           topRight: Radius.circular(size.width * numD07),
//         ),
//       ),
//       builder: (BuildContext context) {
//         return StatefulBuilder(builder: (context, StateSetter stateSetter) {
//           return Container(
//             width: double.infinity,
//             padding: EdgeInsets.only(
//                 top: docList.length >= 3 ? size.width * numD04 : 0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(size.width * numD07),
//                 topRight: Radius.circular(size.width * numD07),
//               ), // Optional: for rounded border
//             ),
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: size.width * numD045,
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: <Widget>[
//                     SizedBox(height: size.width * numD035),
//                     Row(
//                       children: [
//                         ...[
//                           Text(
//                             "Upload docs for verification",
//                             style: commonTextStyle(
//                                 size: size,
//                                 fontSize: size.width * numD045,
//                                 color: Colors.black,
//                                 fontWeight: FontWeight.w700),
//                           ),
//                         ],
//                         const Spacer(),
//                         IconButton(
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//                           icon: const Icon(Icons.close),
//                         ),
//                       ],
//                     ),
//                     const Divider(
//                       color: Colors.black,
//                       thickness: 1.3,
//                     ),
//                     SizedBox(height: size.width * numD035),
//                     Text(
//                       "Kindly upload clear copies of your original documents to complete bank verification.",
//                       style: TextStyle(
//                           color: Colors.black,
//                           fontFamily: "AirbnbCereal",
//                           fontSize: size.width * numD035),
//                     ),
//                     SizedBox(height: size.width * numD05),
//                     ListView.separated(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: docInstructionList.length,
//                       itemBuilder: (context, index) {
//                         return Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               docInstructionList[index].isSelected
//                                   ? Container(
//                                       margin: EdgeInsets.only(
//                                           top: size.width * numD008),
//                                       child: Image.asset(
//                                           "${iconsPath}ic_checkbox_filled.png",
//                                           height: size.width * numD05),
//                                     )
//                                   : Container(
//                                       margin: EdgeInsets.only(
//                                           top: size.width * numD005),
//                                       child: Icon(
//                                         Icons.circle,
//                                         color: colorThemePink,
//                                         size: size.width * numD035,
//                                       ),
//                                     ),
//                               SizedBox(
//                                 width: docInstructionList[index].isSelected
//                                     ? size.width * numD028
//                                     : size.width * numD04,
//                               ),
//                               Expanded(
//                                 child: Text(
//                                     docInstructionList[index].documentName,
//                                     style: TextStyle(
//                                         fontSize: size.width * numD035,
//                                         color: Colors.black,
//                                         fontFamily: "AirbnbCereal",
//                                         fontWeight: FontWeight.w400)),
//                               ),
//                             ]);
//                       },
//                       separatorBuilder: (BuildContext context, int index) {
//                         return SizedBox(
//                           height: size.width * numD025,
//                         );
//                       },
//                     ),
//                     SizedBox(height: size.width * numD05),
//                     InkWell(
//                       onTap: () {
//                         if (docList.length == docInstructionList.length) {
//                           showSnackBar("Error",
//                               "You can upload all the document. ", Colors.red);
//                         } else {
//                           showDocListBottomSheet(stateSetter);
//                         }
//                       },
//                       child: Container(
//                         padding: EdgeInsets.all(size.width * numD035),
//                         decoration: BoxDecoration(
//                             border: Border.all(color: colorTextFieldBorder),
//                             borderRadius:
//                                 BorderRadius.circular(size.width * numD03)),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               "Select Document",
//                               style: TextStyle(
//                                   color: Colors.black,
//                                   fontFamily: "AirbnbCereal",
//                                   fontSize: size.width * numD035),
//                             ),
//                             const Icon(
//                               Icons.keyboard_arrow_down_sharp,
//                               color: Colors.black,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: size.width * numD05),
//                     GridView.builder(
//                       physics: const NeverScrollableScrollPhysics(),
//                       shrinkWrap: true,
//                       gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         childAspectRatio: 1,
//                         crossAxisSpacing: 12,
//                         mainAxisSpacing: 12,
//                       ),
//                       itemCount: docList.length,
//                       itemBuilder: (context, index) {
//                         return Container(
//                           padding: EdgeInsets.all(size.width * numD025),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.black),
//                             borderRadius:
//                                 BorderRadius.circular(size.width * numD04),
//                           ),
//                           child: Column(
//                             children: [
//                               Stack(
//                                 alignment: Alignment.topRight,
//                                 children: [
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(
//                                         size.width * numD03),
//                                     child: docList[index]
//                                             .documentName
//                                             .endsWith(".pdf")
//                                         ? Image.asset(
//                                             "${iconsPath}pdfIcon.png",
//                                             height: size.width * numD28,
//                                             width: size.width * numD38,
//                                           )
//                                         : docList[index].id.isNotEmpty
//                                             ? Image.network(
//                                                 docImageUrl +
//                                                     docList[index].documentName,
//                                                 height: size.width * numD28,
//                                                 width: size.width * numD38,
//                                                 fit: BoxFit.cover,
//                                               )
//                                             : Image.file(
//                                                 File(docList[index]
//                                                     .documentName),
//                                                 height: size.width * numD28,
//                                                 width: size.width * numD38,
//                                                 fit: BoxFit.cover,
//                                               ),
//                                   ),
//                                   InkWell(
//                                     onTap: () {
//                                       docInstructionList[index].isSelected =
//                                           false;
//                                       docList.removeAt(index);
//                                       setState(() {});
//                                       stateSetter(() {});
//                                     },
//                                     child: Align(
//                                       alignment: Alignment.topRight,
//                                       child: Padding(
//                                         padding: EdgeInsets.all(
//                                             size.width * numD018),
//                                         child: Image.asset(
//                                             "${iconsPath}ic_deleteIcon.png",
//                                             height: size.width * numD05),
//                                       ),
//                                     ),
//                                   )
//                                 ],
//                               ),
//                               SizedBox(
//                                 height: size.width * numD02,
//                               ),
//                               Text(
//                                 docList[index].id.isEmpty
//                                     ? docList[index]
//                                         .documentName
//                                         .split("/")
//                                         .last
//                                     : docList[index].documentName,
//                                 textAlign: TextAlign.center,
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: commonTextStyle(
//                                     size: size,
//                                     fontSize: size.width * numD03,
//                                     color: Colors.black,
//                                     fontWeight: FontWeight.w400),
//                               ),
//                               SizedBox(
//                                 height:
//                                     Platform.isIOS ? size.width * numD02 : 0,
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                     SizedBox(height: size.width * numD05),
//                     SizedBox(
//                       width: size.width,
//                       height: size.width * numD13,
//                       child: commonElevatedButton(
//                           submitText,
//                           size,
//                           commonTextStyle(
//                               size: size,
//                               fontSize: size.width * numD035,
//                               color: Colors.white,
//                               fontWeight: FontWeight.w700),
//                           commonButtonStyle(size, colorThemePink), () {
//                         if (docList.length < 2) {
//                           showSnackBar(
//                               "Error",
//                               "Please upload your documents to proceed",
//                               Colors.red);
//                         } else {
//                           Navigator.pop(context);
//                           callUploadDocApi();
//                         }
//                       }),
//                     ),
//                     SizedBox(height: size.width * numD08),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         });
//       },
//     );
//   }

//   void getFromGallery(
//       bool isFile1, StateSetter mainStateSetter, int idx) async {
//     XFile? pickedFile = await ImagePicker().pickImage(
//       source: ImageSource.gallery,
//     );
//     if (pickedFile != null) {
//       var pickFile = File(pickedFile.path);
//       file = File(pickFile.path);
//       docList.add(DocumentDataModel(
//           id: "", documentName: pickFile.path, isSelected: false));
//       docInstructionList[idx].isSelected = true;
//       setState(() {});
//       mainStateSetter(() {});
//     }
//   }

//   void pickFile(String fileName, StateSetter mainStateSetter, int idx) async {
//     debugPrint("inside in this if ::::::");
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//         allowMultiple: false);
//     if (result != null) {
//       debugPrint("docFile=====> $fileName");
//       file = File(result.files.single.path.toString());
//       docList.add(DocumentDataModel(
//           id: "",
//           documentName: result.files.single.path.toString(),
//           isSelected: false));

//       docInstructionList[idx].isSelected = true;
//       setState(() {});
//       mainStateSetter(() {});
//     }
//   }

//   void showUploadImageOptionBottomSheet(
//       bool selectFirst, StateSetter mainStateSetter, int index) {
//     var size = MediaQuery.of(context).size;
//     showModalBottomSheet(
//         context: context,
//         backgroundColor: Colors.transparent,
//         isScrollControlled: true,
//         builder: (context) {
//           return Container(
//             decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(size.width * numD04),
//                     topRight: Radius.circular(size.width * numD04))),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   margin: EdgeInsets.only(
//                       left: size.width * numD06,
//                       right: size.width * numD03,
//                       top: size.width * numD018),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Select Option",
//                         style: TextStyle(
//                             color: Colors.black,
//                             fontSize: size.width * numD048,
//                             fontFamily: "AirbnbCereal",
//                             fontWeight: FontWeight.w500),
//                         textAlign: TextAlign.center,
//                       ),
//                       IconButton(
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//                           icon: Icon(Icons.close_rounded,
//                               color: Colors.black, size: size.width * numD08)),
//                     ],
//                   ),
//                 ),
//                 SizedBox(
//                   height: size.width * numD04,
//                 ),
//                 Container(
//                   margin: EdgeInsets.only(
//                       left: size.width * numD06, right: size.width * numD06),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: InkWell(
//                           onTap: () {
//                             Navigator.pop(context);
//                             getFromGallery(selectFirst, mainStateSetter, index);
//                             // getImages();
//                           },
//                           child: Container(
//                               alignment: Alignment.center,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 border: Border.all(color: Colors.black),
//                                 borderRadius:
//                                     BorderRadius.circular(size.width * numD02),
//                               ),
//                               height: size.width * numD25,
//                               padding: EdgeInsets.all(size.width * numD02),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.upload, size: size.width * numD08),
//                                   SizedBox(
//                                     height: size.width * numD03,
//                                   ),
//                                   Text(
//                                     "My Gallery",
//                                     style: TextStyle(
//                                         color: Colors.black,
//                                         fontSize: size.width * numD035,
//                                         fontFamily: "AirbnbCereal",
//                                         fontWeight: FontWeight.bold),
//                                   )
//                                 ],
//                               )),
//                         ),
//                       ),
//                       SizedBox(
//                         width: size.width * 0.05,
//                       ),
//                       Expanded(
//                         child: InkWell(
//                           onTap: () {
//                             Navigator.pop(context);
//                             pickFile("", mainStateSetter, index);
//                           },
//                           child: Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 border: Border.all(color: Colors.black),
//                                 borderRadius:
//                                     BorderRadius.circular(size.width * numD02),
//                               ),
//                               height: size.width * numD25,
//                               padding: EdgeInsets.all(size.width * numD04),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.file_copy_outlined,
//                                     size: size.width * numD08,
//                                   ),
//                                   SizedBox(
//                                     height: size.width * numD03,
//                                   ),
//                                   Text(
//                                     "My Files",
//                                     style: TextStyle(
//                                         color: Colors.black,
//                                         fontSize: size.width * numD035,
//                                         fontFamily: "AirbnbCereal",
//                                         fontWeight: FontWeight.bold),
//                                   )
//                                 ],
//                               )),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(
//                   height: size.width * numD06,
//                 ),
//               ],
//             ),
//           );
//         });
//   }

//   void showDocListBottomSheet(StateSetter mainStateSetter) {
//     var size = MediaQuery.of(context).size;
//     showModalBottomSheet(
//       isScrollControlled: true,
//       useSafeArea: true,
//       isDismissible: false,
//       enableDrag: false,
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(size.width * numD07),
//           topRight: Radius.circular(size.width * numD07),
//         ),
//       ),
//       builder: (BuildContext context) {
//         return StatefulBuilder(builder: (context, StateSetter stateSetter) {
//           return Container(
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(size.width * numD07),
//                 topRight: Radius.circular(size.width * numD07),
//               ), // Optional: for rounded border
//             ),
//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: size.width * numD045,
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: <Widget>[
//                   SizedBox(height: size.width * numD035),
//                   Row(
//                     children: [
//                       ...[
//                         Text(
//                           "Select Document",
//                           style: commonTextStyle(
//                               size: size,
//                               fontSize: size.width * numD045,
//                               color: Colors.black,
//                               fontWeight: FontWeight.w700),
//                         ),
//                       ],
//                       const Spacer(),
//                       IconButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         icon: const Icon(Icons.close),
//                       ),
//                     ],
//                   ),
//                   const Divider(
//                     color: Colors.black,
//                     thickness: 1.3,
//                   ),
//                   SizedBox(height: size.width * numD03),
//                   ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: docInstructionList.length,
//                     itemBuilder: (context, index) {
//                       return InkWell(
//                         onTap: () {
//                           Navigator.pop(context);
//                           if (docInstructionList[index].isSelected) {
//                             showSnackBar(
//                                 "Error",
//                                 "You have already uploaded ${docInstructionList[index].documentName}.",
//                                 Colors.red);
//                           } else {
//                             showUploadImageOptionBottomSheet(
//                                 true, mainStateSetter, index);
//                           }
//                         },
//                         child: Text(
//                           docInstructionList[index].documentName,
//                           style: commonTextStyle(
//                               size: size,
//                               fontSize: size.width * numD036,
//                               color: Colors.black,
//                               fontWeight: FontWeight.w400),
//                         ),
//                       );
//                     },
//                     separatorBuilder: (BuildContext context, int index) {
//                       return SizedBox(
//                         height: size.width * numD04,
//                       );
//                     },
//                   ),
//                   SizedBox(height: size.width * numD05),
//                 ],
//               ),
//             ),
//           );
//         });
//       },
//     );
//   }

//   void startVibration() async {
//     final Iterable<Duration> pauses = [
//       const Duration(milliseconds: 50),
//     ];
//   }

//   openUrl(String url) async {
//     if (await canLaunchUrl(Uri.parse(url))) {
//       debugPrint('launching com googleUrl');
//       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//     } else {
//       throw 'Could not launch url';
//     }
//   }

//   void uploadStripeImage(String path) {
//     debugPrint("image path doc $path");

//     var imageMap = {"image": path};

//     NetworkClass.multipartSingleImageNetworkClass(
//             uploadStripeFiles, this, reqUploadStripeFiles, {}, path, "image")
//         .callMultipartServiceNew(true, "post", imageMap);
//   }

//   void showUploadImageBottomSheet() {
//     var size = MediaQuery.of(context).size;
//     showModalBottomSheet(
//         context: context,
//         backgroundColor: Colors.transparent,
//         isScrollControlled: true,
//         builder: (context) {
//           return SingleChildScrollView(
//             child: Container(
//               decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(size.width * numD04),
//                       topRight: Radius.circular(size.width * numD04))),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     margin: EdgeInsets.only(
//                         left: size.width * numD06,
//                         right: size.width * numD03,
//                         top: size.width * numD018),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           "Select Option",
//                           style: TextStyle(
//                               color: Colors.black,
//                               fontSize: size.width * numD048,
//                               fontFamily: "AirbnbCereal",
//                               fontWeight: FontWeight.w500),
//                           textAlign: TextAlign.center,
//                         ),
//                         IconButton(
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                             icon: Icon(Icons.close_rounded,
//                                 color: Colors.black,
//                                 size: size.width * numD08)),
//                       ],
//                     ),
//                   ),
//                   SizedBox(
//                     height: size.width * numD04,
//                   ),
//                   Container(
//                     margin: EdgeInsets.only(
//                         left: size.width * numD06, right: size.width * numD06),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: InkWell(
//                             onTap: () {
//                               Navigator.pop(context);
//                               //  getFromGallery(selectFirst, mainStateSetter,index);
//                               // getImages();
//                             },
//                             child: Container(
//                                 alignment: Alignment.center,
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   border: Border.all(color: Colors.black),
//                                   borderRadius: BorderRadius.circular(
//                                       size.width * numD02),
//                                 ),
//                                 height: size.width * numD25,
//                                 padding: EdgeInsets.all(size.width * numD02),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(Icons.upload,
//                                         size: size.width * numD08),
//                                     SizedBox(
//                                       height: size.width * numD03,
//                                     ),
//                                     Text(
//                                       "My Gallery",
//                                       style: TextStyle(
//                                           color: Colors.black,
//                                           fontSize: size.width * numD035,
//                                           fontFamily: "AirbnbCereal",
//                                           fontWeight: FontWeight.bold),
//                                     )
//                                   ],
//                                 )),
//                           ),
//                         ),
//                         SizedBox(
//                           width: size.width * 0.05,
//                         ),
//                         Expanded(
//                           child: InkWell(
//                             onTap: () {
//                               Navigator.pop(context);
//                               // pickFile("");
//                             },
//                             child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   border: Border.all(color: Colors.black),
//                                   borderRadius: BorderRadius.circular(
//                                       size.width * numD02),
//                                 ),
//                                 height: size.width * numD25,
//                                 padding: EdgeInsets.all(size.width * numD04),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.file_copy_outlined,
//                                       size: size.width * numD08,
//                                     ),
//                                     SizedBox(
//                                       height: size.width * numD03,
//                                     ),
//                                     Text(
//                                       "My Files",
//                                       style: TextStyle(
//                                           color: Colors.black,
//                                           fontSize: size.width * numD035,
//                                           fontFamily: "AirbnbCereal",
//                                           fontWeight: FontWeight.bold),
//                                     )
//                                   ],
//                                 )),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(
//                     height: size.width * numD06,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         });
//   }

//   void createStripeAccounts() {
//     try {
//       Map<String, String> params = {
//         "front": stripe1,
//         "back": stripe2,
//         "email": sharedPreferences!.getString(emailKey).toString(),
//         "first_name": sharedPreferences!.getString(firstNameKey).toString(),
//         "last_name": sharedPreferences!.getString(lastNameKey).toString(),
//         "country": sharedPreferences!.getString(countryKey).toString(),
//         "phone": sharedPreferences!.getString(phoneKey).toString(),
//         "post_code": sharedPreferences!.getString(postCodeKey).toString(),
//         "city": sharedPreferences!.getString(cityKey).toString(),
//         "dob": sharedPreferences!.getString(dobKey).toString(),
//         "account_holder_name": "John Doe",
//         "sort_code": "108800",
//         "account_number": "00012345",
//         "bank_name": "ICICI"
//       };
//       debugPrint("stripe:::::$params");
//       NetworkClass.fromNetworkClass(
//               createStripeAccount, this, reqCreateStipeAccount, params)
//           .callRequestServiceHeader(true, "post", null);
//     } on Exception catch (e) {
//       debugPrint("$e");
//     }
//   }

//   void deleteDocDialog(String id, int index) {
//     showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             contentPadding: EdgeInsets.zero,
//             insetPadding: EdgeInsets.symmetric(
//                 horizontal: MediaQuery.of(context).size.width * numD02),
//             content: StatefulBuilder(
//                 builder: (BuildContext context, StateSetter stateSetter) {
//               return Container(
//                 width: MediaQuery.of(context).size.width * num1,
//                 //   height: MediaQuery.of(context).size.width * numD45,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(
//                       MediaQuery.of(context).size.width * numD025),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Padding(
//                         padding: EdgeInsets.only(
//                             top: MediaQuery.of(context).size.width * 0.05)),
//                     Image.asset(
//                       "${iconsPath}delete.png",
//                       width: MediaQuery.of(context).size.width * numD11,
//                       height: MediaQuery.of(context).size.width * numD11,
//                       fit: BoxFit.contain,
//                       color: colorThemePink,
//                     ),
//                     Padding(
//                         padding: EdgeInsets.only(
//                             top: MediaQuery.of(context).size.width * 0.02)),
//                     Text(
//                       "Are you sure you want to delete this document?",
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontSize: MediaQuery.of(context).size.width * numD04,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         InkWell(
//                           onTap: () {
//                             Navigator.pop(context);
//                           },
//                           child: Container(
//                             width: MediaQuery.of(context).size.width * numD45,
//                             margin: EdgeInsets.only(
//                                 top: MediaQuery.of(context).size.width * 0.05),
//                             decoration: BoxDecoration(
//                               color: Colors.black,
//                               borderRadius: BorderRadius.circular(
//                                   MediaQuery.of(context).size.width * 0.02),
//                             ),
//                             child: Padding(
//                               padding: EdgeInsets.symmetric(
//                                   vertical:
//                                       MediaQuery.of(context).size.width * 0.03),
//                               child: const Text(
//                                 "Cancel",
//                                 style: TextStyle(
//                                     fontSize: 15,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w700),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(
//                           width: MediaQuery.of(context).size.width * 0.02,
//                         ),
//                         InkWell(
//                           onTap: () {
//                             if (docList[index].id.isEmpty) {
//                               docList.removeAt(index);
//                               docInstructionList[index].isSelected = false;
//                               Navigator.pop(context);
//                             } else {
//                               docList.removeAt(index);
//                               docInstructionList[index].isSelected = false;
//                               callDeleteDocumentAPI(id);
//                               Navigator.pop(context);
//                             }
//                             setState(() {});
//                           },
//                           child: Container(
//                             width: MediaQuery.of(context).size.width * numD45,
//                             margin: EdgeInsets.only(
//                                 top: MediaQuery.of(context).size.width * 0.05),
//                             decoration: BoxDecoration(
//                                 color: colorThemePink,
//                                 borderRadius: BorderRadius.circular(
//                                     MediaQuery.of(context).size.width * 0.02)),
//                             child: Padding(
//                               padding: EdgeInsets.symmetric(
//                                   vertical: MediaQuery.of(context).size.width *
//                                       0.031),
//                               child: Text(
//                                 "Delete",
//                                 style: TextStyle(
//                                     fontSize:
//                                         MediaQuery.of(context).size.width *
//                                             numD037,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           ),
//                         )
//                       ],
//                     ),
//                     SizedBox(
//                       height: MediaQuery.of(context).size.width * numD04,
//                     )
//                   ],
//                 ),
//               );
//             }),
//           );
//         });
//   }

//   void callGetCertificatesAPI() {
//     Map<String, String> map = {
//       'type': 'doc',
//     };
//     NetworkClass(getAllCmsUrl, this, getAllCmsUrlRequest)
//         .callRequestServiceHeader(false, "get", map);
//   }

//   void callUploadDocApi() {
//     AnalyticsHelper.trackEvent('kyc_upload_started', parameters: {
//       'document_count': docList.length,
//     });
//     List<File> filesPath = [];
//     List<String> selectMediaList = [];
//     for (int i = 0; i < docList.length; i++) {
//       var element = docList[i];
//       debugPrint("element:::::::${element.id}");
//       if (docList[i].id.isEmpty) {
//         selectMediaList.add(element.documentName.toString());
//       }
//     }

//     filesPath.addAll(selectMediaList.map((path) => File(path)).toList());

//     NetworkClass.multipartNetworkClassFiles(
//             uploadDocUrl, this, uploadDocReq, {}, filesPath)
//         .callMultipartServiceSameParamMultiImage(true, "patch", "doc_name");
//   }

//   void callGetUploadDocAPI() {
//     NetworkClass(getUploadDocUrl, this, getUploadDocReq)
//         .callRequestServiceHeader(false, "get", null);
//   }

//   void callDeleteDocumentAPI(String id) {
//     Map<String, String> map = {"document_id": id};
//     NetworkClass.fromNetworkClass(deleteDocUrl, this, deleteDocReq, map)
//         .callRequestServiceHeader(false, "post", null);
//   }

//   @override
//   void onError({required int requestCode, required String response}) {
//     try {
//       switch (requestCode) {
//         case uploadCertificateUrlRequest:
//           debugPrint(
//               'uploadCertificateUrlRequest_errorResponse ===> ${jsonDecode(response)}');
//           showSnackBar("Error", uploadDocErrorMessage, Colors.red);
//           break;
//         case getAllCmsUrlRequest:
//           debugPrint(
//               'getAllCmsUrlRequest_errorResponse ===> ${jsonDecode(response)}');
//           break;

//         case reqDeleteCertificateAPI:
//           debugPrint(
//               'reqDeleteCertificateAPI_errorResponse ===> ${jsonDecode(response)}');
//           break;

//         case reqUploadStripeFiles:
//           debugPrint('stripe errorResponse ===> ${jsonDecode(response)}');
//           break;

//         case reqCreateStipeAccount:
//           debugPrint("stripe accountResponse ===> ${jsonDecode(response)}");
//           break;

//         case getUploadDocReq:
//           debugPrint("getUploadDocReq error:::::: ${jsonDecode(response)}");
//           break;

//         case deleteDocReq:
//           debugPrint("deleteDocReq error:::::: ${jsonDecode(response)}");
//           break;
//         case uploadDocReq:
//           debugPrint("uploadDocReq error:::::: ${jsonDecode(response)}");
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
//         case reqUploadStripeFiles:
//           var map = jsonDecode(response);
//           debugPrint("stripedocs========> ${map["data"]}");
//           if (stripe1.isEmpty) {
//             stripe1 = map["data"].toString();
//           } else {
//             stripe2 = map["data"].toString();
//           }
//           setState(() {});

//           break;

//         case reqCreateStipeAccount:
//           var map = jsonDecode(response);
//           debugPrint("Stripe account ===> ${map}");
//           //  uploadCertificatesApi();
//           break;
//         case uploadCertificateUrlRequest:
//           var map = jsonDecode(response);
//           debugPrint("uploadCertificateUrlRequest========> $map");

//           if (map["code"] == 200) {
//             debugPrint("InsideDoc:::::::");
//             if (map["docData"]["govt_id"] != null) {
//               debugPrint("InsideGov");
//               sharedPreferences!.setString(file1Key, map["docData"]["govt_id"]);
//               sharedPreferences!
//                   .setString(file1NameKey, map["docData"]["govt_id_mediatype"]);
//               sharedPreferences!.setBool(skipDocumentsKey, true);
//             }
//             if (map["docData"]["photography_licence"] != null) {
//               sharedPreferences!
//                   .setString(file2Key, map["docData"]["photography_licence"]);
//               sharedPreferences!.setString(
//                   file2NameKey, map["docData"]["photography_mediatype"]);
//               sharedPreferences!.setBool(skipDocumentsKey, true);
//             }
//             if (map["docData"]["comp_incorporation_cert"] != null) {
//               sharedPreferences!.setString(
//                   file3Key, map["docData"]["comp_incorporation_cert"]);
//               sharedPreferences!.setString(file3NameKey,
//                   map["docData"]["comp_incorporation_cert_mediatype"]);
//               sharedPreferences!.setBool(skipDocumentsKey, true);
//             }
//             setState(() {});
//           }
//           showSnackBar(
//               "Documents uploaded!", uploadDocMessage, colorOnlineGreen);
//           debugPrint("uploadComplete::::$uploadComplete");
//           debugPrint("menuScreen::::${widget.menuScreen}");
//           if (widget.menuScreen) {
//             uploadComplete = true;
//             setState(() {});
//           } else {
//             uploadComplete = true;
//             setState(() {});
//             sharedPreferences!.setBool(skipDocumentsKey, true);
//             Navigator.of(context).pushAndRemoveUntil(
//                 MaterialPageRoute(
//                     builder: (context) => WelcomeScreen(
//                           hideLeading: true,
//                           screenType: '',
//                         )),
//                 (route) => false);
//           }

//           if (uploadComplete) {
//             Navigator.of(context).pushAndRemoveUntil(
//                 MaterialPageRoute(
//                     builder: (context) => Dashboard(
//                           initialPosition: 4,
//                         )),
//                 (route) => false);
//           }
//           break;

//         case getAllCmsUrlRequest:
//           debugPrint(
//               'getAllCmsUrlRequest_successResponse ===> ${jsonDecode(response)}');
//           var data = jsonDecode(response);
//           var dataList = data['status'] as List;
//           docInstructionList = dataList
//               .map((e) => DocumentInstructionModel.fromJson(e))
//               .toList();

//           setState(() {});
//           break;

//         case reqDeleteCertificateAPI:
//           debugPrint(
//               'reqDeleteCertificateAPI_successResponse ===> ${jsonDecode(response)}');
//           if (type == "firstDoc") {
//             sharedPreferences?.remove(file1Key);
//             sharedPreferences?.remove(file1NameKey);
//             doc1 = "";
//             doc1Name = "";
//             file1 == null;
//             setState(() {});
//           } else if (type == "secondDoc") {
//             sharedPreferences?.remove(file2Key);
//             sharedPreferences?.remove(file2NameKey);
//             doc2 = "";
//             doc2Name = "";
//             file2 == null;
//             setState(() {});
//           } else {
//             sharedPreferences?.remove(file3Key);
//             sharedPreferences?.remove(file3NameKey);
//             doc3 = "";
//             doc3Name = "";
//             file3 == null;
//             setState(() {});
//           }

//           callGetCertificatesAPI();

//           break;

//         case getUploadDocReq:
//           debugPrint("getUploadDocReq success:::::: $response");
//           var data = jsonDecode(response);
//           var dataModel = data['data'] as List;
//           docList =
//               dataModel.map((e) => DocumentDataModel.fromJson(e)).toList();
//           for (int i = 0;
//               i < docList.length && i < docInstructionList.length;
//               i++) {
//             docInstructionList[i].isSelected = true;
//           }
//           isLoading = true;
//           setState(() {});
//           break;
//         case deleteDocReq:
//           debugPrint("deleteDocReq success:::::: ${jsonDecode(response)}");

//           callGetUploadDocAPI();
//           break;

//         case uploadDocReq:
//           var resp = jsonDecode(response);
//           AnalyticsHelper.trackEvent('kyc_uploaded_successfully',
//               parameters: {'status': resp['status'] ?? 'unknown'});
//           debugPrint("uploadDocReq success:::::: $resp");
//           break;
//       }
//     } on Exception catch (e) {
//       debugPrint("$e");
//     }
//   }
// }

// class DocumentDataModel {
//   String id = "";
//   String documentName = "";
//   bool isSelected = false;

//   DocumentDataModel({
//     required this.id,
//     required this.documentName,
//     required this.isSelected,
//   });

//   factory DocumentDataModel.fromJson(Map<String, dynamic> json) {
//     return DocumentDataModel(
//       id: json['_id'] ?? '',
//       documentName: json['doc_name'] ?? '',
//       isSelected: false,
//     );
//   }
// }

// class DocumentInstructionModel {
//   String id = "";
//   String documentName = "";
//   bool isSelected = false;

//   DocumentInstructionModel({
//     required this.id,
//     required this.documentName,
//     required this.isSelected,
//   });

//   factory DocumentInstructionModel.fromJson(Map<String, dynamic> json) {
//     return DocumentInstructionModel(
//       id: json['_id'] ?? '',
//       documentName: json['document_name'] ?? '',
//       isSelected: false,
//     );
//   }
// }
