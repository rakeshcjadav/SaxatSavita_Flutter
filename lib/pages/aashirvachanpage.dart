import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

class Aashirvachanpage extends StatelessWidget {
  const Aashirvachanpage({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.orange.shade100;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.aashirvachan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Hero(
              tag: 'jogiswami-image',
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/res/z_ashirvachan_jogiswami_image.webp',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Hero(
              tag: 'swamishree-image',
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/res/z_ashirvachan_swami_shree_image.webp',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
