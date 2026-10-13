class ExternalStorageService {
  Future<Map<String, dynamic>> fetchFileMetadata(String url) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final uri = Uri.tryParse(url);
    final fileName = uri != null && uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'tai_lieu_dinh_kem.pdf';

    return {
      'fileName': fileName,
      'mimeType': 'application/pdf',
      'sizeBytes': 2048576,
      'isValidUrl': uri != null && uri.isAbsolute,
    };
  }
}
