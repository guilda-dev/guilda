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
str_id = "GUILDA:PowerNetwork:ControllersNotSaved";


%% export_csv names the local controllers it does not write
net = DebugScript.helper.quiet(@() network.IEEE9bus());
[str_dir, c] = temp_folder(); %#ok<ASGLU>
[str_msg, id, str_path] = export_with_warning(net, fullfile(str_dir, "Net9"));
assert(id == str_id)
assert(contains(str_msg, "Local (6): SG1B001/CAavr1, SG1B001/CAavr1/CPpss1"))
assert(contains(str_msg, "SG1B003/CAavr3/CPpss3"))
assert(contains(str_msg, "Global (0): none"))
assert(isfile(fullfile(str_path, "bus", "parameter.csv")), "警告の前に書き出しを終える")

% 読み込んだ系統に制御器は戻らない (仕様)
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path));
assert(isempty(net2.a_Bus{1}.a_Component{1}.a_LocalController))
assert(size(net2.get_sys().A, 1) == 9)


%% export_csv names the global controllers it does not write
net = DebugScript.helper.quiet(@() network.IEEE9bus());
agc = controller.agc.broadcast_PI_AGC(net, "agc", "SG1B001", "SG1B002");
net.add_global_controller(agc);
[str_dir, c] = temp_folder(); %#ok<ASGLU>
[str_msg, id] = export_with_warning(net, fullfile(str_dir, "Net9"));
assert(id == str_id)
assert(contains(str_msg, "Local (6):"))
assert(contains(str_msg, "Global (1): " + string(agc)))


%% export_csv does not warn without controllers
net = DebugScript.helper.build_ieee14();
[str_dir, c] = temp_folder(); %#ok<ASGLU>
[~, id] = export_with_warning(net, fullfile(str_dir, "Net14"));
assert(id == "")


%% Building the built-in networks does not warn
for str_net = ["IEEE9bus", "IEEE14bus", "IEEE14bus_NoTap", "IEEE14bus_lossless", ...
               "IEEE68bus", "Ishizaki6Bus", "TEST31bus", "Txt3Bus"]
    lastwarn("");
    DebugScript.helper.quiet(@() feval("network." + str_net));
    id = DebugScript.helper.msg_id();
    assert(isempty(id), str_net + ": " + id)
end


%% Bus tags survive a round trip
for str_tag = ["Bus2", "B1000", "BX", "1234"]
    net = tag_network();
    net.a_Bus{2}.str_tag = str_tag;
    [net2, c] = round_trip(net); %#ok<ASGLU>
    assert(string(net2.a_Bus{2}) == str_tag, str_tag)
    assert(isequal(string(net2.a_Bus), string(net.a_Bus)), str_tag)
    assert(string(net2.a_Branch{1}.a_Bus{2}) == str_tag, str_tag)
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
str_tag = string(net.a_Branch);
assert(~endsWith(str_tag(1), "001"), "欠番を作る")
net.a_Branch{2}.str_tag = "Line7";
str_tag = string(net.a_Branch);
[net2, c] = round_trip(net); %#ok<ASGLU>
assert(isequal(string(net2.a_Branch), str_tag))


%% Component tags survive a round trip across model types
net = tag_network();
bus = net.a_Bus{1};
assert(isequal(sort(string(bus.a_Component)), sort(["LPQ1B001"; "SG2B001"])), "機種をまたぐ番号")
bus.a_Component{2}.str_tag = "Gen9";
str_tag = string(bus.a_Component);
[net2, c] = round_trip(net); %#ok<ASGLU>
str_tag2 = string(net2.a_Bus{1}.a_Component);
assert(isequal(sort(str_tag2), sort(str_tag)))


%% Component tags stay as written after a bus rename
net = tag_network();
net.a_Bus{1}.str_tag = "Bus1";
str_tag = string(net.a_Bus{1}.a_Component);
[net2, c] = round_trip(net); %#ok<ASGLU>
assert(isequal(sort(string(net2.a_Bus{1}.a_Component)), sort(str_tag)), "保存時のタグを復元する")


%% The Tag column holds the prefix for reading without FullTag
net = tag_network();
net.a_Bus{1}.str_tag = "B1000";
net.a_Bus{2}.str_tag = "Bus2";
net.a_Bus{3}.str_tag = "BX";
[str_dir, c] = temp_folder(); %#ok<ASGLU>
str_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(str_dir, "Net")));
tab = readtable(fullfile(str_path, "bus", "parameter.csv"), "TextType", "string");
assert(isequal(tab.Tag, ["B"; "Bus"; "BX"]))
assert(isequal(tab.FullTag, ["B1000"; "Bus2"; "BX"]))


%% CSV without FullTag loads as before
net = tag_network();
[str_dir, c] = temp_folder(); %#ok<ASGLU>
str_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(str_dir, "Old")));
remove_full_tag(fullfile(str_path, "bus", "parameter.csv"));
remove_full_tag(fullfile(str_path, "branch", "parameter.csv"));
for str_key = string({dir(fullfile(str_path, "component", "*-*")).name})
    remove_full_tag(fullfile(str_path, "component", str_key, "main.csv"));
end
str_file = fullfile(str_path, "bus", "parameter.csv");
tab = readtable(str_file, "TextType", "string");
tab.Tag = ["Bus"; "Bus"; "Bus"];
writetable(tab, str_file);
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
assert(isequal(string(net2.a_Bus), ["Bus001"; "Bus002"; "Bus003"]), "Tag は接頭辞のまま")
assert(isequal(sort(string(net2.a_Bus{1}.a_Component)), ["LPQ2Bus001"; "SG1Bus001"]))


%% An empty FullTag keeps the automatic tag
net = tag_network();
[str_dir, c] = temp_folder(); %#ok<ASGLU>
str_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(str_dir, "Blank")));
str_file = fullfile(str_path, "bus", "parameter.csv");
tab = readtable(str_file, "TextType", "string");
tab.FullTag = ["Keep7"; ""; ""];
writetable(tab, str_file);
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
assert(isequal(string(net2.a_Bus), ["Keep7"; "B008"; "B009"]))


%% A duplicate FullTag is renamed by the tag rule
net = tag_network();
[str_dir, c] = temp_folder(); %#ok<ASGLU>
str_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(str_dir, "Dup")));
str_file = fullfile(str_path, "bus", "parameter.csv");
tab = readtable(str_file, "TextType", "string");
tab.FullTag(2) = tab.FullTag(1);
writetable(tab, str_file);
net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
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
str_out = evalc('bus = net.add_bus(FullTag="B001");');
assert(string(bus) == "B001002")
assert(contains(str_out, "Tag changed") && contains(str_out, "B001002"))
assert(sum(string(net.a_Bus) == "B001") == 1)
assert(endsWith(string(net.tab_editLog.log(end)), "<<-Add--- B001002"), "追加のログは確定したタグを示す")


%% Importing a bus FullTag logs the addition with that tag and no rename
net = PowerNetwork("TagNet");
net.add_bus(FullTag="Sub7");
net.add_bus(FullTag="1234");
net.add_branch("pi", [1, 2], X=0.1);
net.a_Bus{1}.add_component("load-power", P=-0.1);
net.a_Bus{2}.add_component("load-power", P=-0.1);
[str_dir, c] = temp_folder(); %#ok<ASGLU>
str_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(str_dir, "Net")));

% 編集ログは初回の initialize の後から記録されるので、初期化済みの系統へ読み込む
net2 = initialized_network();
DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Network=net2, Initialize=false));
assert(all(ismember(["Sub7"; "1234"], string(net2.a_Bus))))
str_log = string(net2.tab_editLog.log);
assert(any(endsWith(str_log, "<<-Add--- Sub7")) && any(endsWith(str_log, "<<-Add--- 1234")))
assert(~any(contains(str_log, "<<-Add--- B")), "自動のタグを経由しない")
% 既存の系統ではブランチの自動番号がずれるので、ブランチの改名は記録されうる
assert(~any(contains(str_log, "-> Sub7") | contains(str_log, "-> 1234")), "母線の読み込みは改名を記録しない")


%% An unknown column warns with the file and column, and does not stop the import
[str_path, c] = csv_folder(); %#ok<ASGLU>
str_file = fullfile(str_path, "bus", "parameter.csv");
tab = readtable(str_file, "TextType", "string");
tab = renamevars(tab, "Bshunt", "Bshnt");
tab.Bshnt(:) = 0.5;
writetable(tab, str_file);
[net2, str_msg, id] = import_with_warning(str_path);
assert(id == "GUILDA:import_csv:UnknownColumn")
assert(contains(str_msg, "bus/parameter.csv") && contains(str_msg, "Bshnt"))
assert(numel(net2.a_Bus) == 3 && net2.a_Bus{1}.tab_parameter.dynamics.Bshunt == 0, "列は無視する")


%% A memo column warns with its name as written in each table
w = warning("off", "MATLAB:table:ModifiedAndSavedVarnames");
c_w = onCleanup(@() warning(w));
for str_rel = ["network/parameter.csv", "branch/parameter.csv", "component/load-power/main.csv", "component/load-power/opf.csv"]
    [str_path, c] = csv_folder(); %#ok<ASGLU>
    str_file = fullfile(str_path, str_rel);
    str_line = readlines(str_file, "EmptyLineRule", "skip");
    str_line(1) = str_line(1) + ",備考";
    str_line(2:end) = str_line(2:end) + ",1";
    writelines(str_line, str_file);
    [~, str_msg, id] = import_with_warning(str_path);
    assert(id == "GUILDA:import_csv:UnknownColumn", str_rel)
    assert(contains(str_msg, str_rel) && contains(str_msg, "備考"), str_rel)
end


%% Exported columns are all known
[str_path, c] = csv_folder(); %#ok<ASGLU>
[~, ~, id] = import_with_warning(str_path);
assert(id == "")


%% A bad bus number names the file, row and column and leaves Network= unchanged
for sct = [struct("rel", "branch/parameter.csv", "col", "To", "row", 2, "val", 99), ...
           struct("rel", "branch/parameter.csv", "col", "From", "row", 1, "val", 0), ...
           struct("rel", "branch/parameter.csv", "col", "To", "row", 1, "val", 1.5), ...
           struct("rel", "component/load-power/main.csv", "col", "Bus", "row", 1, "val", 99)]
    [str_path, c] = csv_folder(); %#ok<ASGLU>
    str_file = fullfile(str_path, sct.rel);
    tab = readtable(str_file, "TextType", "string");
    tab.(sct.col)(sct.row) = sct.val;
    writetable(tab, str_file);

    net = PowerNetwork("Host");
    r_Hz = net.tab_parameter.base.Hz;
    str_file = fullfile(str_path, "network", "parameter.csv");
    tab = readtable(str_file);
    tab.Hz = r_Hz + 1;
    writetable(tab, str_file);
    ME = import_error(str_path, net);
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:BusRow", sct.rel)
    str_want = sprintf("%s row %d: %s = %s", sct.rel, sct.row, sct.col, string(sct.val));
    assert(contains(ME.message, str_want), ME.message)
    assert(isempty(net.a_Bus) && isempty(net.a_Branch), "検査の前に追加しない")
    assert(net.tab_parameter.base.Hz == r_Hz, "検査の前に基準値を変えない")
end


%% A text or empty value in a bus number column names the row
for str_val = ["x", ""]
    [str_path, c] = csv_folder(); %#ok<ASGLU>
    str_file = fullfile(str_path, "branch", "parameter.csv");
    tab = readtable(str_file, "TextType", "string");
    tab.To = string(tab.To);
    tab.To(2) = str_val;
    writetable(tab, str_file);
    ME = import_error(str_path, PowerNetwork("Host"));
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:BusRow", str_val)
    assert(contains(ME.message, "branch/parameter.csv row 2: To = NaN"), ME.message)
end


%% An empty ParameterID names the row
[str_path, c] = csv_folder(); %#ok<ASGLU>
str_file = fullfile(str_path, "component", "load-power", "main.csv");
tab = readtable(str_file, "TextType", "string");
tab.ParameterID(1) = NaN;
writetable(tab, str_file);
ME = import_error(str_path, PowerNetwork("Host"));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:UnknownID")
assert(contains(ME.message, "main.csv row 1: ParameterID = NaN"), ME.message)


%% A folder without component/ warns
[str_path, c] = csv_folder(); %#ok<ASGLU>
rmdir(fullfile(str_path, "component"), "s");
[net2, str_msg, id] = import_with_warning(str_path);
assert(id == "GUILDA:import_csv:NoComponentFolder")
assert(contains(str_msg, "component"))
assert(numel(net2.a_Bus) == 3)


%% A missing table names the file and leaves Network= unchanged
for str_rel = ["bus/parameter.csv", "branch/parameter.csv", "component/load-power/main.csv", ...
               "component/load-power/dynamics.csv", "component/load-power/opf.csv"]
    [str_path, c] = csv_folder(); %#ok<ASGLU>
    delete(fullfile(str_path, str_rel));
    net = PowerNetwork("Host");
    ME = import_error(str_path, net);
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:MissingFile", str_rel)
    assert(contains(ME.message, str_rel), ME.message)
    assert(isempty(net.a_Bus), str_rel)
end


%% An unknown ParameterID or OpfID names the row and leaves Network= unchanged
for str_col = ["ParameterID", "OpfID"]
    [str_path, c] = csv_folder(); %#ok<ASGLU>
    str_file = fullfile(str_path, "component", "load-power", "main.csv");
    tab = readtable(str_file, "TextType", "string");
    tab.(str_col)(2) = 99;
    writetable(tab, str_file);
    net = PowerNetwork("Host");
    ME = import_error(str_path, net);
    assert(DebugScript.helper.msg_id(ME) == "GUILDA:import_csv:UnknownID", str_col)
    assert(contains(ME.message, "component/load-power/main.csv row 2: " + str_col + " = 99"), ME.message)
    assert(isempty(net.a_Bus), str_col)
end


%% A number in the Q column of a generator warns through the component
[str_path, c] = csv_folder(); %#ok<ASGLU>
str_file = fullfile(str_path, "component", "gen-park", "main.csv");
tab = readtable(str_file, "TextType", "string");
tab.Q(1) = 0.3;
writetable(tab, str_file);
[~, str_msg, id] = import_with_warning(str_path);
assert(id == "GUILDA:Component:GeneratorQIgnored")
assert(contains(str_msg, "SG"))


%% A failure after the checks can leave Network= partly built (see the help)
[str_path, c] = csv_folder(); %#ok<ASGLU>
str_file = fullfile(str_path, "branch", "parameter.csv");
tab = readtable(str_file, "TextType", "string");
tab.Type(2) = "nosuch";
writetable(tab, str_file);
net = PowerNetwork("Host");
ME = import_error(str_path, net);
assert(DebugScript.helper.msg_id(ME) == "MATLAB:validators:mustBeMember")
assert(numel(net.a_Bus) == 3 && numel(net.a_Branch) == 1)


function [str_path, c] = csv_folder()
    % Exported folder of tag_network
    [str_dir, c] = temp_folder();
    str_path = DebugScript.helper.quiet(@() tag_network().export_csv(fullfile(str_dir, "Net")));
end

function [net, str_msg, id] = import_with_warning(str_path)
    % Import without initialize and return the last warning
    lastwarn("");
    net = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
    [str_msg, id] = lastwarn(); id = DebugScript.helper.msg_id(str_msg, id);
    str_msg = string(str_msg);
    id      = string(id);
end

function ME = import_error(str_path, net)
    ME = [];
    try
        DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Network=net, Initialize=false));
    catch ME
    end
    assert(~isempty(ME), "エラーにならない")
end

function net = initialized_network()
    % Network whose edit log is active
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
    [str_dir, c] = temp_folder();
    str_path = DebugScript.helper.quiet(@() net.export_csv(fullfile(str_dir, "Net")));
    net2 = DebugScript.helper.quiet(@() PowerNetwork.import_csv(str_path, Initialize=false));
end

function remove_full_tag(str_file)
    tab = readtable(str_file, "TextType", "string");
    writetable(removevars(tab, "FullTag"), str_file);
end

function [str_msg, id, str_path] = export_with_warning(net, str_path)
    % Run export_csv and return the last warning
    lastwarn("");
    str_path = DebugScript.helper.quiet(@() net.export_csv(str_path));
    [str_msg, id] = lastwarn(); id = DebugScript.helper.msg_id(str_msg, id);
    str_msg = string(str_msg);
    id      = string(id);
end

function [str_dir, c] = temp_folder()
    str_dir = tempname;
    mkdir(str_dir);
    c = onCleanup(@() rmdir(str_dir, "s"));
end
