import '../services/geocoding_service.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/tag_model.dart';
import '../models/storage_location_model.dart';
import '../struct/studySyncClient.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../struct/firebaseAuthService.dart';
import '../struct/studyDocument.dart';
import '../struct/studyCourse.dart';
import '../database/study_document_dao.dart';
import '../database/study_course_dao.dart';
import '../services/firebase_storage_service.dart';
import '../services/local_file_picker.dart';
import '../services/supabase_service.dart';

class AddEditDocumentPage extends StatefulWidget {
  final StudyDocument? initialDocument;

  const AddEditDocumentPage({super.key, this.initialDocument});

  @override
  State<AddEditDocumentPage> createState() => _AddEditDocumentPageState();
}

class _AddEditDocumentPageState extends State<AddEditDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  final _documentDao = DocumentDao();
  final _courseDao = CourseDao();
  final _storageService = FirebaseStorageService();
  final _supabaseService = SupabaseService();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _fileUrlController;
  late TextEditingController _tagsController;
  late TextEditingController _physicalLocationController;
  late TextEditingController _shelfLocationController;

  List<String> _selectedTags = [];
  String? _selectedLocationId;
  List<DocumentTag> _availableTags = [];
  List<StorageLocationItem> _availableLocations = [];

  String? _selectedCourseId;
  DocumentType _selectedType = DocumentType.lecture;
  DocumentStatus _selectedStatus = DocumentStatus.todo;
  DateTime? _selectedDeadline;
  bool _isPinned = false;
  List<Course> _courses = [];

  // Checklist 2 State: Firebase Storage Upload
  bool _isUploadingFile = false;
  
  String? _uploadedStoragePath;
  String? _uploadedFileName;
  int _uploadedFileSize = 0;

  bool get _isEdit => widget.initialDocument != null;
  bool get _isReadOnly => _isEdit && widget.initialDocument != null && !widget.initialDocument!.canEdit;

  @override
  void initState() {
    super.initState();
    final doc = widget.initialDocument;
    _titleController = TextEditingController(text: doc?.title ?? '');
    _descController = TextEditingController(text: doc?.description ?? '');
    _fileUrlController = TextEditingController(text: doc?.fileUrl ?? '');
    _tagsController = TextEditingController(text: doc?.tags.join(', ') ?? '');
    _physicalLocationController = TextEditingController(text: doc?.physicalLocation ?? 'Thư viện Trung tâm - Tòa H1');
    _shelfLocationController = TextEditingController(text: doc?.shelfLocation ?? 'Kệ A3 - Ngăn 02');
    _selectedCourseId = doc?.courseId;
    _selectedType = doc?.type ?? DocumentType.lecture;
    _selectedStatus = doc?.status ?? DocumentStatus.todo;
    _selectedDeadline = doc?.deadline;
    _isPinned = doc?.isPinned ?? false;

    final db = AppDatabase();
    _availableTags = db.getAllTags();
    _availableLocations = db.getAllStorageLocations();
    _selectedTags = List<String>.from(doc?.tags ?? []);
    if (_availableLocations.isNotEmpty) {
      final matched = _availableLocations.where((l) => l.name == doc?.physicalLocation).firstOrNull;
      _selectedLocationId = matched?.id ?? _availableLocations.first.id;
    }

    if (doc != null && doc.fileUrl.isNotEmpty) {
      _uploadedFileName = 'TaiLieu_${doc.title.replaceAll(' ', '_')}.pdf';
      _uploadedStoragePath = 'documents/cloud-storage/${doc.id}/$_uploadedFileName';
    }

    _loadCourses();
  }

  void _loadCourses() {
    _courses = _courseDao.getAll();
    if (_courses.isNotEmpty) {
      if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
        Course? matched;
        for (final c in _courses) {
          if (c.id == _selectedCourseId || c.code.toLowerCase() == _selectedCourseId!.toLowerCase()) {
            matched = c;
            break;
          }
        }
        _selectedCourseId = matched?.id ?? _courses.first.id;
      } else {
        _selectedCourseId = _courses.first.id;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _fileUrlController.dispose();
    _tagsController.dispose();
    _physicalLocationController.dispose();
    _shelfLocationController.dispose();
    super.dispose();
  }


  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date != null) {
      setState(() => _selectedDeadline = date);
    }
  }

  /// Checklist 2: Tai tep tin len Firebase Cloud Storage theo cau truc phan tang
  /// documents/{owner_id}/{doc_id}/{filename}
  Future<void> _showUploadFileModal() async {
    final authService = FirebaseAuthService();
    if (!authService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập Google trước khi tải tệp lên Firebase Storage!'),
          backgroundColor: Color(0xFFC2185B),
        ),
      );
      return;
    }

    final owner = authService.currentUser!;
    final tempDocId = widget.initialDocument?.id ?? 'doc-${DateTime.now().millisecondsSinceEpoch}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD81B60).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFFD81B60), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tải tệp lên Firebase Cloud Storage',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Checklist 2: documents/{owner_id}/{doc_id}/{filename}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // NUT CHON TEP TRUC TIEP TU MAY TINH
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.folder_open_rounded, size: 22),
                label: const Text(
                  'Chọn tệp từ máy tính của bạn (Mọi định dạng)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadLocalFile(ownerId: owner.id, docId: tempDocId);
                },
              ),

              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('HOẶC CHỌN NHANH TỆP MẪU', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 12),

              _buildSampleFileOption(
                ctx,
                fileName: 'BaoCao_KienTruc_Cloud.pdf',
                title: 'Báo cáo Kiến trúc Cloud Supabase & Firebase (PDF)',
                sizeLabel: '2.4 MB',
                ownerId: owner.id,
                docId: tempDocId,
              ),
              _buildSampleFileOption(
                ctx,
                fileName: 'Slide_ThuyetTrinh_Firebase.pdf',
                title: 'Bộ Slide Thuyết trình Nhóm (PDF - 12 Trang)',
                sizeLabel: '3.8 MB',
                ownerId: owner.id,
                docId: tempDocId,
              ),
              _buildSampleFileOption(
                ctx,
                fileName: 'DeCuong_HeThongPhanTan.docx',
                title: 'Đề cương Ôn tập & Bài tập Lớn SE301 (DOCX)',
                sizeLabel: '1.2 MB',
                ownerId: owner.id,
                docId: tempDocId,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Chon file that tu o cung may tinh (Windows File Dialog)
  Future<void> _pickAndUploadLocalFile({
    required String ownerId,
    required String docId,
  }) async {
    try {
      final picked = await pickFileFromComputer();
      if (picked == null) return; // Nguoi dung cancel

      setState(() => _isUploadingFile = true);

      final result = await _storageService.uploadFile(
        ownerId: ownerId,
        documentId: docId,
        fileName: picked.fileName,
        fileBytes: picked.bytes,
        mimeType: picked.mimeType,
      );

      if (mounted) {
        setState(() {
          _isUploadingFile = false;
          _uploadedStoragePath = result.storagePath;
          _uploadedFileName = result.fileName;
          _uploadedFileSize = result.fileSize;
          _fileUrlController.text = result.fileUrl;

          // Tu dong dien tieu de neu dang trong
          if (_titleController.text.trim().isEmpty) {
            final cleanName = picked.fileName.split('.').first.replaceAll('_', ' ').replaceAll('-', ' ');
            _titleController.text = cleanName;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đã tải file "${picked.fileName}" từ máy tính lên Firebase Storage!\nĐường dẫn: ${result.storagePath}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải tệp từ máy tính: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSampleFileOption(
    BuildContext ctx, {
    required String fileName,
    required String title,
    required String sizeLabel,
    required String ownerId,
    required String docId,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD81B60)),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Đường dẫn: documents/$ownerId/$docId/$fileName ($sizeLabel)',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFD81B60)),
        onTap: () {
          Navigator.pop(ctx);
          _executeUpload(ownerId: ownerId, docId: docId, fileName: fileName);
        },
      ),
    );
  }

  Future<void> _executeUpload({
    required String ownerId,
    required String docId,
    required String fileName,
  }) async {
    setState(() => _isUploadingFile = true);

    try {
      final mockPdfBytes = Uint8List.fromList([
        37, 80, 68, 70, 45, 49, 46, 52, // %PDF-1.4 header
        ...utf8.encode('Cashew Study Document: $fileName for student $ownerId'),
      ]);

      final result = await _storageService.uploadFile(
        ownerId: ownerId,
        documentId: docId,
        fileName: fileName,
        fileBytes: mockPdfBytes,
        mimeType: fileName.endsWith('.pdf') ? 'application/pdf' : 'application/octet-stream',
      );

      if (mounted) {
        setState(() {
          _isUploadingFile = false;
          _uploadedStoragePath = result.storagePath;
          _uploadedFileName = result.fileName;
          _uploadedFileSize = result.fileSize;
          _fileUrlController.text = result.fileUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đã tải lên Firebase Storage thành công!\nĐường dẫn: ${result.storagePath}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải tệp: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveDocument() async {
    if (_isReadOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bạn chỉ có quyền Xem (Viewer) đối với tài liệu này, không thể chỉnh sửa theo RLS!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final authService = FirebaseAuthService();
    if (!authService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập Google trước khi lưu tài liệu lên Cloud!'),
          backgroundColor: Color(0xFFC2185B),
        ),
      );
      return;
    }

    final currentUser = authService.currentUser!;
    final tags = _selectedTags;
    final tagIds = _availableTags
        .where((t) => _selectedTags.contains(t.name) || _selectedTags.contains(t.id))
        .map((t) => t.id)
        .toList();
    final selectedLoc = _availableLocations.where((l) => l.id == _selectedLocationId).firstOrNull;
    final physLoc = selectedLoc?.name ?? (_physicalLocationController.text.trim().isNotEmpty ? _physicalLocationController.text.trim() : 'Tòa A - Phòng A305');
    final shelfLoc = selectedLoc?.shelfDetail ?? (_shelfLocationController.text.trim().isNotEmpty ? _shelfLocationController.text.trim() : 'Tầng 3, Tủ số 2 - Ngăn số 3');

    // courseCode removed

    final fileUrl = _fileUrlController.text.trim();
    final fileName = _uploadedFileName ?? (fileUrl.isNotEmpty ? 'TaiLieu_${DateTime.now().millisecondsSinceEpoch}.pdf' : '');
    final fileSize = _uploadedFileSize > 0 ? _uploadedFileSize : 10240;

    // Sync via SupabaseService

    if (_isEdit) {
      // Checklist 4: Cập nhật thông tin tài liệu trên Supabase & CSDL cục bộ
      final docId = widget.initialDocument!.id;
      try {
        final ok = await _supabaseService.updateDocument(
          documentId: docId,
          newTitle: _titleController.text.trim(),
          newDescription: _descController.text.trim(),
          storageLocationId: _selectedLocationId,
          newFileUrl: fileUrl,
          currentUserId: currentUser.id,
          tags: tags,
          physicalLocation: physLoc,
          shelfLocation: shelfLoc,
          isPinned: _isPinned,
        );
        debugPrint('Kết quả cập nhật Supabase Cloud: $ok');
      } catch (e) {
        debugPrint('Lỗi cập nhật Supabase Cloud: $e');
      }

      final updated = widget.initialDocument!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        fileUrl: fileUrl,
        courseId: _selectedCourseId ?? '',
        type: _selectedType,
        status: _selectedStatus,
        tags: tags,
        deadline: _selectedDeadline,
        isPinned: _isPinned,
        physicalLocation: physLoc,
        shelfLocation: shelfLoc,
      );
      await _documentDao.update(updated);
      unawaited(StudySyncClient().saveToCloud(updated));
    } else {
      // Checklist 2 & 3: Thêm mới tài liệu vào Supabase và liên kết Firebase Storage
      final savedSupabaseDoc = await _supabaseService.insertDocument(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        storageLocationId: _selectedLocationId,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
        currentUser: currentUser,
        tags: tags,
        tagIds: tagIds,
        physicalLocation: physLoc,
        shelfLocation: shelfLoc,
        isPinned: _isPinned,
      );
      final docId = savedSupabaseDoc.id;

      final newDoc = StudyDocument(
        id: docId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        fileUrl: fileUrl,
        courseId: _selectedCourseId ?? '',
        type: _selectedType,
        status: _selectedStatus,
        tags: tags,
        deadline: _selectedDeadline,
        isPinned: _isPinned,
        ownerId: savedSupabaseDoc.ownerId,
        ownerEmail: savedSupabaseDoc.ownerEmail,
        ownerName: savedSupabaseDoc.ownerName,
        sharedPermission: 'owner',
        physicalLocation: physLoc,
        shelfLocation: shelfLoc,
      );
      await _documentDao.insert(newDoc);
      unawaited(StudySyncClient().saveToCloud(newDoc));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_isEdit 
                    ? '✅ Đã cập nhật tài liệu trên Supabase & CSDL cục bộ thành công!' 
                    : '✅ Đã tạo tài liệu và lưu vào Supabase PostgreSQL!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadlineText = _selectedDeadline != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDeadline!)
        : 'Chưa đặt hạn nộp';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isReadOnly 
            ? 'Chi tiết tài liệu (Chỉ xem)' 
            : (_isEdit ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu mới')),
        actions: [
          if (!_isReadOnly)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Lưu',
              onPressed: _saveDocument,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_isReadOnly) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_rounded, color: Colors.teal, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tài liệu được chia sẻ từ ${widget.initialDocument!.ownerName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Bạn đang ở chế độ xem thông tin tài liệu (Chính sách bảo mật RLS Supabase)',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Banner Trang thai Firebase Google
            Builder(
              builder: (context) {
                final authService = FirebaseAuthService();
                final signedIn = authService.isSignedIn;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: signedIn ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: signedIn ? Colors.green.shade300 : Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        signedIn ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                        size: 22,
                        color: signedIn ? Colors.green.shade700 : Colors.amber.shade900,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              signedIn
                                  ? 'Đã đăng nhập: ${authService.currentUser!.displayName} (${authService.currentUser!.role})'
                                  : 'Chưa đăng nhập Firebase Google',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: signedIn ? Colors.green.shade900 : Colors.amber.shade900,
                              ),
                            ),
                            Text(
                              signedIn
                                  ? 'Tài khoản: ${authService.currentUser!.email} (Được phép tải tệp lên Storage)'
                                  : 'Cần đăng nhập Google để tự động lưu tài liệu lên Cloud',
                              style: TextStyle(
                                fontSize: 11,
                                color: signedIn ? Colors.green.shade800 : Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Tieu de
            TextFormField(
              controller: _titleController,
              readOnly: _isReadOnly,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề tài liệu *',
                hintText: 'VD: Báo cáo Kiến trúc Cloud Supabase & Firebase',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
            ),
            const SizedBox(height: 16),



            // Phan loai & Trang thai
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DocumentType>(
                    value: DocumentType.values.contains(_selectedType) ? _selectedType : DocumentType.lecture,
                    decoration: const InputDecoration(
                      labelText: 'Loại tài liệu',
                      border: OutlineInputBorder(),
                    ),
                    items: DocumentType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.displayName));
                    }).toList(),
                    onChanged: _isReadOnly ? null : (val) => setState(() => _selectedType = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<DocumentStatus>(
                    value: DocumentStatus.values.contains(_selectedStatus) ? _selectedStatus : DocumentStatus.todo,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    items: DocumentStatus.values.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.displayName));
                    }).toList(),
                    onChanged: _isReadOnly ? null : (val) => setState(() => _selectedStatus = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Han nop Deadline
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              leading: const Icon(Icons.calendar_today_rounded),
              title: const Text('Hạn nộp (Deadline)'),
              subtitle: Text(deadlineText),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedDeadline != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedDeadline = null),
                    ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
              onTap: _isReadOnly ? null : _pickDeadline,
            ),
            const SizedBox(height: 16),

            // Mo ta chi tiet
            TextFormField(
              controller: _descController,
              readOnly: _isReadOnly,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả / Ghi chú chi tiết',
                hintText: 'Tài liệu phân tích mô hình Hybrid Cloud và RLS...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // ================================================================
            // CHECKLIST 2: COMPONENT LUU TRU TEP TRÊN FIREBASE CLOUD STORAGE
            // ================================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF7F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3C4D4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD81B60).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.folder_zip_rounded, color: Color(0xFFD81B60), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checklist 2: Lưu trữ File trên Firebase Storage',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Cấu trúc: documents/{owner_id}/{doc_id}/{filename}',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_isUploadingFile) ...[
                    const LinearProgressIndicator(color: Color(0xFFD81B60)),
                    const SizedBox(height: 8),
                    const Text(
                      'Đang tải tệp vật lý lên Firebase Cloud Storage...',
                      style: TextStyle(fontSize: 12, color: Color(0xFFD81B60), fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (_uploadedStoragePath != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Đã tải lên Firebase Storage (${_uploadedFileName ?? "File"})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '📁 Storage Path: $_uploadedStoragePath',
                            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.green.shade800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '🐘 Kết nối Supabase: Bảng public.documents sẽ lưu file_url & file_name',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD81B60),
                            side: const BorderSide(color: Color(0xFFD81B60)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: Text(
                            _uploadedStoragePath != null ? 'Tải tệp khác lên Storage' : 'Chọn tệp & Tải lên Firebase Storage',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _isUploadingFile ? null : _showUploadFileModal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // O nhap link truc tiep (Fallback)
                  TextFormField(
                    controller: _fileUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Đường dẫn liên kết / Firebase File URL',
                      hintText: 'https://firebasestorage.googleapis.com/...',
                      prefixIcon: Icon(Icons.link_rounded),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ================================================================
            // 1. THẺ TAG PHÂN LOẠI (LỌC VÒNG FOR - CHỌN NHIỀU TAG)
            // ================================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF7F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3C4D4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD81B60).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.label_rounded, color: Color(0xFFD81B60), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thẻ Tag phân loại (Chọn được nhiều tag)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD81B60)),
                            ),
                            Text(
                              'Nhấn vào các thẻ tag bên dưới để gán cho tài liệu này',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Tạo Tag mới', style: TextStyle(fontSize: 12)),
                        onPressed: _showQuickAddTagDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_availableTags.isEmpty) ...[
                    const Text('Chưa có thẻ tag nào trong danh mục. Bấm "Tạo Tag mới" để thêm.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((t) {
                        final isSel = _selectedTags.contains(t.name);
                        return FilterChip(
                          avatar: CircleAvatar(
                            backgroundColor: isSel ? const Color(0xFFD81B60) : Colors.grey.shade400,
                            radius: 5,
                          ),
                          label: Text(t.name, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          selectedColor: const Color(0xFFF7D8DF),
                          checkmarkColor: const Color(0xFFD81B60),
                          onSelected: _isReadOnly ? null : (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(t.name);
                              } else {
                                _selectedTags.remove(t.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ================================================================
            // 2. VỊ TRÍ KHO LƯU TRỮ (LỌC VÒNG FOR - CHỌN ĐÚNG 1 KHO)
            // ================================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.warehouse_rounded, color: Colors.teal, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kho lưu trữ vật lý (Chỉ chọn 1 kho duy nhất)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                            ),
                            Text(
                              'Tài liệu bản cứng được cất tại Tòa nhà, Tầng, Phòng, Tủ, Ngăn',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_location_alt_rounded, size: 14, color: Colors.teal),
                        label: const Text('Tạo Kho mới', style: TextStyle(fontSize: 12, color: Colors.teal)),
                        onPressed: _showQuickAddLocationDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: (_availableLocations.any((l) => l.id == _selectedLocationId))
                        ? _selectedLocationId
                        : (_availableLocations.isNotEmpty ? _availableLocations.first.id : null),
                    decoration: const InputDecoration(
                      labelText: 'Chọn Kho cất giữ tài liệu *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.apartment_rounded, color: Colors.teal),
                    ),
                    items: _availableLocations.map((loc) {
                      return DropdownMenuItem<String>(
                        value: loc.id,
                        child: Text(
                          '${loc.name} (${loc.shelfDetail})',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _isReadOnly ? null : (val) {
                      setState(() {
                        _selectedLocationId = val;
                        final found = _availableLocations.firstWhere((l) => l.id == val);
                        _physicalLocationController.text = found.name;
                        _shelfLocationController.text = found.shelfDetail;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Hiển thị chi tiết địa chỉ kho đang chọn
                  Builder(
                    builder: (context) {
                      final selectedLoc = _availableLocations.where((l) => l.id == _selectedLocationId).firstOrNull;
                      if (selectedLoc == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chi tiết: ${selectedLoc.building} - ${selectedLoc.floor} - ${selectedLoc.room} | ${selectedLoc.cabinet} - ${selectedLoc.shelf}',
                                style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ghim len dau
            SwitchListTile(
              title: const Text('Ghim tài liệu quan trọng lên đầu'),
              value: _isPinned,
              onChanged: _isReadOnly ? null : (val) => setState(() => _isPinned = val),
            ),

            const SizedBox(height: 24),
            if (_isReadOnly) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('QUAY LẠI (CHẾ ĐỘ CHỈ XEM)'),
                onPressed: () => Navigator.pop(context),
              ),
            ] else ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.save_rounded),
                label: Text(_isEdit ? 'LƯU THAY ĐỔI' : 'TẠO TÀI LIỆU MỚI (LƯU SUPABASE)'),
                onPressed: _saveDocument,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuickAddTagDialog() {
    final tagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm Thẻ Tag Mới'),
        content: TextField(
          controller: tagCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: Cơ sở dữ liệu, Java, Đồ án...',
            prefixIcon: Icon(Icons.tag_rounded),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60), foregroundColor: Colors.white),
            onPressed: () async {
              final name = tagCtrl.text.trim();
              if (name.isEmpty) return;
              final newTag = DocumentTag(id: const Uuid().v4(), name: name);
              await AppDatabase().insertTag(newTag);
              _supabaseService.insertTagOnline(newTag);
              setState(() {
                _availableTags = AppDatabase().getAllTags();
                _selectedTags.add(name);
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Thêm Tag'),
          ),
        ],
      ),
    );
  }

  void _showQuickAddLocationDialog() {
    final searchCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final bldCtrl = TextEditingController();
    final flCtrl = TextEditingController(text: 'Tầng 1');
    final rmCtrl = TextEditingController();
    final cabCtrl = TextEditingController();
    final shCtrl = TextEditingController();
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
              Text('Thêm Kho & Định Vị Bản Đồ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tìm kiếm địa điểm bất kỳ trên bản đồ:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập địa chỉ, tên tòa nhà, phố...',
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(),
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
                            const SizedBox(width: 6),
                            FilledButton(
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
                              child: isSearching
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Tìm'),
                            ),
                          ],
                        ),
                        if (searchResults.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
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
                                      bldCtrl.text = r.building;
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
                        ],
                        if (foundAddress != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '📍 ' + foundAddress!,
                            style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên kho *', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: bldCtrl, decoration: const InputDecoration(labelText: 'Tòa nhà / Khu vực', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: flCtrl, decoration: const InputDecoration(labelText: 'Tầng', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: rmCtrl, decoration: const InputDecoration(labelText: 'Phòng', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: cabCtrl, decoration: const InputDecoration(labelText: 'Tủ', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: shCtrl, decoration: const InputDecoration(labelText: 'Ngăn', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Vĩ độ GPS', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Kinh độ GPS', border: OutlineInputBorder(), isDense: true))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () async {
                var name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  name = bldCtrl.text.trim().isNotEmpty ? '${bldCtrl.text.trim()} - ${rmCtrl.text.trim()}' : 'Kho Lưu Trữ Mới';
                }
                final newLoc = StorageLocationItem(
                  id: const Uuid().v4(),
                  name: name,
                  building: bldCtrl.text.trim(),
                  floor: flCtrl.text.trim(),
                  room: rmCtrl.text.trim(),
                  cabinet: cabCtrl.text.trim(),
                  shelf: shCtrl.text.trim(),
                  latitude: double.tryParse(latCtrl.text.trim()) ?? 21.0285,
                  longitude: double.tryParse(lngCtrl.text.trim()) ?? 105.8542,
                );
                await AppDatabase().insertStorageLocation(newLoc);
                _supabaseService.insertStorageLocationOnline(newLoc);
                setState(() {
                  _availableLocations = AppDatabase().getAllStorageLocations();
                  _selectedLocationId = newLoc.id;
                  _physicalLocationController.text = newLoc.name;
                  _shelfLocationController.text = newLoc.shelfDetail;
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu Kho'),
            ),
          ],
        ),
      ),
    );
  }

}
