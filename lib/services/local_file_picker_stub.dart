import 'dart:typed_data';

class PickedFileData {
  final String fileName;
  final List<int> bytes;
  final int size;
  final String mimeType;

  PickedFileData({
    required this.fileName,
    required this.bytes,
    required this.size,
    required this.mimeType,
  });
}

Future<PickedFileData?> pickFileFromComputer() async {
  // Stub cho moi truong kiem thu test
  return PickedFileData(
    fileName: 'BaoCao_KienTruc_Cloud.pdf',
    bytes: Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52]),
    size: 10240,
    mimeType: 'application/pdf',
  );
}
