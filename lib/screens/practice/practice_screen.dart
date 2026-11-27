import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../services/sound_service.dart';
import '../../services/supabase_client.dart';

class PracticeScreen extends StatefulWidget {
  final UserProfile currentProfile;
  const PracticeScreen({super.key, required this.currentProfile});
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  bool _preferVideo = false;
  int _waitingCount = 0;
  Timer? _pollTimer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _refreshQueueCount();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    if (_isSearching) {
        supabase.from('practice_queue').delete().eq('user_id', widget.currentProfile.id);
    }
    super.dispose();
  }

  Future _refreshQueueCount() async {
    try {
      final rows = await supabase.from('practice_queue').select('user_id').eq('status', 'waiting');
      if (mounted) setState(() => _waitingCount = (rows as List).length);
    } catch (_) {}
  }

  Future _startSearching() async {
    final me = widget.currentProfile;
    SoundService.playMessageChime();
    setState(() => _isSearching = true);

    try {
      await supabase.from('practice_queue').upsert({
        'user_id': me.id,
        'handle': me.handle,
        'gender': me.gender,
        'country': me.country,
        'native_lang': me.nativeLang,
        'learning_lang': me.learningLang,
        'status': 'waiting',
        'room_id': null,
        'partner_id': null,
        'partner_handle': null,
        'is_caller': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkMatch());
      await _checkMatch();
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Matchmaking error: $e')));
      }
    }
  }

  Future _cancelSearching() async {
    _pollTimer?.cancel();
    setState(() => _isSearching = false);
    try {
      await supabase.from('practice_queue').delete().eq('user_id', widget.currentProfile.id);
    } catch (_) {}
    _refreshQueueCount();
  }

  Future _checkMatch() async {
    if (!_isSearching || !mounted) return;
    final me = widget.currentProfile;

    try {
      final myRow = await supabase.from('practice_queue').select().eq('user_id', me.id).maybeSingle();
      if (myRow != null && myRow['status'] == 'matched' && myRow['room_id'] != null) {
        _pollTimer?.cancel();
        setState(() => _isSearching = false);
        SoundService.playMatchRing();
        await supabase.from('practice_queue').delete().eq('user_id', me.id);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RandomCallScreen(
              roomId: myRow['room_id'].toString(),
              currentProfile: me,
              partnerHandle: (myRow['partner_handle'] ?? '@partner').toString(),
              isCaller: (myRow['is_caller'] as bool?) ?? false,
              isVideo: _preferVideo,
            ),
          ),
        );
        _refreshQueueCount();
        return;
      }

      final waiting = await supabase
          .from('practice_queue')
          .select()
          .eq('status', 'waiting')
          .neq('user_id', me.id)
          .order('updated_at', ascending: true)
          .limit(1);

      final list = waiting as List;
      if (mounted) setState(() => _waitingCount = list.length + 1);

      if (list.isNotEmpty) {
        final other = list.first as Map;
        final otherId = other['user_id'].toString();
        final otherHandle = (other['handle'] ?? '@partner').toString();
        final roomId = 'parley_${me.id}_${otherId}_${DateTime.now().millisecondsSinceEpoch}';

        final claimed = await supabase
            .from('practice_queue')
            .update({
              'status': 'matched',
              'room_id': roomId,
              'partner_id': me.id,
              'partner_handle': '${me.handle} ${me.countryFlag}',
              'is_caller': false,
            })
            .eq('user_id', otherId)
            .eq('status', 'waiting')
            .select();

        if ((claimed as List).isNotEmpty) {
          _pollTimer?.cancel();
          setState(() => _isSearching = false);
          SoundService.playMatchRing();
          await supabase.from('practice_queue').delete().eq('user_id', me.id);
          if (!mounted) return;
          final otherFlag = countryToFlag((other['country'] ?? '').toString());
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RandomCallScreen(
                roomId: roomId,
                currentProfile: me,
                partnerHandle: '$otherHandle $otherFlag',
                isCaller: true,
                isVideo: _preferVideo,
              ),
            ),
          );
          _refreshQueueCount();
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.currentProfile;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Spoken Practice')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 10, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      _isSearching
                          ? 'Matching you with a live speaker...'
                          : '$_waitingCount speaker(s) in queue right now',
                      style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              ScaleTransition(
                scale: _isSearching
                    ? Tween<double>(begin: 0.94, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut))
                    : const AlwaysStoppedAnimation<double>(1.0),
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isSearching
                          ? [Colors.deepOrange, Colors.amber.shade700]
                          : [primary, const Color(0xFF1B4332)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isSearching ? Colors.deepOrange : primary).withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _isSearching ? _cancelSearching : _startSearching,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isSearching ? Icons.close : Icons.record_voice_over, size: 48, color: Colors.white),
                        const SizedBox(height: 10),
                        Text(
                          _isSearching ? 'Cancel' : 'Start Random\nPractice',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _isSearching
                    ? 'Searching for an online partner...\nKeep this screen open; you will connect automatically!'
                    : 'Tap the button to connect 1-on-1 with a random online speaker practicing ${me.learningLang}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: false, icon: Icon(Icons.call), label: Text('Voice Call')),
                  ButtonSegment<bool>(value: true, icon: Icon(Icons.videocam), label: Text('Video Call')),
                ],
                selected: {_preferVideo},
                onSelectionChanged: _isSearching ? null : (s) => setState(() => _preferVideo = s.first),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RandomCallScreen extends StatefulWidget {
  final String roomId;
  final UserProfile currentProfile;
  final String partnerHandle;
  final bool isCaller;
  final bool isVideo;

  const RandomCallScreen({
    super.key,
    required this.roomId,
    required this.currentProfile,
    required this.partnerHandle,
    required this.isCaller,
    required this.isVideo,
  });

  @override
  State<RandomCallScreen> createState() => _RandomCallScreenState();
}

class _RandomCallScreenState extends State<RandomCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  RealtimeChannel? _signalChannel;
  final Set<String> _processedIds = {};
  final List<RTCIceCandidate> _pendingRemoteIce = [];
  bool _remoteDescSet = false;

  String _statusText = 'Initializing audio...';
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startWebRtc();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cleanup();
    super.dispose();
  }

  Future _cleanup() async {
    try {
      if (_signalChannel != null) await supabase.removeChannel(_signalChannel!);
      _localStream?.getTracks().forEach((t) => t.stop());
      await _localStream?.dispose();
      await _pc?.close();
      await _localRenderer.dispose();
      await _remoteRenderer.dispose();
    } catch (_) {}
  }

  Future _startWebRtc() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': widget.isVideo ? {'facingMode': 'user'} : false,
      });
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      if (mounted) setState(() => _statusText = 'Mic/Camera blocked: $e');
      return;
    }

    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    });

    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty && mounted) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
          _isConnected = true;
          _statusText = 'Connected';
        });
        _startClock();
      }
    };

    _pc!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected && mounted) {
        setState(() {
          _isConnected = true;
          _statusText = 'Connected';
        });
        _startClock();
      }
    };

    _pc!.onIceCandidate = (RTCIceCandidate c) async {
      if (c.candidate != null) {
        await supabase.from('call_signals').insert({
          'room_id': widget.roomId,
          'sender_id': widget.currentProfile.id,
          'type': 'ice',
          'payload': {'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMLineIndex},
        });
      }
    };

    _signalChannel = supabase
        .channel('sig_${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'call_signals',
          callback: (payload) => _handleSignalRow(payload.newRecord),
        )
        .subscribe();

    if (mounted) setState(() => _statusText = 'Connecting with ${widget.partnerHandle}...');

    if (widget.isCaller) {
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      await supabase.from('call_signals').insert({
        'room_id': widget.roomId,
        'sender_id': widget.currentProfile.id,
        'type': 'offer',
        'payload': {'sdp': offer.sdp, 'type': offer.type},
      });
    } else {
      final existing = await supabase.from('call_signals').select().eq('room_id', widget.roomId).order('created_at', ascending: true);
      for (final row in (existing as List)) {
        await _handleSignalRow(row as Map);
      }
    }
  }

  Future _handleSignalRow(Map row) async {
    final id = row['id']?.toString() ?? '';
    if (id.isNotEmpty && _processedIds.contains(id)) return;
    if (id.isNotEmpty) _processedIds.add(id);
    if (row['sender_id'] == widget.currentProfile.id) return;

    final type = row['type'].toString();
    final data = row['payload'] as Map;

    if (type == 'offer' && !widget.isCaller && _pc != null) {
      await _pc!.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
      _remoteDescSet = true;
      for (final ice in _pendingRemoteIce) {
        await _pc!.addCandidate(ice);
      }
      _pendingRemoteIce.clear();

      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      await supabase.from('call_signals').insert({
        'room_id': widget.roomId,
        'sender_id': widget.currentProfile.id,
        'type': 'answer',
        'payload': {'sdp': answer.sdp, 'type': answer.type},
      });
    } else if (type == 'answer' && widget.isCaller && _pc != null) {
      await _pc!.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
      _remoteDescSet = true;
      for (final ice in _pendingRemoteIce) {
        await _pc!.addCandidate(ice);
      }
      _pendingRemoteIce.clear();
    } else if (type == 'ice' && _pc != null) {
      final candidate = RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']);
      if (_remoteDescSet) {
        await _pc!.addCandidate(candidate);
      } else {
        _pendingRemoteIce.add(candidate);
      }
    } else if (type == 'hangup' && mounted) {
      Navigator.pop(context);
    }
  }

  void _startClock() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds += 1);
    });
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Future _hangUp() async {
    try {
      await supabase.from('call_signals').insert({
        'room_id': widget.roomId,
        'sender_id': widget.currentProfile.id,
        'type': 'hangup',
        'payload': {},
      });
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2421),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.partnerHandle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: widget.isVideo
                  ? Stack(
                      children: [
                        Positioned.fill(child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
                        Positioned(right: 16, top: 16, width: 110, height: 150, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: RTCVideoView(_localRenderer, mirror: true))),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(radius: 54, backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.person, size: 54, color: Colors.white)),
                          const SizedBox(height: 20),
                          Text(widget.partnerHandle, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_isConnected ? 'Connected • ${_fmt(_seconds)}' : _statusText, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _isMuted ? Colors.white : Colors.white24,
                    child: IconButton(
                      icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.black : Colors.white),
                      onPressed: () {
                        final next = !_isMuted;
                        _localStream?.getAudioTracks().forEach((t) => t.enabled = !next);
                        setState(() => _isMuted = next);
                      },
                    ),
                  ),
                  if (widget.isVideo)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _isCameraOff ? Colors.white : Colors.white24,
                      child: IconButton(
                        icon: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam, color: _isCameraOff ? Colors.black : Colors.white),
                        onPressed: () {
                          final next = !_isCameraOff;
                          _localStream?.getVideoTracks().forEach((t) => t.enabled = !next);
                          setState(() => _isCameraOff = next);
                        },
                      ),
                    ),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.red,
                    child: IconButton(icon: const Icon(Icons.call_end, color: Colors.white, size: 28), onPressed: _hangUp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
