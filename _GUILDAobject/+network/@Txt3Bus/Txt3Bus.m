classdef Txt3Bus < PowerNetwork
% 3-bus system of the GUILDA textbook.
% The system of "Systems Control Engineering of Power Systems - System Mathematics
% and MATLAB Simulation -" (2022). It has 3 buses, 2 pi lines, 2 generators
% (gen-1axis) at buses 1 and 3 and a constant-impedance load (load-impedance) at
% bus 2, on a 100 MVA base.
%
% <@Citations>
% - 石崎孝幸 編著, 川口貴弘, 河辺賢一 著, 『電力系統のシステム制御工学
%   ―システム数理とMATLABシミュレーション―』 (計測・制御セレクションシリーズ 4),
%   計測自動制御学会 編, コロナ社, 2022, Example 2.1, ISBN 978-4-339-03384-7,
%   [publisher page](https://www.coronasha.co.jp/np/isbn/9784339033847/).
%
% <@Examples>
% Run the power flow and simulate a fault at bus 2:
%
% ```matlab
% net = network.Txt3Bus();
% res = net.calculate_powerflow();
% sc  = net.add_scenario("fault");
% sc.add_fault("B002", [1,1.05]);
% sol = net.simulate("fault");
% ```
%
% See also network.Tutorial3bus
 
    properties(Constant) % Data
        ver = 1  % Version of the bundled network data.
    end

    methods
        function obj = Txt3Bus()
            % Create the network from the CSV data in the class folder.
            arguments (Output)
                obj  % Txt3Bus network.
            end
            s_filepath   = mfilename("fullpath");
            s_dirpath    = fileparts(s_filepath);
            PowerNetwork.import(s_dirpath, Network=obj);
        end
    end
end
