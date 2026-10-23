import '../database/study_course_dao.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document_permission.dart';
import '../models/supabase_user.dart';
import '../services/firebase_auth_service.dart';
import '../services/supabase_service.dart';
import '../struct/studyCourse.dart';
import '../struct/studyDocument.dart';
import '../models/borrow_request.dart';
import '../models/physical_location.dart';
import '../widgets/interactive_location_map.dart';
import '../services/notification_service.dart';
import '../pages/addEditStudyDocumentPage.dart';
import 'package:url_launcher/url_launcher.dart';
class StudyDocumentCard extends StatelessWidget {
  final StudyDocument document;
  final ValueChanged<DocumentStatus>? onStatusChanged;
  final VoidCallback? onDelete;
  final Course? course;
  final VoidCallback? onTap;

  const StudyDocumentCard({
    super.key,
    required this.document,
    this.onStatusChanged,
    this.onDelete,
    this.course,
    this.onTap,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _getTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.lecture:
        return Colors.blue;
      case DocumentType.exercise:
        return Colors.orange;
      case DocumentType.reference:
        return Colors.teal;
    }
  }

  String _getTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.lecture:
        return "Bài giảng";
      case DocumentType.exercise:
        return "Bài tập";
      case DocumentType.reference:
        return "Tài liệu tham khảo";
    }
  }

  IconData _getTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.lecture:
        return Icons.menu_book_rounded;
      case DocumentType.exercise:
        return Icons.assignment_rounded;
      case DocumentType.reference:
        return Icons.auto_stories_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _getTypeColor(document.type);
    final isDone = document.status == DocumentStatus.completed;
    final isOverdue = document.deadline != null &&
        document.deadline!.isBefore(DateTime.now()) &&
        !isDone;

    final courseDao = CourseDao();
    final Course? resolvedCourse = course ?? (document.courseId.isNotEmpty
        ? courseDao.getById(document.courseId)
        : null);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditDocumentPage(initialDocument: document),
                  ),
                );
              },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getTypeIcon(document.type), size: 13, color: typeColor),
                          const SizedBox(width: 5),
                          Text(
                            _getTypeLabel(document.type),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: typeColor),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),
                    _buildPermissionBadge(),
                    if (resolvedCourse != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(resolvedCourse.colorValue).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          resolvedCourse.code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(resolvedCourse.colorValue),
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    if (document.isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.push_pin_rounded, size: 16, color: Colors.amber),
                      ),

                    if (document.isSynced)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.cloud_done_rounded, size: 16, color: Colors.teal),
                      ),

                    // Nút Chia sẻ trực tiếp trên thẻ
                    IconButton(
                      icon: Icon(
                        Icons.share_rounded,
                        size: 19,
                        color: (document.isOwner || document.canShare) ? const Color(0xFF1976D2) : Colors.grey.shade400,
                      ),
                      tooltip: (document.isOwner || document.canShare) ? 'Chia sẻ tài liệu (RLS)' : 'Chưa có quyền chia sẻ',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (document.isOwner || document.canShare) {
                          _showShareDialog(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '⚠️ Bạn chỉ có quyền [${document.permissionsSummary}]. Để chia sẻ tài liệu này, vui lòng nhờ Chủ sở hữu (${document.ownerName}) cấp thêm [Quyền Chia sẻ (Sharer)] nhé!',
                              ),
                              backgroundColor: Colors.orange.shade800,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 4),

                    // Phân quyền menu hành động dựa trên RLS
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditDocumentPage(initialDocument: document),
                            ),
                          );
                        } else if (val == 'share') {
                          if (document.isOwner || document.canShare) {
                            _showShareDialog(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '⚠️ Bạn chỉ có quyền [${document.permissionsSummary}]. Để chia sẻ tài liệu này, vui lòng nhờ Chủ sở hữu (${document.ownerName}) cấp thêm [Quyền Chia sẻ (Sharer)] nhé!',
                                ),
                                backgroundColor: Colors.orange.shade800,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } else if (val == 'delete' && onDelete != null) {
                          onDelete!();
                        } else if (val == 'view_info') {
                          _showViewOnlyDialog(context);
                        } else if (val == 'view_map') {
                          _showLocationMapDialog(context);
                        } else if (val == 'borrow') {
                          _showBorrowDialog(context);
                        }
                      },
                      itemBuilder: (context) {
                        final items = <PopupMenuEntry<String>>[];

                        if (document.isOwner) {
                          items.add(const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Chỉnh sửa tài liệu'),
                              ],
                            ),
                          ));
                          items.add(const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share_rounded, size: 16, color: Color(0xFF1976D2)),
                                SizedBox(width: 8),
                                Text('Chia sẻ quyền (RLS)', style: TextStyle(color: Color(0xFF1976D2))),
                              ],
                            ),
                          ));
                          items.add(const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Xóa tài liệu', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ));
                        } else {
                          if (document.canEdit) {
                            items.add(const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16, color: Color(0xFFE65100)),
                                  SizedBox(width: 8),
                                  Text('Chỉnh sửa (Quyền Editor)', style: TextStyle(color: Color(0xFFE65100))),
                                ],
                              ),
                            ));
                          }
                          items.add(PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share_rounded, size: 16, color: document.canShare ? const Color(0xFF1976D2) : Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  document.canShare ? 'Chia sẻ quyền (Quyền Sharer)' : 'Chia sẻ quyền (Chưa có quyền)',
                                  style: TextStyle(color: document.canShare ? const Color(0xFF1976D2) : Colors.grey),
                                ),
                              ],
                            ),
                          ));
                          if (document.canDelete) {
                            items.add(const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Xóa tài liệu (Quyền Deleter)', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ));
                          }
                          items.add(const PopupMenuItem(
                            value: 'view_map',
                            child: Row(
                              children: [
                                Icon(Icons.map_rounded, size: 16, color: Colors.teal),
                                SizedBox(width: 8),
                                Text('Xem bản đồ vị trí (TH2)', style: TextStyle(color: Colors.teal)),
                              ],
                            ),
                          ));
                          if (!document.isOwner) {
                            items.add(const PopupMenuItem(
                              value: 'borrow',
                              child: Row(
                                children: [
                                  Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFFD81B60)),
                                  SizedBox(width: 8),
                                  Text('Yêu cầu mượn tài liệu', style: TextStyle(color: Color(0xFFD81B60))),
                                ],
                              ),
                            ));
                          }
                          items.add(const PopupMenuItem(
                            value: 'view_info',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 16, color: Colors.teal),
                                SizedBox(width: 8),
                                Text('Xem chi tiết (Thông tin)', style: TextStyle(color: Colors.teal)),
                              ],
                            ),
                          ));
                        }
                        return items;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Title
                Text(
                  document.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    // decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (document.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    document.description,
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (document.fileUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD81B60).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_done_rounded, size: 13, color: Color(0xFFD81B60)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Firebase Storage: ' + (document.fileUrl.contains('documents') ? document.fileUrl.split('documents').last.split('?').first.replaceAll('%2F', '/') : 'Tệp Cloud đính kèm'),
                            style: const TextStyle(fontSize: 10, color: Color(0xFFD81B60), fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (document.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: document.tags.map((tag) {
                      final cleanTag = tag.trim().startsWith('#') ? tag.trim() : '#${tag.trim()}';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blueGrey.shade200),
                        ),
                        child: Text(
                          cleanTag,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade800),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (document.physicalLocation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showLocationMapDialog(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: Colors.teal),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${document.physicalLocation} (${document.shelfLocation})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_rounded, size: 10, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  'Bản đồ & Kệ',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Tooltip(
                            message: 'Mở vị trí trực tiếp trên Google Maps',
                            child: InkWell(
                              onTap: () => _launchGoogleMapsDirect(context),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A73E8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.open_in_new_rounded, size: 10, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'Google Maps',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Footer: Deadline, Status, Toggle
                Row(
                  children: [
                    if (document.deadline != null) ...[
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(document.deadline!),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey.shade700,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    _buildStatusBadge(document.status),

                    const Spacer(),

                    // Toggle complete button
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (onStatusChanged != null) {
                          onStatusChanged!(
                            isDone ? DocumentStatus.inProgress : DocumentStatus.completed,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDone ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 14,
                              color: isDone ? Colors.green.shade700 : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isDone ? 'Đã xong' : 'Hoàn thành',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDone ? Colors.green.shade700 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DocumentStatus status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case DocumentStatus.completed:
        bg = Colors.green.withOpacity(0.12);
        fg = Colors.green.shade700;
        label = 'Đã hoàn thành';
        break;
      case DocumentStatus.inProgress:
        bg = Colors.amber.withOpacity(0.15);
        fg = Colors.orange.shade800;
        label = 'Đang học';
        break;
      case DocumentStatus.todo:
        bg = Colors.grey.withOpacity(0.12);
        fg = Colors.grey.shade700;
        label = 'Cần học';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  
  Widget _buildPermissionBadge() {
    if (document.isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_rounded, size: 12, color: Colors.green),
            SizedBox(width: 4),
            Text('Của bạn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      );
    }

    final from = document.ownerName.isNotEmpty ? document.ownerName : document.ownerEmail;
    final List<String> grantedNames = [];
    if (document.canView) grantedNames.add('Xem');
    if (document.canEdit) grantedNames.add('Sửa');
    if (document.canDelete) grantedNames.add('Xóa');
    if (document.canShare) grantedNames.add('Chia sẻ');

    final String badgeText = grantedNames.join(' & ');
    final isSharer = document.canShare;
    final isEditor = document.canEdit;

    final Color bgColor = isSharer ? const Color(0xFFEDE7F6) : (isEditor ? const Color(0xFFFFF3E0) : const Color(0xFFE0F2F1));
    final Color borderColor = isSharer ? Colors.deepPurple.shade300 : (isEditor ? Colors.orange.shade300 : Colors.teal.shade300);
    final Color textColor = isSharer ? Colors.deepPurple.shade900 : (isEditor ? Colors.orange.shade900 : Colors.teal.shade900);
    final IconData icon = isSharer ? Icons.share_rounded : (isEditor ? Icons.edit_note_rounded : Icons.visibility_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            'Được chia sẻ: $badgeText (từ $from)',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Future<void> _launchGoogleMapsDirect(BuildContext context) async {
    final lat = document.latitude != 0.0 ? document.latitude : 10.8700;
    final lng = document.longitude != 0.0 ? document.longitude : 106.8030;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched) await launchUrl(uri);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Đang mở Google Maps: $lat, $lng'),
            backgroundColor: const Color(0xFF1976D2),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở Google Maps: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showLocationMapDialog(BuildContext context) {
    final loc = PhysicalLocation(
      locationName: document.physicalLocation.isNotEmpty ? document.physicalLocation : 'Thư viện Trung tâm - Tòa H1',
      shelfNumber: document.shelfLocation.isNotEmpty ? document.shelfLocation : 'Kệ A3 - Ngăn 02',
      latitude: document.latitude != 0.0 ? document.latitude : 10.8700,
      longitude: document.longitude != 0.0 ? document.longitude : 106.8030,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InteractiveLocationMap(
                location: loc,
                documentTitle: document.title,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBorrowDialog(BuildContext context) {
    final auth = FirebaseAuthService();
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final noteController = TextEditingController();
    int borrowDays = 7;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFFD81B60), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yêu cầu Mượn Tài liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Gửi yêu cầu mượn bản cứng/vật lý đến Chủ sở hữu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tài liệu: ${document.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Chủ sở hữu: ${document.ownerName} (${document.ownerEmail})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('Vị trí hiện tại: ${document.physicalLocation} (${document.shelfLocation})', style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Thời hạn mượn dự kiến:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [7, 14, 30].map((days) {
                        final isSel = borrowDays == days;
                        return ChoiceChip(
                          label: Text('$days ngày'),
                          selected: isSel,
                          selectedColor: const Color(0xFFD81B60),
                          labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 12),
                          onSelected: (_) => setDialogState(() => borrowDays = days),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ghi chú cho Chủ sở hữu (tùy chọn):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Mình mượn để ôn thi giữa kỳ tuần tới...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(isSubmitting ? 'Đang gửi...' : 'GỬI YÊU CẦU MƯỢN'),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final req = BorrowRequest(
                            id: 'br-${DateTime.now().millisecondsSinceEpoch}',
                            documentId: document.id,
                            documentTitle: document.title,
                            courseCode: document.courseId,
                            ownerId: document.ownerId,
                            ownerName: document.ownerName,
                            ownerEmail: document.ownerEmail,
                            borrowerId: currentUser.id,
                            borrowerName: currentUser.displayName,
                            borrowerEmail: currentUser.email,
                            dueDate: DateTime.now().add(Duration(days: borrowDays)),
                            notes: noteController.text.trim(),
                          );

                          final ok = await SupabaseService().createBorrowRequest(req);
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            NotificationService().addNotification(
                              title: 'Đã gửi yêu cầu mượn',
                              message: 'Đã gửi yêu cầu mượn tài liệu "${document.title}" đến ${document.ownerName}',
                              color: Colors.green,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? '✅ Đã gửi yêu cầu mượn thành công! Vui lòng chờ ${document.ownerName} phê duyệt.'
                                    : '❌ Có lỗi khi gửi yêu cầu mượn lên hệ thống!'),
                                backgroundColor: ok ? Colors.green.shade700 : Colors.red,
                              ),
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showViewOnlyDialog(BuildContext context) {
    final courseDao = CourseDao();
    final Course? resCourse = course ?? (document.courseId.isNotEmpty ? courseDao.getById(document.courseId) : null);
    final deadlineStr = document.deadline != null ? DateFormat('dd/MM/yyyy').format(document.deadline!) : 'Chưa đặt hạn nộp';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_rounded, color: Color(0xFF1976D2), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Chi tiết toàn bộ thông tin tài liệu & Phân quyền', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Thông tin Chủ sở hữu & Nguồn gốc
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chủ sở hữu: ${document.ownerName} (${document.ownerEmail})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Môn học, Loại tài liệu & Trạng thái
                Row(
                  children: [
                    if (resCourse != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Color(resCourse.colorValue).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${resCourse.code} - ${resCourse.name}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(resCourse.colorValue))),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _getTypeColor(document.type).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_getTypeLabel(document.type), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getTypeColor(document.type))),
                    ),
                    _buildStatusBadge(document.status),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Hạn nộp (Deadline)
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Hạn nộp: $deadlineStr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Mô tả chi tiết
                const Text('Mô tả chi tiết:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    document.description.isNotEmpty ? document.description : '(Không có mô tả chi tiết)',
                    style: TextStyle(fontSize: 12, color: document.description.isNotEmpty ? Colors.black87 : Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Tệp đính kèm Cloud Firebase Storage
                if (document.fileUrl.isNotEmpty) ...[
                  const Text('Tệp đính kèm Cloud (Firebase Storage):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF7F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF3C4D4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_download_rounded, color: Color(0xFFD81B60), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            document.fileUrl,
                            style: const TextStyle(fontSize: 11, color: Color(0xFFD81B60), fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 5.5 Vị trí vật lý & Bản đồ Kệ sách TH2
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _showLocationMapDialog(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: Colors.teal),
                              const SizedBox(width: 4),
                              Text(
                                '${document.physicalLocation} (${document.shelfLocation})',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map_rounded, size: 10, color: Colors.teal),
                                    SizedBox(width: 2),
                                    Text('Bản đồ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.teal)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!document.isOwner)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD81B60),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 13),
                          label: const Text('Mượn tài liệu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () => _showBorrowDialog(context),
                        ),
                    ],
                  ),
                ),

                // 6. Thẻ Tags
                if (document.tags.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 15, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: document.tags.map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // 7. MẢNG CÁC QUYỀN HẠN ĐƯỢC CẤP (RLS)
                const Text('Danh sách quyền hạn của bạn (Row Level Security):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildPermBadge('Quyền Xem', true, Colors.teal),
                          _buildPermBadge('Quyền Sửa', document.canEdit, Colors.orange),
                          _buildPermBadge('Quyền Xóa', document.canDelete, Colors.red),
                          _buildPermBadge('Quyền Chia sẻ', document.canShare, Colors.indigo),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Theo phân quyền trên Supabase: Bạn ${document.canEdit ? "có quyền chỉnh sửa" : "chỉ được xem"}, ${document.canDelete ? "được phép xóa" : "không được xóa"}, và ${document.canShare ? "được phép tiếp tục chia sẻ cho người khác." : "không được phép chia sẻ tiếp."}',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(document.canEdit ? 'Mở & Chỉnh sửa' : 'Mở xem toàn màn hình'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditDocumentPage(initialDocument: document),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermBadge(String name, bool isGranted, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isGranted ? color.withOpacity(0.15) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isGranted ? color.withOpacity(0.5) : Colors.grey.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isGranted ? Icons.check_circle_rounded : Icons.cancel_outlined, size: 12, color: isGranted ? color : Colors.grey),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isGranted ? color : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    final supabase = SupabaseService();
    final auth = FirebaseAuthService();
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final searchController = TextEditingController();
    List<SupabaseUser> searchResults = [];
    SupabaseUser? selectedTargetUser;
    bool canEdit = false;
    bool canDelete = false;
    bool canShare = false;
    bool isSearching = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void performSearch(String q) async {
              setDialogState(() => isSearching = true);
              final all = await supabase.searchUsersOnline(q);
              final filtered = all.where((u) => u.email.toLowerCase() != currentUser.email.toLowerCase()).toList();
              setDialogState(() {
                searchResults = filtered;
                isSearching = false;
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_search_rounded, color: Color(0xFF1976D2), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chia sẻ Tài liệu & Phân quyền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Tìm kiếm theo Gmail và lưu phân quyền lên Supabase RLS', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tài liệu: ${document.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Chủ sở hữu: ${currentUser.displayName} (${currentUser.email})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('1. Tìm kiếm người dùng theo Gmail:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Nhập Gmail cần chia sẻ...',
                                hintStyle: const TextStyle(fontSize: 12),
                                prefixIcon: const Icon(Icons.search, size: 18),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onSubmitted: performSearch,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => performSearch(searchController.text.trim()),
                            child: const Text('Tìm'),
                          ),
                        ],
                      ),

                      if (isSearching)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),

                      if (!isSearching && searchResults.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 140),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: searchResults.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final u = searchResults[i];
                              final isSelected = selectedTargetUser?.email == u.email;
                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: Colors.blue.shade50,
                                leading: CircleAvatar(radius: 12, child: Text(u.displayName.isNotEmpty ? u.displayName[0] : 'U', style: const TextStyle(fontSize: 11))),
                                title: Text(u.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                subtitle: Text(u.email, style: const TextStyle(fontSize: 11)),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF1976D2), size: 18) : null,
                                onTap: () => setDialogState(() => selectedTargetUser = u),
                              );
                            },
                          ),
                        ),
                      ],

                      if (!isSearching && searchResults.isEmpty && searchController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Không tìm thấy người dùng nào với từ khóa "${searchController.text}"', style: const TextStyle(color: Colors.red, fontSize: 11)),
                        ),

                      if (selectedTargetUser != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Color(0xFF1976D2), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Đang chọn: ${selectedTargetUser!.displayName} (${selectedTargetUser!.email})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      if (!document.isOwner)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bạn đang chia sẻ với quyền Sharer: Theo quy tắc bảo mật RLS, bạn chỉ được phép chia sẻ cho người khác ở chế độ [Chỉ Xem (Viewer)]. Quyền Sửa/Xóa chỉ Chủ sở hữu mới được cấp.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF795548), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Text(
                        document.isOwner
                            ? '2. Thiết lập quyền truy cập (Chủ sở hữu có toàn quyền phân bổ):'
                            : '2. Quyền cấp cho người nhận (Cố định ở chế độ Xem):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            // 1. Quyền Xem: Luôn luôn có (mặc định đã tick, không cho bỏ chọn)
                            CheckboxListTile(
                              value: true,
                              onChanged: null, // Khóa cố định luôn có quyền xem
                              activeColor: const Color(0xFF1976D2),
                              secondary: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.visibility_rounded, color: Colors.teal, size: 20),
                              ),
                              title: Row(
                                children: [
                                  const Text('Xem (Viewer)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Luôn luôn có', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                                  ),
                                ],
                              ),
                              subtitle: const Text('Mặc định có quyền xem và tải tệp tài liệu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              dense: true,
                            ),
                            const Divider(height: 1),

                            // 2. Quyền Sửa: Tùy chọn tick thêm (chỉ Owner mới được cấp)
                            CheckboxListTile(
                              value: document.isOwner ? canEdit : false,
                              onChanged: document.isOwner ? (val) => setDialogState(() => canEdit = val ?? false) : null,
                              activeColor: const Color(0xFF1976D2),
                              secondary: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: document.isOwner ? Colors.orange.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.edit_note_rounded, color: document.isOwner ? Colors.orange : Colors.grey, size: 20),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    'Sửa (Editor)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: document.isOwner ? Colors.black87 : Colors.grey.shade500,
                                    ),
                                  ),
                                  if (!document.isOwner) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Chỉ Owner', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                document.isOwner ? 'Cho phép chỉnh sửa thông tin tài liệu' : 'Chỉ Chủ sở hữu mới được cấp quyền Sửa',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              dense: true,
                            ),
                            const Divider(height: 1),

                            // 3. Quyền Xóa: Tùy chọn tick thêm (chỉ Owner mới được cấp)
                            CheckboxListTile(
                              value: document.isOwner ? canDelete : false,
                              onChanged: document.isOwner ? (val) => setDialogState(() => canDelete = val ?? false) : null,
                              activeColor: const Color(0xFF1976D2),
                              secondary: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: document.isOwner ? Colors.red.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.delete_outline_rounded, color: document.isOwner ? Colors.red : Colors.grey, size: 20),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    'Xóa (Deleter)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: document.isOwner ? Colors.black87 : Colors.grey.shade500,
                                    ),
                                  ),
                                  if (!document.isOwner) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Chỉ Owner', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                document.isOwner ? 'Cho phép xóa tài liệu khỏi hệ thống' : 'Chỉ Chủ sở hữu mới được cấp quyền Xóa',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              dense: true,
                            ),
                            const Divider(height: 1),

                            // 4. Quyền Chia sẻ: Tùy chọn tick thêm (chỉ Owner mới được ủy quyền tiếp)
                            CheckboxListTile(
                              value: document.isOwner ? canShare : false,
                              onChanged: document.isOwner ? (val) => setDialogState(() => canShare = val ?? false) : null,
                              activeColor: const Color(0xFF1976D2),
                              secondary: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: document.isOwner ? Colors.blue.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.share_rounded, color: document.isOwner ? const Color(0xFF1976D2) : Colors.grey, size: 20),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    'Chia sẻ (Sharer)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: document.isOwner ? Colors.black87 : Colors.grey.shade500,
                                    ),
                                  ),
                                  if (!document.isOwner) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Chỉ Owner', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                document.isOwner ? 'Cho phép tiếp tục chia sẻ tài liệu cho người khác' : 'Chỉ Chủ sở hữu mới được ủy quyền chia sẻ tiếp',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              dense: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: isSubmitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.share_rounded, size: 18),
                        label: Text(isSubmitting ? 'ĐANG LƯU VÀO SUPABASE...' : 'XÁC NHẬN CHIA SẺ LÊN SUPABASE'),
                        onPressed: (selectedTargetUser == null || isSubmitting)
                            ? null
                            : () async {
                                setDialogState(() => isSubmitting = true);
                                final PermissionType chosenType;
                                final List<String> granted = ['Xem'];
                                if (canEdit) granted.add('Sửa');
                                if (canDelete) granted.add('Xóa');
                                if (canShare) granted.add('Chia sẻ');
                                final String permDesc = granted.join(' + ').toUpperCase();

                                final List<String> permCodes = ['view'];
                                if (canEdit) permCodes.add('edit');
                                if (canDelete) permCodes.add('delete');
                                if (canShare) permCodes.add('share');

                                final count = (canEdit ? 1 : 0) + (canDelete ? 1 : 0) + (canShare ? 1 : 0);
                                if (count >= 2) {
                                  chosenType = PermissionType.all;
                                } else if (canEdit) {
                                  chosenType = PermissionType.edit;
                                } else if (canDelete) {
                                  chosenType = PermissionType.delete;
                                } else if (canShare) {
                                  chosenType = PermissionType.share;
                                } else {
                                  chosenType = PermissionType.view;
                                }

                                final ok = await supabase.shareDocumentOnline(
                                  documentId: document.id,
                                  targetUser: selectedTargetUser!,
                                  permissions: permCodes,
                                  permissionType: chosenType,
                                  currentUser: currentUser,
                                );
                                setDialogState(() => isSubmitting = false);
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? '✅ Đã chia sẻ quyền $permDesc cho ${selectedTargetUser!.email} trên Supabase!'
                                          : '❌ Lỗi chia sẻ quyền lên Supabase!'),
                                      backgroundColor: ok ? Colors.green.shade700 : Colors.red,
                                    ),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
              ],
            );
          },
        );
      },
    );
  }
}
