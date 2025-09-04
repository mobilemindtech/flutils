

import 'package:rxdart/rxdart.dart';

class Safe{
  static T get<T>(T? val){
    return val!;
  }

  static void exec(Function? cb){
    if(cb != null) cb();
  }

  static Future<T?> firstOrNull<T>(ValueStream<T> value) async {

    var isEmpty = await value.isEmpty;

    if(isEmpty)
      return null;
    return await value.first;
  }

  static Future<T?> firstWhereOrNull<T>(ValueStream<T> value, bool test(T element)) async {
    try{
      return value.firstWhere(test);
    }catch(StateError, e){
      if("$e" == "No element")
        return null;
      throw e;
    }
  }

  static T? firstWhere<T>(List<T> value, bool test(T element)) {
    try{
      return value.firstWhere(test);
    } on StateError catch (e){
      if("${e.message}" == "No element")
        return null;
      throw e;
    }
  }
}