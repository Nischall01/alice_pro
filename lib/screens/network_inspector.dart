import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alice_transport/alice_transport.dart';
import '../models/mock_data.dart';
import '../server/websocket_server.dart';

/// Desktop Network Inspector - 3-pane workstation layout
class NetworkInspectorScreen extends StatefulWidget {
  /// Whether to populate mock sample calls on startup (defaults to false)
  final bool useMockData;

  const NetworkInspectorScreen({
    super.key,
    this.useMockData = false,
  });

  @override
  State<NetworkInspectorScreen> createState() => _NetworkInspectorScreenState();
}

class _NetworkInspectorScreenState extends State<NetworkInspectorScreen> {
  late AliceWebSocketServer _wsServer;
  final List<AliceHttpCall> _allCalls = [];
  final Map<String, String> _handshakeDevices = {};
  List<AliceHttpCall> _filteredCalls = [];
  AliceHttpCall? _selectedCall;
  String _searchQuery = '';
  String _filterMethod = 'ALL';
  String _selectedDeviceId = 'ALL';

  @override
  void initState() {
    super.initState();
    if (widget.useMockData) {
      _allCalls.addAll(MockData.generateSampleCalls());
    }
    _filteredCalls = List.from(_allCalls);

    _wsServer = AliceWebSocketServer(port: 4040);
    _wsServer.start();

    _wsServer.onDeviceConnected.listen((info) {
      setState(() {
        _handshakeDevices[info.deviceName] = '${info.deviceName} (${info.platform}) [Connected]';
      });
    });

    _wsServer.onCallReceived.listen((call) {
      setState(() {
        _allCalls.insert(0, call);
        _filterCalls();
      });
    });
  }

  @override
  void dispose() {
    _wsServer.stop();
    super.dispose();
  }

  /// Extracts unique connected devices from captured calls & handshakes
  Map<String, String> get _connectedDevices {
    final map = <String, String>{'ALL': 'All Connected Devices'};
    for (final entry in _handshakeDevices.entries) {
      map[entry.key] = entry.value;
    }
    for (final call in _allCalls) {
      if (call.deviceId != null && call.deviceId!.isNotEmpty) {
        final label = '${call.deviceName ?? 'Device'} (${call.deviceOs ?? 'Mobile'})';
        map[call.deviceId!] = label;
      }
    }
    return map;
  }

  void _filterCalls() {
    setState(() {
      _filteredCalls = _allCalls.where((call) {
        final matchesDevice = _selectedDeviceId == 'ALL' || call.deviceId == _selectedDeviceId;
        final matchesMethod = _filterMethod == 'ALL' || call.method == _filterMethod;
        final matchesSearch = _searchQuery.isEmpty ||
            call.uri.contains(_searchQuery) ||
            (call.statusCode?.toString().contains(_searchQuery) ?? false) ||
            (call.deviceName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        return matchesDevice && matchesMethod && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
    final devicesMap = _connectedDevices;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top toolbar
          Container(
            height: 56,
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF6C5CE7),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.network_ping, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Alice Workstation',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 20),

                // Device selector dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.devices, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: devicesMap.containsKey(_selectedDeviceId) ? _selectedDeviceId : 'ALL',
                        dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: devicesMap.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _selectedDeviceId = value;
                            _filterCalls();
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Search bar
                SizedBox(
                  width: 260,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search requests or devices...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (value) {
                      _searchQuery = value;
                      _filterCalls();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Method filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _filterMethod,
                    dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    items: ['ALL', 'GET', 'POST', 'PUT', 'DELETE'].map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(
                          method,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _filterMethod = value;
                        _filterCalls();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Connected devices count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cell_tower, color: Colors.green.shade300, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${devicesMap.length - 1} Devices Connected',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main 3-pane layout
          Expanded(
            child: Row(
              children: [
                // Pane 1: Request List
                Container(
                  width: 380,
                  color: panelColor,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
                          border: Border(bottom: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.list, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                            const SizedBox(width: 8),
                            Text('Requests (${_filteredCalls.length})', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _filteredCalls.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Listening on ws://0.0.0.0:4040/...\nWaiting for HTTP traffic from connected devices.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredCalls.length,
                                itemBuilder: (context, index) {
                                  final call = _filteredCalls[index];
                                  final isSelected = _selectedCall?.id == call.id;
                                  return _RequestListItem(
                                    call: call,
                                    isSelected: isSelected,
                                    onTap: () => setState(() => _selectedCall = call),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(width: 1, color: borderColor),

                // Pane 2: Request/Response Details
                Expanded(
                  flex: 2,
                  child: _selectedCall == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app, size: 64, color: isDark ? Colors.white12 : Colors.black12),
                              const SizedBox(height: 16),
                              Text('Select a request to view details', style: TextStyle(fontSize: 16, color: isDark ? Colors.white38 : Colors.black38)),
                            ],
                          ),
                        )
                      : _DetailsPanel(call: _selectedCall!, isDark: isDark, borderColor: borderColor),
                ),

                // Divider
                Container(width: 1, color: borderColor),

                // Pane 3: SQL Query Console
                Container(
                  width: 400,
                  color: panelColor,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
                          border: Border(bottom: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.storage, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                            const SizedBox(width: 8),
                            Text('Query Console', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _QueryConsole(isDark: isDark, borderColor: borderColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestListItem extends StatelessWidget {
  final AliceHttpCall call;
  final bool isSelected;
  final VoidCallback onTap;

  const _RequestListItem({
    required this.call,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2D2D5E) : const Color(0xFFEDE7F6))
              : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getMethodColor(call.method),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    call.method.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    call.uri,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  call.deviceOs?.toLowerCase().contains('android') == true
                      ? Icons.android
                      : Icons.phone_iphone,
                  size: 12,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  call.deviceName ?? 'Device',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black45),
                ),
                const Spacer(),
                Text(
                  '${call.statusCode ?? '???'} • ${call.durationMs}ms',
                  style: TextStyle(
                    fontSize: 11,
                    color: call.isSuccess ? (isDark ? Colors.greenAccent : Colors.green) : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET': return const Color(0xFF4CAF50);
      case 'POST': return const Color(0xFF2196F3);
      case 'PUT':
      case 'PATCH': return const Color(0xFFFF9800);
      case 'DELETE': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }
}

class _DetailsPanel extends StatelessWidget {
  final AliceHttpCall call;
  final bool isDark;
  final Color borderColor;

  const _DetailsPanel({
    required this.call,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getMethodColor(call.method),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        call.method.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        call.uri,
                        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.smartphone,
                      label: '${call.deviceName ?? 'Mobile'} (${call.deviceOs ?? 'OS'})',
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.speed, label: '${call.durationMs}ms'),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: call.isSuccess ? Icons.check_circle : Icons.error,
                      label: (call.statusCode ?? 'ERR').toString(),
                      color: call.isSuccess ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _CollapsibleSection(
            title: 'Request Headers',
            icon: Icons.arrow_upward,
            isDark: isDark,
            borderColor: borderColor,
            child: _HeadersTable(headers: call.headers),
          ),
          const SizedBox(height: 12),
          if (call.body != null)
            _CollapsibleSection(
              title: 'Request Body',
              icon: Icons.arrow_upward,
              isDark: isDark,
              borderColor: borderColor,
              child: _CodeBlock(code: call.body!),
            ),
          const SizedBox(height: 20),
          if (call.responseHeaders != null)
            _CollapsibleSection(
              title: 'Response Headers',
              icon: Icons.arrow_downward,
              isDark: isDark,
              borderColor: borderColor,
              child: _HeadersTable(headers: call.responseHeaders!),
            ),
          const SizedBox(height: 12),
          if (call.responseBody != null)
            _CollapsibleSection(
              title: 'Response Body',
              icon: Icons.arrow_downward,
              isDark: isDark,
              borderColor: borderColor,
              child: _CodeBlock(code: call.responseBody!),
            ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET': return const Color(0xFF4CAF50);
      case 'POST': return const Color(0xFF2196F3);
      case 'PUT':
      case 'PATCH': return const Color(0xFFFF9800);
      case 'DELETE': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? (isDark ? Colors.blueAccent : Colors.blue)).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? (isDark ? Colors.blueAccent : Colors.blue)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color ?? (isDark ? Colors.blueAccent : Colors.blue))),
        ],
      ),
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final Color borderColor;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.borderColor,
    required this.child,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: widget.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 16, color: widget.isDark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 8),
                  Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
                ],
              ),
            ),
          ),
          if (_isExpanded) widget.child,
        ],
      ),
    );
  }
}

class _HeadersTable extends StatelessWidget {
  final Map<String, String> headers;

  const _HeadersTable({required this.headers});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: headers.length,
        itemBuilder: (context, index) {
          final key = headers.keys.elementAt(index);
          final value = headers.values.elementAt(index);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.blueAccent : Colors.deepPurple)),
                ),
                Expanded(
                  child: Text(value, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CodeBlock extends StatefulWidget {
  final String code;

  const _CodeBlock({required this.code});

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _isFormatted = true;
  bool _copied = false;

  dynamic _tryParseJson(String input) {
    try {
      final firstPass = jsonDecode(input);
      if (firstPass is String) {
        try {
          return jsonDecode(firstPass);
        } catch (_) {
          return firstPass;
        }
      }
      return firstPass;
    } catch (_) {
      return null;
    }
  }

  String get _formattedCode {
    if (!_isFormatted) return widget.code;

    // 1. Try standard JSON
    final parsedJson = _tryParseJson(widget.code);
    if (parsedJson != null && parsedJson is! String) {
      return const JsonEncoder.withIndent('  ').convert(parsedJson);
    }

    // 2. Try formatting Dart map string format: {key: val, key2: val2}
    final raw = widget.code.trim();
    if ((raw.startsWith('{') && raw.endsWith('}')) || (raw.startsWith('[') && raw.endsWith(']'))) {
      return _formatDartMapString(raw);
    }

    return widget.code;
  }

  bool get _isJson {
    final parsed = _tryParseJson(widget.code);
    return parsed != null && parsed is! String;
  }

  String _formatDartMapString(String str) {
    final sb = StringBuffer();
    int indent = 0;
    bool inQuotes = false;

    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      if (char == '"' || char == "'") {
        inQuotes = !inQuotes;
        sb.write(char);
      } else if (!inQuotes && (char == '{' || char == '[')) {
        sb.write(char);
        sb.write('\n');
        indent++;
        sb.write('  ' * indent);
      } else if (!inQuotes && (char == '}' || char == ']')) {
        sb.write('\n');
        indent = (indent - 1).clamp(0, 100);
        sb.write('  ' * indent);
        sb.write(char);
      } else if (!inQuotes && char == ',') {
        sb.write(char);
        sb.write('\n');
        sb.write('  ' * indent);
        if (i + 1 < str.length && str[i + 1] == ' ') {
          i++; // Skip space after comma
        }
      } else {
        sb.write(char);
      }
    }
    return sb.toString();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _formattedCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textToDisplay = _formattedCode;
    final isJsonPayload = _isJson;

    final bg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Action Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252526) : const Color(0xFFEFEFEF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  isJsonPayload ? 'JSON Payload (${widget.code.length} bytes)' : 'Raw Body (${widget.code.length} bytes)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const Spacer(),
                if (isJsonPayload)
                  InkWell(
                    onTap: () => setState(() => _isFormatted = !_isFormatted),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        _isFormatted ? 'View Raw' : 'Prettify JSON',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C5CE7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _copyToClipboard,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy,
                        size: 13,
                        color: _copied ? Colors.green : (isDark ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied!' : 'Copy',
                        style: TextStyle(
                          fontSize: 11,
                          color: _copied ? Colors.green : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Code Display Area
          Container(
            constraints: const BoxConstraints(maxHeight: 350),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: isJsonPayload && _isFormatted
                    ? _buildJsonRichText(textToDisplay, isDark)
                    : SelectableText(
                        textToDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: isDark ? const Color(0xFFCE9178) : const Color(0xFF000000),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonRichText(String jsonStr, bool isDark) {
    final spans = <TextSpan>[];
    final keyColor = isDark ? const Color(0xFF9CDCFE) : const Color(0xFF0451A5);
    final stringColor = isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515);
    final numberColor = isDark ? const Color(0xFFB5CEA8) : const Color(0xFF098658);
    final boolColor = isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF);
    final nullColor = isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF);
    final punctuationColor = isDark ? const Color(0xFFD4D4D4) : const Color(0xFF333333);

    final regex = RegExp(
      r'("(?:\\.|[^"\\])*")(?=\s*:)|("(?:\\.|[^"\\])*")|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|(true|false)|(null)|([{}[\]:,])',
      multiLine: true,
    );

    int lastMatchEnd = 0;

    for (final match in regex.allMatches(jsonStr)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: jsonStr.substring(lastMatchEnd, match.start),
          style: TextStyle(color: punctuationColor),
        ));
      }

      if (match.group(1) != null) {
        // Key
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(color: keyColor, fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        // String Value
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(color: stringColor),
        ));
      } else if (match.group(3) != null) {
        // Number
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(color: numberColor),
        ));
      } else if (match.group(4) != null) {
        // Boolean
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(color: boolColor, fontWeight: FontWeight.bold),
        ));
      } else if (match.group(5) != null) {
        // Null
        spans.add(TextSpan(
          text: match.group(5),
          style: TextStyle(color: nullColor, fontStyle: FontStyle.italic),
        ));
      } else if (match.group(6) != null) {
        // Punctuation
        spans.add(TextSpan(
          text: match.group(6),
          style: TextStyle(color: punctuationColor),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < jsonStr.length) {
      spans.add(TextSpan(
        text: jsonStr.substring(lastMatchEnd),
        style: TextStyle(color: punctuationColor),
      ));
    }

    return SelectableText.rich(
      TextSpan(
        children: spans,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          height: 1.4,
        ),
      ),
    );
  }
}

class _QueryConsole extends StatefulWidget {
  final bool isDark;
  final Color borderColor;

  const _QueryConsole({required this.isDark, required this.borderColor});

  @override
  State<_QueryConsole> createState() => _QueryConsoleState();
}

class _QueryConsoleState extends State<_QueryConsole> {
  final TextEditingController _controller = TextEditingController();
  String _queryResult = 'Ready to execute query...';
  bool _isExecuting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _executeQuery() {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isExecuting = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _queryResult = '''
+----+---------------------+-------+----------+
| #  | timestamp           | method| status   |
+----+---------------------+-------+----------+
| 1  | 2024-01-15 10:30:00 | GET   | 200      |
| 2  | 2024-01-15 10:30:05 | POST  | 201      |
| 3  | 2024-01-15 10:30:12 | GET   | 200      |
+----+---------------------+-------+----------+

3 rows in set (0.045s)''';
        _isExecuting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: widget.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.code, size: 14, color: widget.isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 8),
                      const Text('SQL Query', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'SELECT * FROM http_calls WHERE status = 200',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: widget.isDark ? Colors.greenAccent : Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _isExecuting ? null : _executeQuery,
              icon: _isExecuting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow, size: 18),
              label: Text(_isExecuting ? 'Executing...' : 'Execute Query'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: widget.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF252525) : const Color(0xFFF8F8F8),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.terminal, size: 14, color: widget.isDark ? Colors.white70 : Colors.black54),
                        const SizedBox(width: 8),
                        const Text('Results', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _queryResult,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: widget.isDark ? Colors.greenAccent : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
