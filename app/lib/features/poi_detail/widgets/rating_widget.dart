import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/repositories/ratings_repository.dart';
import '../../../domain/models/poi_rating.dart';
import '../providers/ratings_provider.dart';

class RatingWidget extends ConsumerStatefulWidget {
  final String poiId;
  final String langCode;

  const RatingWidget({required this.poiId, required this.langCode, super.key});

  @override
  ConsumerState<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends ConsumerState<RatingWidget> {
  int? _selected;
  bool _submitted = false;
  bool _loading = false;
  RatingReason? _reason;

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(myPoiRatingProvider(widget.poiId));
    if (existing.valueOrNull != null) {
      return _AlreadyRatedWidget(rating: existing.value!.rating);
    }

    if (_submitted) {
      return const _ThankYouWidget();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you rate this guide?',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selected = star),
                child: AnimatedScale(
                  scale:
                      _selected != null && _selected! >= star ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    _selected != null && _selected! >= star
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _selected != null && _selected! >= star
                        ? const Color(0xFFB8960C)
                        : Colors.grey[400],
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          if (_selected != null && _selected! <= 2) ...[
            const SizedBox(height: 12),
            Text(
              'What was wrong? (optional)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReasonChip(
                  label: 'Inaccurate',
                  value: RatingReason.inaccurate,
                  selected: _reason,
                  onTap: (r) => setState(() => _reason = r),
                ),
                _ReasonChip(
                  label: 'Too short',
                  value: RatingReason.tooShort,
                  selected: _reason,
                  onTap: (r) => setState(() => _reason = r),
                ),
                _ReasonChip(
                  label: 'Boring',
                  value: RatingReason.boring,
                  selected: _reason,
                  onTap: (r) => setState(() => _reason = r),
                ),
                _ReasonChip(
                  label: 'Wrong language',
                  value: RatingReason.wrongLang,
                  selected: _reason,
                  onTap: (r) => setState(() => _reason = r),
                ),
              ],
            ),
          ],
          if (_selected != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit rating'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _loading = true);

    try {
      await ref.read(ratingsRepositoryProvider).submitRating(
            poiId: widget.poiId,
            rating: _selected!,
            reason: _reason,
            langCode: widget.langCode,
          );

      if (mounted) {
        setState(() {
          _loading = false;
          _submitted = true;
        });
      }
    } catch (e) {
      debugPrint('Rating submission failed: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit rating. Please try again.')),
        );
      }
    }
  }
}

class _ThankYouWidget extends StatelessWidget {
  const _ThankYouWidget();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(
            'Thanks for rating!',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.green),
          ),
        ]),
      );
}

class _AlreadyRatedWidget extends StatelessWidget {
  final int rating;
  const _AlreadyRatedWidget({required this.rating});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          ...List.generate(
            5,
            (i) => Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: const Color(0xFFB8960C),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text('Your rating',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class _ReasonChip extends StatelessWidget {
  final String label;
  final RatingReason value;
  final RatingReason? selected;
  final void Function(RatingReason) onTap;

  const _ReasonChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected == value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected == value
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected == value ? Colors.white : null,
                ),
          ),
        ),
      );
}
