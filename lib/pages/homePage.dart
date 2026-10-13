import 'package:flutter/material.dart';
import '../struct/studyDocument.dart';
import '../database/study_document_dao.dart';
import '../widgets/studyDocumentCard.dart';
import 'addEditStudyDocumentPage.dart';
import 'studyDocumentSearchPage.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final documentDao = DocumentDao();
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: StreamBuilder<List<StudyDocument>>(
        stream: documentDao.watchAll(),
        initialData: documentDao.getAll(),
        builder: (context, snapshot) {
          final docs = snapshot.data ?? [];
          final totalCount = docs.length;
          final inProgressCount = docs.where((d) => d.status == DocumentStatus.inProgress).length;
          final completedCount = docs.where((d) => d.status == DocumentStatus.completed).length;
          final upcomingDocs = docs.where((d) => d.deadline != null && d.status != DocumentStatus.completed).toList();

          return CustomScrollView(
            slivers: [
              // Top Header Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trang chủ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hệ thống Quản lý Tài liệu Học tập theo Kiến trúc Cashew',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
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
                    ],
                  ),
                ),
              ),

              // Cashew Summary Stats Cards (Bank / Upcoming / Overdue equivalent)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatBox(
                          context,
                          title: 'TỔNG TÀI LIỆU',
                          value: totalCount.toString(),
                          subtitle: 'trong kho lưu trữ',
                          icon: Icons.menu_book_rounded,
                          color: const Color(0xFFD81B60),
                          onTap: () => onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatBox(
                          context,
                          title: 'ĐANG HỌC',
                          value: inProgressCount.toString(),
                          subtitle: 'cần hoàn thành',
                          icon: Icons.timelapse_rounded,
                          color: Colors.orange.shade700,
                          onTap: () => onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatBox(
                          context,
                          title: 'HOÀN THÀNH',
                          value: completedCount.toString(),
                          subtitle: 'đã học xong',
                          icon: Icons.check_circle_rounded,
                          color: Colors.green.shade600,
                          onTap: () => onNavigate(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Access Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF7D8DF),
                          const Color(0xFFE8DEF8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.bookmark_add_rounded, color: Color(0xFFD81B60), size: 26),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thêm tài liệu hoặc bài tập mới',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Lưu trữ bài giảng, bài tập, link tài liệu và thiết lập hạn nộp',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD81B60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm mới'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEditDocumentPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Upcoming Tasks Section
              if (upcomingDocs.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bài tập & Deadline sắp đến',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => onNavigate(1),
                          child: const Text('Xem tất cả'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = upcomingDocs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StudyDocumentCard(
                            document: doc,
                            onStatusChanged: (newStatus) async {
                              await documentDao.update(doc.copyWith(status: newStatus));
                            },
                            onDelete: () async {
                              await documentDao.delete(doc.id);
                            },
                          ),
                        );
                      },
                      childCount: upcomingDocs.length > 3 ? 3 : upcomingDocs.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
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
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Icon(icon, size: 18, color: color),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
