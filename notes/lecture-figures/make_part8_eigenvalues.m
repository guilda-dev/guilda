function make_part8_eigenvalues(opt)
% Make the eigenvalue figure of the local LQR example in Part 8 of the lecture
% (_GUILDAdocPages/lecture/part8-controller-design.html): lqr-eigenvalues.png.
%
% Three panels of network.IEEE68bus(LocalController=true), each drawn by
% ResultLIN.plot_eigenvalue of net.get_sys() and shown near the origin (upper half of the
% complex plane, the limits XLim and YLim):
%   (a) as bundled: AVR (avr-ST1) and PSS (pss-PSS1) on all 16 generators;
%   (b) the PSSs removed (AVR only);
%   (c) the AVR of generators 1-15 replaced by local-LQR (Input="Vfield", R=1e-4);
%       generator 16 keeps its AVR without PSS.
% The script sets only the panel titles and the axis limits, and clears the explanatory
% subtitle of plot_eigenvalue (it overlaps in three narrow panels; the caption of the page
% explains the colors). Writes lqr-eigenvalues.png
% into _GUILDAdocPages/images/lecture/part8 (or into OutDir) and prints the number of
% unstable eigenvalues of each panel. Run from the repository root with R2026a (needs the
% Control System Toolbox for local-LQR), e.g.
%   matlab -batch "GUILDA.addpath; addpath('notes/lecture-figures'); make_part8_eigenvalues();"
    arguments (Input)
        opt.OutDir (1,1) string = ""                                % Output folder; "" for _GUILDAdocPages/images/lecture/part8.
        opt.Resolution (1,1) double {mustBePositive} = 150          % [dpi] Resolution of the PNG.
        opt.Size (1,2) double {mustBePositive} = [22, 9]            % [cm] Size of the figure.
        opt.XLim (1,2) double = [-3, 1]                             % [1/s] Limits of the real axis.
        opt.YLim (1,2) double = [0, 14]                             % [rad/s] Limits of the imaginary axis.
    end
    s_out = opt.OutDir;
    if s_out == ""
        s_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));   % notes/lecture-figures -> notes -> root
        s_out = fullfile(s_root, "_GUILDAdocPages", "images", "lecture", "part8");
    end

    % (a) as bundled
    net = network.IEEE68bus(LocalController=true);
    c_lin = {net.get_sys()};
    % (b) AVR only
    for i = 1:16
        gen = net.a_Bus{i}.a_Component{1};
        gen.remove_local_controller(gen.pss.s_tag);
    end
    net.initialize();
    c_lin{2} = net.get_sys();
    % (c) local LQR on generators 1-15 in the place of the AVR
    for i = 1:15
        net.a_Bus{i}.a_Component{1}.add_local_controller("local-LQR", parameter=struct(Input="Vfield", R=1e-4));
    end
    net.initialize();
    c_lin{3} = net.get_sys();

    sv_title = ["(a) AVR + PSS", "(b) AVR", "(c) local-LQR (G1–G15)"];
    fig = figure(Color="w", Units="centimeters", Position=[2 2 opt.Size]);
    tl = tiledlayout(fig, 1, 3, TileSpacing="compact", Padding="compact");
    for k = 1:3
        e = c_lin{k}.get_eigenvalue();
        fprintf("%s: %d unstable eigenvalues, largest real part %.4g\n", sv_title(k), sum(real(e) > 1e-6), max(real(e)));
        G = c_lin{k}.plot_eigenvalue(Parent=nexttile(tl));
        title(G.ax(1), sv_title(k));
        subtitle(G.ax(1), "");
        xlim(G.ax(1), opt.XLim);
        ylim(G.ax(1), opt.YLim);
    end
    drawnow;
    exportgraphics(fig, fullfile(s_out, "lqr-eigenvalues.png"), Resolution=opt.Resolution, BackgroundColor="white");
    close(fig);
end
