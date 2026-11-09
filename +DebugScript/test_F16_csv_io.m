% F16 CSV の書き出しと読み込みの確認
%
%   export_csv は書き出さなかった局所制御器と広域制御器を警告で示す (Issue #94)
%   組み込み系統の構築では警告を出さない
%   母線、ブランチ、機器のタグは FullTag 列で往復し、FullTag の無い CSV は従来どおり読む (Issue #95)
%   add_bus の FullTag は完全なタグを与え、読み込みは母線の改名を記録しない (Issue #95)
%   未知の列は警告、行番号や ID の誤りはエラーで、ファイル、行、列を示す (Issue #96)
%   表の誤りでは Network= の系統を変更しない (Issue #96)
%
% 実行: runtests("DebugScript.test_F16_csv_io")  または  DebugScript.run_all("Features","F16")

% 共通設定 (各テストの前に毎回実行される)
s_id = "GUILDA:PowerNetwork:ControllersNotSaved";


%% export_csv names the local controllers it does not write
net = DebugScript.helper.quiet(@() network.IEEE9bus());
[s_dir, c] = temp_folder(); %#ok<ASGLU>
[s_msg, id, s_path] = export_with_warning(net, fullfile(s_dir, "Net9"));
assert(id == s_id)
assert(contains(s_msg, "Local (6): SG1B001/CA1SG1B001, SG1B001/CA1SG1B001/CP2SG1B001"))
assert(contains(s_msg, "SG1B003/CA1SG1B003/CP2SG1B003"))
assert(contains(s_msg, "Global (0): none"))
assert(isfile(fullfile(s_path, "bus", "parameter.csv")), "警告の前に書き出しを終える")

% 読み込んだ系統に制御器は戻らない (仕様)
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(s_path));
assert(isempty(net2.a_Bus{1}.a_Component{1}.a_LocalController))
assert(size(net2.get_sys().A, 1) == 9)


%% export_csv names the global controllers it does not write
net = DebugScript.helper.quiet(@() network.IEEE9bus());
agc = net.add_global_controller("agc-PI", ["SG1B001","SG1B002"]);
[s_dir, c] = temp_folder(); %#ok<ASGLU>
[s_msg, id] = export_with_warning(net, fullfile(s_dir, "Net9"));
assert(id == s_id)
assert(contains(s_msg, "Local (6):"))
assert(contains(s_msg, "Global (1): " + string(agc)))


%% export_csv does not warn without controllers
net = DebugScript.helper.build_ieee14();
[s_dir, c] = temp_folder(); %#ok<ASGLU>
[~, id] = export_with_warning(net, fullfile(s_dir, "Net14"));
assert(id == "")


%% Building the built-in networks does not warn
for s_net = ["IEEE9bus", "IEEE14bus", "IEEE14bus_NoTap", "IEEE14bus_lossless", ...
               "IEEE68bus", "Ishizaki6Bus", "TEST31bus", "Txt3Bus", ...
               "IEEJ_EAST10", "IEEJ_EAST30", "IEEJ_WEST10", "IEEJ_WEST30"]
    lastwarn("");
    DebugScript.helper.quiet(@() feval("network." + s_net));
    id = DebugScript.helper.msg_id();
    assert(isempty(id), s_net + ": " + id)
end


%% Bus tags survive a round trip
for s_tag = ["Bus2", "B1000", "BX", "1234"]
    net = tag_network();
    net.a_Bus{2}.s_tag = s_tag;
    [net2, c] = round_trip(net); %#ok<ASGLU>
    assert(string(net2.a_Bus{2}) == s_tag, s_tag)
    assert(isequal(string(net2.a_Bus), string(net.a_Bus)), s_tag)
    assert(string(net2.a_Branch{1}.a_Bus{2}) == s_tag, s_tag)
end


%% Missing bus numbers survive a round trip
net = tag_network();
net.add_bus();
net.remove_bus("B003", RemoveBranches=true);
assert(isequal(string(net.a_Bus), ["B001"; "B002"; "B004"]))
[net2, c] = round_trip(net); %#ok<ASGLU>
assert(isequal(string(net2.a_Bus), ["B001"; "B002"; "B004"]))
assert(string(net2.add_bus()) == "B005", "次の番号は欠番を再利用しない")


%% Branch tags survive a round trip
net = tag_network();
net.add_branch("pi", [1, 3], X=0.1);
net.remove_branch(string(net.a_Branch{1}));
sv_tag = string(net.a_Branch);
assert(~endsWith(sv_tag(1), "001"), "欠番を作る")
net.a_Branch{2}.s_tag = "Line7";
sv_tag = string(net.a_Branch);
[net2, c] = round_trip(net); %#ok<ASGLU>
assert(isequal(string(net2.a_Branch), sv_tag))


%% Component tags survive a round trip across model types
net = tag_network();
bus = net.a_Bus{1};
assert(isequal(sort(string(bus.a_Component)), sort(["LPQ1B001"; "SG2B001"])), "機種をまたぐ番号")
bus.a_Component{2}.s_tag = "Gen9";
sv_tag = string(bus.a_Component);
[net2, c] = round_trip(net); %#ok<ASGLU>
sv_tag2 = string(net2.a_Bus{1}.a_Component);
assert(isequal(sort(sv_tag2), sort(sv_tag)))


%% Component tags stay as written after a bus rename
net = tag_network();
net.a_Bus{1}.s_tag = "Bus1";
sv_tag = string(net.a_Bus{1}.a_Component);
[net2, c] = round_trip(net); %#ok<ASGLU>
assert(isequal(sort(string(net2.a_Bus{1}.a_Component)), sort(sv_tag)), "保存時のタグを復元する")


%% The Tag column holds the prefix for reading without FullTag
net = tag_network();
net.a_Bus{1}.s_tag = "B1000";
net.a_Bus{2}.s_tag = "Bus2";
net.a_Bus{3}.s_tag = "BX";
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(s_dir, "Net")));
tab = readtable(fullfile(s_path, "bus", "parameter.csv"), "TextType", "string");
assert(isequal(tab.Tag, ["B"; "Bus"; "BX"]))
assert(isequal(tab.FullTag, ["B1000"; "Bus2"; "BX"]))


%% CSV without FullTag loads as before
net = tag_network();
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(s_dir, "Old")));
remove_full_tag(fullfile(s_path, "bus", "parameter.csv"));
remove_full_tag(fullfile(s_path, "branch", "parameter.csv"));
for s_key = string({dir(fullfile(s_path, "component", "*-*")).name})
    remove_full_tag(fullfile(s_path, "component", s_key, "main.csv"));
end
s_file = fullfile(s_path, "bus", "parameter.csv");
tab = readtable(s_file, "TextType", "string");
tab.Tag = ["Bus"; "Bus"; "Bus"];
writetable(tab, s_file);
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(s_path, Initialize=false));
assert(isequal(string(net2.a_Bus), ["Bus001"; "Bus002"; "Bus003"]), "Tag は接頭辞のまま")
assert(isequal(sort(string(net2.a_Bus{1}.a_Component)), ["LPQ2Bus001"; "SG1Bus001"]))


%% An empty FullTag keeps the automatic tag
net = tag_network();
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path   = DebugScript.helper.quiet(@() net.export_csv(fullfile(s_dir, "Blank")));
s_file   = fullfile(s_path, "bus", "parameter.csv");
tab = readtable(s_file, "TextType", "string");
tab.FullTag = ["Keep7"; ""; ""];
writetable(tab, s_file);
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(s_path, Initialize=false));
assert(isequal(string(net2.a_Bus), ["Keep7"; "B008"; "B009"]))


%% A duplicate FullTag is renamed by the tag rule
net = tag_network();
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path   = DebugScript.helper.quiet(@() net.export_csv(fullfile(s_dir, "Dup")));
s_file   = fullfile(s_path, "bus", "parameter.csv");
tab = readtable(s_file, "TextType", "string");
tab.FullTag(2) = tab.FullTag(1);
writetable(tab, s_file);
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(s_path, Initialize=false));
assert(numel(unique(string(net2.a_Bus))) == 3)
assert(string(net2.a_Bus{2}) == "B001002")


%% add_bus FullTag gives the complete tag without an automatic number
net = PowerNetwork("TagNet");
assert(string(net.add_bus(FullTag="Sub7", Tag="Ignored")) == "Sub7")
assert(string(net.add_bus(FullTag="1234")) == "1234")
assert(string(net.add_bus()) == "B1235", "次の番号は完全なタグの数字に続く")
assert(string(net.add_bus(Tag="Bus", FullTag="")) == "Bus1236", "空なら従来どおり")


%% add_bus FullTag already in use is renamed with an Info line
net = initialized_network();
s_out = evalc('bus = net.add_bus(FullTag="B001");');
assert(string(bus) == "B001002")
assert(contains(s_out, "Tag changed") && contains(s_out, "B001002"))
assert(sum(string(net.a_Bus) == "B001") == 1)
assert(endsWith(net.sct_stale.powerflow(end), "<<-Add--- B001002"), "追加のメッセージは確定したタグを示す")


%% Importing a bus FullTag logs the addition with that tag and no rename
net = PowerNetwork("TagNet");
net.add_bus(FullTag="Sub7");
net.add_bus(FullTag="1234");
net.add_branch("pi", [1, 2], X=0.1);
net.a_Bus{1}.add_component("load-power", P=-0.1);
net.a_Bus{2}.add_component("load-power", P=-0.1);
[s_dir, c] = temp_folder(); %#ok<ASGLU>
s_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(s_dir, "Net")));

% 古さのメッセージは初回の initialize の後から積まれるので、初期化済みの系統へ読み込む
net2 = initialized_network();
DebugScript.helper.quiet(@() PowerNetwork.import_csv(s_path, Network=net2, Initialize=false));
assert(all(ismember(["Sub7"; "1234"], string(net2.a_Bus))))
sv_log = net2.sct_stale.powerflow;
assert(any(endsWith(sv_log, "<<-Add--- Sub7")) && any(endsWith(sv_log, "<<-Add--- 1234")))
assert(~any(contains(sv_log, "<<-Add--- B")), "自動のタグを経由しない")
assert(~any(contains(sv_log, "rename")), "改名は何も古くしない")


%% An unknown column warns with the file and column, and does not stop the import
[s_path, c] = csv_folder(); %#ok<ASGLU>
s_file = fullfile(s_path, "bus", "parameter.csv");
tab = readtable(s_file, "TextType", "string");
tab = renamevars(tab, "Bshunt", "Bshnt");
tab.Bshnt(:) = 0.5;
writetable(tab, s_file);
[net2, s_msg, id] = import_with_warning(s_path);
assert(id == "GUILDA:import_csv:UnknownColumn")
assert(contains(s_msg, "bus/parameter.csv") && contains(s_msg, "Bshnt"))
assert(numel(net2.a_Bus) == 3 && net2.a_Bus{1}.tab_parameter.dynamics.Bshunt == 0, "列は無視する")


%% The removed bus columns V0 and Varg0 are ignored with an INFO message
% 母線の初期値 V0, Varg0 は廃止。旧形式の CSV は INFO を出して列を無視する (警告ではない)
[s_path, c] = csv_folder(); %#ok<ASGLU>
s_file = fullfile(s_path, "bus", "parameter.csv");
tab = readtable(s_file, "TextType", "string");
tab.V0(:) = 1.1;
tab.Varg0(:) = 0.1;
writetable(tab, s_file);
lastwarn("");
s_log = evalc("net2 = PowerNetwork.import_csv(s_path);");
assert(isempty(lastwarn()) && contains(s_log, "V0, Varg0") && contains(s_log, "bus/parameter.csv"))
assert(numel(net2.a_Bus) == 3 && ~any(ismember(["V0","Varg0"], net2.a_Bus{1}.tab_parameter.powerflow.Properties.VariableNames)))


%% A memo column warns with its name as written in each table
w = warning("off", "MATLAB:table:ModifiedAndSavedVarnames");
c_w = onCleanup(@() warning(w));
for s_rel = ["network/parameter.csv", "branch/parameter.csv", "component/load-power/main.csv", "component/load-power/opf.csv"]
    [s_path, c] = csv_folder(); %#ok<ASGLU>
    s_file   = fullfile(s_path, s_rel);
    sv_line  = readlines(s_file, "EmptyLineRule", "skip");
    sv_line(1) = sv_line(1) + ",備考";
    sv_line(2:end) = sv_line(2:end) + ",1";
    writelines(sv_line, s_file);
    [~, s_msg, id] = import_with_warning(s_path);
    assert(id == "GUILDA:import_csv:UnknownColumn", s_rel)
    assert(contains(s_msg, s_rel) && contains(s_msg, "備考"), s_rel)
end


%% Exported columns are all known
[s_path, c] = csv_folder(); %#ok<ASGLU>
[~, ~, id] = import_with_warning(s_path);
assert(id == "")


%% A bad bus number names the file, row and column and leaves Network= unchanged
for sct = [struct("rel", "branch/parameter.csv", "col", "To", "row", 2, "val", 99), ...
           struct("rel", "branch/parameter.csv", "col", "From", "row", 1, "val", 0), ...
           struct("rel", "branch/parameter.csv", "col", "To", "row", 1, "val", 1.5), ...
           struct("rel", "component/load-power/main.csv", "col", "Bus", "row", 1, "val", 99)]
    [s_path, c] = csv_folder(); %#ok<ASGLU>
    s_file = fullfile(s_path, sct.rel);
    tab = readtable(s_file, "TextType", "string");
    tab.(sct.col)(sct.row) = sct.val;
    writetable(tab, s_file);

    net = PowerNetwork("Host");
    r_baseHz = net.tab_parameter.base.Hz;
    s_file   = fullfile(s_path, "network", "parameter.csv");
    tab = readtable(s_file);
    tab.Hz = r_baseHz + 1;
    writetable(tab, s_file);
    ME = import_error(s_path, net);
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:BusRow", sct.rel)
    s_want = sprintf("%s row %d: %s = %s", sct.rel, sct.row, sct.col, string(sct.val));
    assert(contains(ME.message, s_want), ME.message)
    assert(isempty(net.a_Bus) && isempty(net.a_Branch), "検査の前に追加しない")
    assert(net.tab_parameter.base.Hz == r_baseHz, "検査の前に基準値を変えない")
end


%% A text or empty value in a bus number column names the row
for s_val = ["x", ""]
    [s_path, c] = csv_folder(); %#ok<ASGLU>
    s_file = fullfile(s_path, "branch", "parameter.csv");
    tab = readtable(s_file, "TextType", "string");
    tab.To = string(tab.To);
    tab.To(2) = s_val;
    writetable(tab, s_file);
    ME = import_error(s_path, PowerNetwork("Host"));
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:BusRow", s_val)
    assert(contains(ME.message, "branch/parameter.csv row 2: To = NaN"), ME.message)
end


%% An empty ParameterID names the row
[s_path, c] = csv_folder(); %#ok<ASGLU>
s_file = fullfile(s_path, "component", "load-power", "main.csv");
tab = readtable(s_file, "TextType", "string");
tab.ParameterID(1) = NaN;
writetable(tab, s_file);
ME = import_error(s_path, PowerNetwork("Host"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:UnknownID")
assert(contains(ME.message, "main.csv row 1: ParameterID = NaN"), ME.message)


%% A folder without component/ warns
[s_path, c] = csv_folder(); %#ok<ASGLU>
rmdir(fullfile(s_path, "component"), "s");
[net2, s_msg, id] = import_with_warning(s_path);
assert(id == "GUILDA:import_csv:NoComponentFolder")
assert(contains(s_msg, "component"))
assert(numel(net2.a_Bus) == 3)


%% A missing table names the file and leaves Network= unchanged
for s_rel = ["bus/parameter.csv", "branch/parameter.csv", "component/load-power/main.csv", ...
               "component/load-power/dynamics.csv", "component/load-power/opf.csv"]
    [s_path, c] = csv_folder(); %#ok<ASGLU>
    delete(fullfile(s_path, s_rel));
    net = PowerNetwork("Host");
    ME = import_error(s_path, net);
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:MissingFile", s_rel)
    assert(contains(ME.message, s_rel), ME.message)
    assert(isempty(net.a_Bus), s_rel)
end


%% An unknown ParameterID or OpfID names the row and leaves Network= unchanged
for s_col = ["ParameterID", "OpfID"]
    [s_path, c] = csv_folder(); %#ok<ASGLU>
    s_file = fullfile(s_path, "component", "load-power", "main.csv");
    tab = readtable(s_file, "TextType", "string");
    tab.(s_col)(2) = 99;
    writetable(tab, s_file);
    net = PowerNetwork("Host");
    ME = import_error(s_path, net);
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:UnknownID", s_col)
    assert(contains(ME.message, "component/load-power/main.csv row 2: " + s_col + " = 99"), ME.message)
    assert(isempty(net.a_Bus), s_col)
end


%% A number in the Q column of a generator warns through the component
[s_path, c] = csv_folder(); %#ok<ASGLU>
s_file = fullfile(s_path, "component", "gen-park", "main.csv");
tab = readtable(s_file, "TextType", "string");
tab.Q(1) = 0.3;
writetable(tab, s_file);
[~, s_msg, id] = import_with_warning(s_path);
assert(id == "GUILDA:Component:GeneratorQIgnored")
assert(contains(s_msg, "SG"))


%% A failure after the checks can leave Network= partly built (see the help)
[s_path, c] = csv_folder();
s_file = fullfile(s_path, "branch", "parameter.csv");
tab = readtable(s_file, "TextType", "string");
tab.Type(2) = "nosuch";
writetable(tab, s_file);
net = PowerNetwork("Host");
ME = import_error(s_path, net);
assert(contains(ME.message, "Branch model key"), ME.message)    % tools.mustBeKeyOf in add_branch
assert(numel(net.a_Bus) == 3 && numel(net.a_Branch) == 1)


function [s_path, c] = csv_folder()
    % Exported folder of tag_network
    [s_dir, c] = temp_folder();
    s_path = DebugScript.helper.quiet(@() tag_network().export_csv(fullfile(s_dir, "Net")));
end

function [net, s_msg, id] = import_with_warning(s_path)
    % Import without initialize and return the last warning
    lastwarn("");
    net = DebugScript.helper.quiet(@() PowerNetwork.import_csv(s_path, Initialize=false));
    [s_msg, id] = lastwarn(); id = DebugScript.helper.msg_id(s_msg, id);
    s_msg   = string(s_msg);
    id      = string(id);
end

function ME = import_error(s_path, net)
    ME = [];
    try
        DebugScript.helper.quiet(@() PowerNetwork.import_csv(s_path, Network=net, Initialize=false));
    catch ME
    end
    assert(~isempty(ME), "エラーにならない")
end

function net = initialized_network()
    % Network that has been initialized (edits are reported as stale messages)
    net = DebugScript.helper.build_ieee14();
    evalc("net.initialize();");
end

function net = tag_network()
    % 3 buses, 2 branches, and a load and a generator on bus 1
    net = PowerNetwork("TagNet");
    for i = 1:3
        net.add_bus();
    end
    net.add_branch("pi", [1, 2], X=0.1);
    net.add_branch("pi", [2, 3], X=0.1);
    net.a_Bus{1}.add_component("load-power", P=-0.1);
    net.a_Bus{1}.add_component("gen-park", P=0.1);
    net.a_Bus{3}.add_component("load-power", P=-0.1);
end

function [net2, c] = round_trip(net)
    [s_dir, c] = temp_folder();
    s_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(s_dir, "Net")));
    net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(s_path, Initialize=false));
end

function remove_full_tag(s_file)
    tab = readtable(s_file, "TextType", "string");
    writetable(removevars(tab, "FullTag"), s_file);
end

function [s_msg, id, s_path] = export_with_warning(net, s_path)
    % Run export_csv and return the last warning
    lastwarn("");
    s_path = DebugScript.helper.quiet(@() net.export_csv(s_path));
    [s_msg, id] = lastwarn(); id = DebugScript.helper.msg_id(s_msg, id);
    s_msg   = string(s_msg);
    id      = string(id);
end

function [s_dir, c] = temp_folder()
    s_dir = tempname;
    mkdir(s_dir);
    c = onCleanup(@() rmdir(s_dir, "s"));
end
