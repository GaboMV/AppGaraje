class CreateGarageRequest {
  final String nombre;
  final String direccion;
  final double lat;
  final double lng;
  final double precioHora;
  final double precioDia;
  final int capacidad;
  final String? descripcion;

  const CreateGarageRequest({
    required this.nombre,
    required this.direccion,
    required this.lat,
    required this.lng,
    required this.precioHora,
    required this.precioDia,
    required this.capacidad,
    this.descripcion,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'direccion': direccion,
        'lat': lat,
        'lng': lng,
        'precio_hora': precioHora,
        'precio_dia': precioDia,
        'capacidad': capacidad,
        if (descripcion != null && descripcion!.isNotEmpty)
          'descripcion': descripcion,
      };
}
