

class Validator{

  static String emailPattern = "[A-Za-z0-9.\-]+@[A-Za-z0-9\-]+[.][A-Za-z0-9.\-]+";

  static String filterNumber(String text){

    var regex = new RegExp(r"(\d+)");
    var results = regex.allMatches(text).map((m) => m[0]).toList();
    return results.join();
  }

  static bool isValidMobilePhone(String val){
    if(val == null)
      return false;

    val = filterNumber(val);

    return val.length == 11;
  }

  static bool isValidCpf(String cpf){

    if(cpf == null)
      return false;

    cpf = filterNumber(cpf);

    if(cpf.length != 11)
      return false;

    var soma = 0;
    var resto = 0;

    if(cpf == "00000000000")
      return false;

    // <= 9
    for(var i in new List<int>.generate(9, (i) => i+1))
      soma = soma + int.parse(cpf.substring(i-1, i)) * (11 - i);

    resto = (soma * 10) % 11;

    if(resto == 10 || resto == 11)
      resto = 0;

    if(resto != int.parse(cpf.substring(9, 10)))
      return false;

    soma = 0;

    // <= 10
    for(var i in new List<int>.generate(10, (i) => i+1))
      soma = soma + int.parse(cpf.substring(i-1, i)) * (12 - i);

    resto = (soma * 10) % 11;

    if(resto == 10 || resto == 11)
      resto = 0;

    if(resto != int.parse(cpf.substring(10, 11)))
      return false;

    return true;
  }

  static bool isValidEmail(String email){

    if (email == null)
      return false;

    return RegExp(emailPattern).hasMatch(email);
  }

  static bool isEmpty(String text){

    if (text == null)
      return true;

    return text.trim().length == 0;
  }


  static bool isValidCnpj(String  cnpj){

    if (cnpj == null)
      return false;

    cnpj = filterNumber(cnpj);


    if(cnpj.length != 14)
      return false;

    var invalidos = <String>[
      "00000000000000",
      "11111111111111",
      "22222222222222",
      "33333333333333",
      "44444444444444",
      "55555555555555",
      "66666666666666",
      "77777777777777",
      "88888888888888",
      "99999999999999",
    ];

    if (invalidos.contains(cnpj))
      return false;

    int tamanho = cnpj.length - 2;
    var numeros = cnpj.substring(0,tamanho);
    var digitos = cnpj.substring(tamanho);
    var soma = 0;
    var pos = tamanho - 7;

    //for i in [tamanho...0]  by -1
    for(var i in new List<int>.generate(tamanho, (x) => x)){
      soma += int.parse(numeros[i]) * pos--;
      if(pos < 2)
        pos = 9;
    }

    var resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
    if(resultado != int.parse(digitos[0]))
      return false;

    tamanho = tamanho + 1;
    numeros = cnpj.substring(0,tamanho);
    soma = 0;
    pos = tamanho - 7;

    for(var i in new List<int>.generate(tamanho, (x) => x)){
      soma += int.parse(numeros[i]) * pos--;
      if(pos < 2)
        pos = 9;
    }

    resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
    if(resultado != int.parse(digitos[1]))
      return false;

    return true;
  }

}
