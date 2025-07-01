classdef Branch < LayerPackage
% 送電網を定義するスーパークラス
% 'branch_pi'と'branch_pi_transfer'を子クラスに持つ。
%
%           ┌----------┐
%  ┌---v--->|\\\\\\\\\\|--->w--┐     v : V_BUS = [ ∠V ;  |V| ] or [ ∠V ;  log|V| ]
%  |        |\\BRANCH\\|       |     w : I_BUS = [  P ; Q/|V|] or [  P ;      Q  ]
%  |        |\\\\\\\\\\|       |     
%  |        └----------┘       |     
%  |                           |
%  |                           |
%  |        ┌---------┐        |-
%  o---v<---|         |<---w---o     
%  |        |   Bus   |        |-    
%  |        |         |        |     
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
%  << 本クラス内での定義プロパティ >>
%
%     prop             class          description
%==========================================================================
%   ・network         | PowerNetwork| parentを参照するDependent
%   ・omega0          | double      | networkのomegaを参照するDependent
%   ・lineImpedance   | double      | parameterのデータから計算されるDependent
%   ・lineAdmittance  | double      | networkのomegaを参照するDependent
%   ・earthCapacitance| double      | networkのomegaを参照するDependent
%   ・x_equilibrium   | double      | 
%   ・v_equilibrium   | double      | 
%   ・w_equilibrium   | double      | 
%   ・V_equilibrium   | double      | 
%   ・I_equilibrium   | double      | 
%   ・from            | double      | 
%   ・to              | double      | 
%   ・isValid         | logical     | 
%   ・isConnected     | logical     | 
%   ・isLossy         | logical     | 
%   ・isStatics       | logical     | 
%==========================================================================



    properties(Dependent)
        from
        to

        network
        omega0
        lineImpedance
        lineAdmittance
        earthCapacitance
        
        x_equilibrium 
        v_equilibrium
        w_equilibrium

        V_equilibrium
        I_equilibrium
        isValid
    end

    properties 
        isConnected (1,1) logical = true;
        isLossy     (1,1) logical = true;
        isStatic    (1,1) logical = true;
    end
    
    properties(Dependent,Access=protected)
        children (:,1) cell
    end

    properties(Access=protected)
        Buses (2,1) cell = {bus.empty,bus.empty};
    end

    methods(Abstract)
        y = get_admittance_matrix(obj);
    end


    methods
        % Constractor
        function obj = Branch(xij, cij, from, to)
            arguments
                xij  (1,2) double = [0,1];
                cij  (1,1) doucle = 0;
                from (1,1) double {mustBeNonnegative, mustBeInteger} = 0;
                to   (1,1) double {mustBeNonnegative, mustBeInteger} = 0;
            end
            obj.from = from;
            obj.to   = to;
            obj.tag  = 'Line';
            obj.parameter = array2table([xij,cij,nan,nan,inf],"VariableNames",["xreal","ximag","c","tap","phase","Pmax"]);
        end

        % Layer
        connect_bus(obj,from,to)

        % dynamics 
        [svec_x, svec_v, svec_w] = get_ODE_vars(obj,lscl_flagtag)
        [Mass, svec_x, svec_v, svec_w, svec_func_dx,  svec_func_w] = generate_ODE_dynamics(obj)

        % OPF/PF
        optim = generate_OPF_problem(obj,opt)
    

    %% GET METHOD
        function idx = get.from(obj)
            idx = obj.Buses{1}.index;
        end
        function idx = get.to(obj)
            idx = obj.Buses{2}.index;
        end
        function net = get.network(obj)
            net = obj.parent;
        end
        function w0 = get.omega0(obj)
            w0 = obj.network.omega0; 
        end
        function yij = get.lineAdmittance(obj)
            if ~obj.isConnected
                yij = 0;
                return
            end
            p = obj.parameter{:,["xreal","ximag"]};
            yij = 1/(p(1)+1j*p(2));
            if ~obj.isLossy
                yij = yij - real(yij);
            end
        end
        function zij = get.lineImpedance(obj)
            zij = 1/obj.lineAdmittance;
        end
        function cij = get.earthCapacitance(obj)
            if ~obj.isConnected
                cij = 0;
                return
            end
            cij = 1j * obj.parameter.c;
            if ~obj.isLossy
                cij = cij - real(cij);
            end
        end
        function x = get.x_equilibrium(obj)
            if obj.isStatic
                x = [];
            else
                Iconj = obj.I_equilibrium';
                Ivec  = [imag(Iconj); real(Iconj)];
                x     = Ivec(:);
            end
        end        
        function v = get.v_equilibrium(obj)
            v = tools.vcellfun(@(b) b.v_equilibrium, obj.Buses);
        end
        function w = get.w_equilibrium(obj)
            Ist  = obj.I_equilibrium';
            switch config.systemFunc.get("dynamics","port_vw","Value");
                case "[theta,V] to [P,Q/V]"
                    Vst   = obj.V_equilibrium.';
                    PQst  = Vst .* Ist;
                    PQvec = [ real(PQst); imag(PQst)./abs(Vst) ];
                    w     = PQvec(:);
                case "[theta,logV] to [P,Q]"
                    PQst  = obj.V_equilibrium.' .* Ist;
                    PQvec = [ real(PQst); imag(PQst) ];
                    w     = PQvec(:);
                case "[Vre,Vim] to [-Iim,Ire]"
                    Ivec  = [imag(Ist); real(Ist)];
                    w     = Ivec(:);
            end
        end
        function V = get.V_equilibrium(obj)
            V = tools.vcellfun(@(b) b.V_equilibrium, obj.Buses);
        end
        function I = get.I_equilibrium(obj)
            Y = obj.get_admittance_matrix;
            I = Y*obj.V_equilibrium; 
        end
        function flag = get.isValid(obj)
            flag = all(tools.hcellfun(@(b) b.isValid), obj.Buses);
        end
        function c = get.children(~)
            c= {}; 
        end


    %% SET METHOD
        % mode
        function set.isConnected(obj,val)
            arguments
                obj 
                val (1,1) logical = obj.isConnected
            end
            if obj.isConnected~=val
                obj.isConnected = val;
                if val
                    obj.onEdit("parallel on")
                else
                    obj.onEdit("parallel off")
                end
            end
        end
        function set.isLossy(obj,val)
            arguments
                obj 
                val (1,1) logical = obj.isLossy
            end
            if obj.isLossy~=val
                obj.isLossy = val;
                if val
                    obj.onEdit("lossy")
                else
                    obj.onEdit("lossless")
                end
            end
        end
        function set.isStatic(obj,val)
            arguments
                obj 
                val (1,1) logical = obj.isStatic
            end
            if obj.isStatic~=val
                obj.isStatics = val;
                if val
                    obj.onEdit("get to Static")
                else
                    obj.onEdit("get to Dynamic")
                end
            end
        end

        % parameter
        function set.lineImpedance(obj,zij)
            arguments
                obj 
                zij (1,1) double 
            end
            obj.parameter{:,["xreal","ximag"]} = [real(zij),imag(zij)];
        end
        function set.lineAdmittance(obj,yij)
            obj.lineImpedance = 1/yij;
        end
        function set.earthCapacitance(obj,cij)
            arguments
                obj 
                cij (1,1) double
            end
            obj.parameter{:,"c"} = cij/1j;
        end
    end
    
    
end

