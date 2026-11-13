class Categoria {
  final int id;
  final String nome;
  final String tipo;
  final String cor;

  Categoria({required this.id, required this.nome, required this.tipo, required this.cor});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      cor: json['cor'] ?? '',
    );
  }
}
