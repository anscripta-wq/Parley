import 'dart:js_interop';
import 'package:flutter/services.dart';

@JS('eval')
external void _jsEval(String code);

class SoundService {
  static void playMessageChime() {
    HapticFeedback.mediumImpact();
    try {
      _jsEval("var c=new(window.AudioContext||window.webkitAudioContext)(),o=c.createOscillator(),g=c.createGain();o.frequency.setValueAtTime(587,c.currentTime);o.frequency.exponentialRampToValueAtTime(880,c.currentTime+0.15);g.gain.setValueAtTime(0.2,c.currentTime);g.gain.exponentialRampToValueAtTime(0.001,c.currentTime+0.35);o.connect(g);g.connect(c.destination);o.start();o.stop(c.currentTime+0.36);");
    } catch (_) {}
  }

  static void playMatchRing() {
    HapticFeedback.heavyImpact();
    try {
      _jsEval("var c=new(window.AudioContext||window.webkitAudioContext)();[523,659,784,1046].forEach(function(f,i){var o=c.createOscillator(),g=c.createGain();o.type='triangle';o.frequency.setValueAtTime(f,c.currentTime+i*0.1);g.gain.setValueAtTime(0.2,c.currentTime+i*0.1);g.gain.exponentialRampToValueAtTime(0.001,c.currentTime+i*0.1+0.3);o.connect(g);g.connect(c.destination);o.start(c.currentTime+i*0.1);o.stop(c.currentTime+i*0.1+0.32);});");
    } catch (_) {}
  }
}
