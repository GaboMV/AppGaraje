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
    return ServicioModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      precio: (json['precio'] ?? 0).toDouble(),
      descripcion: json['descripcion'],
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
  final String? descripcion;
  final List<String> imagenes;
  final List<ServicioModel> servicios;
  final double calificacion;
  final int totalResenas;
  final String propietarioId;
  final String? propietarioNombre;
  final String? propietarioFoto;
  final bool disponible;

  const GarageModel({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.precioPorHora,
    this.descripcion,
    this.imagenes = const [],
    this.servicios = const [],
    this.calificacion = 0,
    this.totalResenas = 0,
    required this.propietarioId,
    this.propietarioNombre,
    this.propietarioFoto,
    this.disponible = true,
  });

  factory GarageModel.fromJson(Map<String, dynamic> json) {
    final imgs = json['imagenes'];
    final List<String> imageList = imgs is List
        ? imgs.map((e) => e['url']?.toString() ?? '').toList()
        : [];

    final servs = json['servicios'];
    final List<ServicioModel> servicioList = servs is List
        ? servs.map((e) => ServicioModel.fromJson(e)).toList()
        : [];

    final propietario = json['propietario'];

    return GarageModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      latitud: (json['latitud'] ?? 0).toDouble(),
      longitud: (json['longitud'] ?? 0).toDouble(),
      precioPorHora: (json['precio_por_hora'] ?? 0).toDouble(),
      descripcion: json['descripcion'],
      imagenes: imageList,
      servicios: servicioList,
      calificacion: (json['calificacion_promedio'] ?? 0).toDouble(),
      totalResenas: json['total_resenas'] ?? 0,
      propietarioId: propietario?['id']?.toString() ?? '',
      propietarioNombre: propietario?['nombre_completo'],
      propietarioFoto: propietario?['foto_url'],
      disponible: json['disponible'] ?? true,
    );
  }

  String get primeraImagen =>
      imagenes.isNotEmpty ? imagenes.first : '';
}
