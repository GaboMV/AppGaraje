import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/garage_create_provider.dart';
import '../providers/my_garages_provider.dart';
import 'steps/garage_location_step.dart';
import 'steps/garage_details_step.dart';
import 'steps/garage_pricing_step.dart';
import 'steps/garage_availability_step.dart';

class GarageCreateWizard extends ConsumerStatefulWidget {
  const GarageCreateWizard({super.key});

  @override
  ConsumerState<GarageCreateWizard> createState() =>
      _GarageCreateWizardState();
}

class _GarageCreateWizardState extends ConsumerState<GarageCreateWizard> {
  late final PageController _pageController;

  final List<String> _titles = [
    'Ubicación del Garaje',
    'Detalles del Garaje',
    'Precios y Servicios',
    'Disponibilidad',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Reset wizard state on creation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(garageCreateProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    ref.read(garageCreateProvider.notifier).goToStep(page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _next() => _goToPage(ref.read(garageCreateProvider).step + 1);
  void _back() {
    final step = ref.read(garageCreateProvider).step;
    if (step > 0) {
      _goToPage(step - 1);
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    final success =
        await ref.read(garageCreateProvider.notifier).submit();
    if (!mounted) return;
    if (success) {
      // Refresh the list
      await ref.read(myGaragesProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Garaje publicado exitosamente! 🎉'),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(garageCreateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Error al crear el garaje'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(garageCreateProvider);
    final currentStep = state.step;
    final totalSteps = _titles.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_titles[currentStep]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _back,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _StepIndicator(
              current: currentStep, total: totalSteps),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          GarageLocationStep(onNext: _next),
          GarageDetailsStep(onNext: _next),
          GaragePricingStep(onNext: _next),
          GarageAvailabilityStep(onSubmit: _submit),
        ],
      ),
    );
  }
}

// ─── Step Indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paso ${current + 1}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                '${current + 1} de $total',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (current + 1) / total,
              minHeight: 4,
              backgroundColor: AppTheme.border,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
