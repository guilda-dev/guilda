classdef (Abstract) ResultBase < auxiliary
% Abstract base class for the results of analyses (power flow, OPF, CPF, time simulation).
%
% An analysis method net.verb_noun() returns [result, flag, output]; the result object
% also keeps flag and output, the settings actually used and the elapsed time, so the
% result alone is enough to check the outcome. A result stores only what the analysis
% computed and the settings it used. Model data stays with its owner: the result refers to
% the network (a_PowerNetwork) and keeps its tag (s_network); it does not copy bus,
% branch or component data. Plot and Export are part of the contract. A subclass overrides
% the ones it supports; the others stop with the error GUILDA:ResultBase:Unsupported.
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
% result.Plot();
% ```
%
% See also ResultPF, ResultOPF, ResultCPF, ResultLIN, ResultODE

    properties (SetAccess=protected) % Result
        % Success or convergence flag, as returned by the analysis (second output).
        % A logical, or a numeric exit flag where a positive value means success.
        % <@Type> logical or double
        flag = false

        % Solver details, as returned by the analysis (third output).
        output struct = struct()

        % Effective settings of the run.
        % The stored defaults of net.solver_* with the Name-Value overrides of the call
        % applied (see tools.resolve_options).
        options struct = struct()

        % Class name of the solver object that ran the analysis.
        s_solver (1,1) string = ""

        % [s] Elapsed time of the analysis.
        r_elapsed (1,1) double = NaN

        % Tag of the analysed network at the time of the analysis.
        s_network (1,1) string = ""
    end
    properties (SetAccess=protected, Hidden) % Network
        % Reference to the analysed network (not a copy).
        % The network may have been edited after the analysis.
        % <@Type> PowerNetwork (1x1 or empty)
        a_PowerNetwork = []
    end
    properties (Dependent) % Result
        % True when the analysis succeeded (see is_success).
        % <@Type> logical
        l_success
    end

    methods
        function obj = ResultBase(net, solver, options, flag, output, elapsed)
        % Initialize the shared part of a result.
        %
        % Stores the parts shared by every result. Call it from a subclass constructor
        % as obj@ResultBase(...).
            arguments (Input)
                net                = [] % Analysed network (kept as a reference) or [].
                solver             = "" % Solver object that ran the analysis, or its class name.
                options   struct   = struct() % Effective settings of the run (output of tools.resolve_options).
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

        function varargout = Plot(obj, varargin) %#ok<STOUT>
        % Plot the result.
        %
        % Plots the result. Each result class defines its own figures and Name-Value
        % options. A result class without a plot stops with GUILDA:ResultBase:Unsupported.
            arguments (Input)
                obj
            end
            arguments (Input, Repeating)
                varargin  % Name-Value plot options defined by the result class.
            end
            arguments (Output, Repeating)
                varargout % Created figure or axes (defined by the result class).
            end
            obj.error_unsupported("Plot");
        end

        function varargout = Export(obj, varargin) %#ok<STOUT>
        % Write the result to a file.
        %
        % Writes the result to a file. Each result class defines the file formats and
        % Name-Value options. A result class without an export stops with
        % GUILDA:ResultBase:Unsupported.
            arguments (Input)
                obj
            end
            arguments (Input, Repeating)
                varargin  % Output file, then Name-Value export options defined by the result class.
            end
            arguments (Output, Repeating)
                varargout % Path of the written file (defined by the result class).
            end
            obj.error_unsupported("Export");
        end
    end

    methods (Access=protected)
        function l = is_success(obj)
        % Decide whether flag means success.
        %
        % Success test behind l_success: a logical flag as it is, a numeric flag when
        % positive (as for exitflag of fsolve or fmincon). Override it when an analysis
        % uses another convention.
            arguments (Input)
                obj
            end
            arguments (Output)
                l % True when the analysis succeeded.
            end
            f = obj.flag;
            if islogical(f)
                l = isscalar(f) && f;
            elseif isnumeric(f)
                l = isscalar(f) && f > 0;
            else
                l = false;
            end
        end

        function error_unsupported(obj, s_method)
        % Error for an unsupported Plot or Export.
        %
        % Stops with GUILDA:ResultBase:Unsupported for a method of the Plot / Export
        % contract that this result class does not provide.
            arguments (Input)
                obj
                s_method % Name of the unsupported method ("Plot" or "Export").
            end
            error(msg("GUILDA:ResultBase:Unsupported", char(s_method), class(obj)));
        end
    end
end
