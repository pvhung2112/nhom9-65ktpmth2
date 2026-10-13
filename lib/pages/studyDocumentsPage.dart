import '../struct/firebaseAuthService.dart';
import 'dart:async';

import '../struct/studySyncClient.dart';

import 'package:flutter/material.dart';

import '../struct/studyDocument.dart';

import '../struct/studyCourse.dart';

import '../database/study_document_dao.dart';

import '../database/study_course_dao.dart';

import '../widgets/studyDocumentCard.dart';

import 'addEditStudyDocumentPage.dart';

import 'studyDocumentSearchPage.dart';

import 'studyCoursesPage.dart';



class StudyDocumentsPage extends StatefulWidget {

  const StudyDocumentsPage({super.key});



  @override

  State<StudyDocumentsPage> createState() => _StudyDocumentsPageState();

}



class _StudyDocumentsPageState extends State<StudyDocumentsPage> {

  final DocumentDao _documentDao = DocumentDao();

  final CourseDao _courseDao = CourseDao();

  final StudySyncClient _syncClient = StudySyncClient();



  int _selectedTabIndex = 0; // 0: Tất cả, 1: Bài giảng, 2: Bài tập, 3: Tham khảo

  String? _selectedCourseId;

  bool _isLoadingFromCloud = false;



  @override

  void initState() {

    super.initState();

    _loadFromCloud();

  }



  Future<void> _loadFromCloud() async {

    setState(() => _isLoadingFromCloud = true);

    try {

      await _syncClient.pullFromCloud();

    } catch (_) {}

    if (mounted) {

      setState(() => _isLoadingFromCloud = false);

    }

  }



  DocumentType? _getCurrentTabType() {

    switch (_selectedTabIndex) {

      case 1:

        return DocumentType.lecture;

      case 2:

        return DocumentType.exercise;

      case 3:

        return DocumentType.reference;

      default:

        return null;

    }

  }



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final currentType = _getCurrentTabType();



    return Scaffold(

      backgroundColor: theme.colorScheme.background,

      floatingActionButton: FloatingActionButton.extended(

        backgroundColor: const Color(0xFFD81B60),

        foregroundColor: Colors.white,

        icon: const Icon(Icons.add_rounded),

        label: const Text('Thêm tài liệu'),

        onPressed: () {

          Navigator.push(

            context,

            MaterialPageRoute(builder: (_) => const AddEditDocumentPage()),

          );

        },

      ),

      body: CustomScrollView(

        slivers: [

          // Header Bar

          SliverToBoxAdapter(

            child: Padding(

              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),

              child: Row(

                children: [

                  Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Text(

                        'Kho Tài liệu Học tập',

                        style: TextStyle(

                          fontSize: 24,

                          fontWeight: FontWeight.bold,

                          letterSpacing: -0.5,

                        ),

                      ),

                      const SizedBox(height: 2),

                      Text(

                        'Lưu trữ bài giảng, bài tập và tài liệu tham khảo',

                        style: TextStyle(

                          fontSize: 13,

                          color: theme.colorScheme.onSurfaceVariant,

                        ),

                      ),

                    ],

                  ),

                  const Spacer(),

                  IconButton.filledTonal(

                    icon: const Icon(Icons.school_rounded),

                    tooltip: 'Quản lý môn học',

                    onPressed: () {

                      Navigator.push(

                        context,

                        MaterialPageRoute(builder: (_) => const CoursesPage()),

                      );

                    },

                  ),

                  const SizedBox(width: 8),

                  IconButton.filledTonal(

                    icon: _isLoadingFromCloud

                        ? const SizedBox(

                            width: 18,

                            height: 18,

                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD81B60)),

                          )

                        : const Icon(Icons.refresh_rounded),

                    tooltip: 'Làm mới từ Firebase Cloud',

                    onPressed: _isLoadingFromCloud ? null : _loadFromCloud,

                  ),

                  const SizedBox(width: 8),

                  IconButton.filledTonal(

                    icon: const Icon(Icons.search_rounded),

                    tooltip: 'Tìm kiếm',

                    onPressed: () {

                      Navigator.push(

                        context,

                        MaterialPageRoute(builder: (_) => const DocumentSearchPage()),

                      );

                    },

                  ),

                  const SizedBox(width: 8),

                  IconButton.filledTonal(

                    icon: const Icon(Icons.cloud_done_rounded, color: Color(0xFFD81B60)),

                    tooltip: 'Trạng thái Firebase Cloud',

                    onPressed: () => _showCloudDialog(context),

                  ),

                ],

              ),

            ),

          ),



          // Type Tab Pills

          SliverToBoxAdapter(

            child: Padding(

              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),

              child: Container(

                decoration: BoxDecoration(

                  color: theme.colorScheme.surface,

                  borderRadius: BorderRadius.circular(14),

                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),

                ),

                padding: const EdgeInsets.all(4),

                child: Row(

                  children: [

                    _buildTabPill('Tất cả', 0),

                    _buildTabPill('Bài giảng', 1),

                    _buildTabPill('Bài tập', 2),

                    _buildTabPill('Tham khảo', 3),

                  ],

                ),

              ),

            ),

          ),



          // Course Filter Chips

          SliverToBoxAdapter(

            child: Padding(

              padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),

              child: StreamBuilder<List<Course>>(

                stream: _courseDao.watchAll(),

                initialData: _courseDao.getAll(),

                builder: (context, snapshot) {

                  final courses = snapshot.data ?? [];

                  return SingleChildScrollView(

                    scrollDirection: Axis.horizontal,

                    child: Row(

                      children: [

                        _buildCourseFilterChip(

                          label: 'Tất cả môn',

                          isSelected: _selectedCourseId == null,

                          onTap: () => setState(() => _selectedCourseId = null),

                        ),

                        const SizedBox(width: 8),

                        ...courses.map((c) {

                          final isSel = _selectedCourseId == c.id;

                          return Padding(

                            padding: const EdgeInsets.only(right: 8),

                            child: _buildCourseFilterChip(

                              label: c.code,

                              dotColor: Color(c.colorValue),

                              isSelected: isSel,

                              onTap: () => setState(() => _selectedCourseId = isSel ? null : c.id),

                            ),

                          );

                        }),

                      ],

                    ),

                  );

                },

              ),

            ),

          ),



          // Document List

          StreamBuilder<List<StudyDocument>>(

            stream: _documentDao.watchAll(),

            initialData: _documentDao.getAll(),

            builder: (context, snapshot) {

              final allDocuments = snapshot.data ?? _documentDao.getAll();



              // Instant filter by Tab Type

              var documents = allDocuments;

              if (currentType != null) {

                documents = documents.where((d) => d.type == currentType).toList();

              }



              // Instant filter by Course

              if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty && _selectedCourseId != 'all') {

                documents = documents.where((d) => d.courseId == _selectedCourseId).toList();

              }



              if (documents.isEmpty) {

                return SliverToBoxAdapter(

                  child: Center(

                    child: Padding(

                      padding: const EdgeInsets.all(40),

                      child: Column(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          Icon(Icons.menu_book_rounded, size: 56, color: Colors.grey.shade400),

                          const SizedBox(height: 12),

                          Text('Chưa có tài liệu nào trong danh mục này', style: TextStyle(color: Colors.grey.shade600)),

                        ],

                      ),

                    ),

                  ),

                );

              }



              return SliverPadding(

                padding: const EdgeInsets.symmetric(horizontal: 24),

                sliver: SliverList(

                  delegate: SliverChildBuilderDelegate(

                    (context, index) {

                      final doc = documents[index];

                      return Padding(

                        padding: const EdgeInsets.only(bottom: 12),

                        child: StudyDocumentCard(

                          document: doc,

                          onStatusChanged: (newStatus) async {

                            final updated = doc.copyWith(status: newStatus);

                            await _documentDao.update(updated);

                            unawaited(_syncClient.saveToCloud(updated));

                          },

                          onDelete: () async {

                            await _documentDao.delete(doc.id);

                            unawaited(_syncClient.deleteFromCloud(doc.id));

                          },

                        ),

                      );

                    },

                    childCount: documents.length,

                  ),

                ),

              );

            },

          ),



          const SliverToBoxAdapter(child: SizedBox(height: 80)),

        ],

      ),

    );

  }



  Widget _buildTabPill(String label, int index) {

    final isSelected = _selectedTabIndex == index;

    return Expanded(

      child: InkWell(

        borderRadius: BorderRadius.circular(10),

        onTap: () {

          setState(() {

            _selectedTabIndex = index;

          });

        },

        child: Container(

          padding: const EdgeInsets.symmetric(vertical: 9),

          decoration: BoxDecoration(

            color: isSelected ? const Color(0xFFF7D8DF) : Colors.transparent,

            borderRadius: BorderRadius.circular(10),

          ),

          child: Center(

            child: Text(

              label,

              style: TextStyle(

                fontSize: 13,

                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,

                color: isSelected ? const Color(0xFFD81B60) : Colors.grey.shade700,

              ),

            ),

          ),

        ),

      ),

    );

  }



  Widget _buildCourseFilterChip({

    required String label,

    Color? dotColor,

    required bool isSelected,

    required VoidCallback onTap,

  }) {

    return InkWell(

      borderRadius: BorderRadius.circular(20),

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),

        decoration: BoxDecoration(

          color: isSelected ? const Color(0xFFF7D8DF) : Theme.of(context).colorScheme.surface,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(

            color: isSelected ? const Color(0xFFD81B60) : Colors.grey.shade300,

            width: 1.2,

          ),

        ),

        child: Row(

          mainAxisSize: MainAxisSize.min,

          children: [

            if (dotColor != null) ...[

              CircleAvatar(backgroundColor: dotColor, radius: 5),

              const SizedBox(width: 6),

            ],

            Text(

              label,

              style: TextStyle(

                fontSize: 13,

                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,

                color: isSelected ? const Color(0xFFD81B60) : Theme.of(context).colorScheme.onSurface,

              ),

            ),

          ],

        ),

      ),

    );

  }



    void _showCloudDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final auth = FirebaseAuthService();
            final isSignedIn = auth.isSignedIn;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSignedIn ? const Color(0xFFF7D8DF) : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isSignedIn ? Icons.cloud_sync_rounded : Icons.lock_outline_rounded,
                      color: isSignedIn ? const Color(0xFFD81B60) : Colors.amber.shade900,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSignedIn ? 'Quản trị Firebase Cloud' : 'Đăng nhập Firebase Google',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isSignedIn ? 'Hệ thống Đám mây & Phân quyền IAM' : 'Cần đăng nhập để lưu tài liệu lên Cloud',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isSignedIn) ...[
                      // Giao diện khi CHƯA ĐĂNG NHẬP
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.amber.shade900, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bạn đang ở chế độ Chưa đăng nhập. Vui lòng đăng nhập Google để được phép thêm và lưu tài liệu trực tiếp vào Cloud Firestore.',
                                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '🔑 Chọn tài khoản Google trong nhóm (IAM Roles):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      ...FirebaseAuthService.teamMembers.map((member) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF7D8DF),
                              child: Text(
                                member.displayName[0],
                                style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${member.email}\n${member.role}', style: const TextStyle(fontSize: 11)),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD81B60),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              icon: const Icon(Icons.login_rounded, size: 14),
                              label: const Text('Đăng nhập'),
                              onPressed: () async {
                                await auth.signInWithGoogle(user: member);
                                setDialogState(() {});
                                setState(() {});
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã đăng nhập Google thành công: ${member.displayName} (${member.role})'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      // Giao diện khi ĐÃ ĐĂNG NHẬP
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFD81B60),
                              child: Text(
                                auth.currentUser!.displayName[0],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        auth.currentUser!.displayName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('Đã đăng nhập', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  Text(auth.currentUser!.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  Text(
                                    'Vai trò IAM: ${auth.currentUser!.role}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD81B60)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // NÚT ĐĂNG XUẤT GOOGLE
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text('Đăng xuất tài khoản Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () async {
                            await auth.signOut();
                            setDialogState(() {});
                            setState(() {});
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã đăng xuất tài khoản Google thành công!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Thông tin kết nối Cloud
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Text('Dự án Firebase:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                Spacer(),
                                Text('study-document-cloud', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.storage_rounded, color: Colors.orange, size: 18),
                                SizedBox(width: 8),
                                Text('Cơ sở dữ liệu:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                Spacer(),
                                Text('Cloud Firestore (Active)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.cloud_upload_rounded, color: Colors.purple, size: 18),
                                SizedBox(width: 8),
                                Text('Lưu trữ Tệp tin:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                Spacer(),
                                Text('Cloud Storage (Active)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Danh sách thành viên nhóm (Users and permissions)
                      const Text(
                        '👥 Danh sách Thành viên Dự án (IAM Roles):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: const Column(
                          children: [
                            _MemberRoleRow(name: 'Phạm Văn Hưng', msv: '2351170598', role: 'Owner / Trưởng nhóm'),
                            Divider(height: 10),
                            _MemberRoleRow(name: 'Trịnh Trung Kiên', msv: '2251172396', role: 'Editor / Frontend'),
                            Divider(height: 10),
                            _MemberRoleRow(name: 'Đỗ Việt Tiến', msv: '2251243452', role: 'Editor / Frontend'),
                            Divider(height: 10),
                            _MemberRoleRow(name: 'Cao Đức Đạo', msv: '2351170581', role: 'Editor / Backend'),
                            Divider(height: 10),
                            _MemberRoleRow(name: 'Trương Tuấn Hải', msv: '2351170590', role: 'Editor / Cloud Research'),
                          ],
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
                if (isSignedIn)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD81B60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Đồng bộ ngay'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đang truyền dữ liệu lên Google Cloud Firestore...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      final res = await StudySyncClient().syncWithCloud();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.success ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 3),
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
}

class _MemberRoleRow extends StatelessWidget {

  final String name;

  final String msv;

  final String role;



  const _MemberRoleRow({required this.name, required this.msv, required this.role});



  @override

  Widget build(BuildContext context) {

    return Row(

      children: [

        const Icon(Icons.person_pin_rounded, size: 14, color: Colors.blue),

        const SizedBox(width: 6),

        Expanded(

          child: Text(

            '$name ($msv)',

            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),

          ),

        ),

        Container(

          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

          decoration: BoxDecoration(

            color: role.startsWith('Owner') ? const Color(0xFFFCE4EC) : Colors.white,

            borderRadius: BorderRadius.circular(6),

            border: Border.all(color: role.startsWith('Owner') ? const Color(0xFFD81B60) : Colors.black12),

          ),

          child: Text(

            role,

            style: TextStyle(

              fontSize: 10,

              fontWeight: FontWeight.bold,

              color: role.startsWith('Owner') ? const Color(0xFFD81B60) : Colors.black54,

            ),

          ),

        ),

      ],

    );

  }

}