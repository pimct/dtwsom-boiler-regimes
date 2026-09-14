%% Reproduce every table and figure of the paper in order.
%  Stage A once; Stage B and the baselines for the full and reduced sensor
%  sets at the reported 3-min window, then the full model at 1 min (Table 6).
run_stage_a_dtwsom

for useReduced = [false true]
    cfgOverride = struct('useReduced', useReduced, 'window', 36);
    run_with_override('run_stage_b_lstm', cfgOverride);
    run_with_override('run_classifier_baselines', cfgOverride);
end
run_with_override('run_stage_b_lstm', struct('useReduced', false, 'window', 12));

function run_with_override(scriptName, ov)
    % temporarily patches lstm_config with the fields in ov
    global LSTM_CONFIG_OVERRIDE %#ok<GVMIS>
    LSTM_CONFIG_OVERRIDE = ov;
    run(scriptName);
    LSTM_CONFIG_OVERRIDE = [];
end
