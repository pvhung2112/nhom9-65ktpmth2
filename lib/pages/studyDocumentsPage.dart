import '../models/physical_location.dart';
import '../widgets/interactive_location_map.dart';
import '../services/supabase_service.dart';
import '../struct/firebaseAuthService.dart';
import 'dart:async';

import '../struct/studySyncClient.dart';

import 'package:flutter/material.dart';

import '../struct/studyDocument.dart';



import '../database/study_document_dao.dart';



import '../widgets/studyDocumentCard.dart';

import 'addEditStudyDocumentPage.dart';





class StudyDocumentsPage extends StatefulWidget {

  const StudyDocumentsPage({super.key});



  @override

  State<StudyDocumentsPage> createState() => _StudyDocumentsPageState();

}



class _StudyDocumentsPageState extends State<StudyDocumentsPage> {

  final DocumentDao _documentDao = DocumentDao();

  

  final StudySyncClient _syncClient = StudySyncClient();



  int _selectedTabIndex = 0; // 0: Tất cả, 1: Bài giảng, 2: Bài tập, 3: Tham khảo

  String? _selectedTag;
  String? _selectedLocation;

  bool _isLoadingFromCloud = false;



  @override
  void initState() {
    super.initState();
    FirebaseAuthService().addListener(_onAuthChanged);
    _loadFromCloud();
  }

  @override
  void dispose() {
    FirebaseAuthService().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      _loadFromCloud();
    }
  }



  Future<void> _loadFromCloud() async {
    setState(() => _isLoadingFromCloud = true);
    try {
      final auth = FirebaseAuthService();
      final currentUser = auth.currentUser;

      if (currentUser != null) {
        // Kéo tài liệu từ Supabase Cloud
        final accessibleDocs = await SupabaseService().fetchAccessibleStudyDocuments(currentUser);
        // Đồng bộ chính xác theo Supabase: Kể cả khi Supabase đã xóa hết (0 tài liệu), ta vẫn xóa sạch cache
        await _documentDao.clearAll();
        for (var doc in accessibleDocs) {
          await _documentDao.insert(doc);
        }
        debugPrint('Đã đồng bộ ${accessibleDocs.length} tài liệu hợp lệ cho ${currentUser.email}');
      }
    } catch (e) {
      debugPrint('Load cloud error: $e');
    }
    if (mounted) {
      setState(() => _isLoadingFromCloud = false);
    }
  }



  DocumentType? _getCurrentTabType() {

    switch (_selectedTabIndex) {

      case 1:

        return DocumentType.lecture;

      case 2:

        return DocumentType.exercise;

      case 3:

        return DocumentType.reference;

      default:

        return null;

    }

  }



  @override

  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    final currentType = _getCurrentTabType();



    return Scaffold(

      backgroundColor: theme.colorScheme.background,

      floatingActionButton: FloatingActionButton.extended(

        backgroundColor: const Color(0xFFD81B60),

        foregroundColor: Colors.white,

        icon: const Icon(Icons.add_rounded),

        label: const Text('Thêm tài liệu'),

        onPressed: () {

          Navigator.push(

            context,

            MaterialPageRoute(builder: (_) => const AddEditDocumentPage()),

          );

        },

      ),

      body: CustomScrollView(

        slivers: [

          // Header Bar

          SliverToBoxAdapter(

            child: Padding(

              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),

              child: Row(

                children: [

                  Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Text(

                        'Kho Tài liệu Học tập',

                        style: TextStyle(

                          fontSize: 24,

                          fontWeight: FontWeight.bold,

                          letterSpacing: -0.5,

                        ),

                      ),

                      const SizedBox(height: 2),

                      Text(

                        'Lưu trữ bài giảng, bài tập và tài liệu tham khảo',

                        style: TextStyle(

                          fontSize: 13,

                          color: theme.colorScheme.onSurfaceVariant,

                        ),

                      ),

                    ],

                  ),

                  const Spacer(),

                  IconButton.filledTonal(

                    icon: _isLoadingFromCloud

                        ? const SizedBox(

                            width: 18,

                            height: 18,

                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD81B60)),

                          )

                        : const Icon(Icons.refresh_rounded),

                    tooltip: 'Làm mới từ Firebase Cloud',

                    onPressed: _isLoadingFromCloud ? null : _loadFromCloud,

                  ),

                  const SizedBox(width: 8),

                  IconButton.filledTonal(

                    icon: const Icon(Icons.location_city_rounded, color: Colors.teal),
                    tooltip: 'Quản lý vị trí lưu trữ & Bản đồ',
                    onPressed: () => _showLocationOverviewDialog(context),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.cloud_done_rounded, color: Color(0xFFD81B60)),

                    tooltip: 'Trạng thái Firebase Cloud',

                    onPressed: () => _showCloudDialog(context),

                  ),

                ],

              ),

            ),

          ),



          // Type Tab Pills

          SliverToBoxAdapter(

            child: Padding(

              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),

              child: Container(

                decoration: BoxDecoration(

                  color: theme.colorScheme.surface,

                  borderRadius: BorderRadius.circular(14),

                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),

                ),

                padding: const EdgeInsets.all(4),

                child: Row(

                  children: [

                    _buildTabPill('Tất cả', 0),

                    _buildTabPill('Bài giảng', 1),

                    _buildTabPill('Bài tập', 2),

                    _buildTabPill('Tham khảo', 3),

                  ],

                ),

              ),

            ),

          ),



          // Dynamic Tag & Location Filter Chips (Checklist 3)
          StreamBuilder<List<StudyDocument>>(
            stream: _documentDao.watchAll(),
            initialData: _documentDao.getAll(),
            builder: (context, snapshot) {
              final allDocs = snapshot.data ?? _documentDao.getAll();
              final allTags = <String>{};
              final allLocations = <String>{};
              for (final d in allDocs) {
                for (final t in d.tags) {
                  final trimmed = t.trim();
                  if (trimmed.isNotEmpty) allTags.add(trimmed);
                }
                if (d.physicalLocation.trim().isNotEmpty) {
                  allLocations.add(d.physicalLocation.trim());
                }
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hàng 1: Lọc nhanh theo Thẻ Tag
                      if (allTags.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildTagFilterChip(
                                label: 'Tất cả thẻ (${allDocs.length})',
                                icon: Icons.tag_rounded,
                                isSelected: _selectedTag == null,
                                onTap: () => setState(() => _selectedTag = null),
                              ),
                              const SizedBox(width: 8),
                              ...allTags.map((tag) {
                                final isSel = _selectedTag == tag;
                                final count = allDocs.where((d) => d.tags.contains(tag)).length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildTagFilterChip(
                                    label: '$tag ($count)',
                                    isSelected: isSel,
                                    onTap: () => setState(() => _selectedTag = isSel ? null : tag),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Hàng 2: Lọc theo Kho / Tòa nhà lưu trữ bản cứng ngoài đời
                      if (allLocations.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildLocationFilterChip(
                                label: 'Tất cả vị trí kho (${allDocs.length})',
                                icon: Icons.location_city_rounded,
                                isSelected: _selectedLocation == null,
                                onTap: () => setState(() => _selectedLocation = null),
                              ),
                              const SizedBox(width: 8),
                              ...allLocations.map((loc) {
                                final isSel = _selectedLocation == loc;
                                final count = allDocs.where((d) => d.physicalLocation == loc).length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildLocationFilterChip(
                                    label: '$loc ($count)',
                                    icon: Icons.place_rounded,
                                    isSelected: isSel,
                                    onTap: () => setState(() => _selectedLocation = isSel ? null : loc),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          // Document List

          StreamBuilder<List<StudyDocument>>(

            stream: _documentDao.watchAll(),

            initialData: _documentDao.getAll(),

            builder: (context, snapshot) {

              final allDocuments = snapshot.data ?? _documentDao.getAll();



              // Instant filter by Tab Type

              var documents = allDocuments;

              if (currentType != null) {

                documents = documents.where((d) => d.type == currentType).toList();

              }



              // Instant filter by Tag (Checklist 3)
              if (_selectedTag != null && _selectedTag!.isNotEmpty) {
                documents = documents.where((d) => d.tags.contains(_selectedTag)).toList();
              }

              // Instant filter by Vị trí kho lưu trữ (Checklist 3)
              if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
                documents = documents.where((d) => d.physicalLocation == _selectedLocation).toList();
              }

              // ƯU TIÊN TÀI LIỆU ĐÃ GHIM LÊN ĐẦU DANH SÁCH (PINNED FIRST)
              documents.sort((a, b) {
                if (a.isPinned && !b.isPinned) return -1;
                if (!a.isPinned && b.isPinned) return 1;
                return b.updatedAt.compareTo(a.updatedAt);
              });



              if (documents.isEmpty) {

                return SliverToBoxAdapter(

                  child: Center(

                    child: Padding(

                      padding: const EdgeInsets.all(40),

                      child: Column(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          Icon(Icons.menu_book_rounded, size: 56, color: Colors.grey.shade400),

                          const SizedBox(height: 12),

                          Text('Chưa có tài liệu nào trong danh mục này', style: TextStyle(color: Colors.grey.shade600)),

                        ],

                      ),

                    ),

                  ),

                );

              }



              return SliverPadding(

                padding: const EdgeInsets.symmetric(horizontal: 24),

                sliver: SliverList(

                  delegate: SliverChildBuilderDelegate(

                    (context, index) {

                      final doc = documents[index];

                      return Padding(

                        padding: const EdgeInsets.only(bottom: 12),

                        child: StudyDocumentCard(

                          document: doc,

                          onStatusChanged: (newStatus) async {

                            final updated = doc.copyWith(status: newStatus);

                            await _documentDao.update(updated);

                            unawaited(_syncClient.saveToCloud(updated));

                          },

                          onDelete: () async {
                            final currentUserId = FirebaseAuthService().currentUser?.id ?? '';
                            try {
                              await SupabaseService().deleteDocument(
                                documentId: doc.id,
                                currentUserId: currentUserId,
                              );
                            } catch (e) {
                              debugPrint('Lỗi xóa Supabase: $e');
                            }
                            await _documentDao.delete(doc.id);
                          },

                        ),

                      );

                    },

                    childCount: documents.length,

                  ),

                ),

              );

            },

          ),



          const SliverToBoxAdapter(child: SizedBox(height: 80)),

        ],

      ),

    );

  }



  Widget _buildTabPill(String label, int index) {

    final isSelected = _selectedTabIndex == index;

    return Expanded(

      child: InkWell(

        borderRadius: BorderRadius.circular(10),

        onTap: () {

          setState(() {

            _selectedTabIndex = index;

          });

        },

        child: Container(

          padding: const EdgeInsets.symmetric(vertical: 9),

          decoration: BoxDecoration(

            color: isSelected ? const Color(0xFFF7D8DF) : Colors.transparent,

            borderRadius: BorderRadius.circular(10),

          ),

          child: Center(

            child: Text(

              label,

              style: TextStyle(

                fontSize: 13,

                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,

                color: isSelected ? const Color(0xFFD81B60) : Colors.grey.shade700,

              ),

            ),

          ),

        ),

      ),

    );

  }



  Widget _buildTagFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7D8DF) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFD81B60) : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.label_outline_rounded,
              size: 14,
              color: isSelected ? const Color(0xFFD81B60) : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFD81B60) : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }



    void _showCloudDialog(BuildContext context) {
    final supabase = SupabaseService();
    final urlController = TextEditingController(text: supabase.supabaseUrl ?? '');
    final keyController = TextEditingController(text: supabase.supabaseAnonKey ?? '');
    bool isTestingSupabase = false;
    String statusMessage = supabase.connectionStatus;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final auth = FirebaseAuthService();
            final user = auth.currentUser;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7D8DF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: Color(0xFFD81B60),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản trị Cloud & Supabase',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Firebase Auth, Storage & Supabase Cloud PostgreSQL',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF7D8DF)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFD81B60),
                              child: Text(
                                (user != null && user.displayName.isNotEmpty) ? user.displayName[0].toUpperCase() : 'U',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? 'Người dùng',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  Text(
                                    'Vai trò: ${user?.role ?? "Editor"}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD81B60)),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 14),
                              label: const Text('Đăng xuất'),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await auth.signOut();
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Supabase Online Cloud Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.cloud_done_rounded, color: Colors.green.shade700, size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kết nối Supabase Cloud Online',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'Lưu trữ Cơ sở dữ liệu quan hệ PostgreSQL trên Cloud',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: urlController,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                labelText: 'Supabase Project URL',
                                hintText: 'https://xxxxxxxxxxxx.supabase.co',
                                prefixIcon: const Icon(Icons.link_rounded, size: 18),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: keyController,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                labelText: 'Supabase Project Anon Key',
                                hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                                prefixIcon: const Icon(Icons.key_rounded, size: 18),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Trạng thái: $statusMessage',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: supabase.isOnlineMode ? Colors.green.shade700 : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD81B60),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 11),
                                  ),
                                  icon: isTestingSupabase
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.check_circle_outline_rounded, size: 14),
                                  label: const Text('Lưu & Kết nối Online'),
                                  onPressed: isTestingSupabase
                                      ? null
                                      : () async {
                                          setDialogState(() => isTestingSupabase = true);
                                          supabase.configureOnline(
                                            url: urlController.text.trim(),
                                            anonKey: keyController.text.trim(),
                                          );
                                          final ok = await supabase.testConnection();
                                          setDialogState(() {
                                            isTestingSupabase = false;
                                            statusMessage = supabase.connectionStatus;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(ok
                                                    ? 'Kết nối Supabase Cloud Online thành công!'
                                                    : 'Kiểm tra kết nối: ${supabase.connectionStatus}'),
                                                backgroundColor: ok ? Colors.green : Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Hướng dẫn Supabase
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Cách lấy URL & Key từ Supabase Dashboard:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '1. Trên supabase.com/dashboard/organizations, bấm "+ New organization" rồi tạo dự án mới.\n'
                              '2. Mở SQL Editor, dán file schema.sql từ thư mục dự án và bấm Run.\n'
                              '3. Vào Settings > API, copy "Project URL" và "Project API keys (anon public)" dán vào ô trên.',
                              style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLocationFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade100 : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.teal.shade700 : Colors.teal.shade200,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.teal.shade900 : Colors.teal.shade700,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.teal.shade900 : Colors.teal.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationOverviewDialog(BuildContext context) {
    final allDocs = _documentDao.getAll();
    final Map<String, List<StudyDocument>> locationGroups = {};
    for (final doc in allDocs) {
      final loc = doc.physicalLocation.isNotEmpty ? doc.physicalLocation : 'Chưa phân bổ vị trí';
      locationGroups.putIfAbsent(loc, () => []).add(doc);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_city_rounded, color: Colors.teal, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUẢN LÝ VỊ TRÍ LƯU TRỮ VẬT LÝ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Danh mục chi tiết tài liệu theo từng kho, tòa nhà & kệ sách',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: locationGroups.isEmpty
                  ? const Center(child: Text('Chưa có dữ liệu vị trí tài liệu.'))
                  : ListView(
                      children: locationGroups.entries.map((entry) {
                        final locName = entry.key;
                        final docs = entry.value;
                        final firstDoc = docs.first;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.teal.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade50,
                                child: const Icon(Icons.business_rounded, color: Colors.teal, size: 20),
                              ),
                              title: Text(
                                locName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${docs.length} tài liệu bản cứng đang lưu trữ',
                                style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                              ),
                              children: [
                                const Divider(height: 1),
                                ...docs.map((d) => Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFFD81B60)),
                                    title: Text(d.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    subtitle: Text('Vị trí: ${d.shelfLocation}', style: const TextStyle(fontSize: 11, color: Colors.brown)),
                                    trailing: d.isPinned
                                        ? const Icon(Icons.push_pin_rounded, size: 14, color: Colors.amber)
                                        : null,
                                  ),
                                )),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.teal,
                                            side: const BorderSide(color: Colors.teal),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          icon: const Icon(Icons.filter_list_rounded, size: 16),
                                          label: const Text('Lọc tài liệu tại đây', style: TextStyle(fontSize: 12)),
                                          onPressed: () {
                                            setState(() => _selectedLocation = locName);
                                            Navigator.pop(ctx);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton.tonalIcon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.teal.shade100,
                                            foregroundColor: Colors.teal.shade900,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          icon: const Icon(Icons.map_rounded, size: 16),
                                          label: const Text('Xem bản đồ', style: TextStyle(fontSize: 12)),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            InteractiveLocationMap.showModal(
                                              context,
                                              location: PhysicalLocation(
                                                locationName: locName,
                                                campusName: firstDoc.physicalLocation,
                                                shelfNumber: firstDoc.shelfLocation,
                                                latitude: firstDoc.latitude != 0.0 ? firstDoc.latitude : 21.0010,
                                                longitude: firstDoc.longitude != 0.0 ? firstDoc.longitude : 105.8424,
                                                floor: 'Tầng 1',
                                              ),
                                              documentTitle: '${docs.length} tài liệu lưu tại $locName',
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

}
