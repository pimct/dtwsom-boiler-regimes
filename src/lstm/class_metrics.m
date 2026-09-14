function [acc, P, R, F1, macroF1, balAcc, mcc] = class_metrics(cm)
%CLASS_METRICS  Accuracy, per-class precision / recall / F1, macro-F1, balanced
%   accuracy and Matthews correlation from a confusion matrix (rows = true).
%   Precision is NaN for a class that is never predicted.
    n = sum(cm(:));  acc = sum(diag(cm))/n;
    tp = diag(cm)';  fp = sum(cm,1)-tp;  fn = sum(cm,2)'-tp;
    P = tp./max(tp+fp,eps);  R = tp./max(tp+fn,eps);
    F1 = 2*P.*R./max(P+R,eps);
    P(tp+fp==0) = NaN;
    macroF1 = mean(F1,'omitnan');
    balAcc  = mean(R(sum(cm,2)'>0),'omitnan');
    t = sum(cm,2)';  p = sum(cm,1);  c = sum(diag(cm));
    num = c*n - sum(t.*p);
    den = sqrt(max(n^2-sum(p.^2),0)) * sqrt(max(n^2-sum(t.^2),0));
    mcc = num/max(den,eps);
end
