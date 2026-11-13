class Usuario {
  final int id;
  final String nome;
  final String email;
  final String? telefone;

  Usuario({required this.id, required this.nome, required this.email, this.telefone});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      telefone: json['Telefone'] ?? json['telefone'],
    );
  }
}
