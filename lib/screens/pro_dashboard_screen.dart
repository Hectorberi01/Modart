import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_bento_card.dart';
import '../widgets/mesh_gradient_background.dart';

class ProDashboardScreen extends StatelessWidget {
  const ProDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MeshGradientBackground(
      biState: BIState.navy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Espace Professionnel', style: textTheme.headlineMedium),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassBentoCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          color: SmartSoleColors.biNavy,
                        ),
                        const SizedBox(width: 8),
                        Text('Outils de suivi', style: textTheme.titleLarge!),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Retrouvez ici la liste de vos patients et accédez à leurs rapports d\'analyse biomécanique rapides.',
                      style: textTheme.bodyMedium?.copyWith(
                        color:
                            isDark
                                ? SmartSoleColors.textSecondaryDark
                                : SmartSoleColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Patients Récents', style: textTheme.headlineSmall!),
              const SizedBox(height: 12),
              _buildPatientCard(
                context,
                'Lucas M.',
                'Examen pédiatrique - IMM',
                'Hier, 14:30',
                isDark,
              ),
              const SizedBox(height: 12),
              _buildPatientCard(
                context,
                'Thomas G.',
                'Suivi post-opératoire',
                '12 Mars, 10:00',
                isDark,
              ),
              const SizedBox(height: 12),
              _buildPatientCard(
                context,
                'Sophie L.',
                'Bilan préventif running',
                '10 Mars, 16:15',
                isDark,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    'Générer un rapport global',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmartSoleColors.biNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    String name,
    String motif,
    String date,
    bool isDark,
  ) {
    return GlassBentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: SmartSoleColors.biNavy.withValues(alpha: 0.15),
            foregroundColor: SmartSoleColors.biNavy,
            child: Text(name.substring(0, 1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  motif,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SmartSoleColors.biNavy,
                  ),
                ),
              ],
            ),
          ),
          Text(date, style: Theme.of(context).textTheme.labelSmall!),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ],
      ),
    );
  }
}
