classdef (Abstract) AnalysisResult < auxiliary
% <@Desc>
% Abstract base class for the results of analyses (power flow, OPF, CPF, time simulation).
% An analysis method net.verb_noun() returns [result, flag, output]; the result object
% also keeps flag and output, the settings actually used and the elapsed time, so the
% result alone is enough to check the outcome.
% A result stores only what the analysis computed and the settings it used. Model data
% stays with its owner: the result refers to the network (a_PowerNetwork) and keeps its
% tag (str_network); it does not copy bus, branch or component data.
% Plot and Export are part of the contract. A subclass overrides the ones it supports;
% the others stop with the error GUILDA:AnalysisResult:Unsupported.
% <@Role> Class Category
% <@Constructor>
% obj@AnalysisResult(net, solver, options, flag, output, elapsed)
% Called from the constructor of a subclass. AnalysisResult() with no arguments
% creates an empty result.

    properties (SetAccess=protected)
        % <@Desc> Success or convergence flag, as returned by the analysis (second output).
        % A logical, or a numeric exit flag where a positive value means success.
        % <@Role> Result
        % <@Type> logical or double
        % <@Size> 1x1
        flag = false

        % <@Desc> Solver details, as returned by the analysis (third output).
        % <@Role> Result
        % <@Type> struct
        % <@Size> 1x1
        output struct = struct()

        % <@Desc> Effective settings of the run: the stored defaults of net.solver_* with the
        % Name-Value overrides of the call applied (see tools.resolve_options).
        % <@Role> Settings
        % <@Type> struct
        % <@Size> 1x1
        options struct = struct()

        % <@Desc> Class name of the solver object that ran the analysis.
        % <@Role> Settings
        % <@Type> string
        % <@Size> 1x1
        str_solver (1,1) string = ""

        % <@Desc> Elapsed time of the analysis [s].
        % <@Role> Result
        % <@Type> double
        % <@Size> 1x1
        r_elapsed (1,1) double = NaN

        % <@Desc> Tag of the analysed network at the time of the analysis.
        % <@Role> Network
        % <@Type> string
        % <@Size> 1x1
        str_network (1,1) string = ""
    end
    properties (SetAccess=protected, Hidden)
        % <@Desc> Reference to the analysed network (not a copy). The network may have been
        % edited after the analysis.
        % <@Role> Network
        % <@Type> PowerNetwork
        % <@Size> 1x1 or empty
        a_PowerNetwork = []
    end
    properties (Dependent)
        % <@Desc> True when the analysis succeeded (see is_success).
        % <@Role> Result
        % <@Type> logical
        % <@Size> 1x1
        l_success
    end

    methods
        function obj = AnalysisResult(net, solver, options, flag, output, elapsed)
        % <@Desc>
        % Stores the parts shared by every result. Call it from a subclass constructor
        % as obj@AnalysisResult(...).
        % <@Role> Constructor
        % <@Summary> Initialize the shared part of a result.
        % <@Signatures>
        % [
        %   "obj = AnalysisResult()",
        %   "obj = AnalysisResult(net, solver, options, flag, output, elapsed)"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "net", "Type": "PowerNetwork", "Description": "Analysed network (kept as a reference) or [].", "Required": false, "Default": "[]"},
        %   {"Name": "solver", "Type": "object or string", "Description": "Solver object that ran the analysis, or its class name.", "Required": false, "Default": "\"\""},
        %   {"Name": "options", "Type": "struct", "Description": "Effective settings of the run (output of tools.resolve_options).", "Required": false, "Default": "struct()"},
        %   {"Name": "flag", "Type": "logical or double", "Description": "Success or convergence flag.", "Required": false, "Default": "false"},
        %   {"Name": "output", "Type": "struct", "Description": "Solver details.", "Required": false, "Default": "struct()"},
        %   {"Name": "elapsed", "Type": "double or uint64", "Description": "Elapsed time [s], or the value returned by tic at the start of the analysis.", "Required": false, "Default": "NaN"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "obj", "Type": "AnalysisResult", "Description": "The result object."}
        % ]
            arguments
                net                = []
                solver             = ""
                options   struct   = struct()
                flag               = false
                output    struct   = struct()
                elapsed            = NaN
            end
            if ~isempty(net)
                obj.a_PowerNetwork = net;
                obj.str_network    = string(net.str_tag);
            end
            if isstring(solver) || ischar(solver)
                obj.str_solver = string(solver);
            else
                obj.str_solver = string(class(solver));
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

        function varargout = Plot(obj, varargin) %#ok<STOUT,INUSD>
        % <@Desc>
        % Plots the result. Each result class defines its own figures and Name-Value
        % options. A result class without a plot stops with GUILDA:AnalysisResult:Unsupported.
        % <@Role> Plot
        % <@Summary> Plot the result.
        % <@Signatures>
        % [
        %   "Plot(result)",
        %   "h = Plot(result, Name, Value)"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "result", "Type": "AnalysisResult", "Description": "Result to plot.", "Required": true, "Default": "-"},
        %   {"Name": "Name, Value", "Type": "Name-Value", "Description": "Plot options defined by the result class.", "Required": false, "Default": "-"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "h", "Type": "graphics handle", "Description": "Created figure or axes (defined by the result class)."}
        % ]
            obj.error_unsupported("Plot");
        end

        function varargout = Export(obj, varargin) %#ok<STOUT,INUSD>
        % <@Desc>
        % Writes the result to a file. Each result class defines the file formats and
        % Name-Value options. A result class without an export stops with
        % GUILDA:AnalysisResult:Unsupported.
        % <@Role> Export
        % <@Summary> Write the result to a file.
        % <@Signatures>
        % [
        %   "Export(result, filename)",
        %   "str_file = Export(result, filename, Name, Value)"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "result", "Type": "AnalysisResult", "Description": "Result to write.", "Required": true, "Default": "-"},
        %   {"Name": "filename", "Type": "string scalar", "Description": "Output file.", "Required": true, "Default": "-"},
        %   {"Name": "Name, Value", "Type": "Name-Value", "Description": "Export options defined by the result class.", "Required": false, "Default": "-"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "str_file", "Type": "string scalar", "Description": "Path of the written file."}
        % ]
            obj.error_unsupported("Export");
        end
    end

    methods (Access=protected)
        function l = is_success(obj)
        % <@Desc>
        % Success test behind l_success: a logical flag as it is, a numeric flag when
        % positive (as for exitflag of fsolve or fmincon). Override it when an analysis
        % uses another convention.
        % <@Role> Result
        % <@Summary> Decide whether flag means success.
        % <@Signatures>
        % [
        %   "l = is_success(obj)"
        % ]
        % <@Returns>
        % [
        %   {"Name": "l", "Type": "logical scalar", "Description": "True when the analysis succeeded."}
        % ]
            f = obj.flag;
            if islogical(f)
                l = isscalar(f) && f;
            elseif isnumeric(f)
                l = isscalar(f) && f > 0;
            else
                l = false;
            end
        end

        function error_unsupported(obj, str_method)
        % <@Desc>
        % Stops with GUILDA:AnalysisResult:Unsupported for a method of the Plot / Export
        % contract that this result class does not provide.
        % <@Role> Result
        % <@Summary> Error for an unsupported Plot or Export.
        % <@Signatures>
        % [
        %   "error_unsupported(obj, str_method)"
        % ]
            error('GUILDA:AnalysisResult:Unsupported', '%s', ...
                  msg('GUILDA:AnalysisResult:Unsupported', char(str_method), class(obj)));
        end
    end
end
