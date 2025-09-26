import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/customHtmlWidget.dart';
import '../models/aashirvachan_model.dart';
import 'package:saxatsavita_flutter/services/appdataservice.dart';

class AashirvachanDetailPage extends StatefulWidget {
  const AashirvachanDetailPage({super.key, required this.aashirvachan});

  final AashirvachanModel aashirvachan;

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
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: widget.aashirvachan.title,
        actionItems: [ActionOptions.settings],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                  Center(
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
                  CustomHtmlWidget(
                    htmlContent:
                        AppDataService().getValue(
                          widget.aashirvachan.content.text!,
                        )!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
