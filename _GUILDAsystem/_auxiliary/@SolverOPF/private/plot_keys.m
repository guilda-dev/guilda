function sv_key = plot_keys()
% Display keys of PlotFcn: key k is the plot function optimplot<k> of fmincon.
    arguments (Output)
        sv_key (1,:) string  % Keys, in the order of the PlotFcn options of GUILDA.setting.
    end
    sv_key = ["fval","constrviolation","fvalconstr","firstorderopt","stepsize","funccount","x"];
end
