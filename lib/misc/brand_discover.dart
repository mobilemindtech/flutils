
import 'package:flutter/services.dart';
import 'package:flutils/validator/validator.dart';

// validators
// https://github.com/wirecardBrasil/credit-card-validator/blob/master/main/java/br/com/moip/creditcard/EloCreditCard.java
// numbers test
// https://docs.adyen.com/development-resources/test-cards/test-card-numbers#discover
class BrandDiscovery{

  static final _eloBins = [
    "401178", "401179", "431274", "438935",
    "451416", "457393", "457631", "457632",
    "504175", "627780", "636297", "636368",
    "636369"
  ];
  static final _eloRanges = [
    ["506699", "506778"],
    ["509000", "509999"],
    ["650031", "650033"],
    ["650035", "650051"],
    ["650405", "650439"],
    ["650485", "650538"],
    ["650541", "650598"],
    ["650700", "650718"],
    ["650720", "650727"],
    ["650901", "650920"],
    ["651652", "651679"],
    ["655000", "655019"],
    ["655021", "655058"]
  ];

  static String? forNumber(String number){

    number = Validator.filterNumber(number);

    var brands = {
      "VISA": r"^4[0-9]{12}(?:[0-9]{3})",
      "MASTERCARD": r"^5[1-5][0-9]{14}",
      "AMEX": r"^3[47][0-9]{13}",
      "JCB": r"^(?:2131|1800|35\d{3})\d{11}",
      "DINERS": r"^3(?:0[0-5]|[68][0-9])[0-9]{11}",
      "DISCOVER": r"^6(?:011|5[0-9]{2})[0-9]{12}",
      //"ELO": r"^((((401178)|(401179)|(431274)|(438935)|(451416)|(457393)|(457631)|(457632)|(504175)|(627780)|(636297)|(636368)|(636369))\\d{0,10})|((5067)|(4576)|(4011))\\d{0,12})\$",
    };

    for(var k in brands.keys){
      var regex = RegExp(brands[k]!);
      if(regex.hasMatch(number))
        return k;
    }

    if(number.length == 16 && _eloBins.contains(number.substring(0, 6))) {
      return "ELO";
    }else if(number.length >= 5){
      var intNumber = int.parse(number.substring(0, 6));
      if(_eloRanges.any((range) => intNumber >= int.parse(range[0]) && intNumber <= int.parse(range[1]))){
        return "ELO";
      }
    }

    return null;
  }

}