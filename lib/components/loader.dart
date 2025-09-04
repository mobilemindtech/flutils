
import 'package:flutter/material.dart';
import 'package:flutils/app/app_get.dart';


class Loader{
  static void show(BuildContext context, {String message = 'Aguarde...' }) {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context){
        return new Dialog(
          child: new Container(
            padding: EdgeInsets.symmetric(vertical: AppGet.getTabletOrPhone(50, 30), horizontal: 15.0),
            decoration: new BoxDecoration(
                borderRadius: new BorderRadius.circular(10.0)
            ),
            child: new Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                new CircularProgressIndicator(),
                new Container(
                  margin: const EdgeInsets.only(left: 15.0),
                  child: new Text(message,),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  static Future close(BuildContext context) async {
    return Navigator.pop(context);
  }
}