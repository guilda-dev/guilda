function sct = make_part5_figures(opt)
% Make the single-line diagram and print the mode numbers of Part 5 of the lecture
% (_GUILDAdocPages/lecture/part5-linearization.html).
%
% The system of every analysis of the page is network.IEEE9bus(LocalController=true)
% (three generators with AVR and PSS) at its equilibrium. The script
%
% - draws its single-line diagram with PowerNetwork.plot_single_line_diagram, with the
%   names G1-G3 of the generators added next to their buses, and writes
%   ieee9-single-line.png;
% - linearizes it (get_sys) and prints the numbers that the section "Reading the result
%   of IEEE 9-bus" quotes: disp_mode of the oscillatory modes, the decay time constant
%   1/|Re lambda| and the time for the amplitude to halve, the speed part of the mode
%   shapes (magnitude and phase relative to the largest entry) and the participation of
%   each generator (its states and those of its AVR and PSS, from get_participation).
%
% It returns the numbers in a struct. Writes into _GUILDAdocPages/images/lecture/part5/
% (or OutDir). Run from the repository root with R2026a, e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part5_figures();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                        % Output folder; "" for _GUILDAdocPages/images/lecture/part5.
        opt.Resolution (1,1) double {mustBePositive} = 300   % [dpi] Resolution of the PNG.
    end
    arguments (Output)
        sct (1,1) struct  % Numbers of the modes: tab_mode, rm_shapeAbs, rm_shapeDeg, rm_genPart.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part5");
    end

    net = network.IEEE9bus(LocalController=true);
    draw_single_line(net, fullfile(s_out, "ieee9-single-line.png"), opt.Resolution);

    net.initialize();
    sys = net.get_sys();
    sys.disp_mode(MinFrequency=0.1);
    sm = sys.get_mode(MinFrequency=0.1);
    tab = sm.tab_mode;
    tab.TimeConstant = 1./abs(real(tab.Eigenvalue));              % [s]
    tab.HalvingTime = log(2)./abs(real(tab.Eigenvalue));          % [s]
    tab.HalvingCycles = tab.HalvingTime.*tab.Frequency;           % periods until half
    disp(tab)
    sv_gen = "B00" + (1:3)' + "SG1";
    iv_omega = arrayfun(@(s) find(sm.sv_state == "omega_" + s), sv_gen);
    cm = sm.cm_shape(iv_omega, :);
    [~, iv_max] = max(abs(cm), [], 1);
    cm = cm ./ cm(sub2ind(size(cm), iv_max, 1:size(cm, 2)));      % largest speed entry = 1
    rm_part = zeros(3, height(tab));
    for k = 1:3
        rm_part(k, :) = sum(sm.rm_participation(startsWith(sm.sv_owner, sv_gen(k)), :), 1);
    end
    for i = 1:height(tab)
        fprintf("Mode %d: %.3f Hz, zeta %.2f %%\n", i, tab.Frequency(i), 100*tab.DampingRatio(i));
        for k = 1:3
            fprintf("  G%d: speed %.2f at %6.1f deg, participation %.2f\n", k, abs(cm(k, i)), ...
                rad2deg(angle(cm(k, i))), rm_part(k, i));
        end
    end
    sct = struct(tab_mode=tab, rm_shapeAbs=abs(cm), rm_shapeDeg=rad2deg(angle(cm)), rm_genPart=rm_part);
end


function draw_single_line(net, s_file, r_dpi)
% The single-line diagram with the names of the generators beside their buses.
    G = net.plot_single_line_diagram();
    ax = G.ax(1);
    h_fig = ancestor(ax, "figure");
    sct = G.get_layout();
    for k = 1:3
        s_bus = "B00" + k;
        rv_bus = sct.tab_bus{sct.tab_bus.Tag == s_bus, ["X","Y"]};
        rv_d = sct.tab_component{startsWith(sct.tab_component.Tag, s_bus), ["DX","DY"]};
        rv_xy = rv_bus + 2.5*rv_d(1, :);                   % beyond the generator symbol
        text(ax, rv_xy(1), rv_xy(2), "G" + k, FontSize=6.5, FontWeight="bold", ...
            HorizontalAlignment="center", VerticalAlignment="middle");
    end
    r_pad = 0.04*diff(ax.XLim);                            % room for the names at the sides
    ax.XLim = ax.XLim + [-r_pad, r_pad];
    ax.YLim = ax.YLim + [-r_pad, 0];
    drawnow;
    exportgraphics(ax, s_file, Resolution=r_dpi, BackgroundColor="white");
    delete(h_fig);
end
