import 'dart:convert';

enum BorrowStatus {
  pending,   // Chờ chủ sở hữu phê duyệt
  approved,  // Đã phê duyệt, sẵn sàng lấy sách/tài liệu
  rejected,  // Bị từ chối
  borrowed,  // Đang trong quá trình mượn
  returned,  // Đã hoàn trả
  overdue;   // Quá hạn mượn

  String get displayName {
    switch (this) {
      case BorrowStatus.pending:
        return 'Chờ phê duyệt';
      case BorrowStatus.approved:
        return 'Đã duyệt mượn';
      case BorrowStatus.rejected:
        return 'Đã từ chối';
      case BorrowStatus.borrowed:
        return 'Đang mượn';
      case BorrowStatus.returned:
        return 'Đã hoàn trả';
      case BorrowStatus.overdue:
        return 'Quá hạn mượn';
    }
  }

  static BorrowStatus fromString(String? val) {
    if (val == null) return BorrowStatus.pending;
    return BorrowStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => BorrowStatus.pending,
    );
  }
}

class BorrowRequest {
  final String id;
  final String documentId;
  final String documentTitle;
  final String courseCode;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String borrowerId;
  final String borrowerName;
  final String borrowerEmail;
  final DateTime requestDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final BorrowStatus status;
  final String notes;

  BorrowRequest({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    this.courseCode = 'SE301',
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.borrowerId,
    required this.borrowerName,
    required this.borrowerEmail,
    DateTime? requestDate,
    DateTime? dueDate,
    this.returnDate,
    this.status = BorrowStatus.pending,
    this.notes = '',
  })  : requestDate = requestDate ?? DateTime.now(),
        dueDate = dueDate ?? DateTime.now().add(const Duration(days: 7));

  bool get isPending => status == BorrowStatus.pending;
  bool get isApproved => status == BorrowStatus.approved || status == BorrowStatus.borrowed;
  bool get isOverdue => status == BorrowStatus.overdue || (status == BorrowStatus.borrowed && DateTime.now().isAfter(dueDate));

  BorrowRequest copyWith({
    String? id,
    String? documentId,
    String? documentTitle,
    String? courseCode,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    String? borrowerId,
    String? borrowerName,
    String? borrowerEmail,
    DateTime? requestDate,
    DateTime? dueDate,
    DateTime? returnDate,
    BorrowStatus? status,
    String? notes,
  }) {
    return BorrowRequest(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
      courseCode: courseCode ?? this.courseCode,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      borrowerId: borrowerId ?? this.borrowerId,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerEmail: borrowerEmail ?? this.borrowerEmail,
      requestDate: requestDate ?? this.requestDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'document_id': documentId,
    'document_title': documentTitle,
    'course_code': courseCode,
    'owner_id': ownerId,
    'owner_name': ownerName,
    'owner_email': ownerEmail,
    'borrower_id': borrowerId,
    'borrower_name': borrowerName,
    'borrower_email': borrowerEmail,
    'request_date': requestDate.toIso8601String(),
    'due_date': dueDate.toIso8601String(),
    'return_date': returnDate?.toIso8601String(),
    'status': status.name,
    'notes': notes,
  };

  factory BorrowRequest.fromMap(Map<String, dynamic> map) => BorrowRequest(
    id: map['id']?.toString() ?? '',
    documentId: map['document_id']?.toString() ?? '',
    documentTitle: map['document_title']?.toString() ?? 'Tài liệu không tên',
    courseCode: map['course_code']?.toString() ?? 'SE301',
    ownerId: map['owner_id']?.toString() ?? '',
    ownerName: map['owner_name']?.toString() ?? '',
    ownerEmail: map['owner_email']?.toString() ?? '',
    borrowerId: map['borrower_id']?.toString() ?? '',
    borrowerName: map['borrower_name']?.toString() ?? '',
    borrowerEmail: map['borrower_email']?.toString() ?? '',
    requestDate: map['request_date'] != null ? DateTime.tryParse(map['request_date'].toString()) ?? DateTime.now() : DateTime.now(),
    dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'].toString()) ?? DateTime.now().add(const Duration(days: 7)) : DateTime.now().add(const Duration(days: 7)),
    returnDate: map['return_date'] != null ? DateTime.tryParse(map['return_date'].toString()) : null,
    status: BorrowStatus.fromString(map['status']?.toString()),
    notes: map['notes']?.toString() ?? '',
  );

  String toJson() => jsonEncode(toMap());
  factory BorrowRequest.fromJson(String source) => BorrowRequest.fromMap(jsonDecode(source));
}
