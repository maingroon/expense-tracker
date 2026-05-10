import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/models/forecast_insight.dart';
import 'package:expense_tracker/models/forecast_model.dart';
import 'package:expense_tracker/models/forecast_request_model.dart';
import 'package:expense_tracker/screens/forecast/widgets/category_forecast_tile.dart';
import 'package:expense_tracker/screens/forecast/widgets/forecast_chart.dart';
import 'package:expense_tracker/screens/forecast/widgets/forecast_summary_card.dart';
import 'package:expense_tracker/screens/forecast/widgets/insights_panel.dart';
import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/forecast_insights.dart';
import 'package:expense_tracker/services/forecast_repository.dart';
import 'package:expense_tracker/services/forecasting_exceptions.dart';
import 'package:expense_tracker/services/forecasting_service.dart';
import 'package:expense_tracker/services/settings_service.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _ScreenState { loading, insufficientHistory, error, loaded }

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  int _horizonDays = 30;
  _ScreenState _state = _ScreenState.loading;
  Forecast? _balanceForecast;
  List<({Category category, Forecast forecast})> _categoryForecasts = [];
  Map<String, int> _baselinesByCatId = const {};
  List<ForecastInsight> _insights = const [];
  Object? _error;
  int _availableDays = 0;
  int _requiredDays = 1;

  @override
  void initState() {
    super.initState();
    _horizonDays = SettingsService.getForecastHorizonDays();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadForecasts());
  }

  Future<void> _loadForecasts() async {
    if (!mounted) return;
    setState(() => _state = _ScreenState.loading);

    final service = context.read<ForecastingService>();
    final aggregation = context.read<AggregationService>();

    try {
      final hasHistory = await service.hasEnoughHistory;
      if (!mounted) return;

      if (!hasHistory) {
        final avail = await service.availableHistoryDays;
        if (!mounted) return;
        setState(() {
          _state = _ScreenState.insufficientHistory;
          _availableDays = avail;
          _requiredDays = 1;
        });
        return;
      }

      final asOf = DateTime.now();

      final balanceForecast = await service.forecast(
        ForecastRequest(
          target: ForecastTarget.balance,
          horizonDays: _horizonDays,
          asOf: asOf,
        ),
      );
      if (!mounted) return;

      final topCatIds = _topExpenseCategoryIds(5);
      final catForecasts = <({Category category, Forecast forecast})>[];

      for (final catId in topCatIds) {
        final cat = CategoriesService.getCategoryById(catId);
        if (cat == null) continue;
        try {
          final f = await service.forecast(
            ForecastRequest(
              target: ForecastTarget.expenseByCategory,
              categoryId: catId,
              horizonDays: _horizonDays,
              asOf: asOf,
            ),
          );
          catForecasts.add((category: cat, forecast: f));
        } catch (_) {
          // Skip categories with no history.
        }
        if (!mounted) return;
      }

      final asOfMidnight = DateTime(asOf.year, asOf.month, asOf.day);
      final baselineFrom = asOfMidnight.subtract(const Duration(days: 30));
      final baselineTo = asOfMidnight.subtract(const Duration(days: 1));
      final baselines = await categoryBaselines(
        aggregation: aggregation,
        categoryIds: catForecasts.map((c) => c.category.id).toList(),
        from: baselineFrom,
        to: baselineTo,
      );
      if (!mounted) return;

      final insights = await buildInsights(
        balanceForecast: balanceForecast,
        categoryForecasts: catForecasts,
        aggregation: aggregation,
        asOf: asOf,
      );
      if (!mounted) return;

      setState(() {
        _state = _ScreenState.loaded;
        _balanceForecast = balanceForecast;
        _categoryForecasts = catForecasts;
        _baselinesByCatId = baselines;
        _insights = insights;
      });
    } on InsufficientHistoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.insufficientHistory;
        _availableDays = e.availableDays;
        _requiredDays = e.requiredDays;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScreenState.error;
        _error = e;
      });
    }
  }

  List<String> _topExpenseCategoryIds(int n) {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));
    final sums = TransactionsService.getSortedCategoriesSum(from, now);
    final expenses = sums.where((entry) {
      final cat = CategoriesService.getCategoryById(entry.key);
      return cat != null && cat.type == CategoryType.expense;
    }).toList()
      ..sort((a, b) => a.value.abs().compareTo(b.value.abs()) * -1);
    return expenses.take(n).map((e) => e.key).toList();
  }

  Future<void> _onHorizonChanged(int horizon) async {
    _horizonDays = horizon;
    await SettingsService.setForecastHorizonDays(horizon);
    await _loadForecasts();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure ForecastRepository is resolved (satisfies Provider wiring requirement).
    context.read<ForecastRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Forecast')),
      body: RefreshIndicator(
        onRefresh: _loadForecasts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(child: _buildHorizonSelector()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _buildBody()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizonSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7d')),
        ButtonSegment(value: 14, label: Text('14d')),
        ButtonSegment(value: 30, label: Text('30d')),
      ],
      selected: {_horizonDays},
      onSelectionChanged: (set) => _onHorizonChanged(set.first),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _ScreenState.loading => _buildLoadingState(),
      _ScreenState.insufficientHistory => _buildInsufficientHistoryState(),
      _ScreenState.error => _buildErrorState(),
      _ScreenState.loaded => _buildLoadedState(),
    };
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _ShimmerBox(height: 100),
        const SizedBox(height: 16),
        _ShimmerBox(height: 220),
        const SizedBox(height: 16),
        _ShimmerBox(height: 56),
        const SizedBox(height: 8),
        _ShimmerBox(height: 56),
      ],
    );
  }

  Widget _buildInsufficientHistoryState() {
    final daysNeeded = _requiredDays - _availableDays;
    final String message;
    if (_availableDays == 0) {
      message = 'Add your first transaction to unlock forecasts.';
    } else if (daysNeeded > 0) {
      message = 'Keep logging for $daysNeeded more '
          'day${daysNeeded == 1 ? '' : 's'} to unlock forecasts.';
    } else {
      message = 'Keep logging a little longer to unlock forecasts.';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Not enough history',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error?.toString() ?? '',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _loadForecasts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState() {
    final forecast = _balanceForecast;
    if (forecast == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        ForecastSummaryCard(forecast: forecast),
        const SizedBox(height: 16),
        ForecastChart(forecast: forecast),
        if (_insights.isNotEmpty) ...[
          const SizedBox(height: 16),
          InsightsPanel(insights: _insights),
        ],
        if (_categoryForecasts.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Top expense categories',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._categoryForecasts.map(
            (item) => CategoryForecastTile(
              category: item.category,
              forecast: item.forecast,
              baselineCents: _baselinesByCatId[item.category.id],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.height});
  final double height;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
