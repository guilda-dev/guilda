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
% <@Examples>
% ```matlab
% net = PowerNetwork();
% bus = net.add_bus();
% gen = bus.add_component("gen-1axis", "P", 0.5, "parameter", "NGT6");
% gen.tab_parameter.dynamics          % parameters taken from parameter.csv
% gen.add_local_controller(controller.avr.AVR_ST1("avr1"))
% ```
%
% See also Component, Bus.add_component, component.generator.classical, component.generator.park

    methods (Access={?Component})
        function obj =  abstract(index, parameter, varargin)
            % Create the generator and read its dynamic parameters.
            %
            % Called through `Bus.add_component`. `index` is the tag suffix
            % (the tag is `"SG"+index`), `parameter` selects the dynamic
            % parameters (see the class description) and `varargin` holds
            % the name-value options of `add_component`.
            obj@Component("SG"+index, varargin{:})
            r_Q = obj.para_powerflow.Q;
            if ~isnan(r_Q) && r_Q ~= 0
                obj.parameter_error("GeneratorQIgnored", char(obj.str_tag), char(string(r_Q)))
            end
            obj.para_powerflow.Q = nan;
            
            if istable(parameter)
                mp = parameter;
                str_source = "the given table";
            else 
                datapath = fullfile(fileparts(mfilename("fullpath")), "parameter.csv");
                dataset  = readtable(datapath);                
                str_source = "parameter.csv";
                if ischar(parameter) || isstring(parameter)                
                    sv_name = ["NGT2";"NGT6";"NGT8"];
                    str_name = string(parameter);
                    if ~isscalar(str_name) || ~ismember(str_name, sv_name)
                        obj.parameter_error("UnknownParameter", char(strjoin(str_name(:)', ", ")), ...
                                            char(obj.str_tag), char(strjoin(sv_name', ", ")))
                    end
                    mp = dataset(str_name==sv_name,:);
                else
                    mp = dataset(1,:);
                end
            end

            sv_miss = setdiff(string(obj.sv_para), string(mp.Properties.VariableNames), "stable");
            if ~isempty(sv_miss)
                obj.parameter_error("MissingParameter", char(strjoin(sv_miss(:)', ", ")), ...
                                    char(obj.str_tag), char(str_source))
            end
            mp = mp(:,obj.sv_para);
            
            name = cellfun(@(d) string(d), mp.Properties.VariableNames);
            for i=1:numel(name)
                obj.para_dynamics.add_entry(name(i), mp.(name(i)), "double");
            end

            % obj.set_avr( component.generator.avr.base() );
            % obj.set_governor( component.generator.governor.base() );
            % obj.set_pss( component.generator.pss.base() );
        end
    end    

    properties(SetAccess = protected) % Controllers (legacy)
        % Legacy slot for an AVR.
        %
        % <@Deprecated> Use `add_local_controller` and `a_LocalController`.
        avr
        % Legacy slot for a PSS.
        %
        % <@Deprecated> Use `add_local_controller` and `a_LocalController`.
        pss
        % Legacy slot for a governor.
        %
        % <@Deprecated> Use `add_local_controller` and `a_LocalController`.
        governor
    end

    methods
        % Set a governor through the legacy controller slot.
        %
        % <@Deprecated> Use `add_local_controller`.
        set_governor(obj, con)
        % Set an AVR through the legacy controller slot.
        %
        % <@Deprecated> Use `add_local_controller`.
        set_avr(obj, con)
        % Set a PSS through the legacy controller slot.
        %
        % <@Deprecated> Use `add_local_controller`.
        set_pss(obj, con)
        function c = get.governor(obj); c = obj.SpecificControllers{1}; end    
        function c = get.avr(obj);      c = obj.SpecificControllers{2}; end    
        function c = get.pss(obj);      c = obj.SpecificControllers{3}; end    
    end

end
