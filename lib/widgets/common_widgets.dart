import 'package:flutter/material.dart';
import '../models/app_models.dart';

class ParleyAvatar extends StatelessWidget {
  final UserProfile profile;
  final double radius;

  const ParleyAvatar({super.key, required this.profile, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final hasUrl = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: hasUrl ? NetworkImage(profile.avatarUrl!) : null,
      child: hasUrl
          ? null
          : Text(
              profile.initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.85,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
