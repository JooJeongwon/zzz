import 'package:flutter/material.dart';

@immutable
class ChatTheme extends ThemeExtension<ChatTheme> {
  final Color myBubbleColor;
  final Color myBubbleTextColor;
  final Color partnerBubbleColor;
  final Color partnerBubbleTextColor;
  final Color aiBubbleColor;
  final Color aiBubbleTextColor;
  final Color inputBackgroundColor;

  const ChatTheme({
    required this.myBubbleColor,
    required this.myBubbleTextColor,
    required this.partnerBubbleColor,
    required this.partnerBubbleTextColor,
    required this.aiBubbleColor,
    required this.aiBubbleTextColor,
    required this.inputBackgroundColor,
  });

  @override
  ChatTheme copyWith({
    Color? myBubbleColor,
    Color? myBubbleTextColor,
    Color? partnerBubbleColor,
    Color? partnerBubbleTextColor,
    Color? aiBubbleColor,
    Color? aiBubbleTextColor,
    Color? inputBackgroundColor,
  }) {
    return ChatTheme(
      myBubbleColor: myBubbleColor ?? this.myBubbleColor,
      myBubbleTextColor: myBubbleTextColor ?? this.myBubbleTextColor,
      partnerBubbleColor: partnerBubbleColor ?? this.partnerBubbleColor,
      partnerBubbleTextColor: partnerBubbleTextColor ?? this.partnerBubbleTextColor,
      aiBubbleColor: aiBubbleColor ?? this.aiBubbleColor,
      aiBubbleTextColor: aiBubbleTextColor ?? this.aiBubbleTextColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
    );
  }

  @override
  ChatTheme lerp(ThemeExtension<ChatTheme>? other, double t) {
    if (other is! ChatTheme) {
      return this;
    }
    return ChatTheme(
      myBubbleColor: Color.lerp(myBubbleColor, other.myBubbleColor, t)!,
      myBubbleTextColor: Color.lerp(myBubbleTextColor, other.myBubbleTextColor, t)!,
      partnerBubbleColor: Color.lerp(partnerBubbleColor, other.partnerBubbleColor, t)!,
      partnerBubbleTextColor: Color.lerp(partnerBubbleTextColor, other.partnerBubbleTextColor, t)!,
      aiBubbleColor: Color.lerp(aiBubbleColor, other.aiBubbleColor, t)!,
      aiBubbleTextColor: Color.lerp(aiBubbleTextColor, other.aiBubbleTextColor, t)!,
      inputBackgroundColor: Color.lerp(inputBackgroundColor, other.inputBackgroundColor, t)!,
    );
  }
}
