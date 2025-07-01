classdef PowerNetwork < LayerPackage
% 全ての系統構成クラスを格納し管理するクラス
% 時間応答や近似線形化、潮流計算や最適潮流計算などは本クラスのメソッドとして定義 
% 格納されている母線や送電線、機器、制御機クラスから情報を抽出して各種解析をする
%
%
%
%  << 親クラスからの継承プロパティ >>
%
%     prop         class      description
% ========================================================================
%   ・parent   |LayerPackage| 階層構造の上位層にあたるLayerPackageクラス
%   ・parent   |    cell    | 階層構造の下位層にあたるLayerPackageクラス
%   ・tag      |   string   | クラスの呼称
%   ・index    |   double   | インデックス番号、tagともにクラスの命名に使用
%   ・parameter|   table    | ユーザが設定する定数は全てこのプロパティで管理
%   ・editFlag |  logical   | 変更が加えられたかどうかの管理simulate前などに確認
%   ・editLog  |   table    | 変更内容を「変更時間・対象クラス・変更内容」で管理
% ========================================================================
%

    properties
        omega0 (1,1) double {mustBePositive} = 60*2*pi; % 60Hz*2pi
    end

    properties(Dependent,Access=protected)
        children (:,1) cell
    end

    properties(SetAccess=protected)
        Buses             = {};
        Branches          = {};
        GlobalControllers = {};
        methodPF (1,1) string {mustBeMember(methodPF,["AC OPF","ELD","PF","manual","unset"])} = "unset";
    end

    properties(Dependent)
        x_equilibrium
        V_equilibrium
        I_equilibrium
        xbus_equilibrium
        xbranch_equilibrium
        xcg_equilibrium % equilibrium @ global controller
    end


    
    methods
        % construct Layer @Bus 
        add_bus(obj, BusInstance)
        replace_bus(obj, BusInstance, i_bus)
        remove_bus(obj, i_bus)

        % construct Layer @Branch
        add_branch(obj,BranchInstance,from,to)
        replace_branch(obj,BranchInstance,i_branch)
        remove_branch(obj,i_branch)

        % construct Layer @GlobalController
        add_global_controller(obj, ConInstance, index_observe, index_input)
        replace_global_controler(obj,ConInstance,i_controller)
        remove_global_controller(obj,i_controller)

        % Set Lossy
        function assume_lossy(obj)
            for i = 1:numel(obj.Branches)
                obj.Branches{i}.isLossy = true;
            end
        end
        function assume_lossless(obj)
            for i = 1:numel(obj.Branches)
                obj.Branches{i}.isLossy = false;
            end
        end

        
        % OPF/PF 
        [zvec_V, zvec_I, flag, exitflag, output] = optimize_power_flow(obj,options); % 未実装
        [zvec_V, zvec_I, flag, exitflag, output] = calculate_power_flow(obj, options)
        
        % Calculate Equilibrium Point
        xst = set_equilibrium(obj,V,I,mode)
        
        % Calculate System Matrix
        sys = get_sys(obj, class_list,target_index)
        
        % Make Admittance Matrix
        [Ymat, GB] = get_admittance_matrix(obj, ivec_bus, ivec_branch)
        
        % initialize
        [flag,output,dataSheet] = initialize(obj,opt)

        % Dynamic Analysis 
        [out,sim] = simulate(obj, time, u, uidx, opt)

        % Network Information Management
        [data,Graph] = export(obj,options)

        % illustrate Graph
        [fig,G] = graph(obj,opt)
        
    
        % Get Method
        function c = get.children(obj)
            c = [obj.Buses; obj.Branches; obj.GlobalControllers];
        end
        function x = get.x_equilibrium(obj)
            x = tools.vcellfun(@(b) tools.vcellfun(@(c) c.x_equilibium, b.Components), obj.Buses);
        end
        function V = get.V_equilibrium(obj)
            V = tools.vcellfun(@(b) b.V_equilibrium, obj.Buses);
        end
        function I = get.I_equilibrium(obj)
            I = tools.vcellfun(@(b) b.I_equilibrium, obj.Buses);
        end
        function x = get.xbus_equilibrium(obj)
            x = tools.vcellfun(@(b) b.x_equilibium, obj.Buses);
        end
        function x = get.xbranch_equilibrium(obj)
            x = tools.vcellfun(@(b) b.x_equilibium, obj.Branches);
        end
        function x0 = get.xcg_equilibrium(obj)
            x0 = tools.vcellfun(@(c) c.x_equilibrium, obj.GlobalControllers);
        end
    end

    methods(Static)
        function doc(~)
            open("_Tutorial/Main.mlx")
        end
    end


end