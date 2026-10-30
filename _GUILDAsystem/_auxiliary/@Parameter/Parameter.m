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
% net.tab_editLog                    % edits are logged on the network
% ```
%
% See also LayerPackage
    properties(SetAccess=private) % Callback

        % Callback function executed after parameter changes.
        % <@Type> function_handle
        CallbackChanged = @() [];
    end
    properties(Access=private) % Internal state

        % Parameter names managed by this container.
        % <@Type> string (1xN)
        sv_parameter = [];

        % Stashed value used for change comparison.
        % <@Type> any
        val_stash 

        % Parent layer object managed by this container.
        % <@Type> LayerPackage
        a_cls
    end
    properties(Dependent) % Parameters

        % Parameter table generated from the dynamic properties.
        % One column per parameter; a container without parameters gives a table with the
        % single column NoData.
        % <@Type> table (1xN)
        tab_parameter
    end
    properties(Dependent, Access=protected) % Layer structure

        % Parent layer interface for compatibility.
        % <@Type> LayerPackage
        parent

        % Parameter class has no children, but the property is kept for interface compatibility.
        % <@Type> none (0x1)
        children
    end
    properties % Parameters
        NoData = nan; % Placeholder value of a container without parameters.
    end
    
    %% Constructor
    methods
        function obj = Parameter(a_parent,str_tag, CallBackChanged)
        % Create a parameter container for a parent layer.
        %
        % The container is not a managed tag: its tag names the parameter group (e.g.
        % "powerflow", "dynamics") used in the edit log.
            arguments
                a_parent % Parent layer object.
                str_tag = "Parameter" % Parameter tag.
                CallBackChanged = @(varargin) []; % Callback executed after parameter changes.
            end
            arguments (Output)
                obj % Created parameter container.
            end
            obj.a_cls        = a_parent;
            obj.l_managedTag = false;
            obj.str_tag      = str_tag;
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
        callbackPreSet(obj,name,event)
        callbackPostSet(obj,name,cls,event)
    end
end
