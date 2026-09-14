function [X, normInfo] = normalise_segments(Xraw, dataset, cfg)
%NORMALISE_SEGMENTS  Min-max normalisation to [0, 1] of every segment.
%   Uses fixed instrument ranges (cfg.ranges) when given, otherwise the
%   full-record minimum and maximum. The constants are returned in normInfo
%   so that Stage B can apply exactly the same transformation.
    raw = table2array(dataset(:, cfg.select_sensors));
    if strcmp(cfg.norm.mode,'range') && ~isempty(cfg.ranges)
        xmin = cfg.ranges(:,1)'; xmax = cfg.ranges(:,2)'; fitted = 'fixed instrument ranges';
    else
        xmin = min(raw,[],1); xmax = max(raw,[],1);          fitted = 'full-record min-max';
    end
    normfun = @(M) (M - xmin) ./ max(xmax - xmin, eps);
    X = cellfun(@(s) normfun(s')', Xraw, 'UniformOutput', false);
    normInfo.mode = cfg.norm.mode; normInfo.fitted_on = fitted;
    normInfo.xmin = xmin; normInfo.xmax = xmax;
end
