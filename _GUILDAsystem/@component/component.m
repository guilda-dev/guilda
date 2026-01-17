classdef Component < GuildaLayer
% componentクラスの親クラス。
% GUILDA上に機器モデルを実装するために必要なmethodが定義されている。
% 新しい機器モデルを実装する場合はこのcomponentクラスを継承すること。
%
%           ┌----------┐
%  ┌---v--->|  BRANCH  |--->w--┐     
%  |        └----------┘       |     
%  |                           |
%  |                           |
%  |        ┌---------┐        | -
%  o---v<---|   Bus   |<---w---o     
%  |        └---------┘        | -
%  |                           | 
%  |                           |
%  |        ┌-----------┐      |
%  └---v--->|\\\\\\\\\\\|--->w-┘     v : V_BUS = [ ∠V ;  |V| ] or [ ∠V ;  log|V| ]
%           |\Component\|            w : I_BUS = [  P ; Q/|V|] or [  P ;      Q  ]
%  ┌---u--->|\\\\\\\\\\\|--->y-┐     u : input to component (e.g. Pmech,Vfield)
%  |        └-----------┘      |     y : output from component (e.g. Vabs,Efield)
%  |                           |
%  |                           | 
%  |                           |
%  |        ┌------------┐     |
%  └---u----| Controller |<--y-┘    
%           └------------┘          
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


%%%%%%%%%%%%%%%%
%%% Abstract %%%
%%%%%%%%%%%%%%%%
    methods(Abstract)
        [str_x, str_u, str_y] = name_xuy_vars(obj);
        [rvec_xst, rvec_ust, rvec_yst]  = calculate_equilibrium(obj, rvec_vst, rvec_wst);
        [Mass, svec_dx, svec_w, svec_y] = get_ODE_function(obj, sscl_t, svec_x, svec_v, svec_u, opt)
    end

%%%%%%%%%%%%%
%%% Layer %%%
%%%%%%%%%%%%%
    properties(Dependent,Access=protected)
        children (:,1) cell
    end
    properties(Dependent)
        Bus
        omega0
    end
    properties(SetAccess=protected)
        SpecificControllers (:,1) cell = {}; % generatorのavr,pssなどのために設けた。
        LocalControllers    (:,1) cell = {};
    end
    methods
        function c = get.children(obj)
            c = [obj.SpecificControllers;...
                 obj.LocalControllers]; 
        end
        function net = get.Bus(obj)
            net = obj.parent;
        end
        function w0 = get.omega0(obj)
            w0 = obj.Bus.omega0;
        end
    end

%%%%%%%%%%%%%%%%
%%% dynamics %%%
%%%%%%%%%%%%%%%%
    methods
        [sv_x, sv_v, sv_w, sv_u, sv_y] = get_ODE_vars(obj,lscl_flagtag)
        Fac = get_ODE(obj,opt)
    end

%%%%%%%%%%%%%%
%%% OPF/PF %%%
%%%%%%%%%%%%%%
    methods
        optim = get_OPF(obj,opt)
    end

%%%%%%%%%%%%%%%%%
%%% parameter %%%
%%%%%%%%%%%%%%%%%
    properties 
        isConnected (1,1) logical = true;
    end
    properties(Dependent)
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
    end

 
%%%%%%%%%%%%%%%%%%%
%%% Equilibrium %%%
%%%%%%%%%%%%%%%%%%%
    properties
        rateUscon (:,:) double
        rateUlcon (:,:) double
    end
    properties(SetAccess=protected)
        x_equilibrium
        u_equilibrium 
        y_equilibrium
    end
    properties(Dependent)
        v_equilibrium
        w_equilibrium
    end

    methods
        function set.rateUscon(obj,val)
            arguments
                obj 
                val double
            end
            rscl_uport = numel(obj.u_equilibrium)      ; %#ok
            rscl_scon  = numel(obj.SpecificControllers); %#ok
            assert(size(val,1)==rscl_uport, config.lang("行数は入力ポート数と一致する必要があります。","Row count must match the number of input ports."))
            assert(size(val,2)==rscl_scon , config.lang("列数はSpecificControllersの個数と一致する必要があります。","Column count must match the number of SpecificControllers."))
            obj.rateUscon = val;
            obj.onEdit("change rateUscon")
        end
        
        function set.rateUlcon(obj,val)
            arguments
                obj 
                val double
            end
            rscl_uport = numel(obj.u_equilibrium)      ; %#ok
            rscl_lcon  = numel(obj.LocalControllers); %#ok
            assert(size(val,1)==rscl_uport, config.lang("行数は入力ポート数と一致する必要があります。","Row count must match the number of input ports."))
            assert(size(val,2)==rscl_lcon , config.lang("列数はLocalControllersの個数と一致する必要があります。","Column count must match the number of LocalControllers."))
            obj.rateUlcon = val;
            obj.onEdit("change rateUlcon")
        end

        function val = get.v_equilibrium(obj)
            val = obj.Bus.v_equilibrium(:,obj.);
        end

        function val = get.w_equilibrium(obj)
            val = obj.Bus.w_equilibrium(:,obj.index);
        end

    end



%% 　ここから旧ver
    properties
        is_parallel = true;
        constraint  = "current";
    end
    
    properties(Dependent)
        area
        bus
        local_controllers

        x_equilibrium
        u_equilibrium
        y_equilibrium
        V_equilibrium
        I_equilibrium
    end
    
    methods
        function obj = component()
            obj.tag = "MAC";
            obj.InputType = "Add"; % "Add", "Rate", "Value"
            
            equilibrium.x = [];
            equilibrium.u = [];
            equilibrium.y = [];
            equilibrium.v = zeros(4,1);
            equilibrium.w = zeros(4,1);
            obj.equilibrium = equilibrium;
            
            b = bus.dammy();
            b.set_component(obj)
        end

        function w0 = get.omega0(obj)
            w0 = obj.area.omega0;
        end

    
        % equilibrium
            % Get method
            function val = get.x_equilibrium(obj)
                val = obj.equilibrium.x;
            end
            function val = get.u_equilibrium(obj)
                val = obj.equilibrium.u;
            end
            function val = get.y_equilibrium(obj)
                val = obj.equilibrium.y;
            end    
            function out = get.V_equilibrium(obj)
                Vvec = obj.equilibrium.v(1:2);
                out = Vvec(1)+1j*Vvec(2);
            end
            function out = get.I_equilibrium(obj)
                Ivec = obj.equilibrium.v(3:4);
                out = Ivec(1)+1j*Ivec(2);
            end

            % Set method 
            function set.x_equilibrium(obj, value)
                obj.equilibrium.x = value;
                obj.onEdit("edit x_equilibrium.");
            end
            function set.u_equilibrium(obj, value)
                obj.equilibrium.u = value;
                obj.editted("edit u_equilibrium.");
            end
            function set.y_equilibrium(obj, value)
                obj.equilibrium.y = value;
                obj.editted("edit y_equilibrium.");
            end
            function set.V_equilibrium(obj,value)
                obj.equilibrium.v(1:2) = [real(value);imag(value)];
                obj.equilibrium.w(1:2) = [real(value);imag(value)];
                obj.editted("edit V_equilibrium.");
            end
            function set.I_equilibrium(~,~)
                obj.equilibrium.v(3:4) = [real(value);imag(value)];
                obj.equilibrium.w(3:4) = [real(value);imag(value)];
                obj.editted("edit I_equilibrium.");
            end

            % general 
            function [xst,ust,yst] = set_equilibrium(obj,Veq,Ieq)
                [xst, ust, yst] = obj.get_equilibrium(Veq,Ieq);
                VI  = [real(Veq);imag(Veq);real(Ieq);imag(Ieq)];
                obj.equilibrium = struct('x',xst,'u',ust,'y',yst,'v',VI,'w',VI);
                obj.system_matrix = ss([]);
                obj.unEdit;
            end
            function [xst,ust,yst] = get_equilibriuim(~,~,~)
                xst = [];
                ust = [];
                yst = [];
            end


        % child/parents
            % Get method 
            function out = get.area(obj)
                out = obj.bus.area;
            end
            function out = get.bus(obj)
                out = obj.parents{1};
            end
            function out = get.local_controllers(obj)
                out = obj.children;
            end
            % Set method
            function add_controller(obj,c)
                assert(isa(c,'controller'),'Not a "controller" class')
                c.set_parents(obj,'overwrite')
                obj.set_children(component,'append')
                obj.onEdit('change component.')
            end
            function remove_controller(obj,varargin)
                obj.remove_children(varargin{:})
            end


        % Set differential/output/input function
            set_function(obj)
    
        % for check requirment / debug 
            dx   = check_dx(obj)
            flag = check_requirment(obj);
    end
end




