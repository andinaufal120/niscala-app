import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala_api/api.dart';

/// The text and colour of one complaint badge. The label is what the user
/// reads; the tone only reinforces it.
typedef ComplaintBadgeStyle = ({String label, StatusTone tone});

/// The one table of complaint labels. Every complaint screen reads its badges
/// from these maps, so a status has the same text everywhere.
const complaintStatusStyles = <ComplaintStatus, ComplaintBadgeStyle>{
  ComplaintStatus.new_: (label: 'Baru', tone: StatusTone.warning),
  ComplaintStatus.inProgress: (label: 'Diproses', tone: StatusTone.info),
  ComplaintStatus.done: (label: 'Selesai', tone: StatusTone.success),
};

const complaintUrgencyStyles = <ComplaintUrgency, ComplaintBadgeStyle>{
  ComplaintUrgency.low: (label: 'Rendah', tone: StatusTone.neutral),
  ComplaintUrgency.medium: (label: 'Sedang', tone: StatusTone.warning),
  ComplaintUrgency.high: (label: 'Tinggi', tone: StatusTone.danger),
};

const complaintClassificationStyles =
    <ComplaintClassificationState, ComplaintBadgeStyle>{
      ComplaintClassificationState.classifying: (
        label: 'Sedang Diklasifikasi',
        tone: StatusTone.info,
      ),
      ComplaintClassificationState.awaitingClassification: (
        label: 'Menunggu Klasifikasi',
        tone: StatusTone.warning,
      ),
      ComplaintClassificationState.notClassified: (
        label: 'Belum Diklasifikasi',
        tone: StatusTone.neutral,
      ),
    };
