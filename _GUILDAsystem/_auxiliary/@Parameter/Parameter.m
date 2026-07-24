classdef Parameter < auxiliary & LayerPackage & dynamicprops
% <@Desc> 
% Parameter container for LayerPackage-derived objects.
% It manages dynamic parameters, change callbacks, and edit logging.
% <@Role> 
% Edit Log, Parameter
% <@Constructor> 
% Parameter(a_parent, str_tag, CallBackChanged)
% Create a parameter container for the given parent layer.
    properties(SetAccess=private)

        % <@Desc> Callback function executed after parameter changes.
        % <@Role> Edit Log
        % <@Type> function_handle
        % <@Size> 1x1
        CallbackChanged = @() [];
    end
    properties(Access=private)

        % <@Desc> Parameter names managed by this container.
        % <@Role> Parameter
        % <@Type> string
        % <@Size> 1xN
        sv_parameter = [];

        % <@Desc> Stashed value used for change comparison.
        % <@Role> Parameter
        % <@Type> any
        % <@Size> 1x1
        val_stash 

        % <@Desc> Parent layer object managed by this container.
        % <@Role> Layer Structure
        % <@Type> LayerPackage
        % <@Size> 1x1
        a_cls
    end
    properties(Dependent)

        % <@Desc> Parameter table generated from dynamic properties.
        % <@Role> Parameter
        % <@Type> table
        % <@Size> 1xN (N: number of parameters)
        tab_parameter
    end
    properties(Dependent, Access=protected)

        % <@Desc> Parent layer interface for compatibility.
        % <@Role> Layer Structure
        % <@Type> LayerPackage
        % <@Size> 1x1
        parent

        % <@Desc> Parameter class has no children, but the property is kept for interface compatibility.
        % <@Role> Layer Structure
        % <@Type> none
        % <@Size> 0x1
        children
    end
    properties
        NoData = nan;
    end
    
    %% Constructor
    methods
        function obj = Parameter(a_parent,str_tag, CallBackChanged)
        % <@Desc>
        % Creates a parameter container for a parent layer.
        % <@Role>
        % Constructor
        % <@Summary>
        % Initialize the parameter container and callback.
        % <@Signatures>
        % [
        %   "obj = Parameter(a_parent, str_tag, CallBackChanged)"
        % ]
        % <@Parameters>
        % [
        %   {
        %     "Name": "a_parent",
        %     "Type": "LayerPackage",
        %     "Description": "Parent layer object.",
        %     "Required": true,
        %     "Default": "-"
        %   },
        %   {
        %     "Name": "str_tag",
        %     "Type": "string scalar",
        %     "Description": "Parameter tag.",
        %     "Required": false,
        %     "Default": "\"Parameter\""
        %   },
        %   {
        %     "Name": "CallBackChanged",
        %     "Type": "function_handle",
        %     "Description": "Callback executed after parameter changes.",
        %     "Required": false,
        %     "Default": "@(varargin) []"
        %   }
        % ]
        % <@Returns>
        % [
        %   {
        %     "Name": "obj",
        %     "Type": "Parameter",
        %     "Description": "Created parameter container."
        %   }
        % ]
            arguments
                a_parent 
                str_tag = "Parameter"
                CallBackChanged = @(varargin) [];
            end
            obj.a_cls        = a_parent;
            obj.l_managedTag = false;
            obj.str_tag      = str_tag;
            obj.CallbackChanged = CallBackChanged;
        end
    end

    methods
        function tab_para  = get.tab_parameter(obj)
            % <@Desc>
            % Builds a table from the registered parameter properties.
            % <@Role>
            % Parameter
            % <@Summary>
            % Convert dynamic parameter properties into a table.
            % <@Signatures>
            % [
            %   "tab_para = get.tab_parameter(obj)"
            % ]
            % <@Parameters>
            % [
            %   {
            %     "Name": "obj",
            %     "Type": "Parameter",
            %     "Description": "Target parameter container.",
            %     "Required": true,
            %     "Default": "-"
            %   }
            % ]
            % <@Returns>
            % [
            %   {
            %     "Name": "tab_para",
            %     "Type": "table",
            %     "Description": "Parameter table."
            %   }
            % ]
            sv_para = obj.sv_parameter;
            if isempty(sv_para)
                NoData = nan;       %#ok
                tab_para = table(NoData); %#ok
                return
            end
            h_para   = numel(sv_para);
            v_para   = sum( arrayfun(@(idx) numel(obj.(sv_para(idx))), 1:h_para) )/h_para;
            tab_para = array2table(zeros(v_para,h_para),"VariableNames",sv_para);
            % tab_para = array2table(nan(1,h_para),"VariableNames",sv_para);
            for i = 1:h_para
                tab_para.(sv_para(i)) = obj.(sv_para(i));
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
