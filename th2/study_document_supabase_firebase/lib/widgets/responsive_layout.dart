import 'package:flutter/material.dart';

/// Các ngưỡng kích thước chuẩn cho Responsive Web & Mobile
class ResponsiveBreakpoints {
  static const double mobileMax = 700.0;
  static const double tabletMax = 1100.0;
  static const double maxContentWidth = 1320.0;
}

/// Helper tiện ích kiểm tra nhanh loại thiết bị dựa vào BuildContext hoặc chiều rộng
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= ResponsiveBreakpoints.mobileMax &&
        width < ResponsiveBreakpoints.tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.tabletMax;

  static bool isWebOrDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.mobileMax;

  /// Lấy giá trị tương ứng từng loại màn hình (Mobile / Tablet / Desktop)
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }
}

/// Extension tiện lợi trên BuildContext để truy cập nhanh responsive properties
extension ResponsiveContextExtension on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  bool get isWebOrDesktop => ResponsiveHelper.isWebOrDesktop(this);

  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    required T desktop,
  }) =>
      ResponsiveHelper.value(
        context: this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );
}

/// Widget chuyển đổi giao diện linh hoạt theo kích thước container
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tabletMax) {
          return desktop;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.mobileMax) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Widget bọc nội dung cho Web/Desktop với giới hạn chiều rộng tối đa (Max Content Width)
/// Giúp giao diện không bị dàn ngang quá mức trên màn hình lớn/2K/4K
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        child: child,
      ),
    );
  }
}
