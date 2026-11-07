classdef Parameter < auxiliary & LayerPackage
% Parameter container for LayerPackage-derived objects.
%
% It stores the parameters of one group of its owner as a table (`tab_parameter`): one
% row (a GlobalController: one row per controlled unit, named by the unit), one column
% per parameter. Writing the table checks it against the stored one, stores it, and
% reports each changed column with log_edit (tag: the group, e.g. "dynamics"; log:
% "edit <name>: <old> -> <new>"), so the owner layer and the layers above it mark what
% the edit makes stale. `s_lastEdited` is the name of the parameter of that edit, for the
% layers that tell parameters of one group apart (PowerNetwork: baseMVA and Hz).
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% bus = net.a_Bus{1};
% bus.tab_parameter                  % parameters of the bus as a table
% bus.tab_parameter.powerflow.V = 1.02;
% net.sct_stale.powerflow            % the edit makes the power flow of the network stale
% ```
%
% See also LayerPackage
    properties(SetAccess=private, Hidden) % Edit report
        s_lastEdited (1,1) string = ""               % Name of the parameter of the last edit, set before log_edit.
    end
    properties(Access=private) % Internal state
        a_cls                                        % Owner layer of this container. <@Type> LayerPackage
        sv_class (1,:) string = string.empty(1,0)    % Class of each column of tab_parameter, fixed by the defaults.
    end
    properties % Parameter
        tab_parameter = []                           % Parameter table: one column per parameter; writing it keeps the names, height and row names, checks the classes and logs each changed column. <@Type> table (1xN)
    end
    properties(Dependent, Access=protected) % Layer structure
        parent                                       % Parent in the layer structure: the owner layer. <@Type> LayerPackage
        children                                     % Children in the layer structure: none (kept for the LayerPackage interface). <@Type> none (0x1)
    end
    
    %% Constructor
    methods
        function obj = Parameter(a_parent, s_tag, sct_default)
        % Create a parameter container for a parent layer.
        %
        % Its tag names the parameter group (e.g. "powerflow", "dynamics"), the tag of its
        % edits. sct_default gives the parameters and their defaults (field: name, value:
        % default, of the class the parameter keeps); fields with N rows make an N-row table.
        % The rows of a container of a GlobalController are named by its controlled units.
            arguments (Input)
                a_parent                             % Parent layer object.
                s_tag       = "Parameter"            % Parameter tag.
                sct_default (1,1) struct = struct()  % Parameters and their defaults (field: name).
            end
            arguments (Output)
                obj                                  % Created parameter container.
            end
            % The tag is set before the parent: the owner is still being built, so its other
            % containers cannot be checked as siblings yet (set.s_tag).
            obj.s_tag = s_tag;
            obj.a_cls = a_parent;
            if isempty(fieldnames(sct_default))
                tab = table('Size', [1 0], 'VariableTypes', string.empty);
            else
                tab = struct2table(sct_default);
            end
            if isa(a_parent, "GlobalController") && height(tab) == numel(a_parent.controlledUnits) && height(tab) > 0
                tab.Properties.RowNames = string(a_parent.controlledUnits);
            end
            obj.sv_class = string(varfun(@class, tab, "OutputFormat", "cell"));
            obj.tab_parameter = tab;                 % the first assignment logs nothing (set.tab_parameter)
        end
    end

    methods
        function set.tab_parameter(obj, tab)
            % Store a table of the same parameters and log the changed columns.
            %
            % Nothing is stored when the names, the height or the row names differ, or a
            % column has another class than its default (sv_class).
            tab_old = obj.tab_parameter;
            if ~istable(tab_old)                     % constructor
                obj.tab_parameter = tab;
                return
            end
            % Nothing changed: table isequaln compares the names and their order, the row
            % names, the height and the values, but not the classes.
            if isequaln(tab_old, tab) && isequal(string(varfun(@class, tab, "OutputFormat", "cell")), obj.sv_class)
                return
            end
            sv_name = string(tab_old.Properties.VariableNames);
            n_row   = height(tab_old);
            if ~istable(tab) || height(tab) ~= n_row || ~isequal(tab.Properties.RowNames, tab_old.Properties.RowNames)
                error(msg("GUILDA:Parameter:TableMismatch", char(obj.s_tag), char(strjoin(sv_name, ", ")), char(string(n_row))))
            end
            sv_new = string(tab.Properties.VariableNames);
            if ~isequal(sv_new, sv_name)
                if numel(sv_new) ~= numel(sv_name) || ~all(ismember(sv_name, sv_new))
                    error(msg("GUILDA:Parameter:TableMismatch", char(obj.s_tag), char(strjoin(sv_name, ", ")), char(string(n_row))))
                end
                tab = tab(:, sv_name);
            end
            sv_class_new = string(varfun(@class, tab, "OutputFormat", "cell"));
            i_bad = find(sv_class_new ~= obj.sv_class, 1);
            if ~isempty(i_bad)
                error(msg("GUILDA:Parameter:ClassNameMismatch", char(sv_name(i_bad)), char(obj.sv_class(i_bad)), char(sv_class_new(i_bad))))
            end
            n_col = numel(sv_name);
            c_old = cell(1, n_col);
            c_new = cell(1, n_col);
            lv_changed = false(1, n_col);
            for i = 1:n_col
                c_old{i} = tab_old.(i);
                c_new{i} = tab.(i);
                lv_changed(i) = ~isequaln(c_old{i}, c_new{i});
            end
            if ~any(lv_changed)
                return
            end
            obj.tab_parameter = tab;
            for i = find(lv_changed)
                obj.s_lastEdited = sv_name(i);
                obj.log_edit("edit " + sv_name(i) + ": " + tools.value_text(c_old{i}) + " -> " + tools.value_text(c_new{i}), obj.s_tag);
            end
        end
        function p = get.parent(obj); p = obj.a_cls; end
        function c = get.children(~); c = {};        end
    end
end
