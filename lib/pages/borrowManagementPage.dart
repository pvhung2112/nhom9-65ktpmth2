import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/borrow_request.dart';
import '../models/physical_location.dart';
import '../services/supabase_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/notification_service.dart';
import '../database/database_helper.dart';
import '../widgets/interactive_location_map.dart';

class BorrowManagementPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const BorrowManagementPage({super.key, this.onNavigate});

  @override
  State<BorrowManagementPage> createState() => _BorrowManagementPageState();
}

class _BorrowManagementPageState extends State<BorrowManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabase = SupabaseService();
  final FirebaseAuthService _auth = FirebaseAuthService();

  List<BorrowRequest> _myRequests = [];
  List<BorrowRequest> _incomingRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    final myReqs = await _supabase.fetchBorrowRequests(borrowerEmail: user.email);
    final incomingReqs = await _supabase.fetchBorrowRequests(ownerEmail: user.email);

    if (mounted) {
      setState(() {
        _myRequests = myReqs;
        _incomingRequests = incomingReqs;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(BorrowRequest req, BorrowStatus newStatus) async {
    final ok = await _supabase.updateBorrowRequestStatus(req.id, newStatus);
    if (ok) {
      final msg = newStatus == BorrowStatus.approved
          ? 'Đã CHẤP NHẬN (Accept) cho "${req.borrowerName}" mượn tài liệu "${req.documentTitle}"!'
          : (newStatus == BorrowStatus.rejected
              ? 'Đã từ chối yêu cầu mượn tài liệu "${req.documentTitle}".'
              : 'Trạng thái mượn tài liệu đã được cập nhật: ${newStatus.displayName}');

      NotificationService().addNotification(
        title: 'Cập nhật mượn tài liệu',
        message: msg,
        color: newStatus == BorrowStatus.approved ? Colors.green : Colors.orange,
      );

      _loadRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $msg'),
            backgroundColor: newStatus == BorrowStatus.approved ? Colors.green.shade700 : Colors.teal.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showLocationMap(BorrowRequest req) {
    double lat = 21.00699;
    double lng = 105.8251;
    if (req.physicalLocation.isNotEmpty) {
      final locItem = AppDatabase()
          .getAllStorageLocations()
          .where((l) => l.name.toLowerCase().trim() == req.physicalLocation.toLowerCase().trim())
          .firstOrNull;
      if (locItem != null && locItem.latitude != 0.0) {
        lat = locItem.latitude;
        lng = locItem.longitude;
      }
    }

    final loc = PhysicalLocation(
      locationName: req.physicalLocation.isNotEmpty ? req.physicalLocation : 'Thư viện Trung tâm - Tòa H1',
      shelfNumber: req.shelfLocation.isNotEmpty ? req.shelfLocation : 'Kệ A3 - Ngăn 02',
      latitude: lat,
      longitude: lng,
    );

    InteractiveLocationMap.showModal(
      context,
      location: loc,
      documentTitle: req.documentTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomingPending = _incomingRequests.where((r) => r.status == BorrowStatus.pending).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          'Tài liệu đang mượn của tôi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD81B60)),
            tooltip: 'Làm mới dữ liệu',
            onPressed: _loadRequests,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD81B60),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFFD81B60),
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_added_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Tài liệu tôi đang mượn (${_myRequests.where((r) => r.status == BorrowStatus.approved || r.status == BorrowStatus.borrowed).length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Duyệt yêu cầu mượn (${incomingPending.length})'),
                  if (incomingPending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${incomingPending.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD81B60)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyBorrowedTab(),
                _buildIncomingRequestsTab(incomingPending),
              ],
            ),
    );
  }

  // TAB 1: TÀI LIỆU TÔI ĐANG MƯỢN (Đã được chủ tài liệu Accept + Đang chờ duyệt)
  Widget _buildMyBorrowedTab() {
    final approvedList = _myRequests.where((r) => r.status == BorrowStatus.approved || r.status == BorrowStatus.borrowed).toList();
    final pendingList = _myRequests.where((r) => r.status == BorrowStatus.pending).toList();
    final otherList = _myRequests.where((r) => r.status != BorrowStatus.approved && r.status != BorrowStatus.borrowed && r.status != BorrowStatus.pending).toList();

    if (_myRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7D8DF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFFD81B60)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn chưa có tài liệu nào đang mượn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy vào mục "Nơi mượn tài liệu" để khám phá các kho lưu trữ và gửi yêu cầu mượn tài liệu học tập nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Đến Nơi mượn tài liệu'),
                onPressed: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(2); // Chuyển sang Nơi mượn tài liệu (index 2)
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    final df = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. TÀI LIỆU ĐÃ ĐƯỢC DUYỆT MƯỢN (ĐANG MƯỢN)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.green, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'TÀI LIỆU ĐÃ ĐƯỢC CHẤP NHẬN MƯỢN (${approvedList.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (approvedList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chưa có tài liệu nào được chấp nhận mượn. Các yêu cầu đã gửi đang chờ chủ sở hữu phê duyệt ở bên dưới.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          )
        else
          ...approvedList.map((r) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.green.shade200, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.documentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(
                                'Chủ tài liệu: ${r.ownerName} (${r.ownerEmail})',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 13, color: Colors.green),
                              SizedBox(width: 4),
                              Text('ĐÃ CHẤP NHẬN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Thời hạn & Vị trí kho nhận sách
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 5),
                        Text(
                          'Mượn: ${df.format(r.requestDate)}  →  Hạn trả: ${df.format(r.dueDate)}',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    if (r.physicalLocation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF80CBC4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF00796B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Vị trí kho lấy sách: ${r.physicalLocation}${r.shelfLocation.isNotEmpty ? ' (${r.shelfLocation})' : ''}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF004D40)),
                              ),
                            ),
                            InkWell(
                              onTap: () => _showLocationMap(r),
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
                                    Text('Xem bản đồ', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (r.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Ghi chú mượn: "${r.notes}"', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 20),

        // 2. YÊU CẦU ĐANG CHỜ CHỦ SỞ HỮU DUYỆT (PENDING)
        if (pendingList.isNotEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'YÊU CẦU ĐANG CHỜ PHÊ DUYỆT (${pendingList.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...pendingList.map((r) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.orange.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.documentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('Chủ tài liệu: ${r.ownerName} (${r.ownerEmail})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_top_rounded, size: 12, color: Colors.orange),
                              SizedBox(width: 4),
                              Text('Chờ phê duyệt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Text('Ngày gửi: ${df.format(r.requestDate)}  •  Hẹn trả: ${df.format(r.dueDate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                        const Spacer(),
                        if (r.notes.isNotEmpty)
                          Text('Ghi chú: ${r.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        // 3. YÊU CẦU ĐÃ TỪ CHỐI
        if (otherList.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('YÊU CẦU ĐÃ TỪ CHỐI HOẶC KẾT THÚC (${otherList.length})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          ...otherList.map((r) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                dense: true,
                title: Text(r.documentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Chủ tài liệu: ${r.ownerName} • Trạng thái: ${r.status.displayName}', style: const TextStyle(fontSize: 11)),
                trailing: Text(r.status.displayName, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            );
          }),
        ],
      ],
    );
  }

  // TAB 2: DUYỆT YÊU CẦU MƯỢN TÀI LIỆU CỦA TÔI (CHỜ TÔI ACCEPT)
  Widget _buildIncomingRequestsTab(List<BorrowRequest> pendingList) {
    final processedList = _incomingRequests.where((r) => r.status != BorrowStatus.pending).toList();
    final df = DateFormat('dd/MM/yyyy');

    if (_incomingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.mark_email_read_rounded, size: 48, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('Chưa có yêu cầu mượn nào gửi đến bạn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Khi người dùng khác gửi yêu cầu xin mượn tài liệu của bạn, yêu cầu sẽ xuất hiện ở đây để bạn xem xét và Chấp nhận (Accept).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Banner hướng dẫn
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7D8DF).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF7D8DF)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFD81B60), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dưới đây là các yêu cầu mượn tài liệu do người khác gửi tới. Bạn nhấn [Chấp nhận cho mượn] để phê duyệt cho họ mượn sách nhé!',
                  style: TextStyle(fontSize: 12, color: Color(0xFF880E4F), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // YÊU CẦU CHỜ DUYỆT (PENDING)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'YÊU CẦU CHỜ BẠN DUYỆT (${pendingList.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (pendingList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade400, size: 20),
                const SizedBox(width: 10),
                const Text('Tất cả yêu cầu đã được xử lý! Không còn yêu cầu nào chờ duyệt.', style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          )
        else
          ...pendingList.map((r) {
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.orange.shade300, width: 1.4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF1976D2),
                          child: Text(r.borrowerName.isNotEmpty ? r.borrowerName[0] : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.borrowerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(r.borrowerEmail, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: const Text('Xin mượn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ),
                      ],
                    ),
                    const Divider(height: 18),

                    // Tên tài liệu
                    Text('Tài liệu xin mượn:', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 2),
                    Text(r.documentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1976D2))),
                    const SizedBox(height: 8),

                    // Thời gian
                    Row(
                      children: [
                        Icon(Icons.date_range_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 5),
                        Text('Thời gian mượn: ${df.format(r.requestDate)} → Hạn trả: ${df.format(r.dueDate)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),

                    if (r.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text('Lời nhắn của người mượn: "${r.notes}"', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic)),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 2 Nút hành động: CHẤP NHẬN (ACCEPT) & TỪ CHỐI (REJECT)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Từ chối'),
                          onPressed: () => _updateStatus(r, BorrowStatus.rejected),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_rounded, size: 17),
                          label: const Text('CHẤP NHẬN (ACCEPT)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => _updateStatus(r, BorrowStatus.approved),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 24),

        // LỊCH SỬ CÁC YÊU CẦU ĐÃ XỬ LÝ
        if (processedList.isNotEmpty) ...[
          Text('LỊCH SỬ CÁC YÊU CẦU ĐÃ XỬ LÝ (${processedList.length})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          ...processedList.map((r) {
            final isApp = r.status == BorrowStatus.approved || r.status == BorrowStatus.borrowed;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                dense: true,
                title: Text(r.documentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Người mượn: ${r.borrowerName} (${r.borrowerEmail}) • Hạn: ${df.format(r.dueDate)}', style: const TextStyle(fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isApp ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isApp ? 'Đã chấp nhận' : r.status.displayName,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isApp ? Colors.green : Colors.red),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
