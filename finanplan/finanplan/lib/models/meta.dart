class Meta {
  final int id;
  final String titulo;
  final String descricao;
  final String icone;
  final double valorAtual;
  final double valorAlvo;
  final DateTime? dataLimite;

  Meta({required this.id, required this.titulo, required this.descricao, required this.icone, required this.valorAtual, required this.valorAlvo, this.dataLimite});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      icone: json['icone'] ?? 'flag',
      valorAtual: (json['valorAtual'] as num?)?.toDouble() ?? 0,
      valorAlvo: (json['valorAlvo'] as num?)?.toDouble() ?? 0,
      dataLimite: json['dataLimite'] == null ? null : DateTime.tryParse(json['dataLimite']),
    );
  }
}
