import 'package:flutter/foundation.dart';
import '../struct/studyDocument.dart';

class ScoredDocument {
  final StudyDocument document;
  final double score; // 0.0 -> 100.0
  final String reason;
  final List<String> matchedTags;
  final bool isOwnDocument;

  ScoredDocument({
    required this.document,
    required this.score,
    required this.reason,
    this.matchedTags = const [],
    this.isOwnDocument = false,
  });
}

/// Thuật toán Recommendation (Gợi ý tài liệu học tập thông minh)
/// Áp dụng mô hình Hybrid Content-Based Filtering & Jaccard Similarity trên Tags & Môn học
class RecommendationService extends ChangeNotifier {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  // Danh sách sở thích tùy chỉnh thủ công của người dùng (nếu có)
  final List<String> _customInterests = [];
  List<String> get customInterests => List.unmodifiable(_customInterests);

  void addInterest(String tag) {
    final t = tag.trim().toLowerCase();
    if (t.isNotEmpty && !_customInterests.contains(t)) {
      _customInterests.add(t);
      notifyListeners();
    }
  }

  void removeInterest(String tag) {
    if (_customInterests.remove(tag.trim().toLowerCase())) {
      notifyListeners();
    }
  }

  void resetInterests() {
    _customInterests.clear();
    notifyListeners();
  }

  /// Tự động trích xuất sở thích & tần suất thẻ tag từ hành vi thực tế của người dùng:
  /// - Các tài liệu do người dùng tạo
  /// - Các tài liệu người dùng đang học (inProgress) hoặc đã hoàn thành (completed)
  Map<String, int> extractUserTagFrequencies({
    required List<StudyDocument> allDocuments,
    required String currentUserId,
    required String currentUserEmail,
  }) {
    final Map<String, int> frequencies = {};
    for (var doc in allDocuments) {
      final isMine = (currentUserId.isNotEmpty && doc.ownerId == currentUserId) ||
          (currentUserEmail.isNotEmpty && doc.ownerEmail.toLowerCase() == currentUserEmail.toLowerCase()) ||
          doc.status == DocumentStatus.inProgress ||
          doc.status == DocumentStatus.completed;

      if (isMine) {
        for (var tag in doc.tags) {
          final t = tag.trim().toLowerCase();
          if (t.isNotEmpty) {
            frequencies[t] = (frequencies[t] ?? 0) + 1;
          }
        }
      }
    }
    return frequencies;
  }

  /// Tự động trích xuất các mã môn học người dùng đang theo học
  Set<String> extractUserCourses({
    required List<StudyDocument> allDocuments,
    required String currentUserId,
    required String currentUserEmail,
  }) {
    final Set<String> courses = {};
    for (var doc in allDocuments) {
      final isMine = (currentUserId.isNotEmpty && doc.ownerId == currentUserId) ||
          (currentUserEmail.isNotEmpty && doc.ownerEmail.toLowerCase() == currentUserEmail.toLowerCase()) ||
          doc.status == DocumentStatus.inProgress;

      if (isMine && doc.courseId.trim().isNotEmpty) {
        courses.add(doc.courseId.trim().toLowerCase());
      }
    }
    return courses;
  }

  /// Lấy danh sách sở thích tổng hợp (kết hợp tự động học + người dùng tùy chỉnh)
  List<String> getActiveInterests({
    required List<StudyDocument> allDocuments,
    required String currentUserId,
    required String currentUserEmail,
  }) {
    final Set<String> active = Set.from(_customInterests);

    // Học từ lịch sử thực tế
    final freq = extractUserTagFrequencies(
      allDocuments: allDocuments,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );

    // Lấy top các tag có tần suất cao nhất
    final sortedTags = freq.keys.toList()..sort((a, b) => freq[b]!.compareTo(freq[a]!));
    active.addAll(sortedTags.take(8));

    // Nếu vẫn rỗng (Cold start - người dùng mới hoàn toàn) -> lấy tag phổ biến nhất trong kho
    if (active.isEmpty) {
      final allFreq = <String, int>{};
      for (var d in allDocuments) {
        for (var t in d.tags) {
          final tag = t.trim().toLowerCase();
          if (tag.isNotEmpty) allFreq[tag] = (allFreq[tag] ?? 0) + 1;
        }
      }
      final popular = allFreq.keys.toList()..sort((a, b) => allFreq[b]!.compareTo(allFreq[a]!));
      active.addAll(popular.take(5));
    }

    // Nếu kho cũng chưa có tag nào -> fallback mặc định
    if (active.isEmpty) {
      active.addAll(['flutter', 'firebase', 'kiến trúc', 'database', 'se301']);
    }

    return active.toList();
  }

  /// Tính chỉ số tương đồng Jaccard giữa hai tập hợp thẻ Tags:
  /// Jaccard(A, B) = |A ∩ B| / |A ∪ B|
  double calculateJaccardSimilarity(List<String> tagsA, List<String> tagsB) {
    if (tagsA.isEmpty || tagsB.isEmpty) return 0.0;
    final setA = tagsA.map((t) => t.toLowerCase().trim()).toSet();
    final setB = tagsB.map((t) => t.toLowerCase().trim()).toSet();

    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  /// Thuật toán chấm điểm và xếp hạng tài liệu (Content-Based Multi-Factor Scoring)
  List<ScoredDocument> getRecommendations({
    required List<StudyDocument> allDocuments,
    required String currentUserId,
    String currentUserEmail = '',
    int limit = 6,
  }) {
    if (allDocuments.isEmpty) return [];

    final activeInterests = getActiveInterests(
      allDocuments: allDocuments,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );

    final userCourses = extractUserCourses(
      allDocuments: allDocuments,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );

    final List<ScoredDocument> scoredList = [];

    for (var doc in allDocuments) {
      final isOwn = (currentUserId.isNotEmpty && doc.ownerId == currentUserId) ||
          (currentUserEmail.isNotEmpty && doc.ownerEmail.toLowerCase() == currentUserEmail.toLowerCase());

      double score = 0.0;
      final List<String> reasons = [];
      final List<String> matched = [];

      // 1. Trọng số Tag Matching (Tối đa 45 điểm)
      final docTags = doc.tags.map((t) => t.trim().toLowerCase()).toList();
      for (var t in docTags) {
        if (activeInterests.contains(t)) {
          matched.add(t);
        }
      }

      final jaccard = calculateJaccardSimilarity(docTags, activeInterests);
      if (jaccard > 0 || matched.isNotEmpty) {
        final tagScore = (jaccard * 25.0) + (matched.length.clamp(1, 4) * 5.0);
        score += tagScore.clamp(0.0, 45.0);
        reasons.add('Khớp sở thích #${matched.take(2).join(", #")}');
      }

      // 2. Trọng số Môn học (Tối đa 25 điểm)
      if (doc.courseId.trim().isNotEmpty &&
          userCourses.contains(doc.courseId.trim().toLowerCase())) {
        score += 25.0;
        reasons.add('Cùng học phần [${doc.courseId.toUpperCase()}]');
      }

      // 3. Trọng số File đính kèm Cloud (Tối đa 10 điểm)
      if (doc.fileUrl.isNotEmpty) {
        score += 10.0;
        reasons.add('Có file đọc trực tiếp');
      }

      // 4. Trọng số Vị trí vật lý & Sẵn sàng cho mượn (Tối đa 10 điểm)
      if (doc.physicalLocation.isNotEmpty && doc.borrowStatus == 'available') {
        score += 10.0;
        final locShort = doc.physicalLocation.split('-').first.trim();
        reasons.add('Có sẵn bản cứng tại $locShort');
      }

      // 5. Trọng số Đánh dấu quan trọng (Tối đa 10 điểm)
      if (doc.isPinned) {
        score += 10.0;
        reasons.add('Tài liệu được ghim nổi bật');
      }

      // Thưởng điểm khám phá tri thức từ người dùng khác (Community exploration)
      if (!isOwn) {
        score += 5.0;
        final author = doc.ownerName.isNotEmpty ? doc.ownerName : 'Cộng đồng';
        reasons.add('Chia sẻ bởi $author');
      } else {
        if (doc.status == DocumentStatus.inProgress) {
          score += 5.0;
          reasons.add('Đang học dở');
        }
      }

      // Điểm sàn tối thiểu
      if (score < 10.0) {
        score = 10.0 + (doc.isPinned ? 15.0 : 0.0);
        reasons.add('Tài liệu đề xuất chung');
      }

      final normalizedScore = score.clamp(5.0, 100.0);

      scoredList.add(ScoredDocument(
        document: doc,
        score: normalizedScore,
        reason: reasons.take(2).join(' • '),
        matchedTags: matched,
        isOwnDocument: isOwn,
      ));
    }

    // Sắp xếp theo điểm số giảm dần
    scoredList.sort((a, b) => b.score.compareTo(a.score));

    return scoredList.take(limit).toList();
  }
}
