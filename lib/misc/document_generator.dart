
import 'dart:math';

class DocumentGenerator{

  String cpf(){
    var values = List.generate(9, (index) => Random().nextInt(9));
    for(var _ in [0,1]){
      var val = 0;
      values.asMap().forEach((i, v) { val += (values.length + 1 - i) * v; });
      val = val % 11;
      values.add(val > 1 ? 11 - val : 0);
    }
    return values.join("");
  }

  int _calculateSpecialDigit(List<int> values){
    var digit = 0;
    values.asMap().forEach((i, v) { digit += v * (i % 8 + 2); });
    digit = 11 - digit % 11;
    return digit < 10 ? digit : 0;
  }

  String cnpj(){
    var values = [1, 0, 0, 0] + List.generate(8, (index) => Random().nextInt(9));
    for(var _ in [0,1]){
      values = [_calculateSpecialDigit(values)] + values;
    }
    return values.reversed.join("");
  }
}