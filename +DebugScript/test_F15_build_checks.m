% F15 ネットワーク構築時の検査 (add_branch の母線の指定とインピーダンス)
%
% 範囲外の母線番号、不明なタグ、自己ループ、R=X=0 が修正方法を示す GUILDA のエラーになり、
% ネットワークが変わらないことを確認する。組み込みの系統が誤検知なしで構築できることも確認する。
%
% 実行: runtests("DebugScript.test_F15_build_checks")  または  DebugScript.run_all("Features","F15")

%% A bus index is rejected when no buses exist yet
net = PowerNetwork("T");
[id, str_msg] = error_info(@() net.add_branch("pi", [1,2], X=0.1));
assert(id == "GUILDA:PowerNetwork:BranchBusIndex", id)
assert(contains(str_msg, "[1 2]") && contains(str_msg, "has 0 buses") && contains(str_msg, "net.add_bus()"), str_msg)
assert(isempty(net.a_Branch))


%% Bus indices that are not in the network are rejected
net = build_two_buses();
for from_to = {[1,3], [0,1], [-1,2], [1.5,2], [NaN,1], [1,Inf]}
    [id, str_msg] = error_info(@() net.add_branch("pi", from_to{1}, X=0.1));
    assert(id == "GUILDA:PowerNetwork:BranchBusIndex", id)
    assert(contains(str_msg, mat2str(from_to{1})) && contains(str_msg, "has 2 buses"), str_msg)
end
assert(isempty(net.a_Branch))


%% An unknown bus tag is rejected and the message names it
net = build_two_buses();
for from_to = {["B001","B099"], ["B099","B001"]}
    [id, str_msg] = error_info(@() net.add_branch("pi", from_to{1}, X=0.1));
    assert(id == "GUILDA:PowerNetwork:BusNotFound", id)
    assert(contains(str_msg, "B099"), str_msg)
end
assert(isempty(net.a_Branch))


%% A self loop is rejected by index and by tag, and the message points to the shunt
net = build_two_buses();
for from_to = {[1,1], ["B001","B001"]}
    [id, str_msg] = error_info(@() net.add_branch("pi", from_to{1}, X=0.1));
    assert(id == "GUILDA:PowerNetwork:BranchSelfLoop", id)
    assert(contains(str_msg, "B001") && contains(str_msg, "Bshunt"), str_msg)
end
assert(isempty(net.a_Branch))


%% R = X = 0 is rejected for every branch model
net = build_two_buses();
for str_type = ["pi","T","pi_transformer","two_winding_transformer"]
    [id, str_msg] = error_info(@() net.add_branch(str_type, [1,2], R=0, X=0));
    assert(id == "GUILDA:PowerNetwork:BranchZeroImpedance", id)
    assert(contains(str_msg, "B001") && contains(str_msg, "B002") && contains(str_msg, "nonzero"), str_msg)
end
assert(isempty(net.a_Branch))


%% Valid branches are still accepted, also with only R or only X
net = build_two_buses();
net.add_branch("pi", [1,2], R=0, X=0.1);
net.add_branch("pi", [2,1], R=0.1, X=0);
net.add_branch("pi", ["B001","B002"], X=0.1);
net.add_branch("pi", ["B002","B001"]);
assert(numel(net.a_Branch) == 4)


%% All built-in networks still build
for str_net = ["IEEE9bus","IEEE14bus","IEEE14bus_NoTap","IEEE14bus_lossless", ...
               "IEEE68bus","Ishizaki6Bus","TEST31bus","Txt3Bus","Tutorial3bus"]
    net = DebugScript.helper.quiet(@() feval("network."+str_net));
    assert(~isempty(net.a_Branch), str_net)
end


function net = build_two_buses()
    net = PowerNetwork("T");
    net.add_bus();
    net.add_bus();
end

function [id, str_msg] = error_info(fh)
% 実行してエラー ID と文面を返す (エラーにならなければ "")
    id = "";
    str_msg = "";
    try
        DebugScript.helper.quiet(fh);
    catch ME
        id = string(DebugScript.helper.msg_id(ME));
        str_msg = string(ME.message);
    end
end
