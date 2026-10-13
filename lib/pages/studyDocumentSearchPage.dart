import 'package:flutter/material.dart';
import '../struct/studyDocument.dart';
import '../struct/studyCourse.dart';
import '../database/study_document_dao.dart';
import '../database/study_course_dao.dart';
import '../widgets/studyDocumentCard.dart';

class DocumentSearchPage extends StatefulWidget {
  const DocumentSearchPage({super.key});

  @override
  State<DocumentSearchPage> createState() => _DocumentSearchPageState();
}

class _DocumentSearchPageState extends State<DocumentSearchPage> {
  final _documentDao = DocumentDao();
  final _courseDao = CourseDao();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCourseId;
  DocumentType? _selectedType;
  DocumentStatus? _selectedStatus;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _courses = _courseDao.getAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCourseId = null;
      _selectedType = null;
      _selectedStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _documentDao.filterDocuments(
      query: _searchQuery,
      courseId: _selectedCourseId,
      type: _selectedType,
      status: _selectedStatus,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm tài liệu, bài tập, tag...',
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        actions: [
          if (_searchQuery.isNotEmpty || _selectedCourseId != null || _selectedType != null || _selectedStatus != null)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded),
              tooltip: 'Xóa bộ lọc',
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                DropdownButton<String?>(
                  value: _selectedCourseId,
                  hint: const Text('Tất cả môn'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả môn')),
                    ..._courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.code))),
                  ],
                  onChanged: (val) => setState(() => _selectedCourseId = val),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Bài giảng'),
                  selected: _selectedType == DocumentType.lecture,
                  onSelected: (val) => setState(() => _selectedType = val ? DocumentType.lecture : null),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Bài tập'),
                  selected: _selectedType == DocumentType.exercise,
                  onSelected: (val) => setState(() => _selectedType = val ? DocumentType.exercise : null),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Tham khảo'),
                  selected: _selectedType == DocumentType.reference,
                  onSelected: (val) => setState(() => _selectedType = val ? DocumentType.reference : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Đã xong'),
                  selected: _selectedStatus == DocumentStatus.completed,
                  onSelected: (val) => setState(() => _selectedStatus = val ? DocumentStatus.completed : null),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search Results
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Không tìm thấy tài liệu phù hợp', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final doc = results[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StudyDocumentCard(
                          document: doc,
                          onStatusChanged: (newStatus) async {
                            await _documentDao.update(doc.copyWith(status: newStatus));
                            setState(() {});
                          },
                          onDelete: () async {
                            await _documentDao.delete(doc.id);
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
