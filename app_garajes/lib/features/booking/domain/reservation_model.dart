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
  final String? idVendedor;
  final DateTime? creadaEn;
  final String? mensaje;
  final List<String> categorias;

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
    this.categorias = const [],
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final garage = json['garaje'];
    final renter = json['vendedor'] ?? json['inquilino'];
    final owner = garage != null ? garage['dueno'] : (json['dueno'] ?? json['propietario']);

    final fechasList = json['fechas'] as List?;
    final primeraFecha = (fechasList != null && fechasList.isNotEmpty) ? fechasList[0] : null;

    final parsedFecha = (primeraFecha?['fecha']?.toString()) ?? json['fecha']?.toString() ?? '';
    final parsedHoraInicio = (primeraFecha?['hora_inicio']?.toString()) ?? json['hora_inicio']?.toString() ?? '';
    final parsedHoraFin = (primeraFecha?['hora_fin']?.toString()) ?? json['hora_fin']?.toString() ?? '';
    
    final catList = json['categorias'] as List?;
    final parsedCategorias = catList?.map((e) => e['categoria']['nombre'].toString()).toList() ?? [];

    return ReservationModel(
      id: json['id']?.toString() ?? '',
      garageId: garage?['id']?.toString() ?? json['garaje_id']?.toString() ?? json['id_garaje']?.toString() ?? '',
      garageName: garage?['nombre'],
      garageAddress: garage?['direccion'],
      garageImage: (garage?['imagenes'] is List && (garage['imagenes'] as List).isNotEmpty)
          ? garage['imagenes'][0]['url']
          : null,
      renterId: renter?['id']?.toString() ?? json['id_vendedor']?.toString() ?? json['inquilino_id']?.toString() ?? '',
      renterName: renter?['nombre_completo'],
      ownerId: owner?['id']?.toString() ?? garage?['id_dueno']?.toString() ?? json['propietario_id']?.toString() ?? '',
      ownerName: owner?['nombre_completo'],
      fecha: parsedFecha,
      horaInicio: parsedHoraInicio,
      horaFin: parsedHoraFin,
      totalPrecio: _toDouble(json['precio_total']),
      comision: _toDouble(json['comision_app'] ?? json['comision']),
      estado: json['estado']?.toString().toUpperCase() ?? 'PENDIENTE',
      mensaje: json['mensaje_inquilino'] ?? json['mensaje_inicial'],
      idVendedor: json['id_vendedor']?.toString(),
      creadaEn: json['creada_en'] != null
          ? DateTime.tryParse(json['creada_en'])
          : null,
      categorias: parsedCategorias,
    );
  }

  bool get isPending => estado == 'PENDIENTE';
  bool get isNegotiating => estado == 'EN_NEGOCIACION';
  bool get isAccepted => estado == 'ACEPTADA';
  bool get isPaid => estado == 'PAGADA';
  bool get isActive => estado == 'EN_CURSO';
  bool get isCompleted => estado == 'COMPLETADA';

  double get total => totalPrecio;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

