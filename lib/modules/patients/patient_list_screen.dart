import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medcenter/modules/patients/patient_repository.dart';
import 'package:medcenter/shared/app_theme.dart';
import 'package:medcenter/shared/models/patient_model.dart';
import 'package:medcenter/shared/widgets/empty_state.dart';

final _patientSearchProvider = StateProvider<String>((ref) => '');

final _patientsProvider = FutureProvider.family<List<PatientModel>, String>((ref, query) async {
  if (query.isEmpty) return PatientRepository.instance.getAll();
  return PatientRepository.instance.search(query);
});

class PatientListScreen extends ConsumerWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_patientSearchProvider);
    final patientsAsync = ref.watch(_patientsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'New Patient',
            onPressed: () => context.go('/patients/new'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) =>
                  ref.read(_patientSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search name, file no., phone, ID...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (patients) {
          if (patients.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              message: query.isEmpty ? 'No patients yet' : 'No results for "$query"',
              action: query.isEmpty
                  ? ElevatedButton.icon(
                      onPressed: () => context.go('/patients/new'),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Register First Patient'),
                    )
                  : null,
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(_patientsProvider(query)),
            child: ListView.builder(
              itemCount: patients.length,
              itemBuilder: (_, i) => _PatientTile(patient: patients[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/patients/new'),
        icon: const Icon(Icons.person_add),
        label: const Text('New Patient'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final PatientModel patient;
  const _PatientTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    final age = patient.age;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightBlue,
          radius: 24,
          child: Text(
            patient.fullName[0].toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(patient.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(patient.fileNumber,
                style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                    fontSize: 12)),
            if (patient.phone != null)
              Text(patient.phone!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (age != null)
              Text('$age yrs',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            if (patient.gender != null)
              Text(patient.gender!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        onTap: () => context.go('/patients/${patient.id}'),
      ),
    );
  }
}
