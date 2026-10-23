import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/physical_location.dart';

/// Widget Bản đồ tương tác vị trí tài liệu (Campus & Library Floor Map Viewer)
/// Hỗ trợ hiển thị tọa độ GPS, sơ đồ kệ sách và mở Google Maps trực tiếp
class InteractiveLocationMap extends StatefulWidget {
  final PhysicalLocation location;
  final String documentTitle;

  const InteractiveLocationMap({
    super.key,
    required this.location,
    required this.documentTitle,
  });

  @override
  State<InteractiveLocationMap> createState() => _InteractiveLocationMapState();
}

class _InteractiveLocationMapState extends State<InteractiveLocationMap> {
  int _selectedView = 0; // 0: Bản đồ Vệ tinh / GPS, 1: Sơ đồ Kệ sách

  String _getMapTileUrl(double lat, double lon, int zoom) {
    final n = 1 << zoom;
    final x = ((lon + 180.0) / 360.0 * n).floor();
    final rad = lat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(rad) + 1.0 / math.cos(rad)) / math.pi) / 2.0 * n).floor();
    return 'https://basemaps.cartocdn.com/rastertiles/voyager/$zoom/$x/$y.png';
  }

  Future<void> _launchGoogleMaps(BuildContext context) async {
    final uri = Uri.parse(widget.location.googleMapsUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched) {
        await launchUrl(uri);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Đang mở Google Maps: ${widget.location.latitude}, ${widget.location.longitude}'),
            backgroundColor: const Color(0xFF1976D2),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở Google Maps: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _launchDirections(BuildContext context) async {
    final uri = Uri.parse(widget.location.directionsUrl);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở chỉ đường Google Maps: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _copyCoordinates(BuildContext context) {
    final coords = '${widget.location.latitude}, ${widget.location.longitude}';
    Clipboard.setData(ClipboardData(text: coords));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 Đã sao chép tọa độ GPS: $coords'),
        backgroundColor: Colors.teal.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Tên vị trí & Chế độ xem
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        location.fullAddress,
                        style: TextStyle(fontSize: 11, color: Colors.teal.shade800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

          // Thanh chuyển Tab Chế độ xem Bản đồ
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedView = 0),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedView == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _selectedView == 0
                            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.public_rounded,
                            size: 14,
                            color: _selectedView == 0 ? const Color(0xFF1976D2) : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bản đồ Vệ tinh & GPS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedView == 0 ? FontWeight.bold : FontWeight.normal,
                              color: _selectedView == 0 ? const Color(0xFF1976D2) : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedView = 1),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedView == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: _selectedView == 1
                            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shelves,
                            size: 14,
                            color: _selectedView == 1 ? Colors.brown.shade700 : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sơ đồ Kệ sách',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedView == 1 ? FontWeight.bold : FontWeight.normal,
                              color: _selectedView == 1 ? Colors.brown.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Khung Bản đồ trực quan
          SizedBox(
            height: 200,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_selectedView == 0) ...[
                    // Bản đồ thực tế (Map Tile hoặc Fallback Vector Grid)
                    InkWell(
                      onTap: () => _launchGoogleMaps(context),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _getMapTileUrl(location.latitude, location.longitude, 16),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => CustomPaint(
                              painter: _CampusGridPainter(),
                            ),
                          ),
                          // Lớp phủ mờ tăng tương phản
                          Container(
                            color: Colors.black.withOpacity(0.05),
                          ),
                          // Gợi ý nhấn để mở
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_rounded, color: Colors.white, size: 11),
                                  SizedBox(width: 3),
                                  Text(
                                    'Nhấn để mở Google Maps',
                                    style: TextStyle(color: Colors.white, fontSize: 9.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Sơ đồ kệ sách chi tiết
                    CustomPaint(
                      painter: _ShelfLayoutPainter(
                        shelfText: location.shelfNumber,
                      ),
                    ),
                  ],

                  // Marker Pin định vị trung tâm
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 150),
                                child: Text(
                                  widget.documentTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFFD32F2F), size: 22),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Huy hiệu Tọa độ GPS góc dưới bên trái
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: InkWell(
                      onTap: () => _copyCoordinates(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded, color: Colors.white70, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              'GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shelves, size: 16, color: Colors.brown),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vị trí kệ: ${location.shelfNumber}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF4E342E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Thanh công cụ GOOGLE MAPS chính thức
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Nút MỞ GOOGLE MAPS
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchGoogleMaps(context),
                    icon: const Icon(Icons.map_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Mở Google Maps',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8), // Màu Google Blue chuẩn
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Nút CHỈ ĐƯỜNG (Directions)
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _launchDirections(context),
                    icon: const Icon(Icons.directions_rounded, size: 16, color: Color(0xFF1E88E5)),
                    label: const Text(
                      'Chỉ đường',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E88E5)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF90CAF9)),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Nút SAO CHÉP TỌA ĐỘ
                IconButton(
                  tooltip: 'Sao chép tọa độ GPS',
                  onPressed: () => _copyCoordinates(context),
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vẽ sơ đồ mặt bằng các dãy kệ sách trong thư viện
class _ShelfLayoutPainter extends CustomPainter {
  final String shelfText;

  _ShelfLayoutPainter({required this.shelfText});

  @override
  void paint(Canvas canvas, Size size) {
    // Nền phòng đọc
    final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Vẽ tường và cửa ra vào
    final wallPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), const Radius.circular(8)),
      wallPaint,
    );

    // Vẽ các dãy kệ sách
    final shelfNormalPaint = Paint()..color = const Color(0xFFCBD5E1);
    final shelfActivePaint = Paint()..color = Colors.amber.shade700;

    const rows = 3;
    const cols = 4;
    final cellW = (size.width - 70) / cols;
    final cellH = (size.height - 70) / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(25 + c * (cellW + 6), 25 + r * (cellH + 8), cellW, cellH * 0.7);
        final isActive = (r == 1 && c == 2); // Kệ trọng tâm vị trí sách
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          isActive ? shelfActivePaint : shelfNormalPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Lưới khuôn viên trường dự phòng
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
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 20, 80, 50), const Radius.circular(6)), bldPaint);
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
