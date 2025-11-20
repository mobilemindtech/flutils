
import 'dart:developer';

import 'package:intl/intl.dart';

var _regex = new RegExp(r"(\w+)");


String filterNumbers(String text){
  var results = _regex.allMatches(text).map((m) => m[0]).toList();
  return results.join();
}

String formatDate(DateTime? date, {String format = "dd/MM/yyyy"}){
  if(date == null) return "null";
  return DateFormat(format).format(date);
}

String toMoney(double val){
  return NumberFormat("###.0#", "pt_BR").format(val);
}

DateTime? parseDate(val, {String format = "yyyy-MM-ddTHH:mm:ss"}){

  log("######### parseDate val = ${val}");
  log("######### parseDate format = ${format}");

  if(val == null) return null;

  try{
    var data = DateFormat(format).parse(val);

    if(data.year > 2000)
      return data;

  }catch(Exception){

  }

  return null;
}