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
    final nameCtrl = TextEditingController();
    final buildingCtrl = TextEditingController(text: 'Tòa A');
    final floorCtrl = TextEditingController(text: 'Tầng 3');
    final roomCtrl = TextEditingController(text: 'Phòng A305');
    final cabinetCtrl = TextEditingController(text: 'Tủ số 2');
    final shelfCtrl = TextEditingController(text: 'Ngăn số 3');
    final latCtrl = TextEditingController(text: '10.8708');
    final lngCtrl = TextEditingController(text: '106.8025');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warehouse_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text('Thêm Kho / Vị Trí Cất Giữ Mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tên địa điểm / Tên kho:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Tòa A - Phòng A305 hoặc Thư viện H1',
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
                        decoration: const InputDecoration(labelText: 'Tòa nhà', border: OutlineInputBorder(), isDense: true),
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
                        decoration: const InputDecoration(labelText: 'Vĩ độ GPS', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        decoration: const InputDecoration(labelText: 'Kinh độ GPS', border: OutlineInputBorder(), isDense: true),
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
                name = '${buildingCtrl.text.trim()} - ${roomCtrl.text.trim()}';
              }
              final newLoc = StorageLocationItem(
                id: const Uuid().v4(),
                name: name,
                building: buildingCtrl.text.trim(),
                floor: floorCtrl.text.trim(),
                room: roomCtrl.text.trim(),
                cabinet: cabinetCtrl.text.trim(),
                shelf: shelfCtrl.text.trim(),
                latitude: double.tryParse(latCtrl.text.trim()) ?? 10.8708,
                longitude: double.tryParse(lngCtrl.text.trim()) ?? 106.8025,
              );
              await _db.insertStorageLocation(newLoc);
              _supabase.insertStorageLocationOnline(newLoc);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Lưu Vị Trí Kho'),
          ),
        ],
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
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(l.name),
                                        content: InteractiveLocationMap(
                                          location: PhysicalLocation(
                                            locationName: l.name,
                                            campusName: l.building,
                                            shelfNumber: '${l.cabinet} - ${l.shelf}',
                                            latitude: l.latitude,
                                            longitude: l.longitude,
                                            floor: l.floor,
                                          ),
                                          documentTitle: '${docsInLoc.length} tài liệu cất giữ tại đây',
                                        ),
                                      ),
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
