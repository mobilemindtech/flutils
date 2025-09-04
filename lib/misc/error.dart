

String textToError(String text) {
  if (text.toLowerCase().contains("refused")) {
    return "Não foi possível conectar com o servidor.";
  } else if (text.toLowerCase().contains("closed") ||
      text.toLowerCase().contains("handshake") ||
      text.toLowerCase().contains("reset")) {
    return "A conexão terminou inesperadamente, verifique sua internet.";
  } else if (text.toLowerCase().contains("unauthorized")) {
    return "Acesso negado. Saia do app usando a opção SAIR do menu na tela inicial e então entre novamente.";
  } else if (text.toLowerCase().contains("network connection not found")) {
    return "Verifique sua conexão com a internet.";
  } else if (text.toLowerCase().contains("unable to resolve host") ||
      text.toLowerCase().contains("no address associated") ||
      text.toLowerCase().contains("no route host") ||
      text.toLowerCase().contains("bad file descriptor") ||
      text.toLowerCase().contains("failed host lookup")) {
    return "Sua internet está com dificuldades em encontrar o servidor. Verifique a estabilidade da sua rede ou tente usar outra internet.";
  } else if (text.toLowerCase().contains("timeout") ||
      text.toLowerCase().contains("timed")) {
    return "O servidor demorou para responder.";
  }
  return text;
}