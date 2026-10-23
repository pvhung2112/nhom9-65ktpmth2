import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';
import '../struct/studyDocument.dart';
import '../pages/addEditStudyDocumentPage.dart';
import '../services/firebase_auth_service.dart';

class RecommendationCarousel extends StatelessWidget {
  final List<ScoredDocument> recommendations;
  final List<StudyDocument> allDocuments;

  const RecommendationCarousel({
    super.key,
    required this.recommendations,
    this.allDocuments = const [],
  });

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
            allDocuments: allDocuments,
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
                const Text('Tùy chỉnh Sở thích & Thẻ quan tâm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 440,
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

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                    const Text(
                      'Gợi ý Thông minh cho Bạn (Recommendation AI)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Thuật toán Content-Based & Jaccard tự động học sở thích học tập',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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

        // Carousel List
        SizedBox(
          height: 175,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = recommendations[index];
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
                  width: 300,
                  padding: const EdgeInsets.all(13),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: Score + Course badge + Owner
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: scoreBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 13, color: scoreColor),
                                const SizedBox(width: 2),
                                Text(
                                  '${item.score.toStringAsFixed(0)}% Phù hợp',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: scoreColor),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              doc.courseId.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),

                      // Document Title
                      Text(
                        doc.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Matched Tags chips
                      if (doc.tags.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: doc.tags.take(3).map((t) {
                              final isMatched = item.matchedTags.contains(t.toLowerCase().trim());
                              return Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isMatched ? const Color(0xFFF7D8DF) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$t',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                                    color: isMatched ? const Color(0xFFD81B60) : Colors.grey.shade700,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Reason Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
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
            },
          ),
        ),
      ],
    );
  }
}
