import 'package:flutter/cupertino.dart';
import 'package:flutils/app/safe.dart';

class AppNavigator{

  /**
   * Navigate to new page. If loader is true, call pop before.
   */
  static void pushNamed(BuildContext context, String page, [bool loader = false]) {

    if(loader)
      Navigator.pop(context);

    if(!AppNavigator.isInRoute(context, page))
      Navigator.pushNamed(context, page);
  }

  /**
   * Navigate to new page and clean history. If loader is true, call pop before.
   */
  static void pushNamedAndRemoveUntil(BuildContext context, String page, {bool loader = false, Object? arguments}) {

    if(loader)
      Navigator.pop(context);

    if(!AppNavigator.isInRoute(context, page))
      Navigator.pushNamedAndRemoveUntil(context, page, (_) => false, arguments: arguments);
  }

  /**
   * Check if app is in given route
   */
  static bool isInRoute(BuildContext context, String routeName){
    return Safe.get(ModalRoute.of(context)).settings.name == routeName;
  }


}