import '../services/geocoding_service.dart';
import '../database/web_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/storage_location_model.dart';
import '../models/physical_location.dart';
import '../database/database_helper.dart';
import '../database/study_document_dao.dart';
import '../widgets/interactive_location_map.dart';
import '../services/supabase_service.dart';

class StorageLocationsPage extends StatefulWidget {
  const StorageLocationsPage({super.key});

  @override
  State<StorageLocationsPage> createState() => _StorageLocationsPageState();
}

class _StorageLocationsPageState extends State<StorageLocationsPage> {
  final AppDatabase _db = AppDatabase();
  final DocumentDao _docDao = DocumentDao();
  final SupabaseService _supabase = SupabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _syncOnlineLocations();
  }

  Future<void> _syncOnlineLocations() async {
    setState(() => _isLoading = true);
    try {
      final onlineLocs = await _supabase.fetchStorageLocationsOnline();
      await _db.replaceStorageLocations(onlineLocs);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddLocationDialog() {
    final searchCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final buildingCtrl = TextEditingController();
    final floorCtrl = TextEditingController(text: 'Tầng 1');
    final roomCtrl = TextEditingController();
    final cabinetCtrl = TextEditingController();
    final shelfCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    bool isSearching = false;
    List<PlaceSearchResult> searchResults = [];
    String? foundAddress;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.map_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text('Thêm Kho / Định Vị Bản Đồ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÌM KIẾM ĐỊA ĐIỂM BẤT KỲ QUA BẢN ĐỒ (KHÔNG FIX CỨNG)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.search_rounded, color: Colors.blue, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Tìm kiếm địa điểm bất kỳ trên bản đồ:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Nhập tên địa điểm, phố, trường, ngõ...',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onSubmitted: (val) async {
                                  if (val.trim().isEmpty) return;
                                  setDlgState(() => isSearching = true);
                                  final results = await GeocodingService().searchLocation(val);
                                  setDlgState(() {
                                    searchResults = results;
                                    isSearching = false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                              onPressed: isSearching ? null : () async {
                                final val = searchCtrl.text.trim();
                                if (val.isEmpty) return;
                                setDlgState(() => isSearching = true);
                                final results = await GeocodingService().searchLocation(val);
                                setDlgState(() {
                                  searchResults = results;
                                  isSearching = false;
                                });
                              },
                              icon: isSearching
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.search, size: 16),
                              label: const Text('Tìm'),
                            ),
                          ],
                        ),

                        // KẾT QUẢ TÌM KIẾM ĐỘNG
                        if (searchResults.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Chọn kết quả phù hợp để tự động điền:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 130),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: searchResults.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final r = searchResults[i];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.pin_drop_rounded, size: 18, color: Colors.redAccent),
                                    title: Text(r.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    subtitle: Text(r.displayName, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    onTap: () {
                                      setDlgState(() {
                                        nameCtrl.text = r.name;
                                        buildingCtrl.text = r.building;
                                        latCtrl.text = r.latitude.toStringAsFixed(5);
                                        lngCtrl.text = r.longitude.toStringAsFixed(5);
                                        foundAddress = r.displayName;
                                        searchResults = [];
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        if (foundAddress != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: Colors.teal),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    foundAddress!,
                                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.blue),
                                  tooltip: 'Mở Google Maps',
                                  onPressed: () {
                                    openUrlInNewTab('https://www.google.com/maps/search/?api=1&query=' + latCtrl.text + ',' + lngCtrl.text);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('Tên địa điểm / Tên kho:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên vị trí kho cất giữ',
                      prefixIcon: Icon(Icons.business_rounded),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: buildingCtrl,
                          decoration: const InputDecoration(labelText: 'Tòa nhà / Khu vực', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: floorCtrl,
                          decoration: const InputDecoration(labelText: 'Tầng', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: roomCtrl,
                          decoration: const InputDecoration(labelText: 'Phòng', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cabinetCtrl,
                          decoration: const InputDecoration(labelText: 'Tủ cất giữ', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: shelfCtrl,
                          decoration: const InputDecoration(labelText: 'Ngăn / Kệ', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latCtrl,
                          decoration: const InputDecoration(labelText: 'Vĩ độ GPS (tự động khi tìm)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lngCtrl,
                          decoration: const InputDecoration(labelText: 'Kinh độ GPS (tự động khi tìm)', border: OutlineInputBorder(), isDense: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                var name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  name = buildingCtrl.text.trim().isNotEmpty
                      ? '${buildingCtrl.text.trim()} - ${roomCtrl.text.trim()}'
                      : 'Kho Lưu Trữ Mới';
                }
                final newLoc = StorageLocationItem(
                  id: const Uuid().v4(),
                  name: name,
                  building: buildingCtrl.text.trim(),
                  floor: floorCtrl.text.trim(),
                  room: roomCtrl.text.trim(),
                  cabinet: cabinetCtrl.text.trim(),
                  shelf: shelfCtrl.text.trim(),
                  latitude: double.tryParse(latCtrl.text.trim()) ?? 21.0285,
                  longitude: double.tryParse(lngCtrl.text.trim()) ?? 105.8542,
                );
                await _db.insertStorageLocation(newLoc);
                _supabase.insertStorageLocationOnline(newLoc);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu Vị Trí Kho'),
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
                              color: Colors.teal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.warehouse_rounded, color: Colors.teal, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Quản lý Kho Tài Liệu',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quản lý nơi cất giữ tài liệu bản cứng: Tòa nhà, Tầng, Phòng, Tủ và Ngăn',
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
                    onPressed: _isLoading ? null : _syncOnlineLocations,
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text('Thêm Kho Mới', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _showAddLocationDialog,
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<List<StorageLocationItem>>(
            stream: _db.watchAllStorageLocations(),
            initialData: _db.getAllStorageLocations(),
            builder: (context, snapshot) {
              final locs = snapshot.data ?? _db.getAllStorageLocations();

              if (locs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_rounded, size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Chưa có kho lưu trữ nào. Nhấn "Thêm Kho Mới" để tạo!', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final l = locs[index];
                      final docsInLoc = allDocs.where((d) => d.physicalLocation == l.name).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.teal.shade200),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.teal.shade50,
                                  radius: 20,
                                  child: const Icon(Icons.apartment_rounded, color: Colors.teal, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'GPS: ${l.latitude.toStringAsFixed(4)}, ${l.longitude.toStringAsFixed(4)}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.teal.shade300),
                                  ),
                                  child: Text(
                                    '${docsInLoc.length} tài liệu',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                  tooltip: 'Xóa vị trí kho',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Xác nhận xóa'),
                                        content: Text('Bạn có chắc muốn xóa kho "${l.name}"?'),
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
                                      await _db.deleteStorageLocation(l.id);
                                      _supabase.deleteStorageLocationOnline(l.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildBadge(Icons.business_rounded, 'Tòa: ${l.building}'),
                                _buildBadge(Icons.stairs_rounded, 'Tầng: ${l.floor}'),
                                _buildBadge(Icons.meeting_room_rounded, 'Phòng: ${l.room}'),
                                _buildBadge(Icons.shelves, 'Tủ: ${l.cabinet}'),
                                _buildBadge(Icons.inventory_2_rounded, 'Ngăn: ${l.shelf}'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                    side: const BorderSide(color: Colors.teal),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.map_rounded, size: 16),
                                  label: const Text('Xem Bản Đồ Tòa Nhà', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    InteractiveLocationMap.showModal(
                                      context,
                                      location: PhysicalLocation(
                                        locationName: l.name,
                                        campusName: '${l.building} - ${l.room}',
                                        shelfNumber: '${l.cabinet} - ${l.shelf}',
                                        latitude: l.latitude,
                                        longitude: l.longitude,
                                        floor: l.floor,
                                      ),
                                      documentTitle: '${docsInLoc.length} tài liệu cất giữ tại đây',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: locs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.teal.shade800),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
