function r = summarise_metrics(name, acc, mf, ba, mc)
%SUMMARISE_METRICS  One table row "mean +/- SD" per metric.
    f = @(v) sprintf('%.4f +/- %.4f', mean(v), std(v));
    fprintf('%s: accuracy %s | macro-F1 %s | balanced accuracy %s | MCC %s\n', ...
        name, f(acc), f(mf), f(ba), f(mc));
    r = struct('Method', string(name), 'Accuracy', string(f(acc)), 'MacroF1', string(f(mf)), ...
               'BalancedAccuracy', string(f(ba)), 'MCC', string(f(mc)));
end
