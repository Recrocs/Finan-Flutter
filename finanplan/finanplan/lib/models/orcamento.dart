import 'categoria.dart';

class Orcamento {
  final int id;
  final double limite;
  final double gasto;
  final Categoria? categoria;

  Orcamento({required this.id, required this.limite, required this.gasto, this.categoria});

  factory Orcamento.fromJson(Map<String, dynamic> json) {
    return Orcamento(
      id: json['id'],
      limite: (json['limite'] as num).toDouble(),
      gasto: (json['gasto'] as num?)?.toDouble() ?? 0,
      categoria: json['categoria'] == null ? null : Categoria.fromJson(json['categoria']),
    );
  }
}
