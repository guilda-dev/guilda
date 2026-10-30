function sys = get_sys(obj, opt)
% <@Desc>
% Linear model of the bus: its components (with their local controllers) connected at
% the bus.
%   inputs : the port (bus voltage [Vre; Vim] for port "V2I", the current [Ire; Iim]
%            injected by the components for "I2V"), then the inputs of each component
%            and of its controllers (as comp.get_sys)
%   states : the states of the components and their controllers
%   outputs: the other port, then the outputs of each component and of its controllers
% The states are not outputs, so that every name is unique (see comp.get_sys).
% Point gives the point of the linearization in the same form as net.linearize: [] for
% the equilibrium, a vector in the order of bus.get_variable_map(), or {sim, t}.
% The model is not changed.
% <@Role> Static Analysis
% <@Summary> Linear model of the bus (V to I, or I to V).
% <@Signatures>
% [
%   "sys = bus.get_sys()",
%   "sys = bus.get_sys(port=\"I2V\", Point=x)"
% ]
% <@Parameters>
% [
%   {"Name": "port", "Type": "\"V2I\" | \"I2V\"", "Description": "Input and output ports.", "Required": false, "Default": "\"V2I\""},
%   {"Name": "Point", "Type": "[] | double vector | cell {sim, t}", "Description": "Point of the linearization.", "Required": false, "Default": "[] (the equilibrium)"}
% ]
% <@Returns>
% [
%   {"Name": "sys", "Type": "ss", "Description": "Descriptor state-space model with state, input and output names."}
% ]
    arguments
        obj 
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"
        opt.full (1,1) logical = false     % ignored (kept for old calls): the states are not outputs
        opt.con  (1,1) logical = false     % ignored (kept for old calls)
        opt.Point = []
    end

    if isempty(opt.Point) && ~iscell(opt.Point)
        sys = tools.cellfun(@(c) c.get_sys("port", "V2I"), obj.a_Component);
    else
        rv_point  = odeLinearizer.point_vector(obj, opt.Point);
        [~, c_idx] = obj.get_variable_map();
        sys = cell(size(obj.a_Component));
        for j = 1:numel(obj.a_Component)
            sys{j} = obj.a_Component{j}.get_sys("port", "V2I", "Point", rv_point(c_idx{j}));
        end
    end
    if isempty(sys)     % no components: no states, and the bus takes no current (I = 0)
        sys = {ss(zeros(0), zeros(0,2), zeros(2,0), zeros(2))};
        sys{1}.InputName  = {'Vre';'Vim'};
        sys{1}.OutputName = {'Ire';'Iim'};
    end

    % Each component model: inputs [V; u], outputs [I; y]
    Ax  = tools.cellfun(@(ss) ss.A                 , sys);
    Bv  = tools.cellfun(@(ss) ss.B(:,1:2)          , sys);
    Bu  = tools.cellfun(@(ss) ss.B(:,3:end)        , sys);
    Cx  = tools.cellfun(@(ss) ss.C(1:2,:)          , sys);
    Dv  = tools.cellfun(@(ss) ss.D(1:2,1:2)        , sys);    
    Du  = tools.cellfun(@(ss) ss.D(1:2,3:end)      , sys);    
    Cy  = tools.cellfun(@(ss) ss.C(3:end,:)        , sys);
    Dyv = tools.cellfun(@(ss) ss.D(3:end,1:2)      , sys);    
    Dyu = tools.cellfun(@(ss) ss.D(3:end,3:end)    , sys);    

    E = tools.cellfun(@(ss) ss.E, sys);

    StateNames  = tools.cellfun(@(ss) string(ss.StateName)        , sys);
    InputNames  = tools.cellfun(@(ss) string(ss.InputName(3:end))  , sys);
    OutputNames = tools.cellfun(@(ss) string(ss.OutputName(3:end)) , sys);

    Vport = arrayfun(@(str) obj.attach_tag(str), ["Vre";"Vim"]);
    Iport = arrayfun(@(str) obj.attach_tag(str), ["Ire";"Iim"]);

    Bv_all  = vertcat(Bv{:});
    Bu_all  = blkdiag(Bu{:});
    Cx_all  = horzcat(Cx{:});
    Dv_sum  = sum( cat(3,Dv{:}),3 );
    Du_all  = horzcat(Du{:});
    Cy_all  = blkdiag(Cy{:});
    Dyv_all = vertcat(Dyv{:});
    Dyu_all = blkdiag(Dyu{:});
    
    switch opt.port
        case "V2I"
            A =  blkdiag(Ax{:});            
            B = [Bv_all, Bu_all];
            C = [Cx_all; Cy_all];
            D = [Dv_sum, Du_all; Dyv_all, Dyu_all];

            InputNames  = [Vport; vertcat(strings(0,1), InputNames{:})];
            OutputNames = [Iport; vertcat(strings(0,1), OutputNames{:})];

        case "I2V"
            % V = inv_Dv (I - Cx x - Du u)
            inv_Dv = Dv_sum^-1;
            A = blkdiag(Ax{:}) - Bv_all * inv_Dv * Cx_all;                       
            B = [Bv_all * inv_Dv, Bu_all - Bv_all * inv_Dv * Du_all];            
            C = [-inv_Dv * Cx_all; Cy_all - Dyv_all * inv_Dv * Cx_all];
            D = [inv_Dv, -inv_Dv * Du_all; Dyv_all * inv_Dv, Dyu_all - Dyv_all * inv_Dv * Du_all];

            InputNames  = [Iport; vertcat(strings(0,1), InputNames{:})];
            OutputNames = [Vport; vertcat(strings(0,1), OutputNames{:})];
    end    

    sys = dss(A,B,C,D,blkdiag(E{:}));
    sys.StateName  = cellstr(vertcat(strings(0,1), StateNames{:}));
    sys.InputName  = cellstr(InputNames);
    sys.OutputName = cellstr(OutputNames);
    
end
