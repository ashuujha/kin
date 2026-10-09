import 'package:flutter/material.dart';

class CareArtwork extends StatelessWidget {
  const CareArtwork({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 225,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: const BoxDecoration(
            color: Color(0xffc4e59a),
            shape: BoxShape.circle,
          ),
        ),
        const Positioned(
          top: 8,
          right: 28,
          child: Icon(Icons.add_rounded, size: 42, color: Color(0xffc4e59a)),
        ),
        const Positioned(
          bottom: 16,
          left: 22,
          child: Icon(Icons.add_rounded, size: 28, color: Color(0xffa9d47a)),
        ),
        Transform.rotate(
          angle: -.10,
          child: Container(
            width: 144,
            height: 172,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xff151525), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 35,
                  color: Color(0xff151525),
                ),
                const SizedBox(height: 18),
                for (final width in [88.0, 72.0, 84.0]) ...[
                  Container(
                    height: 7,
                    width: width,
                    decoration: BoxDecoration(
                      color: const Color(0xffe9e9e5),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 9),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 19,
          right: 47,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff151525),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xffc4e59a),
              size: 27,
            ),
          ),
        ),
      ],
    ),
  );
}

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
          color: const Color(0xff151525),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Color(0xffc4e59a),
          size: 19,
        ),
      ),
      const SizedBox(width: 9),
      const Text(
        'kin',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 35,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
          color: Color(0xff151525),
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
      color: dark ? const Color(0xffc4e59a) : const Color(0xfff3f3f0),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: const Color(0xff151525)),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xff151525),
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
    this.compact = false,
  });
  final String title, description;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 28, color: const Color(0xff151525)),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xff777780),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xfff3f3f0),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: const Color(0xff151525)),
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
                            color: Color(0xff777780),
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(label),
  );
}
