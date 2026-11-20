% F71 GUILDA.dictionary の [doc] リンクと Key 列、GUILDA.config の Format="table"
%
% dictionary のクラスの木は各行の先頭に [doc] (GUILDA.doc("class", 名前)) とクラスの Key を
% 表示し、[help]・[mlx] は表示しない。Key の無いクラス (PowerNetwork、抽象クラス) は空欄。
% 返す表には Key 列があり、GUILDA.keymap と一致する (keymap はこの列から作られる)。
% GUILDA.config(カテゴリ, Format="table") は Name, Type, Value, Description の表を返す。
%
% 実行: runtests("DebugScript.test_F71_dictionary_doc_key")  または  DebugScript.run_all("Features","F71")


%% Tree rows show doc links and keys but no help or mlx links
txt = evalc("GUILDA.dictionary(""Component"");");
assert(contains(txt, ">[doc]</a>"), txt)
assert(~contains(txt, "[help]") && ~contains(txt, "[mlx]"), txt)
assert(contains(txt, "GUILDA.doc('class', 'component.generator.park')"), txt)
% 見出しの列名
assert(contains(txt, "Link") && contains(txt, "Type") && contains(txt, "Key") && contains(txt, "class tree"), txt)
% 行にクラスのキーが出る
s_row = row_of(txt, "component.generator.park");
assert(contains(s_row, "gen-park"), s_row)


%% Classes without a key have a blank key column
txt = evalc("GUILDA.dictionary(""PowerSystemModel"");");
tab = GUILDA.dictionary("PowerSystemModel", "disp", false);
for s_class = ["PowerNetwork", "Component"]
    assert(tab.Key(tab.filename == s_class) == "", s_class)
    s_row = row_of(txt, s_class);
    % [doc] リンク、種別、空欄のキー、クラス名の順
    s_vis = regexprep(s_row, "<[^>]*>", "");
    assert(~isempty(regexp(s_vis, "^\s*\[doc\]\s+-:Abstract\s+[┣┗]━━ " + regexptranslate("escape", s_class) + "$", "once")) || ...
           ~isempty(regexp(s_vis, "^\s*\[doc\]\s+o:Concrete\s+[┣┗]━━ " + regexptranslate("escape", s_class) + "$", "once")), s_vis)
end


%% The doc link calls GUILDA.doc for every class
% クラス名から呼ぶ ClassName.doc の形 (インスタンスメソッドの doc ではエラー) は使わない
for s_root = ["PowerSystemModel", "auxiliary"]
    txt = evalc("GUILDA.dictionary(""" + s_root + """);");
    sv  = splitlines(string(txt));
    sv  = sv(contains(sv, "[doc]"));
    assert(~isempty(sv) && all(contains(sv, "matlab:GUILDA.doc('class', '")), s_root)
    assert(isempty(regexp(txt, "matlab:[\w.]+\.doc;", "once")), s_root)
end


%% The returned table has a Key column that matches keymap
for s_cat = ["Component", "Branch", "LocalController", "GlobalController"]
    tab = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", s_cat);
    assert(isequal(string(tab.Properties.VariableNames), ["No", "filename", "superclass", "Key"]), s_cat)
    assert(isstring(tab.Key), s_cat)
    lv = tab.Key ~= "";
    dic = GUILDA.keymap(s_cat);
    [sv_key, iv] = sort(tab.Key(lv));
    sv_class = tab.filename(lv);
    assert(isequal(sv_key, sort(reshape(keys(dic), [], 1))), s_cat)
    assert(isequal(sv_class(iv), reshape(dic(sv_key), [], 1)), s_cat)
    % Key のあるクラスはすべて具象クラス
    assert(all(arrayfun(@(c) ~meta.class.fromName(c).Abstract, tab.filename(lv))), s_cat)
end
% 複数の出力でも各表に Key 列がある
c_tab = GUILDA.dictionary("PowerSystemModel", "disp", false, "output", ["Component","Branch"]);
assert(all(cellfun(@(t) ismember("Key", t.Properties.VariableNames), c_tab)))


%% dictionary of Component shows only the tree under Component
txt = evalc("GUILDA.dictionary(""Component"");");
assert(contains(txt, "Search for 'Component' class"), txt)
assert(contains(txt, "component.generator.park") && contains(txt, "component.load.power"), txt)
assert(~contains(txt, "branch.pi") && ~contains(txt, ">PowerNetwork<"), txt)
tab = GUILDA.dictionary("Component", "disp", false);
assert(~any(ismember(["branch.pi", "PowerNetwork", "Component"], tab.filename)))
assert(tab.Key(tab.filename == "component.generator.park") == "gen-park")


%% config Format table lists name, type, value and description
sct = GUILDA.config("TimeSimulation");
tab = GUILDA.config("TimeSimulation", Format="table");
assert(istable(tab))
assert(isequal(string(tab.Properties.VariableNames), ["Name", "Type", "Value", "Description"]))
assert(isequal(tab.Name, string(fieldnames(sct))))
assert(isstring(tab.Type) && isstring(tab.Description) && iscell(tab.Value))
for k = 1:height(tab)
    s = sct.(tab.Name(k));
    assert(isequaln(tab.Value{k}, s.Value), tab.Name(k))
    assert(tab.Type(k) == string(s.Type) && tab.Description(k) == string(s.Description), tab.Name(k))
end
assert(isequal(tab.Value{tab.Name == "Solver"}, GUILDA.config("TimeSimulation", "Solver")))
% パラメータも指定すると 1 行
tab1 = GUILDA.config("TimeSimulation", "Solver", Format="table");
assert(height(tab1) == 1 && tab1.Name == "Solver")
% 既定の返し方は変わらない
assert(isequaln(GUILDA.config("TimeSimulation", Format="struct"), sct))
assert(isstruct(GUILDA.config()))


%% config Format table needs a category
try
    GUILDA.config([], [], Format="table");
    error("DebugScript:NoError", "エラーにならなかった")
catch ME
    % error(msg(...)) には identifier が付かないので、文章から ID を調べる
    s_id = DebugScript.helper.msg_id(ME);
    assert(string(s_id) == "GUILDA:config:TableNeedsCategory", ME.message)
end


function s_row = row_of(txt, s_class)
    % クラスの木で s_class を表示している行 (リンク付きの名前で探す)
    sv = splitlines(string(txt));
    lv = contains(sv, ">" + s_class + "</a>");
    assert(nnz(lv) == 1, s_class + " の行が見つからない")
    s_row = sv(lv);
end
