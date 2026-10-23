import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../struct/studyDocument.dart';
import '../models/storage_location_model.dart';
import '../models/physical_location.dart';
import '../models/tag_model.dart';
import '../models/borrow_request.dart';
import '../services/supabase_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/notification_service.dart';
import '../database/database_helper.dart';
import '../widgets/interactive_location_map.dart';

/// Trang "Nơi mượn tài liệu" (Khám phá các kho lưu trữ và mượn tài liệu từ tất cả người dùng)
class ExploreBorrowPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const ExploreBorrowPage({super.key, this.onNavigate});

  @override
  State<ExploreBorrowPage> createState() => _ExploreBorrowPageState();
}

class _ExploreBorrowPageState extends State<ExploreBorrowPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final AppDatabase _db = AppDatabase();

  List<StudyDocument> _allDocs = [];
  List<StorageLocationItem> _locations = [];
  List<DocumentTag> _tags = [];
  List<BorrowRequest> _myRequests = [];

  String? _selectedLocation;
  String? _selectedTag;
  String _searchQuery = '';
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Tải toàn bộ tài liệu cộng đồng từ Supabase Cloud
      final docs = await _supabaseService.fetchAllCommunityStudyDocuments();
      
      // 2. Tải danh sách kho lưu trữ & thẻ tag
      final locs = await _supabaseService.fetchStorageLocationsOnline();
      final tags = await _supabaseService.fetchTagsOnline();

      if (locs.isNotEmpty) {
        for (var l in locs) {
          _db.insertStorageLocation(l);
        }
      }
      if (tags.isNotEmpty) {
        for (var t in tags) {
          _db.insertTag(t);
        }
      }

      // 3. Tải danh sách yêu cầu mượn của tôi
      final user = _authService.currentUser;
      List<BorrowRequest> myReqs = [];
      if (user != null) {
        myReqs = await _supabaseService.fetchBorrowRequests(borrowerEmail: user.email);
      }

      setState(() {
        _allDocs = docs;
        _locations = _db.getAllStorageLocations();
        _tags = _db.getAllTags();
        _myRequests = myReqs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu Nơi mượn tài liệu: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showBorrowDialog(BuildContext context, StudyDocument doc) {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Vui lòng đăng nhập để gửi yêu cầu mượn tài liệu!')),
      );
      return;
    }

    if (user.email.toLowerCase() == doc.ownerEmail.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ℹ️ Bạn là chủ sở hữu của tài liệu này! Không cần gửi yêu cầu mượn.'),
          backgroundColor: Colors.blue.shade700,
        ),
      );
      return;
    }

    DateTime borrowDate = DateTime.now();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    final noteController = TextEditingController(text: 'Xin phép mượn tài liệu để phục vụ nghiên cứu & học tập.');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final days = dueDate.difference(borrowDate).inDays;
            final df = DateFormat('dd/MM/yyyy');

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
                    child: const Icon(Icons.bookmark_add_rounded, color: Color(0xFFD81B60), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Xin mượn tài liệu',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thông tin tài liệu
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1976D2)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_pin_rounded, size: 14, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(
                                  'Chủ sở hữu: ${doc.ownerName} (${doc.ownerEmail})',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: Colors.teal),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Kho: ${doc.physicalLocation} (${doc.shelfLocation})',
                                    style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chọn ngày mượn & ngày trả
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ngày mượn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: borrowDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                      lastDate: DateTime.now().add(const Duration(days: 60)),
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        borrowDate = picked;
                                        if (dueDate.isBefore(borrowDate)) {
                                          dueDate = borrowDate.add(const Duration(days: 7));
                                        }
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFFD81B60)),
                                        const SizedBox(width: 6),
                                        Text(df.format(borrowDate), style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ngày hẹn trả ($days ngày):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: dueDate,
                                      firstDate: borrowDate,
                                      lastDate: borrowDate.add(const Duration(days: 90)),
                                    );
                                    if (picked != null) {
                                      setDialogState(() => dueDate = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event_available_rounded, size: 14, color: Colors.teal),
                                        const SizedBox(width: 6),
                                        Text(df.format(dueDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Ghi chú / Lời nhắn
                      const Text('Ghi chú / Lời nhắn gửi chủ tài liệu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Nhập lý do mượn sách hoặc lời nhắn...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.orange, size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Sau khi gửi yêu cầu, bạn cần chờ Chủ sở hữu Phê duyệt (Accept) để được cấp quyền mượn.',
                                style: TextStyle(fontSize: 11, color: Colors.brown),
                              ),
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(isSubmitting ? 'Đang gửi...' : 'GỬI YÊU CẦU MƯỢN'),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final req = BorrowRequest(
                            id: 'br-${DateTime.now().millisecondsSinceEpoch}',
                            documentId: doc.id,
                            documentTitle: doc.title,
                            courseCode: '',
                            ownerId: doc.ownerId,
                            ownerName: doc.ownerName,
                            ownerEmail: doc.ownerEmail,
                            borrowerId: user.id,
                            borrowerName: user.displayName,
                            borrowerEmail: user.email,
                            requestDate: borrowDate,
                            dueDate: dueDate,
                            notes: noteController.text.trim(),
                            status: BorrowStatus.pending,
                            physicalLocation: doc.physicalLocation,
                            shelfLocation: doc.shelfLocation,
                            fileUrl: doc.fileUrl,
                          );

                          await _supabaseService.createBorrowRequest(req);
                          setDialogState(() => isSubmitting = false);

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            NotificationService().addNotification(
                              title: 'Đã gửi yêu cầu mượn tài liệu',
                              message: 'Đã gửi yêu cầu mượn "${doc.title}" tới ${doc.ownerName}. Vui lòng chờ phê duyệt.',
                              color: Colors.orange,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Đã gửi yêu cầu mượn tới ${doc.ownerName}! Đang chờ duyệt.'),
                                backgroundColor: Colors.teal.shade700,
                              ),
                            );
                            _loadData();
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLocationMap(StorageLocationItem loc) {
    final physical = PhysicalLocation(
      locationName: loc.name,
      shelfNumber: loc.shelfDetail,
      latitude: loc.latitude,
      longitude: loc.longitude,
    );
    InteractiveLocationMap.showModal(
      context,
      location: physical,
      documentTitle: 'Kho tài liệu: ${loc.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = _authService.currentUser;

    // Lọc danh sách tài liệu
    var filteredDocs = _allDocs;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredDocs = filteredDocs.where((d) {
        return d.title.toLowerCase().contains(q) ||
            d.description.toLowerCase().contains(q) ||
            d.ownerName.toLowerCase().contains(q) ||
            d.ownerEmail.toLowerCase().contains(q) ||
            d.physicalLocation.toLowerCase().contains(q) ||
            d.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filteredDocs = filteredDocs.where((d) => d.physicalLocation == _selectedLocation).toList();
    }

    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      filteredDocs = filteredDocs.where((d) => d.tags.contains(_selectedTag)).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: CustomScrollView(
        slivers: [
          // 1. Top Header Bar
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
                              color: const Color(0xFFF7D8DF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.explore_rounded, color: Color(0xFFD81B60), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Nơi mượn tài liệu',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Khám phá kho tài liệu của tất cả người dùng và gửi yêu cầu mượn sách',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD81B60)))
                        : const Icon(Icons.refresh_rounded),
                    tooltip: 'Làm mới danh sách',
                    onPressed: _isLoading ? null : _loadData,
                  ),
                ],
              ),
            ),
          ),

          // 2. Search Box
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tài liệu, chủ sở hữu, thẻ tag, hoặc tên kho...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD81B60)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ),
          ),

          // 3. Section: Các Kho tài liệu trong hệ thống
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  const Icon(Icons.warehouse_rounded, size: 18, color: Color(0xFF00796B)),
                  const SizedBox(width: 8),
                  const Text(
                    'Các kho lưu trữ tài liệu trong hệ thống',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_selectedLocation != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      icon: const Icon(Icons.clear, size: 14),
                      label: const Text('Xem tất cả kho', style: TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => _selectedLocation = null),
                    ),
                ],
              ),
            ),
          ),

          // Horizontal Warehouse Cards
          SliverToBoxAdapter(
            child: SizedBox(
              height: 105,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _locations.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAll = _selectedLocation == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 4),
                      child: InkWell(
                        onTap: () => setState(() => _selectedLocation = null),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 130,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAll ? const Color(0xFFD81B60) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAll ? const Color(0xFFD81B60) : Colors.grey.shade200,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.all_inclusive_rounded, color: isAll ? Colors.white : Colors.grey.shade700, size: 22),
                              const SizedBox(height: 6),
                              Text(
                                'Tất cả các kho',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isAll ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                '${_allDocs.length} tài liệu',
                                style: TextStyle(fontSize: 11, color: isAll ? Colors.white70 : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final loc = _locations[index - 1];
                  final isSelected = _selectedLocation == loc.name;
                  final docCount = _allDocs.where((d) => d.physicalLocation == loc.name).length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 4),
                    child: InkWell(
                      onTap: () => setState(() => _selectedLocation = isSelected ? null : loc.name),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 190,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Colors.teal : Colors.grey.shade200,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_city_rounded, color: isSelected ? Colors.teal.shade700 : const Color(0xFF00796B), size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    loc.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.teal.shade900 : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              loc.shelfDetail.isNotEmpty ? loc.shelfDetail : loc.building,
                              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade100.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$docCount tài liệu',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _showLocationMap(loc),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.map_rounded, size: 12, color: Colors.teal),
                                      SizedBox(width: 2),
                                      Text('Bản đồ', style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. Section: Thẻ Tags
          if (_tags.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      ..._tags.map((t) {
                        final isSel = _selectedTag == t.name;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(t.name, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                            selected: isSel,
                            selectedColor: const Color(0xFF1976D2),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: isSel ? const Color(0xFF1976D2) : Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            onSelected: (val) => setState(() => _selectedTag = val ? t.name : null),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 5. Section: Danh sách tài liệu
          if (filteredDocs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty || _selectedLocation != null || _selectedTag != null
                            ? 'Không tìm thấy tài liệu phù hợp với bộ lọc'
                            : 'Chưa có tài liệu nào trong kho',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = filteredDocs[index];
                    final isMyDoc = currentUser != null && currentUser.email.toLowerCase() == doc.ownerEmail.toLowerCase();
                    
                    // Kiểm tra trạng thái yêu cầu mượn hiện tại của tôi
                    final existingReq = _myRequests.where((r) => r.documentId == doc.id).firstOrNull;
                    final isPending = existingReq != null && existingReq.status == BorrowStatus.pending;
                    final isApproved = existingReq != null && (existingReq.status == BorrowStatus.approved || existingReq.status == BorrowStatus.borrowed);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Type + Status
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1976D2).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    doc.type.name == 'lecture' ? 'Bài giảng' : (doc.type.name == 'exercise' ? 'Bài tập' : 'Tham khảo'),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isMyDoc)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: const Text('Tài liệu của bạn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                  )
                                else if (isApproved)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.teal.shade300),
                                    ),
                                    child: const Text('✅ Bạn đang mượn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                                  )
                                else if (isPending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.orange.shade300),
                                    ),
                                    child: const Text('⏳ Đang chờ duyệt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Sẵn sàng cho mượn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ),
                                const Spacer(),
                                // Tên chủ sở hữu
                                CircleAvatar(
                                  radius: 11,
                                  backgroundColor: const Color(0xFFD81B60),
                                  child: Text(doc.ownerName.isNotEmpty ? doc.ownerName[0] : 'U', style: const TextStyle(color: Colors.white, fontSize: 9)),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  doc.ownerName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Document Title
                            Text(
                              doc.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),

                            if (doc.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                doc.description,
                                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            // Tags
                            if (doc.tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: doc.tags.map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF90CAF9), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.label_rounded, size: 11, color: Color(0xFF1976D2)),
                                      const SizedBox(width: 3),
                                      Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                                    ],
                                  ),
                                )).toList(),
                              ),
                            ],

                            const SizedBox(height: 10),

                            // Vị trí lưu trữ & Nút xem bản đồ
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2F1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF80CBC4), width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF00796B)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Kho: ${doc.physicalLocation} (${doc.shelfLocation})',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF004D40)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      final loc = PhysicalLocation(
                                        locationName: doc.physicalLocation,
                                        shelfNumber: doc.shelfLocation,
                                        latitude: doc.latitude != 0.0 ? doc.latitude : 21.00699,
                                        longitude: doc.longitude != 0.0 ? doc.longitude : 105.8251,
                                      );
                                      InteractiveLocationMap.showModal(
                                        context,
                                        location: loc,
                                        documentTitle: doc.title,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00796B),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.map_rounded, size: 11, color: Colors.white),
                                          SizedBox(width: 3),
                                          Text('Bản đồ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Footer: Action Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Chủ sở hữu: ${doc.ownerName}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                ),
                                if (isMyDoc)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.person, size: 14),
                                    label: const Text('Tài liệu của bạn', style: TextStyle(fontSize: 11)),
                                    onPressed: null,
                                  )
                                else if (isApproved)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.check_circle_rounded, size: 14),
                                    label: const Text('Đang mượn (Đã duyệt)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      if (widget.onNavigate != null) {
                                        widget.onNavigate!(3); // Chuyển tới Tài liệu đang mượn
                                      }
                                    },
                                  )
                                else if (isPending)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange.shade800,
                                      side: BorderSide(color: Colors.orange.shade400),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.hourglass_top_rounded, size: 14),
                                    label: const Text('Đã gửi yêu cầu (Chờ duyệt)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      if (widget.onNavigate != null) {
                                        widget.onNavigate!(3);
                                      }
                                    },
                                  )
                                else
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD81B60),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.send_rounded, size: 14),
                                    label: const Text('XIN MƯỢN TÀI LIỆU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () => _showBorrowDialog(context, doc),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filteredDocs.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}
