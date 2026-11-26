function sct = make_part7_pvcurve_check(opt)
% Check the shape of the PV curves of IEEE 9-bus in Part 7 of the lecture
% (_GUILDAdocPages/lecture/part7-continuation-power-flow.html). Not a figure of the page:
% it answers why the lower branches of buses 6 and 8 bend back up toward lambda = 0 and
% why the curves with Q limits have corners.
%
% Cases (network.IEEE9bus, net.calculate_continuation_powerflow):
%   all3      LoadBus = B005, B006, B008 (as on the page), no limits
%   all3_Q    the same with Qmax = 0.6 pu on the generators of B002 and B003, Limits="Q"
%   only5     only B005 scaled, no limits
%   only6     only B006 scaled, no limits
%   only8     only B008 scaled, no limits
%   only5_Q   only B005 scaled, Qmax = 0.6 pu, Limits="Q"
% For each case it prints lambda_max, the last lambda of the path, |V| of the load buses
% at the start, at the nose and at the last point, whether |V| rises again on the lower
% branch, and the PV-to-PQ switches; it writes plot_pvcurve of the load buses (all buses
% scaled or not) and of the scaled bus alone as PNG files into OutDir.
%
% Run from the repository root with R2026a:
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part7_pvcurve_check(OutDir='<folder>');"
    arguments (Input)
        opt.OutDir (1,1) string = pwd                         % Output folder of the PNG files.
        opt.Resolution (1,1) double {mustBePositive} = 150    % [dpi] Resolution of the PNG files.
    end
    if ~isfolder(opt.OutDir)
        mkdir(opt.OutDir);
    end
    sv_load = ["B005", "B006", "B008"];
    c_case = { ...
        "all3",    sv_load, false; ...
        "all3_Q",  sv_load, true; ...
        "only5",   "B005",  false; ...
        "only6",   "B006",  false; ...
        "only8",   "B008",  false; ...
        "only5_Q", "B005",  true};
    sct = struct();
    for k = 1:size(c_case, 1)
        [s_name, sv_scale, l_Q] = c_case{k, :};
        net = network.IEEE9bus();
        if l_Q
            net.a_Bus{2}.a_Component{1}.tab_parameter.operation.Qmax = 0.6;
            net.a_Bus{3}.a_Component{1}.tab_parameter.operation.Qmax = 0.6;
        end
        net.initialize();
        if l_Q
            [res, flag] = net.calculate_continuation_powerflow(LoadBus=sv_scale, Limits="Q", Progress="none");
        else
            [res, flag] = net.calculate_continuation_powerflow(LoadBus=sv_scale, Progress="none");
        end
        rv_lambda = res.rv_lambda(:).';
        [~, i_nose] = max(rv_lambda);
        [~, iv_bus] = ismember(sv_load, res.sv_bus);
        rm_V = abs(res.cm_Vbus(iv_bus, :));
        fprintf("\n=== %s: LoadBus = %s, Limits = %s, flag = %d\n", s_name, join(sv_scale, ","), ...
            string(l_Q), flag);
        fprintf("lambda_max = %.4f at step %d of %d; last lambda = %.4f\n", ...
            rv_lambda(i_nose), i_nose - 1, numel(rv_lambda) - 1, rv_lambda(end));
        for i = 1:numel(sv_load)
            rv_low = rm_V(i, i_nose:end);           % lower branch, from the nose on
            [r_min, i_min] = min(rv_low);
            l_rise = i_min < numel(rv_low) && rv_low(end) - r_min > 1e-3;
            fprintf("  %s: |V| start %.3f, nose %.3f, min on lower branch %.3f (lambda %.3f), last %.3f -> rises again: %d\n", ...
                sv_load(i), rm_V(i, 1), rm_V(i, i_nose), r_min, rv_lambda(i_nose - 1 + i_min), ...
                rm_V(i, end), l_rise);
        end
        % Generator Q along the path (bus injection of B001-B003)
        rv_Qnose = zeros(1, 3);
        rv_Qlast = zeros(1, 3);
        Y = net.get_admittance_matrix.Variables;
        for j = 1:3
            I_nose = Y(j, :) * res.cm_Vbus(:, i_nose);
            I_last = Y(j, :) * res.cm_Vbus(:, end);
            rv_Qnose(j) = imag(res.cm_Vbus(j, i_nose) * conj(I_nose));
            rv_Qlast(j) = imag(res.cm_Vbus(j, end) * conj(I_last));
        end
        fprintf("  Q of generators B001-B003 at the nose: %s; at the last point: %s\n", ...
            mat2str(rv_Qnose, 3), mat2str(rv_Qlast, 3));
        if ~isempty(res.tab_switch)
            disp(res.tab_switch);
        end
        sct.(s_name) = struct("lambdaMax", rv_lambda(i_nose), "lambdaLast", rv_lambda(end), ...
            "Vstart", rm_V(:, 1).', "Vnose", rm_V(:, i_nose).', "Vlast", rm_V(:, end).', ...
            "tab_switch", res.tab_switch);

        fig = figure(Color="w", Position=[100 100 640 440], Visible="off");
        res.plot_pvcurve(Bus=sv_load, Parent=fig);
        drawnow;
        exportgraphics(fig, fullfile(opt.OutDir, s_name + "-loadbuses.png"), Resolution=opt.Resolution, BackgroundColor="white");
        delete(fig);
        if isscalar(sv_scale) || s_name == "all3" || s_name == "all3_Q"
            fig = figure(Color="w", Position=[100 100 640 440], Visible="off");
            res.plot_pvcurve(Bus="B005", Parent=fig);
            drawnow;
            exportgraphics(fig, fullfile(opt.OutDir, s_name + "-B005.png"), Resolution=opt.Resolution, BackgroundColor="white");
            delete(fig);
        end
    end
end
