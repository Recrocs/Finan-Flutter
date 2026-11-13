import 'categoria.dart';

class Transacao {
  final int id;
  final DateTime data;
  final double valor;
  final String tipo;
  final String descricao;
  final Categoria? categoria;

  Transacao({required this.id, required this.data, required this.valor, required this.tipo, required this.descricao, this.categoria});

  factory Transacao.fromJson(Map<String, dynamic> json) {
    return Transacao(
      id: json['id'],
      data: DateTime.tryParse(json['data'] ?? '') ?? DateTime.now(),
      valor: (json['valor'] as num).toDouble(),
      tipo: json['tipo'] ?? '',
      descricao: json['descricao'] ?? '',
      categoria: json['categoria'] == null ? null : Categoria.fromJson(json['categoria']),
    );
  }
}
