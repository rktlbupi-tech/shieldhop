import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../config/di/injection.dart';
import '../../data/datasources/settings_remote_datasource.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool hideNewPassword = true;
  bool showLowercase = false;
  bool showSpecialcase = false;
  bool showUppercase = false;
  bool showMincase = false;
  bool showNumber = false;
  bool hideCurrentPassword = true;
  bool hideConfirmPassword = true;

  bool isLoading = false;
  final SettingsRemoteDatasource _datasource = getIt<SettingsRemoteDatasource>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _onNewPasswordChanged(String text) {
    setState(() {
      showMincase = text.length >= 8;
      showUppercase = RegExp(r'[A-Z]').hasMatch(text);
      showLowercase = RegExp(r'[a-z]').hasMatch(text);
      showNumber = RegExp(r'[0-9]').hasMatch(text);
      showSpecialcase = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text);
    });
  }

  Future<void> changePasswordApi() async {
    if (!formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    try {
      await _datasource.changePassword({
        "old_password": _currentPasswordController.text.trim(),
        "new_password": _newPasswordController.text.trim(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your password has been successfully changed!"), backgroundColor: AppColors.primary));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final themeColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.only(
              left: 0,
              top: size.width * 0.01,
            ),
            padding: EdgeInsets.all(
              size.width * 0.043,
            ),
            child: Image.asset(
              "assets/icons/ic_arrow_left.png",
              height: size.width * 0.025,
              width: size.width * 0.025,
              color: Colors.black,
            ),
          ),
        ),
        leadingWidth: size.width * 0.14,
        title: Text(
          "Change password",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: size.width * 0.045,
            fontFamily: 'AirbnbCereal',
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: size.width * 0.02, right: size.width * 0.1),
                  child: Text(
                    "Your password must be at least 8 characters and should include a combination of numbers, letters and special characters",
                    style: TextStyle(color: Colors.black, fontSize: size.width * 0.033, fontFamily: 'AirbnbCereal', fontWeight: FontWeight.w400),
                  ),
                ),
                SizedBox(height: size.width * 0.06),
                Expanded(
                  child: ListView(
                    children: [
                      // Current Password
                      Text(
                        "Current Password",
                        style: TextStyle(fontSize: size.width * 0.035, color: Colors.black, fontWeight: FontWeight.w400, fontFamily: 'AirbnbCereal'),
                      ),
                      SizedBox(height: size.width * 0.02),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: hideCurrentPassword,
                        style: const TextStyle(fontFamily: 'AirbnbCereal'),
                        decoration: InputDecoration(
                          hintText: "Enter current password",
                          hintStyle: const TextStyle(fontFamily: 'AirbnbCereal'),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(size.width * 0.03),
                            child: const ImageIcon(AssetImage("assets/icons/ic_key.png")),
                          ),
                          suffixIcon: InkWell(
                            onTap: () => setState(() => hideCurrentPassword = !hideCurrentPassword),
                            child: ImageIcon(
                              hideCurrentPassword ? const AssetImage("assets/icons/ic_block_eye.png") : const AssetImage("assets/icons/ic_show_eye.png"),
                              color: hideCurrentPassword ? Colors.grey : Colors.black,
                            ),
                          ),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                        ),
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      ),
                      SizedBox(height: size.width * 0.06),

                      // New Password
                      Text(
                        "New password",
                        style: TextStyle(fontSize: size.width * 0.035, color: Colors.black, fontWeight: FontWeight.w400, fontFamily: 'AirbnbCereal'),
                      ),
                      SizedBox(height: size.width * 0.02),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: hideNewPassword,
                        onChanged: _onNewPasswordChanged,
                        style: const TextStyle(fontFamily: 'AirbnbCereal'),
                        decoration: InputDecoration(
                          hintText: "Enter new password",
                          hintStyle: const TextStyle(fontFamily: 'AirbnbCereal'),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(size.width * 0.03),
                            child: const ImageIcon(AssetImage("assets/icons/ic_key.png")),
                          ),
                          suffixIcon: InkWell(
                            onTap: () => setState(() => hideNewPassword = !hideNewPassword),
                            child: ImageIcon(
                              hideNewPassword ? const AssetImage("assets/icons/ic_block_eye.png") : const AssetImage("assets/icons/ic_show_eye.png"),
                              color: hideNewPassword ? Colors.grey : Colors.black,
                            ),
                          ),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Required";
                          if (_currentPasswordController.text == _newPasswordController.text) return "Please choose a new password.";
                          if (!showNumber || !showSpecialcase || !showLowercase || !showUppercase || !showMincase) return "";
                          return null;
                        },
                      ),
                      SizedBox(height: size.width * 0.02),

                      // Validation checks
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Minimum password requirement", style: TextStyle(color: Colors.black, fontSize: size.width * 0.035, fontFamily: 'AirbnbCereal')),
                          SizedBox(height: size.width * 0.02),
                          _buildRequirementRow("Contains at least 01 lowercase character", showLowercase, size),
                          _buildRequirementRow("Contains at least 01 special character", showSpecialcase, size),
                          _buildRequirementRow("Contains at least 01 uppercase character", showUppercase, size),
                          _buildRequirementRow("Must be at least 08 characters", showMincase, size),
                          _buildRequirementRow("Contains at least 01 number", showNumber, size),
                        ],
                      ),
                      SizedBox(height: size.width * 0.06),

                      // Confirm Password
                      Text(
                        "Confirm new password",
                        style: TextStyle(fontSize: size.width * 0.035, color: Colors.black, fontWeight: FontWeight.w400, fontFamily: 'AirbnbCereal'),
                      ),
                      SizedBox(height: size.width * 0.02),
                      TextFormField(
                        controller: _confirmNewPasswordController,
                        obscureText: hideConfirmPassword,
                        style: const TextStyle(fontFamily: 'AirbnbCereal'),
                        decoration: InputDecoration(
                          hintText: "Re-enter new password",
                          hintStyle: const TextStyle(fontFamily: 'AirbnbCereal'),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(size.width * 0.03),
                            child: const ImageIcon(AssetImage("assets/icons/ic_key.png")),
                          ),
                          suffixIcon: InkWell(
                            onTap: () => setState(() => hideConfirmPassword = !hideConfirmPassword),
                            child: ImageIcon(
                              hideConfirmPassword ? const AssetImage("assets/icons/ic_block_eye.png") : const AssetImage("assets/icons/ic_show_eye.png"),
                              color: hideConfirmPassword ? Colors.grey : Colors.black,
                            ),
                          ),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Required";
                          if (_newPasswordController.text.trim() != value) return "Passwords do not match";
                          return null;
                        },
                      ),
                      SizedBox(height: size.width * 0.15),

                      // Button
                      Container(
                        width: size.width,
                        height: size.width * 0.13,
                        margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size.width * 0.03)),
                          ),
                          onPressed: isLoading ? null : changePasswordApi,
                          child: isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text("Submit", style: TextStyle(color: Colors.white, fontSize: size.width * 0.035, fontWeight: FontWeight.bold, fontFamily: 'AirbnbCereal')),
                        ),
                      ),
                      SizedBox(height: size.width * 0.03),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isValid, Size size) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.width * 0.01),
      child: Row(
        children: [
          Image.asset(isValid ? "assets/icons/check.png" : "assets/icons/cross.png", width: 15, height: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: isValid ? Colors.green : Colors.red, fontSize: size.width * 0.03, fontWeight: FontWeight.w500, fontFamily: 'AirbnbCereal'),
          )
        ],
      ),
    );
  }
}
