% F54 ネットワーク図の配置データ (graph パラメータ) の列と net.get_layout / net.set_layout
%
%   net.add_bus(X=, Y=, Shape=, Length=, MarkerSize=, Color=)
%   net.add_branch(..., Path="x y; x y" | n×2, FromOffset=, ToOffset=, Style="line"|"transformer")
%   bus.add_component(..., DX=, DY=, Shape=, Path=, Offset=, MarkerSize=, Color=)
%   L = net.get_layout();  net.set_layout(L, IgnoreUnknown=false)
%   tools.layout_parse_path(s);  tools.layout_mustBePath(x);  tools.layout_convert_columns(folder)
%
% 値は入れたときに検査する (add_*、表への直接の書き込み、GUI と同じ代入、set_layout)。
% 仕様: notes/graph-layout.md §4〜§7。
%
% 実行: runtests("DebugScript.test_F54_graph_layout")  または  DebugScript.run_all("Features","F54")

%% Path parse and validator
assert(isequal(tools.layout_parse_path("0.23 0.5; 0.36 0.33"), [0.23 0.5; 0.36 0.33]))
assert(isequal(size(tools.layout_parse_path("")), [0 2]) && isequal(size(tools.layout_parse_path("   ")), [0 2]))
assert(isequal(tools.layout_parse_path(" -1  2 ;3 4e-1 "), [-1 2; 3 0.4]))
for s_bad = ["1", "1 2 3", "1 2;", "a b", "1 Inf", "1 NaN", "0.1,0.2"]
    assert(error_id(@() tools.layout_parse_path(s_bad)) == "GUILDA:layout_parse_path:InvalidPath", s_bad)
end
ME = caught(@() tools.layout_parse_path("1 2; 3", Context="EL001: "));
assert(startsWith(ME.message, "EL001: Path ""1 2; 3""") && contains(ME.message, """3"""))
tools.layout_mustBePath("");
tools.layout_mustBePath('0 1');
tools.layout_mustBePath([0 1; 2 3]);
tools.layout_mustBePath(zeros(0, 2));
assert(error_id(@() tools.layout_mustBePath([1 2 3])) == "GUILDA:layout_parse_path:InvalidPath")
assert(error_id(@() tools.layout_mustBePath([1 Inf])) == "GUILDA:layout_parse_path:InvalidPath")
assert(~isempty(caught(@() tools.layout_mustBePath(["0 1", "2 3"]))))

%% New columns and defaults
net = PowerNetwork();
b1 = net.add_bus();
assert(isequal(string(b1.tab_parameter.graph.Properties.VariableNames), ["X","Y","Shape","Length","MarkerSize","Color"]))
assert(b1.tab_parameter.graph.Shape == "square" && isnan(b1.tab_parameter.graph.Length) && isnan(b1.tab_parameter.graph.X))
b2 = net.add_bus(X=0.5, Y=0.2, Shape="hbar", Length=0.1, Color="red");
br = net.add_branch("pi", [1 2], Path=[0.1 0.2; 0.3 0.45], Style="transformer");
assert(isequal(string(br.tab_parameter.graph.Properties.VariableNames), ["Path","FromOffset","ToOffset","Style"]))
assert(br.tab_parameter.graph.Path == "0.1 0.2; 0.3 0.45" && br.tab_parameter.graph.Style == "transformer")
br2 = net.add_branch("pi", [1 2]);
assert(br2.tab_parameter.graph.Path == "" && br2.tab_parameter.graph.Style == "line" && isnan(br2.tab_parameter.graph.FromOffset))
c1 = b2.add_component("load-power", P=-0.1, DX=0.01, DY=-0.05, Shape="v", Path="0 -0.03", Offset=0.02);
assert(isequal(string(c1.tab_parameter.graph.Properties.VariableNames), ["DX","DY","Shape","Path","Offset","MarkerSize","Color"]))
assert(b1.add_component("load-power").tab_parameter.graph.Shape == "circle")

%% Checks at input time (add_*)
net = PowerNetwork();
net.add_bus();
b2 = net.add_bus(X=0.5, Y=0.2, Shape="hbar", Length=0.1);
n_bus = numel(net.a_Bus);
assert(error_id(@() net.add_bus(Shape="hbar")) == "GUILDA:Bus:BarLength")
assert(error_id(@() net.add_bus(Shape="vbar", Length=NaN)) == "GUILDA:Bus:BarLength")
assert(error_id(@() net.add_bus(X=Inf)) == "GUILDA:Bus:InvalidGraphNumber")
assert(error_id(@() net.add_bus(Length=Inf)) == "GUILDA:Bus:InvalidGraphPositive")
assert(error_id(@() net.add_bus(Color="nocolor")) == "GUILDA:Bus:InvalidColor")
assert(~isempty(caught(@() net.add_bus(Shape="s"))))          % 短い名前は受け付けない (mustBeMember)
assert(~isempty(caught(@() net.add_bus(Shape="diamond"))))
assert(~isempty(caught(@() net.add_bus(Xaxis=0))))            % 古い名前はない
assert(numel(net.a_Bus) == n_bus, "失敗した add_bus が母線を足した")
n_bra = numel(net.a_Branch);
assert(error_id(@() net.add_branch("pi", [1 2], Path="1 2; 3")) == "GUILDA:layout_parse_path:InvalidPath")
assert(error_id(@() net.add_branch("pi", [1 2], FromOffset=-Inf)) == "GUILDA:Branch:InvalidGraphNumber")
assert(~isempty(caught(@() net.add_branch("pi", [1 2], Style="oo-"))))
assert(~isempty(caught(@() net.add_branch("pi", [1 2], MidXaxis="[0.1]"))))
assert(numel(net.a_Branch) == n_bra)
n_comp = numel(b2.a_Component);
assert(error_id(@() b2.add_component("load-power", Path="x")) == "GUILDA:layout_parse_path:InvalidPath")
assert(error_id(@() b2.add_component("load-power", DX=Inf)) == "GUILDA:Component:InvalidGraphNumber")
assert(error_id(@() b2.add_component("load-power", MarkerSize=-1)) == "GUILDA:Component:InvalidGraphPositive")
assert(~isempty(caught(@() b2.add_component("load-power", Shape="hbar"))))
assert(numel(b2.a_Component) == n_comp)

%% Checks of a direct table write
net = network.IEEE14bus();
bus = net.a_Bus{1};
g0  = bus.tab_parameter.graph;
assert(error_id(@() set_graph(bus, "Shape", "nope")) == "GUILDA:Bus:InvalidShape")
assert(error_id(@() set_graph(bus, "Length", NaN)) == "GUILDA:Bus:BarLength")     % B001 は棒
% GUI は 1 セルずつ書くので、点の母線の Shape を先に棒にすると止まる。メッセージは Length を先に書くよう示す
net3 = DebugScript.helper.build_3bus("gen-1axis");     % 母線は既定の "square"
bus3 = net3.a_Bus{1};
ME = caught(@() set_graph(bus3, "Shape", "hbar"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:Bus:BarLength" && contains(ME.message, "Set Length first (a positive length), then Shape"))
assert(bus3.tab_parameter.graph.Shape == "square")
set_graph(bus3, "Length", 0.1);
set_graph(bus3, "Shape", "hbar");
assert(bus3.tab_parameter.graph.Shape == "hbar")
assert(isequaln(bus.tab_parameter.graph, g0), "失敗した書き込みが値を変えた")
bra = net.a_Branch{1};
assert(error_id(@() set_graph(bra, "Path", "0.1 0.2; 0.3")) == "GUILDA:layout_parse_path:InvalidPath")
assert(error_id(@() set_graph(bra, "Style", "-")) == "GUILDA:Branch:InvalidStyle")
comp = net.a_Bus{2}.a_Component{1};
assert(error_id(@() set_graph(comp, "Shape", "vbar")) == "GUILDA:Component:InvalidShape")
assert(error_id(@() set_graph(comp, "Color", "#12")) == "GUILDA:Component:InvalidColor")
% 棒にするには Length と一緒に 1 回で書く
g = net.a_Bus{3}.tab_parameter.graph;
g.Shape = "vbar"; g.Length = 0.2;
net.a_Bus{3}.tab_parameter.graph = g;
assert(net.a_Bus{3}.tab_parameter.graph.Shape == "vbar")
bra.tab_parameter.graph.Path = "0.2 0.3";
assert(bra.tab_parameter.graph.Path == "0.2 0.3")
% GUI の Parameter タブと同じ代入 (DrawerModelGUI/edit_parameter が実行する 1 行のコード)
s_code = "net.a_Branch{1}.tab_parameter.graph.Path = ""0.1 0.2; 0.3"";";
assert(error_id(@() run_code(net, s_code)) == "GUILDA:layout_parse_path:InvalidPath")
assert(bra.tab_parameter.graph.Path == "0.2 0.3")
eval("net.a_Bus{1}.tab_parameter.graph.Length = 0.2;");
assert(bus.tab_parameter.graph.Length == 0.2)
% graph 以外の Parameter には検査がない
para = bus.a_Parameter{cellfun(@(p) p.s_tag == "powerflow", bus.a_Parameter)};
assert(isempty(para.f_validate))

%% get_layout returns the graph of every element by tag
net = network.IEEE14bus();
L = net.get_layout();
assert(isequal(fieldnames(L)', {'tab_bus', 'tab_branch', 'tab_component'}))
assert(isequal(string(L.tab_bus.Properties.VariableNames), ["Tag","X","Y","Shape","Length","MarkerSize","Color"]))
assert(isequal(string(L.tab_branch.Properties.VariableNames), ["Tag","From","To","Path","FromOffset","ToOffset","Style"]))
assert(isequal(string(L.tab_component.Properties.VariableNames), ["Tag","Bus","DX","DY","Shape","Path","Offset","MarkerSize","Color"]))
assert(isequal(L.tab_bus.Tag, string(cellfun(@(b) char(b.s_tag), net.a_Bus, 'UniformOutput', false))))
assert(height(L.tab_branch) == numel(net.a_Branch) && L.tab_branch.From(1) == "B001" && L.tab_branch.To(1) == "B002")
assert(L.tab_component.Tag(2) == "B002SG1" && L.tab_component.Bus(2) == "B002")
L0 = PowerNetwork().get_layout();
assert(height(L0.tab_bus) == 0 && isequal(string(L0.tab_component.Properties.VariableNames), string(L.tab_component.Properties.VariableNames)))

%% set_layout writes some columns or rows
net = network.IEEE14bus();
DebugScript.helper.quiet(@() net.initialize);
L = net.get_layout();
L.tab_bus.Length(L.tab_bus.Shape == "hbar") = 0.12;
net.set_layout(L);
assert(all(net.get_layout().tab_bus.Length(L.tab_bus.Shape == "hbar") == 0.12))
assert(DebugScript.helper.edit_flag(net) == "initialized" && isempty(DebugScript.helper.stale(net)), "graph の編集は何も古くしない")
L1 = struct("tab_bus", table("B002", 0.7, 'VariableNames', ["Tag", "X"]), ...
            "tab_component", table("B002SG1", "^", 'VariableNames', ["Tag", "Shape"]));
y0 = net.a_Bus{2}.tab_parameter.graph.Y;
net.set_layout(L1);
assert(net.a_Bus{2}.tab_parameter.graph.X == 0.7 && net.a_Bus{2}.tab_parameter.graph.Y == y0)
assert(net.a_Bus{2}.a_Component{1}.tab_parameter.graph.Shape == "^")
% From、To、Bus は読むだけ (あっても書かない)
L2 = net.get_layout();
L2.tab_branch.From(1) = "B014";
net.set_layout(L2);
assert(net.a_Branch{1}.a_Bus{1}.s_tag == "B001")

%% set_layout: unknown tags and columns, IgnoreUnknown
net = network.IEEE14bus();
L = struct("tab_bus", table(["B001"; "B099"], [0.3; 0.4], 'VariableNames', ["Tag", "X"]));
x0 = net.a_Bus{1}.tab_parameter.graph.X;
assert(error_id(@() net.set_layout(L)) == "GUILDA:PowerNetwork:LayoutUnknownTag")
assert(net.a_Bus{1}.tab_parameter.graph.X == x0, "知らないタグでも書く前に止まる")
net.set_layout(L, IgnoreUnknown=true);
assert(net.a_Bus{1}.tab_parameter.graph.X == 0.3)
assert(error_id(@() net.set_layout(struct("tab_bus", table("B001", 1, 'VariableNames', ["Tag", "Xaxis"])))) == "GUILDA:PowerNetwork:LayoutUnknownColumn")
assert(error_id(@() net.set_layout(struct("tab_line", table("B001", 'VariableNames', "Tag")))) == "GUILDA:PowerNetwork:LayoutUnknownColumn")
assert(error_id(@() net.set_layout(struct("tab_bus", table(1, 'VariableNames', "X")))) == "GUILDA:PowerNetwork:LayoutNoTag")

%% set_layout checks all rows before any write
net = network.IEEE14bus();
L  = net.get_layout();
L0 = L;
L.tab_bus.X(1) = 0.9;                           % 正しい行
L.tab_branch.Path(end) = "0.1";                 % 最後の表の最後の行だけ壊れている
assert(error_id(@() net.set_layout(L)) == "GUILDA:layout_parse_path:InvalidPath")
assert(isequaln(net.get_layout(), L0), "1 行が壊れていても何も書かない")
L = L0;
L.tab_bus.Shape(5) = "hbar";
L.tab_bus.Length(5) = NaN;
L.tab_component.DX(1) = 0.5;
assert(error_id(@() net.set_layout(L)) == "GUILDA:Bus:BarLength")
assert(isequaln(net.get_layout(), L0))
% 別の系統に写す (同じタグだけ)
net9 = DebugScript.helper.build_9bus();
net9.set_layout(net.get_layout(), IgnoreUnknown=true);
assert(net9.a_Bus{1}.tab_parameter.graph.X == L0.tab_bus.X(1))

%% CSV round trip keeps the layout
net = network.IEEE14bus();
L = net.get_layout();
L.tab_branch.Path(2) = "";
L.tab_component.Color(1) = "#00FF7F";
net.set_layout(L);
s_dir = fullfile(tempname, "Net14");
mkdir(fileparts(s_dir));
c_rm  = onCleanup(@() rmdir(fileparts(s_dir), "s"));
path  = net.export(s_dir);
net2  = DebugScript.helper.quiet(@() PowerNetwork.import(path, Initialize=false));
assert(isequaln(net2.get_layout(), net.get_layout()))
% writetable で書いた配置の表も読める
s_csv = fullfile(fileparts(s_dir), "bus_layout.csv");
writetable(L.tab_bus, s_csv);
tab = readtable(s_csv, "TextType", "string");
net2.set_layout(struct("tab_bus", tab(:, ["Tag", "X", "Y", "Shape", "Length", "Color"])));
assert(isequaln(net2.get_layout().tab_bus, L.tab_bus))

%% import stops at the old graph columns
s_dir = fullfile(tempname, "Old3");
mkdir(fileparts(s_dir));
c_rm2 = onCleanup(@() rmdir(fileparts(s_dir), "s"));
path  = DebugScript.helper.build_3bus("gen-1axis").export(s_dir);
s_bus = fullfile(path, "bus", "parameter.csv");
tab   = readtable(s_bus, "TextType", "string");
tab   = renamevars(tab, ["X", "Y"], ["Xaxis", "Yaxis"]);
writetable(tab, s_bus);
ME = caught(@() PowerNetwork.import(path));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:import:OldGraphColumns" && contains(ME.message, "tools.layout_convert_columns"))

%% Converter: the values of notes/graph-layout.md §7.2 (IEEE14bus)
s_dir = fullfile(tempname, "conv");
c_rm3 = onCleanup(@() rmdir(s_dir, "s"));
mkdir(s_dir);
s_net = fullfile(s_dir, "Old14");
write_lines(fullfile(s_net, "bus", "parameter.csv"), [
    "Tag,V,Varg,Xaxis,Yaxis,Marker,Slack"
    "B,1.06,0,0.2,0.56,_0.1,1"
    "B,1.045,0,0.34,0.28,_0.13,0"
    "B,1.01,0,0.9,0.1,|0.2,0"
    "B,1.0,0,0.5,0.5,o,0"]);
write_lines(fullfile(s_net, "branch", "parameter.csv"), [
    "Type,From,To,R,X,C,MidXaxis,MidYaxis,Marker"
    "pi,1,2,0.01938,0.05917,0.0264,""[0.23,0.36]"",""[0.5,0.33]"",-"
    "pi,2,3,0.01,0.1,0,,,oo-"
    "pi,3,4,0.01,0.1,0,[0.95],[0.5],-oo"]);
write_lines(fullfile(s_net, "component", "load-power", "main.csv"), [
    "Bus,P,Q,Xaxis,Yaxis,Marker,MidXaxis,MidYaxis"
    "2,-0.217,-0.127,0.31,0.25,<,[0.36],[0.25]"
    "4,-0.1,0,NaN,NaN,s,,"]);
write_lines(fullfile(s_net, "component", "gen-park", "main.csv"), [
    "Bus,P,Q,Xaxis,Yaxis,Marker,MidXaxis,MidYaxis"
    "1,0,NaN,0.2,0.62,o,,"
    "2,0.4,NaN,0.415,0.22,o,,"]);
sv_csv  = fullfile(s_net, ["bus/parameter.csv", "branch/parameter.csv", "component/load-power/main.csv", "component/gen-park/main.csv"]);
c_keep0 = arrayfun(@non_graph_columns, sv_csv, "UniformOutput", false);
sv_file = tools.layout_convert_columns(s_dir);              % model folders below s_dir
assert(numel(sv_file) == 4)
% graph 以外の列 (Slack、V、Varg、P、Q、From、To、R、X、…) は名前・順・値の文字がそのまま
assert(isequal(arrayfun(@non_graph_columns, sv_csv, "UniformOutput", false), c_keep0), "graph 以外の列が変わった")
assert(isempty(tools.layout_convert_columns(s_net)), "2 回目は何も変えない")
tb = readtable(fullfile(s_net, "bus", "parameter.csv"), "TextType", "string");
assert(isequal(string(tb.Properties.VariableNames), ["Tag","V","Varg","X","Y","Shape","Length","Slack"]))
assert(isequal(tb.X(1:2), [0.25; 0.405]) && isequal(tb.Y(1:2), [0.56; 0.28]) && isequal(tb.Shape, ["hbar";"hbar";"vbar";"circle"]))
assert(isequal(tb.Length(1:3), [0.1; 0.13; 0.2]) && isnan(tb.Length(4)) && tb.X(3) == 0.9 && tb.Y(3) == 0.2)
s_text = string(fileread(fullfile(s_net, "branch", "parameter.csv")));
assert(contains(s_text, "pi,1,2,0.01938,0.05917,0.0264,0.23 0.5; 0.36 0.33,-0.02,-0.045,line"), s_text)
assert(contains(s_text, "pi,2,3,0.01,0.1,0,,NaN,NaN,transformer") && contains(s_text, "pi,3,4,0.01,0.1,0,0.95 0.5,0.1,NaN,transformer"))
s_text = string(fileread(fullfile(s_net, "component", "load-power", "main.csv")));
assert(contains(s_text, "2,-0.217,-0.127,-0.095,-0.03,<,-0.045 -0.03,-0.045"), s_text)
assert(contains(s_text, "4,-0.1,0,NaN,NaN,square,,NaN"))
s_text = string(fileread(fullfile(s_net, "component", "gen-park", "main.csv")));
assert(contains(s_text, "2,0.4,NaN,0.01,-0.06,circle,,0.01") && contains(s_text, "1,0,NaN,-0.05,0.06,circle,,-0.05"), s_text)
net = DebugScript.helper.quiet(@() PowerNetwork.import(s_net, Initialize=false));
assert(net.a_Branch{2}.tab_parameter.graph.Style == "transformer")
% x と y の数が違えば、その行を示して止める (ファイルは変えない)
write_lines(fullfile(s_net, "branch", "parameter.csv"), [
    "Type,From,To,R,X,C,MidXaxis,MidYaxis,Marker"
    "pi,1,2,0.01,0.1,0,""[0.23,0.36]"",[0.5],-"]);
ME = caught(@() tools.layout_convert_columns(s_net));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:layout_convert_columns:MidPoints" && contains(ME.message, "row 1"))
assert(contains(string(fileread(fullfile(s_net, "branch", "parameter.csv"))), "MidXaxis"))
assert(DebugScript.helper.msg_id(caught(@() tools.layout_convert_columns(fullfile(s_dir, "none")))) == "GUILDA:layout_convert_columns:NoModelFolder")

%% Bundled networks: converted columns, §7.2 values of IEEE14bus
net = network.IEEE14bus();
L = net.get_layout();
assert(isequal(L.tab_bus{1:2, ["X", "Y", "Length"]}, [0.25 0.56 0.1; 0.405 0.28 0.13]) && all(L.tab_bus.Shape(1:2) == "hbar"))
assert(L.tab_branch.Path(1) == "0.23 0.5; 0.36 0.33" && isequal(L.tab_branch{1, ["FromOffset", "ToOffset"]}, [-0.02 -0.045]))
i_load = find(L.tab_component.Bus == "B002" & L.tab_component.Shape == "<", 1);
assert(isequal(L.tab_component{i_load, ["DX", "DY", "Offset"]}, [-0.095 -0.03 -0.045]) && L.tab_component.Path(i_load) == "-0.045 -0.03")
assert(isequal(L.tab_component{"B002SG1" == L.tab_component.Tag, ["DX", "DY", "Offset"]}, [0.01 -0.06 0.01]))
assert(sum(L.tab_branch.Style == "transformer") > 0)
sct_file = dir(fullfile(fileparts(which("network.IEEE14bus")), "..", "**", "*.csv"));
for k = 1:numel(sct_file)
    s_head = string(readlines(fullfile(sct_file(k).folder, sct_file(k).name), "EmptyLineRule", "skip"));
    if contains(sct_file(k).folder, "archive") || isempty(s_head); continue; end
    assert(~any(ismember(split(s_head(1), ","), ["Xaxis", "Yaxis", "Marker", "MidXaxis", "MidYaxis"])), sct_file(k).name)
end


function sm = non_graph_columns(s_file)
% CSV の graph 以外の列を、見出しと値の文字のまま返す (古い列・新しい列を除く)
    sv_graph = ["Xaxis","Yaxis","Marker","MidXaxis","MidYaxis","Shape","Length","Path","FromOffset","ToOffset","Style","DX","DY","Offset"];
    sv_line = readlines(s_file, "EmptyLineRule", "skip");
    c_row   = cell(numel(sv_line), 1);
    for i = 1:numel(sv_line)
        c_tok    = regexp(sv_line(i), '(?:^|,)("(?:[^"]|"")*"|[^,]*)', 'tokens');
        c_row{i} = string([c_tok{:}]);
    end
    sm = vertcat(c_row{:});
    sv_head = sm(1, :);
    if ~contains(s_file, filesep + "bus" + filesep)   % X, Y of a bus are graph columns; X of a branch is the reactance
        sv_graph = [sv_graph, "Y"];
    else
        sv_graph = [sv_graph, "X", "Y"];
    end
    sm = sm(:, ~ismember(sv_head, sv_graph));
end

function set_graph(obj, s_col, val)
% 要素の graph の 1 列を直接書く (bus.tab_parameter.graph.(s_col) = val)
    obj.tab_parameter.graph.(s_col) = val;
end

function run_code(net, s_code) %#ok<INUSL> net is used by the code
% GUI の Parameter タブと同じく、代入のコードを実行する
    eval(s_code);
end

function write_lines(s_file, sv_line)
% CSV を行の文字列から書く (フォルダも作る)
    if ~isfolder(fileparts(s_file)); mkdir(fileparts(s_file)); end
    writelines(sv_line, s_file);
end

function ME = caught(fcn)
% fcn がエラーで止まることを確かめ、そのエラーを返す
    ME = [];
    try
        DebugScript.helper.quiet(fcn);
    catch ME
    end
    assert(~isempty(ME), "エラーにならなかった")
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
    end
end
