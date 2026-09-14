# Unsupervised classification of industrial boiler operation signals using a DTW-SOM and LSTM framework

MATLAB code and data for

> P. Nimmanterdwong, B. Chalermsinsuwan, R. Piemjaiswang, S. Khaisri, C. Takhonram, W. Chaiwat,
> *Unsupervised classification of industrial boiler operation signals using Dynamic Time Warping
> Self-Organizing Map (DTW-SOM) and Long Short-Term Memory (LSTM) framework*, under review (2026).

The record is a 6-h DCS export from a natural-gas-fired industrial boiler (nine process
variables, 5-s sampling, 4281 samples), included in `data/`.

## What the code does

**Stage A – unsupervised regime discovery.** Non-overlapping 5-min segments are clustered with a
self-organising map whose distance is dynamic time warping and whose prototype update aligns each
segment along the optimal warping path. The active prototypes are grouped by average-linkage
hierarchical clustering; the number of operating regimes is selected from silhouette and
Davies–Bouldin diagnostics under a temporal-compactness constraint. The result for this record is
seven regimes (cold idle, warm idle, transitions, stable high-load firing, hot standby,
high-load ramp and shutdown). Stage A also exports a per-episode, purge-gapped
train / validation / test partition.

**Stage B – supervised regime classification.** An LSTM is trained on trailing 3-min windows
(1-min for comparison) using the Stage-A labels and partition, so that the regime can be
recognised online from a short window. Four-sensor and nine-sensor models are compared, and
k-NN, random-forest and 1-D-CNN baselines are trained on identical windows.

## Requirements

- MATLAB R2023b or later (`trainnet`, `minibatchpredict`)
- Statistics and Machine Learning Toolbox (`linkage`, `silhouette`, `fitcknn`, `TreeBagger`)
- Deep Learning Toolbox
- Signal Processing Toolbox (`dtw`, Fig. 2 only)

No GPU is needed. Stage A (100-node map, 71 segments of 60 × 9 samples, ~1300 epochs) takes
roughly 1.3 h on a desktop CPU; set `cfg.loadModel = true` afterwards to reuse
`results/dtwsom_model.mat`. Each LSTM trains in a few minutes.

## Running

```matlab
cd <repo>
run scripts/run_stage_a_dtwsom.m        % Figs 2-5, Tables 3, S1, S2, partition export
run scripts/run_stage_b_lstm.m          % nine-sensor model, 3-min windows: Tables 4-6, Fig. 6
run scripts/run_classifier_baselines.m  % Table S3
```

Set `cfgL.useReduced = true` (four-sensor model) or `cfgL.window = 12` (1-min windows) in
`config/lstm_config.m`; `scripts/run_all.m` runs every combination reported in the paper.
All settings are in the two config files, none in the scripts.

## Layout

```
config/    default_config.m   Stage-A settings (values of the reported run)
           lstm_config.m      Stage-B and baseline settings
scripts/   run_stage_a_dtwsom.m, run_stage_b_lstm.m, run_classifier_baselines.m, run_all.m
src/       dtwsom/      train_som, dtw_batch, align_batch, predict_bmu, pair_dist, ...
           clustering/  select_clusters, merge_small_clusters, run_baselines, run_stability, ...
           data/        load_record, prep_segments, normalise_segments, make_partition, build_windows, ...
           lstm/        train_lstm, predict_labels, class_metrics
           plotting/    one function per figure
data/      rawdata.csv and a description of its columns
results/   all outputs (git-ignored)
```

## Outputs and where they appear in the paper

| Paper item | File in `results/` |
|---|---|
| Fig. 2 DTW alignment of a prototype and a segment | `fig02_dtw_alignment.png` |
| Fig. 3 dendrogram of active prototypes with the cut | `fig03_dendrogram.svg/.png` |
| Fig. 4 full record with regime episodes | `fig04_record_regimes.svg/.png` |
| Fig. 5 prototypes and segments per regime | `fig05_Cluster*.svg/.png` |
| Fig. 6 confusion charts | `fig06_confusion_<full|reduced>_w36.png` |
| Table 3 regime episodes | `episodes.xlsx` |
| Table 4 windows per regime and class-wise metrics | `lstm_window_counts_w36.xlsx`, `lstm_classwise_*_w36.xlsx` |
| Tables 5–6 overall metrics, timing, parameter count | console output of `run_stage_b_lstm` and `lstm_results_*.mat` |
| Table S1 cluster-count diagnostics | `tableS1_k_diagnostics.xlsx` |
| Table S2 clustering baselines and seed stability | `tableS2_clustering_baselines.xlsx`, `tableS2_seed_stability.xlsx` |
| Table S3 classifier baselines | `tableS3_classifier_baselines_*_w36.xlsx` |
| Training curve, diagnostics vs K, partition map | `figS1_training_curve.png`, `figS2_k_diagnostics.png`, `figS4_partition.png` |

## Method notes

- **DTW.** Classic unconstrained DTW with absolute local cost and symmetric steps, computed per
  channel and summed over the nine channels (`dtw_batch`). A Sakoe–Chiba band is available via
  `cfg.dtw.band`.
- **Prototype update.** The segment is warped onto the prototype's time axis along the optimal
  path (mean of the segment values mapped to each prototype index) before the SOM update
  (`align_batch`).
- **Schedule and stopping.** Exponential decay of learning rate (0.5 → 0.005) and neighbourhood
  radius (5 → 0.5) over 800 epochs, then constant; training stops when the mean quantisation
  error over 100 epochs changes by less than 1 %.
- **Regime count.** For each cut K of the tree of active prototypes, clusters with fewer than
  three segments are merged into the nearest regime; the reported partition maximises the segment
  silhouette among partitions with at least five regimes, each recurring at most three times.
  Every candidate is written to Table S1.
- **Partition.** Within each regime episode, rows are assigned train → val → test in time order
  (60/20/20) with 12 rows removed at each boundary. Windows are formed only inside one partition,
  so no window of any length straddles two partitions.

## Citation

Please cite the paper above (see `CITATION.cff`). Code and data are released under the MIT licence.

## Funding

Thailand Science Research and Innovation Fund, Mahidol University (FF-130/2568) and Chulalongkorn
University (DIS_FF_69_053_2300_016).
