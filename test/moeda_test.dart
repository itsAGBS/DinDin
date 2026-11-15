import 'package:flutter_test/flutter_test.dart';
import 'package:DinDin/utils/moeda.dart';

/// O intl separa símbolo e número com espaço não separável (U+00A0).
String _normalizar(String texto) => texto.replaceAll('\u00A0', ' ');

void main() {
  group('Moeda.formatar', () {
    test('real usa símbolo R\$ e separadores brasileiros', () {
      expect(_normalizar(Moeda.real.formatar(1234.5)), 'R\$ 1.234,50');
    });

    test('dólar usa ponto decimal', () {
      expect(_normalizar(Moeda.dolar.formatar(1234.5)), 'US\$1,234.50');
    });

    test('euro coloca o símbolo depois do valor', () {
      expect(_normalizar(Moeda.euro.formatar(1234.5)), '1.234,50 €');
    });

    test('valores negativos mantêm o sinal', () {
      expect(_normalizar(Moeda.real.formatar(-12)), '-R\$ 12,00');
    });
  });

  group('Moeda.doNome', () {
    test('reconhece o nome salvo', () {
      expect(Moeda.doNome('euro'), Moeda.euro);
    });

    test('volta para o real quando o valor é nulo ou desconhecido', () {
      expect(Moeda.doNome(null), Moeda.real);
      expect(Moeda.doNome('bitcoin'), Moeda.real);
    });
  });
}
