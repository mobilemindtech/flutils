import 'package:dartz/dartz.dart';
import 'package:flutils/misc/app_get.dart';


class Parsers {

  static int toInt(id) =>
      id is int ? id : int.parse(id != null && id != "" ? id : "0");

  static int? toIntOrNull(val) =>
      val is int ? val : val != null && val != "" ? int.parse(val) : null;

  static int getInt(val, [String? key, dynamic item]) =>
      item != null ? toInt(item[key]) : toInt(val);

  static double toDouble(val) =>
      val is double ? val : (val is int ? val.toDouble() : double.parse(
          val != null && val != "" ? val : "0"));

  static double? toDoubleOrNull(val) =>
      val is double ? val : (val is int ? val.toDouble() : val != null &&
          val != "" ? double.parse(val) : null);

  static double getDouble(val, [String? key, dynamic item]) =>
      item != null ? toDouble(item[key]) : toDouble(val);

  static bool toBool(val) => val is bool ? val : val == "true";

  static bool? toBoolOrNull(String? val) => val != null ? val == "true" : null;

  static bool getBool(val, [String? key, dynamic item]) =>
      item != null ? toBool(item[key]) : toBool(val);

  static String safeString(val) => val is String ? val : "";

  static String getString(val, [String? key, dynamic item]) =>
      item != null ? safeString(item[key]) : safeString(val);

  static T? mapOrNull<T>(dynamic json, T Function(Map) f) {
    return Option
        .of<Map>(json is Map ? json : null)
        .map(f)
        .orNull;
  }

  static T stringToEnum<T extends Enum>(String str, List<T> values) {
    T? aux = AppGet.firstWhere(
        values,
            (element) => element.name.toUpperCase() == str.toUpperCase()
    );

    return Option.of(aux)
        .throwOnEmpty(message: "error to parse enum")
        .get();
  }
}