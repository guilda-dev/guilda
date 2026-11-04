% F32 ホットパス関数の引数 (GUILDA.doc が help の Inputs: / Outputs: 節から読む引数)
%
% 内側のループで呼ばれる関数は arguments ブロックを持たず、引数を help の Inputs: / Outputs: 節で
% 記述する。エクスポーターは節を Arguments / Outputs にし、説明文から除く。arguments ブロックが
% あればそちらを使い、名前の過不足と重複は警告する。
% GUILDA のコピーで GUILDA.doc を実行するので、別の MATLAB を起動する (test_F26 と同じ)。
% 別の MATLAB を起動できない環境では SKIP する。
%
% 実行: runtests("DebugScript.test_F32_doc_hot_path_arguments")  または  DebugScript.run_all("Features","F32")

%% Inputs and Outputs sections become the arguments of a method without an arguments block
sct = export_user_class();
m = find_method(sct, "step");
assert(m.Signature == "dx = step(obj, t, x, V, varargin)")
c_name = cellfun(@(a) string(a.Name), m.Arguments);
assert(isequal(c_name, ["obj","t","x","V","varargin"]))
a_t = m.Arguments{2};
assert(a_t.Kind == "Positional" && a_t.Size == "(1,1)" && a_t.Class == "double" && a_t.Unit == "s" && a_t.Description == "Time.")
a_x = m.Arguments{3};
assert(a_x.Size == "(:,1)" && a_x.Class == "double" && a_x.Unit == "" ...
    && a_x.Description == "State vector, continued on the next line.")
a_V = m.Arguments{4};
assert(a_V.Size == "" && a_V.Class == "" && a_V.Unit == "pu" && a_V.Description == "Bus voltage [real; imag].")
assert(m.Arguments{5}.Kind == "Repeating" && ~m.Arguments{5}.Required)
assert(numel(m.Outputs) == 1 && m.Outputs{1}.Name == "dx" && m.Outputs{1}.Kind == "Output" ...
    && m.Outputs{1}.Description == "Right-hand side.")
% 節は説明文から除かれ、残りの文はそのまま
assert(~contains(m.Desc, "Inputs:") && ~contains(m.Desc, "Outputs:") && contains(m.Desc, "Text after the sections."))
assert(isequal(sort(m.SeeAlso), "HotPathDoc"))
% obj と記述した名前には警告しない
assert(~any(contains(sct.validation.Warnings, "HotPathDoc.step")))


%% The list form is read and names not on the function line stand for varargout
sct = export_user_class();
m = find_method(sct, "results");
c_out = cellfun(@(a) string(a.Name), m.Outputs);
assert(isequal(c_out, ["res","flag"]))
assert(m.Outputs{1}.Unit == "pu" && m.Outputs{1}.Description == "Result of the call.")
assert(m.Arguments{2}.Name == "opt" && m.Arguments{2}.Description == "Options.")


%% An arguments block wins and a mismatch is warned
sct = export_user_class();
m = find_method(sct, "both");
assert(m.Arguments{2}.Name == "a" && m.Arguments{2}.Description == "From the block.")
c_warn = string(sct.validation.Warnings);
assert(any(contains(c_warn, "HotPathDoc.both") & contains(c_warn, "arguments block")))
assert(any(contains(c_warn, "HotPathDoc.mismatch") & contains(c_warn, "no entry for b")))
assert(any(contains(c_warn, "HotPathDoc.mismatch") & contains(c_warn, "describes c")))


function sct = export_user_class()
    % 一度だけ書き出し、各セクションは結果を共有する
    persistent sct_cache
    if ~isempty(sct_cache)
        sct = sct_cache;
        return
    end
    str_dir = tempname; mkdir(str_dir); c_dir = onCleanup(@() rmdir(str_dir, "s"));
    str_root = fullfile(str_dir, "GUILDA");
    str_source = GUILDA.pwd();
    mkdir(fullfile(str_root, "_GUILDAdoc"));
    for str_folder = ["@GUILDA", "_GUILDAsystem", "_GUILDAobject"]
        copyfile(fullfile(str_source, str_folder), fullfile(str_root, str_folder));
    end
    str_user = fullfile(str_dir, "user");
    mkdir(str_user);
    writelines(user_class(), fullfile(str_user, "HotPathDoc.m"));

    str_code = sprintf("disp(['F32_CHILD','_STARTED']); cd('%s'); addpath(pwd); GUILDA.addpath; addpath('%s');", str_root, str_user);
    str_code = str_code + " GUILDA.doc('update','always','open',false)";
    str_matlab = fullfile(matlabroot, "bin", "matlab");
    [flag, str_out] = system(sprintf('"%s" -batch "%s"', str_matlab, str_code));
    if ~contains(str_out, "F32_CHILD_STARTED")
        error("DebugScript:Skip", "別の MATLAB を起動できません: %s", strtok(str_out, newline));
    end
    assert(flag == 0, "GUILDA.doc failed in the copy: %s", str_out)
    c_js = dir(fullfile(str_root, "_GUILDAdoc", "database", "User", "**", "HotPathDoc.js"));
    assert(isscalar(c_js), "HotPathDoc.js was not exported")
    str_js = fileread(fullfile(c_js.folder, c_js.name));
    str_json = extractBetween(string(str_js), "] = ", ";" + newline + "})(window);");
    sct = jsondecode(str_json);
    sct_cache = sct;
end


function m = find_method(sct, str_name)
    c_m = sct.methods;
    if ~iscell(c_m), c_m = num2cell(c_m); end
    m = c_m{cellfun(@(x) x.Name == string(str_name), c_m)};
    % jsondecode は同じ形の構造体の配列を構造体配列 (列) にする
    if isstruct(m.Arguments), m.Arguments = num2cell(m.Arguments); end
    if isstruct(m.Outputs),   m.Outputs   = num2cell(m.Outputs);   end
    m.Arguments = reshape(m.Arguments, 1, []);
    m.Outputs   = reshape(m.Outputs, 1, []);
    m.Desc = string(m.Desc);
    m.SeeAlso = string(m.SeeAlso);
end


function str = user_class()
    str = [
        "classdef HotPathDoc < Bus"
        "% Bus subclass for the F32 test (a user class must inherit from GUILDA)."
        "    methods"
        "        function dx = step(obj, t, x, V, varargin) %#ok<INUSD>"
        "        % Evaluate one step."
        "        %"
        "        % Inputs:"
        "        %   t   (1,1) double  [s] Time."
        "        %   x   (:,1) double  State vector,"
        "        %                     continued on the next line."
        "        %   V   [pu] Bus voltage [real; imag]."
        "        %   varargin  More values."
        "        % Outputs:"
        "        %   dx  Right-hand side."
        "        %"
        "        % Text after the sections."
        "        %"
        "        % See also HotPathDoc"
        "            dx = x;"
        "        end"
        "        function varargout = results(obj, opt) %#ok<INUSD>"
        "        % Return results."
        "        %"
        "        % Inputs:"
        "        % - `opt`: Options."
        "        %"
        "        % Outputs:"
        "        %"
        "        % - `res` — [pu] Result of the call."
        "        % - `flag` — Exit flag."
        "            varargout = {1, 2};"
        "        end"
        "        function both(obj, a) %#ok<INUSD>"
        "        % Use an arguments block and a section."
        "        %"
        "        % Inputs:"
        "        %   a  From the section."
        "            arguments"
        "                obj"
        "                a double % From the block."
        "            end"
        "        end"
        "        function mismatch(obj, a, b) %#ok<INUSD>"
        "        % Describe a name that is not an input."
        "        %"
        "        % Inputs:"
        "        %   a  First."
        "        %   c  Not an input."
        "        end"
        "    end"
        "end"
        ];
end
