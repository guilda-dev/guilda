function sys = get_sys(obj, opt)
% <@Desc>
% Linear model of the bus: its components (with their local controllers) connected at
% the bus, from the bus voltage V to the current I injected by the components
% (port "V2I") or the inverse (port "I2V"). Point gives the point of the
% linearization in the same form as net.linearize: [] for the equilibrium, a vector in
% the order of bus.get_variable_map(), or {sim, t}. The model is not changed.
% <@Role> Static Analysis
% <@Summary> Linear model of the bus (V to I, or I to V).
% <@Signatures>
% [
%   "sys = bus.get_sys()",
%   "sys = bus.get_sys(port=\"I2V\", full=true, Point=x)"
% ]
% <@Parameters>
% [
%   {"Name": "port", "Type": "\"V2I\" | \"I2V\"", "Description": "Input and output ports.", "Required": false, "Default": "\"V2I\""},
%   {"Name": "full", "Type": "logical scalar", "Description": "Also output the states.", "Required": false, "Default": "false"},
%   {"Name": "Point", "Type": "[] | double vector | cell {sim, t}", "Description": "Point of the linearization.", "Required": false, "Default": "[] (the equilibrium)"}
% ]
% <@Returns>
% [
%   {"Name": "sys", "Type": "ss", "Description": "Descriptor state-space model with state, input and output names."}
% ]
    arguments
        obj 
        opt.port (1,1) {mustBeMember(opt.port, ["V2I", "I2V"])} = "V2I"
        opt.full (1,1) logical = false
        opt.con  (1,1) logical = false
        opt.Point = []
    end

    if isempty(opt.Point) && ~iscell(opt.Point)
        sys = tools.cellfun(@(c) c.get_sys("port", "V2I", "full", opt.full), obj.a_Component);
    else
        rv_point  = odeLinearizer.point_vector(obj, opt.Point);
        [~, c_idx] = obj.get_variable_map();
        sys = cell(size(obj.a_Component));
        for j = 1:numel(obj.a_Component)
            sys{j} = obj.a_Component{j}.get_sys("port", "V2I", "full", opt.full, "Point", rv_point(c_idx{j}));
        end
    end
    if isempty(sys)     % no components: no states, and the bus takes no current (I = 0)
        sys = {ss(zeros(0), zeros(0,2), zeros(2,0), zeros(2))};
    end

    Ax = tools.cellfun(@(ss) ss.A                 , sys);
    Bv = tools.cellfun(@(ss) ss.B(:,1:2)          , sys);
    Bu = tools.cellfun(@(ss) ss.B(:,3:end)        , sys);
    Cx = tools.cellfun(@(ss) ss.C(end-1:end,:)    , sys);
    Dv = tools.cellfun(@(ss) ss.D(end-1:end,1:2)  , sys);    
    Du = tools.cellfun(@(ss) ss.D(end-1:end,3:end), sys);    

    E = tools.cellfun(@(ss) ss.E, sys);

    StateNames = tools.cellfun(@(ss) ss.StateName , sys);
    InputNames = tools.cellfun(@(c) c.attach_tag(c.sv_u), obj.a_Component);    

    Vport = arrayfun(@(str) obj.attach_tag(str), ["Vre";"Vim"]);
    Iport = arrayfun(@(str) obj.attach_tag(str), ["Ire";"Iim"]);
    
    switch opt.port
        case "V2I"
            A =  blkdiag(Ax{:});            
            B = [vertcat(Bv{:}), blkdiag(Bu{:})];

            nx = size(A,1);
            nu = size(B,2);            

            C  = [  eye(opt.full*nx,nx); horzcat(Cx{:})];
            D  = [zeros(opt.full*nx,nu); [sum( cat(3,Dv{:}),3 ), horzcat(Du{:})]];            

            InputNames  = [Vport; vertcat(InputNames{:})];
            OutputNames = {Iport;[vertcat(StateNames{:}); Iport]};

        case "I2V"
            inv_Dv = sum( cat(3,Dv{:}),3 )^-1;
            inv_Cx = horzcat(Cx{:});
            inv_Du = horzcat(Du{:});       
            inv_Ax = blkdiag(Ax{:}) - vertcat(Bv{:}) * inv_Dv * inv_Cx;                       
            inv_Bv = vertcat(Bv{:}) * inv_Dv;            
            inv_Bu = blkdiag(Bu{:}) - vertcat(Bv{:}) * inv_Dv * inv_Du;

            A =  inv_Ax;
            B = [inv_Bv, inv_Bu];            

            nx = size(A,1);
            nu = size(B,2);            
                        
            C  = [  eye(opt.full*nx,nx); -inv_Dv*inv_Cx];
            D  = [zeros(opt.full*nx,nu); [inv_Dv, -inv_Dv*inv_Du]];            
            InputNames  = [Iport; vertcat(InputNames{:})];
            OutputNames = {Vport;[vertcat(StateNames{:}); Vport]};
    end    


    sys = dss(A,B,C,D,blkdiag(E{:}));
    sys.StateName  = vertcat(StateNames{:});
    sys.InputName  = InputNames;
    sys.OutputName = OutputNames{opt.full+1};
    
end