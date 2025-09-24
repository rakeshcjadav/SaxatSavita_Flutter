import 'package:flutter/material.dart';
import '../models/aashirvachan_model.dart';
import 'package:saxatsavita_flutter/services/appdataservice.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/customtagregistry.dart';

class AashirvachanDetailPage extends StatefulWidget {
  AashirvachanDetailPage({super.key, required this.aashirvachan}) {
    customTagRegistry.registerCustomTags();
  }

  final AashirvachanModel aashirvachan;
  final CustomTagRegistry customTagRegistry = CustomTagRegistry();

  @override
  State<AashirvachanDetailPage> createState() => _AashirvachanDetailPageState();
}

class _AashirvachanDetailPageState extends State<AashirvachanDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle bodyStyle = Theme.of(context).textTheme.bodyMedium!;
    return Scaffold(
      appBar: AppBar(elevation: 5, title: Text(widget.aashirvachan.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Hero(
              tag: '${widget.aashirvachan.tag}-image',
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.aashirvachan.image,
                    height: 195,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                widget.aashirvachan.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (widget.aashirvachan.content.image != null) ...[
              const SizedBox(height: 16),
              Expanded(
                child: Image.asset(
                  widget.aashirvachan.content.image!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            if (widget.aashirvachan.content.text != null) ...[
              const SizedBox(height: 16),
              Html(
                data:
                    AppDataService().getValue(
                      widget.aashirvachan.content.text!,
                    )!,
                style: {
                  "body": Style(
                    fontSize:
                        bodyStyle.fontSize != null
                            ? FontSize(bodyStyle.fontSize!)
                            : FontSize(16),
                    textAlign: TextAlign.justify,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                },
                extensions: [
                  ...widget.customTagRegistry.buildExtensions(context),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
