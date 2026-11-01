% F16 CSV の書き出しと読み込みの確認
%
%   export_csv は書き出さなかった局所制御器と広域制御器を警告で示す (Issue #94)
%   組み込み系統の構築では警告を出さない
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
    [~, id] = lastwarn();
    assert(isempty(id), str_net + ": " + id)
end


function [str_msg, id, str_path] = export_with_warning(net, str_path)
    % Run export_csv and return the last warning
    lastwarn("");
    str_path = DebugScript.helper.quiet(@() net.export_csv(str_path));
    [str_msg, id] = lastwarn();
    str_msg = string(str_msg);
    id      = string(id);
end

function [str_dir, c] = temp_folder()
    str_dir = tempname;
    mkdir(str_dir);
    c = onCleanup(@() rmdir(str_dir, "s"));
end
