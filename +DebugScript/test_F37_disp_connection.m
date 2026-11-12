% F37 信号接続の表示 (PowerNetwork.disp_connection)
%
% net.disp_connection は net.get_variable_map の接続表 (4 番目の出力) をコマンドウィンドウに表示する。
% 入力の持ち主 (母線 → 機器 → 局所制御器 (深さ優先) → 大域制御器) ごとに、各入力とその入力元を並べる。
% 出力 0 個なら表示、1 個なら文字列を返す。オプション Kind は表示する接続の種類 (既定は "equilibrium" 以外)、
% Owner は表示する持ち主 (その持ち主が持つもの、またはその持ち主が入力元の入力を表示)。
% 未知の Owner は GUILDA:PowerNetwork:DispConnectionOwner、未知の Kind は arguments の検証で止まる。
%
% 実行: runtests("DebugScript.test_F37_disp_connection")  または  DebugScript.run_all("Features","F37")


%% It runs on Tutorial10bus and IEEE14bus with 0 and 1 outputs
for c_net = {@network.Tutorial10bus, @network.IEEE14bus}
    net = DebugScript.helper.quiet(c_net{1});
    s = net.disp_connection();
    assert(isstring(s) && isscalar(s) && contains(s, "Signal connections of " + net.s_tag), s)
    s_shown = evalc("net.disp_connection()");
    assert(contains(s_shown, "Signal connections of " + net.s_tag), s_shown)
    s_all = net.disp_connection(Kind=["local","global","observe","equilibrium"]);
    assert(strlength(s_all) > strlength(s))
end


%% Every target of the connection map is in the text
for c_net = {@network.Tutorial10bus, @network.IEEE14bus}
    net = DebugScript.helper.quiet(c_net{1});
    [tab, ~, ~, tc] = net.get_variable_map();
    for c_kind = {["local","global","observe"], "global", ["local","global","observe","equilibrium"]}
        sv_kind = c_kind{1};
        s = net.disp_connection(Kind=sv_kind);
        check_targets(net, s, tab, tc(ismember(tc.Kind, sv_kind), :));
    end
end


%% The default lists local, global and observe and counts the hidden equilibrium connections
net = DebugScript.helper.quiet(@network.Tutorial10bus);
[~, ~, ~, tc] = net.get_variable_map();
s = net.disp_connection();
assert(~contains(s, "[equilibrium]"), s)
assert(contains(s, "Not shown (option Kind): " + sum(tc.Kind == "equilibrium") + " equilibrium"), s)
% 和になる入力は ◀┳ で示し、出力と状態を区別する
assert(contains(s, "Pmech  ◀┳ output Pmech of B001SG1CG3"), s)
assert(contains(s, "┗ output Pmech of PowerNetworkAGC1  [global]"), s)
assert(contains(s, "delta ◀━ state delta of B003SG1  [observe]"), s)
assert(contains(s, "omega (B004SG1) ◀━ output omega of B004SG1  [observe]"), s)
% 入力のない持ち主 (空の母線 B006、入力が平衡値だけの B005) は出ない
assert(~contains(s, "B006") && ~contains(s, "B005"), s)
% タグの後に matlab:doc のリンク
assert(contains(s, "B001SG1CA1 <a href=""matlab:doc('controller.avr.AVR_DC1');"">@controller.avr.AVR_DC1</a>"), s)


%% Owner restricts the view
net = DebugScript.helper.quiet(@network.Tutorial10bus);
% 機器: その局所制御器を含み、その機器を観測する大域制御器の入力も出る
s = net.disp_connection(Owner="B003SG1");
assert(contains(s, "B003SG1CL1") && contains(s, "B003SG1CG2") && contains(s, "omega (B003SG1)"), s)
assert(~contains(s, "B001SG1") && ~contains(s, "omega (B001SG1)"), s)
% 和の入力は入力元をすべて示す
assert(contains(s, "┗ output Pmech of PowerNetworkAGC1  [global]"), s)
% 大域制御器: その入力と、その出力が入る入力
s = net.disp_connection(Owner="PowerNetworkAGC1", Kind="global");
assert(count(s, "output Pmech of PowerNetworkAGC1") == 4 && ~contains(s, "[local]") && ~contains(s, "[observe]"), s)
% 母線と複数の持ち主
s = net.disp_connection(Owner=["B002","B004SG1"]);
assert(contains(s, "B002SG1CG2") && contains(s, "B004SG1") && ~contains(s, "B003SG1"), s)
% 入れ子の局所制御器 (PSS) だけ
s = net.disp_connection(Owner="B001SG1CP2");
assert(contains(s, "Vpss ◀━ output Vpss of B001SG1CP2") && contains(s, "B001SG1CP2") && ~contains(s, "B001SG1CG3"), s)


%% An unknown Owner or Kind stops with a clear error
net = DebugScript.helper.quiet(@network.Tutorial10bus);
ME = caught(@() net.disp_connection(Owner=["B001SG1","B999"]));
assert(DebugScript.helper.msg_id(ME) == "GUILDA:PowerNetwork:DispConnectionOwner", DebugScript.helper.msg_id(ME))
assert(contains(ME.message, "B999") && ~contains(ME.message, "B001SG1,"), ME.message)
ME = caught(@() net.disp_connection(Kind="feedback"));
assert(contains(ME.message, "Kind") && contains(ME.message, "equilibrium"), ME.message)


function check_targets(net, s, tab, tc)
    % 接続表の各入力 (持ち主と名前) がそのブロックの行にあり、入力元の行数が接続の数と同じ
    sv_line = splitlines(s);
    sv_line = regexprep(sv_line, "<a href=[^>]*>|</a>", "");
    iv_target = unique(tc.TargetIndex);
    n_input = sum(contains(sv_line, "━━ ") & contains(sv_line, "◀"));   % 見出しの "input ◀ sources" は数えない
    assert(n_input == numel(iv_target), "入力の数 %d、◀ の行の数 %d", numel(iv_target), n_input)
    assert(sum(endsWith(sv_line, "]") & contains(sv_line, "  [")) == height(tc), "入力元の行の数")
    for i = reshape(iv_target, 1, [])
        s_owner = tab.Owner(i);
        i_owner = find(endsWith(sv_line, " " + s_owner + " @" + owner_class(net, s_owner)), 1);
        assert(~isempty(i_owner), "持ち主 %s がない", s_owner)
        % 持ち主の行より後で、同じかより浅い字下げの持ち主の行より前にある入力の行
        iv_col = strlength(sv_line) - strlength(regexprep(sv_line, "^[ ┃┣┗━]*", ""));
        lv_ownerline = contains(sv_line, " @");
        i_end = i_owner + find(lv_ownerline(i_owner+1:end) & iv_col(i_owner+1:end) <= iv_col(i_owner), 1);
        if isempty(i_end); i_end = numel(sv_line) + 1; end
        sv_block = sv_line(i_owner+1:i_end-1);
        s_name = tab.Name(i);
        assert(any(~cellfun(@isempty, regexp(cellstr(sv_block), "[┣┗]━━ " + s_name + "( \(\w+\))? *◀", "once"))), ...
               "入力 %s (%s) がない", tab.Label(i), s_owner)
    end
end

function s = owner_class(net, s_tag)
    % 持ち主のクラス名 (母線、機器、制御器)
    c = [net.a_Bus; net.a_GlobalController];
    k = 0;
    while k < numel(c)
        k = k + 1;
        if string(c{k}.s_tag) == s_tag
            s = string(class(c{k}));
            return
        end
        if isa(c{k}, "Bus")
            c = [c; c{k}.a_Component]; %#ok<AGROW>
        elseif isprop(c{k}, "a_LocalController")
            c = [c; c{k}.a_LocalController]; %#ok<AGROW>
        end
    end
    error("no owner %s", s_tag)
end

function ME = caught(fcn)
    ME = [];
    try
        DebugScript.helper.quiet(fcn);
    catch ME
    end
    assert(~isempty(ME), "エラーにならない")
end
