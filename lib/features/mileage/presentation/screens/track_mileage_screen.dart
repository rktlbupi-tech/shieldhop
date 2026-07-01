import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../common/widgets/empty_state.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/mileage_entities.dart';
import '../bloc/mileage_bloc.dart';

class TrackMileageScreen extends StatelessWidget {
  const TrackMileageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return BlocProvider(
      create: (_) => getIt<MileageBloc>()
        ..add(FetchMileageOverview(period: MileagePeriod.monthly, date: today)),
      child: const _TrackMileageView(),
    );
  }
}

class _TrackMileageView extends StatefulWidget {
  const _TrackMileageView();

  @override
  State<_TrackMileageView> createState() => _TrackMileageViewState();
}

class _TrackMileageViewState extends State<_TrackMileageView> {
  DateTime _currentDate = DateTime.now();
  MileagePeriod _period = MileagePeriod.monthly;
  int _selectedTripIndex = 0;

  // Default map centre — the API stores no route geometry, so there's no
  // polyline to draw; this just keeps the map from being blank.
  static const LatLng _defaultCenter = LatLng(51.5074, -0.1278);

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_currentDate);

  void _reload() => context.read<MileageBloc>().add(
    FetchMileageOverview(period: _period, date: _dateStr),
  );

  void _changeDay(bool next) {
    setState(() {
      _currentDate = next
          ? _currentDate.add(const Duration(days: 1))
          : _currentDate.subtract(const Duration(days: 1));
      _selectedTripIndex = 0;
    });
    _reload();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _currentDate = picked;
        _selectedTripIndex = 0;
      });
      _reload();
    }
  }

  // ── formatting helpers ──────────────────────────────────────────────────────
  double _toUnit(double meters, String unit) =>
      unit == 'mi' ? meters / 1609.344 : meters / 1000.0;

  String _distanceStr(double meters, String unit) =>
      '${_toUnit(meters, unit).toStringAsFixed(1)} $unit';

  String _durationStr(int minutes) {
    final m = minutes.abs();
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
  }

  String _money(double amount, String currency) {
    const symbols = {'GBP': '£', 'USD': '\$', 'EUR': '€', 'INR': '₹'};
    final sym = symbols[currency] ?? '$currency ';
    return '$sym${amount.toStringAsFixed(2)}';
  }

  String _clock(DateTime? d) =>
      d == null ? '' : DateFormat('hh:mm a').format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppAppBar(
        title: "Track mileage",
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        showBack: true,
      ),

      body: SafeArea(
        child: BlocConsumer<MileageBloc, MileageState>(
          listenWhen: (p, c) =>
              c is LogMileageSuccess || c is LogMileageFailure,
          listener: (context, state) {
            if (state is LogMileageSuccess) {
              _toast("Mileage logged for today.");
            } else if (state is LogMileageFailure) {
              _toast(state.errorMessage);
            }
          },
          builder: (context, state) {
            if (state is MileageLoading || state is MileageInitial) {
              return const Center(child: LoadingWidget());
            }
            if (state is MileageError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: state.message,
                buttonLabel: 'Retry',
                onButtonTap: _reload,
              );
            }
            final loaded = state is MileageLoaded ? state : null;
            if (loaded == null) {
              return const Center(child: LoadingWidget());
            }
            return _buildContent(size, loaded);
          },
        ),
      ),
    );
  }

  Widget _buildContent(Size size, MileageLoaded loaded) {
    final summary = loaded.summary;
    final trips = loaded.trips;
    final unit = summary?.unit ?? 'km';
    final currency =
        summary?.currency ?? (trips.isNotEmpty ? trips.first.currency : 'GBP');
    final selIndex = trips.isEmpty
        ? 0
        : _selectedTripIndex.clamp(0, trips.length - 1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // Period filter (daily / weekly / monthly / yearly)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: MileagePeriod.values.map((p) {
              final isSelected = _period == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: ChoiceChip(
                  label: Text(
                    p.label,
                    style: TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF6B7280),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFFEFF6FF),
                  backgroundColor: Colors.white,
                  checkmarkColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFDBEAFE)
                          : Colors.grey.shade200,
                    ),
                  ),
                  onSelected: (_) {
                    setState(() {
                      _period = p;
                      _selectedTripIndex = 0;
                    });
                    _reload();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Date selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeDay(false),
            ),
            GestureDetector(
              onTap: _pickDate,
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy, EEEE').format(_currentDate),
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeDay(true),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // KPI cards
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatItem(
                "Total Distance",
                _distanceStr(summary?.totalDistanceMeters ?? 0, unit),
                delta: summary?.distanceDeltaMeters ?? 0,
                deltaText: _distanceStr(
                  (summary?.distanceDeltaMeters ?? 0).abs(),
                  unit,
                ),
                icon: LucideIcons.milestone,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                "Total Trips",
                '${summary?.activeDays ?? 0}',
                delta: (summary?.activeDaysDelta ?? 0).toDouble(),
                deltaText: '${(summary?.activeDaysDelta ?? 0).abs()}',
                icon: LucideIcons.gauge,
                color: Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatItem(
                "Total Duration",
                _durationStr(summary?.totalDurationMinutes ?? 0),
                delta: (summary?.durationDeltaMinutes ?? 0).toDouble(),
                deltaText: _durationStr(summary?.durationDeltaMinutes ?? 0),
                icon: LucideIcons.timer,
                color: Colors.purple,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                "Est. Fuel Cost",
                _money(summary?.estFuelCost ?? 0, currency),
                delta: summary?.estFuelCostDelta ?? 0,
                deltaText: _money(
                  (summary?.estFuelCostDelta ?? 0).abs(),
                  currency,
                ),
                icon: LucideIcons.fuel,
                color: Colors.orange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Map (no route geometry from the API — static, with the day's labels)
        if (trips.isNotEmpty) _buildMap(trips[selIndex]),
        if (trips.isNotEmpty) const SizedBox(height: 16),

        // Trips (one row per day)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Trips",
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "${trips.length} ${trips.length == 1 ? 'day' : 'days'}",
              style: const TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (trips.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            child: Text(
              "No mileage in this period",
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          )
        else
          ...List.generate(trips.length, (index) {
            return _buildTripRow(trips[index], index, unit, selIndex == index);
          }),
        const SizedBox(height: 12),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.shield_check,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Mileage is calculated using GPS data. Ensure location is turned on during trips for accurate tracking.",
                  style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap(MileageTripEntity trip) {
    final title = (trip.startLabel != null && trip.endLabel != null)
        ? '${trip.startLabel} → ${trip.endLabel}'
        : (trip.date != null
              ? DateFormat('dd MMM yyyy').format(trip.date!)
              : 'Selected day');
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 11,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            liteModeEnabled: true,
          ),
          Positioned(
            left: 8,
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripRow(
    MileageTripEntity trip,
    int index,
    String unit,
    bool isSelected,
  ) {
    final title = (trip.startLabel != null && trip.endLabel != null)
        ? '${trip.startLabel} to ${trip.endLabel}'
        : (trip.date != null
              ? DateFormat('EEE, dd MMM yyyy').format(trip.date!)
              : 'Day record');
    final clockLine = (trip.clockInAt != null && trip.clockOutAt != null)
        ? '${_clock(trip.clockInAt)} – ${_clock(trip.clockOutAt)}'
        : (trip.source == 'manual' ? 'Manual entry' : 'GPS');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey.shade100,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedTripIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 12,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clockLine,
                      style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (trip.reimbursementAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Reimbursement ${_money(trip.reimbursementAmount, trip.currency)}',
                        style: const TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _distanceStr(trip.distanceMeters, unit),
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _durationStr(trip.durationMinutes),
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    required double delta,
    required String deltaText,
    required IconData icon,
    required Color color,
  }) {
    final isUp = delta > 0;
    final isFlat = delta == 0;
    final deltaColor = isFlat
        ? const Color(0xFF9CA3AF)
        : (isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444));
    final arrow = isFlat ? '' : (isUp ? '▲ ' : '▼ ');

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$arrow$deltaText ${_period.vsLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                fontSize: 11,
                color: deltaColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'AirbnbCereal')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Log mileage dialog (GPS distance OR manual odometer) ────────────────────
  void _showLogDialog() {
    final bloc = context.read<MileageBloc>();
    final state = bloc.state;
    final unit = state is MileageLoaded ? (state.summary?.unit ?? 'km') : 'km';

    final distanceCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final odoStartCtrl = TextEditingController();
    final odoEndCtrl = TextEditingController();

    InputDecoration dec(String hint) => InputDecoration(
      hintText: hint,
      isDense: true,
      hintStyle: TextStyle(
        fontFamily: 'AirbnbCereal',
        color: Colors.grey.shade400,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log mileage · ${DateFormat('dd MMM').format(_currentDate)}',
          style: const TextStyle(
            fontFamily: 'AirbnbCereal',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distance ($unit)',
                style: const TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: distanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: dec('e.g. 24.6'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: dec('Duration (minutes)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startCtrl,
                decoration: dec('Start label (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endCtrl,
                decoration: dec('End label (optional)'),
              ),
              const Divider(height: 28),
              const Text(
                'Or manual odometer (km)',
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: odoStartCtrl,
                      keyboardType: TextInputType.number,
                      decoration: dec('Start'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: odoEndCtrl,
                      keyboardType: TextInputType.number,
                      decoration: dec('End'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'AirbnbCereal', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final dist = double.tryParse(distanceCtrl.text.trim());
              final odoS = double.tryParse(odoStartCtrl.text.trim());
              final odoE = double.tryParse(odoEndCtrl.text.trim());
              final dur = int.tryParse(durationCtrl.text.trim());

              final hasDistance = dist != null && dist > 0;
              final hasOdo = odoS != null && odoE != null;
              if (!hasDistance && !hasOdo) {
                _toast('Enter a distance or an odometer pair.');
                return;
              }
              if (hasOdo && odoE < odoS) {
                _toast('Odometer end must be ≥ start.');
                return;
              }

              bloc.add(
                LogMileageDay(
                  date: _dateStr,
                  distanceMeters: hasDistance
                      ? dist * (unit == 'mi' ? 1609.344 : 1000.0)
                      : null,
                  odometerStart: hasDistance ? null : odoS,
                  odometerEnd: hasDistance ? null : odoE,
                  durationMinutes: dur,
                  startLabel: startCtrl.text.trim(),
                  endLabel: endCtrl.text.trim(),
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
