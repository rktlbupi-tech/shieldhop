import 'package:flutter/material.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController textController = TextEditingController();

  final SettingsRemoteDatasource _datasource =
      getIt<SettingsRemoteDatasource>();
  bool isLoading = false;

  Future<void> submitContactUs() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      await _datasource.contactUs({
        "phone": phoneController.text.trim(),
        "email": emailController.text.trim(),
        "subject": subjectController.text.trim(),
        "text": textController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request submitted successfully"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    subjectController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final themeColor = AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Contact us",
          style: TextStyle(
            color: Colors.black,
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                  children: [
                    SizedBox(height: size.width * 0.02),
                    Text(
                      "Your contact number",
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: size.width * 0.02),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "Enter contact number",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? "Required"
                          : null,
                    ),
                    SizedBox(height: size.width * 0.06),

                    Text(
                      "Your Email id",
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: size.width * 0.02),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: "Enter email id",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? "Required"
                          : null,
                    ),
                    SizedBox(height: size.width * 0.06),

                    Text(
                      "Subject",
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: size.width * 0.02),
                    TextFormField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        hintText: "Enter subject",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? "Required"
                          : null,
                    ),
                    SizedBox(height: size.width * 0.06),

                    Text(
                      "Leave a message for us",
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: size.width * 0.02),
                    TextFormField(
                      controller: textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Write a message here...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.03,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? "Required"
                          : null,
                    ),
                    SizedBox(height: size.width * 0.1),

                    Container(
                      width: size.width,
                      height: size.width * 0.13,
                      margin: EdgeInsets.symmetric(
                        horizontal: size.width * 0.02,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              size.width * 0.03,
                            ),
                          ),
                        ),
                        onPressed: isLoading ? null : submitContactUs,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Submit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.035,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: size.width * 0.1),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon(
                          "assets/icons/ic_twitter.png",
                          "https://twitter.com/presshop",
                          size,
                        ),
                        SizedBox(width: size.width * 0.04),
                        _buildSocialIcon(
                          "assets/icons/ic_linkdin.png",
                          "https://linkedin.com/company/presshop",
                          size,
                        ),
                        SizedBox(width: size.width * 0.04),
                        _buildSocialIcon(
                          "assets/icons/ic_instagram.png",
                          "https://instagram.com/presshop",
                          size,
                        ),
                        SizedBox(width: size.width * 0.04),
                        _buildSocialIcon(
                          "assets/icons/ic_facebook.png",
                          "https://facebook.com/presshop",
                          size,
                        ),
                      ],
                    ),
                    SizedBox(height: size.width * 0.05),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String asset, String url, Size size) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: EdgeInsets.all(size.width * 0.03),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          asset,
          width: size.width * 0.06,
          height: size.width * 0.06,
        ),
      ),
    );
  }
}
