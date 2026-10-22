import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../struct/studyCourse.dart';
import '../database/study_course_dao.dart';
import '../database/study_document_dao.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final _courseDao = CourseDao();
  final _documentDao = DocumentDao();

  void _showAddEditCourseDialog([Course? initialCourse]) {
    final isEdit = initialCourse != null;
    final codeController = TextEditingController(text: initialCourse?.code ?? '');
    final nameController = TextEditingController(text: initialCourse?.name ?? '');
    final lecturerController = TextEditingController(text: initialCourse?.lecturer ?? '');
    final creditsController = TextEditingController(text: '${initialCourse?.credits ?? 3}');
    int selectedColor = initialCourse?.colorValue ?? 0xFF1E88E5;

    final colorOptions = [
      0xFF1E88E5, // Xanh dương
      0xFF43A047, // Xanh lá
      0xFFFB8C00, // Cam
      0xFFE53935, // Đỏ
      0xFF8E24AA, // Tím
      0xFF00ACC1, // Xanh mòng két
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Chỉnh sửa Môn học' : 'Thêm Môn học mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Mã môn học (VD: SE301) *'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên môn học *'),
                ),
                TextField(
                  controller: lecturerController,
                  decoration: const InputDecoration(labelText: 'Giảng viên phụ trách'),
                ),
                TextField(
                  controller: creditsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số tín chỉ'),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Mã màu nhận diện:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colorOptions.map((c) {
                    final isSel = selectedColor == c;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: CircleAvatar(
                        backgroundColor: Color(c),
                        radius: 16,
                        child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
              onPressed: () async {
                final code = codeController.text.trim();
                final name = nameController.text.trim();
                if (code.isEmpty || name.isEmpty) return;

                if (isEdit) {
                  final updated = initialCourse.copyWith(
                    code: code,
                    name: name,
                    lecturer: lecturerController.text.trim(),
                    credits: int.tryParse(creditsController.text) ?? 3,
                    colorValue: selectedColor,
                  );
                  await _courseDao.update(updated);
                } else {
                  final newCourse = Course(
                    id: const Uuid().v4(),
                    code: code,
                    name: name,
                    lecturer: lecturerController.text.trim(),
                    credits: int.tryParse(creditsController.text) ?? 3,
                    colorValue: selectedColor,
                  );
                  await _courseDao.insert(newCourse);
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Danh mục Môn học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Thêm môn học',
            onPressed: () => _showAddEditCourseDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<Course>>(
        stream: _courseDao.watchAll(),
        initialData: _courseDao.getAll(),
        builder: (context, snapshot) {
          final courses = snapshot.data ?? [];
          final allDocs = _documentDao.getAll();

          if (courses.isEmpty) {
            return const Center(child: Text('Chưa có môn học nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final c = courses[index];
              final count = allDocs.where((d) => d.courseId == c.id).length;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(c.colorValue),
                    child: Text(c.code.substring(0, 2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text('${c.code} - ${c.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${c.lecturer.isNotEmpty ? c.lecturer + ' • ' : ''}${c.credits} tín chỉ • $count tài liệu'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'edit') {
                        _showAddEditCourseDialog(c);
                      } else if (val == 'delete') {
                        await _courseDao.delete(c.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa môn', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
