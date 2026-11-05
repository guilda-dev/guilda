classdef Parameter < auxiliary & LayerPackage & dynamicprops
% Parameter container for LayerPackage-derived objects.
%
% It manages dynamic parameters, change callbacks, and edit logging. Each parameter is a
% dynamic property; a change of its value is checked against its class and written to the
% edit log of the owner layer (tag "Parameter(<group>)").
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% bus = net.a_Bus{1};
% bus.tab_parameter                  % parameters of the bus as a table
% net.tab_editLog                    % edits are logged on the owner layer; the network collects them
% ```
%
% See also LayerPackage
    properties(SetAccess=private) % Callback
        CallbackChanged = @() [];  % Callback function executed after parameter changes. <@Type> function_handle
    end
    properties(Access=private) % Internal state
        sv_parameter = [];  % Parameter names managed by this container. <@Type> string (1xN)
        val_stash  % Stashed value used for change comparison. <@Type> any
        a_cls  % Owner layer of this container. <@Type> LayerPackage
    end
    properties(Dependent) % Parameter
        tab_parameter  % Parameter table: one column per parameter (the single column NoData when there are none). <@Type> table (1xN)
    end
    properties(Dependent, Access=protected) % Layer structure
        parent  % Parent in the layer structure: the owner layer. <@Type> LayerPackage
        children  % Children in the layer structure: none (kept for the LayerPackage interface). <@Type> none (0x1)
    end
    properties % Parameters
        NoData = nan;  % Placeholder value of a container without parameters.
    end
    
    %% Constructor
    methods
        function obj = Parameter(a_parent,s_tag, CallBackChanged)
        % Create a parameter container for a parent layer.
        %
        % Its tag names the parameter group (e.g. "powerflow", "dynamics"), used in the edit log.
            arguments (Input)
                a_parent                             % Parent layer object.
                s_tag           = "Parameter"        % Parameter tag.
                CallBackChanged = @(varargin) [];    % Callback executed after parameter changes.
            end
            arguments (Output)
                obj                                  % Created parameter container.
            end
            % The tag is set before the parent: the owner is still being built, so its other
            % containers cannot be checked as siblings yet (set.s_tag).
            obj.s_tag  = s_tag;
            obj.a_cls  = a_parent;
            obj.CallbackChanged = CallBackChanged;
        end
    end

    methods
        function tab_para  = get.tab_parameter(obj)
            % Convert dynamic parameter properties into a table.
            %
            % Builds a table from the registered parameter properties.
            % Output `tab_para`: the parameter table.
            sv_para = obj.sv_parameter;
            if isempty(sv_para)
                NoData = nan;               %#ok
                tab_para = table(NoData);   %#ok
            else
                for s_ipara =  sv_para(:)'
                    sct_para.(s_ipara) = obj.(s_ipara);
                end
                tab_para = struct2table(sct_para);
            end
        end
        function p = get.parent(obj); p = obj.a_cls; end
        function c = get.children(~); c = {};        end
    end

    methods(Hidden)
        add_entry(obj,names,defaults,valids)
        attach_callbacks(obj,name,valid)
        callbackPreSet(obj,name,event)
        callbackPostSet(obj,name,event)
    end
end
