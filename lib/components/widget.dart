


import 'package:flutter/material.dart';
import 'package:flutils/app/safe.dart';
import 'package:flutils/services/email_service.dart';
import 'package:flutils/misc/error.dart';
import 'package:flutils/support/device.dart';
import 'package:flutils/types/flutils_style.dart';
import 'package:flutils/types/flutils_navigator.dart';
import 'package:flutils/app/app_get.dart';

class WidgetUtil {

  static Widget space5(){
    return space(5);
  }
  static Widget space10(){
    return space(10);
  }

  static Widget space15(){
    return space(15);
  }
  static Widget space20(){
    return space(20);
  }

  static Widget space25(){
    return space(25);
  }
  static Widget space30(){
    return space(30);
  }
  static Widget space(double val){
    return SizedBox(
      height: AppGet.getPhoneOrTablet(val, val * 1.5)
    );
  }

  static Widget getActivityIndicator(){
    return new Container(
      padding: const EdgeInsets.only(top: 50.0),
      height: 100.0,
      child: const Center(child: const CircularProgressIndicator()),
    );
  }

  static Widget createErrorBox(String text, BuildContext context, FlutilsStyle style, FlutilsNavigatior navigator, {Object? error, String? action, Function? runAgain, Function? logout}){

    var sendError = true;

    assert((){sendError = false; return true;}());

    print("sendError = $sendError");

    if(sendError)
      EmailService.send(error: error, action: action);

    Widget actionBody = Container();

    text = textToError(text);

    if(runAgain != null){

      actionBody = Column(
        children: [
          GestureDetector(
            onTap: () => Safe.exec(runAgain),
            child: Container(
              margin: EdgeInsets.only(top: 5),
              child: Center(
                child: Text(
                  "Toque para tentar novamente",
                  style: TextStyle(
                      fontFamily: style.fontFamily,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                      color: style.textColorErrorBox
                  ),
                ),
              ),
            ),
          ),
          space10(),
          GestureDetector(
            onTap: () => navigator.logout(context),
            child: Container(
              margin: EdgeInsets.only(top: 5),
              child: Center(
                child: Text(
                  "Sair do app",
                  style: TextStyle(
                      fontFamily: style.fontFamily,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                      color: style.textColorErrorBox
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }



    return Container(
        margin: EdgeInsets.only(top: 15),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Column(
          children: <Widget>[

            Container(
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: style.fontFamily,
                      fontSize: 14,
                      color: Colors.deepOrange
                  ),
                ),
              ),
            ),
            actionBody

          ],
        )
    );
  }

  static Widget createProgressBox(){
    return Container(
      child: Center(
        child: CircularProgressIndicator(), //valueColor: new AlwaysStoppedAnimation<Color>(Colors.white)
      ),
    );
  }

  static Widget createEmptyList(FlutilsStyle style, {String text = "Nenhum registro encontrado", Color fontColor = Colors.black38, FontWeight fontWeight = FontWeight.normal, EdgeInsets margin = const EdgeInsets.only(top: 15)}){
    var isTablet = Device.isTablet();

    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(15),
          margin: margin,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: style.fontFamily,
                  fontSize: isTablet?18:14,
                  color: fontColor,
                  fontWeight: fontWeight
              ),
            ),
          ),
        ),
      ],
    );
  }




}