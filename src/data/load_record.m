function dataset = load_record(file, cfg)
%LOAD_RECORD  Read the boiler record and return a table with standard column names.
%   dataset = LOAD_RECORD(file, cfg)
%   file : data/rawdata.csv (first column = clock time, then the nine process
%          variables in the order of cfg.baseNames), or a .mat file holding a
%          table 'dataset' that already uses those names.
%   The returned table has a 'DateTime' column followed by the nine variables
%   named as in cfg.baseNames, one row per sample. The sampling interval is
%   checked against cfg.sample_period_s.
    [~, ~, ext] = fileparts(file);
    if strcmpi(ext, '.mat')
        S = load(file, 'dataset'); dataset = S.dataset;
    else
        T = readtable(file, 'VariableNamingRule','preserve', 'Encoding','UTF-8');
        if width(T) < 1 + numel(cfg.baseNames)
            error('load_record:columns', '%s has %d columns; expected a time column followed by %d variables.', ...
                  file, width(T), numel(cfg.baseNames));
        end
        dataset = T(:, 1:1+numel(cfg.baseNames));
        dataset.Properties.VariableNames = [{'DateTime'}, cfg.baseNames];
        dataset.Properties.VariableDescriptions = [{'clock time'}, cfg.baseLabels];
    end
    if any(ismissing(dataset(:, cfg.baseNames)), 'all')
        error('load_record:missing', 'The record contains missing values; clean it before running the pipeline.');
    end
    % sampling-interval check (only when the time column is a duration or datetime)
    t = dataset.DateTime;
    if isduration(t) || isdatetime(t)
        dt = seconds(diff(t));
        if any(abs(dt - cfg.sample_period_s) > 1e-6)
            warning('load_record:interval', 'Sampling interval is not a constant %g s (min %g, max %g).', ...
                    cfg.sample_period_s, min(dt), max(dt));
        end
    end
    fprintf('Record: %d samples x %d variables from %s\n', height(dataset), numel(cfg.baseNames), file);
end
