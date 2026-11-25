
classdef IEEE39Bus < PowerNetwork
% IEEE 39-bus test system (New England 10-machine) without controllers.
% The 39-bus, 10-machine New England system.
% It has 39 buses, 46 branches (34 lines and 12 transformers), 10 generators and
% 19 loads; 60 Hz.
%
% Bus types:
%
% - Slack bus: bus 31
% - PV buses: bus 30 and buses 32 to 39
% - PQ buses: buses 1 to 29
%
% Data:
%
% - Lines are pi lines with the line charging given at each end (`C = b/2`);
%   transformers are two_winding_transformer branches with `C = 0` and their tap.
% - Generators are gen-2axis models; `M = 2H` with `H` on the system base (the
%   frequency deviation `omega` of gen-2axis is in pu) and `D = 2`.
% - Loads are load-power models. The buses without a generator or a load have a
%   load-power model with `P = Q = 0`.
% - The diagram layout (net.plot_diagram) follows Figure 1 of I. Hiskens, "IEEE PES
%   Task Force on Benchmark Systems for Stability Controls: Report on the 39-bus
%   system (New England Reduced Model)", 2013. The loads with `P = Q = 0`, which the
%   figure does not show, are short stubs at free places of their buses.
%
% A constant-power load cannot be supplied at the low voltages of a bus fault, so
% `net.simulate` with `add_fault` stops at the start of the fault (no consistent
% initial condition, GUILDA:SolverODE:InitialConditionFailed). For a fault, replace
% the loads with load-impedance first (second example).
%
% <@Citations>
% - I. Hiskens, "IEEE PES Task Force on Benchmark Systems for Stability Controls: Report
%   on the 39-bus system (New England Reduced Model)," Tech. Rep., 2013,
%   [https://cmte.ieee.org/pes-psdp/?p=331](https://cmte.ieee.org/pes-psdp/?p=331).
% - T. Athay, R. Podmore, and S. Virmani, "A practical method for the direct analysis of
%   transient stability," *IEEE Trans. Power App. Syst.*, vol. PAS-98, no. 2, pp. 573–584,
%   1979, doi: [10.1109/TPAS.1979.319407](https://doi.org/10.1109/TPAS.1979.319407).
% - M. A. Pai, *Energy Function Analysis for Power System Stability*. Boston, MA, USA:
%   Kluwer Academic, 1989, doi:
%   [10.1007/978-1-4613-1635-0](https://doi.org/10.1007/978-1-4613-1635-0).
%
% <@Examples>
% ```matlab
% net = network.IEEE39Bus();
% res = net.calculate_powerflow();
% ```
% ```matlab
% net = network.IEEE39Bus();
% for b = 1:numel(net.a_Bus)
%     c = net.a_Bus{b}.a_Component;
%     for k = 1:numel(c)
%         if isa(c{k}, "component.load.power") && any(c{k}.tab_parameter.powerflow{1, ["P","Q"]} ~= 0)
%             net.a_Bus{b}.replace_component(c{k}.s_tag, "load-impedance");
%         end
%     end
% end
% net.initialize();
% sc = net.add_scenario("fault");
% sc.add_fault("B016", [1, 1.05]);
% res = net.simulate("fault");
% ```
%
% See also network.IEEE68bus, network.IEEE9bus

    methods
        function obj = IEEE39Bus()
            % Create the network from the CSV data in the class folder.
            arguments (Output)
                obj  % IEEE39Bus network.
            end
            s_filepath   = mfilename("fullpath");
            s_dirpath    = fileparts(s_filepath);
            PowerNetwork.import(s_dirpath, Network=obj);
        end
    end
end
