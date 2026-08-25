class UserModel {
  final String id;
  final String correo;
  final String nombreCompleto;
  final String estaVerificado; // "NO_VERIFICADO", "PENDIENTE", "RECHAZADO", "VERIFICADO"
  final String? motivoRechazoKyc;
  final String? modoActual;
  final String? token;
  final String? dniFotoUrl;
  final String? selfieUrl;
  final String? telefono;

  const UserModel({
    required this.id,
    required this.correo,
    required this.nombreCompleto,
    this.estaVerificado = "NO_VERIFICADO",
    this.motivoRechazoKyc,
    this.modoActual,
    this.token,
    this.dniFotoUrl,
    this.selfieUrl,
    this.telefono,
  });

  bool get isVerified => estaVerificado == "VERIFICADO";
  bool get isPending => estaVerificado == "PENDIENTE";
  bool get isRejected => estaVerificado == "RECHAZADO";
  bool get isPropietario => modoActual == "PROPIETARIO";
  bool get isCustomer => modoActual == "VENDEDOR";

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      correo: json['correo'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '',
      estaVerificado: json['esta_verificado']?.toString() ?? 'NO_VERIFICADO',
      motivoRechazoKyc: json['motivo_rechazo_kyc'],
      modoActual: json['modo_actual'],
      token: json['token'],
      dniFotoUrl: json['dni_foto_url'],
      selfieUrl: json['selfie_url'],
      telefono: json['telefono'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'correo': correo,
        'nombre_completo': nombreCompleto,
        'esta_verificado': estaVerificado,
        'motivo_rechazo_kyc': motivoRechazoKyc,
        'modo_actual': modoActual,
        'dni_foto_url': dniFotoUrl,
        'selfie_url': selfieUrl,
        'telefono': telefono,
      };

  UserModel copyWith({
    String? id,
    String? correo,
    String? nombreCompleto,
    String? estaVerificado,
    String? motivoRechazoKyc,
    String? modoActual,
    String? token,
    String? dniFotoUrl,
    String? selfieUrl,
    String? telefono,
  }) {
    return UserModel(
      id: id ?? this.id,
      correo: correo ?? this.correo,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      estaVerificado: estaVerificado ?? this.estaVerificado,
      motivoRechazoKyc: motivoRechazoKyc ?? this.motivoRechazoKyc,
      modoActual: modoActual ?? this.modoActual,
      token: token ?? this.token,
      dniFotoUrl: dniFotoUrl ?? this.dniFotoUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      telefono: telefono ?? this.telefono,
    );
  }
}
