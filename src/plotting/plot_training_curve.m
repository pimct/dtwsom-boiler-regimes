function fh = plot_training_curve(trainLog)
%PLOT_TRAINING_CURVE  Quantisation error and mean prototype change per epoch.
    fh = figure('Color','w');
    yyaxis left;  plot(trainLog.QE, 'LineWidth', 1.2); ylabel('Mean quantisation error (DTW)');
    yyaxis right; semilogy(trainLog.dW, 'LineWidth', 1.2); ylabel('Mean prototype change');
    xlabel('Epoch'); grid on; title('DTW-SOM training convergence');
end
