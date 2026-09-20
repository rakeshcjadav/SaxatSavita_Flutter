import 'package:flutter/material.dart';

const quizSoftGreen = Color(0xFFE8F5E9);
const quizSoftGreenBorder = Color(0xFF81C784);
const quizSoftGreenFg = Color(0xFF1B5E20);
const quizSoftRed = Color(0xFFFFEBEE);
const quizSoftRedBorder = Color(0xFFE57373);
const quizSoftRedFg = Color(0xFFB71C1C);
const quizGuOptionLetters = ['ક', 'ખ', 'ગ', 'ઘ'];

String toGujaratiNumeral(int n) {
  return n
      .toString()
      .replaceAll('0', '૦')
      .replaceAll('1', '૧')
      .replaceAll('2', '૨')
      .replaceAll('3', '૩')
      .replaceAll('4', '૪')
      .replaceAll('5', '૫')
      .replaceAll('6', '૬')
      .replaceAll('7', '૭')
      .replaceAll('8', '૮')
      .replaceAll('9', '૯');
}

String quizOptionLetter({
  required bool useGujarati,
  required int displayIndex,
}) {
  if (useGujarati && displayIndex < quizGuOptionLetters.length) {
    return quizGuOptionLetters[displayIndex];
  }
  return String.fromCharCode(65 + displayIndex);
}
