classdef (Abstract) ResultBase < auxiliary
% Abstract base class for the results of analyses (power flow, OPF, CPF, time simulation, linearization).
%
% An analysis method net.verb_noun() returns [result, flag, output]; the result object
% also keeps flag and output, the settings actually used and the elapsed time, so the
% result alone is enough to check the outcome. A result stores what the analysis computed
% and the settings it used (`options`: the analysis method merges its section of
% GUILDA.setting, and for the continuation power flow the LoadBus of net.solver_CPF, with
% the Name-Value options of the call; get_sys keeps the options of its call). Model data
% stays with its owner. ResultPF, ResultOPF and ResultODE are built from data and a struct
% snapshot of the network (struct(net, false)); they keep its tag (s_network) and refer to
% no network object. ResultPF and ResultODE keep the snapshot (sct_network); ResultOPF
% keeps the tag only. ResultCPF and ResultLIN refer to the analysed network
% (a_PowerNetwork, not a copy; the network may have been edited after the analysis) and
% keep its tag; they do not copy bus, branch or component data. export
% is part of the contract: a subclass overrides it when it writes files; otherwise it stops
% with the error GUILDA:ResultBase:Unsupported. Figures are drawn by the plot_* methods of
% each subclass (ResultPF.plot_voltage, ResultOPF.plot_dispatch, ResultCPF.plot_pvcurve,
% ResultODE.plot_trajectory, ResultLIN.plot_eigenvalue).
%
% <@Examples>
% Every analysis of a network returns a subclass of ResultBase:
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% [result, flag, output] = net.calculate_powerflow();
% result.l_success     % true when the analysis succeeded
% result.options       % settings used for this run
% result.r_elapsed     % elapsed time [s]
% result.plot_voltage();
% ```
%
% See also ResultPF, ResultOPF, ResultCPF, ResultLIN, ResultODE

    properties (SetAccess=protected) % Result
        flag = false                  % Success or convergence flag (second output): logical, or a numeric exit flag positive on success. <@Type> logical or double
        output struct = struct()      % Solver details, as returned by the analysis (third output).
        options struct = struct()     % Effective settings: the section of GUILDA.setting of the analysis, with the Name-Value options of the call applied.
        s_solver (1,1) string = ""    % Class name of the solver object that ran the analysis.
        r_elapsed (1,1) double = NaN  % [s] Elapsed time of the analysis.
        s_network (1,1) string = ""   % Tag of the analysed network at the time of the analysis.
    end
    properties (SetAccess=protected, Hidden) % Network
        a_PowerNetwork = []           % Analysed network: a reference, not a copy (it may have been edited since). <@Type> PowerNetwork (1x1 or empty)
    end
    properties (Dependent) % Result
        l_success                     % True when the analysis succeeded (see is_success). <@Type> logical
    end

    methods
        function obj = ResultBase(net, solver, options, flag, output, elapsed)
        % Initialize the shared part of a result.
        %
        % Stores the parts shared by every result. Call it from a subclass constructor
        % as obj@ResultBase(...).
            arguments (Input)
                net                = [] % Analysed network (kept as a reference) or [] (results built from a snapshot).
                solver             = "" % Solver object that ran the analysis, or its class name.
                options   struct   = struct() % Effective settings of the run.
                flag               = false % Success or convergence flag.
                output    struct   = struct() % Solver details.
                elapsed            = NaN % [s] Elapsed time, or the value returned by tic at the start of the analysis.
            end
            arguments (Output)
                obj % The result object.
            end
            if ~isempty(net)
                obj.a_PowerNetwork = net;
                obj.s_network      = string(net.s_tag);
            end
            if isstring(solver) || ischar(solver)
                obj.s_solver = string(solver);
            else
                obj.s_solver = string(class(solver));
            end
            obj.options = options;
            obj.flag    = flag;
            obj.output  = output;
            if isa(elapsed, "uint64")
                obj.r_elapsed = toc(elapsed);
            else
                obj.r_elapsed = elapsed;
            end
        end

        function l = get.l_success(obj)
            l = obj.is_success();
        end

        varargout = export(obj, varargin)
    end

    methods (Access=protected)
        l = is_success(obj)
        error_unsupported(obj, s_method)
    end
end
