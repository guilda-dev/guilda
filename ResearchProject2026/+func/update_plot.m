function update_plot(net, Graph, txt, sct)

    fprintf(" >> グラフプロットに反映中...")
    cv_V = net.cv_Vequilibrium;
    Graph.set_powerflow(net)
    disp(" ok!!")

    sys  = net.get_sys;
    eigA = eig(sys.A);

    Ar = real(eigA);
    Ai = imag(eigA);

    if all(Ar<1e-5)
        txt.String = "安定です👏";
        txt.Color  = "b";
    else
        txt.String = "不安定です🙇‍♂️";
        txt.Color  = "r";
    end

    fprintf(" >> 極配置プロットに反映中...")
    sct.XData = Ar;
    sct.YData = Ai;
    disp(" ok!!")
end