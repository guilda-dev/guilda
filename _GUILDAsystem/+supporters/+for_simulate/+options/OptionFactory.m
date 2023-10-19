classdef OptionFactory < handle

    properties
        current_time
        tlim
    end

    properties(SetAccess=protected)
        solver_class

        %各オプションの管理クラスを格納
        fault
        input
        parallel
        gridcode
        OutputFcn
        reporter
        
        %各オプションのデータを格納
        islinear
        initial
        odeoptions
        readme
    end
    
    properties(Access=protected,Dependent)
        network
    end

    methods
        function obj = OptionFactory(solver,t,uidx,u,varargin)
            obj.solver_class = solver;
            obj.tlim = [min(t),max(t)];

            net = obj.network;
            
            p = inputParser;
            p.CaseSensitive = false;
            % linear/nolinear simulation
                addParameter(p, 'linear'           , false);
            % fault setting
                addParameter(p, 'fault'            , []);
            % Set input signal 
                addParameter(p, 'u'                , []);
                addParameter(p, 'method'           , 'zoh');
            % Set the condition for parallel on/off
                addParameter(p, 'parallel_component' , []);
                addParameter(p, 'parallel_branch'    , []);
                addParameter(p, 'parallel_con_local' , []);
                addParameter(p, 'parallel_con_global', []);
                addParameter(p, 'simulate_disconncted_mac', true);
            % Set initial state value
                addParameter(p, 'V0'               , net.V_equilibrium);
                addParameter(p, 'I0'               , net.I_equilibrium);
                addParameter(p, 'x0_sys'           , net.x_equilibrium);
                addParameter(p, 'x0_con_local'     , tools.vcellfun(@(c) c.get_x0(), net.a_controller_local ));
                addParameter(p, 'x0_con_global'    , tools.vcellfun(@(c) c.get_x0(), net.a_controller_global));
            % Whether to consider grid codes in simulations
                addParameter(p, 'grid_code'        , 'ignore', @(method) ismember(method, {'ignore', 'interruption', 'monitor', 'control'}));
            % Simulation setup (basically no need to tinker with it)
                addParameter(p, 'tools_readme'     , false   , @(val) islogical(val) );
            % when simulation take a long time, whether continue or not 
                addParameter(p, 'reset_time'       , inf     , @(val) isnumeric(val) );
                addParameter(p, 'do_retry'         , true    , @(val) islogical(val) );
                addParameter(p, 'report'           , 'dialog', @(method) ismember(method, {'none', 'cmd', 'dialog'}));
                addParameter(p, 'OutputFcn'        , []); %'live_grid_code'と指定した場合，機器の接続状況をライブする。
            % option for ode solver 
                addParameter(p, 'AbsTol'           , 1e-8);
                addParameter(p, 'RelTol'           , 1e-8);
                addParameter(p, 'MaxOrder'         , 5); % 1~5
            
            parse(p, varargin{:});
            op = p.Results;


            obj.islinear   = op.linear;
            
            obj.readme = op.tools_readme;

            obj.odeoptions = odeset(...
                    'RelTol'      , op.RelTol  , ...
                    'AbsTol'      , op.AbsTol  , ...
                    'MaxOrder'    , op.MaxOrder, ...
                    'MassSingular','yes'       );

            obj.initial = struct(...
                    'sys', op.x0_sys        ,...
                    'cl' , op.x0_con_local  ,...
                    'cg' , op.x0_con_global ,...
                    'V0' , op.V0            ,...
                    'I0' , op.I0            );

            obj.fault     = supporters.for_simulate.options.fault(obj,t,op.fault);
            obj.parallel  = supporters.for_simulate.options.parallel(obj,t,op);
            obj.input     = supporters.for_simulate.options.input(obj,t,uidx,u,op);
            
            % 開発中
            %obj.gridcode  = supporters.for_simulate.reporter.GridCode_checker;
            %obj.OutputFcn = supporters.for_simulate.reporter.Response_reporter;
            %obj.reporter  = supporters.for_simulate.Factory_Reporter(obj.tlim, op.report); 

            obj.current_time = t(1);
        end

        function net = get.network(obj)
            net = obj.solver_class.network;
        end

        function set.current_time(obj,t)
            obj.current_time = t;
            obj.fault.current_time    = t; %#ok
            obj.input.current_time    = t; %#ok
            obj.parallel.current_time = t; %#ok
        end
        
        function out = get_bus_list(obj,type)
            switch type
                case 'I0const'
                    out = obj.parallel.get_bus_list;
                case 'V0const'
                    out = obj.fault.get_bus_list;
                case 'input'
                    out = obj.input.get_bus_list;
            end
        end

        function out = get_next_tend(obj,t)
            f = obj.fault.get_next_tend(t);
            i = obj.input.get_next_tend(t);
            p = obj.parallel.get_next_tend(t);
            out = min([f,i,p,obj.tlim(end)]);
        end

        function option = export_option(obj)
            popt = obj.parallel.export_option;
            option = struct(...
                'linear', obj.islinear                 ,...
                'fault' , obj.fault.export_option      ,...
                'u'     , obj.input.export_option      ,...
                'V0'    , obj.initial.V0               ,...
                'I0'    , obj.initial.I0               ,...
                'x0_sys', obj.initial.sys              ,...
                'x0_con_local' , obj.initial.con_local ,...
                'x0_con_global', obj.initial.con_global,...
                'parallel_component' , popt.mac        ,...
                'parallel_branch'    , popt.baranch    ,...
                'parallel_con_local' , popt.con_local  ,...
                'parallel_con_global', popt.con_global ,...
                'grid_code'   , obj.gridcode.mode      ,...
                'tools_readme', obj.readme             ,...
                'reset_time'  , obj.reporter.reset_time,...
                'do_retry'    , obj.reporter.do_retry  ,...
                'report'      , obj.reporter.mode      ,...
                'OutputFcn'   , obj.OutputFcn.mode     ,...
                'AbsTol'      , obj.odeoptions.AbsTol  ,...
                'RelTol'      , obj.odeoptions.RelTol  ,...
                'MaxOrder'    , obj.odeoptions.MaxOrder ...
                );
        end

    end

    methods(Access=protected)
        function editted(obj)
            obj.solver_class.ToBeStop = true;
        end
    end

end



