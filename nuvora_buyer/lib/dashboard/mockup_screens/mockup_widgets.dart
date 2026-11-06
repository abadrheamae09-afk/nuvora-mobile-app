// ============================================================
// mockup_widgets.dart
// Reusable small widgets shared across multiple mockup screens.
// Keeps individual screen files lean and avoids code repetition.
// ============================================================

import 'package:flutter/material.dart';
import 'mockup_theme.dart';

// ─────────────────────────────────────────────────────────────
// Section title row
// ─────────────────────────────────────────────────────────────

class MSectionTitle extends StatelessWidget {
  const MSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: MTextStyles.title),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: MTextStyles.caption.copyWith(
                color: MColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Product card (vertical, used in grids)
// ─────────────────────────────────────────────────────────────

class MProductCard extends StatelessWidget {
  const MProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.imageColor,
    this.rating = 4.5,
    this.sold = 120,
    this.onTap,
    this.badgeLabel,
  });

  final String name;
  final String price;
  final Color imageColor;
  final double rating;
  final int sold;
  final VoidCallback? onTap;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: MDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: imageColor.withAlpha(40),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: imageColor,
                    ),
                  ),
                ),
                if (badgeLabel != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: MColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel!,
                        style: MTextStyles.tag
                            .copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MTextStyles.subtitle
                        .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(price, style: MTextStyles.price.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: MColors.starGold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$rating',
                        style: MTextStyles.caption.copyWith(fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$sold sold',
                          style: MTextStyles.caption.copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Product card (horizontal, used in lists)
// ─────────────────────────────────────────────────────────────

class MProductListTile extends StatelessWidget {
  const MProductListTile({
    super.key,
    required this.name,
    required this.price,
    required this.imageColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String price;
  final Color imageColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: MDecorations.card(),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 72,
                height: 72,
                color: imageColor.withAlpha(40),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: imageColor,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MTextStyles.subtitle.copyWith(fontSize: 13),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: MTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(price, style: MTextStyles.price.copyWith(fontSize: 14)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Order card (used in my_orders_screen)
// ─────────────────────────────────────────────────────────────

class MOrderCard extends StatelessWidget {
  const MOrderCard({
    super.key,
    required this.orderId,
    required this.sellerName,
    required this.itemCount,
    required this.total,
    required this.statusLabel,
    required this.statusColor,
    this.onTap,
  });

  final String orderId;
  final String sellerName;
  final int itemCount;
  final String total;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: MDecorations.card(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: MColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(sellerName, style: MTextStyles.subtitle),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: MTextStyles.tag.copyWith(
                      color: statusColor,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: MColors.divider),
            // Order id + count
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #$orderId',
                    style: MTextStyles.caption,
                  ),
                ),
                Text(
                  '$itemCount item${itemCount != 1 ? "s" : ""}',
                  style: MTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: $total',
                  style: MTextStyles.subtitle.copyWith(
                    color: MColors.primary,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: MColors.muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Primary button
// ─────────────────────────────────────────────────────────────

class MPrimaryButton extends StatelessWidget {
  const MPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final btn = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: MColors.primary,
        foregroundColor: Colors.white,
        minimumSize: Size(fullWidth ? double.infinity : 0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      child: child,
    );

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state placeholder
// ─────────────────────────────────────────────────────────────

class MEmptyState extends StatelessWidget {
  const MEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: MColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: MColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: MTextStyles.title, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: MTextStyles.caption.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: action,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MColors.primary,
                  side: const BorderSide(color: MColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gradient header widget (reused on home/store screens)
// ─────────────────────────────────────────────────────────────

class MGradientHeader extends StatelessWidget {
  const MGradientHeader({
    super.key,
    required this.child,
    this.height,
  });

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MColors.headerTop, MColors.headerBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Input field builder (consistent style across auth screens)
// ─────────────────────────────────────────────────────────────

class MTextField extends StatelessWidget {
  const MTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: MTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: MColors.primarySoft,
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, color: MColors.muted) : null,
        suffixIcon: suffixIcon,
        hintStyle: MTextStyles.body.copyWith(color: MColors.muted),
        labelStyle: MTextStyles.body.copyWith(color: MColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MColors.danger, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Star rating row
// ─────────────────────────────────────────────────────────────

class MStarRating extends StatelessWidget {
  const MStarRating({
    super.key,
    required this.rating,
    this.size = 20,
  });

  final int rating; // 1-5
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: MColors.starGold,
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status timeline step (order tracking)
// ─────────────────────────────────────────────────────────────

class MTimelineStep extends StatelessWidget {
  const MTimelineStep({
    super.key,
    required this.label,
    required this.timestamp,
    required this.isDone,
    required this.isLast,
  });

  final String label;
  final String timestamp;
  final bool isDone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? MColors.success : MColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDone ? MColors.success : MColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Label + time
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: MTextStyles.subtitle.copyWith(
                      color: isDone ? MColors.ink : MColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(timestamp, style: MTextStyles.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
