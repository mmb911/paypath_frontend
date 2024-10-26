// ignore_for_file: use_build_context_synchronously, avoid_print, unused_catch_clause

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paypath_last/config/routes/custom_push_navigators.dart';
import 'package:paypath_last/core/error/error_handler.dart';
import 'package:paypath_last/core/utils/global_constants.dart';
import 'package:paypath_last/core/utils/utils.dart';
import 'package:paypath_last/features/auth/models/user.dart';
import 'package:paypath_last/features/auth/providers/auth_provider.dart';
import 'package:paypath_last/features/auth/providers/user_provider.dart';
import 'package:paypath_last/features/auth/screens/login_screen.dart';
import 'package:paypath_last/widgets/main_app.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  void signUpUser({
    required BuildContext context,
    required String fullname,
    required String username,
    required String email,
    required String password,
    required VoidCallback onSignUpSuccess,
  }) async {
    try {
      User user = User(
        fullname: fullname,
        username: username,
        email: email,
        password: password,
        token: '',
        type: '',
        id: '',
        pin: '',
        isVerified: false,
      );
      showDialogLoader(context);

      http.Response res = await http
          .post(
            Uri.parse("$uri/api/createUser"),
            headers: <String, String>{
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: user.toJson(),
          )
          .timeout(const Duration(seconds: 25));
      Navigator.of(context, rootNavigator: true).pop('dialog');

      statusCodeHandler(
          context: context,
          response: res,
          onSuccess: () {
            onSignUpSuccess();
          });
    } on TimeoutException catch (e) {
      showTimeOutError(
        context: context,
        popDialogAndLoader: true,
      );
    } on SocketException catch (e) {
      showNoInternetError(
        context: context,
        popDialogAndLoader: true,
      );
    } on Error catch (e) {
      print('Transfer Error: $e');
    }
  }

  void sendOtp({
    required BuildContext context,
    required String email,
    required String sendPurpose,
    required VoidCallback onTapDialogButton,
  }) async {
    try {
      showDialogLoader(context);

      http.Response res = await http
          .post(Uri.parse("$uri/api/sendOtp/$sendPurpose"),
              headers: <String, String>{
                "Content-Type": "application/json; charset=UTF-8",
              },
              body: jsonEncode({
                "email": email,
              }))
          .timeout(const Duration(seconds: 25));
      Navigator.of(context, rootNavigator: true).pop('dialog');
      print(res.statusCode);
      statusCodeHandler(
        context: context,
        response: res,
        onSuccess: () {
          showAlertMessage(
            context: context,
            title: "Verify Account",
            message: "Please Check Mail For OTP Code",
            onTap: onTapDialogButton,
          );
        },
      );
    } on TimeoutException catch (e) {
      showTimeOutError(
        context: context,
        popDialogAndLoader: true,
      );
    } on SocketException catch (e) {
      showNoInternetError(
        context: context,
        popDialogAndLoader: true,
      );
    } on Error catch (e) {
      print('Send Otp Error: $e');
    }
  }

  void verifyOtp({
    required BuildContext context,
    required String email,
    required String otpCode,
    required VoidCallback onSuccessButtonTap,
  }) async {
    try {
      showDialogLoader(context);

      http.Response res = await http
          .post(Uri.parse("$uri/api/verifyOtp"),
              headers: <String, String>{
                "Content-Type": "application/json; charset=UTF-8",
              },
              body: jsonEncode({
                "email": email,
                "otpCode": otpCode,
              }))
          .timeout(const Duration(seconds: 25));
      Navigator.of(context, rootNavigator: true).pop('dialog');

      statusCodeHandler(
        context: context,
        response: res,
        onSuccess: () {
          showAlertMessage(
            context: context,
            title: "Verification Confirmed",
            message: jsonDecode(res.body)['message'],
            onTap: onSuccessButtonTap,
          );
        },
      );
    } on TimeoutException catch (e) {
      showTimeOutError(
        context: context,
        popDialogAndLoader: true,
      );
    } on SocketException catch (e) {
      showNoInternetError(
        context: context,
        popDialogAndLoader: true,
      );
    } on Error catch (e) {
      print('Verification Error: $e');
    }
  }

  Future checkAvailableUsername({
    required BuildContext context,
    required String username,
    required VoidCallback onSuccess,
  }) async {
    String errorText = '';
    final userToken =
        Provider.of<UserProvider>(context, listen: false).user.token;
    try {
      http.Response res = await http.get(
          Uri.parse('$uri/api/getUsername/$username'),
          headers: <String, String>{
            "Content-Type": "application/json; charset=UTF-8",
            'x-auth-token': userToken,
          }).timeout(const Duration(seconds: 25));

      switch (res.statusCode) {
        case 200:
          onSuccess();
          break;
        case 400:
          errorText = jsonDecode(res.body)['message'];
          break;
        case 500:
          showSnackBar(context, jsonDecode(res.body));
      }
    } on TimeoutException catch (e) {
      showTimeOutError(
        context: context,
      );
    } on SocketException catch (e) {
      showNoInternetError(
        context: context,
      );
    } on Error catch (e) {
      print('Check Available Username Error: $e');
    }
    return errorText;
  }

  void loginInUser({
    required BuildContext context,
    required String username,
    required String password,
    required VoidCallback onLoginSuccess,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      showDialogLoader(context);
      http.Response res = await http
          .post(
            Uri.parse('$uri/api/login'),
            headers: <String, String>{
              "Content-Type": "application/json; charset=UTF-8",
            },
            body: jsonEncode({
              'username': username,
              'password': password,
              'deviceToken': authProvider.deviceToken,
            }),
          )
          .timeout(const Duration(seconds: 25));

      Navigator.of(context, rootNavigator: true).pop('dialog');

      statusCodeHandler(
          context: context,
          response: res,
          onSuccess: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            Provider.of<UserProvider>(context, listen: false).setUser(res.body);
            await prefs.setString(
                'x-auth-token', jsonDecode(res.body)['token']);
            onLoginSuccess();
          });
    } on TimeoutException catch (e) {
      showTimeOutError(
        context: context,
        popDialogAndLoader: true,
      );
    } on SocketException catch (e) {
      print("the error is: $e");
      showNoInternetError(
        context: context,
        popDialogAndLoader: true,
      );
    } on Error catch (e) {
      print('Login Error: $e');
    }
  }

  Future obtainTokenAndUserData(
    BuildContext context,
  ) async {
    try {
      //showDialogLoader(context);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('x-auth-token');

      if (authToken == null) {
        prefs.setString('x-auth-token', '');
      }

      var returnedTokenResponse = await http.post(Uri.parse('$uri/checkToken'),
          headers: <String, String>{
            "Content-Type": "application/json; charset=UTF-8",
            'x-auth-token': authToken!
          });
      //the response will supply us with true or false according to the tokenIsValid api
      var response = jsonDecode(returnedTokenResponse.body);

      if (response == true) {
        //get user data

        http.Response returnedUserResponse =
            await http.get(Uri.parse('$uri/'), headers: <String, String>{
          "Content-Type": "application/json; charset=UTF-8",
          'x-auth-token': authToken,
        });

        var userProvider = Provider.of<UserProvider>(
          context,
          listen: false,
        );
        userProvider.setUser(returnedUserResponse.body);
        print(returnedUserResponse.body);
        print(response);
        //Navigator.of(context, rootNavigator: true).pop('dialog');
      }
      return response;
    } catch (e) {
      print(e);
    }
  }

  void createNewPassword({
    required BuildContext context,
    required String password,
    required String confirmPassword,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      showDialogLoader(context);

      http.Response res = await http
          .post(
              Uri.parse("$uri/api/changePassword/${authProvider.emailAddress}"),
              headers: <String, String>{
                "Content-Type": "application/json; charset=UTF-8",
              },
              body: jsonEncode({
                "password": password,
                "confirmPassword": confirmPassword,
              }))
          .timeout(const Duration(seconds: 25));
      Navigator.of(context, rootNavigator: true).pop('dialog');

      statusCodeHandler(
        context: context,
        response: res,
        onSuccess: () {
          showAlertMessage(
            context: context,
            title: "Success",
            message: "Password Changed Successfully",
            onTap: () => namedNav(
              context,
              LoginScreen.route,
            ),
          );
        },
      );
    } on TimeoutException catch (e) {
      showTimeOutError(
        context: context,
        popDialogAndLoader: true,
      );
    } on SocketException catch (e) {
      showNoInternetError(
        context: context,
        popDialogAndLoader: true,
      );
    } on Error catch (e) {
      print('Create New Password Error: $e');
    }
  }

  void createPin({
    required BuildContext context,
    required String pin,
    required String username,
    required String confirmPin,
  }) async {
    final userToken =
        Provider.of<UserProvider>(context, listen: false).user.token;
    try {
      if (confirmPin == pin) {
        showDialogLoader(context);
        http.Response res = await http
            .post(
              Uri.parse('$uri/api/createLoginPin/$username'),
              headers: <String, String>{
                "Content-Type": "application/json; charset=UTF-8",
                'x-auth-token': userToken,
              },
              body: jsonEncode({
                'pin': pin,
              }),
            )
            .timeout(const Duration(seconds: 25));

        Navigator.of(context, rootNavigator: true).pop('dialog');

        statusCodeHandler(
            context: context,
            response: res,
            onSuccess: () {
              showAlertMessage(
                  context: context,
                  title: "Success",
                  message: jsonDecode(res.body)['message'],
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, MainApp.route, (route) => false,
                        arguments: 0);
                  });
            });
      } else {
        showErrorMessage(
            context: context,
            title: "Error",
            message: "The pin you entered does not match.Try again",
            onTap: () {
              Navigator.pop(context);
            });
      }
    } on TimeoutException catch (e) {
      showTimeOutError(
        context: context,
        popDialogAndLoader: true,
      );
    } on SocketException catch (e) {
      showNoInternetError(
        context: context,
        popDialogAndLoader: true,
      );
    } on Error catch (e) {
      print('Create Pin Error: $e');
    }
  }

  void loginUsingPin({
    required BuildContext context,
    required String pin,
    required String username,
  }) async {
    final userToken =
        Provider.of<UserProvider>(context, listen: false).user.token;
    try {
      showDialogLoader(context);
      http.Response res = await http
          .post(
            Uri.parse('$uri/api/loginUsingPin/$username'),
            headers: <String, String>{
              "Content-Type": "application/json; charset=UTF-8",
              'x-auth-token': userToken,
            },
            body: jsonEncode({
              'pin': pin,
            }),
          )
          .timeout(const Duration(seconds: 25));

      Navigator.of(context, rootNavigator: true).pop('dialog');

      statusCodeHandler(
          context: context,
          response: res,
          onSuccess: () {
            Navigator.pushNamedAndRemoveUntil(
                context, MainApp.route, (route) => false,
                arguments: 0);
          });
    } on TimeoutException catch (e) {
      showTimeOutError(
        context: context,
        popDialogAndLoader: true,
      );
    } on SocketException catch (e) {
      showNoInternetError(
        context: context,
        popDialogAndLoader: true,
      );
    } on Error catch (e) {
      print('Pin Login Error: $e');
    }
  }
}
