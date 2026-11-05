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
s_dir = tempname; mkdir(s_dir); c_dir = onCleanup(@() rmdir(s_dir, "s"));
s_root = copy_guilda(fullfile(s_dir, "private", "GUILDA"));
sct_graph = decode_graph(export_graph(s_root));
cell_from = sct_graph.nodes(cellfun(@first_item, sct_graph.edges) + 1);
assert(any(strcmp(cell_from, "PowerNetwork.simulate")), "A method of an @Class folder lost its edges")
sct_helpers = dir(fullfile(s_root, "_GUILDAsystem", "@Bus", "private", "*.m"));
assert(~isempty(sct_helpers))
for i = 1:numel(sct_helpers)
    s_node = "Bus." + erase(sct_helpers(i).name, ".m");
    assert(~any(strcmp(sct_graph.nodes, s_node)), "A private helper became a node: %s", s_node)
end


%% A package folder above a user class does not hide a receiver of that name
% GUILDA 自体は + フォルダの下で動かないので, ユーザーのクラスのフォルダで確認する
% SolverODE は GUILDA のコードが Class.member で参照する名前で, パッケージ扱いになると辺が消える
s_dir = tempname; mkdir(s_dir); c_dir = onCleanup(@() rmdir(s_dir, "s"));
s_root   = copy_guilda(fullfile(s_dir, "GUILDA"));
s_user   = fullfile(s_dir, "+SolverODE", "user");
mkdir(s_user);
writelines(["classdef F26UserClass < Bus", "end"], fullfile(s_user, "F26UserClass.m"));
s_without = export_graph(s_root);
s_with = export_graph(s_root, s_user);
assert(strcmp(s_without, s_with), "A package folder outside GUILDA changed the call graph")


function val = first_item(val_edge)
    % jsondecode は, 値がすべて数値の辺を数値の列に, 配列を含む辺を cell にする
    if iscell(val_edge)
        val = val_edge{1};
    else
        val = val_edge(1);
    end
end


function s_root = copy_guilda(s_root)
    s_source = GUILDA.pwd();
    mkdir(fullfile(s_root, "_GUILDAdoc"));
    for s_folder = ["@GUILDA", "_GUILDAsystem", "_GUILDAobject"]
        copyfile(fullfile(s_source, s_folder), fullfile(s_root, s_folder));
    end
end


function s_js = export_graph(s_root, s_user)
    % GUILDA のコピーで GUILDA.doc を実行し, list_CallGraph.js の中身を返す
    % 目印は連結して表示するので, 出力にあれば子の MATLAB がコードの実行まで進んだことになる
    s_code = sprintf("disp(['F26_CHILD','_STARTED']); cd('%s'); addpath(pwd); GUILDA.addpath;", s_root);
    if nargin > 1
        s_code = s_code + sprintf(" addpath('%s');", s_user);
    end
    s_code = s_code + " GUILDA.doc('update','always','open',false)";
    s_matlab = fullfile(matlabroot, "bin", "matlab");
    [flag, s_out] = system(sprintf('"%s" -batch "%s"', s_matlab, s_code));
    if ~contains(s_out, "F26_CHILD_STARTED")
        error("DebugScript:Skip", "別の MATLAB を起動できません: %s", strtok(s_out, newline));
    end
    assert(flag == 0, "GUILDA.doc failed in the copy: %s", s_out)
    s_js = fileread(fullfile(s_root, "_GUILDAdoc", "database", "list_CallGraph.js"));
end


function sct_graph = decode_graph(s_js)
    sct_graph = jsondecode(extractBetween(string(s_js), "window.GUILDA_DOC_CALLGRAPH = ", ";" + newline));
end
