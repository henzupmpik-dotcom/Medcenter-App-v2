import 'package:medcenter/shared/widgets/loading_overlay.dart';

// Alias so invoice_detail_screen.dart can use InfoRow(label:, value:)
class InfoRow extends InfoRowWidget {
  const InfoRow({super.key, required String label, required String value})
      : super(label, value);
}
