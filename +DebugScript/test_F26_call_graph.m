% F26 呼び出しグラフの収集 (GUILDA.doc が書き出す list_CallGraph.js)
%
% グラフは GUILDA を置いた場所に依存しない。private という名前のフォルダの下に置いても、
% @Class フォルダのメソッドはノードのままで、@Class/private の関数だけがノードにならない。
% GUILDA の外にある +pkg フォルダは, GUILDA のコードの受け手 の解釈を変えない。
% GUILDA 自体を読み直すので、コピーで別の MATLAB を起動する。カレントフォルダの @GUILDA が
% パスより優先されるので、起動後にコピーへ移動する。別の MATLAB を起動できない環境では SKIP する。
%
% 実行: runtests("DebugScript.test_F26_call_graph")  または  DebugScript.run_all("Features","F26")

%% The call graph does not depend on a private folder above GUILDA
str_dir = tempname; mkdir(str_dir); c_dir = onCleanup(@() rmdir(str_dir, "s"));
str_root = copy_guilda(fullfile(str_dir, "private", "GUILDA"));
sct_graph = decode_graph(export_graph(str_root));
cell_from = sct_graph.nodes(cellfun(@first_item, sct_graph.edges) + 1);
assert(any(strcmp(cell_from, "PowerNetwork.simulate")), "A method of an @Class folder lost its edges")
sct_helpers = dir(fullfile(str_root, "_GUILDAsystem", "@Bus", "private", "*.m"));
assert(~isempty(sct_helpers))
for i = 1:numel(sct_helpers)
    str_node = "Bus." + erase(sct_helpers(i).name, ".m");
    assert(~any(strcmp(sct_graph.nodes, str_node)), "A private helper became a node: %s", str_node)
end


%% A package folder above a user class does not hide a receiver of that name
% GUILDA 自体は + フォルダの下で動かないので, ユーザーのクラスのフォルダで確認する
% SolverODE は GUILDA のコードが Class.member で参照する名前で, パッケージ扱いになると辺が消える
str_dir = tempname; mkdir(str_dir); c_dir = onCleanup(@() rmdir(str_dir, "s"));
str_root = copy_guilda(fullfile(str_dir, "GUILDA"));
str_user = fullfile(str_dir, "+SolverODE", "user");
mkdir(str_user);
writelines(["classdef F26UserClass < Bus", "end"], fullfile(str_user, "F26UserClass.m"));
str_without = export_graph(str_root);
str_with = export_graph(str_root, str_user);
assert(strcmp(str_without, str_with), "A package folder outside GUILDA changed the call graph")


function val = first_item(val_edge)
    % jsondecode は, 値がすべて数値の辺を数値の列に, 配列を含む辺を cell にする
    if iscell(val_edge)
        val = val_edge{1};
    else
        val = val_edge(1);
    end
end


function str_root = copy_guilda(str_root)
    str_source = GUILDA.pwd();
    mkdir(fullfile(str_root, "_GUILDAdoc"));
    for str_folder = ["@GUILDA", "_GUILDAsystem", "_GUILDAobject"]
        copyfile(fullfile(str_source, str_folder), fullfile(str_root, str_folder));
    end
end


function str_js = export_graph(str_root, str_user)
    % GUILDA のコピーで GUILDA.doc を実行し, list_CallGraph.js の中身を返す
    % 目印は連結して表示するので, 出力にあれば子の MATLAB がコードの実行まで進んだことになる
    str_code = sprintf("disp(['F26_CHILD','_STARTED']); cd('%s'); addpath(pwd); GUILDA.addpath;", str_root);
    if nargin > 1
        str_code = str_code + sprintf(" addpath('%s');", str_user);
    end
    str_code = str_code + " GUILDA.doc('update','always','open',false)";
    str_matlab = fullfile(matlabroot, "bin", "matlab");
    [flag, str_out] = system(sprintf('"%s" -batch "%s"', str_matlab, str_code));
    if ~contains(str_out, "F26_CHILD_STARTED")
        error("DebugScript:Skip", "別の MATLAB を起動できません: %s", strtok(str_out, newline));
    end
    assert(flag == 0, "GUILDA.doc failed in the copy: %s", str_out)
    str_js = fileread(fullfile(str_root, "_GUILDAdoc", "database", "list_CallGraph.js"));
end


function sct_graph = decode_graph(str_js)
    sct_graph = jsondecode(extractBetween(string(str_js), "window.GUILDA_DOC_CALLGRAPH = ", ";" + newline));
end
