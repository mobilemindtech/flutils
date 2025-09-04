import 'package:dartz/dartz.dart';
import 'package:flutils/app/safe.dart';


int toInt(id) => id is int ? id : int.parse(id != null && id != "" ? id : "0");

int? toIntOrNull(val) => val is int ? val : val != null && val != "" ? int.parse(val) : null;

double toDouble(val) => val is double ? val : (val is int ? val.toDouble() : double.parse(val != null && val != "" ? val : "0"));

double? toDoubleOrNull(val) => val is double ? val : (val is int ? val.toDouble() : val != null && val != "" ? double.parse(val) : null );

bool toBool(val) => val is bool ? val : val == "true";

bool? toBoolOrNull(String? val) => val != null ? val == "true" : null;

String safeString(val) => val is String ? val : "";

int getInt(val, [String? key, dynamic item]) =>  item != null ?  toInt(item[key]) : toInt(val);
double getDouble(val, [String? key, dynamic item]) =>  item != null ?  toDouble(item[key]) : toDouble(val);
bool getBool(val, [String? key, dynamic item]) =>  item != null ?  toBool(item[key]) : toBool(val);
String getString(val, [String? key, dynamic item]) =>  item != null ?  safeString(item[key]) : safeString(val);

T? mapOrNull<T>(dynamic json, T Function(Map) f){
  return Option.of<Map>(json is Map ? json : null)
      .map(f)
      .orNull;
}

T stringToEnum<T extends Enum>(String str, List<T> values) {
  T? aux = Safe.firstWhere(
      values,
          (element) => element.name.toUpperCase() == str.toUpperCase()
  );
  if (aux != null) {
    return aux;
  } else {
    throw Exception("Erro ao dar parse para enum");
  }
}
