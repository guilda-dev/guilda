function rv = point_with_inputs(net, rv_xvu)
% 点 x, Vre, Vim, u に、接続マップから求めた制御器の入力 uc を加える (get_sys の点の行 x, Vre, Vim, u, uc)
%
%   rv = DebugScript.helper.point_with_inputs(net, rv_xvu)
%
% 以前の get_sys は点の x, Vre, Vim, u から制御器の入力 uc を接続で求めていた (局所関数
% input_values)。その点と同じ点を今の get_sys に与えるための関数。各入力は "global" を除く
% 源の和: "observe" は機器の出力 y か状態、"local" は入れ子の LC の出力 yc (深い LC から)、
% "equilibrium" は制御器の rv_Uequilibrium。基準値 (linearization_reference.mat) のずらした点や、
% 以前の長さのベクトルを使うテストで使う。
    arguments (Input)
        net     % 系統 (PowerNetwork、net.initialize の後)。
        rv_xvu  (:,1) double  % net.get_variable_map() の Kind が x, Vre, Vim, u の行の値。
    end
    arguments (Output)
        rv (:,1) double  % Kind が x, Vre, Vim, u, uc の行の値 (net.get_sys の点)。
    end
    [tab, ~, ~, tab_c] = net.get_variable_map();
    n_xvu = nnz(ismember(tab.Kind, ["x","Vre","Vim","u"]));
    assert(numel(rv_xvu) == n_xvu, "点の長さ %d が x, Vre, Vim, u の行の数 %d と違う", numel(rv_xvu), n_xvu)
    val = [rv_xvu; zeros(height(tab) - n_xvu, 1)];
    rows = @(o, s_kind) find(tab.Kind == s_kind & tab.Owner == string(o.s_tag));
    lv_V = tab.Kind == "Vre" | tab.Kind == "Vim";
    V_of = @(c) val(lv_V & tab.Bus == string(c.a_Bus.s_tag));
    % 機器の出力 y、LC ごとの (制御器, 機器) の組 (深さ優先)
    c_lc = cell(0,2);
    for i = 1:numel(net.a_Bus)
        for j = 1:numel(net.a_Bus{i}.a_Component)
            c = net.a_Bus{i}.a_Component{j};
            iv_y = rows(c, "y");
            if ~isempty(iv_y)
                val(iv_y) = reshape(c.f_Y(0, val(rows(c, "x")), V_of(c)), [], 1);
            end
            c_stack = flip(reshape(c.a_LocalController, [], 1));
            while ~isempty(c_stack)
                con = c_stack{end};
                c_stack(end) = [];
                c_lc(end+1,:) = {con, c}; %#ok<AGROW>
                c_stack = [c_stack; flip(reshape(con.a_LocalController, [], 1))]; %#ok<AGROW>
            end
        end
    end
    f_in = @(con, iv_uc) sources(con, iv_uc, val, tab_c);
    % LC: 深い LC から (入れ子の LC は親の後に並ぶ)
    for k = size(c_lc,1):-1:1
        con = c_lc{k,1};
        iv_uc = rows(con, "uc");
        val(iv_uc) = f_in(con, iv_uc);
        iv_yc = rows(con, "yc");
        if ~isempty(iv_yc)
            val(iv_yc) = reshape(con.f_Y(0, val(rows(con, "x")), V_of(c_lc{k,2}), val(iv_uc)), [], 1);
        end
    end
    for k = 1:numel(net.a_GlobalController)
        gc = net.a_GlobalController{k};
        iv_uc = rows(gc, "uc");
        val(iv_uc) = f_in(gc, iv_uc);
    end
    rv = val(ismember(tab.Kind, ["x","Vre","Vim","u","uc"]));
end


function rv = sources(con, iv_uc, val, tab_c)
% 各入力の源の和 ("global" を除く)
    rv = zeros(numel(iv_uc),1);
    rv_eq = reshape(con.rv_Uequilibrium, [], 1);
    for m = 1:numel(iv_uc)
        tab_m = tab_c(tab_c.TargetIndex == iv_uc(m) & tab_c.Kind ~= "global", :);
        for r = 1:height(tab_m)
            if tab_m.Kind(r) == "equilibrium"
                rv(m) = rv(m) + rv_eq(m);
            else
                rv(m) = rv(m) + val(tab_m.SourceIndex(r));
            end
        end
    end
end
