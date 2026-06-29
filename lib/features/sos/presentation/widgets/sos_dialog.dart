import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../config/di/injection.dart';
import '../bloc/sos_bloc.dart';

class SosDialog extends StatefulWidget {
  const SosDialog({super.key});
  static Future<void> show(BuildContext context) => showDialog(
    context: context, barrierDismissible: false,
    builder: (_) => const SosDialog(),
  );
  @override State<SosDialog> createState() => _SosDialogState();
}

class _SosDialogState extends State<SosDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SosBloc>(
      create: (_) => getIt<SosBloc>(),
      child: Builder(
        builder: (context) {
          return BlocListener<SosBloc, SosState>(
            listener: (context, state) {
              if (state is SosInitial) {
                Navigator.of(context).pop();
              }
            },
            child: BlocBuilder<SosBloc, SosState>(
              builder: (context, state) {
                final isIdle = state is SosInitial;
                final isActive = state is SosActive;
                final isStopping = state is SosStopping;
                
                String message = '';
                if (state is SosActive) {
                  message = state.message;
                }

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                  child: Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Emergency SOS', style: AppTextStyles.h4),
                      SizedBox(height: 8.h),
                      Text(
                        isIdle
                            ? 'Press the SOS button to alert your team and management immediately.'
                            : 'SOS is ACTIVE. Your location is being shared with your team.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 28.h),
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, child) {
                          final scale = isActive ? 1.0 + _pulse.value * 0.1 : 1.0;
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: GestureDetector(
                          onTap: isIdle
                              ? () => context.read<SosBloc>().add(const StartSosEvent(lat: 0.0, lng: 0.0))
                              : null,
                          child: Container(
                            width: 120.w, height: 120.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isIdle
                                  ? AppColors.error
                                  : AppColors.error.withValues(alpha: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withValues(alpha: isActive ? 0.5 : 0.2),
                                  blurRadius: isActive ? 32 : 16,
                                  spreadRadius: isActive ? 8 : 0,
                                ),
                              ],
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.sos_outlined, size: 40.sp, color: Colors.white),
                              SizedBox(height: 4.h),
                              Text('SOS', style: AppTextStyles.button.copyWith(fontSize: 14.sp, color: Colors.white, letterSpacing: 2)),
                            ]),
                          ),
                        ),
                      ),
                      if (message.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(message, style: AppTextStyles.labelSmall.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                        ),
                      ],
                      SizedBox(height: 24.h),
                      if (isActive)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                            onPressed: () => context.read<SosBloc>().add(const StopSosEvent()),
                            child: const Text('I\'m Safe — Stop SOS'),
                          ),
                        ),
                      if (isStopping || state is SosLoading)
                        const CircularProgressIndicator(),
                      SizedBox(height: isIdle ? 0 : 8.h),
                      TextButton(
                        onPressed: isIdle ? () => Navigator.pop(context) : null,
                        child: Text('Cancel', style: AppTextStyles.labelMedium.copyWith(
                            color: isIdle ? AppColors.textSecondary : AppColors.textHint)),
                      ),
                    ]),
                  ),
                );
              },
            ),
          );
        }
      ),
    );
  }
}
