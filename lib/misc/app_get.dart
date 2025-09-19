
import 'package:flutter/material.dart';
import 'package:flutils/misc/device.dart';
import 'package:rxdart/streams.dart';

typedef GetWidgetTest = bool Function();
typedef GetWidgetMake<T> = T Function();

class AppGet {

  static T? getOrNull<T>(GetWidgetTest getTest, T? item){
    if(getTest()){
      return item;
    }

    return null;
  }

  static T? getOrNull2<T>(GetWidgetTest getTest, GetWidgetMake<T> make){
    if(getTest()){
      return make();
    }
    return null;
  }

  static T getOr<T>(GetWidgetTest getTest, T? item1, T? item2){
    if(getTest()){
      return item1!;
    }
    return item2!;
  }

  static T getOr3<T>(T? item1, T item2){
    if(item1 != null){
      return item1;
    }
    return item2;
  }

  static T getOr2<T>(GetWidgetTest getTest, GetWidgetMake<T> make1, GetWidgetMake<T> make2){
    if(getTest()){
      return make1();
    }
    return make2();
  }

  static Widget getWidgetOrEmpty(GetWidgetTest getTest, Widget? widget){
    if(getTest()){
      return widget!;
    }
    return Container();
  }

  static Widget getWidgetMakeOrEmpty(GetWidgetTest getTest, GetWidgetMake<Widget> make){
    if(getTest()){
      return make();
    }
    return Container();
  }

  static T getPhoneOrTablet<T>(T item1, T item2){
    if(Device.isTablet()){
      return item2;
    }
    return item1;
  }

  static T getTabletOrPhone<T>(T item1, T item2){
    if(Device.isTablet()){
      return item1;
    }
    return item2;
  }

  static Future<T?> firstOrNull<T>(ValueStream<T> value) async {

    var isEmpty = await value.isEmpty;

    if (isEmpty) {
      return null;
    }
    return await value.first;
  }

  static Future<T?> firstWhereOrNull<T>(ValueStream<T> value, bool test(T element)) async {
    try {
      return value.firstWhere(test);
    } catch(e) {
      if ("$e".contains("No element")) {
        return null;
      }
      throw e;
    }
  }

  static T? firstWhere<T>(List<T> value, bool test(T element)) {
    try {
      return value.firstWhere(test);
    } catch(e) {
      if ("$e".contains("No element")) {
        return null;
      }
      throw e;
    }
  }

  static T get<T>(T? val){
    return val!;
  }

  static void exec(Function? cb){
    if(cb != null) cb();
  }
}