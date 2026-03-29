class ServicioModel {
  final String id;
  final String nombre;
  final double precio;
  final String? descripcion;

  const ServicioModel({
    required this.id,
    required this.nombre,
    required this.precio,
    this.descripcion,
  });

  factory ServicioModel.fromJson(Map<String, dynamic> json) {
    try {
      return ServicioModel(
        id: json['id']?.toString() ?? '',
        nombre: json['nombre'] ?? '',
        precio: _toDouble(json['precio']),
        descripcion: json['descripcion'],
      );
    import '../../../core/utils/app_logger.dart';
    
    // ...
    } catch (e) {
      AppLogger.warn('Error derivando entidad conceptual ServicioModel: $e');
      return const ServicioModel(id: '', nombre: 'Error', precio: 0.0);
    }
  }
}

class GarageImageModel {
  final String id;
  final String url;

  const GarageImageModel({required this.id, required this.url});

  factory GarageImageModel.fromJson(Map<String, dynamic> json) {
    return GarageImageModel(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

class GarageModel {
  final String id;
  final String nombre;
  final String direccion;
  final double latitud;
  final double longitud;
  final double precioPorHora;
  final double precioPorDia;
  final String? descripcion;
  final List<GarageImageModel> imagenes;
  final List<ServicioModel> servicios;
  final double calificacion;
  final int totalResenas;
  final String propietarioId;
  final String? propietarioNombre;
  final String? propietarioFoto;
  final bool disponible;
  final bool estaAprobado;
  final String horaInicioJornada;
  final String horaFinJornada;
  final bool tieneWifi;
  final bool tieneBano;
  final bool tieneElectricidad;
  final bool tieneMesa;

  const GarageModel({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.precioPorHora,
    required this.precioPorDia,
    this.descripcion,
    this.imagenes = const [],
    this.servicios = const [],
    this.calificacion = 0,
    this.totalResenas = 0,
    required this.propietarioId,
    this.propietarioNombre,
    this.propietarioFoto,
    this.disponible = true,
    this.estaAprobado = false,
    this.horaInicioJornada = '08:00',
    this.horaFinJornada = '20:00',
    this.tieneWifi = false,
    this.tieneBano = false,
    this.tieneElectricidad = false,
    this.tieneMesa = false,
  });

  factory GarageModel.fromJson(Map<String, dynamic> json) {
    try {
      final imgs = json['imagenes'];
      final List<GarageImageModel> imageList = imgs is List
          ? imgs.map((e) => GarageImageModel.fromJson(e as Map<String, dynamic>)).toList()
          : [];

      final servs = json['servicios_adicionales'] ?? json['servicios'];
      final List<ServicioModel> servicioList = servs is List
          ? servs.map((e) => ServicioModel.fromJson(e)).toList()
          : [];

      final propietario = json['dueno'] ?? json['propietario'];
      // Buscar ID del dueño en varias posibles ubicaciones
      final String propId = propietario?['id']?.toString() ?? 
                            json['id_dueno']?.toString() ?? 
                            '';

      return GarageModel(
        id: json['id']?.toString() ?? '',
        nombre: json['nombre'] ?? '',
        direccion: json['direccion'] ?? '',
        latitud: _toDouble(json['latitud']),
        longitud: _toDouble(json['longitud']),
        precioPorHora: _toDouble(json['precio_hora'] ?? json['precio_por_hora']),
        precioPorDia: _toDouble(json['precio_dia'] ?? json['precio_por_dia']),
        descripcion: json['descripcion'],
        imagenes: imageList,
        servicios: servicioList,
        calificacion: _toDouble(json['calificacion_promedio']),
        totalResenas: json['total_resenas'] ?? 0,
        propietarioId: propId,
        propietarioNombre: propietario?['nombre_completo'],
        propietarioFoto: propietario?['foto_url'],
        disponible: json['disponible'] ?? true,
        estaAprobado: json['esta_aprobado'] ?? false,
        horaInicioJornada: json['hora_inicio_jornada'] ?? '08:00',
        horaFinJornada: json['hora_fin_jornada'] ?? '20:00',
        tieneWifi: json['tiene_wifi'] ?? false,
        tieneBano: json['tiene_bano'] ?? false,
        tieneElectricidad: json['tiene_electricidad'] ?? false,
        tieneMesa: json['tiene_mesa'] ?? false,
      );
    } catch (e, stack) {
      AppLogger.error('Inconsistencia en serialización de GarageModel', error: e, stackTrace: stack);
      AppLogger.info('Volcado JSON adjunto: $json');
      rethrow;
    }
  }

  String get primeraImagen =>
      imagenes.isNotEmpty ? imagenes.first.url : '';
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
