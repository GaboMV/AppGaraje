class NotificacionModel {
  final String id;
  final String titulo;
  final String? cuerpo;
  final bool leido;
  final DateTime fechaCreacion;

  NotificacionModel({
    required this.id,
    required this.titulo,
    this.cuerpo,
    required this.leido,
    required this.fechaCreacion,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      cuerpo: json['cuerpo'],
      leido: json['leido'] ?? false,
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : DateTime.now(),
    );
  }
}
