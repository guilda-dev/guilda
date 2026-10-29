classdef CPFResult < AnalysisResult
% <@Desc>
% Result of net.calculate_continuation_powerflow: the load parameter lambda and the bus
% voltages at each point of the traced path, and the nose point (maximum loading). The
% loads of options.LoadBus are scaled by (1 + lambda). It holds computed values only; the
% settings of the buses and components stay with the network.
% Plot draws the PV curves. Export writes the path as a table (CSV, Excel).
% <@Role> Class Category
% <@Constructor>
% result = CPFResult(net, solver, options, flag, output, elapsed, sv_bus, rv_lambda, cm_Vbus, rm_x, rm_xPredicted)
% Created by ContinuationPowerFlow.solve.

    properties (SetAccess=private)
        % <@Desc> Bus tags, in the order of the rows of cm_Vbus.
        % <@Role> Result
        % <@Type> string
        % <@Size> n_bus x 1
        sv_bus (:,1) string = strings(0,1)

        % <@Desc> Load parameter lambda at each point of the path (the first point is the
        % equilibrium).
        % <@Role> Result
        % <@Type> double
        % <@Size> 1 x n_step
        rv_lambda double = zeros(1,0)

        % <@Desc> Bus voltage phasors [pu] at each point of the path, one row per bus.
        % <@Role> Result
        % <@Type> complex double
        % <@Size> n_bus x n_step
        cm_Vbus double = zeros(0,0)

        % <@Desc> Largest lambda on the path (the nose of the PV curve: maximum loading).
        % <@Role> Result
        % <@Type> double
        % <@Size> 1x1
        r_lambdaMax (1,1) double = NaN

        % <@Desc> Index of the nose point in rv_lambda and the columns of cm_Vbus.
        % <@Role> Result
        % <@Type> double
        % <@Size> 1x1
        r_noseStep (1,1) double = NaN

        % <@Desc> Full variable vector at each point of the path (the CPF_Result.x_sol of
        % v3): [|V|; angle V] of each bus (followed by the component states when
        % options.UseInternalState is true), and lambda in the last row.
        % <@Role> Result
        % <@Type> double
        % <@Size> n_var x n_step
        rm_x double = zeros(0,0)

        % <@Desc> Predicted points of the predictor-corrector method, in the layout of rm_x
        % (the CPF_Result.x_prd of v3). The first column is NaN.
        % <@Role> Result
        % <@Type> double
        % <@Size> n_var x n_step
        rm_xPredicted double = zeros(0,0)
    end

    properties (Dependent)
        % <@Desc> Bus voltages at the nose point, one row per bus (row names = bus tags):
        % V [pu], Varg [rad], Vphasor.
        % <@Role> Result
        % <@Type> table
        % <@Size> n_bus x 3
        tab_nose

        % <@Desc> The path as a table, one row per point: lambda, then V_<bus> [pu] and
        % Varg_<bus> [rad] of each bus. Export writes this table.
        % <@Role> Result
        % <@Type> table
        % <@Size> n_step x (1 + 2 n_bus)
        tab_path
    end

    methods
        function obj = CPFResult(net, solver, options, flag, output, elapsed, sv_bus, rv_lambda, cm_Vbus, rm_x, rm_xPredicted)
        % <@Desc>
        % Stores the computed values of a continuation power flow.
        % <@Role> Constructor
        % <@Summary> Create a continuation power flow result.
        % <@Signatures>
        % [
        %   "result = CPFResult()",
        %   "result = CPFResult(net, solver, options, flag, output, elapsed, sv_bus, rv_lambda, cm_Vbus, rm_x, rm_xPredicted)"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "net, solver, options, flag, output, elapsed", "Type": "-", "Description": "Shared part, see AnalysisResult.", "Required": false, "Default": "-"},
        %   {"Name": "sv_bus", "Type": "string", "Description": "Bus tags (rows of cm_Vbus).", "Required": false, "Default": "strings(0,1)"},
        %   {"Name": "rv_lambda", "Type": "double", "Description": "lambda along the path.", "Required": false, "Default": "[]"},
        %   {"Name": "cm_Vbus", "Type": "complex double", "Description": "Bus voltages along the path.", "Required": false, "Default": "[]"},
        %   {"Name": "rm_x", "Type": "double", "Description": "Full variable vector along the path.", "Required": false, "Default": "[]"},
        %   {"Name": "rm_xPredicted", "Type": "double", "Description": "Predicted points.", "Required": false, "Default": "[]"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "result", "Type": "CPFResult", "Description": "The result object."}
        % ]
            arguments
                net                  = []
                solver               = "ContinuationPowerFlow"
                options       struct = struct()
                flag                 = false
                output        struct = struct()
                elapsed              = NaN
                sv_bus        string = strings(0,1)
                rv_lambda     double = zeros(1,0)
                cm_Vbus       double = zeros(0,0)
                rm_x          double = zeros(0,0)
                rm_xPredicted double = zeros(0,0)
            end
            obj@AnalysisResult(net, solver, options, flag, output, elapsed);
            obj.sv_bus        = sv_bus(:);
            obj.rv_lambda     = reshape(rv_lambda, 1, []);
            obj.cm_Vbus       = cm_Vbus;
            obj.rm_x          = rm_x;
            obj.rm_xPredicted = rm_xPredicted;
            if ~isempty(obj.rv_lambda)
                [obj.r_lambdaMax, obj.r_noseStep] = max(obj.rv_lambda);
            end
        end

        function tab = get.tab_nose(obj)
            if isnan(obj.r_noseStep)
                cv_V = complex(zeros(numel(obj.sv_bus),1));
            else
                cv_V = obj.cm_Vbus(:, obj.r_noseStep);
            end
            tab = table(abs(cv_V), angle(cv_V), cv_V, ...
                        'VariableNames', ["V","Varg","Vphasor"], 'RowNames', cellstr(obj.sv_bus));
        end

        function tab = get.tab_path(obj)
            rm_V = [abs(obj.cm_Vbus); angle(obj.cm_Vbus)].';
            sv_name = ["V_" + obj.sv_bus; "Varg_" + obj.sv_bus].';
            tab = [table(obj.rv_lambda(:), 'VariableNames', "lambda"), ...
                   array2table(rm_V, 'VariableNames', sv_name)];
        end

        fig = Plot(obj, opt)
        str_file = Export(obj, filename)
    end
end
