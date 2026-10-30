classdef Branch < PowerSystemModel
% Abstract class of a branch of a power network, such as a transmission line or transformer.
%
% A branch connects two buses (`a_Bus`, from and to). Its series and shunt parameters
% (`tab_parameter.dynamics`: R, X, C, tap, phase) give the admittance matrix used by the
% power flow, the OPF and the simulation; `tab_parameter.operation` holds the OPF limits
% (Smax, Imax, Pmax, Qmax, Vargmax). Branches are created by `PowerNetwork.add_branch`;
% subclasses in the `branch` package define the model (`get_admittance_matrix`).
%
% <@Examples>
% ```matlab
% net = network.IEEE9bus();
% br  = net.a_Branch{1};               % or net.add_branch("pi", [1,2], R=0.01, X=0.085)
% br.tab_parameter.dynamics            % R, X, C, tap, phase
% Y   = br.get_admittance_matrix();    % 2x2 admittance matrix
% br.set_opffcn("DefaultConstraint", false);
% ```
%
% See also PowerNetwork.add_branch, branch.pi, Bus

%% Abstract Methods/Properties
    properties(Abstract, Constant)
        % Key that identifies the branch type, e.g. "pi" or "pi_transformer".
        key

        % Prefix of the tags of branches of this type.
        header
    end
    methods(Abstract)
        % Return the 2x2 admittance matrix of the branch.
        %
        % The matrix maps the voltages of the end buses [V_from; V_to] to the currents
        % injected into the branch at those ends, in per unit.
        Ymat = get_admittance_matrix(obj)
    end

%% Properties
   properties(SetAccess=protected) % Layer Structure

        % PowerNetwork the branch belongs to ([] when removed).
        % <@Type> PowerNetwork
        a_PowerNetwork 

        % End buses of the branch {from; to}.
        % <@Type> cell
        a_Bus

        % OPF terms (Cost, Constraint, DefaultConstraint) set by set_opffcn.
        % reset_opffcn restores the defaults.
        % <@Type> struct
        s_opffcn = opffcn.default()
   end
    properties(Dependent) % Parameter

        % Parameter table of the branch: dynamics, operation and graph.
        % <@Type> table
        tab_parameter

        % [pu] Voltage phasors of the end buses at the equilibrium.
        % <@Type> double
        cv_Vequilibrium

        % [pu] Currents injected into the branch at its ends at the equilibrium.
        % <@Type> double
        cv_Iequilibrium
    end
    
    properties(Hidden,SetAccess=protected) % Parameter
        para_dynamics       % Parameter: R, X, C, tap, phase
        para_operation      % Parameter: Smax, Imax, Pmax, Qmax, Vargmax
        para_graph          % Parameter: MidXaxis, MidYaxis, Marker
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent              % Layer Structure
        children            % Layer Structure
    end

%% Constructor
    methods(Access={?Branch, ?PowerNetwork})
        function obj = Branch(index, opt)
            % Create a branch (called by PowerNetwork.add_branch through a subclass).
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