import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';
import '../struct/studyDocument.dart';
import '../pages/addEditStudyDocumentPage.dart';
import '../services/firebase_auth_service.dart';

class RecommendationCarousel extends StatefulWidget {
  final List<ScoredDocument> recommendations;
  final List<StudyDocument> allDocuments;

  const RecommendationCarousel({
    super.key,
    required this.recommendations,
    this.allDocuments = const [],
  });

  @override
  State<RecommendationCarousel> createState() => _RecommendationCarouselState();
}

class _RecommendationCarouselState extends State<RecommendationCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPreferencesDialog(BuildContext context) {
    final recService = RecommendationService();
    final auth = FirebaseAuthService();
    final currentUserId = auth.currentUser?.id ?? '';
    final currentUserEmail = auth.currentUser?.email ?? '';

    final tagController = TextEditingController();

    final quickSuggestions = [
      'Flutter',
      'Firebase',
      'Kiến trúc',
      'Microservice',
      'Database',
      'AI',
      'An toàn thông tin',
      'Lập trình Web',
      'SE301',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final activeTags = recService.getActiveInterests(
            allDocuments: widget.allDocuments,
            currentUserId: currentUserId,
            currentUserEmail: currentUserEmail,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tùy chỉnh Sở thích & Thẻ quan tâm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width > 500
                  ? 440.0
                  : (MediaQuery.of(context).size.width * 0.92),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hệ thống AI tự động học các thẻ tag từ môn học và tài liệu bạn tham gia. '
                      'Bạn có thể bấm [x] để xóa hoặc nhập thêm các chủ đề bạn muốn ưu tiên gợi ý:',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 14),

                    // Danh sách thẻ hiện tại
                    const Text('Các thẻ đang quan tâm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: activeTags.map((tag) {
                        return Chip(
                          backgroundColor: Colors.purple.shade50,
                          side: BorderSide(color: Colors.purple.shade200),
                          label: Text('#$tag', style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w600)),
                          deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.purple),
                          onDeleted: () {
                            recService.removeInterest(tag);
                            setDialogState(() {});
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Thêm thẻ mới
                    const Text('Thêm thẻ sở thích mới:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tagController,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên thẻ tag (vd: python, web, AI...)',
                              hintStyle: const TextStyle(fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                recService.addInterest(val.trim());
                                tagController.clear();
                                setDialogState(() {});
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8E24AA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Thêm', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            if (tagController.text.trim().isNotEmpty) {
                              recService.addInterest(tagController.text.trim());
                              tagController.clear();
                              setDialogState(() {});
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    // Gợi ý nhanh
                    const Text('Gợi ý phổ biến (bấm để thêm nhanh):', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickSuggestions.map((s) {
                        final isAdded = activeTags.contains(s.toLowerCase());
                        return ActionChip(
                          backgroundColor: isAdded ? Colors.grey.shade100 : Colors.white,
                          side: BorderSide(color: isAdded ? Colors.grey.shade300 : Colors.purple.shade200),
                          label: Text('+ $s', style: TextStyle(fontSize: 11, color: isAdded ? Colors.grey : const Color(0xFF8E24AA))),
                          onPressed: isAdded
                              ? null
                              : () {
                                  recService.addInterest(s);
                                  setDialogState(() {});
                                },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Khôi phục tự động học'),
                onPressed: () {
                  recService.resetInterests();
                  setDialogState(() {});
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hoàn tất & Cập nhật gợi ý'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(ScoredDocument item, BuildContext context, {double? width}) {
    final doc = item.document;

    // Color based on score
    Color scoreColor = Colors.purple;
    Color scoreBg = Colors.purple.shade50;
    if (item.score >= 70) {
      scoreColor = Colors.teal.shade800;
      scoreBg = Colors.teal.shade50;
    } else if (item.score >= 50) {
      scoreColor = const Color(0xFF8E24AA);
      scoreBg = Colors.purple.shade50;
    } else {
      scoreColor = Colors.blue.shade800;
      scoreBg = Colors.blue.shade50;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddEditDocumentPage(initialDocument: doc)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.purple.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Score + Course badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: scoreBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: scoreColor),
                      const SizedBox(width: 2),
                      Text(
                        '${item.score.toStringAsFixed(0)}% Phù hợp',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scoreColor),
                      ),
                    ],
                  ),
                ),
                if (doc.courseId.trim().isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      doc.courseId.trim().toUpperCase(),
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Document Title
            Text(
              doc.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.25),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Matched Tags chips
            if (doc.tags.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: doc.tags.take(4).map((t) {
                    final isMatched = item.matchedTags.contains(t.toLowerCase().trim());
                    return Container(
                      margin: const EdgeInsets.only(right: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMatched ? const Color(0xFFF7D8DF) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$t',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                          color: isMatched ? const Color(0xFFD81B60) : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
            ],

            const Spacer(),

            // Reason Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF8E24AA)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.reason,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recs = widget.recommendations;
    if (recs.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 700;
        final double horizontalPadding = isMobile ? 16.0 : 24.0;
        final double cardHeight = isMobile ? 190.0 : 185.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8E24AA), Color(0xFFD81B60)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gợi ý Thông minh cho Bạn',
                          style: TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Thuật toán Content-Based & Jaccard tự động học sở thích',
                          style: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Pagination controls on Mobile if more than 1 item
                  if (isMobile && recs.length > 1) ...[
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Gợi ý trước',
                      onPressed: _currentPage > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                    Text(
                      '${_currentPage + 1}/${recs.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8E24AA)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Gợi ý kế tiếp',
                      onPressed: _currentPage < recs.length - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                    ),
                    const SizedBox(width: 4),
                  ],

                  if (isMobile)
                    IconButton(
                      tooltip: 'Tùy chỉnh sở thích',
                      icon: const Icon(Icons.tune_rounded, color: Color(0xFF8E24AA), size: 20),
                      onPressed: () => _showPreferencesDialog(context),
                    )
                  else
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8E24AA),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Tùy chỉnh sở thích', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _showPreferencesDialog(context),
                    ),
                ],
              ),
            ),

            // Content: Responsive between Mobile (PageView 100% width) and Desktop (Side-by-side or Grid)
            if (isMobile) ...[
              // MOBILE: PageView fits 100% of container width (NO horizontal clipping/overflow)
              SizedBox(
                height: cardHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: recs.length,
                  onPageChanged: (idx) {
                    setState(() => _currentPage = idx);
                  },
                  itemBuilder: (context, index) {
                    final item = recs[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
                      child: _buildCard(item, context),
                    );
                  },
                ),
              ),
              if (recs.length > 1) ...[
                const SizedBox(height: 6),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(recs.length, (idx) {
                      final isSel = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isSel ? 18 : 6,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF8E24AA) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ] else ...[
              // DESKTOP: If 2 items, show side-by-side cleanly filling the width.
              // If more items, show in a clean responsive row/grid.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
                child: recs.length == 2
                    ? SizedBox(
                        height: cardHeight,
                        child: Row(
                          children: [
                            Expanded(child: _buildCard(recs[0], context)),
                            const SizedBox(width: 14),
                            Expanded(child: _buildCard(recs[1], context)),
                          ],
                        ),
                      )
                    : recs.length == 1
                        ? SizedBox(
                            height: cardHeight,
                            child: Row(
                              children: [
                                Expanded(child: _buildCard(recs[0], context)),
                              ],
                            ),
                          )
                        : SizedBox(
                            height: cardHeight,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recs.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                return _buildCard(recs[index], context, width: 310);
                              },
                            ),
                          ),
              ),
            ],
          ],
        );
      },
    );
  }
}
