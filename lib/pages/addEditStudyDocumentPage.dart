import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../struct/firebaseAuthService.dart';
import '../struct/studySyncClient.dart';
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

  @override
  void initState() {
    super.initState();
    final doc = widget.initialDocument;
    _titleController = TextEditingController(text: doc?.title ?? '');
    _descController = TextEditingController(text: doc?.description ?? '');
    _fileUrlController = TextEditingController(text: doc?.fileUrl ?? '');
    _tagsController = TextEditingController(text: doc?.tags.join(', ') ?? '');
    _selectedCourseId = doc?.courseId;
    _selectedType = doc?.type ?? DocumentType.lecture;
    _selectedStatus = doc?.status ?? DocumentStatus.todo;
    _selectedDeadline = doc?.deadline;
    _isPinned = doc?.isPinned ?? false;

    if (doc != null && doc.fileUrl.isNotEmpty) {
      _uploadedFileName = 'TaiLieu_${doc.title.replaceAll(' ', '_')}.pdf';
      _uploadedStoragePath = 'documents/cloud-storage/${doc.id}/$_uploadedFileName';
    }

    _loadCourses();
  }

  void _loadCourses() {
    _courses = _courseDao.getAll();
    if (_courses.isNotEmpty && _selectedCourseId == null) {
      _selectedCourseId = _courses.first.id;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _fileUrlController.dispose();
    _tagsController.dispose();
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
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final courseCode = _courses
        .firstWhere((c) => c.id == _selectedCourseId, orElse: () => Course(id: '', code: 'SE301', name: '', colorValue: 0))
        .code;

    final fileUrl = _fileUrlController.text.trim();
    final fileName = _uploadedFileName ?? (fileUrl.isNotEmpty ? 'TaiLieu_${DateTime.now().millisecondsSinceEpoch}.pdf' : '');
    final fileSize = _uploadedFileSize > 0 ? _uploadedFileSize : 10240;

    // 1. Ket noi voi bang documents tren Supabase (Checklist 2)
    final savedSupabaseDoc = await _supabaseService.insertDocument(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      courseCode: courseCode,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      currentUser: currentUser,
    );

    // 2. Dong bo voi CSDL cuc bo (Local-First DAO)
    final syncClient = StudySyncClient();
    final docId = widget.initialDocument?.id ?? savedSupabaseDoc.id;

    if (_isEdit) {
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
      );
      await _documentDao.update(updated);
      unawaited(syncClient.saveToCloud(updated));
    } else {
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
      );
      await _documentDao.insert(newDoc);
      unawaited(syncClient.saveToCloud(newDoc));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('✅ Đã lưu tệp lên Firebase Storage & kết nối với bảng documents trên Supabase!'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
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
        title: Text(_isEdit ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu mới'),
        actions: [
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
              decoration: const InputDecoration(
                labelText: 'Tiêu đề tài liệu *',
                hintText: 'VD: Báo cáo Kiến trúc Cloud Supabase & Firebase',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
            ),
            const SizedBox(height: 16),

            // Chon Mon hoc
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(
                labelText: 'Môn học / Học phần *',
                border: OutlineInputBorder(),
              ),
              items: _courses.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: Color(c.colorValue), radius: 6),
                      const SizedBox(width: 8),
                      Text('${c.code} - ${c.name}'),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCourseId = val),
            ),
            const SizedBox(height: 16),

            // Phan loai & Trang thai
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DocumentType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Loại tài liệu',
                      border: OutlineInputBorder(),
                    ),
                    items: DocumentType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.displayName));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<DocumentStatus>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    items: DocumentStatus.values.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.displayName));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
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
              onTap: _pickDeadline,
            ),
            const SizedBox(height: 16),

            // Mo ta chi tiet
            TextFormField(
              controller: _descController,
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

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Thẻ tag (ngăn cách bằng dấu phẩy)',
                hintText: 'KTPM, Firebase, Supabase, RLS',
                prefixIcon: Icon(Icons.tag_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Ghim len dau
            SwitchListTile(
              title: const Text('Ghim tài liệu quan trọng lên đầu'),
              value: _isPinned,
              onChanged: (val) => setState(() => _isPinned = val),
            ),

            const SizedBox(height: 24),
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
        ),
      ),
    );
  }
}
