import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/physical_location.dart';
import '../database/web_storage.dart';

/// Widget Bản đồ hiển thị Google Maps thật 100% (Google Maps Embed Viewer)
/// Không fix cứng, lấy đúng tọa độ GPS của kho/địa điểm để hiển thị Google Maps
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
    final lat = location.latitude;
    final lng = location.longitude;
    final embedUrl = 'https://maps.google.com/maps?q=$lat,$lng&hl=vi&z=16&output=embed';
    final viewType = 'gmap-${lat.toStringAsFixed(4)}-${lng.toStringAsFixed(4)}';

    // Đăng ký Iframe nhúng bản đồ Google Maps thật cho Flutter Web
    registerMapIframe(viewType, embedUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Thông tin địa điểm
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

          // KHU VỰC BẢN ĐỒ GOOGLE MAPS THẬT 100%
          SizedBox(
            height: 230,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: kIsWeb
                        ? HtmlElementView(viewType: viewType)
                        : Image.network(
                            'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=16&size=600x300&maptype=mapnik&markers=$lat,$lng,ol-marker',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.map_rounded, size: 48, color: Colors.grey),
                              ),
                            ),
                          ),
                  ),

                  // Nút mở Google Maps chỉ đường góc trên bên phải
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          openUrlInNewTab(location.googleMapsUrl);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded, size: 14, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                'Mở Google Maps',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                        'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
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
