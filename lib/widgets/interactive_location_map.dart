import 'package:flutter/material.dart';
import '../models/physical_location.dart';
import '../database/web_storage.dart';

/// Widget Bản đồ tương tác vị trí tài liệu (Campus & Library Floor Map Viewer)
/// Hỗ trợ hiển thị tọa độ GPS, bản đồ OpenStreetMap thực tế, sơ đồ kệ sách và liên kết Google Maps
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
    final staticMapUrl = 'https://staticmap.openstreetmap.de/staticmap.php?center=${location.latitude},${location.longitude}&zoom=17&size=600x300&maptype=mapnik&markers=${location.latitude},${location.longitude},ol-marker';

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
          // Header: Tên vị trí và Tòa nhà
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF004D40)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${location.campusName} - ${location.floor}',
                        style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
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

          // Bản đồ OpenStreetMap thực tế & Lưới mô phỏng (Interactive Campus Map)
          SizedBox(
            height: 190,
            child: ClipRect(
              child: Stack(
                children: [
                  // Lớp nền 1: Ảnh bản đồ OpenStreetMap thực tế từ tọa độ GPS
                  Positioned.fill(
                    child: Image.network(
                      staticMapUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => CustomPaint(
                        size: const Size(double.infinity, 190),
                        painter: _CampusGridPainter(),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Stack(
                          children: [
                            CustomPaint(
                              size: const Size(double.infinity, 190),
                              painter: _CampusGridPainter(),
                            ),
                            const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Pin định vị tài liệu nổi bật
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
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
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

                  // Tọa độ GPS hiển thị góc dưới bên trái
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                  ),

                  // Nút mở Google Maps chỉ đường thực tế
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Tooltip(
                      message: 'Mở vị trí chính xác trên Google Maps',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            openUrlInNewTab(location.googleMapsUrl);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📍 Đang mở Google Maps tại tọa độ (${location.latitude}, ${location.longitude})'),
                                backgroundColor: Colors.teal.shade800,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade400),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4, offset: const Offset(0, 1)),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_rounded, size: 14, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  'Google Maps',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer: Vị trí ngăn & kệ sách chi tiết
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

    final pathPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.6), pathPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.65, size.height), pathPaint);

    final bldPaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20, 20, 80, 50), const Radius.circular(6)), bldPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 110, 30, 90, 60), const Radius.circular(6)), bldPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(30, size.height - 70, 100, 50), const Radius.circular(6)), bldPaint);

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
