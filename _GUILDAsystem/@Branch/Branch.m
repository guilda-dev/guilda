classdef Branch < PowerSystemModel
% <@Desc> 
% Abstract class representing a branch in the power system, such as a transmission line or transformer.
% It defines the structure and parameters of a branch, including its connection to buses and cubicles.
% Main function
% - build admittance matrix
% - build OPF problem
% - build ode function
% <@Role> 
% Power System Model
% <@Constructor> 
% Branch(tag, struct_default, opt)

%% Abstract Methods/Properties
    properties(Abstract, Constant)
        % <@Desc> Key Value to identify the type of branch (e.g., "pi", "pi_transformer").
        % <@Role> Signature
        % <@Type> string
        % <@Size> 1x1
        key

        header
    end
    methods(Abstract)
        % Dynamics
        Ymat = get_admittance_matrix(obj)
    end

%% Properties
   properties(SetAccess=protected)

        % <@Desc> PoweNetwork object to which the branch belongs
        % <@Role> Layer Structure
        % <@Type> PowerNetwork
        % <@Size> 1×1
        a_PowerNetwork 

        % <@Desc> Bus objects connected by the branch
        % <@Role> LayerStructure
        % <@Type> Bus objects cell array
        % <@Size> 2×1
        a_Bus
   end
    properties(Dependent)

        % <@Desc> Parameter table of the branch
        % <@Role> Parameter
        % <@Type> table
        % <@Size> 1xn
        tab_parameter

        % <@Desc> Operating point of the Voltage at the branch terminals
        % <@Role> Equilibrium
        % <@Type> complex
        % <@Size> 2×1
        cv_Vequilibrium

        % <@Desc> Operating point of the Voltage at the branch terminals
        % <@Role> Equilibrium
        % <@Type> complex
        % <@Size> 2×1
        cv_Iequilibrium
    end
    
    properties(Hidden,SetAccess=protected)

        % <@Desc> Parameters related to the branch dynamics
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1×1
        para_dynamics

        % <@Desc> Parameters related to the branch operation
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1×1
        para_operation    
        
        % <@Desc> Parameters related to the branch graph plot.
        % <@Role> Parameter
        % <@Type> Parameter
        % <@Size> 1×1
        para_graph

    end
    properties(Dependent, Access=protected)

        % <@Desc> manage hierarchical structure of layers.
        % <@Role> Layer Structure
        % <@Type> PowerNetwork(LayerPackage)
        % <@Size> 1x1
        parent

        % <@Desc> manage hierarchical structure of layers.
        % <@Role> Layer Structure
        % <@Type> Cubicle(LayerPackage) cell array
        % <@Size> Nx1
        children
    end

%% Constructor
    methods(Access={?Branch, ?PowerNetwork})
        function obj = Branch(index, opt)
            obj.str_tag = obj.header+index;
            
            a_Pm = Parameter(obj,"dynamics");
            a_Po = Parameter(obj,"operation");
            a_Pg = Parameter(obj,"graph");

            assert( isreal(opt.R), "ERROR: R must be a real number.")
            assert( isreal(opt.X), "ERROR: X must be a real number.")
            assert( isreal(opt.C), "ERROR: C must be a real number.")

            a_Pm.add_entry(        "R", opt.R        , "double" ,...
                                   "X", opt.X        , "double" ,...
                                   "C", opt.C        , "double" ,...
                                 "tap", opt.Tap      , "double" ,...
                               "phase", opt.Phase    , "double" );
            a_Po.add_entry(     "Smax", opt.Smax     , "double" ,...
                                "Imax", opt.Imax     , "double" ,...
                                "Pmax", opt.Pmax     , "double" ,...
                                "Qmax", opt.Qmax     , "double" ,...
                             "Vargmax", opt.Vargmax  , "double" );
            a_Pg.add_entry( "MidXaxis", opt.MidXaxis , "string",...
                            "MidYaxis", opt.MidYaxis , "string",...
                              "Marker", opt.Marker      , "string");

            obj.para_dynamics  = a_Pm;
            obj.para_operation = a_Po;
            obj.para_graph     = a_Pg;
        end
    end

%% Methods
    methods(Access={?PowerNetwork})
        set_network(obj,a_PowerNetwork)
        set_bus(obj,a_Bus)
    end
    methods
        % OPF
        [prob, x0, const] = build_opf_problem(obj, prob, x0, const, rm_V, option)
        
        % ode setting
        [n_odeX, n_odeU, Mass, x0] = reset_odeset(~, n_odeX, n_odeU, omega0)
    end

%% Get Methods
    methods
        function tp = get.tab_parameter(obj)
            dynamics  = obj.para_dynamics.tab_parameter;
            operation = obj.para_operation.tab_parameter;
            graph     = obj.para_graph.tab_parameter;
            tp        = table(dynamics,operation,graph);
        end
        function v = get.cv_Vequilibrium(obj)
            v = cellfun(@(cub) cub.c_Vequilibrium, obj.a_Bus);
        end
        function i = get.cv_Iequilibrium(obj)
            Y = obj.get_admittance_matrix;
            i = Y * obj.cv_Vequilibrium;
        end
        function p = get.parent(obj)
            p = obj.a_PowerNetwork;
        end
        function p = get.children(obj)
            p = {obj.para_dynamics; obj.para_operation; obj.para_graph};
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