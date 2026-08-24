import 'package:flutter/foundation.dart';

// Provider inicial, so para definir o padrao de gerenciamento de estado.
// As telas de verdade (dashboard, cadastro, etc) vao criar seus proprios
// providers mais completos quando cada parte for implementada.
class AppState extends ChangeNotifier {
  int contador = 0;

  void incrementar() {
    contador++;
    notifyListeners();
  }
}
