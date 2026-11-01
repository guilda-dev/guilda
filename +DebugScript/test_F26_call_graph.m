% F26 呼び出しグラフの収集 (GUILDA.doc が書き出す list_CallGraph.js)
%
% グラフは GUILDA を置いた場所に依存しない。private という名前のフォルダの下に置いても、
% @Class フォルダのメソッドはノードのままで、@Class/private の関数だけがノードにならない。
% GUILDA 自体を読み直すので、コピーで別の MATLAB を起動する。カレントフォルダの @GUILDA が
% パスより優先されるので、起動後にコピーへ移動する。
%
% 実行: runtests("DebugScript.test_F26_call_graph")  または  DebugScript.run_all("Features","F26")

%% The call graph does not depend on a private folder above GUILDA
str_dir = tempname; mkdir(str_dir); c_dir = onCleanup(@() rmdir(str_dir, "s"));
str_root = fullfile(str_dir, "private", "GUILDA");
sct_graph = export_copy(str_root);
cell_from = sct_graph.nodes(cellfun(@first_item, sct_graph.edges) + 1);
assert(any(strcmp(cell_from, "PowerNetwork.simulate")), "A method of an @Class folder lost its edges")
sct_helpers = dir(fullfile(str_root, "_GUILDAsystem", "@Bus", "private", "*.m"));
assert(~isempty(sct_helpers))
for i = 1:numel(sct_helpers)
    str_node = "Bus." + erase(sct_helpers(i).name, ".m");
    assert(~any(strcmp(sct_graph.nodes, str_node)), "A private helper became a node: %s", str_node)
end


function val = first_item(val_edge)
    % jsondecode は, 値がすべて数値の辺を数値の列に, 配列を含む辺を cell にする
    if iscell(val_edge)
        val = val_edge{1};
    else
        val = val_edge(1);
    end
end


function sct_graph = export_copy(str_root)
    % GUILDA のコピーで GUILDA.doc を実行し, list_CallGraph.js の中身を返す
    str_source = GUILDA.pwd();
    mkdir(fullfile(str_root, "_GUILDAdoc"));
    for str_folder = ["@GUILDA", "_GUILDAsystem", "_GUILDAobject"]
        copyfile(fullfile(str_source, str_folder), fullfile(str_root, str_folder));
    end
    str_matlab = fullfile(matlabroot, "bin", "matlab");
    str_code = sprintf("cd('%s'); addpath(pwd); GUILDA.addpath; GUILDA.doc('update','always','open',false)", str_root);
    [flag, str_out] = system(sprintf('"%s" -batch "%s"', str_matlab, str_code));
    assert(flag == 0, "GUILDA.doc failed in the copy: %s", str_out)
    str_js = fileread(fullfile(str_root, "_GUILDAdoc", "database", "list_CallGraph.js"));
    sct_graph = jsondecode(extractBetween(string(str_js), "window.GUILDA_DOC_CALLGRAPH = ", ";" + newline));
end
