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
% GUILDA calls it at startup (setting UpdateKeyMap). Call it yourself after adding or
% removing a model class or changing its key, to use the new keys without restarting
% GUILDA.
%
% For developers, `Signature=true` also regenerates
% `_GUILDAsystem/resources/functionSignatures.json`, the code suggestions of the methods
% that build or remove a model, from their arguments blocks: the names, kinds, classes
% and defaults of the arguments, the trailing comment of each argument line as its
% purpose, the model keys of the category for `Key`, and the tags of the current
% object for the tag arguments. The file is written only when its content changes.
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
        opt.Signature (1,1) logical = false   % Also regenerate _GUILDAsystem/resources/functionSignatures.json (for developers).
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
        write_signatures(fullfile(GUILDA.pwd(), "_GUILDAsystem", "resources", "functionSignatures.json"))
    end
end

function write_signatures(s_file)
    % Write functionSignatures.json of the methods in sig_methods, only when it changes
    arguments (Input)
        s_file (1,1) string   % Path of functionSignatures.json.
    end
    c_method = sig_methods();
    sv_entry = strings(0,1);
    for i = 1:size(c_method, 1)
        sv_entry(end+1,1) = method_entry(c_method{i,:});    %#ok<AGROW>
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
        c_method   % n-by-3 cell: class name, method name, n-by-3 cell of tag arguments.
    end
    s_lcon = "[string(obj.a_LocalController); string(cellfun(@(c) strjoin([string(c.a_LocalController); """"], """"), obj.a_LocalController, ""UniformOutput"", false))]";
    c_method = {
        "Bus",          "add_component",            cell(0,3)
        "Bus",          "replace_component",        {"s_tag",      "string(obj.a_Component)",         "string"}
        "Bus",          "remove_component",         {"s_tag",      "string(obj.a_Component)",         "string"}
        "Component",    "add_local_controller",     cell(0,3)
        "Component",    "remove_local_controller",  {"s_tag",      s_lcon,                            "string"}
        "PowerNetwork", "add_branch",               {"from_to",    "string(obj.a_Bus)",               ["string","numeric"]}
        "PowerNetwork", "add_global_controller",    cell(0,3)
        "PowerNetwork", "remove_branch",            {"tag",        "string(obj.a_Branch)",            "string"}
        "PowerNetwork", "remove_bus",               {"sr_BusTag",  "string(obj.a_Bus)",               "string"}
        "PowerNetwork", "remove_global_controller", {"sr_GconTag", "string(obj.a_GlobalController)",  "string"}
        "PowerNetwork", "add_scenario",             cell(0,3)
        "PowerNetwork", "remove_scenario",          {"sr_tag",     "string(obj.a_Scenario)",          "string"}
        };
end

function s_entry = method_entry(s_class, s_method, c_tag)
    % JSON text of one method, from its arguments blocks (metadata and source comments)
    arguments (Input)
        s_class  (1,1) string   % Class name, e.g. "Bus".
        s_method (1,1) string   % Method name, e.g. "add_component".
        c_tag    cell           % Tag arguments {argument, expression on obj, other accepted types}.
    end
    arguments (Output)
        s_entry  % JSON text of the entry "<class>.<method>": {...}.
    end
    mc = meta.class.fromName(s_class);
    mm = mc.MethodList(string({mc.MethodList.Name}) == s_method);
    mm = mm(1);
    sct_comment = argument_comments(mm.FullPath);

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
        if k == 1
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

    s_entry = "  """ + s_class + "." + s_method + """: {" + newline ...
            + "    ""inputs"": [" + newline + join(sv_in, "," + newline) + newline + "    ]";
    if ~isempty(sv_out)
        s_entry = s_entry + "," + newline + "    ""outputs"": [" + newline + join(sv_out, "," + newline) + newline + "    ]";
    end
    s_entry = s_entry + newline + "  }";
end

function c_type = argument_type(arg, s_id, c_tag)
    % "type" of an argument: its class, the model keys, the tags of obj or a member list
    arguments (Input)
        arg    (1,1) matlab.metadata.Argument   % Argument metadata.
        s_id   (1,1) string   % Argument name.
        c_tag  cell           % Tag arguments {argument, expression on obj, other accepted types}.
    end
    arguments (Output)
        c_type   % cell of types (char), a cell of such cells (alternatives), or {} for none.
    end
    s_class = "";
    sv_fun  = strings(0,1);
    if ~isempty(arg.Validation)
        if ~isempty(arg.Validation.Class)
            s_class = string(arg.Validation.Class.Name);
        end
        for f = arg.Validation.Functions
            sv_fun(end+1,1) = string(func2str(f.Function));    %#ok<AGROW>
        end
    end
    c_type = {};
    if s_class ~= ""
        c_type = {char(s_class)};
    end

    k_tag = find(string(c_tag(:,1)) == s_id, 1);
    if ~isempty(k_tag)
        % Tags of the current object; the other types keep the suggestions alive when obj has none
        c_type = [{{'string', char("choices=cellstr(" + c_tag{k_tag,2} + ")")}}, ...
                  arrayfun(@(s) {{char(s)}}, string(c_tag{k_tag,3}))];
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

function sct = argument_comments(s_file)
    % Trailing comments of the argument lines of the first function in the file
    arguments (Input)
        s_file (1,1) string   % Method file.
    end
    arguments (Output)
        sct   % struct with fields Input and Output: dictionary of argument name -> comment.
    end
    sct = struct("Input", dictionary(string.empty, string.empty), "Output", dictionary(string.empty, string.empty));
    sv_line = readlines(s_file, "EmptyLineRule", "read");
    s_block = "";
    for i = 1:numel(sv_line)
        s_line = sv_line(i);
        tok = regexp(s_line, "^\s*arguments\s*\(\s*(Input|Output)", "tokens", "once");
        if ~isempty(tok)
            s_block = tok;
            continue
        end
        if s_block == ""
            if i > 1 && ~isempty(regexp(s_line, "^\s*function\s", "once"))
                break    % a local function: its arguments are not those of the method
            end
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
        dic     dictionary   % dictionary: string -> string.
        s_key   (1,1) string % Key.
    end
    arguments (Output)
        s   % Value or "".
    end
    s = "";
    if isConfigured(dic) && isKey(dic, s_key)
        s = dic(s_key);
    end
end
