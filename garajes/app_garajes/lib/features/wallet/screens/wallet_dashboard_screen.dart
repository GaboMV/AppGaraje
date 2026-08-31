import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import 'wallet_screen.dart' show walletProvider, WalletModel;

// ─── Movement Model ───────────────────────────────────────────────────────────

class MovimientoModel {
  final String id;
  final String tipo;
  final double monto;
  final String descripcion;
  final DateTime fecha;

  const MovimientoModel({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.descripcion,
    required this.fecha,
  });

  factory MovimientoModel.fromJson(Map<String, dynamic> json) {
    return MovimientoModel(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      monto: _toDouble(json['monto']),
      descripcion: json['descripcion']?.toString() ?? '',
      fecha: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  bool get isIngreso =>
      tipo == 'INGRESO' || tipo == 'LIBERACION' || tipo == 'RETENCION';
  bool get isEgreso => tipo == 'RETIRO';
}

// ─── Movements Provider ───────────────────────────────────────────────────────

final movimientosProvider =
    FutureProvider.autoDispose<List<MovimientoModel>>((ref) async {
  try {
    final response =
        await DioClient.instance.get(ApiConstants.walletMovements);
    final data = response.data;
    final list = (data is List ? data : (data['movimientos'] ?? [])) as List;
    return list
        .map((e) => MovimientoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    // Si el endpoint aún no existe, retorna lista vacía en lugar de error
    return [];
  }
});

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Dashboard de billetera tipo "Anfitrión" para el dueño del garaje.
/// Muestra saldo disponible, saldo retenido y últimos movimientos.
class WalletDashboardScreen extends ConsumerWidget {
  const WalletDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final movAsync = ref.watch(movimientosProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Dashboard Anfitrión'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(walletProvider);
              ref.invalidate(movimientosProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Balance principal ────────────────────────────────────────
              walletAsync.when(
                data: (w) => _HeroBalanceCard(wallet: w),
                loading: () => const _LoadingBalanceCard(),
                error: (_, __) => _ErrorCard(
                  onRetry: () => ref.invalidate(walletProvider),
                ),
              ),
              const SizedBox(height: 16),

              // ── Botón retiro (deshabilitado) ─────────────────────────────
              _WithdrawButton(),
              const SizedBox(height: 28),

              // ── Resumen de stats ─────────────────────────────────────────
              walletAsync.maybeWhen(
                data: (w) => _StatsRow(wallet: w),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 28),

              // ── Últimos movimientos ──────────────────────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Últimos Movimientos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  movAsync.maybeWhen(
                    data: (list) => Text(
                      '${list.length} registros',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              movAsync.when(
                data: (list) => list.isEmpty
                    ? const _EmptyMovements()
                    : _MovementsList(movements: list),
                loading: () => const _LoadingMovements(),
                error: (_, __) => const _EmptyMovements(),
              ),
              const SizedBox(height: 20),

              // ── Info box ────────────────────────────────────────────────
              const _InfoBox(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Balance Card ────────────────────────────────────────────────────────

class _HeroBalanceCard extends StatelessWidget {
  final WalletModel wallet;
  const _HeroBalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Mi Billetera',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Saldo Disponible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bs. ${wallet.disponible.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CardChip(
                icon: Icons.lock_clock_rounded,
                label: 'Retenido',
                value: 'Bs. ${wallet.retenido.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _CardChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Withdraw Button (deshabilitado) ─────────────────────────────────────────

class _WithdrawButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Próximamente disponible',
      child: ElevatedButton.icon(
        // null = botón deshabilitado en Flutter
        onPressed: null,
        icon: const Icon(Icons.account_balance_rounded, size: 18),
        label: const Text('Solicitar Retiro a Cuenta Bancaria'),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: AppTheme.border,
          disabledForegroundColor: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final WalletModel wallet;
  const _StatsRow({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final total = wallet.disponible + wallet.retenido;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up_rounded,
            iconColor: AppTheme.secondary,
            bgColor: const Color(0xFFD1FAE5),
            label: 'Total Acumulado',
            value: 'Bs. ${total.toStringAsFixed(2)}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.hourglass_bottom_rounded,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
            label: 'Por Liberar',
            value: 'Bs. ${wallet.retenido.toStringAsFixed(2)}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Movements List ───────────────────────────────────────────────────────────

class _MovementsList extends StatelessWidget {
  final List<MovimientoModel> movements;
  const _MovementsList({required this.movements});

  @override
  Widget build(BuildContext context) {
    final displayList =
        movements.length > 10 ? movements.sublist(0, 10) : movements;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayList.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.border),
        itemBuilder: (_, i) => _MovementTile(movement: displayList[i]),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final MovimientoModel movement;
  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isIngreso = movement.isIngreso;
    final amountColor =
        isIngreso ? AppTheme.secondary : AppTheme.error;
    final amountPrefix = isIngreso ? '+' : '-';

    final dateStr =
        DateFormat('dd MMM · HH:mm', 'es').format(movement.fecha);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIngreso
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIngreso
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: amountColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTipo(movement.tipo),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '$amountPrefix Bs. ${movement.monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'INGRESO':
        return 'Ingreso';
      case 'RETIRO':
        return 'Retiro';
      case 'RETENCION':
        return 'Retención';
      case 'LIBERACION':
        return 'Liberación';
      default:
        return tipo;
    }
  }
}

// ─── Empty / Loading States ───────────────────────────────────────────────────

class _EmptyMovements extends StatelessWidget {
  const _EmptyMovements();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 40, color: AppTheme.border),
          const SizedBox(height: 12),
          const Text(
            'Sin movimientos aún',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aquí verás tus ingresos y retiros',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LoadingMovements extends StatelessWidget {
  const _LoadingMovements();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }
}

class _LoadingBalanceCard extends StatelessWidget {
  const _LoadingBalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.3),
            AppTheme.primary.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error),
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Box ─────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo funciona tu billetera?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          SizedBox(height: 10),
          _InfoRow(
            icon: Icons.lock_clock_rounded,
            text:
                'El saldo retenido se libera 24h después de completado el check-out.',
          ),
          _InfoRow(
            icon: Icons.account_balance_rounded,
            text: 'Los retiros se procesarán en 1–3 días hábiles cuando estén habilitados.',
          ),
          _InfoRow(
            icon: Icons.shield_outlined,
            text: 'Todas las transacciones están protegidas por nuestro sistema ACID.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
