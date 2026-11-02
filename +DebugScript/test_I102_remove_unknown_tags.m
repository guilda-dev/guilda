% I102 存在しないタグの remove_branch / remove_component / replace_component
%
% エラー ID と文面を確認し、エラーのときは何も変わらないことを確認する。
%
% 実行: runtests("DebugScript.test_I102_remove_unknown_tags")  または  DebugScript.run_all("Features","I102")

%% remove_branch rejects an unknown tag
net = DebugScript.helper.build_9bus();
n_branch = numel(net.a_Branch);
[id, str_msg] = error_info(@() net.remove_branch("NoSuchTag"));
assert(id == "GUILDA:PowerNetwork:BranchNotFound")
assert(contains(str_msg, "NoSuchTag") && contains(str_msg, net.str_tag) && contains(str_msg, "string(net.a_Branch)"))
assert(numel(net.a_Branch) == n_branch)


%% remove_branch removes nothing when one of the tags is unknown
net = DebugScript.helper.build_9bus();
n_branch = numel(net.a_Branch);
br = net.a_Branch{1};
[id, str_msg] = error_info(@() net.remove_branch([string(br), "NoSuchA", "NoSuchB"]));
assert(id == "GUILDA:PowerNetwork:BranchNotFound")
assert(contains(str_msg, "NoSuchA") && contains(str_msg, "NoSuchB") && ~contains(str_msg, string(br)))
assert(numel(net.a_Branch) == n_branch && br.a_PowerNetwork == net)


%% remove_branch accepts several tags, as a row or a column
net = DebugScript.helper.build_9bus();
n_branch = numel(net.a_Branch);
net.remove_branch(string(net.a_Branch(1:2)));
net.remove_branch(reshape(string(net.a_Branch(1:2)), 1, []));
assert(numel(net.a_Branch) == n_branch-4)


%% remove_bus still removes the connected branches
net = DebugScript.helper.build_9bus();
net.remove_bus("B009", RemoveBranches=true);
assert(~ismember("B009", string(net.a_Bus)))


%% remove_component rejects an unknown tag
net = DebugScript.helper.build_9bus();
bus = net.a_Bus{5};
n_comp = numel(bus.a_Component);
[id, str_msg] = error_info(@() bus.remove_component("NoSuchTag"));
assert(id == "GUILDA:Bus:ComponentNotFound")
assert(contains(str_msg, "NoSuchTag") && contains(str_msg, bus.str_tag) && contains(str_msg, "string(bus.a_Component)"))
assert(numel(bus.a_Component) == n_comp)


%% replace_component rejects an unknown tag
net = DebugScript.helper.build_9bus();
bus = net.a_Bus{5};
comp = bus.a_Component{1};
[id, str_msg] = error_info(@() bus.replace_component("NoSuchTag", "load-power"));
assert(id == "GUILDA:Bus:ComponentNotFound")
assert(contains(str_msg, "NoSuchTag") && contains(str_msg, bus.str_tag))
assert(bus.a_Component{1} == comp)


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
