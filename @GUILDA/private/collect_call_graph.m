function sct_graph = collect_call_graph(sct_scan)
% Collect which properties and methods each System class method uses.
%
% >> sct_graph = collect_call_graph(find_doc_classes("user", false))
%
% The source is read with mtree (undocumented, so it is used in this file only)
% and nothing is evaluated. Callers are the methods and get./set. accessors of
% the System classes; Object classes only tell which members subclasses implement.
%
% Two forms are collected: recv.member, and member(recv, ...) when member is a
% method of the class of recv, or, with recv unknown, a name that only System methods
% have and MATLAB does not resolve. Also Class(...), Class.member, super calls and @helper.
%
% The class of a receiver comes from, in this order (the winning rule is stored):
%   self         the first input of a non-static method, the first output of a
%                constructor. Helper functions have no self.
%   declared     property class validator, or arguments block class
%   constructor  x = Class(...), or a Class.member reference
%   assignment   tracked through local assignments, for-loops, method outputs and
%                obj.p = value anywhere in the System classes
%   argument     every call of a helper passes this class in that position
%   name         naming rule: a_Bus -> Bus, net -> PowerNetwork, para_x -> Parameter
%   unique       the receiver is unknown, and one class defines a member of that name
%   candidates   the receiver is unknown, and several classes define it; all are kept
% A rule on a chain such as obj.a.b is the weakest link of the chain. self,
% declared and constructor give "certain" edges, candidates gives "candidates",
% and the others give "inferred". A variable assigned two different classes is unknown.
%
% Struct-like receivers give no edge: names such as opt, ctx or sct_x, name-value
% argument structs, variables built only by x.f = ..., values of a non-class type,
% and an UpperCamelCase member (name-value naming) on an unknown receiver.
%
% Local functions and private/ helpers have no node of their own: their references
% are attributed to every method that reaches them, with the helper's file and line.
%
% Output struct:
%   Nodes    : cell of "Class.member" and "Class.get.prop"
%   Edges    : struct array From, To (cell of nodes; several for candidates), Kind
%              ("method"|"property"|"parameter"|"subclass"), Confidence, Rule, File,
%              Line. One edge per From, To, Kind: the strongest reference, first line.
%   Dynamic  : struct array From, File, Line: obj.(name), feval, str2func and eval
%   Implementers : Map "Class.member" -> number of subclasses that implement it
%   Writes   : Map "Class.prop" -> cell of the method nodes that assign obj.prop = ...
%              (with a known receiver class, so no candidates)
%   Missing  : references on a known class to a member it does not have
%   Stats    : reference counts per confidence and per rule, before merging
    str_root = GUILDA.pwd();
    sct_ctx = build_context(sct_scan, str_root);
    sct_units = build_units(sct_scan, sct_ctx, str_root);

    % Repeated rounds let types learned in one unit reach the others.
    for i_round = 1:3
        sct_units = learn_types(sct_units, sct_ctx);
    end
    sct_graph = emit_graph(sct_units, sct_ctx);
end



%% Classes and members
function sct_ctx = build_context(sct_scan, str_root)
    sct_classes = sct_scan.Classes;
    bln_system = strcmp({sct_classes.Origin}, 'System');
    bln_object = strcmp({sct_classes.Origin}, 'Object');

    sct_ctx = struct();
    sct_ctx.root     = str_root;
    sct_ctx.info     = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_ctx.shorts   = containers.Map('KeyType', 'char', 'ValueType', 'char');
    sct_ctx.index    = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_ctx.implementers = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_ctx.props    = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_ctx.outputs  = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_ctx.packages = package_names(sct_scan, str_root);
    sct_ctx.system   = {sct_classes(bln_system).Name};

    cell_guilda = {sct_classes(bln_system | bln_object).Name};
    for i_class = find(bln_system)
        str_name = sct_classes(i_class).Name;
        meta_class = meta.class.fromName(str_name);
        if isempty(meta_class)
            warning(msg("GUILDA:collect_call_graph:NoClass", str_name));
            continue
        end
        sct_info = read_members(str_name, meta_class, cell_guilda);
        sct_ctx.info(str_name) = sct_info;
        sct_ctx.shorts(sct_info.Short) = str_name;
        add_to_index(sct_ctx.index, sct_info);
    end

    % Members each class gets only from a subclass, in the System or the Object tree.
    for i_class = find(bln_system | bln_object)
        str_name = sct_classes(i_class).Name;
        meta_class = meta.class.fromName(str_name);
        if isempty(meta_class)
            continue
        end
        cell_ancestors = setdiff(superclasses(str_name), {'handle'});
        cell_own = own_member_names(meta_class, str_name);
        for str_ancestor = reshape(cell_ancestors, 1, [])
            for str_member = cell_own
                str_key = [str_ancestor{1}, '.', str_member{1}];
                if isKey(sct_ctx.implementers, str_key)
                    sct_ctx.implementers(str_key) = [sct_ctx.implementers(str_key), {str_name}];
                else
                    sct_ctx.implementers(str_key) = {str_name};
                end
            end
        end
    end
end

function cell_names = package_names(sct_scan, str_root)
    cell_names = {'containers', 'matlab', 'java', 'py'};
    cell_rel = extractAfter({sct_scan.Files.Path}, [str_root, filesep]);
    cell_tokens = regexp(cell_rel, '(?:^|[/\\])\+(\w+)', 'tokens');
    for i_file = 1:numel(cell_tokens)
        for i_token = 1:numel(cell_tokens{i_file})
            cell_names{end+1} = cell_tokens{i_file}{i_token}{1}; %#ok<AGROW>
        end
    end
    cell_names = unique(cell_names);
end

function sct_info = read_members(str_name, meta_class, cell_guilda)
    sct_info = struct('Name', str_name, 'Short', short_name(str_name), ...
        'Methods', containers.Map('KeyType', 'char', 'ValueType', 'any'), ...
        'Props', containers.Map('KeyType', 'char', 'ValueType', 'any'), ...
        'Dynamic', any(strcmp(superclasses(str_name), 'dynamicprops')));
    meta_methods = meta_class.MethodList;
    for i_item = 1:numel(meta_methods)
        meta_m = meta_methods(i_item);
        str_defining = meta_m.DefiningClass.Name;
        if ~strcmp(meta_m.Name, 'empty') && any(strcmp(cell_guilda, str_defining))
            sct_info.Methods(meta_m.Name) = struct('Defining', str_defining, ...
                'Static', meta_m.Static, 'Abstract', meta_m.Abstract);
        end
    end
    meta_props = meta_class.PropertyList;
    for i_item = 1:numel(meta_props)
        meta_p = meta_props(i_item);
        str_defining = meta_p.DefiningClass.Name;
        if any(strcmp(cell_guilda, str_defining))
            str_type = '';
            if ~isempty(meta_p.Validation) && ~isempty(meta_p.Validation.Class)
                str_type = meta_p.Validation.Class.Name;
            end
            sct_info.Props(meta_p.Name) = struct('Defining', str_defining, ...
                'Type', str_type, 'Abstract', meta_p.Abstract);
        end
    end
end

function add_to_index(map_index, sct_info)
    % Member name -> the classes that define it (inherited members count once).
    for str_kind = ["Methods", "Props"]
        map_members = sct_info.(str_kind);
        for str_member = keys(map_members)
            sct_m = map_members(str_member{1});
            str_node = [sct_m.Defining, '.', str_member{1}];
            if isKey(map_index, str_member{1})
                sct_entry = map_index(str_member{1});
            else
                sct_entry = struct('Nodes', {{}}, 'IsMethod', true);
            end
            if ~any(strcmp(sct_entry.Nodes, str_node))
                sct_entry.Nodes{end+1} = str_node;
            end
            sct_entry.IsMethod = sct_entry.IsMethod && str_kind == "Methods";
            map_index(str_member{1}) = sct_entry;
        end
    end
end

function cell_own = own_member_names(meta_class, str_name)
    meta_m = meta_class.MethodList;
    meta_p = meta_class.PropertyList;
    cell_m = cell(1, numel(meta_m));
    for i = 1:numel(meta_m)
        if strcmp(meta_m(i).DefiningClass.Name, str_name) && ~meta_m(i).Abstract
            cell_m{i} = meta_m(i).Name;
        end
    end
    cell_p = cell(1, numel(meta_p));
    for i = 1:numel(meta_p)
        if strcmp(meta_p(i).DefiningClass.Name, str_name) && ~meta_p(i).Abstract
            cell_p{i} = meta_p(i).Name;
        end
    end
    cell_own = [cell_m, cell_p];
    cell_own = cell_own(~cellfun(@isempty, cell_own));
end

function str_short = short_name(str_name)
    cell_parts = strsplit(str_name, '.');
    str_short = cell_parts{end};
end



%% Units: one per function, reduced to plain events so that mtree is read only once
function sct_units = build_units(sct_scan, sct_ctx, str_root)
    % The files of each class: the classdef file and the @Class folder.
    sct_units = struct('Name', {}, 'Class', {}, 'IsMethod', {}, 'File', {}, 'Line', {}, ...
        'Self', {}, 'Inputs', {}, 'Outputs', {}, 'Declared', {}, 'StructVars', {}, 'Events', {}, ...
        'Scope', {}, 'Calls', {}, 'ArgTypes', {}, 'Env', {});
    cell_files = {sct_scan.Files.Path};
    cell_system = sct_ctx.system;
    for i_class = 1:numel(cell_system)
        str_class = cell_system{i_class};
        if ~isKey(sct_ctx.info, str_class)
            continue
        end
        str_file = sct_scan.Classes(strcmp({sct_scan.Classes.Name}, str_class)).File;
        [str_dir, ~] = fileparts(str_file);
        [~, str_dir_name] = fileparts(str_dir);
        cell_class_files = {str_file};
        if startsWith(str_dir_name, '@')
            cell_class_files = cell_files(startsWith(cell_files, [str_dir, filesep]));
        end
        for i_file = 1:numel(cell_class_files)
            sct_units = [sct_units, read_file_units(cell_class_files{i_file}, str_class, str_file, sct_ctx, str_root)]; %#ok<AGROW>
        end
    end
    sct_units = link_helpers(sct_units);
end

function sct_found = read_file_units(str_file, str_class, str_classdef_file, sct_ctx, str_root)
    sct_found = struct('Name', {}, 'Class', {}, 'IsMethod', {}, 'File', {}, 'Line', {}, ...
        'Self', {}, 'Inputs', {}, 'Outputs', {}, 'Declared', {}, 'StructVars', {}, 'Events', {}, ...
        'Scope', {}, 'Calls', {}, 'ArgTypes', {}, 'Env', {});
    T = mtree(str_file, '-file');
    if T.count == 0 || any(strcmp(T.kinds, 'ERR'))
        warning(msg("GUILDA:collect_call_graph:ParseFailed", str_file));
        return
    end
    sct_info = sct_ctx.info(str_class);
    str_rel = strrep(extractAfter(str_file, [str_root, filesep]), '\', '/');
    bln_private = contains(str_rel, '/private/');
    bln_classdef = strcmp(str_file, str_classdef_file);

    iv_in_methods = [];
    if bln_classdef
        iv_in_methods = T.mtfind('Kind', 'METHODS').Tree.mtfind('Kind', 'FUNCTION').indices;
    end
    iv_functions = T.mtfind('Kind', 'FUNCTION').indices;
    for k = 1:numel(iv_functions)
        fn = T.select(iv_functions(k));
        str_fname = strip(fn.Fname.string);
        str_base = regexprep(str_fname, '^(get|set)\.', '');
        bln_accessor = ~strcmp(str_base, str_fname);
        bln_member = isKey(sct_info.Methods, str_fname) || bln_accessor;
        if bln_classdef
            % Functions after the classdef block are local helpers.
            bln_method = any(iv_in_methods == iv_functions(k)) && bln_member;
        else
            % A method file holds one method; the rest of the file are helpers. MATLAB
            % lists private/ functions as methods, but they are helpers: no self.
            bln_method = k == 1 && bln_member && ~bln_private;
        end
        str_self_kind = 'none';
        if bln_method
            if strcmp(str_fname, sct_info.Short)
                str_self_kind = 'output';
            elseif bln_accessor || ~sct_info.Methods(str_fname).Static
                str_self_kind = 'input';
            end
        end
        sct_unit = read_function(T, fn, str_self_kind);
        sct_unit.Name = str_fname;
        sct_unit.Class = str_class;
        sct_unit.IsMethod = bln_method;
        sct_unit.File = str_rel;
        sct_unit.Line = fn.lineno;
        if bln_private
            sct_unit.Scope = private_scope(str_rel, k == 1);
        else
            sct_unit.Scope = str_rel;
        end
        sct_found(end+1) = sct_unit; %#ok<AGROW>
    end
end

function str_scope = private_scope(str_rel, bln_first)
    % The first function of a private file is visible to the whole class folder.
    if bln_first
        str_scope = ['private:', regexprep(str_rel, '/private/[^/]*$', '')];
    else
        str_scope = str_rel;
    end
end

function sct_unit = read_function(T, fn, str_self_kind)
    sct_unit = struct('Name', '', 'Class', '', 'IsMethod', false, 'File', '', 'Line', 0, ...
        'Self', '', 'Inputs', {node_names(fn.Ins)}, 'Outputs', {node_names(fn.Outs)}, ...
        'Declared', {cell(0, 2)}, 'StructVars', {{}}, 'Events', [], ...
        'Scope', '', 'Calls', {{}}, 'ArgTypes', {{}}, 'Env', []);
    if strcmp(str_self_kind, 'input') && ~isempty(sct_unit.Inputs)
        sct_unit.Self = sct_unit.Inputs{1};
    elseif strcmp(str_self_kind, 'output') && ~isempty(sct_unit.Outputs)
        sct_unit.Self = sct_unit.Outputs{1};
    end
    body = fn.Tree;

    % Arguments blocks: classes and name-value structs.
    decl = body.mtfind('Kind', 'PROPTYPEDECL');
    for i = decl.indices
        d = T.select(i);
        var = d.VarName;
        if var.isnull
            continue
        end
        if ~d.VarNamedField.isnull
            sct_unit.StructVars{end+1} = var.string;
        elseif ~d.VarType.isnull
            sct_unit.Declared(end+1, :) = {var.string, chain_text(d.VarType)};
        end
    end

    cell_events = {};
    iv_inner = [];
    iv = body.mtfind('Kind', {'DOT', 'DOTLP', 'CALL', 'LP', 'SUBSCR', 'EQUALS', 'FOR', 'ANONID', 'AT'}).indices;
    for i = iv
        n = T.select(i);
        switch n.kind
            case 'DOT'
                if strcmp(n.Left.kind, 'DOT')
                    iv_inner(end+1) = n.Left.indices; %#ok<AGROW>
                end
                if strcmp(n.Right.kind, 'FIELD')
                    cell_events{end+1} = struct('Type', 'dot', 'Recv', to_expr(n.Left), 'Member', n.Right.string, ...
                        'Line', n.lineno, 'Inner', any(iv_inner == i)); %#ok<AGROW>
                end
            case 'DOTLP'
                cell_events{end+1} = struct('Type', 'dynamic', 'Recv', to_expr(n.Left), 'Line', n.lineno); %#ok<AGROW>
            case {'CALL', 'LP'}
                % LP: a call inside brackets.
                cell_events = [cell_events, read_call(n)]; %#ok<AGROW>
            case 'AT'
                % @helper: a handle to a local or private function.
                if strcmp(n.Arg.kind, 'ID')
                    cell_events{end+1} = struct('Type', 'call', 'Name', n.Arg.string, 'Args', {{}}, 'Line', n.lineno); %#ok<AGROW>
                end
            case 'SUBSCR'
                % tools.vcellfun(@(x) ..., list) and the like, written with a dot.
                if strcmp(n.Left.kind, 'DOT') && ~isempty(regexp(chain_text(n.Left), '^tools\.\w*(cell|array)fun$', 'once'))
                    cell_events = [cell_events, bind_anon_params(list_nodes(n.Right), n.lineno)]; %#ok<AGROW>
                end
            case 'EQUALS'
                cell_events = [cell_events, read_assign(n)]; %#ok<AGROW>
            case 'FOR'
                x = n.Index;
                if strcmp(x.kind, 'ID')
                    cell_events{end+1} = struct('Type', 'assign', 'Var', x.string, 'Value', to_expr(n.Vector), 'Line', n.lineno); %#ok<AGROW>
                end
            case 'ANONID'
                cell_events{end+1} = struct('Type', 'declare', 'Var', n.string, 'Line', n.lineno); %#ok<AGROW>
        end
    end
    sct_unit.Events = cell_events;
end

function cell_events = read_call(n)
    cell_events = {};
    f = n.Left;
    cell_args = list_nodes(n.Right);
    switch f.kind
        case 'ATBASE'
            cell_events{1} = struct('Type', 'super', 'Name', f.Left.string, 'Base', chain_text(f.Right), 'Line', n.lineno);
        case 'ID'
            str_name = f.string;
            if any(strcmp(str_name, {'feval', 'str2func', 'eval', 'evalc', 'evalin'}))
                cell_events{1} = struct('Type', 'dynamic', 'Recv', struct('k', 'val'), 'Line', n.lineno);
                return
            end
            cell_events{1} = struct('Type', 'call', 'Name', str_name, 'Args', {cellfun(@to_expr, cell_args, 'UniformOutput', false)}, 'Line', n.lineno);
            if any(strcmp(str_name, {'cellfun', 'arrayfun'}))
                cell_events = [cell_events, bind_anon_params(cell_args, n.lineno)];
            end
    end
end

function cell_events = bind_anon_params(cell_args, r_line)
    % cellfun(@(x) ..., list): x is an element of list.
    cell_events = {};
    if numel(cell_args) < 2 || ~strcmp(cell_args{1}.kind, 'ANON')
        return
    end
    cell_params = list_nodes(cell_args{1}.Left);
    for i_param = 1:min(numel(cell_params), numel(cell_args) - 1)
        cell_events{end+1} = struct('Type', 'assign', 'Var', cell_params{i_param}.string, ...
            'Value', to_expr(cell_args{i_param + 1}), 'Line', r_line); %#ok<AGROW>
    end
end

function cell_events = read_assign(n)
    cell_events = {};
    l = n.Left;
    r = to_expr(n.Right);
    switch l.kind
        case 'LB'
            cell_outs = list_nodes(l.Arg);
            for i_out = 1:numel(cell_outs)
                if strcmp(cell_outs{i_out}.kind, 'ID')
                    sct_value = struct('k', '?');
                    if i_out == 1
                        sct_value = r;
                    end
                    cell_events{end+1} = struct('Type', 'assign', 'Var', cell_outs{i_out}.string, 'Value', sct_value, 'Line', n.lineno); %#ok<AGROW>
                end
            end
        case 'ID'
            cell_events{1} = struct('Type', 'assign', 'Var', l.string, 'Value', r, 'Line', n.lineno);
        otherwise
            lhs = l;
            while any(strcmp(lhs.kind, {'SUBSCR', 'CELL'}))
                lhs = lhs.Left;
            end
            switch lhs.kind
                case 'DOT'
                    if strcmp(lhs.Right.kind, 'FIELD')
                        cell_events{1} = struct('Type', 'pset', 'Recv', to_expr(lhs.Left), 'Member', lhs.Right.string, 'Value', r, 'Line', n.lineno);
                    end
                case 'ID'
                    cell_events{1} = struct('Type', 'assign', 'Var', lhs.string, 'Value', r, 'Line', n.lineno);
            end
    end
end

function sct_e = to_expr(n)
    % The part of an expression that can carry a receiver class.
    sct_e = struct('k', '?');
    if n.isnull
        return
    end
    switch n.kind
        case {'ID', 'ANONID'}
            sct_e = struct('k', 'id', 's', n.string);
        case 'DOT'
            if strcmp(n.Right.kind, 'FIELD')
                sct_e = struct('k', 'dot', 'l', to_expr(n.Left), 'f', n.Right.string);
            end
        case {'SUBSCR', 'CELL'}
            sct_e = struct('k', 'idx', 'l', to_expr(n.Left));
        case {'CALL', 'LP'}
            if strcmp(n.Left.kind, 'ID')
                cell_args = list_nodes(n.Right);
                sct_first = struct('k', '?');
                if ~isempty(cell_args)
                    sct_first = to_expr(cell_args{1});
                end
                sct_e = struct('k', 'call', 'f', n.Left.string, 'a', sct_first);
            end
        case {'PARENS', 'TRANS', 'DOTTRANS'}
            sct_e = to_expr(n.Arg);
        case 'LB'
            cell_rows = list_nodes(n.Arg);
            if isscalar(cell_rows)
                sct_e = to_expr(cell_rows{1});
                if strcmp(cell_rows{1}.kind, 'ROW')
                    cell_items = list_nodes(cell_rows{1}.Arg);
                    if isscalar(cell_items)
                        sct_e = to_expr(cell_items{1});
                    end
                end
            end
        case {'INT', 'DOUBLE', 'HEX', 'BINARY', 'STRING', 'CHARVECTOR', 'COLON', ...
                'PLUS', 'MINUS', 'MUL', 'DIV', 'DOTMUL', 'DOTDIV', 'EXP', 'DOTEXP', ...
                'EQ', 'NE', 'LT', 'GT', 'LE', 'GE', 'AND', 'OR', 'ANDAND', 'OROR', 'NOT', ...
                'UMINUS'}
            sct_e = struct('k', 'val');
    end
end

function cell_nodes = list_nodes(n)
    cell_nodes = {};
    if n.isnull
        return
    end
    L = n.List;
    for i = L.indices
        cell_nodes{end+1} = L.select(i); %#ok<AGROW>
    end
end

function cell_names = node_names(n)
    % Names of a function's inputs or outputs; "~" stays in place as an empty name.
    cell_names = {};
    cell_nodes = list_nodes(n);
    for i = 1:numel(cell_nodes)
        if strcmp(cell_nodes{i}.kind, 'ID')
            cell_names{end+1} = cell_nodes{i}.string; %#ok<AGROW>
        else
            cell_names{end+1} = ''; %#ok<AGROW>
        end
    end
end

function str = chain_text(n)
    str = '';
    switch n.kind
        case {'ID', 'FIELD'}
            str = n.string;
        case 'DOT'
            str = [chain_text(n.Left), '.', chain_text(n.Right)];
    end
end

function sct_units = link_helpers(sct_units)
    % Name -> unit within a file, and within the private folder of a class.
    map_scope = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for i = 1:numel(sct_units)
        map_scope([sct_units(i).File, '|', sct_units(i).Name]) = i;
        if startsWith(sct_units(i).Scope, 'private:')
            map_scope([sct_units(i).Scope, '|', sct_units(i).Name]) = i;
        end
    end
    for i = 1:numel(sct_units)
        str_private = ['private:', regexprep(sct_units(i).File, '(/private)?/[^/]*$', '')];
        cell_events = sct_units(i).Events;
        for k = 1:numel(cell_events)
            if strcmp(cell_events{k}.Type, 'call')
                r_target = 0;
                str_local = [sct_units(i).File, '|', cell_events{k}.Name];
                str_shared = [str_private, '|', cell_events{k}.Name];
                if isKey(map_scope, str_local)
                    r_target = map_scope(str_local);
                elseif isKey(map_scope, str_shared)
                    r_target = map_scope(str_shared);
                end
                cell_events{k}.Target = r_target;
            end
        end
        sct_units(i).Events = cell_events;
    end
end



%% Receiver types
% A type is {class, rule}; class is '' when unknown and '#value' for a value that is
% not a class object (struct, table, number).

function sct_units = learn_types(sct_units, sct_ctx)
    n_units = numel(sct_units);
    cell_args = repmat({containers.Map('KeyType', 'double', 'ValueType', 'any')}, 1, n_units);
    for i = 1:n_units
        cell_args{i} = containers.Map('KeyType', 'double', 'ValueType', 'any');
    end
    for i = 1:n_units
        sct_units(i).Env = build_env(sct_units(i), sct_units, sct_ctx);
    end
    for i = 1:n_units
        sct_u = sct_units(i);
        map_env = sct_u.Env;
        cell_events = sct_u.Events;
        for k = 1:numel(cell_events)
            sct_ev = cell_events{k};
            switch sct_ev.Type
                case 'pset'
                    learn_property(sct_ev, map_env, sct_units, sct_ctx);
                case 'call'
                    if sct_ev.Target > 0
                        for i_arg = 1:numel(sct_ev.Args)
                            merge_arg(cell_args{sct_ev.Target}, i_arg, ...
                                type_of(sct_ev.Args{i_arg}, map_env, sct_u, sct_units, sct_ctx));
                        end
                    end
            end
        end
        % What a method or helper returns.
        if ~isempty(sct_u.Outputs) && ~isempty(sct_u.Outputs{1}) && isKey(map_env, sct_u.Outputs{1})
            cell_type = map_env(sct_u.Outputs{1});
            if is_class_type(cell_type) && strcmp(sct_u.Self, sct_u.Outputs{1}) == false
                sct_ctx.outputs(output_key(sct_u)) = cell_type;
                if startsWith(sct_u.Name, 'get.')
                    str_member = extractAfter(sct_u.Name, 'get.');
                    sct_ctx.props([sct_u.Class, '.', str_member]) = cell_type;
                end
            end
        end
    end
    for i = 1:n_units
        sct_units(i).ArgTypes = cell_args{i};
    end
end

function str_key = output_key(sct_u)
    if sct_u.IsMethod
        str_key = [sct_u.Class, '.', sct_u.Name];
    else
        str_key = [sct_u.File, '|', sct_u.Name];
    end
end

function learn_property(sct_ev, map_env, sct_units, sct_ctx)
    cell_recv = type_of(sct_ev.Recv, map_env, struct('File', '', 'Name', ''), sct_units, sct_ctx);
    if ~is_class_type(cell_recv) || ~isKey(sct_ctx.info, cell_recv{1})
        return
    end
    sct_info = sct_ctx.info(cell_recv{1});
    if ~isKey(sct_info.Props, sct_ev.Member)
        return
    end
    cell_value = type_of(sct_ev.Value, map_env, struct('File', '', 'Name', ''), sct_units, sct_ctx);
    if ~is_class_type(cell_value)
        return
    end
    str_key = [sct_info.Props(sct_ev.Member).Defining, '.', sct_ev.Member];
    if isKey(sct_ctx.props, str_key)
        cell_old = sct_ctx.props(str_key);
        if ~strcmp(cell_old{1}, cell_value{1})
            sct_ctx.props(str_key) = {'', ''};  % Two classes: not determinable.
        end
    else
        sct_ctx.props(str_key) = {cell_value{1}, 'assignment'};
    end
end

function merge_arg(map_arg, i_arg, cell_type)
    if ~is_class_type(cell_type)
        cell_type = {'', ''};
    end
    if isKey(map_arg, i_arg)
        cell_old = map_arg(i_arg);
        if ~strcmp(cell_old{1}, cell_type{1})
            map_arg(i_arg) = {'', ''};
        end
    else
        map_arg(i_arg) = {cell_type{1}, weaker(cell_type{2}, 'argument')};
    end
end

function bln = is_class_type(cell_type)
    bln = ~isempty(cell_type{1}) && cell_type{1}(1) ~= '#';
end

function map_env = build_env(sct_u, sct_units, sct_ctx)
    map_env = containers.Map('KeyType', 'char', 'ValueType', 'any');
    cell_inputs = sct_u.Inputs;
    for i_in = 1:numel(cell_inputs)
        if ~isempty(cell_inputs{i_in})
            map_env(cell_inputs{i_in}) = name_type(cell_inputs{i_in}, sct_ctx);
        end
    end
    % Helper inputs: the class all callers agree on.
    if ~sct_u.IsMethod && isa(sct_u.ArgTypes, 'containers.Map')
        for i_in = 1:numel(cell_inputs)
            if ~isempty(cell_inputs{i_in}) && isKey(sct_u.ArgTypes, i_in) && ~isempty(sct_u.ArgTypes(i_in))
                cell_arg = sct_u.ArgTypes(i_in);
                if ~isempty(cell_arg{1})
                    map_env(cell_inputs{i_in}) = cell_arg;
                end
            end
        end
    end
    for i = 1:size(sct_u.Declared, 1)
        cell_type = class_from_name(sct_u.Declared{i, 2}, 'declared', sct_ctx);
        if ~isempty(cell_type{1})
            map_env(sct_u.Declared{i, 1}) = cell_type;
        end
    end
    for str_var = sct_u.StructVars
        map_env(str_var{1}) = {'#value', 'declared'};
    end
    bln_fixed = @(s) strcmp(s, sct_u.Self);
    if ~isempty(sct_u.Self)
        map_env(sct_u.Self) = {sct_u.Class, 'self'};
    end

    % Assignments are flow-insensitive: every right side of a variable must agree.
    cell_events = sct_u.Events;
    map_struct_writes = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    map_assigned = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    for k = 1:numel(cell_events)
        sct_ev = cell_events{k};
        switch sct_ev.Type
            case 'declare'
                if ~isKey(map_env, sct_ev.Var)
                    map_env(sct_ev.Var) = name_type(sct_ev.Var, sct_ctx);
                end
            case 'assign'
                map_assigned(sct_ev.Var) = true;
            case 'pset'
                if strcmp(sct_ev.Recv.k, 'id')
                    map_struct_writes(sct_ev.Recv.s) = true;
                end
        end
    end
    % x.f = ... with no other source of x: a struct built here.
    for str_var = keys(map_struct_writes)
        if ~isKey(map_assigned, str_var{1}) && ~isKey(map_env, str_var{1})
            map_env(str_var{1}) = {'#value', 'name'};
        end
    end
    for i_pass = 1:2
        map_seen = containers.Map('KeyType', 'char', 'ValueType', 'any');
        for k = 1:numel(cell_events)
            sct_ev = cell_events{k};
            if ~strcmp(sct_ev.Type, 'assign') || bln_fixed(sct_ev.Var)
                continue
            end
            cell_new = type_of(sct_ev.Value, map_env, sct_u, sct_units, sct_ctx);
            if isKey(map_seen, sct_ev.Var)
                cell_old = map_seen(sct_ev.Var);
                if isempty(cell_new{1})
                    % An unknown right side lowers a certain type.
                    if ~isempty(cell_old{1})
                        cell_new = {cell_old{1}, weaker(cell_old{2}, 'assignment')};
                    end
                elseif isempty(cell_old{1})
                    cell_new = {cell_new{1}, weaker(cell_new{2}, 'assignment')};
                elseif strcmp(cell_old{1}, '#conflict') || ~strcmp(cell_old{1}, cell_new{1})
                    cell_new = {'#conflict', 'assignment'};
                else
                    cell_new = {cell_new{1}, weaker(cell_old{2}, cell_new{2})};
                end
            end
            map_seen(sct_ev.Var) = cell_new;
        end
        for str_var = keys(map_seen)
            cell_type = map_seen(str_var{1});
            bln_input = any(strcmp(cell_inputs, str_var{1}));
            if isempty(cell_type{1})
                if ~bln_input
                    cell_type = name_type(str_var{1}, sct_ctx);
                else
                    continue
                end
            end
            map_env(str_var{1}) = cell_type;
        end
    end
end

function cell_type = type_of(sct_e, map_env, sct_u, sct_units, sct_ctx)
    cell_type = {'', ''};
    switch sct_e.k
        case 'val'
            cell_type = {'#value', 'name'};
        case 'id'
            if isKey(map_env, sct_e.s)
                cell_type = map_env(sct_e.s);
            elseif isKey(sct_ctx.shorts, sct_e.s)
                cell_type = {sct_ctx.shorts(sct_e.s), 'constructor'};
            end
        case 'idx'
            cell_type = type_of(sct_e.l, map_env, sct_u, sct_units, sct_ctx);
        case 'dot'
            str_chain = expr_chain(sct_e);
            if isKey(sct_ctx.info, str_chain)
                cell_type = {str_chain, 'constructor'};
                return
            end
            cell_left = type_of(sct_e.l, map_env, sct_u, sct_units, sct_ctx);
            cell_type = member_type(cell_left, sct_e.f, sct_ctx);
        case 'call'
            if isKey(map_env, sct_e.f)
                % A variable indexed or called. A value by its name alone may be a handle.
                cell_type = map_env(sct_e.f);
                if strcmp(cell_type{1}, '#value') && strcmp(cell_type{2}, 'name')
                    cell_type = {'', ''};
                end
                return
            end
            if isKey(sct_ctx.shorts, sct_e.f)
                cell_type = {sct_ctx.shorts(sct_e.f), 'constructor'};
                return
            end
            if any(strcmp(sct_e.f, {'struct', 'table', 'zeros', 'ones', 'eye', 'numel', 'size', 'length', ...
                    'string', 'char', 'sprintf', 'strcat', 'strjoin', 'double', 'logical', 'isempty', 'sum', 'any', 'all', 'find'}))
                cell_type = {'#value', 'name'};
                return
            end
            str_helper = [sct_u.File, '|', sct_e.f];
            if isKey(sct_ctx.outputs, str_helper)
                cell_type = sct_ctx.outputs(str_helper);
                return
            end
            cell_first = type_of(sct_e.a, map_env, sct_u, sct_units, sct_ctx);
            if is_class_type(cell_first) && isKey(sct_ctx.info, cell_first{1})
                sct_info = sct_ctx.info(cell_first{1});
                if isKey(sct_info.Methods, sct_e.f)
                    cell_type = member_type(cell_first, sct_e.f, sct_ctx);
                end
            end
    end
end

function cell_type = member_type(cell_left, str_member, sct_ctx)
    cell_type = {'', ''};
    if strcmp(cell_left{1}, '#value')
        % A struct field can hold an object: ctx.net.a_Bus. The field itself gets no edge.
        cell_type = cell_left;
        if isempty(regexp(str_member, '^[A-Z]', 'once'))
            cell_named = name_type(str_member, sct_ctx);
            if is_class_type(cell_named)
                cell_type = cell_named;
            end
        end
        return
    end
    if is_class_type(cell_left) && isKey(sct_ctx.info, cell_left{1})
        sct_info = sct_ctx.info(cell_left{1});
        if isKey(sct_info.Props, str_member)
            sct_p = sct_info.Props(str_member);
            if ~isempty(sct_p.Type) && isKey(sct_ctx.info, sct_p.Type)
                cell_type = {sct_p.Type, weaker(cell_left{2}, 'declared')};
                return
            elseif any(strcmp(sct_p.Type, {'double', 'single', 'logical', 'string', 'char', 'table', 'struct', 'function_handle', 'datetime'}))
                cell_type = {'#value', 'declared'};
                return
            end
            str_key = [sct_p.Defining, '.', str_member];
            if isKey(sct_ctx.props, str_key)
                cell_learned = sct_ctx.props(str_key);
                if ~isempty(cell_learned{1})
                    cell_type = {cell_learned{1}, weaker(cell_left{2}, cell_learned{2})};
                end
                return
            end
        elseif isKey(sct_info.Methods, str_member)
            str_key = [sct_info.Methods(str_member).Defining, '.', str_member];
            if isKey(sct_ctx.outputs, str_key)
                cell_learned = sct_ctx.outputs(str_key);
                cell_type = {cell_learned{1}, weaker(weaker(cell_left{2}, cell_learned{2}), 'assignment')};
            end
            return
        elseif sct_info.Dynamic
            cell_type = {'#value', cell_left{2}};
            return
        else
            return
        end
    end
    % UpperCamelCase on an unknown receiver is a struct field, such as r.Bus(i).
    cell_named = {'', ''};
    if isempty(regexp(str_member, '^[A-Z]', 'once'))
        cell_named = name_type(str_member, sct_ctx);
    end
    if ~isempty(cell_named{1})
        cell_type = cell_named;
        if ~isempty(cell_left{1}) && ~strcmp(cell_named{1}, '#value')
            cell_type{2} = weaker(cell_left{2}, 'name');
        end
    end
end

function str = expr_chain(sct_e)
    str = '';
    switch sct_e.k
        case 'id'
            str = sct_e.s;
        case 'dot'
            str_left = expr_chain(sct_e.l);
            if ~isempty(str_left)
                str = [str_left, '.', sct_e.f];
            end
    end
end

function cell_type = class_from_name(str_name, str_rule, sct_ctx)
    cell_type = {'', ''};
    if isKey(sct_ctx.info, str_name)
        cell_type = {str_name, str_rule};
    elseif any(strcmp(str_name, {'double', 'single', 'logical', 'string', 'char', 'table', 'struct', 'function_handle'}))
        cell_type = {'#value', str_rule};
    end
end

function cell_type = name_type(str_name, sct_ctx)
    % Naming rule of developer/naming-conventions.html, with the usual short forms.
    cell_type = {'', ''};
    if any(strcmp(str_name, {'opt', 'opts', 'option', 'options', 'ctx', 'mpc', 'args', 'arg', 'config', 'cfg', 'info', 'param'})) ...
            || ~isempty(regexp(str_name, '^(s|str|sct|tab|cell|map|iv|rv|cv|lv|sv|im|rm|cm|lm|sm|l|r|i|n|bln)_', 'once'))
        cell_type = {'#value', 'name'};
        return
    end
    if startsWith(str_name, 'para_') && isKey(sct_ctx.info, 'Parameter')
        cell_type = {'Parameter', 'name'};
        return
    end
    str_key = lower(regexprep(str_name, '^(a_|old_|new_|i(?=[A-Z]))', ''));
    str_key = regexprep(str_key, '(_?[ij]+|\d+|_old|_new)$', '');
    persistent map_alias
    if isempty(map_alias)
        map_alias = containers.Map( ...
            {'net', 'network', 'comp', 'br', 'bra', 'lc', 'avr', 'pss', 'gc'}, ...
            {'PowerNetwork', 'PowerNetwork', 'Component', 'Branch', 'Branch', 'LocalController', 'LocalController', 'LocalController', 'GlobalController'});
    end
    if isKey(map_alias, str_key)
        str_class = map_alias(str_key);
    else
        str_class = '';
        for str_short = keys(sct_ctx.shorts)
            if strcmpi(str_short{1}, str_key)
                str_class = sct_ctx.shorts(str_short{1});
                break
            end
        end
    end
    if ~isempty(str_class) && isKey(sct_ctx.info, str_class)
        cell_type = {str_class, 'name'};
    end
end

function str_rule = weaker(str_a, str_b)
    cell_order = {'self', 'constructor', 'declared', 'assignment', 'argument', 'name', 'unique'};
    i_a = find(strcmp(cell_order, str_a), 1);
    i_b = find(strcmp(cell_order, str_b), 1);
    if isempty(i_a), i_a = 0; end
    if isempty(i_b), i_b = 0; end
    if i_a >= i_b
        str_rule = str_a;
    else
        str_rule = str_b;
    end
    if isempty(str_rule)
        str_rule = 'name';
    end
end



%% Edges
function sct_graph = emit_graph(sct_units, sct_ctx)
    n_units = numel(sct_units);
    cell_refs = cell(1, n_units);
    cell_dynamic = cell(1, n_units);
    cell_calls = cell(1, n_units);
    sct_missing = struct('From', {}, 'Class', {}, 'Member', {}, 'Rule', {}, 'File', {}, 'Line', {});
    for i = 1:n_units
        sct_units(i).Env = build_env(sct_units(i), sct_units, sct_ctx);
        [cell_refs{i}, cell_dynamic{i}, cell_calls{i}, sct_miss_i] = read_refs(sct_units(i), sct_units, sct_ctx);
        sct_missing = [sct_missing, sct_miss_i]; %#ok<AGROW>
    end

    % Each method: its own references plus those of the helpers it reaches.
    map_edges = containers.Map('KeyType', 'char', 'ValueType', 'any');
    sct_dynamic = struct('From', {}, 'File', {}, 'Line', {});
    map_conf = containers.Map({'certain', 'inferred', 'candidates'}, {0, 0, 0});
    map_rule = containers.Map('KeyType', 'char', 'ValueType', 'double');
    map_writes = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for i = find([sct_units.IsMethod])
        str_from = from_node(sct_units(i), sct_ctx);
        iv_reach = i;
        iv_todo = cell_calls{i};
        while ~isempty(iv_todo)
            r = iv_todo(1);
            iv_todo(1) = [];
            % Other methods get their own node; only helpers are absorbed.
            if ~any(iv_reach == r) && ~sct_units(r).IsMethod
                iv_reach(end+1) = r; %#ok<AGROW>
                iv_todo = [iv_todo, cell_calls{r}]; %#ok<AGROW>
            end
        end
        for r = iv_reach
            for k = 1:numel(cell_refs{r})
                sct_ref = cell_refs{r}{k};
                if strcmp(sct_ref.Kind, 'write')
                    str_prop = sct_ref.To{1};
                    if ~isKey(map_writes, str_prop)
                        map_writes(str_prop) = {str_from};
                    elseif ~any(strcmp(map_writes(str_prop), str_from))
                        map_writes(str_prop) = [map_writes(str_prop), {str_from}];
                    end
                    continue
                end
                map_conf(sct_ref.Confidence) = map_conf(sct_ref.Confidence) + 1;
                if ~isKey(map_rule, sct_ref.Rule), map_rule(sct_ref.Rule) = 0; end
                map_rule(sct_ref.Rule) = map_rule(sct_ref.Rule) + 1;
                add_edge(map_edges, str_from, sct_ref, sct_units(r).File);
            end
            for k = 1:numel(cell_dynamic{r})
                sct_dynamic(end+1) = struct('From', str_from, 'File', sct_units(r).File, 'Line', cell_dynamic{r}(k)); %#ok<AGROW>
            end
        end
    end

    cell_edges = values(map_edges);
    sct_edges = [cell_edges{:}];
    cell_nodes = {};
    if ~isempty(sct_edges)
        cell_to = [sct_edges.To];
        cell_nodes = unique([{sct_edges.From}, cell_to]);
    end
    map_impl = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for str_key = keys(sct_ctx.implementers)
        if any(strcmp(cell_nodes, str_key{1}))
            map_impl(str_key{1}) = numel(unique(sct_ctx.implementers(str_key{1})));
        end
    end
    sct_graph = struct('Nodes', {cell_nodes}, 'Edges', sct_edges, 'Dynamic', sct_dynamic, ...
        'Implementers', map_impl, 'Writes', map_writes, 'Missing', sct_missing, ...
        'Stats', struct('Confidence', map_conf, 'Rule', map_rule));
end

function str_from = from_node(sct_u, sct_ctx)
    str_base = regexprep(sct_u.Name, '^(get|set)\.', '');
    sct_info = sct_ctx.info(sct_u.Class);
    if strcmp(str_base, sct_u.Name) && isKey(sct_info.Methods, sct_u.Name)
        str_from = [sct_info.Methods(sct_u.Name).Defining, '.', sct_u.Name];
    else
        str_from = [sct_u.Class, '.', sct_u.Name];
    end
end

function add_edge(map_edges, str_from, sct_ref, str_file)
    cell_order = {'certain', 'inferred', 'candidates'};
    str_key = [str_from, '>', strjoin(sct_ref.To, '|'), '>', sct_ref.Kind];
    sct_new = struct('From', str_from, 'To', {sct_ref.To}, 'Kind', sct_ref.Kind, ...
        'Confidence', sct_ref.Confidence, 'Rule', sct_ref.Rule, 'File', str_file, 'Line', sct_ref.Line);
    if isKey(map_edges, str_key)
        sct_old = map_edges(str_key);
        if find(strcmp(cell_order, sct_new.Confidence)) >= find(strcmp(cell_order, sct_old.Confidence))
            return
        end
    end
    map_edges(str_key) = sct_new;
end

function [cell_refs, iv_dynamic, iv_calls, sct_missing] = read_refs(sct_u, sct_units, sct_ctx)
    cell_refs = {};
    iv_dynamic = [];
    iv_calls = [];
    sct_missing = struct('From', {}, 'Class', {}, 'Member', {}, 'Rule', {}, 'File', {}, 'Line', {});
    map_env = sct_u.Env;
    cell_events = sct_u.Events;
    for k = 1:numel(cell_events)
        sct_ev = cell_events{k};
        switch sct_ev.Type
            case 'dot'
                str_chain = expr_chain(struct('k', 'dot', 'l', sct_ev.Recv, 'f', sct_ev.Member));
                if isKey(sct_ctx.info, str_chain)
                    % pkg.Class(...) is a constructor call; pkg.Class.member comes next.
                    if ~sct_ev.Inner
                        cell_refs{end+1} = constructor_ref(str_chain, sct_ev.Line, sct_ctx); %#ok<AGROW>
                    end
                    continue
                end
                [sct_ref, sct_miss] = resolve_dot(sct_ev, map_env, sct_u, sct_units, sct_ctx);
                if ~isempty(sct_ref)
                    cell_refs{end+1} = sct_ref; %#ok<AGROW>
                end
                sct_missing = [sct_missing, sct_miss]; %#ok<AGROW>
            case 'call'
                if isKey(map_env, sct_ev.Name)
                    continue  % An indexed variable.
                end
                if sct_ev.Target > 0
                    if strcmp(sct_ev.Name, sct_ctx.info(sct_u.Class).Short)
                        cell_refs{end+1} = constructor_ref(sct_u.Class, sct_ev.Line, sct_ctx); %#ok<AGROW>
                    elseif sct_units(sct_ev.Target).IsMethod
                        % A method of this class called by name: same as the method form.
                        cell_refs = [cell_refs, method_form(sct_ev, map_env, sct_u, sct_units, sct_ctx)]; %#ok<AGROW>
                    else
                        iv_calls(end+1) = sct_ev.Target; %#ok<AGROW>
                    end
                elseif isKey(sct_ctx.shorts, sct_ev.Name)
                    cell_refs{end+1} = constructor_ref(sct_ctx.shorts(sct_ev.Name), sct_ev.Line, sct_ctx); %#ok<AGROW>
                else
                    cell_refs = [cell_refs, method_form(sct_ev, map_env, sct_u, sct_units, sct_ctx)]; %#ok<AGROW>
                end
            case 'super'
                if isKey(sct_ctx.info, sct_ev.Base)
                    sct_base = sct_ctx.info(sct_ev.Base);
                    str_member = sct_ev.Name;
                    if strcmp(str_member, sct_u.Self)
                        str_member = sct_base.Short;  % obj@Base(...): the constructor.
                    end
                    if isKey(sct_base.Methods, str_member)
                        cell_refs{end+1} = make_ref({[sct_base.Methods(str_member).Defining, '.', str_member]}, 'method', 'self', sct_ev.Line); %#ok<AGROW>
                    end
                end
            case 'pset'
                % recv.prop = value: a write, kept apart from the edges.
                cell_recv = type_of(sct_ev.Recv, map_env, sct_u, sct_units, sct_ctx);
                if is_class_type(cell_recv) && isKey(sct_ctx.info, cell_recv{1})
                    sct_info = sct_ctx.info(cell_recv{1});
                    if isKey(sct_info.Props, sct_ev.Member)
                        cell_refs{end+1} = make_ref({[sct_info.Props(sct_ev.Member).Defining, '.', sct_ev.Member]}, ...
                            'write', cell_recv{2}, sct_ev.Line); %#ok<AGROW>
                    end
                end
            case 'dynamic'
                cell_recv = type_of(sct_ev.Recv, map_env, sct_u, sct_units, sct_ctx);
                if ~strcmp(cell_recv{1}, '#value') || strcmp(sct_ev.Recv.k, 'val')
                    if ~isempty(cell_recv{1}) || strcmp(sct_ev.Recv.k, 'val')
                        iv_dynamic(end+1) = sct_ev.Line; %#ok<AGROW>
                    end
                end
        end
    end
end

function sct_ref = constructor_ref(str_class, r_line, sct_ctx)
    str_short = sct_ctx.info(str_class).Short;
    sct_ref = make_ref({[str_class, '.', str_short]}, 'method', 'constructor', r_line);
end

function cell_refs = method_form(sct_ev, map_env, sct_u, sct_units, sct_ctx)
    % member(recv, ...): only when the receiver class is known and has that method.
    cell_refs = {};
    if isempty(sct_ev.Args)
        return
    end
    cell_first = type_of(sct_ev.Args{1}, map_env, sct_u, sct_units, sct_ctx);
    if strcmp(cell_first{1}, '#value')
        return
    end
    if ~is_class_type(cell_first) || ~isKey(sct_ctx.info, cell_first{1})
        % Unknown receiver: a name that is only a System method, never a MATLAB function.
        if isKey(sct_ctx.index, sct_ev.Name) && sct_ctx.index(sct_ev.Name).IsMethod && exist(sct_ev.Name) == 0 %#ok<EXIST>
            sct_entry = sct_ctx.index(sct_ev.Name);
            str_rule = 'candidates';
            if isscalar(sct_entry.Nodes), str_rule = 'unique'; end
            cell_refs{1} = make_ref(sct_entry.Nodes, 'method', str_rule, sct_ev.Line);
        end
        return
    end
    sct_info = sct_ctx.info(cell_first{1});
    if isKey(sct_info.Methods, sct_ev.Name)
        sct_m = sct_info.Methods(sct_ev.Name);
        str_kind = 'method';
        if sct_m.Abstract
            str_kind = 'subclass';
        end
        cell_refs{1} = make_ref({[sct_m.Defining, '.', sct_ev.Name]}, str_kind, cell_first{2}, sct_ev.Line);
    elseif strcmp(cell_first{2}, 'self') && isKey(sct_ctx.implementers, [sct_info.Name, '.', sct_ev.Name])
        cell_refs{1} = make_ref({[sct_info.Name, '.', sct_ev.Name]}, 'subclass', 'self', sct_ev.Line);
    end
end

function [sct_ref, sct_miss] = resolve_dot(sct_ev, map_env, sct_u, sct_units, sct_ctx)
    sct_ref = [];
    sct_miss = struct('From', {}, 'Class', {}, 'Member', {}, 'Rule', {}, 'File', {}, 'Line', {});
    str_member = sct_ev.Member;
    cell_recv = type_of(sct_ev.Recv, map_env, sct_u, sct_units, sct_ctx);
    if strcmp(cell_recv{1}, '#value')
        return
    end
    if strcmp(sct_ev.Recv.k, 'id') && any(strcmp(sct_ev.Recv.s, sct_ctx.packages)) && ~isKey(map_env, sct_ev.Recv.s)
        return
    end
    if is_class_type(cell_recv) && isKey(sct_ctx.info, cell_recv{1})
        sct_info = sct_ctx.info(cell_recv{1});
        str_rule = cell_recv{2};
        if isKey(sct_info.Methods, str_member)
            sct_m = sct_info.Methods(str_member);
            str_kind = 'method';
            if sct_m.Abstract, str_kind = 'subclass'; end
            sct_ref = make_ref({[sct_m.Defining, '.', str_member]}, str_kind, str_rule, sct_ev.Line);
            return
        elseif isKey(sct_info.Props, str_member)
            sct_p = sct_info.Props(str_member);
            str_kind = 'property';
            if sct_p.Abstract, str_kind = 'subclass'; end
            sct_ref = make_ref({[sct_p.Defining, '.', str_member]}, str_kind, str_rule, sct_ev.Line);
            return
        elseif sct_info.Dynamic
            sct_ref = make_ref({[sct_info.Name, '.', str_member]}, 'parameter', str_rule, sct_ev.Line);
            return
        elseif isKey(sct_ctx.implementers, [sct_info.Name, '.', str_member])
            sct_ref = make_ref({[sct_info.Name, '.', str_member]}, 'subclass', str_rule, sct_ev.Line);
            return
        end
        sct_miss(1).From = [sct_u.Class, '.', sct_u.Name];
        sct_miss(1).Class = sct_info.Name;
        sct_miss(1).Member = str_member;
        sct_miss(1).Rule = str_rule;
        sct_miss(1).File = sct_u.File;
        sct_miss(1).Line = sct_ev.Line;
        % self, declared and constructor are facts; the member is then not a class member.
        if any(strcmp(str_rule, {'self', 'declared', 'constructor'}))
            return
        end
    end

    % Unknown receiver: name-value fields are UpperCamelCase.
    if ~isempty(regexp(str_member, '^[A-Z]', 'once')) || ~isKey(sct_ctx.index, str_member)
        return
    end
    sct_entry = sct_ctx.index(str_member);
    str_kind = 'property';
    if sct_entry.IsMethod, str_kind = 'method'; end
    if isscalar(sct_entry.Nodes)
        sct_ref = make_ref(sct_entry.Nodes, str_kind, 'unique', sct_ev.Line);
    else
        sct_ref = make_ref(sct_entry.Nodes, str_kind, 'candidates', sct_ev.Line);
    end
end

function sct_ref = make_ref(cell_to, str_kind, str_rule, r_line)
    switch str_rule
        case {'self', 'declared', 'constructor'}
            str_conf = 'certain';
        case 'candidates'
            str_conf = 'candidates';
        otherwise
            str_conf = 'inferred';
    end
    sct_ref = struct('To', {reshape(cell_to, 1, [])}, 'Kind', str_kind, 'Confidence', str_conf, 'Rule', str_rule, 'Line', r_line);
end
