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
    } catch (e) {
      print('Error parsing ServicioModel: $e');
      return const ServicioModel(id: '', nombre: 'Error', precio: 0.0);
    }
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
  final List<String> imagenes;
  final List<ServicioModel> servicios;
  final double calificacion;
  final int totalResenas;
  final String propietarioId;
  final String? propietarioNombre;
  final String? propietarioFoto;
  final bool disponible;
  final bool estaAprobado;

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
  });

  factory GarageModel.fromJson(Map<String, dynamic> json) {
    try {
      final imgs = json['imagenes'];
      final List<String> imageList = imgs is List
          ? imgs.map((e) => e['url']?.toString() ?? '').toList()
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
      );
    } catch (e, stack) {
      print('CRITICAL ERROR parsing GarageModel: $e');
      print('JSON data: $json');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  String get primeraImagen =>
      imagenes.isNotEmpty ? imagenes.first : '';
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
