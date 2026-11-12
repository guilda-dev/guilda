function make_linearization_reference(s_file)
% 線形化の基準値 (+DebugScript/+helper/linearization_reference.mat) を作る (Issue #121)
%
% 接続器 SolverLIN と共通の get_sys に置き換える前のコード (基準 de2a93f5) で実行した
% 結果を保存したもの。置き換えた後のコードでは動かない (旧 API を使う) ため、作り方の
% 記録として archive に置く。比べるテストは test_F7_linearization の
% "Linear models match the reference values"。
%
% 保存するもの (系統ごと、平衡点とずらした点):
%   - 網: rm_* (疎行列)、x・v・u の Label、点、Kron (状態 150 以下はモデル、すべて固有値) と
%     DAE (Coordinate "theta&rho") のモデル
%   - 機器 (LC 付き、V2I と I2V)、機器単体、母線 (V2I と I2V)、LC、GC のモデル (struct)
% ずらした点は状態に 0.01*randn*max(1,|x|) を足したもの (rng(1))。
    arguments
        s_file (1,1) string = fullfile(fileparts(fileparts(mfilename("fullpath"))), "+helper", "linearization_reference.mat")
    end
    sv_net = ["IEEE14bus","IEEE14bus_NoTap","IEEE14bus_lossless","IEEE39Bus","IEEE68bus","IEEE9bus", ...
              "IEEJ_EAST10","IEEJ_EAST30","IEEJ_WEST10","IEEJ_WEST30","Ishizaki6Bus","TEST31bus","Txt3Bus"];
    c_case = cell(0,1);
    for s = sv_net
        c_case{end+1,1} = struct("name", s, "gc", false); %#ok<AGROW>
    end
    c_case{end+1,1} = struct("name", "Ishizaki6Bus", "gc", true);
    c_case{end+1,1} = struct("name", "IEEE14bus", "gc", true);

    ref = struct("name", {}, "net", {}, "point", {}, "kron", {}, "dae", {}, "comp", {}, "bus", {}, "lc", {}, "gc", {});
    for k = 1:numel(c_case)
        cs  = c_case{k};
        net = build(cs);
        r0  = net.linearize();
        tab = r0.tab_variable;
        p   = r0.rv_point;
        lx  = tab.Kind == "x";
        rng(1);
        p2  = p;
        p2(lx) = p2(lx) + 0.01*randn(nnz(lx),1).*max(1,abs(p2(lx)));
        c_pt = {[], p2};
        for m = 1:2
            r = net.linearize(Point=c_pt{m});
            e = struct();
            e.name  = cs.name + string(ifelse(cs.gc, "+GC", ""));
            e.point = r.rv_point;
            e.net   = struct("Axx", sparse(r.rm_Axx), "Axv", sparse(r.rm_Axv), "Bx", sparse(r.rm_Bx), ...
                             "Avx", sparse(r.rm_Avx), "Avv", sparse(r.rm_Avv), "Bv", sparse(r.rm_Bv), "E", sparse(r.rm_E), ...
                             "sv_x", tab.Label(tab.Kind == "x"), "sv_v", tab.Label(tab.Kind == "Vre" | tab.Kind == "Vim"), ...
                             "sv_u", tab.Label(tab.Kind == "u"), "l_eq", m == 1);
            K = r.get_ss("Kron", Format="struct");
            ev = eig(K.A, K.E);
            if numel(K.StateName) > 150     % 大きい系統は固有値と名前だけ (Kron は rm_* から決まる)
                K = struct("StateName", K.StateName, "InputName", K.InputName);
            else
                K = sparse_model(K);
            end
            K.eig = ev(isfinite(ev));
            e.kron = K;
            e.dae = sparse_model(r.get_ss("DAE", Coordinate="theta&rho", Format="struct"));
            [e.comp, e.bus, e.lc, e.gc] = objects(net, r, m == 1);
            ref(end+1) = e; %#ok<AGROW>
            fprintf("%-18s %d: nx %d\n", e.name, m, numel(e.net.sv_x));
        end
    end
    s_base = string(strtrim(evalc("system('git rev-parse --short HEAD');")));
    save(s_file, "ref", "s_base", "-v7");
    fprintf("saved %s (%d entries)\n", s_file, numel(ref));
end


function net = build(cs)
    net = network.(cs.name)();
    if cs.gc
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
        net.add_global_controller("agc-PI", cc(1:2), parameter=struct(alpha=[1;1], beta=[1;1]));
    end
    evalc("net.initialize();");
end


function [c_comp, c_bus, c_lc, c_gc] = objects(net, r, l_eq)
% モデルオブジェクトの線形モデル。ずらした点は網の点から各層の行を選ぶ
    [~, c_idxBus] = net.get_variable_map();
    p = r.rv_point;
    n_lin = numel(p);
    c_comp = cell(0,1);  c_bus = cell(0,1);  c_lc = cell(0,1);  c_gc = cell(0,1);
    for i = 1:numel(net.a_Bus)
        bus = net.a_Bus{i};
        iv_b = c_idxBus{i}(c_idxBus{i} <= n_lin);
        pb = p(iv_b);
        sb = struct("tag", string(bus.s_tag));
        if l_eq
            sb.V2I = bus.get_sys(Format="struct");
        else
            sb.V2I = bus.get_sys(Point=pb, Format="struct");
        end
        sb.I2V = try_sys(@() bus.get_sys(port="I2V", Point=ifelse(l_eq, [], pb), Format="struct"));
        c_bus{end+1,1} = sb; %#ok<AGROW>
        [~, c_idx] = bus.get_variable_map();
        nb = numel(pb);
        for j = 1:numel(bus.a_Component)
            comp = bus.a_Component{j};
            pc = pb(c_idx{j}(c_idx{j} <= nb));
            sc = struct("tag", string(comp.s_tag), "bus", string(bus.s_tag));
            if l_eq
                sc.V2I = comp.get_sys(Format="struct");
                sc.alone = comp.get_sys(Controllers=false, Format="struct");
            else
                sc.V2I = comp.get_sys(Point=pc, Format="struct");
                sc.alone = struct();
            end
            sc.I2V = try_sys(@() comp.get_sys(port="I2V", Point=ifelse(l_eq, [], pc), Format="struct"));
            c_comp{end+1,1} = sc; %#ok<AGROW>
            if l_eq
                a_lc = all_controllers(comp);
                for q = 1:numel(a_lc)
                    c_lc{end+1,1} = struct("tag", string(a_lc{q}.s_tag), "bus", string(bus.s_tag), ...
                                           "sys", a_lc{q}.get_sys(Format="struct")); %#ok<AGROW>
                end
            end
        end
    end
    if l_eq
        [tab, ~, c_idxGC, tab_c] = net.get_variable_map();
        for k = 1:numel(net.a_GlobalController)
            gc = net.a_GlobalController{k};
            S = gc.get_sys(Format="struct");
            % 旧モデルの入力の列と出力の行が、新しいモデルのどの uc・yc の Label か
            iv_gc = c_idxGC{k};
            iv_uc = iv_gc(tab.Kind(iv_gc) == "uc");
            iv_yc = iv_gc(tab.Kind(iv_gc) == "yc");
            tab_g = tab_c(tab_c.Kind == "global" & ismember(tab_c.SourceIndex, iv_yc), :);
            [~, iv_ord] = sort(tab_g.SourceIndex);
            S.InputSlot  = tab.Label(iv_uc);
            S.OutputSlot = tab.Label(tab_g.SourceIndex(iv_ord));
            c_gc{end+1,1} = struct("tag", string(gc.s_tag), "sys", S); %#ok<AGROW>
        end
    end
end


function S = try_sys(f)
    try
        S = f();
    catch ME
        S = struct("error", string(ME.identifier));
    end
end

function S = sparse_model(S)
    for s = ["A","B","C","D","E"]
        S.(s) = sparse(S.(s));
    end
end

function list = all_controllers(parent)
    list = cell(0,1);
    for k = 1:numel(parent.a_LocalController)
        con  = parent.a_LocalController{k};
        list = [list; {con}; all_controllers(con)]; %#ok<AGROW>
    end
end

function v = ifelse(c, a, b)
    if c, v = a; else, v = b; end
end
