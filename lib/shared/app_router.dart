import 'package:go_router/go_router.dart';
import 'package:medcenter/core/config/clinic_config.dart';
import 'package:medcenter/core/security/auth_service.dart';
import 'package:medcenter/modules/dashboard/dashboard_screen.dart';
import 'package:medcenter/modules/setup/create_clinic_screen.dart';
import 'package:medcenter/modules/setup/join_clinic_screen.dart';
import 'package:medcenter/modules/setup/welcome_screen.dart';
import 'package:medcenter/modules/staff/login_screen.dart';
import 'package:medcenter/modules/staff/staff_list_screen.dart';
import 'package:medcenter/modules/staff/staff_form_screen.dart';
import 'package:medcenter/shared/widgets/main_shell.dart';
import 'package:medcenter/modules/patients/patient_list_screen.dart';
import 'package:medcenter/modules/patients/patient_form_screen.dart';
import 'package:medcenter/modules/patients/patient_detail_screen.dart';
import 'package:medcenter/modules/consultations/consultation_form_screen.dart';
import 'package:medcenter/modules/consultations/consultation_detail_screen.dart';
import 'package:medcenter/modules/prescriptions/prescription_form_screen.dart';
import 'package:medcenter/modules/prescriptions/prescription_detail_screen.dart';
import 'package:medcenter/modules/billing/billing_list_screen.dart';
import 'package:medcenter/modules/billing/invoice_form_screen.dart';
import 'package:medcenter/modules/billing/invoice_detail_screen.dart';
import 'package:medcenter/modules/billing/payment_screen.dart';
import 'package:medcenter/modules/appointments/appointment_list_screen.dart';
import 'package:medcenter/modules/appointments/appointment_form_screen.dart';
import 'package:medcenter/modules/settings/clinic_settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final configured = ClinicConfig.instance.isConfigured;
    final loggedIn = AuthService.instance.isLoggedIn;
    final path = state.uri.path;

    if (!configured && !path.startsWith('/setup')) return '/setup';
    if (configured && !loggedIn && path != '/login') return '/login';
    if (loggedIn && (path == '/login' || path == '/')) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/home'),

    // Setup
    GoRoute(path: '/setup', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/setup/create', builder: (_, __) => const CreateClinicScreen()),
    GoRoute(path: '/setup/join', builder: (_, __) => const JoinClinicScreen()),

    // Auth
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

    // Main shell — V2: 5 tabs (Home, Patients, Appointments, Staff, Settings)
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        // Home Dashboard (V2 NEW)
        GoRoute(
          path: '/home',
          builder: (_, __) => const DashboardScreen(),
        ),

        // Patients
        GoRoute(
          path: '/patients',
          builder: (_, __) => const PatientListScreen(),
          routes: [
            GoRoute(path: 'new', builder: (_, __) => const PatientFormScreen()),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  PatientDetailScreen(patientId: state.pathParameters['id']!),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, state) =>
                      PatientFormScreen(patientId: state.pathParameters['id']),
                ),
                GoRoute(
                  path: 'consultation/new',
                  builder: (_, state) =>
                      ConsultationFormScreen(patientId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'prescription/new',
                  builder: (_, state) =>
                      PrescriptionFormScreen(patientId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'invoice/new',
                  builder: (_, state) =>
                      InvoiceFormScreen(patientId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),

        // Appointments
        GoRoute(
          path: '/appointments',
          builder: (_, __) => const AppointmentListScreen(),
          routes: [
            GoRoute(path: 'new', builder: (_, __) => const AppointmentFormScreen()),
          ],
        ),

        // Consultations
        GoRoute(
          path: '/consultations/:id',
          builder: (_, state) =>
              ConsultationDetailScreen(consultationId: state.pathParameters['id']!),
        ),

        // Prescriptions
        GoRoute(
          path: '/prescriptions/:id',
          builder: (_, state) =>
              PrescriptionDetailScreen(prescriptionId: state.pathParameters['id']!),
        ),

        // Billing list (V2 NEW — for dashboard Quick Actions nav)
        GoRoute(
          path: '/billing/list',
          builder: (_, __) => const BillingListScreen(),
        ),

        // Billing detail + payment
        GoRoute(
          path: '/billing/:id',
          builder: (_, state) =>
              InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/billing/:id/pay',
          builder: (_, state) =>
              PaymentScreen(invoiceId: state.pathParameters['id']!),
        ),

        // Staff
        GoRoute(
          path: '/staff',
          builder: (_, __) => const StaffListScreen(),
          routes: [
            GoRoute(path: 'new', builder: (_, __) => const StaffFormScreen()),
            GoRoute(
              path: ':id/edit',
              builder: (_, state) =>
                  StaffFormScreen(userId: state.pathParameters['id']),
            ),
          ],
        ),

        // Settings
        GoRoute(
          path: '/settings',
          builder: (_, __) => const ClinicSettingsScreen(),
        ),
      ],
    ),
  ],
);
