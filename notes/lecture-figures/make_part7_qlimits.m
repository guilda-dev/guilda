function make_part7_qlimits(opt)
% Make the PV curves of bus B005 of the IEEE 9-bus system without and with reactive power
% limits in Part 7 of the lecture (_GUILDAdocPages/lecture/part7-continuation-power-flow.html,
% section "Reactive power limits change the curve").
%
% The commands of the page: the continuation power flow with LoadBus = B005, B006, B008,
% (a) without limits and (b) with Qmax = 0.6 pu on the generators of B002 and B003 and
% Limits="Q"; each panel is ResultCPF.plot_pvcurve(Bus="B005") in a tile, and in (b) a
% marker with the bus name at each switch of result_Q.tab_switch on the curve of B005
% (plain plot/text, shown on the page). Only B005 is drawn, as in the figure before (see
% make_part7_pvcurve_b005). Writes _GUILDAdocPages/images/lecture/part7/q-limits.png (or
% into OutDir). Run from the repository root with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part7_qlimits();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part7.
        opt.Resolution (1,1) double {mustBePositive} = 150   % [dpi] Resolution of the PNG.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part7");
    end
    fig = figure(Color="w", Position=[100 100 1100 440], Visible="off");

    % --- the commands of the page ---
    net = network.IEEE9bus();
    net.initialize();
    result = net.calculate_continuation_powerflow(LoadBus=["B005","B006","B008"], Progress="none");
    net.a_Bus{2}.a_Component{1}.tab_parameter.operation.Qmax = 0.6;
    net.a_Bus{3}.a_Component{1}.tab_parameter.operation.Qmax = 0.6;
    result_Q = net.calculate_continuation_powerflow(LoadBus=["B005","B006","B008"], Limits="Q", Progress="none");
    disp(result_Q.tab_switch);

    tiledlayout(fig, 1, 2);
    ax1 = nexttile;
    result.plot_pvcurve(Bus="B005", Parent=ax1);
    title(ax1, "(a) Q_{max} = \infty");
    ax2 = nexttile;
    result_Q.plot_pvcurve(Bus="B005", Parent=ax2);
    title(ax2, "(b) Q_{max} = 0.6 pu (B002, B003)");
    sw = result_Q.tab_switch;
    V5 = abs(result_Q.cm_Vbus(result_Q.sv_bus == "B005", sw.Step));
    hold(ax2, "on");
    plot(ax2, sw.lambda, V5, "ko", MarkerFaceColor="k", HandleVisibility="off");
    text(ax2, sw.lambda, V5, sw.Bus + "  ", HorizontalAlignment="right");
    linkaxes([ax1 ax2]);
    xlim(ax1, [-0.2 1.5]);
    % --- end of the commands of the page ---

    fprintf("lambdaMax: %.4f (no limits), %.4f (Q limits); |V| of B005 at the nose: %.3f, %.3f\n", ...
        result.r_lambdaMax, result_Q.r_lambdaMax, ...
        abs(result.cm_Vbus(result.sv_bus == "B005", result.r_noseStep)), ...
        abs(result_Q.cm_Vbus(result_Q.sv_bus == "B005", result_Q.r_noseStep)));
    fprintf("switch lambda: %s, |V| of B005: %s\n", mat2str(sw.lambda.', 4), mat2str(V5, 4));
    fprintf("check index: rv_lambda(Step) = %s\n", mat2str(result_Q.rv_lambda(sw.Step), 5));
    drawnow;
    exportgraphics(fig, fullfile(s_out, "q-limits.png"), Resolution=opt.Resolution, BackgroundColor="white");
    delete(fig);
end
