

import 'package:flutils/misc/app_get.dart';
import 'package:flutter/cupertino.dart';

mixin FlutilsNavigatior {
  Future logout(BuildContext context);

  /**
   * Navigate to new page. If loader is true, call pop before.
   */
  void pushNamed(BuildContext context, String page, [bool loader = false]) {

    if(loader)
      Navigator.pop(context);

    if(!isInRoute(context, page))
      Navigator.pushNamed(context, page);
  }

  /**
   * Navigate to new page and clean history. If loader is true, call pop before.
   */
  void pushNamedAndRemoveUntil(BuildContext context, String page, {bool loader = false, Object? arguments}) {

    if(loader)
      Navigator.pop(context);

    if(!isInRoute(context, page))
      Navigator.pushNamedAndRemoveUntil(context, page, (_) => false, arguments: arguments);
  }

  /**
   * Check if app is in given route
   */
  bool isInRoute(BuildContext context, String routeName){
    return AppGet.get(ModalRoute.of(context)).settings.name == routeName;
  }
}