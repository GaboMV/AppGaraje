class UserModel {
  final String id;
  final String correo;
  final String nombreCompleto;
  final bool estaVerificado;
  final String? modoActual;
  final String? token;

  const UserModel({
    required this.id,
    required this.correo,
    required this.nombreCompleto,
    this.estaVerificado = false,
    this.modoActual,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      correo: json['correo'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      estaVerificado: json['esta_verificado'] ?? false,
      modoActual: json['modo_actual'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'correo': correo,
        'nombre_completo': nombreCompleto,
        'esta_verificado': estaVerificado,
        'modo_actual': modoActual,
      };

  UserModel copyWith({
    String? id,
    String? correo,
    String? nombreCompleto,
    bool? estaVerificado,
    String? modoActual,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      correo: correo ?? this.correo,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      estaVerificado: estaVerificado ?? this.estaVerificado,
      modoActual: modoActual ?? this.modoActual,
      token: token ?? this.token,
    );
  }
}
