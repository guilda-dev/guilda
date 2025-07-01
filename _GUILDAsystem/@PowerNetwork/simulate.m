function [out,sim] = simulate(obj, time, u, uidx, opt)
% Numerical Simulation
% >> See "_GUILDAsystem/@power_network/simulate.m"
    arguments
        obj 
        time double
        u    (:,:) double
        uidx (1,:) double
        opt.odeset  (1,1) struct = odeset();
        opt.RelTol  (1,1) double = 1e-3;
        opt.AbsTol  (1,1) double = 1e-6;
        opt.MaxStep (1,1) double = 0.1*(time(end)-time(1));
        opt.MinStep (1,1) double = 0;
        opt.NormControl    (1,1) string {mustBeMember(opt.NormControl,   ["on","off"])}      = "off";
        opt.DisplaySetting (1,1) string {mustBeMember(opt.DisplaySetting,["on","off"])}      = "on"; 
        opt.Dialog         (1,1) string {mustBeMember(opt.Dialog, ["disp","dialog","none"])} = "dialog";
        opt.TimeLimit      (1,1) double {mustBePositive} = inf;
        opt.ExportData     (1,1) string {mustBeMember(opt.ExportData,["double","table","solfactory"])} = "solfactory"; 
    end

    % 旧バーションの実行方法に対応するための処理
    % 旧バーションはは１つの母線には一つの機器が接続されているという仮定が置かれていたため、対象の機器はBuses{i}.Components{1}とする。
    for i = uidx
        comp = obj.Buses{i}.Components{1};
        nu   = numel(comp.u_equilibrium);
        comp.add_odeinput(time,u(1:nu,:),"method","zoh","lifetime","1time")
        u = u((nu+1):end,:);
    end


    % ode15sで使用するoptの初期設定
    OdeSet = odeset("RelTol", opt.RelTol, "AbsTol", opt.AbsTol, ...
                    "MaxStep",opt.MaxStep,"MinStep",opt.MinStep,...
                    "NormControl",opt.NormControl,...
                    "OutputFcn",@(t) rep.OutputFcn(t) );


    % シミュレータクラスを生成
    simulator =  supporters.for_simulate.odefactory(obj);

    % クラスのリストを取得
    Buses       =  obj.Buses;
    Components  = [obj.Branches; obj.Components];
    Controllers = [obj.LocalControllers; obj.GlobalControllers];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%  シミュレーション開始 %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% シミュレーション開始時の初期設定
    obj.DisplaySettings = opt.DisplaySetting;
    simulator.initialize(time, OdeSet, opt.Dialog, opt.TimeLimit)


    t0 = time(1);
    te = time(2);


    %%%%%%%% 地絡や入力・並解列のタイミング毎にタームを切り替える  %%%%%
    while t0<te
        simulator.initialize_term( obj, t0, opt.DisplaySetting)

        % ターム開始時の初期設定
        [sysBus,teBus] = cellfun(@(bus) bus.initialize(t0), obj.Buses, 'UniformOutput',false);
         sysBus = blkdiag(sysBus{:});
         Abus_v = sparse(sysBus.A);
         Abus_w = sparse(sysBus.B);
        
        [sysComp,te]

        t0 = t(end);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%  シミュレーション終了 %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    % 出力データの形式指定
    switch opt.ExportData
        case "double"
            out = simulator.export("double");
        case "table"
            out = simulator.export("table");
        case "solfactory"
            sol  = simulator.export("table");
            info = net.information("Display",false);
            out  = supporters.for_simulate.solfactory(sol,info);
    end

end