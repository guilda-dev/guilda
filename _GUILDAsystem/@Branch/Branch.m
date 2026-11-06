classdef Branch < PowerSystemModel
% Abstract class of a line or transformer between two buses, which computes its own 2x2 admittance matrix.
%
% The network sums the matrices of its branches into the bus admittance matrix used by the
% power flow, the OPF and the simulation.
%
% - Owns R, X, C, tap, phase (`tab_parameter.dynamics`), its OPF flow limits
%   (`tab_parameter.operation`: Smax, Imax, Pmax, Qmax, Vargmax) and drawing data, and
%   decides how they form an admittance matrix (the subclass contract
%   `get_admittance_matrix`).
% - Parameters (`tab_parameter`) are per unit on the system base, set by add_branch (R, X,
%   C, Tap, Phase and the limits) or by writing the table. An edit of dynamics makes the
%   power flow of the network stale; operation and graph make nothing stale.
% - Refers to its two end buses (`a_Bus`, from and to), but is not their parent and does
%   not own their voltages. The end voltages and currents it shows are derived from the
%   buses. The order of `a_Bus` is the row and column order of the 2x2 matrix.
% - Has no states and no function-handle cache. It takes part in the simulation only
%   through the admittance matrix built when an analysis starts.
% - Created only by `PowerNetwork.add_branch`; only the network sets and clears
%   `a_PowerNetwork` and `a_Bus`. No dangling ends: `PowerNetwork.remove_bus` on a bus with
%   branches stops unless RemoveBranches=true.
%
% Subclasses in the `branch` package define `key` (the type name of add_branch), `header`
% (the tag prefix, "EL" for lines and "ET" for transformers) and `get_admittance_matrix`.
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
    properties(Abstract, Constant) % Subclass contract
        key  % Branch type, e.g. "pi": the Type of PowerNetwork.add_branch (running GUILDA regenerates its key list).
        header  % Tag prefix of branches of this type, e.g. "EL" for lines and "ET" for transformers.
    end
    methods(Abstract)
        % Return the 2x2 admittance matrix of the branch.
        %
        % The matrix maps the voltages of the end buses [V_from; V_to] to the currents
        % injected into the branch at those ends, in per unit. It reads para_dynamics and
        % must not read or change anything else.
        Ymat = get_admittance_matrix(obj)
    end

%% Properties
    properties(SetAccess=protected) % Layer Structure
        a_PowerNetwork  % PowerNetwork the branch belongs to ([] when removed). <@Type> PowerNetwork
        a_Bus  % End buses {from; to}: the row and column order of the admittance matrix. <@Type> cell of Bus (2x1)
    end
    properties(SetAccess=protected) % OPF
        f_opfcost = []  % OPF cost handle @(v, p) from set_opffcn; replaces the default cost of the branch ([]: none). <@Stale> nothing
        f_opfconst = []  % OPF constraint handle @(v, p) from set_opffcn, returning a struct of named constraints ([]: none). <@Stale> nothing
        l_opfdefault = true  % Whether the default OPF constraints of the branch are kept (DefaultConstraint of set_opffcn). <@Stale> nothing
    end
    properties(Dependent) % Parameter
        tab_parameter  % Parameter table: the para_* tables side by side; writing it writes the parameters. <@Type> table
        cv_Vequilibrium  % [pu] Voltage phasors of the end buses at the equilibrium. <@Type> double
        cv_Iequilibrium  % [pu] Currents into the branch at its ends at the equilibrium: get_admittance_matrix() * cv_Vequilibrium. <@Type> double
    end

    properties(Hidden,SetAccess=protected) % Parameter
        para_dynamics  % R, X [pu]: series impedance; C [pu]: shunt susceptance (meaning set by the subclass); tap: off-nominal ratio; phase [rad].
        para_operation  % OPF limits at both ends: Smax, Imax, Pmax, Qmax [pu] (default Inf); Vargmax [rad]: end-bus angle difference (default pi/2).
        para_graph  % MidXaxis, MidYaxis: intermediate points of the line in the diagram; Marker: line style.
    end
    properties(Dependent, Access=protected) % Layer Structure
        parent  % Parent in the layer structure: the network.
        children  % Children in the layer structure: the Parameter objects.
    end

%% Constructor
    methods(Access={?Branch, ?PowerNetwork})
        function obj = Branch(index, opt)
            % Create a branch (called by PowerNetwork.add_branch through a subclass).
            arguments (Input)
                index (1,1) string   % Number part of the tag, e.g. "001".
                opt   (1,1) struct   % Branch settings of add_branch.
            end
            arguments (Output)
                obj   % New Branch object.
            end
            obj.s_tag = obj.header+index;
            
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
        initialize(obj)
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