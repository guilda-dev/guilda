% F41 ブランチの状態 (get_admittance_matrix の Status と Point、回線数)
%
%   Y = br.get_admittance_matrix(Status="3LG", Point=0.3);
%   tab_Y = net.get_admittance_matrix(BranchStatus=table(Target, Status, Point));
%
% 状態は "close"(既定), "3LG", "6LG", "3open", "6open"。R, X, C は全回線の値で、1 回線は
% Y_close/n。"close" は今の式と完全に一致し、"3open" = Y_close(n-1)/n、"6open" = 0。
% 地絡は 1 回線を Point で 2 つの区間 (元のクラスと同じ形) に分けた 3 節点の回路を、故障点を
% 接地して縮約した行列 G1 で、"3LG" = 3open + G1、"6LG" = n G1。変圧器は理想変圧器を送電端に
% 置き、Point はその先の直列部分の位置。Point は故障の状態だけが使い、他の状態は無視する。
% 系統の行列は故障の行と並列の行を合成する (notes/branch-status-events.md §2.5)。
%
% 実行: runtests("DebugScript.test_F41_branch_status")  または  DebugScript.run_all("Features","F41")

% 共通設定 (各テストの前に毎回実行される)
sv_key = ["pi", "T", "pi_transformer", "two_winding_transformer"];
R = 0.012; X = 0.11; C = 0.09;


%% close is the current formula for every class, circuit count and tap
for s_key = sv_key
    for n = 1:3
        for rv_tp = [1, 0; 0.97, 0.1]'
            br = one_branch(s_key, R, X, C, rv_tp(1), rv_tp(2), n);
            Y  = br.get_admittance_matrix();
            s_case = s_key + " n=" + n + " tap=" + rv_tp(1);
            assert(isequal(Y, current_formula(s_key, R, X, C, rv_tp(1), rv_tp(2))), s_case)
            assert(isequal(br.get_admittance_matrix(Status="close"), Y), s_case)
        end
    end
end


%% Open states and an ignored Point
for s_key = sv_key
    for n = 1:3
        br = one_branch(s_key, R, X, C, 0.97, 0.1, n);
        Y  = br.get_admittance_matrix();
        s_case = s_key + " n=" + n;
        assert(isequal(br.get_admittance_matrix(Status="6open"), zeros(2)), s_case)
        % Point は故障の状態だけが使う: 他の状態ではエラーにも警告にもならない
        lastwarn("");
        assert(isequal(br.get_admittance_matrix(Status="close", Point=0.3), Y), s_case)
        assert(isequal(br.get_admittance_matrix(Status="6open", Point=1.5), zeros(2)), s_case)
        if n >= 2
            assert(isequal(br.get_admittance_matrix(Status="3open"), Y*(n-1)/n), s_case)
            assert(isequal(br.get_admittance_matrix(Status="3open", Point=0), Y*(n-1)/n), s_case)
        end
        assert(isempty(lastwarn()), s_case)
    end
end
br = one_branch("pi", R, X, C, 1, 0, 2);
assert(isequal(br.get_admittance_matrix(Status="3open"), br.get_admittance_matrix()/2), "2 回線の半分は誤差なし")


%% Faults match the reduction of the three-node circuit
for s_key = sv_key
    for n = 1:3
        for rv_tp = [1, 0; 0.97, 0.1]'
            br = one_branch(s_key, R, X, C, rv_tp(1), rv_tp(2), n);
            for p = [0.01, 0.3, 0.5, 0.99]
                s_case = s_key + " n=" + n + " tap=" + rv_tp(1) + " p=" + p;
                G1  = faulted_circuit(s_key, R, X, C, rv_tp(1), rv_tp(2), n, p);
                Y6  = br.get_admittance_matrix(Status="6LG", Point=p);
                assert(rel_err(Y6, n*G1) < 1e-9, s_case + ": 6LG = n G1, " + rel_err(Y6, n*G1))
                assert(isdiag(Y6), s_case)
                if n >= 2
                    Y3  = br.get_admittance_matrix(Status="3LG", Point=p);
                    Y3o = br.get_admittance_matrix(Status="3open");
                    assert(rel_err(Y3 - Y3o, G1) < 1e-9, s_case + ": 3LG - 3open = G1, " + rel_err(Y3 - Y3o, G1))
                end
            end
        end
    end
end

% pi と T の 6LG は p と 1-p の入れ替えで対角が入れ替わる
for s_key = ["pi", "T"]
    br = one_branch(s_key, R, X, C, 1, 0, 2);
    Ya = br.get_admittance_matrix(Status="6LG", Point=0.3);
    Yb = br.get_admittance_matrix(Status="6LG", Point=0.7);
    assert(rel_err(Ya, rot90(Yb, 2)) < 1e-12, s_key)
end

% 端に近い地絡はその端のアドミタンスが大きい (母線の地絡に近づく)
br = one_branch("pi", R, X, C, 1, 0, 2);
Ye = br.get_admittance_matrix(Status="6LG", Point=1e-6);
assert(abs(Ye(1,1)) > 1e5 * abs(Ye(2,2)))


%% Errors: Point outside (0,1) and one circuit
for s_key = sv_key
    br = one_branch(s_key, R, X, C, 1, 0, 2);
    for s_st = ["3LG", "6LG"]
        for p = [0, 1, NaN, 1.2, -0.1]
            assert(error_id(@() br.get_admittance_matrix(Status=s_st, Point=p)) == "GUILDA:Branch:InvalidPoint", s_key + " " + s_st + " " + p)
        end
        assert(error_id(@() br.get_admittance_matrix(Status=s_st)) == "GUILDA:Branch:InvalidPoint", "Point なし")
    end
    br1 = one_branch(s_key, R, X, C, 1, 0, 1);
    assert(error_id(@() br1.get_admittance_matrix(Status="3LG", Point=0.5)) == "GUILDA:Branch:SingleCircuit", s_key)
    assert(error_id(@() br1.get_admittance_matrix(Status="3open")) == "GUILDA:Branch:SingleCircuit", s_key)
    assert(all(isfinite(br1.get_admittance_matrix(Status="6LG", Point=0.5)), "all"), "1 回線でも 6LG は使える")
    assert(isequal(br1.get_admittance_matrix(Status="6open"), zeros(2)))
end
ME = caught(@() br.get_admittance_matrix(Status="3LG", Point=0));
assert(contains(ME.message, "add_fault"), "端の故障は母線の故障で与える")
assert(error_id(@() br.get_admittance_matrix(Status="BG")) ~= "", "未知の状態")


%% add_branch sets the circuit count
net = PowerNetwork();
net.add_bus(); net.add_bus();
br2 = net.add_branch("pi", [1, 2], X=0.1);
br3 = net.add_branch("pi", [1, 2], X=0.1, Circuit=3);
assert(br2.tab_parameter.dynamics.circuit == 2 && br3.tab_parameter.dynamics.circuit == 3)
assert(isequal(br2.get_admittance_matrix(), br3.get_admittance_matrix()), "close は回線数によらない")
assert(error_id(@() net.add_branch("pi", [1, 2], X=0.1, Circuit=1.5)) ~= "")
assert(error_id(@() net.add_branch("pi", [1, 2], X=0.1, Circuit=0)) ~= "")


%% The network matrix without states is the current matrix
net = DebugScript.helper.build_ieee14();
tab_Y = net.get_admittance_matrix();
tab_empty = table(strings(0,1), strings(0,1), zeros(0,1), VariableNames=["Target","Status","Point"]);
assert(isequaln(net.get_admittance_matrix(BranchStatus=tab_empty), tab_Y))
assert(isequal(tab_Y.Variables, manual_sum(net)), "ブランチの和と母線のシャント")
tab_closed = state_table(["EL001";"EL002"], ["close";"none"], [NaN; NaN]);
assert(isequal(net.get_admittance_matrix(BranchStatus=tab_closed).Variables, tab_Y.Variables))


%% 6open on the network removes the branch
net = DebugScript.helper.build_ieee14();
s_br = string(net.a_Branch{3});
Y_open = net.get_admittance_matrix(BranchStatus=state_table(s_br, "6open", NaN)).Variables;
net.remove_branch(s_br);
Y_removed = net.get_admittance_matrix().Variables;
assert(rel_err(Y_open, Y_removed) < 1e-14, "" + rel_err(Y_open, Y_removed))


%% The fault and parallel rows of a branch combine by the table
net = DebugScript.helper.build_ieee14();
Y_full = net.get_admittance_matrix().Variables;
sv_Bus = string(net.a_Bus);
for k = [1, find(cellfun(@(b) b.key, net.a_Branch) == "two_winding_transformer", 1)]
    br = net.a_Branch{k};
    br.tab_parameter.dynamics.circuit = 3;
    n  = 3;
    [~, iv] = ismember(string(br.a_Bus), sv_Bus);   % ブランチの順 (from, to)
    p  = 0.3;
    Yst = @(s, varargin) br.get_admittance_matrix("Status", s, varargin{:});
    sct_expect = struct( ...
        "none_close", Yst("close"),  "none_3open", Yst("3open"), "none_6open", zeros(2), ...
        "x3LG_close", Yst("3LG", "Point", p), "x3LG_3open", Yst("3open"), "x3LG_6open", zeros(2), ...
        "x6LG_close", Yst("6LG", "Point", p), "x6LG_3open", (n-1)/n*Yst("6LG", "Point", p), "x6LG_6open", zeros(2));
    for s_fault = ["none", "3LG", "6LG"]
        for s_par = ["close", "3open", "6open"]
            s_name = matlab.lang.makeValidName(s_fault + "_" + s_par, Prefix="x");
            Yb = sct_expect.(s_name);
            Y_expect = Y_full;
            Y_expect(iv, iv) = Y_expect(iv, iv) - Yst("close") + Yb;
            % 行の順序は問わない (並列を先に書く)
            tab = state_table(string(br) + ["";""], [s_par; s_fault], [NaN; p]);
            Y = net.get_admittance_matrix(BranchStatus=tab).Variables;
            assert(rel_err(Y, Y_expect) < 1e-12, br.key + " " + s_fault + "," + s_par + ": " + rel_err(Y, Y_expect))
        end
    end
end

% (6LG, 3open) は n = 2 なら 1 回線の地絡 G1 だけ
br = net.a_Branch{1};
br.tab_parameter.dynamics.circuit = 2;
tab = state_table(string(br) + ["";""], ["6LG"; "3open"], [0.4; NaN]);
Y = net.get_admittance_matrix(BranchStatus=tab).Variables;
Y_full = net.get_admittance_matrix().Variables;
[~, iv] = ismember(string(br.a_Bus), string(net.a_Bus));
Yb = Y(iv, iv) - (Y_full(iv, iv) - br.get_admittance_matrix());
assert(rel_err(Yb, br.get_admittance_matrix(Status="6LG", Point=0.4)/2) < 1e-12)


%% Rows of an event table can be passed as they are
net = DebugScript.helper.build_ieee14();
tab_event = table(["Fault001"; "Parallel001"], ["EL001"; "EL002"], [1; 1.1], ["3LG"; "3open"], [0.3; NaN], ...
    VariableNames=["Tag","Target","Time","Status","Point"]);
Y = net.get_admittance_matrix(BranchStatus=tab_event).Variables;
tab = state_table(["EL001"; "EL002"], ["3LG"; "3open"], [0.3; NaN]);
assert(isequal(Y, net.get_admittance_matrix(BranchStatus=tab).Variables))
tab_cell = table({'EL001'}, categorical("6LG"), 0.5, VariableNames=["Target","Status","Point"]);
assert(isequal(net.get_admittance_matrix(BranchStatus=tab_cell).Variables, ...
    net.get_admittance_matrix(BranchStatus=state_table("EL001", "6LG", 0.5)).Variables), "cellstr と categorical")


%% A wrong state table stops with InvalidBranchStatus
net = DebugScript.helper.build_ieee14();
s_id = "GUILDA:PowerNetwork:InvalidBranchStatus";
s_bus = string(net.a_Bus{1});
assert(error_id(@() net.get_admittance_matrix(BranchStatus=state_table(s_bus, "6open", NaN))) == s_id, "母線のタグ")
assert(error_id(@() net.get_admittance_matrix(BranchStatus=state_table("EL001", "BG", NaN))) == s_id, "BG")
assert(error_id(@() net.get_admittance_matrix(BranchStatus=state_table("EL001", "open", NaN))) == s_id, "open")
assert(error_id(@() net.get_admittance_matrix(BranchStatus=state_table(["EL001";"EL001"], ["3LG";"6LG"], [0.3;0.3]))) == s_id, "故障の行が 2 つ")
assert(error_id(@() net.get_admittance_matrix(BranchStatus=state_table(["EL001";"EL001"], ["3open";"close"], [NaN;NaN]))) == s_id, "並列の行が 2 つ")
assert(error_id(@() net.get_admittance_matrix(BranchStatus=table("EL001", "6open", VariableNames=["Target","Status"]))) == s_id, "Point の列がない")
ME = caught(@() net.get_admittance_matrix(BranchStatus=state_table(s_bus, "6open", NaN)));
assert(contains(ME.message, s_bus), ME.message)
% ブランチの検査はブランチの ID のまま
assert(error_id(@() net.get_admittance_matrix(BranchStatus=state_table("EL001", "3LG", 1)))   == "GUILDA:Branch:InvalidPoint")
net.a_Branch{1}.tab_parameter.dynamics.circuit = 1;
assert(error_id(@() net.get_admittance_matrix(BranchStatus=state_table("EL001", "3open", NaN))) == "GUILDA:Branch:SingleCircuit")
assert(error_id(@() net.get_admittance_matrix(BranchStatus=state_table(["EL001";"EL001"], ["6LG";"3open"], [0.5;NaN]))) == "GUILDA:Branch:SingleCircuit")


function br = one_branch(s_key, R, X, C, tap, phase, n)
    net = PowerNetwork();
    net.add_bus(); net.add_bus();
    br = net.add_branch(s_key, [1, 2], R=R, X=X, C=C, Tap=tap, Phase=phase, Circuit=n);
end

function Y = current_formula(s_key, R, X, C, tap, phase)
    % 状態を加える前の get_admittance_matrix の式 (写し)
    yij = 1/(R+1j*X);
    cij = 1j*C;
    switch s_key
        case "pi"
            Y = [cij+yij, -yij; -yij, cij+yij];
        case "T"
            Ya = 2*yij;
            b  = cij;
            Y  = [Ya*(Ya+b), -Ya^2; -Ya^2, (Ya+b)*Ya]/(Ya+b+Ya);
        case "pi_transformer"
            r = tap*exp(1j*phase);
            Y = [(cij+yij)/tap^2, -yij/conj(r); -yij/r, cij+yij];
        case "two_winding_transformer"
            ym = [cij+yij/tap^2, -yij/tap; -yij/tap, yij];
            Y  = ym*blkdiag(1, exp(1j*phase));
    end
end

function G1 = faulted_circuit(s_key, R, X, C, tap, phase, n, p)
    % 1 回線 (n R, n X, C/n) を Point で 2 区間に分け、故障点を 1e12 で接地して縮約した 2x2 行列
    z1 = n*(R+1j*X);   % 1 回線の直列インピーダンス
    b1 = 1j*C/n;       % 1 回線のシャント
    rv_l = [p, 1-p];
    switch s_key
        case {"pi", "pi_transformer"}
            % 節点 S, F, R。区間 l は直列 l z1、両端にシャント l b1 (pi の C は各端の値)
            Y3 = zeros(3);
            for k = 1:2
                iv = [k, k+1];
                ys = 1/(rv_l(k)*z1);
                Y3(iv, iv) = Y3(iv, iv) + [ys + rv_l(k)*b1, -ys; -ys, ys + rv_l(k)*b1];
            end
            Yr = reduce(Y3, [1, 3], 2);
            if s_key == "pi_transformer"
                D  = diag([1/(tap*exp(1j*phase)), 1]);
                Yr = D'*Yr*D;
            end
        case "T"
            % 節点 S, M1, F, M2, R。区間 l は直列 l z1/2 ずつ、中点にシャント l b1
            Y5 = zeros(5);
            for k = 1:2
                ys = 2/(rv_l(k)*z1);
                i0 = 2*k - 1;   % 区間の始点 (1 または 3)
                for iv = [i0, i0+1; i0+1, i0+2]'
                    Y5(iv, iv) = Y5(iv, iv) + [ys, -ys; -ys, ys];
                end
                Y5(i0+1, i0+1) = Y5(i0+1, i0+1) + rv_l(k)*b1;
            end
            Y5(3,3) = Y5(3,3) + 1e12;
            Yr = reduce(Y5, [1, 5], [2, 3, 4]);
        case "two_winding_transformer"
            % 直列だけの線路 (シャントなし) を縮約し、送電端の母線側のシャントとタップを付ける
            Y3 = zeros(3);
            for k = 1:2
                iv = [k, k+1];
                ys = 1/(rv_l(k)*z1);
                Y3(iv, iv) = Y3(iv, iv) + [ys, -ys; -ys, ys];
            end
            Yr = reduce(Y3, [1, 3], 2);
            Dt = diag([1/tap, 1]);
            Yr = (diag([b1, 0]) + Dt*Yr*Dt)*blkdiag(1, exp(1j*phase));
    end
    G1 = Yr;
end

function Yr = reduce(Y, iv_keep, iv_elim)
    % 故障点の縮約 (pi と変圧器は故障点 F を 1e12 で接地)
    if numel(iv_elim) == 1
        Y(iv_elim, iv_elim) = Y(iv_elim, iv_elim) + 1e12;
    end
    Yr = Y(iv_keep, iv_keep) - Y(iv_keep, iv_elim)/Y(iv_elim, iv_elim)*Y(iv_elim, iv_keep);
end

function e = rel_err(A, B)
    e = norm(A - B, 1)/max(norm(B, 1), eps);
end

function Y = manual_sum(net)
    sv_Bus = string(net.a_Bus);
    Y = zeros(numel(sv_Bus));
    for i = 1:numel(net.a_Branch)
        br = net.a_Branch{i};
        iv = arrayfun(@(b) find(sv_Bus == string(b{1})), br.a_Bus);
        Y(iv, iv) = Y(iv, iv) + br.get_admittance_matrix();
    end
    Y = Y + diag(cellfun(@(b) b.tab_parameter.dynamics.Gshunt + 1j*b.tab_parameter.dynamics.Bshunt, net.a_Bus));
end

function tab = state_table(sv_target, sv_status, rv_point)
    tab = table(string(sv_target(:)), string(sv_status(:)), rv_point(:), VariableNames=["Target","Status","Point"]);
end

function id = error_id(f)
    id = "";
    try
        DebugScript.helper.quiet(f);
    catch me
        id = string(DebugScript.helper.msg_id(me));
        if id == ""
            id = "(no id) " + me.message;
        end
    end
end

function ME = caught(f)
    ME = [];
    try
        DebugScript.helper.quiet(f);
    catch ME
    end
    assert(~isempty(ME), "エラーにならない")
end
