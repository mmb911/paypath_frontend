import 'package:flutter/material.dart';
import 'package:paypath_last/config/routes/custom_push_navigators.dart';
import 'package:paypath_last/core/utils/assets.dart';
import 'package:paypath_last/core/utils/color_constants.dart';
import 'package:paypath_last/core/utils/global_constants.dart';
import 'package:paypath_last/core/utils/validators.dart';
import 'package:paypath_last/features/auth/providers/auth_provider.dart';
import 'package:paypath_last/features/auth/screens/forgort_password_verification_screen.dart';
import 'package:paypath_last/features/auth/services/auth_service.dart';
import 'package:paypath_last/widgets/custom_app_bar.dart';
import 'package:paypath_last/widgets/custom_button.dart';
import 'package:paypath_last/widgets/custom_textfield.dart';
import 'package:paypath_last/widgets/height_space.dart';

import 'package:provider/provider.dart';

class ForgortPasswordScreen extends StatefulWidget {
  static const String route = '/forgort-password';
  const ForgortPasswordScreen({super.key});

  @override
  State<ForgortPasswordScreen> createState() => _ForgortPasswordScreenState();
}

class _ForgortPasswordScreenState extends State<ForgortPasswordScreen> {
  final AuthService authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final emailFormkey = GlobalKey<FormState>();
  sendOtp() {
    if (emailFormkey.currentState!.validate()) {
      authService.sendOtp(
        context: context,
        email: emailController.text,
        onTapDialogButton: () => namedNavRemoveUntil(
            context, ForgortPasswordVerificationScreen.route),
        sendPurpose: 'forgort-password',
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setUserEmail(emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: const CustomAppBar(image: logo),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: value20),
          child: Stack(
            children: [
              screenUI(),
              Padding(
                padding: EdgeInsets.only(bottom: heightValue10),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CustomButton(
                    buttonText: "Send Code",
                    buttonTextColor: secondaryAppColor,
                    onTap: () => sendOtp(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget screenUI() {
    return Form(
      key: emailFormkey,
      child: Column(
        children: [
          HeightSpace(heightValue10),
          Text(
            "Forgort Password",
            style:
                TextStyle(fontSize: heightValue30, fontWeight: FontWeight.bold),
          ),
          HeightSpace(heightValue10),
          Text(
            "Enter the email address connected to your account ",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: heightValue17,
            ),
          ),
          HeightSpace(heightValue10),
          CustomTextField(
            hintText: "Enter your email",
            labelText: "Email",
            controller: emailController,
            validator: validateEmail,
          )
        ],
      ),
    );
  }
}
