import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../services/hotel_service.dart';

class AgentCalendarView extends StatefulWidget {
  final RoomModel room;
  final Map<String, dynamic> propertyData;

  const AgentCalendarView({
    super.key,
    required this.room,
    required this.propertyData,
  });

  @override
  State<AgentCalendarView> createState() => _AgentCalendarViewState();
}

class _AgentCalendarViewState extends State<AgentCalendarView> {
  final HotelService _hotelService = HotelService();

  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  // Map from 'yyyy-MM-dd' → entry map (includes 'status', 'uuid', 'metadata')
  Map<String, Map<String, dynamic>> _calendarEntries = {};
  bool _isLoading = false;

  // For range selection
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  static const List<String> _blockReasons = [
    'Maintenance',
    'Personal Use',
    'Offline Bookings',
  ];
  String _selectedReason = 'Maintenance';

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadCalendar() async {
    final roomId = widget.room.id;
    if (roomId == null) return;
    setState(() => _isLoading = true);

    final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    try {
      final response = await _hotelService.getAgentCalendar(
        roomId: roomId,
        startDate: _fmt(startOfMonth),
        endDate: _fmt(endOfMonth),
      );
      if (response.success && response.data != null && mounted) {
        final map = <String, Map<String, dynamic>>{};
        for (final entry in response.data!) {
          final date = entry['date'] as String?;
          if (date != null) map[date] = entry;
        }
        setState(() => _calendarEntries = map);
      }
    } catch (_) {
      // Non-critical — show empty calendar
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _dayColor(String dateKey) {
    final entry = _calendarEntries[dateKey];
    if (entry == null) return Colors.transparent;
    final status = entry['status'] as String?;
    if (status == 'blocked') return const Color(0xFFFFE0B2);
    if (status == 'booked') return const Color(0xFFFFCDD2);
    return Colors.transparent;
  }

  Color _dayTextColor(String dateKey) {
    final entry = _calendarEntries[dateKey];
    if (entry == null) return Colors.black;
    final status = entry['status'] as String?;
    if (status == 'blocked') return const Color(0xFFE65100);
    if (status == 'booked') return const Color(0xFFC62828);
    return Colors.black;
  }

  bool _isInRange(DateTime d) {
    if (_rangeStart == null) return false;
    if (_rangeEnd == null) return d == _rangeStart;
    return !d.isBefore(_rangeStart!) && !d.isAfter(_rangeEnd!);
  }

  void _onDayTap(DateTime date) {
    final dateKey = _fmt(date);
    final entry = _calendarEntries[dateKey];
    final status = entry?['status'] as String?;

    if (status == 'blocked') {
      // Log the full entry so we can see what keys the backend returns
      debugPrint('📅 [Calendar] Blocked entry for $dateKey: $entry');
      final metadata = entry?['metadata'];
      final metaMap = metadata is Map ? metadata : null;
      final uuid = metaMap?['uuid']?.toString() ??
          entry?['uuid']?.toString() ??
          entry?['block_uuid']?.toString() ??
          entry?['block_id']?.toString() ??
          entry?['id']?.toString();
      debugPrint('📅 [Calendar] Resolved uuid: $uuid');
      _showUnblockDialog(dateKey, uuid);
      return;
    }

    if (status == 'booked') return; // Can't act on booked dates

    // Range selection
    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = date;
        _rangeEnd = null;
      } else {
        if (date.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = date;
        } else {
          _rangeEnd = date;
        }
        // Show block sheet
        _showBlockSheet();
      }
    });
  }

  void _showBlockSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Block Dates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                'From ${_fmt(_rangeStart!)} to ${_fmt(_rangeEnd ?? _rangeStart!)}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 16),
              const Text('Reason', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _blockReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setSheetState(() => _selectedReason = v);
                    setState(() => _selectedReason = v);
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF426DC2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _blockDates();
                  },
                  child: const Text('Block Dates', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
      });
    });
  }

  Future<void> _blockDates() async {
    final roomId = widget.room.id;
    if (roomId == null || _rangeStart == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await _hotelService.blockRoomDates(
        roomId: roomId,
        startDate: _fmt(_rangeStart!),
        endDate: _fmt(_rangeEnd ?? _rangeStart!),
        reason: _selectedReason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.success ? 'Dates blocked successfully' : (response.message ?? 'Failed to block dates')),
          backgroundColor: response.success ? const Color(0xFF10B981) : Colors.red,
        ));
        if (response.success) _loadCalendar();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to block dates'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUnblockDialog(String dateKey, String? uuid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock Date'),
        content: uuid == null
            ? Text('Unable to unblock $dateKey — no block ID found. Please contact support.')
            : Text('Do you want to unblock $dateKey?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          if (uuid != null)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _unblockDates(uuid);
              },
              child: const Text('Unblock', style: TextStyle(color: Color(0xFF426DC2))),
            ),
        ],
      ),
    );
  }

  Future<void> _unblockDates(String uuid) async {
    setState(() => _isLoading = true);
    try {
      final response = await _hotelService.unblockDates(uuid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.success ? 'Dates unblocked' : (response.message ?? 'Failed to unblock')),
          backgroundColor: response.success ? const Color(0xFF10B981) : Colors.red,
        ));
        if (response.success) _loadCalendar();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to unblock dates'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday; // 1=Mon … 7=Sun

    List<Widget> cells = [];

    // Empty padding for days before month start
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final dateKey = _fmt(date);
      final inRange = _isInRange(date);
      final bg = inRange ? const Color(0xFFBBDEFB) : _dayColor(dateKey);
      final textColor = inRange ? const Color(0xFF0D47A1) : _dayTextColor(dateKey);
      final entry = _calendarEntries[dateKey];
      final status = entry?['status'] as String?;
      final isBooked = status == 'booked';

      cells.add(
        GestureDetector(
          onTap: isBooked ? null : () => _onDayTap(date),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isBooked ? Colors.grey.shade400 : textColor,
                  decoration: isBooked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: cells,
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthName = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][_currentMonth.month];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Calendar', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
            Text(widget.room.name, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
          ],
        ),
      ),
      body: _isLoading && _calendarEntries.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Legend
                  Row(
                    children: [
                      _legendDot(const Color(0xFFFFE0B2), 'Blocked'),
                      const SizedBox(width: 16),
                      _legendDot(const Color(0xFFFFCDD2), 'Booked'),
                      const SizedBox(width: 16),
                      _legendDot(const Color(0xFFBBDEFB), 'Selected'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Month navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                          });
                          _loadCalendar();
                        },
                      ),
                      Text(
                        '$monthName ${_currentMonth.year}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                          });
                          _loadCalendar();
                        },
                      ),
                    ],
                  ),

                  // Day headers
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map((d) => Center(
                              child: Text(d, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),

                  _buildCalendar(),

                  const SizedBox(height: 20),
                  const Text(
                    'Tap an available date to start selecting a range. Tap a blocked date to unblock it.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),

                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator(color: Color(0xFF426DC2))),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
      ],
    );
  }
}
