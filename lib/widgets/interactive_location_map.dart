import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/physical_location.dart';
import '../database/web_storage.dart';

/// Widget Bản đồ hiển thị Google Maps thật 100% (Google Maps Embed Viewer)
/// Thiết kế kích thước chuẩn mực, tỷ lệ vàng, giao diện sang trọng hiện đại
class InteractiveLocationMap extends StatelessWidget {
  final PhysicalLocation location;
  final String documentTitle;

  const InteractiveLocationMap({
    super.key,
    required this.location,
    required this.documentTitle,
  });

  /// Hàm tĩnh mở Modal Dialog Google Maps lớn, đẹp mắt, có nút X đóng góc phải
  static void showModal(
    BuildContext context, {
    required PhysicalLocation location,
    required String documentTitle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: InteractiveLocationMap(
          location: location,
          documentTitle: documentTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = location.latitude;
    final lng = location.longitude;
    final embedUrl = 'https://maps.google.com/maps?q=$lat,$lng&hl=vi&z=16&output=embed';
    final viewType = 'gmap-${lat.toStringAsFixed(5)}-${lng.toStringAsFixed(5)}';

    // Đăng ký Iframe nhúng Google Maps thật cho Flutter Web
    registerMapIframe(viewType, embedUrl);

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 860 ? 780.0 : (screenWidth * 0.92);

    return Container(
      width: dialogWidth,
      constraints: const BoxConstraints(maxWidth: 820),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER: TÊN ĐỊA ĐIỂM + NÚT X ĐÓNG GÓC PHẢI
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 16, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade100),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.teal, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.locationName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              location.floor,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.campusName.isNotEmpty ? location.campusName : 'Khuôn viên lưu trữ',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // NÚT 'X' ĐÓNG DIALOG
                IconButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: 'Đóng bản đồ (X)',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade700,
                    hoverColor: Colors.red.shade50,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // 2. KHU VỰC BẢN ĐỒ GOOGLE MAPS RỘNG RÃI, VỪA MẮT (CAO 380PX)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: kIsWeb
                          ? HtmlElementView(viewType: viewType)
                          : Image.network(
                              'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=16&size=750x400&maptype=mapnik&markers=$lat,$lng,ol-marker',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.map_rounded, size: 48, color: Colors.grey)),
                              ),
                            ),
                    ),

                    // Nút mở Google Maps chỉ đường góc trên bên phải
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            openUrlInNewTab(location.googleMapsUrl);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded, size: 15, color: Colors.blue),
                                SizedBox(width: 6),
                                Text(
                                  'Mở trên Google Maps',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tọa độ GPS hiển thị góc dưới bên trái
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. KHU VỰC THÔNG TIN VỊ TRÍ CHI TIẾT
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.meeting_room_rounded,
                      color: Colors.teal,
                      title: 'Phòng / Khu vực',
                      value: location.campusName.isNotEmpty ? location.campusName : 'Khuôn viên chính',
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.shelves,
                      color: Colors.brown,
                      title: 'Vị trí ngăn & kệ',
                      value: location.shelfNumber.isNotEmpty ? location.shelfNumber : 'Kệ cất giữ',
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFFD81B60),
                      title: 'Tài liệu liên kết',
                      value: documentTitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
