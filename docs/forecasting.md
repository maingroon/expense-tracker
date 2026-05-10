# Forecasting Module — Developer Guide

## Architecture

```
Transactions table  ──▶  AggregationService  ──▶  FeatureBuilder  ──▶  ForecastingService
                                                                              │
                                                                              ▼
                                                                     ForecastRepository
                                                                              │
                                                                              ▼
                                                                         Forecast UI
```

### Component responsibilities

| Component | File | Role |
|-----------|------|------|
| `AggregationService` | `lib/services/aggregation_service.dart` | Read-only SQL aggregation over the existing `transactions` table. Provides daily totals, per-category breakdowns, and running balance series. |
| `FeatureBuilder` | `lib/services/feature_builder.dart` | Transforms a window of `DailyAggregate` history into a fixed-length `List<double>` for model inference. **Stub** — throws `UnimplementedError` until the offline pipeline exports a model. |
| `ForecastingService` | `lib/services/forecasting_service.dart` | Abstract interface. `NaiveForecastingService` is the current implementation (last-30-day average); replace with an ML-backed class when ready. |
| `ForecastRepository` | `lib/services/forecast_repository.dart` | SQLite persistence for `Forecast` objects and active model metadata. |
| Forecast UI | `lib/screens/forecast/` | Three widgets (`ForecastChart`, `ForecastSummaryCard`, `CategoryForecastTile`) plus `ForecastScreen`. |

---

## Dropping a new model artefact

1. Copy the trained file (JSON or ONNX) into `assets/models/`.
2. Register it at runtime:

```dart
final repo = context.read<ForecastRepository>();
await repo.setActiveModel(ModelMetadata(
  name: 'my_model',
  version: '2.0.0',
  trainedAt: DateTime.now(),
  artefactPath: 'assets/models/my_model_v2.onnx',
  isActive: true,
));
```

3. Implement `FeatureBuilder.build` using the exported `feature_config.json`.
4. Replace `NaiveForecastingService` in the `ProxyProvider2` in `main.dart` with your
   ML-backed implementation of `ForecastingService`.

---

## Forecast contract

See `lib/models/forecast_model.dart` for the full type definitions.

- **`ForecastTarget`** — `expenseTotal`, `balance`, or `expenseByCategory`.
- **`ForecastPoint.predictedCents`** — signed for balance; non-negative magnitude for expense.
- **`ForecastPoint.lowerCents` / `upperCents`** — 80% confidence interval, nullable.
- **`Forecast.horizonDays`** — must be 7, 14, or 30.

---

## Golden-test contract

The file `assets/test/golden_forecasts.json` is populated by the offline training
pipeline. Each entry has this shape:

```json
{
  "case_id": "case_001",
  "as_of": "2026-04-01T00:00:00Z",
  "history": [
    {"date": "2026-03-01", "income_cents": 0, "expense_cents": 4500, "net_cents": -4500}
  ],
  "feature_config_version": "v1",
  "expected_features": [0.12, -1.5],
  "expected_prediction_cents": 4720,
  "expected_lower_cents": 3500,
  "expected_upper_cents": 5900
}
```

`test/services/golden_test.dart` loads this file and asserts feature vectors and
predictions match within tolerance (1e-4 for features, 1 cent for predictions).
The test passes trivially while the file is empty.
