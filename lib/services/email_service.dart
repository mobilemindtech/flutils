

import 'dart:convert';
import 'dart:io';
import 'package:flutils/misc/app_get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EmailUserInfo {
  String name;
  String email;
  EmailUserInfo(this.name, this.email);
}

class EmailService {

  static String mailServerUrl = 'http://www.mobilemind.com.br/mailServer/sendEmail';
  static DateTime? lastSent;
  static bool sending = false;
  static Future<EmailUserInfo> Function()? userInfoFactory;
  static String? appName;

  static configure(String appName, Future<EmailUserInfo> Function() userInfoFactory){
    EmailService.appName = appName;
    EmailService.userInfoFactory = userInfoFactory;
  }

  static Future<Null> send({String? subject,
        String body = "",
        Object? error,
        String? action}) async {


    subject ??= "$appName - App info";

    if (lastSent != null) {
      var diff = DateTime.now().difference(AppGet.get(lastSent));

      if (diff.inSeconds < 5)
        return;
    }

    if (sending)
      return;

    sending = true;

    var userInfo = await userInfoFactory!();

    if (error != null) {
      print("email error type ${error.runtimeType}");

      body = """
        <h2>Informações sobre o app $appName</h2>
        <p>
          User: ${userInfo.name} <br/>
          E-mail: ${userInfo.email} <br/>          
          Action: $action <br/>
          S.O: ${Platform.isIOS ? "ios" : "android"}<br/>
          Date: ${DateFormat("dd/MM/yyyy").format(DateTime.now())} <br/>
          ${error.runtimeType} - $error
        </p>
      """;
    }
    var payload = {
      "subject": subject,
      "body": body,
      "fromName": appName,
      "to": "suporte@mobilemind.com.br",
      "application": appName
    };

    try {
      var response = await http.post(
          Uri.parse(mailServerUrl), body: json.encode(payload), headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      });

      if (response.statusCode != 200) {
        print("Error on send e-mail. Code: ${response
            .statusCode}, Message: ${response.reasonPhrase}");
      } else {
        lastSent = DateTime.now();
        print("E-mail send success");
      }
    } finally {
      sending = false;
    }
  }

}