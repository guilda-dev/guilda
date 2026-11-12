classdef Tutorial10bus < PowerNetwork
% 10-bus network that contains every registered model class, to try each feature on one network.
% It has 10 buses, 10 branches (one of each branch class at least), 5 generators (one
% of each generator class), 4 loads (both load classes), every local controller class
% and an AGC over four generators; 60 Hz, 100 MVA base. Buses 1-5 are generator buses
% behind a step-up branch; buses 6-10 form a ring. Bus 6 has no component (a non-unit
% bus, eliminated in get_sys(Method="Kron")). The network is built with add_bus, add_branch,
% add_component, add_local_controller and add_global_controller and is initialized by
% the constructor.
%
% Buses and models (generator parameters: rows of the generator parameter.csv; line and
% load data: network.IEEE9bus):
%
% | Bus  | Type  | Component                    | Local controllers                       |
% |------|-------|------------------------------|-----------------------------------------|
% | B001 | slack | gen-park (NGT2), V = 1.04    | avr-DC1 (kap 20) + pss-PSS1, gov-LPT1   |
% | B002 | PV    | gen-2axis (NGT6), P = 1.63   | avr-ST1 (kap 2), gov-LPT3               |
% | B003 | PV    | gen-1axis (NGT8), P = 0.85   | local-LQR (Input "Vfield"), gov-LPT4    |
% | B004 | PV    | gen-classical (NGT2), P = 0.5| none                                    |
% | B005 | PV    | gen-droop (NGT8), P = 0.3    | none                                    |
% | B006 | PQ    | none (empty bus)             |                                         |
% | B007 | PQ    | load-impedance, -1.25 - 0.5j |                                         |
% | B008 | PQ    | load-power, -0.9 - 0.3j      |                                         |
% | B009 | PQ    | load-impedance, -1.0 - 0.35j |                                         |
% | B010 | PQ    | load-impedance, -0.5 - 0.15j |                                         |
%
% The global controller agc-PI (default gains) controls the generators at buses 1-4;
% its `Pmech` output goes to the `Pmech` input of each generator, beside the governor
% output (get_variable_map shows the routing in its connection map).
%
% Branches:
%
% | From-To | Class                   | Data                                  |
% |---------|-------------------------|---------------------------------------|
% | 1-6     | pi_transformer          | X 0.0576                              |
% | 2-7     | two_winding_transformer | X 0.0625                              |
% | 3-8     | pi_transformer          | X 0.0586, Tap 0.98                    |
% | 4-9     | T                       | R 0.005, X 0.05, C 0.04               |
% | 5-10    | pi                      | R 0.005, X 0.05, C 0.02               |
% | 6-7     | pi                      | R 0.01, X 0.085, C 0.088              |
% | 7-8     | pi                      | R 0.0085, X 0.072, C 0.0745           |
% | 8-9     | T                       | R 0.0119, X 0.1008, C 0.209           |
% | 9-10    | pi                      | R 0.017, X 0.092, C 0.079             |
% | 10-6    | pi                      | R 0.032, X 0.161, C 0.153             |
%
% Notes:
%
% - Controller placement: an AVR, the PSS and local-LQR drive `Vfield`, and the governors,
%   the PSS and the AGC observe `omega`. gen-droop has no `omega` (no output), so it has no
%   controller and is not under the AGC; gen-classical has no controller and is under the
%   AGC only. local-LQR drives `Vfield` only, so that the governor and the AGC keep `Pmech`.
% - Linearization: all the finite eigenvalues of `get_ss("Kron")` and `get_ss("DAE")` agree. One eigenvalue is 0 (to rounding): the mode of the common angle
%   of all the rotors, as no bus voltage is fixed. All the others have a negative real part.
% - Simulation: a three-phase fault on bus 8 for 50 ms settles. A fault on another bus
%   stops at the start of the fault, because the constant-power load at bus 8 cannot be
%   supplied at the fault voltages (see load-power).
% - Not included: component.ConstSource.power (legacy class without a model key; it cannot
%   be created) and controller.local_LQR_retrofit (GUILDA v2 interface; not registered in
%   GUILDA.keymap).
%
% <@Examples>
% Initialize, linearize and simulate a fault at bus 8:
%
% ```matlab
% net = network.Tutorial10bus();
% net.initialize;
% sys = net.get_sys(Method="Kron");
% e   = eig(sys.A);
% sc  = Scenario("fault", Time=[0,10]);
% net.add_scenario(sc);
% sc.add_fault("B008", [1,1.05]);
% sol = net.simulate(sc);
% ```
%
% See also network.Tutorial3bus, network.IEEE9bus, GUILDA.keymap, PowerNetwork.get_variable_map

    methods
        function obj = Tutorial10bus()
            % Create the network and initialize it.

            arguments (Output)
                obj % Tutorial10bus network.
            end

            % Buses 1-5: generator buses; buses 6-10: the ring (bus 6 has no component)
            obj.add_bus("V",1.04);
            obj.add_bus("V",1.025);
            obj.add_bus("V",1.025);
            obj.add_bus("V",1.02);
            obj.add_bus("V",1.02);
            for i = 6:10
                obj.add_bus();
            end

            % Step-up branches of the generators, then the ring
            obj.add_branch("pi_transformer",          [1,6],  "X",0.0576);
            obj.add_branch("two_winding_transformer", [2,7],  "X",0.0625);
            obj.add_branch("pi_transformer",          [3,8],  "X",0.0586, "Tap",0.98);
            obj.add_branch("T",                       [4,9],  "R",0.005,  "X",0.050,  "C",0.04);
            obj.add_branch("pi",                      [5,10], "R",0.005,  "X",0.050,  "C",0.02);
            obj.add_branch("pi",                      [6,7],  "R",0.010,  "X",0.085,  "C",0.088);
            obj.add_branch("pi",                      [7,8],  "R",0.0085, "X",0.072,  "C",0.0745);
            obj.add_branch("T",                       [8,9],  "R",0.0119, "X",0.1008, "C",0.209);
            obj.add_branch("pi",                      [9,10], "R",0.017,  "X",0.092,  "C",0.079);
            obj.add_branch("pi",                      [10,6], "R",0.032,  "X",0.161,  "C",0.153);

            % Generators (bus 1 is the slack bus)
            g1 = obj.a_Bus{1}.add_component("gen-park",      "P",0,    "parameter","NGT2");
            g2 = obj.a_Bus{2}.add_component("gen-2axis",     "P",1.63, "parameter","NGT6");
            g3 = obj.a_Bus{3}.add_component("gen-1axis",     "P",0.85, "parameter","NGT8");
            g4 = obj.a_Bus{4}.add_component("gen-classical", "P",0.50, "parameter","NGT2");
            obj.a_Bus{5}.add_component(     "gen-droop",     "P",0.30, "parameter","NGT8");
            obj.a_Bus{1}.l_isSlack = true;

            % Loads
            obj.a_Bus{7}.add_component( "load-impedance", "P",-1.25, "Q",-0.50);
            obj.a_Bus{8}.add_component( "load-power",     "P",-0.90, "Q",-0.30);
            obj.a_Bus{9}.add_component( "load-impedance", "P",-1.00, "Q",-0.35);
            obj.a_Bus{10}.add_component("load-impedance", "P",-0.50, "Q",-0.15);

            % Local controllers (AVR/PSS data: network.IEEE9bus; governor: Prate = rated MW / base)
            g1.add_local_controller("avr-DC1",   parameter=struct(kap=20));
            g1.add_local_controller("pss-PSS1",  parameter=struct(kpss=20, tWS=10, tn1=0.05, td1=0.015, tn2=0.08, td2=0.01));
            g1.add_local_controller("gov-LPT1",  parameter=struct(Prate=2.5));
            g2.add_local_controller("avr-ST1",   parameter=struct(kap=2));
            g2.add_local_controller("gov-LPT3",  parameter=struct(Prate=2.0));
            g3.add_local_controller("local-LQR", parameter=struct(Input="Vfield"));
            g3.add_local_controller("gov-LPT4",  parameter=struct(Prate=1.5));

            % Global controller over the generators that have omega
            obj.add_global_controller("agc-PI", {g1, g2, g3, g4});

            obj.initialize;
        end
    end
end
