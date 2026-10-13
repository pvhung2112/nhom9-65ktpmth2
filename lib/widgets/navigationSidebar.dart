import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Trang chủ', 'index': 0},
      {'icon': Icons.menu_book_rounded, 'label': 'Tài liệu học tập', 'index': 1},
      {'icon': Icons.school_rounded, 'label': 'Môn học', 'index': 2},
      {'icon': Icons.flag_rounded, 'label': 'Mục tiêu', 'index': 3},
      {'icon': Icons.search_rounded, 'label': 'Tìm kiếm', 'index': 4},
    ];

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & App Name (Cashew Style)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7D8DF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFFD81B60),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cashew Study',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Quản lý Tài liệu Cloud',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 12),

          // Navigation Items with Cashew Pink Pill Style
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: items.map((item) {
                final idx = item['index'] as int;
                final isSelected = selectedIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () => onDestinationSelected(idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF7D8DF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 22,
                              color: isSelected ? const Color(0xFFD81B60) : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFFD81B60) : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // User Profile Footer with dynamic user info & Logout Button
          Padding(
            padding: const EdgeInsets.all(14),
            child: ListenableBuilder(
              listenable: FirebaseAuthService(),
              builder: (context, _) {
                final auth = FirebaseAuthService();
                final user = auth.currentUser;
                final displayName = user?.displayName ?? 'Khách';
                final email = user?.email ?? 'Chưa đăng nhập';
                final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFD81B60),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                                            IconButton(
                        tooltip: 'Chuyển tài khoản kiểm thử RLS (Checklist 6)',
                        icon: const Icon(Icons.switch_account_rounded, size: 18, color: Color(0xFF1976D2)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Row(
                                children: [
                                  Icon(Icons.security_rounded, color: Color(0xFFD81B60)),
                                  SizedBox(width: 10),
                                  Text('Chuyển đổi tài khoản (Checklist 6)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: SizedBox(
                                width: 380,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: FirebaseAuthService.predefinedAccounts.map((acc) {
                                    final isCurrent = auth.currentUser?.id == acc.id;
                                    return ListTile(
                                      dense: true,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      selected: isCurrent,
                                      selectedTileColor: const Color(0xFFF7D8DF),
                                      leading: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isCurrent ? const Color(0xFFD81B60) : Colors.grey.shade400,
                                        child: Text(acc.displayName[0], style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      ),
                                      title: Text(acc.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Text(acc.email + ' • ' + acc.role, style: const TextStyle(fontSize: 10)),
                                      trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: Color(0xFFD81B60), size: 18) : null,
                                      onTap: () async {
                                        Navigator.pop(ctx);
                                        await auth.switchUser(acc.id);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
IconButton(
                        tooltip: 'Đăng xuất tài khoản',
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Color(0xFFD81B60),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: const Row(
                                children: [
                                  Icon(Icons.logout_rounded, color: Color(0xFFD81B60)),
                                  SizedBox(width: 10),
                                  Text('Đăng xuất tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Hủy'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD81B60),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Đăng xuất'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await auth.signOut();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
