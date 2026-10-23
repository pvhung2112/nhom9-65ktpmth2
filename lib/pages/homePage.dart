import 'package:flutter/material.dart';
import '../struct/studyDocument.dart';
import '../database/study_document_dao.dart';
import '../widgets/studyDocumentCard.dart';
import 'addEditStudyDocumentPage.dart';
import '../services/recommendation_service.dart';
import '../widgets/recommendation_carousel.dart';
import '../services/firebase_auth_service.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final documentDao = DocumentDao();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final double horizontalPadding = isMobile ? 16.0 : (width > 1100 ? 32.0 : 24.0);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: StreamBuilder<List<StudyDocument>>(
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
                      // 1. Top Header Bar (Trang chủ & Welcome)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, isMobile ? 16 : 24, horizontalPadding, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trang chủ',
                                      style: TextStyle(
                                        fontSize: isMobile ? 22 : 28,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Hệ thống Quản lý Tài liệu Học tập theo Kiến trúc Cashew',
                                      style: TextStyle(
                                        fontSize: isMobile ? 11.5 : 13,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Cashew Summary Stats Cards (Thống kê tài liệu)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
                          child: _buildResponsiveStats(
                            context,
                            width: width,
                            totalCount: totalCount,
                            inProgressCount: inProgressCount,
                            completedCount: completedCount,
                            onNavigate: onNavigate,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      // 3. Khối Gợi ý Thông minh TH2 (Recommendation AI)
                      SliverToBoxAdapter(
                        child: ListenableBuilder(
                          listenable: RecommendationService(),
                          builder: (context, _) {
                            final auth = FirebaseAuthService();
                            final recs = RecommendationService().getRecommendations(
                              allDocuments: docs,
                              currentUserId: auth.currentUser?.id ?? '',
                              currentUserEmail: auth.currentUser?.email ?? '',
                            );
                            return RecommendationCarousel(
                              recommendations: recs,
                              allDocuments: docs,
                            );
                          },
                        ),
                      ),

                      // 4. Quick Access Banner (Thêm tài liệu mới)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 8),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 14 : 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF7D8DF),
                                  Color(0xFFE8DEF8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.12)),
                            ),
                            child: isMobile
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(9),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.bookmark_add_rounded, color: Color(0xFFD81B60), size: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Thêm tài liệu hoặc bài tập mới',
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                Text(
                                                  'Lưu trữ bài giảng, bài tập, link file và hạn nộp',
                                                  style: TextStyle(fontSize: 11, color: Colors.black54),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFFD81B60),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 11),
                                          ),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('Thêm tài liệu mới', style: TextStyle(fontSize: 12.5)),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const AddEditDocumentPage()),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
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

                      // 5. Upcoming Tasks Section (Bài tập & Deadline sắp đến)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD81B60),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bài tập & Deadline sắp đến',
                                    style: TextStyle(
                                      fontSize: isMobile ? 15 : 17.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => onNavigate(1),
                                child: const Text('Xem tất cả', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (upcomingDocs.isNotEmpty)
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                        )
                      else
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade800, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Không có deadline nào sắp tới',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Bạn đã hoàn thành tốt các bài tập và nhiệm vụ học tập!',
                                          style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // 6. Bottom scroll padding (đủ để cuộn qua bottom navigation bar trên mobile)
                      SliverToBoxAdapter(
                        child: SizedBox(height: isMobile ? 95 : 45),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Xây dựng cụm Stats Card thích ứng linh hoạt theo độ rộng màn hình
  Widget _buildResponsiveStats(
    BuildContext context, {
    required double width,
    required int totalCount,
    required int inProgressCount,
    required int completedCount,
    required ValueChanged<int> onNavigate,
  }) {
    final box1 = _buildStatBox(
      context,
      title: 'TỔNG TÀI LIỆU',
      value: totalCount.toString(),
      subtitle: 'trong kho lưu trữ',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFFD81B60),
      onTap: () => onNavigate(1),
    );

    final box2 = _buildStatBox(
      context,
      title: 'ĐANG HỌC',
      value: inProgressCount.toString(),
      subtitle: 'cần hoàn thành',
      icon: Icons.timelapse_rounded,
      color: Colors.orange.shade700,
      onTap: () => onNavigate(1),
    );

    final box3 = _buildStatBox(
      context,
      title: 'HOÀN THÀNH',
      value: completedCount.toString(),
      subtitle: 'đã học xong',
      icon: Icons.check_circle_rounded,
      color: Colors.green.shade600,
      onTap: () => onNavigate(1),
    );

    // Màn hình hẹp (Điện thoại / cửa sổ nhỏ < 520px): Bố cục 2 thẻ trên + 1 thẻ dưới
    if (width < 520) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: box1),
              const SizedBox(width: 10),
              Expanded(child: box2),
            ],
          ),
          const SizedBox(height: 10),
          box3,
        ],
      );
    }

    // Màn hình vừa và lớn (>= 520px): 3 thẻ dàn ngang đều nhau
    return Row(
      children: [
        Expanded(child: box1),
        const SizedBox(width: 12),
        Expanded(child: box2),
        const SizedBox(width: 12),
        Expanded(child: box3),
      ],
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon, size: 18, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
