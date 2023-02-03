function [cost_total,cost_breakdown] = get_cost_function(obj, varargin)

nbus = numel(obj.a_bus);

p = inputParser;
p.CaseSensitive = false;
addParameter(p, 't',  0);
addParameter(p, 'x', []);
addParameter(p, 'V', []);
addParameter(p, 'I', []);
addParameter(p, 'u', []);
addParameter(p, 'x_con_local', []);
addParameter(p, 'x_con_global', []);
parse(p, varargin{:});
p = p.Results;


if isempty(p.V)
    p.V = tools.complex2vec(obj.V_equilibrium);
end
if isempty(p.I)
    [~ ,Y] = obj.get_admittance_matrix();
    p.I = Y*p.V;
end

X = cell(nbus,1);
V = cell(nbus,1);
I = cell(nbus,1);
u = cell(nbus,1);

has_x = ~isempty(p.x);
has_u = ~isempty(p.u);

xidx = 0;
uidx = 0;

for idx = 1:nbus
    c  = obj.a_bus{idx}.component;
    if has_x
        nx = c.get_nx;
        X{idx} = p.x(xidx+(1:nx));
        xidx = xidx+nx;
    else
        X{idx} = c.x_equilibrium;
    end
    if has_u
        nu = c.get_nu;
        u{idx} = p.u(uidx+(1:nu));
        uidx = uidx+nu;
    else
        u{idx} = zeros(c.get_nu,1);
    end
    V{idx} = p.V([2*idx-1,2*idx]);
    I{idx} = p.I([2*idx-1,2*idx]);
end



%%% ブランチ上のコスト関数 %%%
    cost_breakdown.branch = zeros(numel(obj.a_branch),1);
    for i = 1:numel(obj.a_branch)
        br = obj.a_branch{i};
        cost_breakdown.branch(i) = br.CostFunction(br,V{br.from},V{br.to});
    end


%%% 機器上のコスト関数 %%%
    cost_breakdown.component = zeros(nbus,1);
    for i = 1:nbus
        c = obj.a_bus{i}.component;
        cost_breakdown.component(i) = c.CostFunction(c,p.t,X{i},V{i},I{i},u{i});
    end


%%% ローカルコントローラ上のコスト関数 %%%
    ncon = numel(obj.a_controller_local);
    has_xcl = ~isempty(p.x_con_local);
    xidx = 0;

    cost_breakdown.controller_local = zeros(ncon,1);
    for i = 1:ncon
        c = obj.a_controller_local{i};
        if has_xcl
            nx = c.get_nx;
            x = p.x_con_local(xidx+(1:nx));
            xidx = xidx + nx;
        else
            x = c.get_x0;
        end
        X = tools.arrayfun(@(i) X{i}, c.index_input(:));
        V = tools.arrayfun(@(i) V{i}, c.index_input(:));
        I = tools.arrayfun(@(i) I{i}, c.index_input(:));
        U = tools.arrayfun(@(i) u{i}, c.index_oberve(:));
        cost_breakdown.controller_local(i) = c.CostFunction(c,x,X,V,I,U);
    end


%%% グローバルコントローラ上のコスト関数 %%%
    ncon = numel(obj.a_controller_global);
    has_xcg = ~isempty(p.x_con_local);
    xidx = 0;

    cost_breakdown.controller_global = zeros(ncon,1);
    for i = 1:ncon
        c = obj.a_controller_global{i};
        if has_xcg
            nx = c.get_nx;
            x = p.x_con_global(xidx+(1:nx));
            xidx = xidx + nx;
        else
            x = c.get_x0;
        end
        X = tools.arrayfun(@(i) X{i}, c.index_input(:));
        V = tools.arrayfun(@(i) V{i}, c.index_input(:));
        I = tools.arrayfun(@(i) I{i}, c.index_input(:));
        U = [];
        cost_breakdown.controller_global(i) = c.CostFunction(c,x,X,V,I,U);
    end



%%% 全体のコストの合計を算出．
    cost_total = sum(vertcat(cost_breakdown.branch,...
                             cost_breakdown.component,...
                             cost_breakdown.controller_local,...
                             cost_breakdown.controller_global));
end
