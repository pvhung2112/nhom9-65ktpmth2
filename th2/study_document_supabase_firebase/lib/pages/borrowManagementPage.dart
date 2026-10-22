import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/borrow_request.dart';
import '../services/supabase_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/notification_service.dart';

class BorrowManagementPage extends StatefulWidget {
  const BorrowManagementPage({super.key});

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

  Future<void> _loadRequests() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    final myReqs = await _supabase.fetchBorrowRequests(borrowerEmail: user.email);
    final incomingReqs = await _supabase.fetchBorrowRequests(ownerEmail: user.email);

    setState(() {
      _myRequests = myReqs;
      _incomingRequests = incomingReqs;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(BorrowRequest req, BorrowStatus newStatus) async {
    final ok = await _supabase.updateBorrowRequestStatus(req.id, newStatus);
    if (ok) {
      NotificationService().addNotification(
        title: 'Cập nhật mượn/trả tài liệu',
        message: 'Tài liệu "${req.documentTitle}" đã chuyển sang trạng thái: ${newStatus.displayName}',
        color: newStatus == BorrowStatus.approved ? Colors.green : Colors.orange,
      );
      _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã cập nhật trạng thái: ${newStatus.displayName}'),
            backgroundColor: Colors.teal.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Quản lý Mượn & Trả Tài liệu (TH2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới danh sách',
            onPressed: _loadRequests,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFD81B60),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFD81B60),
          tabs: [
            Tab(
              icon: const Icon(Icons.outbox_rounded, size: 18),
              text: 'Yêu cầu của tôi (${_myRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.inbox_rounded, size: 18),
              text: 'Yêu cầu gửi đến tôi (${_incomingRequests.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyRequestsTab(),
                _buildIncomingRequestsTab(),
              ],
            ),
    );
  }

  Widget _buildMyRequestsTab() {
    if (_myRequests.isEmpty) {
      return _buildEmptyState('Bạn chưa gửi yêu cầu mượn tài liệu nào', Icons.folder_open_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myRequests.length,
      itemBuilder: (context, index) {
        final r = _myRequests[index];
        return _buildRequestCard(r, isOwnerView: false);
      },
    );
  }

  Widget _buildIncomingRequestsTab() {
    if (_incomingRequests.isEmpty) {
      return _buildEmptyState('Chưa có yêu cầu mượn nào gửi đến tài liệu của bạn', Icons.mark_email_read_rounded);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _incomingRequests.length,
      itemBuilder: (context, index) {
        final r = _incomingRequests[index];
        return _buildRequestCard(r, isOwnerView: true);
      },
    );
  }

  Widget _buildRequestCard(BorrowRequest r, {required bool isOwnerView}) {
    Color statusColor;
    switch (r.status) {
      case BorrowStatus.pending:
        statusColor = Colors.orange;
        break;
      case BorrowStatus.approved:
      case BorrowStatus.borrowed:
        statusColor = Colors.green;
        break;
      case BorrowStatus.rejected:
        statusColor = Colors.red;
        break;
      case BorrowStatus.returned:
        statusColor = Colors.teal;
        break;
      case BorrowStatus.overdue:
        statusColor = Colors.red.shade900;
        break;
    }

    final df = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
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
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.book_rounded, color: Color(0xFFD81B60), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.documentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        isOwnerView ? 'Người mượn: ${r.borrowerName} (${r.borrowerEmail})' : 'Chủ tài liệu: ${r.ownerName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    r.status.displayName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('Hạn trả: ${df.format(r.dueDate)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                const Spacer(),
                if (r.notes.isNotEmpty)
                  Text('Ghi chú: ${r.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
            if (isOwnerView && r.status == BorrowStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Từ chối'),
                    onPressed: () => _updateStatus(r, BorrowStatus.rejected),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Phê duyệt mượn'),
                    onPressed: () => _updateStatus(r, BorrowStatus.approved),
                  ),
                ],
              ),
            ],
            if (isOwnerView && r.status == BorrowStatus.approved) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                  label: const Text('Xác nhận đã nhận lại sách'),
                  onPressed: () => _updateStatus(r, BorrowStatus.returned),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }
}
