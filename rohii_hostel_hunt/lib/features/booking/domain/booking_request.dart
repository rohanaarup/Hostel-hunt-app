enum BookingRequestStatus { pending, confirmed, paid, cancelled, rejected, unknown }

/// One of the signed-in student's bookings, from GET /bookings/my/.
class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.hostelName,
    required this.roomLabel,
    required this.rawStatus,
    required this.status,
    required this.amount,
    required this.paymentMode,
    required this.createdAt,
  });

  final String id;
  final String hostelName;

  /// "Room 101", or empty when the booking has no room on it.
  final String roomLabel;

  /// The status exactly as the server sent it.
  final String rawStatus;
  final BookingRequestStatus status;
  final double? amount;

  /// 'online' or 'offline'.
  final String paymentMode;
  final DateTime? createdAt;

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    final raw = (json['status'] as String? ?? '').trim();
    final room = (json['room_display'] ?? json['room_name']) as String?;
    return BookingRequest(
      id: json['id']?.toString() ?? '',
      hostelName: (json['hostel_name'] as String?)?.trim().isNotEmpty == true ? json['hostel_name'] as String : 'Hostel',
      roomLabel: (room ?? '').trim(),
      rawStatus: raw,
      status: _statusOf(raw),
      amount: json['amount'] == null ? null : double.tryParse(json['amount'].toString()),
      paymentMode: json['payment_mode'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
    );
  }

  static BookingRequestStatus _statusOf(String raw) {
    switch (raw) {
      case 'pending':
        return BookingRequestStatus.pending;
      case 'confirmed':
        return BookingRequestStatus.confirmed;
      case 'paid':
        return BookingRequestStatus.paid;
      case 'cancelled':
        return BookingRequestStatus.cancelled;
      case 'rejected':
        return BookingRequestStatus.rejected;
    }
    return BookingRequestStatus.unknown;
  }

  /// "Pending", "Confirmed"...; a status this app does not know is shown readably, not hidden.
  String get statusLabel {
    switch (status) {
      case BookingRequestStatus.pending:
        return 'Pending';
      case BookingRequestStatus.confirmed:
        return 'Confirmed';
      case BookingRequestStatus.paid:
        return 'Paid';
      case BookingRequestStatus.cancelled:
        return 'Cancelled';
      case BookingRequestStatus.rejected:
        return 'Rejected';
      case BookingRequestStatus.unknown:
        final text = rawStatus.replaceAll('_', ' ').trim();
        return text.isEmpty ? 'Unknown' : '${text[0].toUpperCase()}${text.substring(1)}';
    }
  }

  /// "₹1,50,000" (Indian digit grouping), or empty when there is no amount.
  String get amountLabel {
    final value = amount;
    if (value == null) return '';
    final digits = value.round().toString();
    if (digits.length <= 3) return '₹$digits';
    final head = digits.substring(0, digits.length - 3);
    final grouped = head.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+$)'), (m) => '${m[1]},');
    return '₹$grouped,${digits.substring(digits.length - 3)}';
  }

  /// "15 Oct 2026", or empty when the date is missing.
  String get submittedOn {
    final date = createdAt;
    if (date == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
