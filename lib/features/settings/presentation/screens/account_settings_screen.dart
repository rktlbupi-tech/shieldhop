import 'package:flutter/material.dart';
import 'account_delete_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Account settings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: size.width * 0.05,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.02,
        ),
        children: [
          ListTile(
            title: Text(
              "Delete Account",
              style: TextStyle(
                fontSize: size.width * 0.04,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: size.width * 0.05,
              color: Colors.red,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountDeleteScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
