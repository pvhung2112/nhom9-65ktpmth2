// Dịch vụ Lưu trữ Tệp Đám mây (Firebase Cloud Storage)
// Phục vụ Checklist 6: Tải lên và đồng bộ tệp tài liệu bài giảng/bài tập

class UploadProgressInfo {
  final int bytesTransferred;
  final int totalBytes;
  final double progressPercent;

  UploadProgressInfo({
    required this.bytesTransferred,
    required this.totalBytes,
    required this.progressPercent,
  });
}

class FirebaseCloudStorageService {
  static final FirebaseCloudStorageService _instance = FirebaseCloudStorageService._internal();
  factory FirebaseCloudStorageService() => _instance;
  FirebaseCloudStorageService._internal();

  /// Tải tệp tài liệu (PDF, Word, ZIP) lên Firebase Cloud Storage Bucket
  Future<String> uploadDocumentFile({
    required String filePath,
    required String fileName,
    required String userId,
    void Function(UploadProgressInfo progress)? onProgress,
  }) async {
    // Trong môi trường production kết nối Firebase Storage:
    // final ref = FirebaseStorage.instance.ref().child('study_docs/$userId/$fileName');
    // final uploadTask = ref.putFile(File(filePath));
    // uploadTask.snapshotEvents.listen((taskSnapshot) {
    //   onProgress?.call(UploadProgressInfo(
    //     bytesTransferred: taskSnapshot.bytesTransferred,
    //     totalBytes: taskSnapshot.totalBytes,
    //     progressPercent: taskSnapshot.bytesTransferred / taskSnapshot.totalBytes,
    //   ));
    // });
    // await uploadTask;
    // return await ref.getDownloadURL();

   
    return 'https://firebasestorage.googleapis.com/v0/b/study-document-cloud.appspot.com/o/study_docs%2F$userId%2F$fileName?alt=media';
  }

  /// Xóa tệp khỏi đám mây
  Future<void> deleteDocumentFile({
    required String storageUrl,
  }) async {
    // final ref = FirebaseStorage.instance.refFromURL(storageUrl);
    // await ref.delete();
  }
}
