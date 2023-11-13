%電力系統のフレームワークを作成
net = power_network;


%母線(bus)の定義
    shunt = [0,0];
    %母線1の定義
    bus_1 = bus_slack(2,0,shunt);
    net.add_bus(bus_1);
    %母線2の定義
    bus_2 = bus_PV(0.5,2,shunt);
    net.add_bus(bus_2);
    %母線3の定義
    bus_3 = bus_PQ(-3,0,shunt);
    net.add_bus(bus_3);


%機器(component)の定義

    %系統周波数の定義
    omega0 = 60*2*pi;

    %母線1に同期発電機の1軸モデルを付加
    Xd = 1.569; Xd_prime = 0.963; Xq = 0.963; T = 5.14; M = 100; D = 10;
    mac_data = table(Xd,Xd_prime,Xq,T,M,D);
    component1 = generator_1axis( omega0, mac_data);
    net.a_bus{1}.set_component(component1);

    %母線2にも同期発電機の1軸モデルを付加
    Xd = 1.220; Xd_prime = 0.667; Xq = 0.667; T = 8.97; M = 12; D = 10;
    mac_data = table(Xd,Xd_prime,Xq,T,M,D);
    comp2 = generator_1axis( omega0, mac_data);
    net.a_bus{2}.set_component(comp2);

    %母線3には定インピーダンスモデルを付加
    comp3 = load_impedance();
    net.a_bus{3}.set_component(comp3);


%ブランチ(branch)の定義

    %母線1と母線2を繋ぐ送電線の定義
    branch12 = branch_pi(1,2,[0.010,0.085],0);
    net.add_branch(branch12);
    %母線2と母線3を繋ぐ送電線の定義
    branch23 = branch_pi(2,3,[0.017,0.092],0);
    net.add_branch(branch23);
    

%潮流計算の実行
net.initialize


%余談 ~アドミタンス行列の導出~
full(net.get_admittance_matrix)


%シミュレーションの実行(制御器なしver)

    %条件設定
    time = [0,10,20,60];
    u_idx = 3;
    u = [0, 0.05, 0.1, 0.1;...
         0,    0,   0,   0];

    %入力信号波形プロット
    figure; hold on;
    u_percent = u*100;
    stairs(time,u_percent(1,:),'LineWidth',2)
    stairs(time,u_percent(2,:),'--','LineWidth',2)
    xlabel('時刻(s)','FontSize',15); 
    ylabel('定常値からの変化率(%)','FontSize',15);
    ylim([-20,20])
    legend({'インピーダンスの実部','インピーダンスの虚部'},'Location','southeast')
    title('母線3のインピーダンスの値の変化','FontSize',20)
    hold off;

    %解析実行
    out1 = net.simulate(time,u, u_idx);

    %データ抽出
    sampling_time = out1.t;
    omega1 = out1.X{1}(:,2);
    omega2 = out1.X{2}(:,2);

    %プロット
    figure; hold on;
    plot(sampling_time, omega2,'LineWidth',2)
    plot(sampling_time, omega1,'LineWidth',2)
    xlabel('時刻(s)','FontSize',15); 
    ylabel('周波数偏差','FontSize',15);
    legend({'機器2の周波数偏差','機器1の周波数偏差'})
    title('各同期発電機の周波数偏差','FontSize',20)
    hold off

%電力系統に制御器を付加 

    %AGCコントローラを定義
    con = controller_broadcast_PI_AGC(net,1:2,1:2,-10,-500);

    %電力系統にcontrollerクラスを代入
    net.add_controller_global(con);


%シミュレーションの実行(制御器ありver)

    %解析実行
    out2 = net.simulate(time,u,u_idx);

    %データ抽出
    sampling_time = out2.t;
    omega1 = out2.X{1}(:,2);
    omega2 = out2.X{2}(:,2);

    %プロット
    figure; hold on;
    plot(sampling_time, omega2,'LineWidth',2)
    plot(sampling_time, omega1,'LineWidth',2)
    xlabel('時刻(s)','FontSize',15); 
    ylabel('周波数偏差','FontSize',15);
    legend({'機器2の周波数偏差','機器1の周波数偏差'})
    title('各同期発電機の周波数偏差','FontSize',20)
    hold off

%制御器を付ける前と後の比較のプロット
    figure; hold on;
    plot(out1.t, out1.X{2}(:,2),'Color','#A2142F','LineWidth',1.5)
    plot(out1.t, out1.X{1}(:,2),'Color','#EDB120','LineWidth',1.5)
    plot(out2.t, out2.X{2}(:,2),'Color','#0072BD','LineWidth',1.5)
    plot(out2.t, out2.X{1}(:,2),'Color','#77AC30','LineWidth',1.5)
    xlabel('時刻(s)','FontSize',15); 
    ylabel('周波数偏差','FontSize',15);
    legend({'機器2の周波数偏差(AGCなし)','機器1の周波数偏差(AGCなし)',...
                '機器2の周波数偏差(AGCあり)','機器1の周波数偏差(AGCあり)'},...
                'Location','east')
    title('各同期発電機の周波数偏差','FontSize',20)
    hold off
