import '../struct/studyDocument.dart';

class ScoredDocument {
  final StudyDocument document;
  final double score;
  final String reason;

  ScoredDocument({
    required this.document,
    required this.score,
    required this.reason,
  });
}

/// Thuật toán Recommendation (Gợi ý tài liệu thông minh)
/// Áp dụng Hybrid Content-Based Filtering & Jaccard Similarity trên Tags và Môn học
class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  /// Tính chỉ số tương đồng Jaccard giữa hai tập hợp Tags:
  /// Jaccard(A, B) = |A ∩ B| / |A ∪ B|
  double _calculateJaccardSimilarity(List<String> tagsA, List<String> tagsB) {
    if (tagsA.isEmpty || tagsB.isEmpty) return 0.0;
    final setA = tagsA.map((t) => t.toLowerCase().trim()).toSet();
    final setB = tagsB.map((t) => t.toLowerCase().trim()).toSet();

    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  /// Thuật toán xếp hạng và gợi ý tài liệu phù hợp cho người dùng
  List<ScoredDocument> getRecommendations({
    required List<StudyDocument> allDocuments,
    required String currentUserId,
    List<String> userInterests = const ['microservice', 'database', 'kiến trúc', 'flutter', 'firebase'],
    List<String> userCourses = const ['c1', 'c2', 'SE301', 'CS402'],
    int limit = 5,
  }) {
    final List<ScoredDocument> scored = [];

    for (var doc in allDocuments) {
      // Không gợi ý tài liệu do chính mình tạo nếu người dùng muốn khám phá tài liệu mới
      double score = 0.0;
      final List<String> reasons = [];

      // 1. Điểm tương đồng Tags (Trọng số 45%)
      final tagSim = _calculateJaccardSimilarity(doc.tags, userInterests);
      if (tagSim > 0) {
        score += tagSim * 45.0;
        final matchedTags = doc.tags.where((t) => userInterests.any((i) => i.toLowerCase() == t.toLowerCase())).toList();
        reasons.add('Trùng thẻ sở thích #${matchedTags.take(2).join(", #")}');
      }

      // 2. Điểm trùng khớp Môn học học kỳ này (Trọng số 35%)
      if (userCourses.any((c) => c.toLowerCase() == doc.courseId.toLowerCase())) {
        score += 35.0;
        reasons.add('Đúng chuyên ngành học phần đang theo');
      }

      // 3. Điểm vị trí vật lý sẵn sàng (Trọng số 10%)
      if (doc.physicalLocation.isNotEmpty) {
        score += 10.0;
        reasons.add('Có sẵn bản vật lý tại ${doc.physicalLocation.split("-").first.trim()}');
      }

      // 4. Điểm trạng thái mượn (Trọng số 10%)
      if (doc.borrowStatus == 'available') {
        score += 10.0;
        reasons.add('Đang sẵn sàng cho mượn');
      }

      // Điểm cơ sở để tài liệu chất lượng luôn được hiển thị
      if (score < 5.0) {
        score = 5.0 + (doc.isPinned ? 15.0 : 0.0);
        reasons.add('Tài liệu học tập nổi bật');
      }

      scored.add(ScoredDocument(
        document: doc,
        score: score,
        reason: reasons.join(' • '),
      ));
    }

    // Sắp xếp theo điểm số từ cao xuống thấp
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(limit).toList();
  }
}
