# dtwsom-boiler-regimes

Unsupervised discovery of operating regimes in an industrial natural-gas boiler using a
Dynamic-Time-Warping self-organizing map (DTW-SOM), with labels exported for a downstream
LSTM regime classifier.

The code accompanies the manuscript *[title, journal, year — to be added on acceptance]*.

## What the method does

1. **Segmentation.** Nine process variables sampled every 5 s are cut into non-overlapping
   5-min segments (60 samples × 9 channels).
2. **Normalisation.** Each channel is min–max scaled to [0, 1], either by fixed instrument
   ranges (recommended, leakage-free) or by the full record (descriptive fallback).
3. **DTW-SOM training.** A 30-node map is trained with classic DTW as the distance
   (independent per-channel DTW summed over channels). Prototypes are updated along the
   optimal warping path, so they remain time-aligned averages of the segments they represent.
   All DTW computations are vectorised (`dtw_batch`, `align_batch`) — no per-call overhead.
4. **Regime-count selection.** Prototypes that are the best-matching unit of at least one
   segment are clustered hierarchically (average linkage on the DTW matrix). A candidate table
   over K = 2…9 reports node- and segment-level silhouette, Davies–Bouldin, effective K,
   temporal-episode counts and minimum cluster size. The reported partition is the
   best-separated one among populated, temporally compact partitions finer than the trivial
   idle/firing split (`silhouette_constrained`); alternative rules (`twolevel`, `contiguity`,
   `silhouette`, `fixed`) are provided for comparison.
5. **Validation.** Quantisation and topographic error, baselines under the same segments
   (Euclidean SOM, DTW hierarchical clustering, DTW k-medoids), multi-seed stability (ARI),
   and training/inference timing are computed and saved.
6. **Export for classification.** Sample-level regime labels and a leakage-resistant
   train/val/test partition (assigned in time order *within each regime episode*, with purge
   gaps) are written for the LSTM stage.

## Repository layout

```
final_code_r8.m          main script: segmentation → DTW-SOM → regime selection → validation → figures
README.md
LICENSE
```

The script is self-contained; all helper functions are local functions at the end of the file.

## Requirements

- MATLAB R2021b or later
- Statistics and Machine Learning Toolbox (`linkage`, `cluster`, `silhouette`, `crosstab`)
- Signal Processing Toolbox (`dtw`, used only for the alignment illustration figure)

No Parallel Computing Toolbox or GPU is needed. A full run (500 epochs, baselines, 5-seed
stability) takes roughly 20–40 min on a laptop CPU; the 5-min segment inference time is a few
milliseconds.

## Data

The DCS record used in the paper (`refined_dataset.mat`) is proprietary and not distributed.
The script expects a MATLAB table named `dataset` with, in columns 4–12:

| Column | Variable | Unit |
|---|---|---|
| 4 | Inlet gas pressure | bar |
| 5 | Inlet gas temperature | °C |
| 6 | Inlet gas flow | m³/h |
| 7 | Feed-water temperature | °C |
| 8 | Steam pressure | bar |
| 9 | Steam temperature | °C |
| 10 | Steam flow | m³/h |
| 11 | Exhaust-gas O₂ | % |
| 12 | Exhaust-gas temperature | °C |

Rows are consecutive samples at a fixed interval (`cfg.sample_period_s`). Any multivariate
time series with the same table structure can be used by adjusting `cfg.select_sensors`.

## Usage

```matlab
% 1. place refined_dataset.mat (or your own table) in the working directory
% 2. edit the configuration block at the top of final_code_r8.m:
%      cfg.somSize, cfg.segment_size, cfg.ranges (instrument ranges), cfg.Kselect
% 3. run
final_code_r8
```

### Key configuration

| Field | Default | Meaning |
|---|---|---|
| `cfg.segment_size` / `cfg.stride` | 60 / 60 | 5-min non-overlapping segments at 5-s sampling |
| `cfg.somSize` | `[5 6]` | SOM grid (30 nodes) |
| `cfg.numEpochs` | 500 | fixed budget; check the convergence figure |
| `cfg.dtw.band` | 0 | Sakoe–Chiba band as fraction of segment length (0 = unconstrained) |
| `cfg.norm.mode`, `cfg.ranges` | `'range'`, `[]` | fixed-range normalisation; falls back to full-record min–max if empty |
| `cfg.Kselect` | `'silhouette_constrained'` | regime-count rule (see above) |
| `cfg.Kmin`, `cfg.minSegPerCluster`, `cfg.maxEpisodesPerCluster` | 4, 2, 3 | constraints for the selection rule |
| `cfg.lstm.window`, `cfg.lstm.frac`, `cfg.lstm.purge` | 12, [0.6 0.2 0.2], 12 | partition exported for the LSTM stage |
| `cfg.runBaselines`, `cfg.runStability` | true, true | optional validation blocks |

## Outputs

| File | Content |
|---|---|
| `dtwsom_model_r6.mat` | prototypes, snapshot, configuration, training log |
| `results_report_r6.mat` | quality metrics, K table, episodes, timing, environment, stability |
| `episodes_r6.xlsx` | regime episodes in time order (cluster, start/end, length) |
| `labeldataset_r6.xlsx` | sample-level regime label and train/val/test/gap assignment |
| `segments_r6.xlsx` | per-segment BMU, cluster, quantisation error |
| `lstm_window_counts_r6.xlsx` | 1-min windows per class and split available to the classifier |
| `baseline_comparison_r6.xlsx` | silhouette and ARI of baselines vs DTW-SOM |
| `fig4_overview_r6.svg` and on-screen figures | convergence, dendrogram, K diagnostics, SOM grid, overview, prototypes per regime, DTW alignment |

## Reproducibility

Random seeds are fixed (`cfg.seed`; stability seeds in `cfg.stabilitySeeds`). The report file
stores MATLAB version, CPU and core count together with wall-clock training time and
per-segment inference time.

## Citation

```
@article{dtwsom_boiler,
  author  = {Nimmanterdwong, Prathana and ...},
  title   = {...},
  journal = {...},
  year    = {2026},
  doi     = {...}
}
```

## License

MIT (see `LICENSE`).

## Contact

Prathana Nimmanterdwong — Department of Chemical Technology, Faculty of Science,
Chulalongkorn University, Bangkok, Thailand.
