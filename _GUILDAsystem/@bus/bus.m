classdef Bus < GuildaLayer
% 母線を定義するスーパークラス
% 'bus_PV'と'bus_PQ','bus_slack'を子クラスに持つ。
%
%           ┌----------┐
%  ┌---v--->|          |--->w--┐     
%  |        |  BRANCH  |       |     
%  |        |          |       |     
%  |        └----------┘       |    
%  |                           |
%  |                           |
%  |        ┌---------┐        |-
%  o---v<---|/////////|<---w---o     v : V_BUS = [ ∠V ;  |V| ] or [ ∠V ;  log|V| ]
%  |        |///Bus///|        |-    w : I_BUS = [  P ; Q/|V|] or [  P ;      Q  ]
%  |        |/////////|        |     
%  |        └---------┘        |     
%  |                           | 
%  |                           |
%  |        ┌-----------┐      |
%  └---v--->|           |--->w-┘    
%           | Component |           
%      u--->|           |--->y      
%           └-----------┘
%
%
%  << 親クラスからの継承プロパティ >>
%
%     prop         class      description
%==========================================================================
%   ・parent   |LayerPackage| 階層構造の上位層にあたるLayerPackageクラス
%   ・parent   |    cell    | 階層構造の下位層にあたるLayerPackageクラス
%   ・tag      |   string   | クラスの呼称
%   ・index    |   double   | インデックス番号、tagともにクラスの命名に使用
%   ・parameter|   table    | ユーザが設定する定数は全てこのプロパティで管理
%   ・editFlag |  logical   | 変更が加えられたかどうかの管理simulate前などに確認
%   ・editLog  |   table    | 変更内容を「変更時間・対象クラス・変更内容」で管理
%==========================================================================
% 
% 
%  << クラス内で定義するプロパティ >>
%     prop               class      description
%==========================================================================
%   ・Components    (:,1) cell    : componentクラスを格納するcell配列
%   ・shunt         (1,2) double  : シャント値[実部,虚部]
%   ・omega0        (1,1) double  : 系統周波数 60x2pi
%   ・parameter     (1,:) table   : 列名(潮流設定とシャント値)Vabs,Varg,P,Q,shuntG,shuntB
%   ・isFault       (1,1) logical : 地絡が起きている場合はtrue
%   ・x_equilibrium (2,1) double  : 状態の平衡点  >>  [∠V;|V|] or [∠V;log|V|]
%   ・v_equilibrium (2,1) double  : 出力の平衡点  >>  [∠V;|V|] or [∠V;log|V|]
%   ・w_equilibrium (2,1) double  : 入力の平衡点  >>  [ P;Q/V] or [ P; Q]
%   ・V_equilibrium (1,1) double  : 定常潮流状態の複素電圧
%   ・I_equilibrium (1,1) double  : 定常潮流状態の複素電流
%   ・ratePcomp     (:,1) double  : 各componentクラスの有効電力の比率
%   ・rateQcomp     (:,1) double  : 各componentクラスの無効電力の比率
%   ・mode_OPFconst (1,:)string   : OPFの制約条件のモード (string配列として複数選択可)
%                                 ・電圧絶対値( 0.95 < |V|/|Vst| < 1.05) --> "P"
%

    methods
        function obj = Bus(shunt)
            arguments
                shunt (1,2) double = [0,0];
            end
            obj.shunt     = shunt;
            obj.tag       = "Bus";
            obj.parameter = array2table([nan(1,4),zeros(1,2)],"VariableNames",["theta","absV","P","Q","shuntG","shuntB"]);
            obj.add_component(component.Empty());
        end
    end

%%%%%%%%%%%%%%%%
%%% Abstract %%%
%%%%%%%%%%%%%%%%
    methods(Abstract)
        [svec_x, rvec_x0, svec_V,  svec_P, svec_Q ] = generate_PF_constraint(obj)
    end

%%%%%%%%%%%%%
%%% Layer %%%
%%%%%%%%%%%%%
    properties(Dependent,Access=protected)
        children (:,1) cell
    end
    properties(SetAccess=protected)
        Components
    end
    methods
        function c = get.children(obj)
            c = obj.Components;
        end
        function add_component(obj,CompInstance)
            arguments
                obj 
                CompInstance (1,1) Component
            end
            idx = numel(obj.Components)+1;
            CompInstance.born(obj,idx)
            obj.Components = [obj.Components; {CompInstance}];
            obj.ratePcomp = ones(idx,1)/idx;
            obj.rateQcomp = ones(idx,1)/idx;
            obj.onEdit("add Component")
        end
        function set_component(obj,CompInstance)
            arguments
                obj 
                CompInstance (1,1) Component
            end
            CompInstance.born(obj,1)
            obj.Components{1} = CompInstance;
            obj.onEdit("set Component")
        end
        function replace_component(obj,CompInstance,index)
            arguments
                obj 
                CompInstance (1,1) Component
                index        (1,1) double {mustBeInteger,mustBePositive} = 1;
            end
            CompInstance.born(obj,index)
            cellfun(@(c) CompInstance.add_local_controller(c), obj.Components.LocalCOntrollers)
            obj.Components{index} = CompInstance;
            obj.onEdit("replace Component"+index)
        end
    end
        

%%%%%%%%%%%%%%%%
%%% dynamics %%%
%%%%%%%%%%%%%%%%
    properties(SetAccess=protected)
        simset
    end
    methods
        [sv_x, sv_v, sv_w] = get_ODE_vars(obj,lscl_flagtag)
        Fac = odeget(obj,opt)
        odeset(obj,opt)
    end

%%%%%%%%%%%%%%
%%% OPF/PF %%%
%%%%%%%%%%%%%%
    methods
        Fac = get_OPF(obj,opt)
    end

%%%%%%%%%%%%%%%%%
%%% parameter %%%
%%%%%%%%%%%%%%%%%
    properties
        isFault   (1,1) ligical = false;
    end
    properties(Dependent)
        shunt
        omega0
    end
    methods
        function flag = validate_params(obj,params)
            arguments
                obj 
                params (1,:) table 
            end
            varnames_old = string(obj.parameter.Properties.VariableNames);
            varnames_new = string(params.Properties.VariableNames);
            flag = all(varnames_old==varnames_new);
            assert(flag,config.lang("parameterの変数名が間違っています。","The variable name for parameter is incorrect."))
        end
        function set.isFault(obj,val)
            arguments
                obj 
                val (1,1) logical = obj.isFault;
            end
            if obj.isFault~=val
                obj.isFault = val;
                if val
                    obj.onEdit("fault occurred")
                else
                    obj.onEdit("fault release")
                end
            end
        end
        function set.shunt(obj,shunt)
            arguments
                obj 
                shunt (1,2) double = [0,0]; 
            end
            obj.parameter.shuntG = shunt(1);
            obj.parameter.shuntB = shunt(2);
            obj.onEdit("edit shunt")
        end
        function val = get.shunt(obj)
            val = [obj.parameter.shuntG, obj.parameter.shuntB];
        end
        function w0 = get.omega0(obj)
            w0 = obj.parent.omega0; 
        end
    end
 
%%%%%%%%%%%%%%%%%%%
%%% Equilibrium %%%
%%%%%%%%%%%%%%%%%%%
    properties
        Default_P_distribution
        Default_Q_distribution
    end
    properties(SetAccess=protected)
        V_equilibrium (1,1) double = 1;
        I_equilibrium (1,1) double = 0;
        Icomp_equilibrium (:,1) double = 0;
        Pcomp_equilibrium (:,1) double = 0;
        Qcomp_equilibrium (:,1) double = 0;
    end
    properties(Dependent)
        x_equilibrium 
        v_equilibrium
        w_equilibrium
    end
    methods
        set_equilibrium(obj,data)
        
        function set.ratePcomp(obj,val)
            arguments
                obj 
                val (:,1) double
            end
            rscl_dim = numel(obj.Components); %#ok
            assert(numel(val)==rscl_dim, config.lang("変数は"+rscl_dim+"次元である必要があります。","Variables must be in the "+rscl_dim+" dimension."))
            obj.ratePcomp = val;
            obj.onEdit("change ratePcomp")
        end
        
        function set.rateQcomp(obj,val)
            arguments
                obj 
                val (:,1) double
            end
            rscl_dim = numel(obj.Components); %#ok
            assert(numel(val)==rscl_dim,config.lang("変数は"+rscl_dim+"次元である必要があります。","Variables must be in the "+rscl_dim+" dimension."))
            obj.rateQcomp = val;
            obj.onEdit("change rateQcomp")
        end

        function val = get.P_equilibrium(obj)
            PQ  = obj.V_equilibrium * conj(obj.I_equilibrium);
            val = [real(PQ);imag(PQ)];
        end

        function x = get.x_equilibrium(obj)
            x = obj.v_equilibrium;
        end

        function x = get.v_equilibrium(obj)
            switch config.systemFunc.get("dynamics","port_vw","Value")
            case "absV to Q/V"; x = [ angle(obj.V_equilibrium); abs(obj.V_equilibrium) ];
            case "logV to Q"  ; x = [ angle(obj.V_equilibrium); log(abs(obj.V_equilibrium)) ];
            end
        end
        function w = get.w_equilibrium(obj)
            switch config.systemFunc.get("dynamics","port_vw","Value")
            case "absV to Q/V"; w = obj.S_equilibrium./[1;abs(obj.V_equilibrium)];
            case "logV to Q"  ; w = obj.S_equilibrium;
            end
        end
    end
end

