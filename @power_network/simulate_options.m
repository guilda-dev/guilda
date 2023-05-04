function options = simulate_options(obj, t, u, uidx, varargin)

x0_con_local = tools.vcellfun(@(c) c.get_x0(), obj.a_controller_local);
x0_con_global = tools.vcellfun(@(c) c.get_x0(), obj.a_controller_global);

p = inputParser;
p.CaseSensitive = false;
addParameter(p, 'linear'        , false);
addParameter(p, 'fault'         , struct('time',[0,0],'bus',[]));
addParameter(p, 'u'             , []);
addParameter(p, 'x0_sys'        , obj.x_equilibrium);
addParameter(p, 'V0'            , obj.V_equilibrium);
addParameter(p, 'I0'            , obj.I_equilibrium);
addParameter(p, 'x0_con_local'  , x0_con_local);
addParameter(p, 'x0_con_global' , x0_con_global);
addParameter(p, 'AbsTol'        , 1e-8);
addParameter(p, 'RelTol'        , 1e-8);
addParameter(p, 'do_report'     , true);
addParameter(p, 'reset_time'    , inf);
addParameter(p, 'do_retry'      , true);
addParameter(p, 'OutputFcn'     , []); %'live_grid_code'と指定した場合，機器の接続状況をライブする。
addParameter(p, 'tools'         , true);
addParameter(p, 'method'        , 'zoh'   , @(method) ismember(method, {'zoh', 'foh'}));
addParameter(p, 'grid_code'     , 'ignore', @(method) ismember(method, {'ignore', 'monitor', 'control'}));

parse(p, varargin{:});
options = p.Results;


options.fault    = organize_fault(options.fault);
options.u        = organize_u(obj,t,u,uidx,options.u);
options.OutputFcn= organize_OutputFcn(obj,options.OutputFcn);

end

function out_fault = organize_fault(fault)
    switch class(fault)
        case 'cell'
            out_fault = struct('time',[0,0],'bus',[]);
            for i = 1:numel(fault)
                out_fault(i).time = fault{i}{1}(:).';
                out_fault(i).bus  = fault{i}{2}(:).';
            end
        case 'struct'
            out_fault = fault;
        case 'table'
            out_fault = table2struct(fault);
        otherwise
            out_fault = struct('time',[0,0],'bus',[]);
    end
end


function u_ = organize_u(net,t,u,u_idx,u_option)
    u_ = [];
    if ~isempty(u_idx)
        nu = 0;
        u_ = struct;
        for i = 1:numel(u_idx)
           idx = u_idx(i);
           nui = net.a_bus{idx}.component.get_nu;
           u_(i).bus  = idx;
           u_(i).time = t;
           u_(i).u    = u(nu+(1:nui),:);
           nu = nu + nui;
        end
    end
    if ~isempty(u_option)
        u_ = [u_option(:),u_(:)];
    end
end

function OutputFcn = organize_OutputFcn(net,Fcn,unistate)
    if nargin<3
        unistate = unique(tools.hcellfun(@(b) b.component.get_state_name, net.a_bus));
    end

    OutputFcn = struct('Gridcode',[],'Response',[],'other',[]);

    if iscell(Fcn)
        for i = 1:numel(Fcn)
            temp = organize_OutputFcn(net,Fcn{i},unistate);
            OutputFcn.Response = unique([OutputFcn.Response, temp.Response]);
            OutputFcn.Gridcode = unique([OutputFcn.Gridcode, temp.Gridcode]);
            OutputFcn.other    = unique([OutputFcn.other   , temp.other   ]);
        end 
        return
    end

    if ischar(Fcn)
        if ismember(Fcn,unistate)
            OutputFcn.Response = {Fcn};
        elseif ismember(Fcn,{'GridCode','grid_code','gridcode'})
            n(1) = numel(net.a_bus);
            n(2) = numel(net.a_branch);
            n(3) = numel(net.a_controller_local)+numel(net.a_controller_global);
            list = {'component','branch','controller'};
            OutputFcn.Gridcode = list(n>0);
        end
    elseif isa(Fcn,'function_handle')
        OutputFcn.other = {Fcn};
    end
end