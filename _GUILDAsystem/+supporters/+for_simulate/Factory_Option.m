classdef Factory_Option < handle
    
    properties
        % 入力データ
        time
        network
        options

       % 加工データ
       timelist

        
        % 役割分担
        branch_fault
        branch_input
        branch_parallel_mac
        branch_parallel_cl
        branch_parallel_cg
        
        % OutputFcn
        reporter
      
    end

    methods
        function obj = Factory_Option(t,net,varargin)
            obj.time = t;
            obj.network = net;
    
            x0_con_local  = tools.vcellfun(@(c) c.get_x0(), net.a_controller_local );
            x0_con_global = tools.vcellfun(@(c) c.get_x0(), net.a_controller_global);
            
            p = inputParser;
            p.CaseSensitive = false;
            
            % linear/nolinear simulation
                addParameter(p, 'linear'           , false);
            % fault setting
                addParameter(p, 'fault'            , []);
            % Set input signal 
                addParameter(p, 'u'                , []);
                addParameter(p, 'method'           , 'zoh'   );
            % Set the condition for parallel on/off
                addParameter(p, 'parallel'         , struct('time',[t(1),t(end)],'index',1:numel(net.a_bus),'parallel','on'));
                addParameter(p, 'switch_con_local' , struct('time',[t(1),t(end)],'index',1:numel(net.a_controller_local) ,'switch','on'));
                addParameter(p, 'switch_con_global', struct('time',[t(1),t(end)],'index',1:numel(net.a_controller_global),'switch','on'));
            % Set initial state value
                addParameter(p, 'V0'               , net.V_equilibrium);
                addParameter(p, 'I0'               , net.I_equilibrium);
                addParameter(p, 'x0_sys'           , net.x_equilibrium);
                addParameter(p, 'x0_con_local'     , x0_con_local);
                addParameter(p, 'x0_con_global'    , x0_con_global);
            % when simulation take a long time, whether continue or not 
                addParameter(p, 'reset_time'       , inf);
                addParameter(p, 'do_retry'         , true);
            % Whether to consider grid codes in simulations
                addParameter(p, 'grid_code'        , 'ignore', @(method) ismember(method, {'ignore', 'monitor', 'control'}));
            % Simulation setup (basically no need to tinker with it)
                addParameter(p, 'tools_readme'     , false);
                addParameter(p, 'do_report'        , true);
                addParameter(p, 'OutputFcn'        , []); %'live_grid_code'と指定した場合，機器の接続状況をライブする。
            % option for ode solver 
                addParameter(p, 'AbsTol'           , 1e-8);
                addParameter(p, 'RelTol'           , 1e-8);
                addParameter(p, 'MaxOrder'         , 5); % 1~5
            
            parse(p, varargin{:});
            op = p.Results;
            obj.options = op;
   
            obj.reporter= supporters.for_simulate.Factory_Reporter(t, obj.network, op);

        end

        function [x0sys,x0cl,x0cg,V0,I0,V0vir] = get_initialVal(obj)
            x0sys = obj.options.x0_sys;
            x0cl  = obj.options.x0_con_local;
            x0cg  = obj.options.x0_con_global;
            V0    = tools.complex2vec(obj.options.V0);
            I0    = tools.complex2vec(obj.options.I0);
            V0vir = zeros(size(V0));
        end

        function fbus = get_bus(obj,type)
            switch type
                case 'I0const'
                    fbus = @(t) find(obj.branch_parallel_mac.apply(t));
                case 'V0const'
                    [ftime,ftab] = obj.branch_fault.timetable;
                    fbus = @(t) find(ftab{:,find(ftime<=t,1,'last')})';
                case 'parallel'
                    [ftime,ftab] = obj.branch_parallel_mac.timetable;
                    fbus = @(t) find(ftab{:,find(ftime<=t,1,'last')})';
                case 'input'
            end
        end

        function fdata = get_ufunc(obj)
            fdata = @(tlim) obj.branch_input.get_ufunc(tlim);
        end

        function initialize(obj)
            t   = obj.time;
            op  = obj.options;
            net = obj.network;

            obj.branch_fault        = supporters.for_simulate.option.fault(   net, t, op.fault);
            obj.branch_input        = supporters.for_simulate.option.input(   net, t, op.u);
            obj.branch_parallel_mac = supporters.for_simulate.option.parallel(net, t, op.parallel);
            %branch_parallel_cl  =
            %branch_parallel_cg  = 
            
            tlist = obj.broadcast('timelist');
            obj.timelist = unique(horzcat(tlist{:}),'sorted');
        end
        

        function out = broadcast(obj,func,varargin)
            prop = {'fault','input','parallel_mac'};
            out = tools.cellfun(@(p) obj.(['branch_',p]).(func)(varargin{:}),prop);
        end

        function odeopt = get_odeoption(obj,varargin) 
            odeopt   = odeset(...
                       ...%'Events'   , Event,...
                      'RelTol'   , obj.options.RelTol  , ...
                      'AbsTol'   , obj.options.AbsTol  , ...
                      'MaxOrder' , obj.options.MaxOrder, ...
                      'OutputFcn', @(t, y, flag) obj.reporter.report(t, y, flag, obj.options.reset_time, datetime),...
                      varargin{:});
        end


    end

end



