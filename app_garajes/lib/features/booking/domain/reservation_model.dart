class ReservationModel {
  final String id;
  final String garageId;
  final String? garageName;
  final String? garageAddress;
  final String? garageImage;
  final String renterId;
  final String? renterName;
  final String ownerId;
  final String? ownerName;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final double totalPrecio;
  final double comision;
  final String estado;
  final String? mensaje;
  final String? idVendedor;
  final DateTime? creadaEn;

  const ReservationModel({
    required this.id,
    required this.garageId,
    this.garageName,
    this.garageAddress,
    this.garageImage,
    required this.renterId,
    this.renterName,
    required this.ownerId,
    this.ownerName,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.totalPrecio,
    this.comision = 0,
    required this.estado,
    this.mensaje,
    this.idVendedor,
    this.creadaEn,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final garage = json['garaje'];
    final renter = json['inquilino'];
    final owner = json['propietario'];

    return ReservationModel(
      id: json['id']?.toString() ?? '',
      garageId: garage?['id']?.toString() ?? json['garaje_id']?.toString() ?? '',
      garageName: garage?['nombre'],
      garageAddress: garage?['direccion'],
      garageImage: (garage?['imagenes'] is List && (garage['imagenes'] as List).isNotEmpty)
          ? garage['imagenes'][0]['url']
          : null,
      renterId: renter?['id']?.toString() ?? json['inquilino_id']?.toString() ?? '',
      renterName: renter?['nombre_completo'],
      ownerId: owner?['id']?.toString() ?? json['propietario_id']?.toString() ?? '',
      ownerName: owner?['nombre_completo'],
      fecha: json['fecha'] ?? '',
      horaInicio: json['hora_inicio'] ?? '',
      horaFin: json['hora_fin'] ?? '',
      totalPrecio: _toDouble(json['precio_total']),
      comision: _toDouble(json['comision']),
      estado: json['estado'] ?? 'pendiente',
      mensaje: json['mensaje_inquilino'],
      idVendedor: json['id_vendedor']?.toString(),
      creadaEn: json['creada_en'] != null
          ? DateTime.tryParse(json['creada_en'])
          : null,
    );
  }

  bool get isPending => estado == 'pendiente';
  bool get isAccepted => estado == 'aceptada';
  bool get isPaid => estado == 'pagada';
  bool get isActive => estado == 'activa';
  bool get isCompleted => estado == 'completada';
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

