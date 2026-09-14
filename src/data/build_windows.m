function win = build_windows(dataset, Tlab, cfg, cfgL)
%BUILD_WINDOWS  Trailing windows that respect the Stage-A partition.
%   win = BUILD_WINDOWS(dataset, Tlab, cfg, cfgL)
%   A window ending at row e spans rows e-w+1:e. It is kept only if all its
%   rows carry the same split label and that label is not "gap". Its class is
%   the regime label of its last row (trailing window, zero lag). Used
%   identically by the LSTM stage and the classifier baselines.
%
%   win.Xn, win.cols       normalised record and selected channel indices
%   win.ends               row index of the last sample of every kept window
%   win.split, win.label   partition and class per window
%   win.idxTr/idxVa/idxTe  window indices per partition
%   win.classes, win.K
%   win.seq(ii)            cell array of [w x nChannels] sequences for windows ii
%   win.flat(ii)           one flattened row per window (for k-NN / forest)
%   win.counts             K x 3 table of windows per class and partition
    w = cfgL.window; N = height(dataset);
    lab   = categorical(string(Tlab.ClusterLabeled));
    split = string(Tlab.Split);
    X  = table2array(dataset(:, cfgL.select_sensors));
    Xn = (X - cfg.norm.xmin) ./ max(cfg.norm.xmax - cfg.norm.xmin, eps);
    cols = 1:numel(cfgL.select_sensors);
    if cfgL.useReduced, cols = find(ismember(cfgL.select_sensors, cfgL.reduced_sensors)); end

    ends = (w:N)'; keep = false(size(ends));
    for q = 1:numel(ends)
        s = split(ends(q)-w+1 : ends(q));
        keep(q) = s(1) ~= "gap" && all(s == s(1));
    end
    ends = ends(keep);
    win.w = w; win.N = N; win.Xn = Xn; win.cols = cols; win.ends = ends;
    win.split = split(ends); win.label = lab(ends);
    win.rowLabel = lab; win.rowSplit = split;
    win.classes = categories(lab); win.K = numel(win.classes);
    win.idxTr = find(win.split=="train"); win.idxVa = find(win.split=="val"); win.idxTe = find(win.split=="test");
    win.seq  = @(ii) arrayfun(@(e) Xn(e-w+1:e, cols), ends(ii), 'UniformOutput', false);
    win.flat = @(ii) cell2mat(cellfun(@(a) a(:)', win.seq(ii), 'UniformOutput', false));

    cnt = zeros(win.K,3);
    for k = 1:win.K
        m = win.label == win.classes{k};
        cnt(k,:) = [sum(m & win.split=="train"), sum(m & win.split=="val"), sum(m & win.split=="test")];
    end
    win.counts = array2table(cnt, 'RowNames', win.classes, 'VariableNames', {'Train','Validation','Test'});
end
