import 'package:flutter/material.dart';

class AashirvachanContent {
  final String? image;
  final String? text;

  const AashirvachanContent({this.image, this.text});

  factory AashirvachanContent.fromMap(Map<String, dynamic> map) {
    return AashirvachanContent(
      image: map['image'] as String?,
      text: map['text'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {if (image != null) 'image': image, if (text != null) 'text': text};
  }
}

class AashirvachanModel {
  final String title;
  final String tag;
  final String image;
  final AashirvachanContent content;

  const AashirvachanModel({
    required this.title,
    required this.tag,
    required this.image,
    required this.content,
  });

  factory AashirvachanModel.fromMap(Map<String, dynamic> map) {
    return AashirvachanModel(
      title: map['title'] as String,
      tag: map['tag'] as String,
      image: map['image'] as String,
      content: AashirvachanContent.fromMap(
        map['content'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'tag': tag,
      'image': image,
      'content': content.toMap(),
    };
  }
}
