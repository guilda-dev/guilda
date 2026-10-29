classdef odeSimulationResult < AnalysisResult
% <@Desc>
% Result of net.simulate: the time response of the bus voltages, currents and powers and
% of the states and inputs of the components. It holds computed values only; the settings
% of the buses and components stay with the network (a hidden reference, see
% AnalysisResult). flag is 1 when the simulation reached the end time, 0 when it stopped
% by TimeLimit and -1 when the solver stopped early; then the trajectories end at
% output.tEnd.
% Plot draws a trajectory of the buses or components. Export writes all trajectories as a
% table (CSV, Excel) or as a MAT-file.
% <@Role> Class Category
% <@Constructor>
% result = odeSimulationResult(net, solver, options, flag, output, elapsed, c_phase)
% Created by odeSimulator.solve.

    properties (SetAccess=private)
        % <@Desc> Trajectories, as a struct:
        % t (time [s], column), Bus(i).V (table Vreal, Vimag), Bus(i).I (Ireal, Iimag),
        % Bus(i).PQ (P, Q), Bus(i).Component(j).X (states, columns named by sv_x) and
        % Bus(i).Component(j).U (inputs, columns named by sv_u). Bus(i) follows net.a_Bus
        % and Component(j) follows a_Component of the bus. At a boundary between two phases
        % the time appears twice (end of one phase, start of the next).
        % <@Role> Result
        % <@Type> struct
        % <@Size> 1x1
        odeResults struct = struct()

        % <@Desc> Bus tags, in the order of odeResults.Bus.
        % <@Role> Result
        % <@Type> string
        % <@Size> n_bus x 1
        sv_bus (:,1) string = strings(0,1)

        % <@Desc> Component tags of each bus, in the order of odeResults.Bus(i).Component.
        % <@Role> Result
        % <@Type> cell of string
        % <@Size> n_bus x 1
        c_component (:,1) cell = cell(0,1)
    end

    methods
        function obj = odeSimulationResult(net, solver, options, flag, output, elapsed, c_phase)
        % <@Desc>
        % Collects the trajectories of the integration phases into odeResults.
        % <@Role> Constructor
        % <@Summary> Create a time simulation result.
        % <@Signatures>
        % [
        %   "result = odeSimulationResult()",
        %   "result = odeSimulationResult(net, solver, options, flag, output, elapsed, c_phase)"
        % ]
        % <@Parameters>
        % [
        %   {"Name": "net, solver, options, flag, output, elapsed", "Type": "-", "Description": "Shared part, see AnalysisResult.", "Required": false, "Default": "-"},
        %   {"Name": "c_phase", "Type": "cell of table", "Description": "Result of each phase (odeEventSet.Event2State: t, x, i).", "Required": false, "Default": "{}"}
        % ]
        % <@Returns>
        % [
        %   {"Name": "result", "Type": "odeSimulationResult", "Description": "The result object."}
        % ]
            arguments
                net             = []
                solver          = "odeSimulator"
                options  struct = struct()
                flag            = false
                output   struct = struct()
                elapsed         = NaN
                c_phase  cell   = {}
            end
            obj@AnalysisResult(net, solver, options, flag, output, elapsed);
            if isempty(net) || isempty(c_phase)
                return
            end

            a_bus = net.a_Bus;
            obj.sv_bus      = string(a_bus(:));
            obj.c_component = cellfun(@(b) string(b.a_Component(:)), a_bus(:), 'UniformOutput', false);

            sol = reshape(c_phase, [], 1);
            t = cell2mat( cellfun(@(T) T.t, sol, 'UniformOutput', false) );
            X = cell2mat( cellfun(@(T) T.x, sol, 'UniformOutput', false) );
            I = cell2mat( cellfun(@(T) T.i, sol, 'UniformOutput', false) );

            obj.odeResults.t = t{:,1};
            for i=1:numel(a_bus)

                a_Comp = a_bus{i}.a_Component;

                obj.odeResults.Bus(i).Component = struct();
                for j=1:numel(a_Comp)
                    c_idx = a_Comp{j}.iv_odeX;
                    sol_c_idx = X(:,c_idx);
                    sol_c_idx.Properties.VariableNames = a_Comp{j}.sv_x;
                    obj.odeResults.Bus(i).Component(j).X = sol_c_idx;

                    c_idx = a_Comp{j}.iv_odeU;
                    sol_c_idx = X(:,c_idx);
                    sol_c_idx.Properties.VariableNames = a_Comp{j}.sv_u;
                    obj.odeResults.Bus(i).Component(j).U = sol_c_idx;
                end

                b_idx = a_bus{i}.iv_odeX;

                sol_V_idx = X{:,b_idx};
                sol_I_idx = I{:,[2*i-1,2*i]};
                sol_P_idx = array2table( sol_V_idx(:,1) .* sol_I_idx(:,1) + sol_V_idx(:,2) .* sol_I_idx(:,2) );
                sol_Q_idx = array2table( sol_V_idx(:,2) .* sol_I_idx(:,1) - sol_V_idx(:,1) .* sol_I_idx(:,2) );

                sol_V_idx = X(:,b_idx);
                sol_I_idx = I(:,[2*i-1,2*i]);

                sol_V_idx.Properties.VariableNames = ["Vreal","Vimag"];
                sol_I_idx.Properties.VariableNames = ["Ireal","Iimag"];
                sol_P_idx.Properties.VariableNames = "P";
                sol_Q_idx.Properties.VariableNames = "Q";

                obj.odeResults.Bus(i).V  = sol_V_idx;
                obj.odeResults.Bus(i).I  = sol_I_idx;
                obj.odeResults.Bus(i).PQ = [sol_P_idx,sol_Q_idx];
            end
        end

        ax = Plot(obj, opt)
        str_file = Export(obj, filename)
    end

end
