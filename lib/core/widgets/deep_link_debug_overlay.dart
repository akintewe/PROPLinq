import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proplinq/core/services/deep_linking_service.dart';

/// Temporary on-screen debug overlay for diagnosing deep link flow without a
/// cable. Shows every step the DeepLinkingService records. Tap to expand/hide,
/// long-press to copy the log. Remove once deep linking is confirmed working.
class DeepLinkDebugOverlay extends StatefulWidget {
  const DeepLinkDebugOverlay({super.key});

  @override
  State<DeepLinkDebugOverlay> createState() => _DeepLinkDebugOverlayState();
}

class _DeepLinkDebugOverlayState extends State<DeepLinkDebugOverlay> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: DeepLinkingService.debugLog,
      builder: (context, log, _) {
        // Hide entirely until the first deep-link event is recorded.
        if (log.isEmpty) return const SizedBox.shrink();

        return Positioned(
          left: 8,
          right: 8,
          bottom: 40,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: log.join('\n')));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deep link log copied')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                constraints: BoxConstraints(
                  maxHeight: _expanded ? 320 : 90,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.link,
                            color: Colors.greenAccent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'DEEP LINK LOG (${log.length}) — tap expand, hold to copy',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        reverse: true,
                        child: Text(
                          log.join('\n'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
