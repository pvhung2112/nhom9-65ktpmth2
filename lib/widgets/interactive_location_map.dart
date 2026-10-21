import 'package:flutter/material.dart';
import '../models/physical_location.dart';

/// Widget Bản đồ tương tác vị trí tài liệu (Campus & Library Floor Map Viewer)
/// Hỗ trợ hiển thị tọa độ GPS, sơ đồ kệ sách và liên kết Google Maps
class InteractiveLocationMap extends StatelessWidget {
  final PhysicalLocation location;
  final String documentTitle;

  const InteractiveLocationMap({
    super.key,
    required this.location,
    required this.documentTitle,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.teal, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.locationName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                      ),
                      Text(
                        location.fullAddress,
                        style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    location.floor,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),

          // Bản đồ mô phỏng khuôn viên & Thư viện (Visual Interactive Campus Map)
          SizedBox(
            height: 180,
            child: ClipRect(
              child: Stack(
                children: [
                  // Lưới nền bản đồ
                  CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _CampusGridPainter(),
                  ),

                  // Pin định vị tài liệu tại thư viện
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81B60),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book_rounded, color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  documentTitle,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFFD81B60), size: 24),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81B60),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tọa độ GPS hiển thị góc
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                  ),

                  // Nút mở Google Maps
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Tooltip(
                      message: 'Xem trên Google Maps',
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📍 Đang chuyển đến Google Maps: ${location.googleMapsUrl}'),
                              backgroundColor: Colors.teal.shade800,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade400),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded, size: 12, color: Colors.blue),
                              SizedBox(width: 4),
                              Text('Google Maps', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer: Vị trí ngăn & kệ sách
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shelves, size: 16, color: Colors.brown),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vị trí kệ: ${location.shelfNumber}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4E342E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Vẽ các đường đường đi khuôn viên (Campus pathways)
    final pathPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.6), pathPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.65, size.height), pathPaint);

    // Vẽ các khối tòa nhà (Campus buildings)
    final bldPaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20, 20, 80, 50), const Radius.circular(6)), bldPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 110, 30, 90, 60), const Radius.circular(6)), bldPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(30, size.height - 70, 100, 50), const Radius.circular(6)), bldPaint);

    // Khối Thư viện Trung tâm (Library Building)
    final libPaint = Paint()..color = Colors.teal.shade200;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 140, height: 75),
        const Radius.circular(10),
      ),
      libPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
