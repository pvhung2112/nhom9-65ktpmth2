import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../struct/studyGoal.dart';
import '../database/study_goal_dao.dart';

class StudyGoalsPage extends StatelessWidget {
  const StudyGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goalDao = GoalDao();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Mục tiêu học tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Thêm mục tiêu',
            onPressed: () {
              final titleCtrl = TextEditingController();
              final countCtrl = TextEditingController(text: '5');

              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Mục tiêu mới'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Mục tiêu học tập')),
                      TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số tài liệu cần hoàn thành')),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        final count = int.tryParse(countCtrl.text) ?? 5;
                        if (title.isNotEmpty) {
                          await goalDao.insert(StudyGoal(
                            id: const Uuid().v4(),
                            title: title,
                            targetCount: count,
                            deadline: DateTime.now().add(const Duration(days: 14)),
                          ));
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Thêm'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<StudyGoal>>(
        stream: goalDao.watchAll(),
        initialData: goalDao.getAll(),
        builder: (context, snapshot) {
          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return const Center(child: Text('Chưa có mục tiêu học tập nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final g = goals[index];
              final percent = g.progressPercentage;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(g.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${(percent * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF1E88E5),
                        borderRadius: BorderRadius.circular(6),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Đã hoàn thành ${g.completedCount}/${g.targetCount} bài', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                            tooltip: 'Tăng tiến độ',
                            onPressed: () async {
                              await goalDao.update(g.copyWith(completedCount: g.completedCount + 1));
                            },
                          ),
                        ],
                      ),
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
