classdef CPFResult < AnalysisResult
% Result of net.calculate_continuation_powerflow.
%
% Holds the load parameter lambda and the bus voltages at each point of the traced path,
% and the nose point (maximum loading). The loads of options.LoadBus are scaled by (1 + lambda). It holds computed values only;
% the settings of the buses and components stay with the network. Plot draws the PV
% curves. Export writes the path as a table (CSV, Excel).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% [result, flag] = net.calculate_continuation_powerflow(LoadBus=["B009","B014"]);
% result.r_lambdaMax       % maximum loading (nose of the PV curve)
% result.tab_nose          % bus voltages at the nose
% result.Plot(Bus="all");  % PV curves of every bus
% result.Export("cpf.csv");
% ```
%
% See also ContinuationPowerFlow, AnalysisResult

    properties (SetAccess=private) % Result
        % Bus tags, in the order of the rows of cm_Vbus.
        sv_bus (:,1) string = strings(0,1)

        % Load parameter lambda at each point of the path (the first point is the equilibrium).
        rv_lambda double = zeros(1,0)

        % [pu] Bus voltage phasors at each point of the path, one row per bus.
        cm_Vbus double = zeros(0,0)

        % Largest lambda on the path (the nose of the PV curve: maximum loading).
        r_lambdaMax (1,1) double = NaN

        % Index of the nose point in rv_lambda and the columns of cm_Vbus.
        r_noseStep (1,1) double = NaN

        % Full variable vector at each point of the path (the CPF_Result.x_sol of v3).
        % Rows: [|V|; angle V] of each bus (followed by the component states when
        % options.UseInternalState is true), and lambda in the last row.
        rm_x double = zeros(0,0)

        % Predicted points of the predictor-corrector method, in the layout of rm_x.
        % The CPF_Result.x_prd of v3. The first column is NaN.
        rm_xPredicted double = zeros(0,0)
    end

    properties (Dependent) % Result
        % Bus voltages at the nose point, one row per bus (row names = bus tags).
        % Columns: V [pu], Varg [rad], Vphasor [pu].
        % <@Type> table (n_bus x 3)
        tab_nose

        % The path as a table, one row per point.
        % Columns: lambda, then V_<bus> [pu] and Varg_<bus> [rad] of each bus. Export writes
        % this table.
        % <@Type> table (n_step x (1 + 2 n_bus))
        tab_path
    end

    methods
        function obj = CPFResult(net, solver, options, flag, output, elapsed, sv_bus, rv_lambda, cm_Vbus, rm_x, rm_xPredicted)
        % Create a continuation power flow result.
        %
        % Stores the computed values of a continuation power flow.
            arguments
                net                  = [] % Analysed network; see AnalysisResult.
                solver               = "ContinuationPowerFlow" % Solver object or its class name; see AnalysisResult.
                options       struct = struct() % Effective settings; see AnalysisResult.
                flag                 = false % Success or convergence flag; see AnalysisResult.
                output        struct = struct() % Solver details; see AnalysisResult.
                elapsed              = NaN % [s] Elapsed time or tic value; see AnalysisResult.
                sv_bus        string = strings(0,1) % Bus tags (rows of cm_Vbus).
                rv_lambda     double = zeros(1,0) % lambda along the path.
                cm_Vbus       double = zeros(0,0) % [pu] Bus voltages along the path.
                rm_x          double = zeros(0,0) % Full variable vector along the path.
                rm_xPredicted double = zeros(0,0) % Predicted points.
            end
            arguments (Output)
                obj % The result object.
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
