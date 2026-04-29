function [Graph, txt, sct] = new_plot(net)
    
    figure("Position", [0, 0, 1200, 600]);
    
    t = tiledlayout(3, 5, 'Padding', 'compact');
    ax1 = nexttile(t, 1, [3, 3]);
    ax2 = nexttile(t, 4, [1, 2]);
    ax3 = nexttile(t, 9, [2, 2]);

    Graph = net.draw_diagram(ax1);
    Graph.GridWidth = 0.05;
    Graph.NodeFontSize = 5;
    Graph.NodeHeightMode = "none";
    xlim(ax1,0.05+[0,1])
    grid(ax1,"off")

    axis(ax2,"off")
    txt = text(ax2,0,0,"安定","FontSize",20,"FontWeight","bold","HorizontalAlignment","center","Color","b");
    xlim(ax2,[-1,1.5])
    ylim(ax2,[-2,1])
    
    sys  = net.get_sys;
    eigA = eig(sys.A);
    Ar = real(eigA);
    Ai = imag(eigA);
    
    hold(ax3,"on")
    grid(ax3,"on")
    subtitle(ax3,"極配置")
    xline(0,"k-","LineWidth",0.5)
    yline(0,"k-","LineWidth",0.5)
    % xlim(ax3,[-2,0.5])
    ylim(ax3,[-1,1]*40)
    % xticks(ax3,-2:0.4:0.4)
    sct = scatter(ax3, Ar, Ai, 10, "blue", "filled","o");
end