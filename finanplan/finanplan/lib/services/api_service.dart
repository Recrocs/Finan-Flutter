  import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<dynamic> get(String rota) async {
    final resposta = await http.get(Uri.parse('$baseUrl$rota')).timeout(const Duration(seconds: 15));
    return _tratarResposta(resposta);
  }

  static Future<dynamic> post(String rota, Map<String, dynamic> dados) async {
    final resposta = await http.post(
      Uri.parse('$baseUrl$rota'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 15));
    return _tratarResposta(resposta);
  }

  static Future<dynamic> put(String rota, Map<String, dynamic> dados) async {
    final resposta = await http.put(
      Uri.parse('$baseUrl$rota'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 15));
    return _tratarResposta(resposta);
  }

  static Future<dynamic> patch(String rota, Map<String, dynamic> dados) async {
    final resposta = await http.patch(
      Uri.parse('$baseUrl$rota'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 15));
    return _tratarResposta(resposta);
  }

  static Future<dynamic> delete(String rota) async {
    final resposta = await http.delete(Uri.parse('$baseUrl$rota')).timeout(const Duration(seconds: 15));
    return _tratarResposta(resposta);
  }

  static dynamic _tratarResposta(http.Response resposta) {
    dynamic dados;
    try {
      dados = jsonDecode(resposta.body);
    } catch (_) {
      dados = resposta.body;
    }

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return dados;
    }

    if (dados is Map && dados['erro'] != null) {
      throw Exception(dados['erro']);
    }

    throw Exception('Erro ${resposta.statusCode} na comunicação com o servidor.');
  }
}
