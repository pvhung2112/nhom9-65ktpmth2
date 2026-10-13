import '../services/supabase_service.dart';
import '../models/document_permission.dart';
import '../struct/firebaseAuthService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../struct/studyDocument.dart';
import '../struct/studyCourse.dart';
import '../database/study_course_dao.dart';
import '../pages/addEditStudyDocumentPage.dart';

typedef DocumentCard = StudyDocumentCard;

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
                          _showShareDialog(context);
                        } else if (val == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa tài liệu'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 16, color: Color(0xFF1976D2)),
                              SizedBox(width: 8),
                              Text('Chia sẻ quyền (RLS)', style: TextStyle(color: Color(0xFF1976D2))),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa tài liệu', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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

  void _showShareDialog(BuildContext context) {
    final supabase = SupabaseService();
    final auth = FirebaseAuthService();
    final currentUser = auth.currentUser ?? FirebaseAuthService.predefinedAccounts[0];

    final candidateUsers = FirebaseAuthService.predefinedAccounts
        .where((u) => u.id != currentUser.id)
        .toList();

    String selectedUserId = candidateUsers.isNotEmpty ? candidateUsers[0].id : '';
    PermissionType selectedType = PermissionType.view;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final activePermissions = supabase.getPermissionsForDocument(document.id);

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
                    child: const Icon(Icons.share_rounded, color: Color(0xFF1976D2), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chia sẻ Tài liệu & Phân quyền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Checklist 4: Cấp quyền view / edit trên Supabase', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
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
                          Text('Chủ sở hữu: ${currentUser.displayName} (${currentUser.role})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Chọn thành viên trong nhóm để chia sẻ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),

                    if (candidateUsers.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: selectedUserId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        items: candidateUsers.map((u) {
                          return DropdownMenuItem(
                            value: u.id,
                            child: Row(
                              children: [
                                CircleAvatar(radius: 10, child: Text(u.displayName[0])),
                                const SizedBox(width: 8),
                                Text('${u.displayName} (${u.role})', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedUserId = val ?? ''),
                      ),

                    const SizedBox(height: 14),
                    const Text('Loại quyền hạn cấp cho thành viên:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<PermissionType>(
                            title: const Text('Chỉ xem (View)', style: TextStyle(fontSize: 12)),
                            value: PermissionType.view,
                            groupValue: selectedType,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<PermissionType>(
                            title: const Text('Chỉnh sửa (Edit)', style: TextStyle(fontSize: 12)),
                            value: PermissionType.edit,
                            groupValue: selectedType,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('CẤP QUYỀN TRUY CẬP (LƯU SUPABASE)'),
                      onPressed: selectedUserId.isEmpty ? null : () async {
                        try {
                          await supabase.shareDocument(
                            documentId: document.id,
                            targetUserId: selectedUserId,
                            permissionType: selectedType,
                            currentUser: currentUser,
                          );
                          setDialogState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã cấp quyền ${selectedType.name.toUpperCase()} trên Supabase Cloud!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $err'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    ),

                    if (activePermissions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Danh sách đã được cấp quyền trên Supabase:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: activePermissions.length,
                          itemBuilder: (ctx, i) {
                            final perm = activePermissions[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${perm.userName} (${perm.userEmail})',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: perm.permissionType == PermissionType.edit ? Colors.orange.shade100 : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      perm.permissionType.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: perm.permissionType == PermissionType.edit ? Colors.orange.shade900 : Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                    tooltip: 'Thu hồi quyền',
                                    onPressed: () async {
                                      await supabase.revokePermission(
                                        documentId: document.id,
                                        targetUserId: perm.userId,
                                        currentUserId: currentUser.id,
                                      );
                                      setDialogState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
