// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'local_file_picker_stub.dart';

Future<PickedFileData?> pickFileFromComputer() async {
  final completer = Completer<PickedFileData?>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '*/*'; // Chap nhan moi dinh dang file: PDF, Word, Excel, Slide, Anh, Zip...
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((event) {
        try {
          final result = reader.result;
          List<int> byteList = [];
          if (result is Uint8List) {
            byteList = result;
          } else if (result is ByteBuffer) {
            byteList = result.asUint8List();
          } else if (result is List<int>) {
            byteList = result;
          }

          completer.complete(PickedFileData(
            fileName: file.name,
            bytes: byteList,
            size: file.size,
            mimeType: file.type.isNotEmpty ? file.type : 'application/octet-stream',
          ));
        } catch (_) {
          completer.complete(null);
        }
      });

      reader.onError.listen((_) => completer.complete(null));
      reader.readAsArrayBuffer(file);
    } else {
      completer.complete(null);
    }
  });

  return completer.future.timeout(
    const Duration(minutes: 5),
    onTimeout: () => null,
  );
}
