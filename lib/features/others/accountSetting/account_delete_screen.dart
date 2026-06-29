// import 'dart:convert';

// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:flutter/material.dart';
// import 'package:presshop/utils/CommonAppBar.dart';
// import 'package:presshop/utils/CommonExtensions.dart';
// import 'package:presshop/utils/CommonWigdets.dart';
// import 'package:presshop/view/authentication/LoginScreen.dart';

// import '../../main.dart';
// import '../../utils/Common.dart';
// import '../../utils/networkOperations/NetworkClass.dart';
// import '../../utils/networkOperations/NetworkResponse.dart';

// class AccountDeleteScreen extends StatefulWidget {
//   const AccountDeleteScreen({super.key});

//   @override
//   State<AccountDeleteScreen> createState() => _AccountDeleteScreenState();
// }

// class _AccountDeleteScreenState extends State<AccountDeleteScreen>
//     implements NetworkResponse {
//   List<dynamic> purposeData = [...purposeForDeleteAccount];
//   Map<String, String> selectReason = {};

//   @override
//   Widget build(BuildContext context) {
//     var size = MediaQuery.of(context).size;
//     return Scaffold(
//       appBar: CommonAppBar(
//         elevation: 0,
//         hideLeading: false,
//         title: Text(
//           "Delete account",
//           style: TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.bold,
//               fontSize: size.width * appBarHeadingFontSize),
//         ),
//         centerTitle: false,
//         titleSpacing: 0,
//         size: size,
//         showActions: true,
//         leadingFxn: () {
//           /*  if (widget.editProfileScreen) {
//               widget.editProfileScreen = false;
//             }*/
//           Navigator.pop(context);
//         },
//         actionWidget: [],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(size.width * numD045),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Center(
//               child: Image.asset(
//                 "assets/rabbits/delete_rabbit.png",
//                 height: size.width * numD35,
//                 fit: BoxFit.contain,
//               ),
//             ),
//             SizedBox(height: size.height * numD02),
//             Text(
//               deleteAccountText,
//               style: commonTextStyle(
//                   size: size,
//                   fontSize: size.width * numD035,
//                   color: Colors.red,
//                   fontWeight: FontWeight.w600),
//             ),
//             SizedBox(
//               height: size.height * numD02,
//             ),
//             Text(
//               "Please let us know your reason for deleting the app :- ",
//               style: commonTextStyle(
//                   size: size,
//                   fontSize: size.width * numD04,
//                   color: Colors.black,
//                   fontWeight: FontWeight.w500),
//             ),
//             SizedBox(
//               height: size.height * numD01,
//             ),
//             Expanded(
//               child: ListView.separated(
//                 shrinkWrap: true,
//                 separatorBuilder: (context, index) =>
//                     const Divider(height: 1, color: Colors.grey),
//                 padding: isIpad
//                     ? EdgeInsets.symmetric(vertical: size.width * numD012)
//                     : EdgeInsets.zero,
//                 physics: const BouncingScrollPhysics(),
//                 itemCount: purposeData.length,
//                 scrollDirection: Axis.vertical,
//                 itemBuilder: (ctx, int) {
//                   return ListTile(
//                     contentPadding: isIpad
//                         ? EdgeInsets.symmetric(vertical: size.width * numD02)
//                         : EdgeInsets.zero,
//                     leading: Transform.scale(
//                       scale: isIpad ? 1.8 : 1,
//                       child: Checkbox(
//                         visualDensity: VisualDensity.compact,
//                         value: selectReason == purposeData[int],
//                         onChanged: (value) {
//                           selectReason = purposeData[int];
//                           setState(() {});
//                         },
//                         activeColor: colorThemePink,
//                         checkColor: Colors.white,
//                       ),
//                     ),
//                     title: Text(
//                       purposeData[int]['title'],
//                       style: commonTextStyle(
//                           size: size,
//                           fontSize: size.width * numD034,
//                           color: Colors.black,
//                           fontWeight: FontWeight.w400),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Container(
//               width: double.infinity,
//               height: size.height * (isIpad ? numD1 : numD08),
//               padding: EdgeInsets.symmetric(vertical: size.height * numD015),
//               child: commonElevatedButton(
//                 'Delete Account',
//                 size,
//                 commonTextStyle(
//                     size: size,
//                     fontSize: size.width * (isIpad ? numD032 : numD038),
//                     color: Colors.white,
//                     fontWeight: FontWeight.w700),
//                 commonButtonStyle(size, colorThemePink),
//                 () {
//                   if (selectReason.isNotEmpty) {
//                     showDeleteDialog(size);
//                   } else {
//                     showToast("Please select reason...");
//                   }
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   void showDeleteDialog(Size size) {
//     showDialog(
//         context: navigatorKey.currentState!.context,
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
//                                 youWIllBeMissedText,
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
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(
//                                         size.width * numD04),
//                                     border: Border.all(color: Colors.black)),
//                                 child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(
//                                         size.width * numD04),
//                                     child: Image.asset(
//                                       "assets/rabbits/delete_rabbit2.png",
//                                       height: size.width * numD30,
//                                       width: size.width * numD35,
//                                       fit: BoxFit.cover,
//                                     )),
//                               ),
//                               SizedBox(
//                                 width: size.width * numD04,
//                               ),
//                               Expanded(
//                                 child: Text(
//                                   deleteAccountPopupMessageText,
//                                   style: TextStyle(
//                                       color: Colors.black,
//                                       fontSize: size.width * numD035,
//                                       fontWeight: FontWeight.w500),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(
//                           height: size.width * numD02,
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
//                                     "Procced",
//                                     size,
//                                     commonButtonTextStyle(size),
//                                     commonButtonStyle(size, Colors.black), () {
//                                   Navigator.pop(context);
//                                   NetworkClass.fromNetworkClass(
//                                           deleteAccountUrl,
//                                           this,
//                                           deleteAccountUrlReq,
//                                           selectReason)
//                                       .callRequestServiceHeader(
//                                           true, "post", null);
//                                 }),
//                               )),
//                               SizedBox(
//                                 width: size.width * numD04,
//                               ),
//                               Expanded(
//                                   child: SizedBox(
//                                 height: size.width * numD12,
//                                 child: commonElevatedButton(
//                                     "Cancel",
//                                     size,
//                                     commonButtonTextStyle(size),
//                                     commonButtonStyle(size, colorThemePink),
//                                     () async {
//                                   Navigator.pop(context);
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

//   @override
//   void onError({required int requestCode, required String response}) {
//     try {
//       switch (requestCode) {
//         case deleteAccountUrlReq:
//           debugPrint("deleteAccount error: $response");
//           var map = jsonDecode(response);
//           showSnackBar(
//               "Error",
//               map["body"].toString().replaceAll("_", " ").toCapitalized(),
//               Colors.red);
//           break;
//       }
//     } on Exception catch (e) {
//       debugPrint("$e");
//     }
//   }

//   @override
//   void onResponse({required int requestCode, required String response}) async {
//     try {
//       switch (requestCode) {
//         case deleteAccountUrlReq:
//           var map = jsonDecode(response);
//           debugPrint("deleteAccount response: $response");
//           if (map["code"] == 200) {
//             await FirebaseAnalytics.instance.logEvent(
//               name: 'account deleted successfully',
//               parameters: {
//                 'error': 'Account deleted successfully',
//                 'timestamp': DateTime.now().toIso8601String(),
//               },
//             );
//             sharedPreferences!.clear();
//             googleSignIn.signOut();
//             showToast(map['message']);
//             Navigator.of(context).pushAndRemoveUntil(
//                 MaterialPageRoute(builder: (context) => const LoginScreen()),
//                 (route) => false);
//           }
//           break;
//       }
//     } on Exception catch (e) {
//       debugPrint("$e");

//       await FirebaseAnalytics.instance.logEvent(
//         name: 'auto logout error on account delete',
//         parameters: {
//           'error': e.toString(),
//           'timestamp': DateTime.now().toIso8601String(),
//         },
//       );
//     }
//   }
// }
