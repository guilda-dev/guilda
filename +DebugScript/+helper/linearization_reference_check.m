function tab = linearization_reference_check(sv_case)
% 線形モデルを基準値 (linearization_reference.mat) と比べ、差の最大値を表で返す (Issue #121)
%
%   tab = DebugScript.helper.linearization_reference_check()
%   tab = DebugScript.helper.linearization_reference_check(["IEEE9bus","Ishizaki6Bus+GC"])
%
% 基準値は接続器 SolverLIN に置き換える前のコードで求めたもの
% (+DebugScript/archive/make_linearization_reference.m)。同じ系統・同じ点で、網 (rm_*、
% ODE、DAE)、機器 (LC 付き V2I、機器単体)、母線 (V2I)、LC、GC のモデルを求め、状態・
% 入力・出力を名前で対応させて比べる。基準値にある電流を入力とするポートのモデルは使わない
% (ポートは V2I だけ)。名前の変化 (機器と LC の電圧の入力は母線の Label、GC の入出力は
% uc・yc の Label) は対応表で吸収する。
% 列: Case, Point ("eq" | "shift"), Part, Diff (相対差の最大値: |新 - 旧| / max(1, |旧| の最大))
    arguments (Input)
        sv_case (1,:) string = string.empty(1,0)   % 比べる系統 (既定: すべて)
    end
    arguments (Output)
        tab table   % 比べた部分ごとの相対差の最大値
    end
    S = load(fullfile(fileparts(mfilename("fullpath")), "linearization_reference.mat"), "ref");
    ref = S.ref;
    if ~isempty(sv_case)
        ref = ref(ismember([ref.name], sv_case));
    end
    rows = cell(0,4);
    s_built = "";
    for e = ref
        if e.name ~= s_built
            net = build(e.name);
            s_built = e.name;
        end
        s_pt = "shift";
        if e.net.l_eq
            s_pt = "eq";
        end
        add = @(s_part, d) cell2table({e.name, s_pt, s_part, d}, VariableNames=["Case","Point","Part","Diff"]);
        if e.net.l_eq
            r = net.get_sys(Format="GUILDAorigin");
        else
            r = net.get_sys(e.point, Format="GUILDAorigin");
        end
        tab_v = r.tab_variable;
        assert(isequal(tab_v.Label(tab_v.Kind == "x"), e.net.sv_x) && isequal(tab_v.Label(tab_v.Kind == "u"), e.net.sv_u), ...
               "変数表の並びが基準値と違う: %s", e.name)
        d = 0;
        for s = ["Axx","Axv","Bx","Avx","Avv","Bv","E"]
            d = max(d, rdiff(r.("rm_" + s), e.net.(s)));
        end
        rows(end+1,:) = {e.name, s_pt, "net rm_*", d}; %#ok<AGROW>
        d = max(rdiff(r.rv_point, e.point), 0);
        rows(end+1,:) = {e.name, s_pt, "net point", d}; %#ok<AGROW>
        K = r.get_ss("ODE", Format="struct");
        if isfield(e.kron, "A")
            rows(end+1,:) = {e.name, s_pt, "net ODE", model_diff(K, e.kron, false)}; %#ok<AGROW>
        end
        ev = eig(K.A, K.E);
        ev = ev(isfinite(ev));
        rows(end+1,:) = {e.name, s_pt, "net ODE eig", eig_diff(ev, e.kron.eig)}; %#ok<AGROW>
        D = r.get_ss("DAE", Coordinate="theta&rho", Format="struct");
        rows(end+1,:) = {e.name, s_pt, "net DAE", model_diff(D, e.dae, true)}; %#ok<AGROW>

        % モデルオブジェクト
        [~, c_idxBus] = net.get_variable_map();
        p = r.rv_point;
        n_lin = numel(p);
        dc = 0;  dcA = 0;  db = 0;  dl = 0;  dg = 0;
        q = 0;
        for i = 1:numel(net.a_Bus)
            bus = net.a_Bus{i};
            pb = p(c_idxBus{i}(c_idxBus{i} <= n_lin));
            sb = e.bus{i};
            c_pt = {[]};
            if ~e.net.l_eq
                c_pt = {pb};
            end
            db = max(db, model_diff(bus.get_sys(c_pt{:}, Format="struct"), sb.V2I, false));
            [~, c_idx] = bus.get_variable_map();
            for j = 1:numel(bus.a_Component)
                comp = bus.a_Component{j};
                q = q + 1;
                sc = e.comp{q};
                assert(sc.tag == string(comp.s_tag))
                pc = pb(c_idx{j}(c_idx{j} <= numel(pb)));
                c_pt = {[]};
                if ~e.net.l_eq
                    c_pt = {pc};
                end
                f_ren = @(N) rename_v(N, bus, comp);
                dc  = max(dc, model_diff(f_ren(comp.get_sys(c_pt{:}, Format="struct")), sc.V2I, false));
                if e.net.l_eq
                    dcA = max(dcA, model_diff(f_ren(alone(comp)), sc.alone, false));
                end
            end
        end
        rows = [rows; {e.name, s_pt, "bus V2I", db}; {e.name, s_pt, "comp V2I", dc}]; %#ok<AGROW>
        if e.net.l_eq
            rows(end+1,:) = {e.name, s_pt, "comp alone", dcA}; %#ok<AGROW>
            for q = 1:numel(e.lc)
                [lc, bus] = find_lc(net, e.lc{q}.tag);
                dl = max(dl, model_diff(rename_v(lc.get_sys(Format="struct"), bus, lc), e.lc{q}.sys, false));
            end
            rows(end+1,:) = {e.name, s_pt, "LC", dl}; %#ok<AGROW>
            for k = 1:numel(e.gc)
                dg = max(dg, gc_diff(net.a_GlobalController{k}.get_sys(Format="struct"), e.gc{k}.sys));
            end
            if ~isempty(e.gc)
                rows(end+1,:) = {e.name, s_pt, "GC", dg}; %#ok<AGROW>
            end
        end
    end
    tab = cell2table(rows, VariableNames=["Case","Point","Part","Diff"]);
end


function net = build(s_case)
% 基準値と同じ系統 (make_linearization_reference の build)
    l_gc = endsWith(s_case, "+GC");
    net = DebugScript.helper.quiet(@() network.(erase(s_case, "+GC"))());
    if l_gc
        g = net.a_Bus{1}.a_Component{1};
        if isempty(g.a_LocalController)
            g.add_local_controller("avr-ST1");
        end
        g.add_local_controller("pss-PSS1");
        cc = {};
        for i = 1:numel(net.a_Bus)
            for j = 1:numel(net.a_Bus{i}.a_Component)
                c = net.a_Bus{i}.a_Component{j};
                if any(c.sv_u == "Pmech")
                    cc{end+1} = c; %#ok<AGROW>
                end
            end
        end
        DebugScript.helper.quiet(@() net.add_global_controller("agc-PI", cc(1:2), parameter=struct(alpha=[1;1], beta=[1;1])));
    end
    DebugScript.helper.quiet(@() net.initialize());
end


function S = alone(comp)
% 機器単体のモデル (旧: get_sys(Controllers=false)、新: get_linear_block)
    try
        S = comp.get_linear_block(comp.rv_Xequilibrium(:), [real(comp.c_Vequilibrium); imag(comp.c_Vequilibrium)], comp.rv_Uequilibrium(:));
        S.OutputName = S.OutputName(1:2);       % 単体の旧モデルの出力は電流だけ
        S.C = S.C(1:2,:);
        S.D = S.D(1:2,:);
    catch
        S = comp.get_sys(Controllers=false, Format="struct");
    end
end


function N = rename_v(N, bus, owner)
% 電圧の名前: 新しいモデルの母線の Label を、旧モデルの所有者のタグ付きの名前にする
    sv_new = reshape(string(bus.attach_tag(["Vre";"Vim"])), [], 1);
    sv_old = reshape(string(owner.attach_tag(["Vre";"Vim"])), [], 1);
    for s = ["InputName","OutputName"]
        [lv, iv] = ismember(N.(s), sv_new);
        N.(s)(lv) = sv_old(iv(lv));
    end
end


function d = model_diff(N, O, l_order)
% 名前で対応させた差 (l_order: 状態・入力・出力の並びも同じであること)
    [d, iv_x, iv_u, iv_y] = deal(Inf, [], [], []);
    sv_xN = string(N.StateName);  sv_uN = string(N.InputName);  sv_yN = string(N.OutputName);
    sv_xO = string(O.StateName);  sv_uO = string(O.InputName);  sv_yO = string(O.OutputName);
    if numel(sv_xN) ~= numel(sv_xO) || numel(sv_uN) ~= numel(sv_uO) || numel(sv_yN) ~= numel(sv_yO)
        return
    end
    if l_order || all(sv_yO == "")
        if ~isequal(sv_xN, sv_xO) || ~isequal(sv_uN, sv_uO) || ~isequal(sv_yN, sv_yO)
            return
        end
        iv_x = 1:numel(sv_xN);  iv_u = 1:numel(sv_uN);  iv_y = 1:numel(sv_yN);
    else
        [lx, iv_x] = ismember(sv_xO, sv_xN);
        [lu, iv_u] = ismember(sv_uO, sv_uN);
        [ly, iv_y] = ismember(sv_yO, sv_yN);
        if ~all(lx) || ~all(lu) || ~all(ly)
            return
        end
    end
    d = max([rdiff(N.A(iv_x,iv_x), O.A), rdiff(N.B(iv_x,iv_u), O.B), rdiff(N.C(iv_y,iv_x), O.C), ...
             rdiff(N.D(iv_y,iv_u), O.D), rdiff(N.E(iv_x,iv_x), O.E), 0]);
end


function d = gc_diff(N, O)
% GC: 旧の入力の列は電圧と InputSlot (uc の Label)、出力の行は OutputSlot (yc の Label)
    if isequal(string(N.InputName), string(O.InputName)) && isequal(string(N.OutputName), string(O.OutputName))
        d = model_diff(N, O, true);     % 旧と同じ名前 (置き換える前のコード)
        return
    end
    sv_u = [string(O.InputName(1:end-numel(O.InputSlot))); O.InputSlot];
    O.InputName = sv_u;
    [lu, iv_u] = ismember(sv_u, string(N.InputName));
    [ly, iv_y] = ismember(O.OutputSlot, string(N.OutputName));
    [lx, iv_x] = ismember(string(O.StateName), string(N.StateName));
    if ~all(lu) || ~all(ly) || ~all(lx) || numel(N.InputName) ~= numel(sv_u)
        d = Inf;
        return
    end
    d = max([rdiff(N.A(iv_x,iv_x), O.A), rdiff(N.B(iv_x,iv_u), O.B), rdiff(N.C(iv_y,iv_x), O.C), ...
             rdiff(N.D(iv_y,iv_u), O.D), rdiff(N.E(iv_x,iv_x), O.E), 0]);
end


function d = rdiff(M, R)
    M = full(M);  R = full(R);
    if ~isequal(size(M), size(R))
        d = Inf;
        return
    end
    if isempty(R)
        d = 0;
        return
    end
    d = max(abs(M(:) - R(:))) / max(1, max(abs(R(:))));
end


function d = eig_diff(e1, e2)
    if numel(e1) ~= numel(e2)
        d = Inf;
        return
    end
    d = 0;
    for k = 1:numel(e1)
        d = max(d, min(abs(e2 - e1(k))) / max(1, abs(e1(k))));
    end
    for k = 1:numel(e2)
        d = max(d, min(abs(e1 - e2(k))) / max(1, abs(e2(k))));
    end
end


function [lc, bus] = find_lc(net, s_tag)
    for i = 1:numel(net.a_Bus)
        for j = 1:numel(net.a_Bus{i}.a_Component)
            list = all_controllers(net.a_Bus{i}.a_Component{j});
            for k = 1:numel(list)
                if string(list{k}.s_tag) == s_tag
                    lc = list{k};
                    bus = net.a_Bus{i};
                    return
                end
            end
        end
    end
    error("DebugScript:NoController", "LC %s がない", s_tag)
end

function list = all_controllers(parent)
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end
