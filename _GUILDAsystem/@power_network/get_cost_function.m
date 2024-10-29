function cost_breakdown = get_cost_function(obj, out)

horz = @(data) reshape(data,1,[]);

a_bus = obj.a_bus;
a_branch = obj.a_branch;
a_controller_local = obj.a_controller_local;
a_controller_global = obj.a_controller_global;

nbus = numel(a_bus);
ncon_local = numel(a_controller_local);
ncon_global = numel(a_controller_global);

t = out.t;
T = 1:numel(t);
X = cell(size(nbus));
V = cell(size(nbus));
I = cell(size(nbus));
u_global = cell(size(nbus));
u_local = cell(size(nbus));
u = cell(size(nbus));
Xcon_local = cell(size(a_controller_local));
Xcon_global = cell(size(a_controller_global));

for n = 1:nbus
    X{n} = table2array(out.X{n});
    V{n} = [table2array(out.V{n}(:,"real")),table2array(out.V{n}(:,"imag"))];
    I{n} = [table2array(out.I{n}(:,"real")),table2array(out.I{n}(:,"imag"))];
    u_global{n} = table2array(out.Uinput{n});
    u_local{n} = table2array(out.Utotal{n});
    u{n} = u_global{n} + u_local{n};
end

for n = 1:ncon_local
    Xcon_local{n} = table2array(out.Xcon.local{n});
end

for n = 1:ncon_global
    Xcon_global{n} = table2array(out.Xcon.global{n});
end


%%% ブランチ上のコスト関数の時系列データ %%%
cost_breakdown.branch = cell(size(a_branch));
br_function_state = find(tools.vcellfun(@(br) ~isempty(br.CostFunction), a_branch));
for i = 1:numel(br_function_state)
    idx = br_function_state(i);
    br = a_branch{idx};
    cost_br = tools.varrayfun(@(j) horz(br.CostFunction(br, t(j), V{br.from}(j,:),V{br.to}(j,:))), T');
    %cost_br(isnan(cost_br)) = 0;
    cost_breakdown.branch{idx} = cost_br;
end

%%% ブランチ上のコスト関数の指定時間内の合計 %%%
cost_breakdown.branch_total = cell(size(a_branch));
for i = 1:numel(br_function_state)
    idx = br_function_state(i);
    [~, r] = size(cost_breakdown.branch{idx});
    for j = 1:r
        cost_breakdown.branch_total{idx}(1,j) = trapz(t, cost_breakdown.branch{idx}(:,j));
    end
end


%%% 機器上のコスト関数 %%%
cost_breakdown.component = cell(size(a_bus));
component_function_state = find(tools.vcellfun(@(b) ~isempty(b.component.CostFunction), a_bus));
for i = 1:numel(component_function_state)
    idx = component_function_state(i);
    c = obj.a_bus{idx}.component;
    cost_comp = tools.varrayfun(@(j) horz(c.CostFunction(c,t(j),X{idx}(j,:),V{idx}(j,:),I{idx}(j,:),u{idx}(j,:))), T');
    %cost_comp(isnan(cost_comp)) = 0;
    cost_breakdown.component{idx} = cost_comp;
end

%%% 機器上のコスト関数の指定時間内の合計 %%%
cost_breakdown.component_total = cell(size(a_bus));
for i = 1:numel(component_function_state)
    idx = component_function_state(i);
    [~, r] = size(cost_breakdown.component{idx});
    for j = 1:r
        cost_breakdown.component_total{idx}(1,j) = trapz(t, cost_breakdown.component{idx}(:,j));
    end
end


%%% ローカルコントローラ上のコスト関数 %%%
cost_breakdown.controller_local = cell(size(a_controller_local));
controller_local_state = find(tools.vcellfun(@(c) ~isempty(c.CostFunction), a_controller_local));
for i = 1:numel(controller_local_state)
    idx = controller_local_state(i);
    c = a_controller_local{idx};
    x = Xcon_local{idx};
    for j = 1:numel(t)
        Xc = tools.arrayfun(@(i) X{i}(j,:), c.index_input(:));
        Vc = tools.arrayfun(@(i) V{i}(j,:), c.index_input(:));
        Ic = tools.arrayfun(@(i) I{i}(j,:), c.index_input(:));
        Uc = tools.arrayfun(@(o) u_local{o}(j,:), c.index_observe(:));
        cost_breakdown.controller_local{idx}(j,:) = horz(c.CostFunction(c,t(j),x(j),Xc,Vc,Ic,Uc));
    end
end

%%% ローカルコントローラ上のコスト関数の指定時間内の合計 %%%
cost_breakdown.controller_local_total = cell(size(a_controller_local));
for i = 1:numel(controller_local_state)
    idx = controller_local_state(i);
    [~, r] = size(cost_breakdown.controller_local{idx});
    for j = 1:r
        cost_breakdown.controller_local_total{idx}(1,j) = trapz(t, cost_breakdown.controller_local{idx}(:,j));
    end
end


%%% グローバルコントローラ上のコスト関数 %%%
cost_breakdown.controller_global = cell(size(a_controller_global));
controller_global_state = find(tools.vcellfun(@(c) ~isempty(c.CostFunction), a_controller_global));
for i = 1:numel(controller_global_state)
    idx = controller_global_state(i);
    c = a_controller_global{idx};
    x = Xcon_global{idx};
    for j = 1:numel(t)
        Xc = tools.arrayfun(@(i) X{i}(j,:), c.index_input(:));
        Vc = tools.arrayfun(@(i) V{i}(j,:), c.index_input(:));
        Ic = tools.arrayfun(@(i) I{i}(j,:), c.index_input(:));
        Uc = tools.arrayfun(@(o) u_global{o}(j,:), c.index_observe(:));
        cost_breakdown.controller_global{idx}(j,:) = horz(c.CostFunction(obj,t(j),x(j),Xc,Vc,Ic,Uc));
    end
end

%%% グローバルコントローラ上のコスト関数の指定時間内の合計 %%%
cost_breakdown.controller_global_total = cell(size(a_controller_global));
for i = 1:numel(controller_global_state)
    idx = controller_global_state(i);
    [~, r] = size(cost_breakdown.controller_global{idx});
    for j = 1:r
        cost_breakdown.controller_global_total{idx}(1,j) = trapz(t, cost_breakdown.controller_global{idx}(:,j));
    end
end

end
