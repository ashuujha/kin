import 'package:flutter/material.dart';

class KinBrand extends StatelessWidget {
  const KinBrand({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xff173d33),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Color(0xffe1ebe2),
          size: 19,
        ),
      ),
      const SizedBox(width: 9),
      const Text(
        'kin',
        style: TextStyle(
          fontSize: 35,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
          color: Color(0xff173d33),
        ),
      ),
    ],
  );
}

class KinBadge extends StatelessWidget {
  const KinBadge(this.text, {super.key, this.icon, this.dark = false});
  final String text;
  final IconData? icon;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: dark ? const Color(0xff2d5044) : const Color(0xffe8eee6),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 13,
            color: dark ? Colors.white : const Color(0xff173d33),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : const Color(0xff173d33),
            ),
          ),
        ),
      ],
    ),
  );
}

class KinActionCard extends StatelessWidget {
  const KinActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
  final String title, description;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xffe8eee6),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xff173d33)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff65766b),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    ),
  );
}

class KinCard extends StatelessWidget {
  const KinCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });
  final String title;
  final Widget child;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

void showNotice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
String friendlyError(Object error) =>
    'Could not complete this action. Check your connection and try again.';

class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.busy,
    required this.label,
    required this.onPressed,
  });
  final bool busy;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label),
  );
}
