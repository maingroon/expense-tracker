Model artefacts dropped here by the offline training pipeline
(`expense-forecasting-research/`).

Three files form the contract; see
`../../docs/forecasting.md` and `../../../end_to_end_implementation_plan.md`
for the full architecture.

| File | Owner |
|---|---|
| `feature_config.json` | feature names, order, normalisation stats |
| `coeffs.json` | trained ridge regressor (intercept + 20 weights, residual std) |
| `../test/golden_forecasts.json` | parity fixtures for `test/services/golden_test.dart` |

## Current build

- **Model:** ridge regression, alpha = 0.1 (best on validation MAE).
- **Trained:** 2026-05-03 on 198 users × ~660 train days from TabFormer (200 sampled users, last 24 months).
- **Window:** 60 days. **Target:** next-day expense in cents.
- **Residual std (population, ddof=0):** ~15 660 cents — drives the Dart service's ±1.28 σ (80 %) confidence bands.

| Horizon | MAE (cents) | RMSE | sMAPE |
|---|---|---|---|
|  7 d |  31 565 |  48 521 | 0.341 |
| 14 d |  50 811 |  69 487 | 0.284 |
| 30 d | 111 111 | 133 435 | 0.300 |

LightGBM was within 5 % MAE on average and was therefore not selected — pure-Dart inference avoids the ONNX runtime / Android NDK setup. See `expense-forecasting-research/reports/results.md` for the full comparison.

## Retraining

```bash
cd ../../../expense-forecasting-research
.venv/bin/python -m src.models.train_all
.venv/bin/python -m src.export.run_all
.venv/bin/pytest tests/test_artefact_parity.py -v
cp artefacts/feature_config.json artefacts/coeffs.json ../expense-tracker/assets/models/
cp artefacts/golden_forecasts.json ../expense-tracker/assets/test/
flutter test test/services/golden_test.dart
```

Bump `model_version` in `coeffs.json` whenever the contract shifts.
