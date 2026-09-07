import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StepState { done, current, pending }

/// The horizontal circle-and-connector stepper used for the payment
/// verification lifecycle (`design_spec.md` §2, pattern 3: "Paid to the fund
/// → Matched to statement → In the ledger") and similar short processes. A
/// filled circle with a checkmark means done, a ringed circle with a center
/// dot means current, and a plain ring means pending.
class ProcessStepper extends StatelessWidget {
  const ProcessStepper({super.key, required this.steps});

  final List<({String labelEn, String labelNe, StepState state})> steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: steps[i].state == StepState.pending
                              ? colors.divider
                              : colors.accentDark3,
                        ),
                      )
                    else
                      const Spacer(),
                    _StepCircle(state: steps[i].state),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: steps[i].state == StepState.done
                              ? colors.accentDark3
                              : colors.divider,
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  steps[i].labelEn,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: steps[i].state == StepState.current
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: steps[i].state == StepState.pending
                        ? colors.textQuaternary
                        : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.state});

  final StepState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return switch (state) {
      StepState.done => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
        child: Icon(Icons.check, size: 14, color: colors.bg),
      ),
      StepState.current => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.accent, width: 2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
          ),
        ),
      ),
      StepState.pending => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.divider, width: 2),
        ),
      ),
    };
  }
}
