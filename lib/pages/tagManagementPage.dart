import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/tag_model.dart';
import '../database/database_helper.dart';
import '../database/study_document_dao.dart';
import '../services/supabase_service.dart';

class TagManagementPage extends StatefulWidget {
  const TagManagementPage({super.key});

  @override
  State<TagManagementPage> createState() => _TagManagementPageState();
}

class _TagManagementPageState extends State<TagManagementPage> {
  final AppDatabase _db = AppDatabase();
  final DocumentDao _docDao = DocumentDao();
  final SupabaseService _supabase = SupabaseService();
  bool _isLoading = false;

  final List<String> _presetColors = [
    '#D81B60', // Pink / Cashew
    '#1E88E5', // Blue
    '#43A047', // Green
    '#FB8C00', // Orange
    '#8E24AA', // Purple
    '#E53935', // Red
    '#00ACC1', // Cyan
    '#5D4037', // Brown
  ];

  @override
  void initState() {
    super.initState();
    _syncOnlineTags();
  }

  Future<void> _syncOnlineTags() async {
    setState(() => _isLoading = true);
    try {
      final onlineTags = await _supabase.fetchTagsOnline();
      await _db.replaceTags(onlineTags);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Color _hexToColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFFD81B60);
    }
  }

  void _showAddTagDialog() {
    final nameController = TextEditingController();
    String selectedColor = _presetColors.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.label_rounded, color: Color(0xFFD81B60)),
              SizedBox(width: 8),
              Text('Thêm Thẻ Tag Mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tên thẻ tag phân loại:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: Cơ sở dữ liệu, Java, Đồ án...',
                  prefixIcon: Icon(Icons.tag_rounded),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Chọn màu sắc nhận diện:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((colorHex) {
                  final isSel = selectedColor == colorHex;
                  final c = _hexToColor(colorHex);
                  return InkWell(
                    onTap: () => setDlgState(() => selectedColor = colorHex),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: c,
                      child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final newTag = DocumentTag(
                  id: const Uuid().v4(),
                  name: name,
                  color: selectedColor,
                );
                await _db.insertTag(newTag);
                _supabase.insertTagOnline(newTag);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Tạo Tag'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDocs = _docDao.getAll();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD81B60).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.label_rounded, color: Color(0xFFD81B60), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Quản lý Thẻ Tag',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phân loại và tìm kiếm tài liệu theo chủ đề (Checklist 3)',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded),
                    tooltip: 'Đồng bộ từ Supabase Cloud',
                    onPressed: _isLoading ? null : _syncOnlineTags,
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD81B60),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm Thẻ Tag', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _showAddTagDialog,
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<List<DocumentTag>>(
            stream: _db.watchAllTags(),
            initialData: _db.getAllTags(),
            builder: (context, snapshot) {
              final tags = snapshot.data ?? _db.getAllTags();

              if (tags.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.label_off_rounded, size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Chưa có thẻ tag nào. Nhấn "Thêm Thẻ Tag" để tạo mới!', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 110,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final t = tags[index];
                      final tagColor = _hexToColor(t.color);
                      final docCount = allDocs.where((d) => d.tags.contains(t.name)).length;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: tagColor.withOpacity(0.3), width: 1.2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: tagColor.withOpacity(0.15),
                              radius: 20,
                              child: Icon(Icons.tag_rounded, color: tagColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    t.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$docCount tài liệu đang dùng',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              tooltip: 'Xóa tag',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: Text('Bạn có chắc muốn xóa thẻ tag "${t.name}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _db.deleteTag(t.id);
                                  _supabase.deleteTagOnline(t.id);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: tags.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
