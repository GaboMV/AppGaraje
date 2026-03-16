import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';

class WalletModel {
  final double disponible;
  final double retenido;
  const WalletModel({this.disponible = 0, this.retenido = 0});
  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final wallet = json['billetera'] ?? json;
    return WalletModel(
      disponible: (wallet['saldo_disponible'] ?? 0).toDouble(),
      retenido: (wallet['saldo_retenido'] ?? 0).toDouble(),
    );
  }
}

final walletProvider = FutureProvider<WalletModel>((ref) async {
  final response = await DioClient.instance.get(ApiConstants.wallet);
  return WalletModel.fromJson(response.data);
});

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  bool _showWithdraw = false;
  bool _withdrawLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestWithdrawal() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingresa un monto válido'),
            backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _withdrawLoading = true);
    try {
      await DioClient.instance.post(ApiConstants.withdrawal, data: {
        'monto': amount,
        'cuenta_destino': _accountCtrl.text,
      });
      if (mounted) {
        setState(() => _showWithdraw = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Solicitud de retiro enviada correctamente'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        ref.invalidate(walletProvider);
        _amountCtrl.clear();
        _accountCtrl.clear();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _withdrawLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mi Billetera'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Balance card
                walletAsync.when(
                  data: (wallet) => _BalanceCard(wallet: wallet),
                  loading: () => const _LoadingCard(),
                  error: (e, _) => _ErrorCard(
                    onRetry: () => ref.invalidate(walletProvider),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.invalidate(walletProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Actualizar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _showWithdraw = true),
                        icon: const Icon(Icons.account_balance_rounded,
                            size: 18),
                        label: const Text('Retirar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Info section
                const _InfoSection(),
              ],
            ),
          ),

          // Withdrawal modal
          if (_showWithdraw) ...[
            GestureDetector(
              onTap: () => setState(() => _showWithdraw = false),
              child: Container(color: Colors.black54),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    MediaQuery.of(context).padding.bottom + 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Solicitar Retiro',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20)),
                    const SizedBox(height: 20),
                    const Text('Monto a retirar',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '\$ ',
                        hintText: '0.00',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Cuenta destino (CBU/CVU)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _accountCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Ingresa tu CBU o CVU',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed:
                          _withdrawLoading ? null : _requestWithdrawal,
                      child: _withdrawLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                          : const Text('Confirmar Retiro'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final WalletModel wallet;
  const _BalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo Disponible',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              '\$ ${wallet.disponible.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_empty_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Retenido: \$ ${wallet.retenido.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error),
              TextButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar')),
            ],
          ),
        ),
      );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Cómo funciona?',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            _InfoRow(
                icon: Icons.lock_clock_rounded,
                text:
                    'El saldo retenido se libera 24h después del check-out.'),
            _InfoRow(
                icon: Icons.account_balance_rounded,
                text:
                    'Los retiros se procesan en 1-3 días hábiles.'),
            _InfoRow(
                icon: Icons.shield_outlined,
                text: 'Todas las transacciones están protegidas.'),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12))),
          ],
        ),
      );
}
