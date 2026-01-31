import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';

class MenuTile extends StatefulWidget {
  final IconData? icon;
  final String? svgPath;
  final String title;
  final String? subtitle;
  final Color color;
  final int? badgeCount;
  final VoidCallback onTap;

  const MenuTile({
    super.key,
    this.icon,
    this.svgPath,
    required this.title,
    this.subtitle,
    required this.color,
    this.badgeCount,
    required this.onTap,
  });

  @override
  State<MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<MenuTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // أحجام متجاوبة
        final iconSize = constraints.maxWidth * 0.16;
        final bgIconSize = constraints.maxWidth * 0.45;
        final iconBoxSize = constraints.maxWidth * 0.28;
        final titleSize = constraints.maxWidth * 0.10;
        final subtitleSize = constraints.maxWidth * 0.07;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isHovered
                        ? widget.color
                        : AppColors.border.withValues(alpha: 0.6),
                    width: _isHovered ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? widget.color.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 🎨 أيقونة خلفية كبيرة شفافة (زخرفة)
                    Positioned(
                      left: -bgIconSize * 0.15,
                      bottom: -bgIconSize * 0.15,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isHovered ? 0.12 : 0.06,
                        child: widget.svgPath != null
                            ? SvgPicture.asset(
                                widget.svgPath!,
                                width: bgIconSize,
                                height: bgIconSize,
                                colorFilter: ColorFilter.mode(
                                  widget.color,
                                  BlendMode.srcIn,
                                ),
                              )
                            : Icon(
                                widget.icon,
                                color: widget.color,
                                size: bgIconSize,
                              ),
                      ),
                    ),

                    // المحتوى الرئيسي
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(constraints.maxWidth * 0.08),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🎨 الأيقونة الرئيسية
                            Flexible(
                              flex: 3,
                              child: _buildIconBox(iconBoxSize, iconSize),
                            ),

                            SizedBox(height: constraints.maxWidth * 0.04),

                            // 📝 العنوان الرئيسي
                            Flexible(
                              flex: 1,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: titleSize.clamp(12.0, 18.0),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // العنوان الفرعي
                            if (widget.subtitle != null) ...[
                              SizedBox(height: constraints.maxWidth * 0.02),
                              Flexible(
                                flex: 1,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: subtitleSize.clamp(9.0, 12.0),
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // بناء صندوق الأيقونة الملون
  Widget _buildIconBox(double boxSize, double iconSize) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            // لون خلفية فاتح مشتق من اللون الأساسي
            color: widget.color.withValues(alpha: _isHovered ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(boxSize * 0.25),
          ),
          child: Center(
            child: widget.svgPath != null
                ? SvgPicture.asset(
                    widget.svgPath!,
                    width: iconSize,
                    height: iconSize,
                    colorFilter: ColorFilter.mode(
                      widget.color,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(
                    widget.icon,
                    color: widget.color,
                    size: iconSize,
                  ),
          ),
        ),
        // الشارة (Badge)
        if (widget.badgeCount != null && widget.badgeCount! > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                // حدود بيضاء لفصل الشارة عن الأيقونة
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                widget.badgeCount! > 99 ? '99+' : '${widget.badgeCount}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
