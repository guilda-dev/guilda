classdef Component < PowerSystemModel
% Class for managing equipment dynamics and power-flow settings 

%% Abstract properties/methods
    properties(Abstract,Constant)
        key      (1,1) string
        str_x    (:,1) string
        str_u    (:,1) string 
        str_y    (:,1) string
        str_para (:,1) string
    end
    methods(Abstract)
        [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,r_P,r_Q);
        set_odefcn(obj, omega0)
    end
    

%% Parameter
    properties(SetAccess=protected)
        a_Bus                                  % [   Layer   ] 接続しているBusクラス(a_Cubicleから辿る)
        a_LocalController (:,1) = cell(0,1)    % [   Layer   ] 接続されているControllerクラスのcell配列        
        rm_odeMass                             % [  Dynamics ] 数値積分の計算に使用する質量行列のシンボリック式
        fv_odeDiff                             % [  Dynamics ] 数値積分の計算に使用する微分方程式のシンボリック式
        fv_odeI                                % [  Dynamics ] 数値積分の計算に使用する接続方程式のシンボリック式
        fv_odeY
        JacobiA
        JacobiB
        JacobiBu
        JacobiC
        JacobiCyx
        JacobiD
        JacobiDu
        JacobiDyv
        JacobiDyu
        odeLinearSystem
    end
    properties
        cv_Xcurrent = zeros(0,1)               % [  Simulation ] シミュレーション中の状態
        cv_Ucurrent = zeros(0,1)               % [  Simulation ] シミュレーション中の入力
    end
    properties(SetAccess=protected)
        cv_Xequilibrium = zeros(0,1)           % [SteadyState] 状態の平衡点
        cv_Uequilibrium = zeros(0,1)           % [SteadyState] 定常入力
        c_Iequilibrium                         % [SteadyState] 定常潮流状態での機器の注入電流
        c_Vequilibrium                         % [SteadyState] 定常潮流状態での機器の注入電圧
    end
    properties (SetAccess={?odeSimulator, ?Component}, Hidden)
        iv_odeX  = zeros(0,1);
        iv_odeU  = zeros(0,1);        
    end    
    properties(Dependent)
        cv_Xequilibrium_all                    % [SteadyState] 制御器の状態も含めた平衡点
        tab_parameter                          % [ Parameter ] ハイパーパラメータの設定値
    end
    properties(SetAccess=protected)
        para_dynamics                          % [ Parameter ] tab_prameterの動特性の部分を管理するParameterクラス 
        para_powerflow                         % [ Parameter ] tab_prameterの潮流設定の部分を管理するParameterクラス
        para_operation                         % [ Parameter ] tab_prameterの運用基準の部分を管理するParameterクラス
        para_OPF                               % [ Parameter ] tab_prameterのOPFの部分を管理するParameterクラス
        para_graph                             % [ Parameter ] tab_prameterのグラフ描画の部分を管理するParameterクラス
    end  
    properties(Dependent, Access=protected)
        parent                                 % [   Layer   ] Layerの上位に当たるクラス
        children                               % [   Layer   ] Layerの下位に当たるクラス群
    end
    properties (Access={?odeSimulator, ?Component, ?odeEventSet})        
        isConnect = true
    end
    properties (Hidden)
        X_offset 
        U_offset 
    end

    
    
%% Constructor
    methods(Access=protected)
        function obj = Component(str_tag, opt)
            obj.str_tag        = str_tag;
            obj.para_dynamics  = Parameter(obj,"dynamics");
            obj.para_powerflow = Parameter(obj,"powerflow");
            obj.para_OPF       = Parameter(obj,"OPF");
            obj.para_graph     = Parameter(obj,"graph");
            obj.para_operation = Parameter(obj,"operation");

            obj.para_operation.add_entry( "baseMVA", opt.baseMVA          , "double",...
                                             "Pmin", opt.Pmin             , "double",...
                                             "Pmax", opt.Pmax             , "double",...
                                             "Qmin", opt.Qmin             , "double",...
                                             "Qmax", opt.Qmax             , "double");
            obj.para_powerflow.add_entry(       "P", opt.P                , "double",...
                                                "Q", opt.Q                , "double");
            obj.para_OPF.add_entry(            "P0", opt.OPFinit_P0       , "double",...
                                               "Q0", opt.OPFinit_Q0       , "double",...
                                               "HP", opt.OPFcost_HP       , "double",...
                                               "HQ", opt.OPFcost_HQ       , "double",...
                                               "fP", opt.OPFcost_fP       , "double",...
                                               "fQ", opt.OPFcost_fQ       , "double",...
                                          "startup", opt.OPFcost_startup  , "double",...
                                         "shutdown", opt.OPFcost_shutdown , "double");
            obj.para_graph.add_entry(       "Xaxis", opt.Xaxis            , "double",...
                                            "Yaxis", opt.Yaxis            , "double",...
                                           "Marker", opt.Marker           , "string",...
                                         "MidXaxis", opt.MidXaxis         , "string",...
                                         "MidYaxis", opt.MidYaxis         , "string",...
                                         "BusPoint", opt.BusPoint        , "string");
        end
    end

%% Methods
    methods
        % Layer Structure
        add_local_controller(obj, a_Controller)
        remove_local_controller(obj,str_tag)

        % OPF
        [prob, x0, const] = build_opf_problem(obj, prob, x0, const, Busvar, option)

        % Dynamics
        [n_odeX, n_odeU, Mass, x0] = reset_odeset(obj, n_odeX, n_odeU, omega0)

        %get_sys
        sys = get_sys(obj, x, V, u)

    end

    methods(Access={?Bus})
        set_bus(obj,bus)
        set_equilibrium(obj)
    end


%% Get Methods
    methods
        function x = get.cv_Xequilibrium_all(obj)
            a_con = [obj.a_GlobalController; obj.a_LocalController];
            x_con = tools.vcellfun(@(comp) comp.cv_Xequilibrium, a_con);
            x     = [obj.cv_Xequilibrium; x_con];
        end
        function p = get.parent(obj)
            p = obj.a_Bus;
        end
        function p = get.children(obj)
            p = [ obj.a_LocalController  ;...
                 {obj.para_dynamics      ; obj.para_powerflow     ;...
                  obj.para_operation     ; obj.para_OPF           ;...
                  obj.para_graph         }];
        end
        function tp = get.tab_parameter(obj)
            dynamics  = obj.para_dynamics.tab_parameter;
            powerflow = obj.para_powerflow.tab_parameter;
            OPF       = obj.para_OPF.tab_parameter;
            operation = obj.para_operation.tab_parameter;
            graph     = obj.para_graph.tab_parameter;
            tp        = table(dynamics,operation,powerflow,OPF,graph);
        end
    end

%% Set Methods
    methods
        function set.tab_parameter(obj,val)
            fieldname = val.Properties.VariableNames;
            for i = 1:numel(fieldname)
                propname = "para_"+fieldname{i};
                tabdata  = val.(fieldname{i});
                paraname = tabdata.Properties.VariableNames;
                for j = 1:numel(paraname)
                    obj.(propname).(paraname{j}) = tabdata.(paraname{j});
                end
            end
        end
    end   
end





