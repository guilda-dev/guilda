classdef Branch < PowerSystemModel
% Abstract class of a line or transformer between two buses, which computes its own 2x2 admittance matrix.
%
% The network sums the matrices of its branches into the bus admittance matrix used by the
% power flow, the OPF and the simulation.
%
% - Owns R, X, C, tap, phase (`tab_parameter.dynamics`), its operating limits
%   (`tab_parameter.operation`: Smax, Imax, Pmax, Qmax, Vargmax) and drawing data, and
%   decides how they form an admittance matrix (the subclass contract
%   `get_admittance_matrix`).
% - Parameters (`tab_parameter`) are per unit on the system base, set by add_branch (R, X,
%   C, Tap, Phase and the limits) or by writing the table. An edit of dynamics makes the
%   power flow of the network stale; operation and graph make nothing stale.
% - Refers to its two end buses (`a_Bus`, from and to), but is not their parent and does
%   not own their voltages. The end voltages and currents it shows are derived from the
%   buses. The order of `a_Bus` is the row and column order of the 2x2 matrix.
% - struct(br) is the LayerPackage struct with one more field, `cm_Y`: the 2x2 matrix of
%   get_admittance_matrix. A network snapshot (struct(net, false)) thus carries the
%   admittance of every branch, also of a branch class of your own; ResultPF reads it.
% - Has no states and no function-handle cache. It takes part in the simulation only
%   through the admittance matrix built when an analysis starts.
% - Created only by `PowerNetwork.add_branch` (the constructors of the concrete classes
%   are accessible only from `PowerNetwork`); only the network sets `a_PowerNetwork` and
%   `a_Bus`, and `PowerNetwork.remove_branch` deletes the branch. No dangling ends: `PowerNetwork.remove_bus` on a bus with
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
% br.tab_parameter.operation.Smax = Inf;   % no apparent-power limit
% ```
%
% See also PowerNetwork.add_branch, branch.pi, Bus

%% Abstract Properties
    properties(Abstract, Constant) % Subclass contract
        key                  % Branch type, e.g. "pi": the Type of PowerNetwork.add_branch (running GUILDA regenerates its key list).
        header               % Tag prefix of branches of this type, e.g. "EL" for lines and "ET" for transformers.
    end

%% Properties
    properties(SetAccess={?PowerNetwork}) % Layer Structure
        a_PowerNetwork = []           % PowerNetwork the branch belongs to (set by add_branch). <@Type> PowerNetwork
        a_Bus (:,1) cell = cell(0,1)  % End buses {from; to}: the row and column order of the admittance matrix. <@Type> cell of Bus (2x1)
    end
    properties(Dependent) % Parameter
        cv_Vequilibrium      % [pu] Voltage phasors of the end buses at the equilibrium. <@Type> double
        cv_Iequilibrium      % [pu] Currents into the branch at its ends at the equilibrium: get_admittance_matrix() * cv_Vequilibrium. <@Type> double
    end

    properties(Dependent, Access=protected) % Layer Structure
        parent               % Parent in the layer structure: the network.
        children             % Children in the layer structure: the Parameter objects.
    end

%% Abstract Methods
    methods(Abstract)
        % Return the 2x2 admittance matrix of the branch.
        %
        % The matrix maps the voltages of the end buses [V_from; V_to] to the currents
        % injected into the branch at those ends, in per unit. It reads tab_parameter.dynamics and
        % must not read or change anything else.
        Ymat = get_admittance_matrix(obj)
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
            
            % tab_parameter columns:
            % - dynamics: R, X [pu]: series impedance; C [pu]: shunt susceptance (meaning set by the subclass); tap: off-nominal ratio; phase [rad]
            % - operation: operating limits at both ends: Smax, Imax, Pmax, Qmax [pu] (default Inf); Vargmax [rad]: end-bus angle difference (default pi/2); Inf or NaN: no limit
            % - graph: MidXaxis, MidYaxis: intermediate points of the line in the diagram; Marker: line style

            assert( isreal(opt.R), "ERROR: R must be a real number.")
            assert( isreal(opt.X), "ERROR: X must be a real number.")
            assert( isreal(opt.C), "ERROR: C must be a real number.")

            a_Pm = Parameter(obj, "dynamics", struct( ...
                    "R", opt.R, ...
                    "X", opt.X, ...
                    "C", opt.C, ...
                  "tap", opt.Tap, ...
                "phase", opt.Phase));
            a_Po = Parameter(obj, "operation", struct( ...
                   "Smax", opt.Smax, ...
                   "Imax", opt.Imax, ...
                   "Pmax", opt.Pmax, ...
                   "Qmax", opt.Qmax, ...
                "Vargmax", opt.Vargmax));
            a_Pg = Parameter(obj, "graph", struct( ...
                "MidXaxis", opt.MidXaxis, ...
                "MidYaxis", opt.MidYaxis, ...
                  "Marker", opt.Marker));

            obj.a_Parameter = {a_Pm; a_Po; a_Pg};
        end
    end

%% Methods
    methods(Hidden)
        [out, sct_visited] = struct(obj, l_disp, s_header, sct_visited)
    end
    methods(Access={?PowerNetwork})
        initialize(obj)
    end
    methods(Access=protected)
        sct_page = gui_content(obj)
    end

%% Get Methods
    methods
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
            p = obj.a_Parameter;
        end
    end
end
