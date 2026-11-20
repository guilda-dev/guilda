classdef abstract < Component
% Base class of the grid-forming inverter models.
%
% A grid-forming inverter connects to one bus, sets its own internal voltage and
% frequency, and injects a current into the bus. Subclasses define the state variables,
% the equations and the parameter names (`sv_x`, `sv_u`, `sv_y`, `sv_para`).
%
% Add a grid-forming inverter with `Bus.add_component` and a model key such as
% `"gfm-vsg-classical"`. Its tag is the bus tag + `"GFM"` + a number, e.g. `"B001GFM1"`.
% In the power flow the inverter is a PV source: `tab_parameter.powerflow.Q` is always
% `NaN`. A `Q` other than `NaN` or 0 is ignored with a warning.
%
% The `parameter` argument of `add_component` sets the dynamic parameters:
% - a table whose columns include the names in `sv_para`;
% - a name in the column `Name` of the `parameter.csv` bundled with the subclass
%   (in its class folder);
% - anything else but text (default `NaN`): the first row of that `parameter.csv`.
%
% A missing column or another name stops with an error. A new inverter has no local
% controllers: its inputs stay at their equilibrium until a controller drives them.
%
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% vsg = bus.add_component("gfm-vsg-classical", "P", 0.5);
% vsg.s_tag                           % "B001GFM1"
% vsg.tab_parameter.dynamics          % parameters taken from parameter.csv
% ```
%
% See also Component, Bus.add_component, component.GFMInverter.VSG_classical, component.GFLInverter.abstract

    methods (Access={?Component})
        function obj = abstract(index, parameter, varargin)
            % Create the inverter and read its dynamic parameters.
            %
            % Called through `Bus.add_component`. `index` is the tag suffix
            % (the tag is the bus tag + `"GFM"+index`), `parameter` selects the dynamic
            % parameters (see the class description) and `varargin` holds
            % the name-value options of `add_component`.
            arguments (Input)
                index      % Number of the tag: the tag is the bus tag + "GFM" + index.
                parameter  % Dynamic parameters: a table, a name in the Name column of the parameter.csv of the subclass, or NaN for its first row.
            end
            arguments (Input, Repeating)
                varargin  % Options of Bus.add_component, passed on to Component.
            end
            arguments (Output)
                obj  % Grid-forming inverter object.
            end
            obj@Component("GFM"+index, varargin{:})
            tp  = obj.tab_parameter;
            r_Q = tp.powerflow.Q;
            if ~isnan(r_Q) && r_Q ~= 0
                show_msg("warning", "GUILDA:Component:GFMInverterQIgnored", char(obj.s_tag), char(string(r_Q)))
            end
            obj.tab_parameter.powerflow.Q = nan;

            if istable(parameter)
                mp = parameter;
                s_source = "the given table";
            else
                datapath = fullfile(fileparts(which(class(obj))), "parameter.csv");
                dataset  = readtable(datapath, "TextType", "string");
                s_source = "parameter.csv";
                if ischar(parameter) || isstring(parameter)
                    sv_name = reshape(dataset.Name, [], 1);
                    s_name  = string(parameter);
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
        end
    end
end
