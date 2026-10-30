classdef Txt3Bus < PowerNetwork
% 3-bus system of the GUILDA textbook.
% The system of "Systems Control Engineering of Power Systems - System Mathematics
% and MATLAB Simulation -" (2022). It has 3 buses, 2 pi lines, 2 generators
% (gen-1axis) at buses 1 and 3 and a constant-impedance load (load-impedance) at
% bus 2, on a 100 MVA base.
%
% <@Examples>
% Run the power flow and simulate a fault at bus 2:
%
% ```matlab
% net = network.Txt3Bus();
% res = net.calculate_powerflow();
% ev  = odeEventSet("fault", net, "TimeSpan", [1,1.05], "FaultBus", "B002");
% sol = net.simulate([0,10], ev);
% ```
%
% See also network.Tutorial3bus
 
    properties(Constant) % Data
        ver = 1 % Version of the bundled network data.
    end

    methods
        function obj = Txt3Bus()
            % Create the network from the CSV data in the class folder.
            arguments (Output)
                obj % Txt3Bus network.
            end
            str_filepath = mfilename("fullpath");
            str_dirpath  = fileparts(str_filepath);
            PowerNetwork.import_csv(str_dirpath, Network=obj);
        end
    end
end
