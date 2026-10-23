import 'package:niscala/core/tokens.dart';
import 'package:niscala_api/api.dart';

/// The text and colour token of one complaint badge. The label is what the
/// user reads; the colours only reinforce it.
typedef ComplaintBadgeStyle = ({
  String label,
  BadgeColors Function(NiscalaTokens) colors,
});

/// The one table of complaint labels. Every complaint screen reads its badges
/// from these maps, so a status has the same text everywhere.
final complaintStatusStyles = <ComplaintStatus, ComplaintBadgeStyle>{
  ComplaintStatus.new_: (label: 'Baru', colors: (t) => t.complaintNew),
  ComplaintStatus.inProgress: (
    label: 'Diproses',
    colors: (t) => t.complaintInProgress,
  ),
  ComplaintStatus.done: (label: 'Selesai', colors: (t) => t.complaintDone),
};

final complaintUrgencyStyles = <ComplaintUrgency, ComplaintBadgeStyle>{
  ComplaintUrgency.low: (label: 'Rendah', colors: (t) => t.urgencyLow),
  ComplaintUrgency.medium: (label: 'Sedang', colors: (t) => t.urgencyMedium),
  ComplaintUrgency.high: (label: 'Tinggi', colors: (t) => t.urgencyHigh),
};

final complaintClassificationStyles =
    <ComplaintClassificationState, ComplaintBadgeStyle>{
      ComplaintClassificationState.classifying: (
        label: 'Sedang Diklasifikasi',
        colors: (t) => t.classificationClassifying,
      ),
      ComplaintClassificationState.awaitingClassification: (
        label: 'Menunggu Klasifikasi',
        colors: (t) => t.classificationAwaiting,
      ),
      ComplaintClassificationState.notClassified: (
        label: 'Belum Diklasifikasi',
        colors: (t) => t.classificationNotClassified,
      ),
    };
