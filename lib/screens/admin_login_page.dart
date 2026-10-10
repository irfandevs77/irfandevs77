import 'package:flutter/material.dart';

import 'account_login_page.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) => const AccountLoginPage(adminOnly: true);
}
