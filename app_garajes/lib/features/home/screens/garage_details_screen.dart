import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/garage_model.dart';
import '../providers/search_provider.dart';

class GarageDetailsScreen extends ConsumerStatefulWidget {
  const GarageDetailsScreen({super.key});

  @override
  ConsumerState<GarageDetailsScreen> createState() =>
      _GarageDetailsScreenState();
}

class _GarageDetailsScreenState
    extends ConsumerState<GarageDetailsScreen> {
  int _currentImg = 0;

  @override
  Widget build(BuildContext context) {
    final garage = ref.watch(selectedGarageProvider);
    if (garage == null) {
      return const Scaffold(
          body: Center(child: Text('Garaje no disponible')));
    }

    final selectedServices = ref.watch(selectedServicesProvider);
    final extraTotal =
        selectedServices.fold<double>(0, (sum, s) => sum + s.precio);
    final totalDisplay = garage.precioPorHora + extraTotal;

    return Scaffold(
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // Image gallery app bar
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.38,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  _CircleBtn(icon: Icons.share_outlined, onTap: () {}),
                  _CircleBtn(icon: Icons.favorite_border_rounded, onTap: () {}),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ImageGallery(
                    images: garage.imagenes.map((e) => e.url).toList(),
                    current: _currentImg,
                    onChanged: (i) => setState(() => _currentImg = i),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge + price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Garaje Privado',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${garage.precioPorHora.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24),
                              ),
                              Text('por hora',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Name
                      Text(garage.nombre,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              height: 1.2)),
                      const SizedBox(height: 8),

                      // Address
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(garage.direccion,
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                          ),
                        ],
                      ),

                      const _Divider(),

                      // Owner & rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.primaryLight,
                                backgroundImage:
                                    garage.propietarioFoto != null
                                        ? NetworkImage(
                                            garage.propietarioFoto!)
                                        : null,
                                child: garage.propietarioFoto == null
                                    ? const Icon(Icons.person_rounded,
                                        color: AppTheme.primary)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      garage.propietarioNombre ??
                                          'Propietario',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  Text('Dueño del Garaje',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 16,
                                    color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(
                                  garage.calificacion.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                Text(' (${garage.totalResenas})',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Description
                      if (garage.descripcion != null) ...[
                        const _Divider(),
                        Text(garage.descripcion!,
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                height: 1.6)),
                      ],

                      // Free services
                      const _Divider(),
                      const _SectionTitle('Incluido gratis'),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          _AmenityChip(
                              icon: Icons.wc_rounded, label: 'Baño'),
                          SizedBox(width: 12),
                          _AmenityChip(
                              icon: Icons.bolt_rounded, label: 'Luz'),
                          SizedBox(width: 12),
                          _AmenityChip(
                              icon: Icons.wifi_rounded, label: 'WiFi'),
                        ],
                      ),

                      // Extra services
                      if (garage.servicios.isNotEmpty) ...[
                        const _Divider(),
                        const _SectionTitle('Servicios Extra'),
                        const SizedBox(height: 12),
                        ...garage.servicios.map((s) {
                          final isSelected =
                              selectedServices.any((sel) => sel.id == s.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: _ServiceTile(
                              servicio: s,
                              selected: isSelected,
                              onToggle: () {
                                final notifier = ref
                                    .read(selectedServicesProvider.notifier);
                                if (isSelected) {
                                  notifier.state = selectedServices
                                      .where((sel) => sel.id != s.id)
                                      .toList();
                                } else {
                                  notifier.state = [
                                    ...selectedServices,
                                    s
                                  ];
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom CTA bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: AppTheme.border, width: 1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total Estimado',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      Text(
                        '\$${totalDisplay.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          context.push(AppRoutes.bookingRequest),
                      child: const Text('Reservar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final int current;
  final ValueChanged<int> onChanged;
  const _ImageGallery(
      {required this.images,
      required this.current,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        color: AppTheme.primaryLight,
        child: const Center(
          child: Icon(Icons.garage_outlined, size: 80, color: AppTheme.primary),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onChanged,
          itemBuilder: (_, i) => Image.network(
            images[i],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(color: AppTheme.primaryLight);
            },
            errorBuilder: (context, error, stackTrace) =>
                Container(color: AppTheme.primaryLight),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == current ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == current
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 18), onPressed: onTap),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 28, color: AppTheme.border);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 4, height: 20, color: AppTheme.primary,
              margin: const EdgeInsets.only(right: 10)),
          Text(text,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ],
      );
}

class _AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AmenityChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
          ],
        ),
      );
}

class _ServiceTile extends StatelessWidget {
  final ServicioModel servicio;
  final bool selected;
  final VoidCallback onToggle;
  const _ServiceTile(
      {required this.servicio,
      required this.selected,
      required this.onToggle});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryLight
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color:
                    selected ? AppTheme.primary.withOpacity(0.5) : AppTheme.border),
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(servicio.nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (servicio.descripcion != null)
                      Text(servicio.descripcion!,
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                '+\$${servicio.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      );
}
