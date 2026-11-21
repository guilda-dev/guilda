classdef abstract < Component
% Base class of the synchronous generator models.
%
% A generator model connects to one bus, takes the mechanical power `Pmech` and
% the field voltage `Vfield` as input signals, and injects a current into the bus.
% Subclasses define the state variables, the equations and the parameter names
% (`sv_x`, `sv_u`, `sv_y`, `sv_para`).
%
% Add a generator with `Bus.add_component` and a model key such as
% `"gen-classical"`, `"gen-1axis"`, `"gen-2axis"`, `"gen-park"` or `"gen-droop"`.
% In the power flow the generator is a PV source: `tab_parameter.powerflow.Q`
% is always `NaN`. A `Q` other than `NaN` or 0 is ignored with a warning.
%
% The `parameter` argument of `add_component` sets the dynamic parameters:
% - a table whose columns include the names in `sv_para`;
% - `"NGT2"`, `"NGT6"` or `"NGT8"`, a row of the bundled `parameter.csv`;
% - anything else but text (default `NaN`): the first row of `parameter.csv` (NGT2).
%
% A missing column or another name stops with an error.
%
% A new generator has a Static AVR (`"avr-static"`) and a Static governor
% (`"gov-static"`), which keep `Vfield` and `Pmech` at their equilibrium
% (controller.avr.Static, controller.governor.Static). Another AVR or governor
% replaces them without a warning. A model without the input `Vfield` (`Pmech`) gets
% no Static AVR (governor).
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% gen = bus.add_component("gen-1axis", "P", 0.5, "parameter", "NGT6");
% gen.tab_parameter.dynamics          % parameters taken from parameter.csv
% gen.add_local_controller("avr-ST1")
% ```
%
% See also Component, Bus.add_component, component.generator.classical, component.generator.park

    properties(Dependent, SetAccess=private) % Controllers
        avr       % The AVR in a_LocalController (role "avr"), [] if none. Read-only: attach with set_avr or add_local_controller.
        pss       % The PSS under the AVR, [] if none. Read-only: attach with set_pss or add_local_controller.
        governor  % The governor in a_LocalController (role "governor"), [] if none. Read-only: attach with set_governor or add_local_controller.
    end

    methods (Access={?Component})
        function obj =  abstract(index, parameter, varargin)
            % Create the generator and read its dynamic parameters.
            %
            % Called through `Bus.add_component`. `index` is the tag suffix
            % (the tag is the bus tag + `"SG"+index`), `parameter` selects the dynamic
            % parameters (see the class description) and `varargin` holds
            % the name-value options of `add_component`.
            arguments (Input)
                index      % Number of the tag: the tag is the bus tag + "SG" + index.
                parameter  % Dynamic parameters: a table, a name in parameter.csv ("NGT2", "NGT6", "NGT8"), or NaN for its first row.
            end
            arguments (Input, Repeating)
                varargin  % Options of Bus.add_component, passed on to Component.
            end
            arguments (Output)
                obj  % Generator object.
            end
            obj@Component("SG"+index, varargin{:})
            tp  = obj.tab_parameter;
            r_Q = tp.powerflow.Q;
            if ~isnan(r_Q) && r_Q ~= 0
                show_msg("warning", "GUILDA:Component:GeneratorQIgnored", char(obj.s_tag), char(string(r_Q)))
            end
            obj.tab_parameter.powerflow.Q = nan;
            
            if istable(parameter)
                mp = parameter;
                s_source = "the given table";
            else 
                datapath = fullfile(fileparts(mfilename("fullpath")), "parameter.csv");
                dataset  = readtable(datapath);                
                s_source = "parameter.csv";
                if ischar(parameter) || isstring(parameter)                
                    sv_name = ["NGT2";"NGT6";"NGT8"];
                    s_name = string(parameter);
                    if ~isscalar(s_name) || ~ismember(s_name, sv_name)
                        error(msg("GUILDA:Component:UnknownParameter", char(strjoin(s_name(:)', ", ")), ...
                              char(obj.s_tag), char(strjoin(sv_name', ", "))))
                    end
                    mp = dataset(s_name==sv_name,:);
                else
                    mp = dataset(1,:);
                end
            end

            sv_miss = setdiff(string(obj.sv_para), string(mp.Properties.VariableNames), "stable");
            if ~isempty(sv_miss)
                error(msg("GUILDA:Component:MissingParameter", char(strjoin(sv_miss(:)', ", ")), ...
                          char(obj.s_tag), char(s_source)))
            end
            mp = mp(:,obj.sv_para);
            
            obj.a_Parameter{cellfun(@(p) p.s_tag=="dynamics", obj.a_Parameter)} = Parameter(obj, "dynamics", table2struct(mp));

            % The AVR and governor slots are filled from the start: the default Static controllers
            % keep Vfield and Pmech at their equilibrium until another AVR or governor replaces
            % them (a model without such an input gets no Static for it)
            if ismember("Vfield", obj.sv_u)
                obj.add_local_controller("avr-static");
            end
            if ismember("Pmech", obj.sv_u)
                obj.add_local_controller("gov-static");
            end
        end
    end    

    methods
        % Attach an AVR by its model key: add_local_controller for a key with the role "avr".
        con = set_avr(obj, Key, opt)
        % Attach a PSS under the AVR by its model key: add_local_controller for a key with the role "pss".
        con = set_pss(obj, Key, opt)
        % Attach a governor by its model key: add_local_controller for a key with the role "governor".
        con = set_governor(obj, Key, opt)
        function c = get.avr(obj)
            c = top_controller(obj, "avr");
        end
        function c = get.governor(obj)
            c = top_controller(obj, "governor");
        end
        function c = get.pss(obj)
            c = [];
            avr = top_controller(obj, "avr");
            if ~isempty(avr) && ~isempty(avr.a_LocalController)
                c = avr.a_LocalController{1};
            end
        end
    end

    methods (Static, Access=protected)
        % Hessian over [x; theta; V] of the dq energy function (shared by the get_hessian overrides)
        H = energy_hessian_dq(x, V, rv_aq, r_Eq, rv_ad, r_Ed, Xd, Xq, K)
    end

end


function con = top_controller(gen, s_role)
    % The top-level local controller of the role ([] if none); a_LocalController holds at most one of each
    con = [];
    for k = 1:numel(gen.a_LocalController)
        if gen.a_LocalController{k}.s_role == s_role
            con = gen.a_LocalController{k};
            return
        end
    end
end
