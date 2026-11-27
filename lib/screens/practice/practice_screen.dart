import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../services/supabase_client.dart';
import '../../widgets/common_widgets.dart';

class PracticeScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const PracticeScreen({super.key, required this.currentProfile});

  @override
  State createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State {
  bool _isAvailableToSpeak = true;
  bool _isLoadingPartners = true;
  List _allPartners = [];
  Set _onlineUserIds = {};
  RealtimeChannel? _lobbyChannel;
  Map? _incomingCall;

  @override
  void initState() {
    super.initState();
    _loadPartners();
    _setupLobbyChannel();
  }

  @override
  void dispose() {
    if (_lobbyChannel != null) {
      supabase.removeChannel(_lobbyChannel!);
    }
    super.dispose();
  }

  Future _loadPartners() async {
    final w = widget as PracticeScreen;
    try {
      final rows = await supabase
          .from('profiles')
          .select()
          .neq('id', w.currentProfile.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allPartners = (rows as List).map((r) => UserProfile.fromMap(r as Map)).toList();
          _isLoadingPartners = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPartners = false);
    }
  }

  void _setupLobbyChannel() {
    final w = widget as PracticeScreen;
    final myId = w.currentProfile.id;

    _lobbyChannel = supabase.channel(
      'spoken_practice_lobby',
      opts: const RealtimeChannelConfig(self: false),
    );

    _lobbyChannel!
        .onPresenceSync((_) {
          final states = _lobbyChannel!.presenceState();
          final active = <String>{};
          for (final state in states) {
            for (final presence in state.presences) {
              final uid = presence.payload['user_id']?.toString();
              if (uid != null && uid.isNotEmpty) {
                active.add(uid);
              }
            }
          }
          if (mounted) {
            setState(() => _onlineUserIds = active);
          }
        })
        .onBroadcast(
          event: 'call_invite',
          callback: (payload) {
            if (payload['callee_id'] == myId && mounted) {
              SystemSound.play(SystemSoundType.alert);
              HapticFeedback.heavyImpact();
              setState(() => _incomingCall = Map.from(payload));
            }
          },
        )
        .onBroadcast(
          event: 'call_cancel',
          callback: (payload) {
            if (_incomingCall != null &&
                payload['room_id'] == _incomingCall!['room_id'] &&
                mounted) {
              setState(() => _incomingCall = null);
            }
          },
        )
        .subscribe((status, [_]) async {
          if (status == RealtimeSubscribeStatus.subscribed && _isAvailableToSpeak) {
            await _lobbyChannel!.track({
              'user_id': myId,
              'handle': w.currentProfile.handle,
              'native_lang': w.currentProfile.nativeLang,
              'learning_lang': w.currentProfile.learningLang,
            });
          }
        });
  }

  Future _toggleAvailability(bool value) async {
    final w = widget as PracticeScreen;
    setState(() => _isAvailableToSpeak = value);
    if (_lobbyChannel == null) return;

    if (value) {
      await _lobbyChannel!.track({
        'user_id': w.currentProfile.id,
        'handle': w.currentProfile.handle,
        'native_lang': w.currentProfile.nativeLang,
        'learning_lang': w.currentProfile.learningLang,
      });
    } else {
      await _lobbyChannel!.untrack();
    }
  }

  Future _startCall(UserProfile partner, {required bool isVideo}) async {
    final w = widget as PracticeScreen;
    final roomId = 'room_${w.currentProfile.id}_${partner.id}_${DateTime.now().millisecondsSinceEpoch}';

    if (_lobbyChannel != null) {
      await _lobbyChannel!.sendBroadcastMessage(
        event: 'call_invite',
        payload: {
          'room_id': roomId,
          'caller_id': w.currentProfile.id,
          'caller_handle': w.currentProfile.handle,
          'caller_native': w.currentProfile.nativeLang,
          'caller_learning': w.currentProfile.learningLang,
          'callee_id': partner.id,
          'is_video': isVideo,
        },
      );
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveCallScreen(
          roomId: roomId,
          currentProfile: w.currentProfile,
          partner: partner,
          isCaller: true,
          isVideo: isVideo,
          lobbyChannel: _lobbyChannel,
        ),
      ),
    );
  }

  Future _acceptIncomingCall() async {
    final call = _incomingCall;
    if (call == null) return;
    final w = widget as PracticeScreen;

    setState(() => _incomingCall = null);

    final caller = UserProfile(
      id: call['caller_id'].toString(),
      handle: call['caller_handle'].toString(),
      nativeLang: (call['caller_native'] ?? 'English').toString(),
      learningLang: (call['caller_learning'] ?? 'Spanish').toString(),
      bio: '',
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveCallScreen(
          roomId: call['room_id'].toString(),
          currentProfile: w.currentProfile,
          partner: caller,
          isCaller: false,
          isVideo: (call['is_video'] as bool?) ?? false,
          lobbyChannel: _lobbyChannel,
        ),
      ),
    );
  }

  Future _declineIncomingCall() async {
    final call = _incomingCall;
    if (call == null) return;
    setState(() => _incomingCall = null);

    if (_lobbyChannel != null) {
      await _lobbyChannel!.sendBroadcastMessage(
        event: 'call_decline',
        payload: {'room_id': call['room_id']},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlinePartners = _allPartners
        .where((p) => _onlineUserIds.contains((p as UserProfile).id))
        .toList();
    final offlinePartners = _allPartners
        .where((p) => !_onlineUserIds.contains((p as UserProfile).id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spoken Practice'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPartners),
        ],
      ),
      body: Column(
        children: [
          if (_incomingCall != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.ring_volume, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incoming ${(_incomingCall!['is_video'] == true) ? 'Video' : 'Voice'} Call',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          _incomingCall!['caller_handle'].toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.redAccent),
                    onPressed: _declineIncomingCall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.lightGreenAccent),
                    onPressed: _acceptIncomingCall,
                  ),
                ],
              ),
            ),
          Card(
            margin: const EdgeInsets.all(16),
            child: SwitchListTile(
              title: const Text('Available for Spoken Practice', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                _isAvailableToSpeak
                    ? 'You are visible to partners in the lobby.'
                    : 'You appear offline for calls.',
              ),
              value: _isAvailableToSpeak,
              onChanged: _toggleAvailability,
            ),
          ),
          Expanded(
            child: _isLoadingPartners
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 10, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Online Now (${onlinePartners.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (onlinePartners.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No partners online right now. You can still ring any reader below if they have the app open!',
                            style: TextStyle(color: Theme.of(context).disabledColor, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ...onlinePartners.map((p) {
                          final partner = p as UserProfile;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: ParleyAvatar(profile: partner),
                              title: Text(partner.handle, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Speaks ${partner.nativeLang} • Learning ${partner.learningLang}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.call, color: Theme.of(context).colorScheme.primary),
                                    onPressed: () => _startCall(partner, isVideo: false),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.videocam, color: Theme.of(context).colorScheme.primary),
                                    onPressed: () => _startCall(partner, isVideo: true),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 18),
                      const Text(
                        'All Readers',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      ...offlinePartners.map((p) {
                        final partner = p as UserProfile;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: ParleyAvatar(profile: partner),
                            title: Text(partner.handle, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Speaks ${partner.nativeLang} • Learning ${partner.learningLang}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.call_outlined),
                                  onPressed: () => _startCall(partner, isVideo: false),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.videocam_outlined),
                                  onPressed: () => _startCall(partner, isVideo: true),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class ActiveCallScreen extends StatefulWidget {
  final String roomId;
  final UserProfile currentProfile;
  final UserProfile partner;
  final bool isCaller;
  final bool isVideo;
  final RealtimeChannel? lobbyChannel;

  const ActiveCallScreen({
    super.key,
    required this.roomId,
    required this.currentProfile,
    required this.partner,
    required this.isCaller,
    required this.isVideo,
    this.lobbyChannel,
  });

  @override
  State createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RealtimeChannel? _roomChannel;

  String _statusText = 'Connecting...';
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isConnected = false;
  Timer? _callTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _cleanupMedia();
    super.dispose();
  }

  Future _cleanupMedia() async {
    try {
      if (_roomChannel != null) {
        await supabase.removeChannel(_roomChannel!);
      }
      _localStream?.getTracks().forEach((t) => t.stop());
      await _localStream?.dispose();
      await _peerConnection?.close();
      await _localRenderer.dispose();
      await _remoteRenderer.dispose();
    } catch (_) {}
  }

  Future _initCall() async {
    final w = widget as ActiveCallScreen;
    setState(() {
      _statusText = w.isCaller ? 'Ringing ${w.partner.handle}...' : 'Connecting call...';
    });

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': w.isVideo ? {'facingMode': 'user'} : false,
      });
      _localRenderer.srcObject = _localStream;
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Microphone/Camera permission denied: $e');
      }
      return;
    }

    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty && mounted) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
          _isConnected = true;
          _statusText = 'Connected';
        });
        _startTimer();
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && _roomChannel != null) {
        _roomChannel!.sendBroadcastMessage(
          event: 'ice',
          payload: {
            'sender_id': w.currentProfile.id,
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      }
    };

    _roomChannel = supabase.channel(
      w.roomId,
      opts: const RealtimeChannelConfig(self: false),
    );

    _roomChannel!
        .onBroadcast(
          event: 'offer',
          callback: (payload) async {
            if (!w.isCaller && _peerConnection != null) {
              await _peerConnection!.setRemoteDescription(
                RTCSessionDescription(payload['sdp'], payload['type']),
              );
              final answer = await _peerConnection!.createAnswer();
              await _peerConnection!.setLocalDescription(answer);
              await _roomChannel!.sendBroadcastMessage(
                event: 'answer',
                payload: {'sdp': answer.sdp, 'type': answer.type},
              );
            }
          },
        )
        .onBroadcast(
          event: 'answer',
          callback: (payload) async {
            if (w.isCaller && _peerConnection != null) {
              await _peerConnection!.setRemoteDescription(
                RTCSessionDescription(payload['sdp'], payload['type']),
              );
            }
          },
        )
        .onBroadcast(
          event: 'ice',
          callback: (payload) async {
            if (_peerConnection != null) {
              await _peerConnection!.addCandidate(
                RTCIceCandidate(
                  payload['candidate'],
                  payload['sdpMid'],
                  payload['sdpMLineIndex'],
                ),
              );
            }
          },
        )
        .onBroadcast(
          event: 'hangup',
          callback: (_) {
            if (mounted) Navigator.pop(context);
          },
        )
        .subscribe((status, [_]) async {
          if (status == RealtimeSubscribeStatus.subscribed && w.isCaller) {
            await Future.delayed(const Duration(milliseconds: 600));
            final offer = await _peerConnection!.createOffer();
            await _peerConnection!.setLocalDescription(offer);
            await _roomChannel!.sendBroadcastMessage(
              event: 'offer',
              payload: {'sdp': offer.sdp, 'type': offer.type},
            );
          }
        });
  }

  void _startTimer() {
    if (_callTimer != null) return;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds += 1);
    });
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _toggleMute() {
    if (_localStream == null) return;
    final nextMuted = !_isMuted;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !nextMuted;
    }
    setState(() => _isMuted = nextMuted);
  }

  void _toggleCamera() {
    if (_localStream == null) return;
    final nextOff = !_isCameraOff;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = !nextOff;
    }
    setState(() => _isCameraOff = nextOff);
  }

  Future _endCall() async {
    final w = widget as ActiveCallScreen;
    if (_roomChannel != null) {
      await _roomChannel!.sendBroadcastMessage(event: 'hangup', payload: {});
    }
    if (w.lobbyChannel != null) {
      await w.lobbyChannel!.sendBroadcastMessage(
        event: 'call_cancel',
        payload: {'room_id': w.roomId},
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as ActiveCallScreen;
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(w.partner.handle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: w.isVideo
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                        ),
                        Positioned(
                          right: 16,
                          top: 16,
                          width: 110,
                          height: 150,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: RTCVideoView(_localRenderer, mirror: true),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ParleyAvatar(profile: w.partner, radius: 56),
                          const SizedBox(height: 20),
                          Text(
                            w.partner.handle,
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isConnected ? _formatDuration(_elapsedSeconds) : _statusText,
                            style: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
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
                      onPressed: _toggleMute,
                    ),
                  ),
                  if (w.isVideo)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _isCameraOff ? Colors.white : Colors.white24,
                      child: IconButton(
                        icon: Icon(_isCameraOff ? Icons.videocam_off : Icons.videocam, color: _isCameraOff ? Colors.black : Colors.white),
                        onPressed: _toggleCamera,
                      ),
                    ),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white, size: 28),
                      onPressed: _endCall,
                    ),
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
  State createState() => _RandomCallScreenState();
}

class _RandomCallScreenState extends State {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  RealtimeChannel? _signalChannel;
  final Set _processedIds = {};
  final List _pendingRemoteIce = [];
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
    final w = widget as RandomCallScreen;
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': w.isVideo ? {'facingMode': 'user'} : false,
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
          'room_id': w.roomId,
          'sender_id': w.currentProfile.id,
          'type': 'ice',
          'payload': {'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMLineIndex},
        });
      }
    };

    _signalChannel = supabase
        .channel('sig_${w.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'call_signals',
          callback: (payload) => _handleSignalRow(payload.newRecord),
        )
        .subscribe();

    if (mounted) setState(() => _statusText = 'Connecting with ${w.partnerHandle}...');

    if (w.isCaller) {
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      await supabase.from('call_signals').insert({
        'room_id': w.roomId,
        'sender_id': w.currentProfile.id,
        'type': 'offer',
        'payload': {'sdp': offer.sdp, 'type': offer.type},
      });
    } else {
      final existing = await supabase.from('call_signals').select().eq('room_id', w.roomId).order('created_at', ascending: true);
      for (final row in (existing as List)) {
        await _handleSignalRow(row as Map);
      }
    }
  }

  Future _handleSignalRow(Map row) async {
    final w = widget as RandomCallScreen;
    final id = row['id']?.toString() ?? '';
    if (id.isNotEmpty && _processedIds.contains(id)) return;
    if (id.isNotEmpty) _processedIds.add(id);
    if (row['sender_id'] == w.currentProfile.id) return;

    final type = row['type'].toString();
    final data = row['payload'] as Map;

    if (type == 'offer' && !w.isCaller && _pc != null) {
      await _pc!.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
      _remoteDescSet = true;
      for (final ice in _pendingRemoteIce) {
        await _pc!.addCandidate(ice);
      }
      _pendingRemoteIce.clear();

      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      await supabase.from('call_signals').insert({
        'room_id': w.roomId,
        'sender_id': w.currentProfile.id,
        'type': 'answer',
        'payload': {'sdp': answer.sdp, 'type': answer.type},
      });
    } else if (type == 'answer' && w.isCaller && _pc != null) {
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
    final w = widget as RandomCallScreen;
    try {
      await supabase.from('call_signals').insert({
        'room_id': w.roomId,
        'sender_id': w.currentProfile.id,
        'type': 'hangup',
        'payload': {},
      });
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as RandomCallScreen;
    return Scaffold(
      backgroundColor: const Color(0xFF1A2421),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(w.partnerHandle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: w.isVideo
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
                          Text(w.partnerHandle, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                  if (w.isVideo)
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
