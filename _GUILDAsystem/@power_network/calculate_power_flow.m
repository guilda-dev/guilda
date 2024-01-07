function [V, I, flag, output] = calculate_power_flow(obj, varargin)
n = numel(obj.a_bus);
x0_all = kron(ones(n, 1), [1; 0]);

p = inputParser;
p.CaseSensitive = false;
p.addParameter('MaxFunEvals', 1e6);
p.addParameter('MaxIterations', 2e5);
p.addParameter('Display', 'none');%'iter-detailed');
p.addParameter('UseParallel', false);
p.addParameter('return_vector', false);
p.addParameter('warning', @warning); % @warning, @error, []
p.addParameter('message', false);
p.parse(varargin{:});
p = p.Results;

if isempty(p.warning)
    p.warning = @none;
end

options = optimoptions('fsolve', 'MaxFunEvals', p.MaxFunEvals,...
    'MaxIterations', p.MaxIterations, 'Display', p.Display,...
    'UseParallel', p.UseParallel);

[~, Ymat] = obj.get_admittance_matrix();
[V,~,flag,output] = fsolve(@(x) func_eq(obj.a_bus, Ymat, x), x0_all,options);
switch flag
    case 0
        warning off backtrace
        p.warning('Power equation could not be solved. >> The number of iterations exceeds options.MaxIterations or the number of function evaluations exceeds options.MaxFunctionEvaluations.')
        warning on backtrace
    case {-2,-3}
        warning off backtrace
        p.warning('Power equation could not be solved. Please review the power flow settings')
        warning on backtrace
end

if p.message
    disp(output.message)
end

I = Ymat*V;

if ~p.return_vector
    V = tools.vec2complex(V);
    I = tools.vec2complex(I);
end

end


function out = func_eq(bus, Ymat, x)
    n = numel(bus);
    Vmat = x;
    Vr = x(1:2:end);
    Vi = x(2:2:end);
    YV = Ymat*Vmat;
    YV_mat = cell(n, 1);
    for itr = 1:n
        YV_mat{itr} = sparse([YV(2*itr-1), YV(2*itr); -YV(2*itr), YV(2*itr-1)]);
    end
    YV_mat = blkdiag(YV_mat{:});
    PQhat = YV_mat*Vmat;
    Phat = PQhat(1:2:end);
    Qhat = PQhat(2:2:end);
    
    eq_consts = cell(n, 1);
    for itr = 1:n
        eq_consts{itr} = bus{itr}.get_constraint(Vr(itr), Vi(itr), Phat(itr), Qhat(itr));
    end
    out = vertcat(eq_consts{:});
end

function none(varargin)
end