function update_keymap(opt)
% Rebuild the model key map from the classes on the path
%
% Clears the cache of GUILDA.keymap, builds it again from the Constant `key` of the
% Component, Branch, LocalController and GlobalController classes that
% GUILDA.dictionary finds, and prints the keys. The methods that take a model key
% (Bus.add_component, Bus.replace_component, PowerNetwork.add_branch,
% Component.add_local_controller, PowerNetwork.add_global_controller) validate and
% dispatch the key through GUILDA.keymap, so a new or removed model class is used
% from then on.
%
% GUILDA calls it at startup (setting UpdateKeyMap of the Startup section: "disp" prints
% the keys, "silent" does not, "none" skips it). Call it yourself after adding or
% removing a model class or changing its key, to use the new keys without restarting
% GUILDA.
%
% For developers, `Signature=true` also regenerates
% `_GUILDAsystem/resources/functionSignatures.json`, the code suggestions of the methods
% that build or remove a model or an event of a Scenario, of the constructors and the edit
% methods of the events (EventFault, ...; the key of a constructor is the class name), of the analysis methods
% (simulate, get_sys and the power flow, OPF and CPF calculations) and of the plot_*,
% disp_*, get_* and export methods of the results, from their arguments blocks. DrawerOptionDialog builds its forms
% from the same file. It holds the names, kinds, classes and defaults of the arguments,
% the trailing comment of each argument line as its purpose, the model keys of the
% category for `Key`, and the tags of the current object for the tag arguments (and, for
% the input names of Scenario.add_input and EventInput.edit, the inputs of the chosen
% component). The
% "type" of an argument declared with size (1,1) also has the attribute "scalar" (in
% each alternative of a tag argument); the GUI uses it to choose a single-choice widget.
% MATLAB applies a resources/functionSignatures.json only to the functions of the folder
% that holds it, not to a subfolder that is a separate path entry. So it also writes
% `_GUILDAsystem/_auxiliary/resources/functionSignatures.json` with the entries of the
% classes whose class folder is in `_GUILDAsystem/_auxiliary` (Scenario, the events, the results,
% PowerSystemModel); the file in `_GUILDAsystem/resources` keeps every entry for the GUI.
% Each file is written only when its content changes.
% Run it after editing the arguments block of one of these methods.
%
% <@Examples>
% ```matlab
% GUILDA.update_keymap
% GUILDA.update_keymap(Signature=true)
% ```
%
% See also GUILDA.keymap, GUILDA.dictionary
    arguments (Input)
        opt.Signature (1,1) logical = false  % Also regenerate the functionSignatures.json of _GUILDAsystem and _GUILDAsystem/_auxiliary (for developers).
    end

    clear keymap    % the persistent cache of GUILDA.keymap
    disp(newline+" === Update Key List === ")
    for s_cat = ["Component", "Branch", "LocalController", "GlobalController"]
        disp(newline+"  @"+s_cat+": ")
        dic    = GUILDA.keymap(s_cat);
        sv_key = keys(dic);
        if isempty(sv_key)
            continue
        end
        n_max  = max(strlength(sv_key));
        for i = 1:numel(sv_key)
            padding = string(repmat(' ', 1, n_max - strlength(sv_key(i)) + 1));
            disp("  addkey: <key> " + sv_key(i) + padding + " --> <class> " + dic(sv_key(i)))
        end
    end

    if opt.Signature
        c_method = sig_methods();
        sv_entry = strings(0,1);
        lv_aux   = false(0,1);
        s_aux    = fullfile(GUILDA.pwd(), "_GUILDAsystem", "_auxiliary");
        for i = 1:size(c_method, 1)
            sv_entry(end+1,1) = method_entry(c_method{i,:});    %#ok<AGROW>
            % The class folder @<class> of the classdef file is in _auxiliary
            lv_aux(end+1,1)   = fileparts(fileparts(which(c_method{i,1}))) == s_aux;    %#ok<AGROW>
        end
        % Every entry: read by the GUI (DrawerOptionDialog, DrawerResultGUI); MATLAB uses
        % the entries of the classes of _GUILDAsystem
        write_signatures(fullfile(GUILDA.pwd(), "_GUILDAsystem", "resources", "functionSignatures.json"), sv_entry)
        % The entries of the classes of _auxiliary, for MATLAB: a separate path entry does
        % not use the resources folder of its parent
        write_signatures(fullfile(s_aux, "resources", "functionSignatures.json"), sv_entry(lv_aux))
    end
end

function write_signatures(s_file, sv_entry)
    % Write a functionSignatures.json with the given entries, only when it changes
    arguments (Input)
        s_file   (1,1) string  % Path of functionSignatures.json.
        sv_entry (:,1) string  % JSON text of the entries (method_entry).
    end
    s_json = "{" + newline + "  ""_schemaVersion"": ""1.0.0""," + newline ...
           + join(sv_entry, "," + newline) + newline + "}" + newline;
    if isfile(s_file) && string(fileread(s_file, "Encoding", "UTF-8")) == s_json
        return
    end
    if ~isfolder(fileparts(s_file))
        mkdir(fileparts(s_file));
    end
    file_id = fopen(s_file, 'w', 'n', 'UTF-8');
    fprintf(file_id, '%s', char(s_json));
    fclose(file_id);
    validateFunctionSignaturesJSON(char(s_file))
end

function c_method = sig_methods()
    % Methods in functionSignatures.json: class, method, and the arguments whose choices
    % are tags of the current object {argument, expression on obj, other accepted types}
    arguments (Output)
        c_method  % n-by-3 cell: class name, method name, n-by-3 cell of tag arguments.
    end
    % Tags of the network of a Scenario: buses, branches, components, controllers, disturbances;
    % the input names of the component given as unit (an earlier argument)
    s_bus    = "string(obj.a_PowerNetwork.a_Bus)";
    s_branch = "string(obj.a_PowerNetwork.a_Branch)";
    s_comp   = "[strings(0,1); tools.vcellfun(@(b) string(b.a_Component(:)), obj.a_PowerNetwork.a_Bus)]";
    s_unit   = "[strings(0,1); tools.vcellfun(@(b) string(b.a_Component(:)), obj.a_PowerNetwork.a_Bus); " ...
             + "string(obj.a_PowerNetwork.a_GlobalController(:)); " ...
             + "tools.vcellfun(@(c) string(c.a_LocalController(:)), tools.vcellfun(@(b) b.a_Component(:), obj.a_PowerNetwork.a_Bus))]";
    s_dist   = "unique([obj.tab_event.Tag; obj.tab_offset.Tag; obj.tab_input.Tag], ""stable"")";
    s_uname  = "obj.a_PowerNetwork.get_element(unit).sv_u";
    % The same tags for the edit method of an event: the network of its scenario
    s_net    = "obj.a_Scenario.a_PowerNetwork";
    s_elem   = "obj.get_element_table().Tag";
    s_group  = "[""powerflow""; ""dynamics""; ""operation""; ""OPF""; ""graph""]";
    s_lcon = "[string(obj.a_LocalController); string(cellfun(@(c) strjoin([string(c.a_LocalController); """"], """"), obj.a_LocalController, ""UniformOutput"", false))]";
    c_method = {
        "Bus",          "add_component",            cell(0,3)
        "Bus",          "replace_component",        {"s_tag",      "string(obj.a_Component)",         "string"}
        "Bus",          "remove_component",         {"s_tag",      "string(obj.a_Component)",         "string"}
        "Component",    "add_local_controller",     cell(0,3)
        "Component",    "remove_local_controller",  {"s_tag",      s_lcon,                            "string"}
        "PowerNetwork", "add_bus",                  cell(0,3)
        "PowerNetwork", "add_branch",               {"from_to",    "string(obj.a_Bus)",               ["string","numeric"]}
        "PowerNetwork", "add_global_controller",    cell(0,3)
        "PowerNetwork", "remove_branch",            {"tag",        "string(obj.a_Branch)",            "string"}
        "PowerNetwork", "remove_bus",               {"sr_BusTag",  "string(obj.a_Bus)",               "string"}
        "PowerNetwork", "remove_global_controller", {"sr_GconTag", "string(obj.a_GlobalController)",  "string"}
        "PowerNetwork", "add_scenario",             cell(0,3)
        "PowerNetwork", "remove_scenario",          {"sr_tag",     "string(obj.a_Scenario)",          "string"}
        "PowerNetwork", "simulate",                 {"s_scenario", "string(obj.a_Scenario)",          "string"}
        "PowerNetwork", "calculate_powerflow",               cell(0,3)
        "PowerNetwork", "calculate_optimal_powerflow",       cell(0,3)
        "PowerNetwork", "calculate_continuation_powerflow",  cell(0,3)
        "PowerNetwork", "initialize",               cell(0,3)
        "PowerNetwork", "get_element",              {"Tag",        "[" + s_elem + "; string(obj.a_Scenario(:))]", "string"}
        "PowerNetwork", "get_element_table",        {"Owner",      s_elem,                            "string"}
        "PowerNetwork", "get_parameter",            {"Group",      s_group,                           "string"; "Owner", s_elem, "string"}
        "PowerNetwork", "set_parameter",            {"Group",      s_group,                           "string"}
        "PowerSystemModel", "get_sys",              cell(0,3)    % the linearization of every layer (net.get_sys)
        "LocalController", "add_local_controller",  cell(0,3)
        "LocalController", "remove_local_controller", cell(0,3)
        "Scenario",     "add_fault",                {"target",     "[" + s_bus + "; " + s_branch + "]", "string"}
        "Scenario",     "add_trip",                 {"unit",       s_unit,                            "string"}
        "Scenario",     "add_open_branch",          {"branch",     s_branch,                          "string"}
        "Scenario",     "add_offset",               {"unit",       s_comp,                            "string"}
        "Scenario",     "add_input",                {"unit",       s_comp,                            "string"; "name", s_uname, "string"}
        "Scenario",     "remove_event",             {"tag",        s_dist,                            "string"}
        "EventFault",      "EventFault",            cell(0,3)    % constructors: no network, no tags
        "EventTrip",       "EventTrip",             cell(0,3)
        "EventOpenBranch", "EventOpenBranch",       cell(0,3)
        "EventOffset",     "EventOffset",           cell(0,3)
        "EventInput",      "EventInput",            cell(0,3)
        "EventFault",      "edit",                  {"Target", replace("[" + s_bus + "; " + s_branch + "]", "obj.a_PowerNetwork", s_net), "string"}
        "EventTrip",       "edit",                  {"Unit",   replace(s_unit,   "obj.a_PowerNetwork", s_net), "string"}
        "EventOpenBranch", "edit",                  {"Branch", replace(s_branch, "obj.a_PowerNetwork", s_net), "string"}
        "EventOffset",     "edit",                  {"Unit",   replace(s_comp,   "obj.a_PowerNetwork", s_net), "string"}
        "EventInput",      "edit",                  {"Unit",   replace(s_comp,   "obj.a_PowerNetwork", s_net), "string"; ...
                                                     "Name",   s_net + ".get_element(obj.s_unit).sv_u",       "string"}
        };
    % Analysis results: the methods a result GUI offers
    sct_result = struct( ...
        "ResultPF",  ["plot_voltage", "plot_branch", "plot_convergence", "plot_spring_model", ...
                      "plot_diagram", "plot_single_line_diagram", "disp_summary", "disp_bus", "disp_branch", "disp_violation", "get_summary", "export"], ...
        "ResultOPF", ["plot_dispatch", "plot_lmp", "plot_iteration", "disp_summary", "disp_binding", "get_lmp", "get_summary", "export"], ...
        "ResultCPF", ["plot_pvcurve", "plot_diagram", "plot_spring_model", "plot_stability_index", "plot_generator", ...
                      "plot_branch", "get_point", "export"], ...
        "ResultODE", ["plot_trajectory", "get_trajectory", "plot_spring_model", "plot_diagram", "get_point", "export"], ...
        "ResultLIN", ["plot_eigenvalue", "plot_eigenvalue_path", "plot_matrix", "plot_kernel", "plot_participation", "plot_eigenvector", ...
                      "plot_reduced_matrix", "plot_contribution", "get_mode", "get_participation", "get_ss", "get_contribution", "get_eigenvalue", "get_eigenvector", ...
                      "get_kernel", "get_reduced_matrix", "disp_summary", "disp_mode"]);
    for s_class = string(fieldnames(sct_result)).'
        for s_method = sct_result.(s_class)
            c_method(end+1, :) = {s_class, s_method, cell(0,3)};    %#ok<AGROW>
        end
    end
    % plot_trajectory, get_trajectory: the bus quantities and the state, input and output
    % names of the components (not of the controllers); they evaluate on an empty result
    % (tab_variable = table())
    s_quantity = "[""Vabs""; ""Vangle""; ""P""; ""Q""; unique([strings(0,1); tools.vcellfun(" ...
               + "@(T) T.Name(ismember(T.Kind, [""x"", ""u"", ""y""]) & ismember(T.Owner, [strings(0,1); vertcat(obj.c_component{:})])), " ...
               + "repmat({[obj.tab_variable; obj.tab_output]}, height(obj.tab_variable) > 0, 1))], ""stable"")]";
    c_method{[c_method{:,1}] == "ResultODE" & [c_method{:,2}] == "plot_trajectory", 3} = ...
        {"Quantity", s_quantity, "string"; "Bus", "[""all""; obj.sv_bus]", "string"};
    % get_contribution, get_reduced_matrix, plot_reduced_matrix: the elements of the model of
    % the result (tab_owner of the connected model), their classes and packages and the base
    % classes; a result without a model suggests the base classes only
    s_target = "unique([strings(0,1); tools.vcellfun(@(S) [S.tab_owner.Owner; unique(S.tab_owner.Class); " ...
             + "unique(regexprep(S.tab_owner.Class(contains(S.tab_owner.Class, ""."")), ""\.[^.]+$"", """"))], " ...
             + "repmat({obj.sct_model.sct_sys}, isfield(obj.sct_model.sct_sys, ""tab_owner""), 1)); " ...
             + "[""Component""; ""LocalController""; ""GlobalController""; ""Branch""; ""Bus""]], ""stable"")";
    for s_m = ["get_contribution", "get_reduced_matrix", "plot_reduced_matrix"]
        c_method{[c_method{:,1}] == "ResultLIN" & [c_method{:,2}] == s_m, 3} = {"target", s_target, "string"};
    end
    c_method{[c_method{:,1}] == "ResultODE" & [c_method{:,2}] == "get_trajectory", 3} = ...
        {"Quantity", s_quantity, "string"; "Bus", "[""all""; obj.sv_bus]", "string"; ...
         "Owner", "[""all""; obj.sv_bus; vertcat(strings(0,1), obj.c_component{:})]", "string"};
end

function s_entry = method_entry(s_class, s_method, c_tag)
    % JSON text of one method, from its arguments blocks (metadata and source comments)
    %
    % A constructor (s_method is the class name) has the key "<class>" and no obj input.
    arguments (Input)
        s_class  (1,1) string  % Class name, e.g. "Bus".
        s_method (1,1) string  % Method name, e.g. "add_component".
        c_tag    cell          % Tag arguments {argument, expression on obj, other accepted types}.
    end
    arguments (Output)
        s_entry  % JSON text of the entry "<class>.<method>" (constructor: "<class>"): {...}.
    end
    mc = meta.class.fromName(s_class);
    mm = mc.MethodList(string({mc.MethodList.Name}) == s_method);
    mm = mm(1);
    l_ctor = s_method == s_class;
    sct_comment = argument_comments(mm.FullPath, s_method);

    a_in = mm.Signature.Inputs;
    sv_in = strings(numel(a_in), 1);
    for k = 1:numel(a_in)
        arg  = a_in(k);
        s_id = string(arg.Identifier.Name);
        sct  = struct("name", s_id);
        if arg.Required
            sct.kind = "required";
        elseif arg.NameValue
            sct.kind = "namevalue";
        else
            sct.kind = "ordered";
        end
        if k == 1 && ~l_ctor
            sct.type = s_class;
        else
            c_type = argument_type(arg, s_id, c_tag);
            if ~isempty(c_type)
                sct.type = c_type;
            end
        end
        s_purpose = lookup(sct_comment.Input, s_id);
        if ~isempty(arg.DefaultValue)
            s_purpose = strtrim(s_purpose + " Default: " + string(arg.DefaultValue.Expression) + ".");
        end
        if s_purpose ~= ""
            sct.purpose = s_purpose;
        end
        sv_in(k) = "      " + jsonencode(sct);
    end

    a_out = mm.Signature.Outputs;
    sv_out = strings(numel(a_out), 1);
    for k = 1:numel(a_out)
        s_id = string(a_out(k).Identifier.Name);
        sct  = struct("name", s_id);
        s_purpose = lookup(sct_comment.Output, s_id);
        if s_purpose ~= ""
            sct.purpose = s_purpose;
        end
        sv_out(k) = "      " + jsonencode(sct);
    end

    s_key = s_class + "." + s_method;
    if l_ctor
        s_key = s_class;
    end
    s_entry = "  """ + s_key + """: {" + newline ...
            + "    ""inputs"": [" + newline + join(sv_in, "," + newline) + newline + "    ]";
    if ~isempty(sv_out)
        s_entry = s_entry + "," + newline + "    ""outputs"": [" + newline + join(sv_out, "," + newline) + newline + "    ]";
    end
    s_entry = s_entry + newline + "  }";
end

function c_type = argument_type(arg, s_id, c_tag)
    % "type" of an argument: its class, the model keys, the tags of obj or a member list
    arguments (Input)
        arg    (1,1) matlab.metadata.Argument  % Argument metadata.
        s_id   (1,1) string                    % Argument name.
        c_tag  cell                            % Tag arguments {argument, expression on obj, other accepted types}.
    end
    arguments (Output)
        c_type  % cell of types (char), a cell of such cells (alternatives), or {} for none.
    end
    s_class = "";
    sv_fun  = strings(0,1);
    c_scalar = {};    % {'scalar'} for a (1,1) argument
    if ~isempty(arg.Validation)
        if ~isempty(arg.Validation.Class)
            s_class = string(arg.Validation.Class.Name);
        end
        for f = arg.Validation.Functions
            sv_fun(end+1,1) = string(func2str(f.Function));    %#ok<AGROW>
        end
        a_size = arg.Validation.Size;
        if numel(a_size) == 2 && all(arrayfun(@(d) isa(d, "matlab.metadata.FixedDimension") && d.Length == 1, a_size))
            c_scalar = {'scalar'};
        end
    end
    c_type = c_scalar;
    if s_class ~= ""
        c_type = [{char(s_class)}, c_scalar];
    end

    k_tag = find(string(c_tag(:,1)) == s_id, 1);
    if ~isempty(k_tag)
        % Tags of the current object; the other types keep the suggestions alive when obj has none
        c_type = [{[{'string'}, c_scalar, {char("choices=cellstr(" + c_tag{k_tag,2} + ")")}]}, ...
                  arrayfun(@(s) {[{char(s)}, c_scalar]}, string(c_tag{k_tag,3}))];
        return
    end
    for s_fun = sv_fun'
        s_cat = regexp(s_fun, "mustBeKeyOf\(\w+,\s*""(\w+)""\)", "tokens", "once");
        if ~isempty(s_cat)
            c_type = [c_type, {char("choices=cellstr(keys(GUILDA.keymap(""" + s_cat + """)))")}];    %#ok<AGROW>
            return
        end
        s_list = regexp(s_fun, "mustBeMember\([\w.]+,\s*(.+)\)$", "tokens", "once");
        if ~isempty(s_list)
            c_type = [c_type, {char("choices=cellstr(" + s_list + ")")}];    %#ok<AGROW>
            return
        end
    end
end

function sct = argument_comments(s_file, s_function)
    % Trailing comments of the argument lines of the function s_function in the file
    arguments (Input)
        s_file     (1,1) string  % Method file, or the classdef file of a constructor.
        s_function (1,1) string  % Name of the function (the method, or the class of a constructor).
    end
    arguments (Output)
        sct  % struct with fields Input and Output: dictionary of argument name -> comment.
    end
    sct = struct("Input", dictionary(string.empty, string.empty), "Output", dictionary(string.empty, string.empty));
    sv_line = readlines(s_file, "EmptyLineRule", "read");
    s_block = "";
    l_in = false;    % inside s_function
    for i = 1:numel(sv_line)
        s_line = sv_line(i);
        if ~isempty(regexp(s_line, "^\s*function\s", "once"))
            if l_in
                break    % the next function: its arguments are not those of s_function
            end
            l_in = ~isempty(regexp(s_line, "^\s*function\s.*?\<" + s_function + "\s*\(", "once"));
            continue
        end
        if ~l_in
            continue
        end
        tok = regexp(s_line, "^\s*arguments\s*\(\s*(Input|Output)", "tokens", "once");
        if ~isempty(tok)
            s_block = tok;
            continue
        end
        if s_block == ""
            continue
        end
        if ~isempty(regexp(s_line, "^\s*end\s*$", "once"))
            s_block = "";
            continue
        end
        tok = regexp(s_line, "^\s*(?:\w+\.)?(\w+)\W.*?%\s*(.*\S)\s*$", "tokens", "once");
        if ~isempty(tok)
            sct.(s_block)(tok(1)) = tok(2);
        end
    end
end

function s = lookup(dic, s_key)
    % Value of the key in a dictionary of strings, or "" when absent
    arguments (Input)
        dic     dictionary    % dictionary: string -> string.
        s_key   (1,1) string  % Key.
    end
    arguments (Output)
        s  % Value or "".
    end
    s = "";
    if isConfigured(dic) && isKey(dic, s_key)
        s = dic(s_key);
    end
end
