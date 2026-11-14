function set_time(obj, t)
% Show the sample of the state nearest to time t.
%
% The bus, branch and component values of that sample are computed and the drawing is
% updated. With one sample (n_t = 1) it draws that sample again. The title shows the time
% of the sample when the state has more than one sample.
%
% <@Examples>
% ```matlab
% G = net.plot_diagram();
% G.set_time(0);
% ```
    arguments (Input)
        obj
        t (1,1) double % [s] Time to show.
    end
    rv_t = obj.sct_state.rv_t;
    [~, k] = min(abs(rv_t - t));
    obj.i_time = k;
    obj.set_powerflow(obj.sct_state.cm_Vbus(:, k), obj.sct_state.cm_Icomp(:, k));
    if numel(rv_t) > 1 && isgraphics(obj.ax)
        title(obj.ax, sprintf("t = %.2f s", rv_t(k)));
    end
end
