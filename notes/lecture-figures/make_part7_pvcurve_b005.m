function make_part7_pvcurve_b005(opt)
% Make the PV curve of bus B005 of the IEEE 9-bus system in Part 7 of the lecture
% (_GUILDAdocPages/lecture/part7-continuation-power-flow.html, section "The PV curves of
% the IEEE 9-bus system").
%
% The commands of the page: network.IEEE9bus, net.initialize, the continuation power flow
% with LoadBus = B005, B006, B008 (no limits), and ResultCPF.plot_pvcurve(Bus="B005") as
% GUILDA draws it. Only B005 is drawn: the path is parameterised by the one load parameter
% lambda, and on its lower branch the voltages of B006 and B008 rise again toward lambda = 0
% (see make_part7_pvcurve_check), which is not the lower branch of their own PV curves.
% Writes _GUILDAdocPages/images/lecture/part7/ieee9-pv-curve-b005.png (or into OutDir).
% Run from the repository root with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part7_pvcurve_b005();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part7.
        opt.Resolution (1,1) double {mustBePositive} = 150   % [dpi] Resolution of the PNG.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part7");
    end
    net = network.IEEE9bus();
    net.initialize();
    result = net.calculate_continuation_powerflow(LoadBus=["B005","B006","B008"], Progress="none");
    fprintf("r_lambdaMax = %.4f\n", result.r_lambdaMax);
    fig = figure(Color="w", Position=[100 100 640 440], Visible="off");
    result.plot_pvcurve(Bus="B005", Parent=fig);
    drawnow;
    exportgraphics(fig, fullfile(s_out, "ieee9-pv-curve-b005.png"), Resolution=opt.Resolution, BackgroundColor="white");
    delete(fig);
end
