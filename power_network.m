classdef power_network < handle
    
    properties(Dependent)
        x_equilibrium
        V_equilibrium
        I_equilibrium
    end
    
    properties(SetAccess = protected)
        a_bus = {}
        a_controller_global = {}
        a_controller_local = {}
        a_branch = {}
    end
    
    methods(Static)
        function dx = get_dx(bus, controllers_global, controllers, Ymat,...
                nx_bus, nx_controller_global, nx_controller, nu_bus,...
                t, x_all, u, idx_u, idx_fault, simulated_bus)

            n1 = sum(nx_bus(simulated_bus));
            n2 = sum(nx_controller_global);
            n3 = sum(nx_controller);
            n4 = 2*numel(simulated_bus);
            n5 = 2*numel(idx_fault);

            x = x_all(1:n1);
            xkg = x_all(n1+(1:n2));
            xk = x_all(n1+n2+(1:n3));

            V = reshape(x_all(n1+n2+n3+(1:n4)), 2, []);
            I_fault = reshape(x_all(n1+n2+n3+n4+(1:n5)), 2, []);

            I = reshape(Ymat*V(:), 2, []);
            I(:, idx_fault) = I_fault;

            Vall = zeros(2, numel(bus));
            Iall = zeros(2, numel(bus));

            Vall(:, simulated_bus) = V;
            Iall(:, simulated_bus) = I;

            idx = 0;

            x_bus = cell(numel(bus), 1);
            U_bus = cell(numel(bus), 1);

            for i = 1:numel(simulated_bus)
            %     b = bus{itr};
                x_bus{simulated_bus(i)} = x(idx+(1:nx_bus(simulated_bus(i))));
                idx = idx + nx_bus(simulated_bus(i));
                U_bus{simulated_bus(i)} = zeros(nu_bus(simulated_bus(i)), 1);
            end

            xkg_cell = cell(numel(controllers_global), 1);
            xk_cell = cell(numel(controllers), 1);

            idx = 0;
            for i = 1:numel(controllers_global)
               xkg_cell{i} = xkg(idx+(1:nx_controller_global(i)));
               idx = idx + nx_controller_global(i);
            end

            idx = 0;
            for i = 1:numel(controllers)
               xk_cell{i} = xk(idx+(1:nx_controller(i)));
               idx = idx + nx_controller(i);
            end


            dxkg = cell(numel(controllers_global), 1);
            for i = 1:numel(controllers_global)
               c = controllers_global{i};
               [dxkg{i}, ug_] = c.get_dx_u_func(t, xkg_cell{i}, x_bus(c.index_observe), Vall(:, c.index_observe), Iall(:, c.index_observe), []);
               idx = 0;
               for i_input = c.index_input(:)'
                   U_bus{i_input} = U_bus{i_input} + ug_(idx+(1:nu_bus(i_input)));
                   idx = idx + nu_bus(i_input);
               end
            end
            U_global = U_bus;

            dxk = cell(numel(controllers), 1);
            for i = 1:numel(controllers)
               c = controllers{i};

               [dxk{i}, u_] = c.get_dx_u_func(t, xk_cell{i}, x_bus(c.index_observe), Vall(:, c.index_observe), Iall(:, c.index_observe), U_global(c.index_observe));
               idx = 0;
               for i_input = c.index_input(:)'
                   U_bus{i_input} = U_bus{i_input} + u_(idx+(1:nu_bus(i_input)));
                   idx = idx + nu_bus(i_input);
               end
            end

            idx = 0;
            for i = idx_u(:)'
               U_bus{i} = U_bus{i} + u(idx+(1:nu_bus(i)));
               idx = idx + nu_bus(i);
            end

            % [dx_component, constraint] = tools_arrayfun(...
            %     @(i) bus{i}.component.get_dx_con(t, x_bus{i}, Vall(:, i), Iall(:, i), U_bus{i}),...
            %     simulated_bus);


            dx_component = cell(numel(simulated_bus), 1);
            constraint = cell(numel(simulated_bus), 1);
            for i = 1:numel(simulated_bus)
                idx = simulated_bus(i);
               [dx_component{i}, constraint{i}] = bus{idx}.component.get_dx_con_func(...
                t, x_bus{idx}, Vall(:, idx), Iall(:, idx), U_bus{idx}...   
                ); 
            end

            dx_algebraic = vertcat(constraint{:}, reshape(Vall(:, idx_fault), [], 1));

            dx = [vertcat(dx_component{:}); vertcat(dxkg{:}); vertcat(dxk{:}); dx_algebraic];
        end
    end
    
    methods
        function initialize(obj)
            [V, I] = obj.calculate_power_flow();
            obj.set_equilibrium(V, I);
        end
        
        function x = get.x_equilibrium(obj)
            x = tools_vcellfun(@(b) b.component.x_equilibrium, obj.a_bus);
        end

        function x = get.V_equilibrium(obj)
            x = tools_vcellfun(@(b) b.V_equilibrium, obj.a_bus);
        end
        
        function x = get.I_equilibrium(obj)
            x = tools_vcellfun(@(b) b.I_equilibrium, obj.a_bus);
        end
        
        function add_controller_local(obj, controller)
            obj.remove_controller_local(controller.index_all);
            obj.a_controller_local{numel(obj.a_controller_local)+1} = controller;
        end
        
        function add_controller_global(obj, controller)
            obj.a_controller_global{numel(obj.a_controller_global)+1} = controller;
        end
        
        function remove_controller_local(obj, idx)
            remove_idx = [];
            for itr = 1:numel(obj.a_controller_local)
                if ~isempty(intersect(obj.a_controller_local{itr}.index_all, idx))
                    remove_idx = [remove_idx; itr]; %#ok
                end
            end
            obj.a_controller_local(remove_idx) = [];
        end
        
        function remove_controller_global(obj, idx)
            remove_idx = [];
            for itr = 1:numel(obj.a_controller_global)
                if ~isempty(intersect(obj.a_controller_global{itr}.index_all, idx))
                    remove_idx = [remove_idx; itr]; %#ok
                end
            end
            obj.a_controller_local(remove_idx) = [];
        end
        
        function check_bus_edited(obj)
            edited = tools_hcellfun(@(bus) bus.edited, obj.a_bus);
            if any(edited)
                disp(['bus',mat2str(find(edited)),'の潮流設定が変更されています.'])
                sw = input('再度,潮流計算しますか？(y/n)：',"str");
                if strcmp(sw,'y')
                    obj.initialize();
                end
            end
        end
        
        function add_bus(obj, bus)
            if iscell(bus)
                if any(tools_vcellfun(@(b) ~isa(b, 'bus'), bus))
                   error('must be a child of bus');
                end
                obj.a_bus = [obj.a_bus; bus];
            else
                if isa(bus, 'bus')
                    obj.a_bus = [obj.a_bus; {bus}];
                else
                   error('must be a child of bus'); 
                end
            end
        end
        
        function add_branch(obj, branch)
            if iscell(branch)
                if any(tools_vcellfun(@(l) ~isa(l, 'branch'), branch))
                   error();
                end
                obj.a_branch = [obj.a_branch; branch];
            else
                if isa(branch, 'branch')
                    obj.a_branch = [obj.a_branch; {branch}];
                else
                   error(); 
                end
            end
        end

        function [Y, Ymat] = get_admittance_matrix(obj, a_idx_bus)
            if nargin < 2
                a_idx_bus = 1:numel(obj.a_bus);
            end

            n_bus = numel(obj.a_bus);
            Y = sparse(n_bus, n_bus);

            for i = 1:numel(obj.a_branch)
               br = obj.a_branch{i};
               if ismember(br.from, a_idx_bus) || ismember(br.to, a_idx_bus)
                   Y_branch = br.get_admittance_matrix();
                   Y([br.from, br.to], [br.from, br.to]) = Y([br.from, br.to], [br.from, br.to]) + Y_branch;
               end
            end

            shunt = tools_vcellfun(@(b) b.shunt, obj.a_bus(a_idx_bus));
            S = sparse(a_idx_bus, a_idx_bus, shunt, n_bus, n_bus);

            Y = Y + S;
            if nargout == 2
                Ymat = tools_complex2matrix(Y);
            end
        end
        
        function out = simulate(obj, t, varargin)
            if nargin < 3 || isstruct(varargin{1}) || ischar(varargin{1})
                options = obj.simulate_options(varargin{:});
                u = [];
                idx_u = [];
            else
                u = varargin{1};
                idx_u = varargin{2};
                options = obj.simulate_options(varargin{3:end});
            end

            out = obj.solve_odes(t, u, idx_u, options.fault,...
                options.x0_sys, options.x0_con_global,...
                options.x0_con_local,...
                tools_complex2vec(options.V0), tools_complex2vec(options.I0), options.linear, options);
        end
    end
    
    methods(Access = private)
        function [V, I] = calculate_power_flow(obj, varargin)
            n = numel(obj.a_bus);
            x0_all = kron(ones(n, 1), [1; 0]);

            p = inputParser;
            p.CaseSensitive = false;
            p.addParameter('MaxFunEvals', 1e6);
            p.addParameter('MaxIterations', 2e4);
            p.addParameter('Display', 'none');
            p.addParameter('UseParallel', false);
            p.addOptional('return_vector', false);
            p.parse(varargin{:});

            options = optimoptions('fsolve', 'MaxFunEvals', p.Results.MaxFunEvals,...
                'MaxIterations', p.Results.MaxIterations, 'Display', p.Results.Display,...
                'UseParallel', p.Results.UseParallel);

            [Y, Ymat] = obj.get_admittance_matrix();
            V = fsolve(@(x) func_eq(obj.a_bus, Ymat, x), x0_all, options);
            I = Ymat*V;

            if ~p.Results.return_vector
                V = tools_vec2complex(V);
                I = tools_vec2complex(I);
            end
        end
        
        function set_equilibrium(obj, V, I)
            for i = 1:numel(obj.a_bus)
               obj.a_bus{i}.set_equilibrium(V(i), I(i)); 
            end
        end
        
        function options = simulate_options(obj, varargin)
            p = inputParser;
            p.CaseSensitive = false;
            addParameter(p, 'linear', false);
            addParameter(p, 'fault', {});
            addParameter(p, 'x0_sys', obj.x_equilibrium);
            addParameter(p, 'V0', obj.V_equilibrium);
            addParameter(p, 'I0', obj.I_equilibrium);
            x0_con_local = tools_vcellfun(@(c) c.get_x0(), obj.a_controller_local);
            addParameter(p, 'x0_con_local', x0_con_local);
            x0_con_global = tools_vcellfun(@(c) c.get_x0(), obj.a_controller_global);
            addParameter(p, 'x0_con_global', x0_con_global);
            addParameter(p, 'method', 'zoh', @(method) ismember(method, {'zoh', 'foh'}));
            addParameter(p, 'AbsTol', 1e-8);
            addParameter(p, 'RelTol', 1e-8);
            addParameter(p, 'do_report', false);
            addParameter(p, 'reset_time', inf);
            addParameter(p, 'do_retry', true);
            addParameter(p, 'OutputFcn', []);
            addParameter(p, 'tools', false);

            parse(p, varargin{:});
            options = p.Results;
        end
        
        function out = solve_odes(obj, t, u, idx_u, fault, x, xkg, xk, V0, I0, linear, options)
            bus = obj.a_bus;
            controllers_global = obj.a_controller_global;
            controllers = obj.a_controller_local;

            fault_time = tools_cellfun(@(c) c{1}, fault);
            idx_fault = tools_cellfun(@(c) c{2}, fault);

            uf = sample2f(t, u);
            fault_f = idx2f(fault_time, idx_fault);
            t_cand = t(:);
            if iscell(fault_time)
                for i = 1:numel(fault_time)
                    tf = fault_time{i};
                    t_cand = [t_cand; tf(:)]; %#ok
                end
            else
                t_cand = [t_cand; fault_time(:)];
            end

            t_cand = unique(sort(t_cand));
            t_cand = t_cand(:);
            % f_jacobi = {};
            nx_bus = tools_vcellfun(@(b) b.get_nx, bus);
            nu_bus = tools_vcellfun(@(b) b.get_nu, bus);
            nx_kg = tools_vcellfun(@(c) c.get_nx, controllers_global);
            nx_k = tools_vcellfun(@(c) c.get_nx, controllers);
            idx_non_unit = find(tools_vcellfun(@(b) isa(b.component, 'component_empty'), bus));
            idx_controller = unique(...
                tools_vcellfun(@(c) [c.index_observe(:); c.index_input(:)],...
                [controllers(:); controllers_global(:)]));

            [Y, Ymat_all] = obj.get_admittance_matrix();

            switch options.method
                case 'zoh'
                    t_simulated = get_t_simulated(t_cand, uf, fault_f);
                case 'foh'
                    t_simulated = t_cand;
            end

            sols = cell(numel(t_simulated)-1, 1);
            reporter = tools_Reporter(t_simulated(1), t_simulated(end), options.do_report, options.OutputFcn);
            out_X = cell(numel(t_simulated)-1, 1);
            out_V = cell(numel(t_simulated)-1, 1);
            out_I = cell(numel(t_simulated)-1, 1);
            x0 = [x; xkg; xk];

            if linear
                for i = 1:numel(controllers_global)
                    c = controllers_global{i};
                    c.get_dx_u_func = @c.get_dx_u_linear;
                end
                for i = 1:numel(controllers)
                    c = controllers{i};
                    c.get_dx_u_func = @c.get_dx_u_linear;
                end
                for i = 1:numel(bus)
                    c = bus{i}.component;
                    c.get_dx_con_func = @c.get_dx_constraint_linear;
                end
            else
                for i = 1:numel(controllers_global)
                    c = controllers_global{i};
                    c.get_dx_u_func = @c.get_dx_u;
                end
                for i = 1:numel(controllers)
                    c = controllers{i};
                    c.get_dx_u_func = @c.get_dx_u;
                end
                for i = 1:numel(bus)
                    c = bus{i}.component;
                    c.get_dx_con_func = @c.get_dx_constraint;
                end
            end

            out = struct();
            out.simulated_bus = cell(numel(t_simulated)-1, 1);
            out.fault_bus = cell(numel(t_simulated)-1, 1);
            out.Ymat_reproduce = cell(numel(t_simulated)-1, 1);


            for i = 1:numel(t_simulated)-1
                f_ = fault_f((t_simulated(i)+t_simulated(i+1))/2);
                except = unique([f_(:); idx_controller(:)]);
                simulated_bus = setdiff(1:numel(bus), setdiff(idx_non_unit, except));
                simulated_bus = simulated_bus(:);
                [~, Ymat, ~, Ymat_reproduce] = obj.reduce_admittance_matrix(Y, simulated_bus);
                out.simulated_bus{i} = simulated_bus;
                out.fault_bus{i} = f_;
                out.Ymat_reproduce{i} = Ymat_reproduce;
                idx_simulated_bus = [2*simulated_bus-1; 2*simulated_bus];

                idx_fault_bus = [f_(:)*2-1, f_(:)*2]';
                idx_fault_bus = idx_fault_bus(:);

                x = [x0; V0(idx_simulated_bus); I0(idx_fault_bus)];


                switch options.method
                    case 'zoh'
                        u_ = uf((t_simulated(i)+t_simulated(i+1))/2);
                        func = @(t, x) power_network.get_dx(...
                            bus, controllers_global, controllers, Ymat,...
                            nx_bus, nx_kg, nx_k, nu_bus, ...
                            t, x, u_, idx_u, f_, simulated_bus...
                            );
                    case 'foh'
                        us_ = uf(t_simulated(i));
                        ue_ = uf(t_simulated(i+1));
                        u_ = @(t) (ue_*(t-t_simulated(i))+us_*(t_simulated(i+1)-t))/(t_simulated(i+1)-t_simulated(i));
                        func = @(t, x) power_network.get_dx(...
                            bus, controllers_global, controllers, Ymat,...
                            nx_bus, nx_kg, nx_k, nu_bus, ...
                            t, x, u_(t), idx_u, f_, simulated_bus...
                            );
                end

                nx = numel(x0);
                nVI = numel(x)-nx;
                nV = nVI-numel(f_)*2;
                nI = numel(f_)*2;
                Mf = blkdiag(eye(nx), zeros(nVI));
                %       r = @(t, y, flag) false;
                %     r = @odephas2;
                t_now = datetime;
                r = @(t, y, flag) reporter.report(t, y, flag, options.reset_time, t_now);

                odeoptions = odeset('Mass',Mf, 'RelTol', options.RelTol, 'AbsTol', options.AbsTol, 'OutputFcn', r);
                sol = ode15s(func, t_simulated(i:i+1)', x, odeoptions);
                tend = t_simulated(i+1);

                while sol.x(end) < tend && (options.do_retry || ~reporter.reset)
                    t_now = datetime();
                    r = @(t, y, flag) reporter.report(t, y, flag, options.reset_time, t_now);
                    odeoptions = odeset(odeoptions, 'OutputFcn', r);
                    sol = odextend(sol, [], tend, sol.y(:,end),odeoptions);
                end
                y = sol.y(:, end);
                V = y(nx+(1:numel(idx_simulated_bus)));
                x0 = y(1:nx);
                V0 = Ymat_reproduce*V;
                I0 = Ymat_all * V0;
                sols{i} = sol;
                X = sol.y(1:nx, :)';
                V = sol.y(nx+(1:nV), :)'*Ymat_reproduce';
                I = V*Ymat_all';
                ifault = [f_(:)*2-1, f_(:)*2]';
                I(:, ifault(:)) = sol.y(nx+nV+(1:nI), :)';
                out_X{i} = X;
                out_V{i} = V;
                out_I{i} = I;
            end

            out.t = tools_vcellfun(@(sol) sol.x(:), sols);
            X_all = vertcat(out_X{:});
            V_all = vertcat(out_V{:});
            I_all = vertcat(out_I{:});
            out.X = cell(numel(obj.a_bus), 1);
            out.V = tools_arrayfun(@(i) V_all(:, i*2-1:i*2), 1:numel(obj.a_bus));
            out.I = tools_arrayfun(@(i) I_all(:, i*2-1:i*2), 1:numel(obj.a_bus));

            idx = 0;
            for i = 1:numel(obj.a_bus)
                out.X{i} = X_all(:, idx+(1:obj.a_bus{i}.get_nx()));
                idx = idx + obj.a_bus{i}.get_nx();
            end

            for i=1:numel(obj.a_controller_global)
                out.Xk_global{i} = X_all(:, idx+(1:obj.a_controller_global{i}.get_nx()));
                idx = idx + obj.a_controller_global{i}.get_nx();
            end

            for i=1:numel(obj.a_controller_local)
                out.Xk{i} = X_all(:, idx+(1:obj.a_controller_local{i}.get_nx()));
                idx = idx + obj.a_controller_local{i}.get_nx();
            end

            U_bus = tools_arrayfun(@(i) zeros(numel(out.t), bus{i}.get_nu()), 1:numel(bus));
            U_bus0 = tools_arrayfun(@(i) zeros(numel(out.t), bus{i}.get_nu()), 1:numel(bus));

            out.U_global = cell(numel(obj.a_controller_global), 1);

            for i = 1:numel(obj.a_controller_global)
                c = obj.a_controller_global{i};
                out.U_global{i} = c.get_input_vectorized(out.t, out.Xk_global{i}, out.X(c.index_observe), out.V(c.index_observe),...
                    out.I(c.index_observe), U_bus0(c.index_observe));

                idx = 0;
                for j = 1:numel(c.index_input)
                    nu = size(U_bus{j}, 2);
                    U_bus{j} = U_bus{j} + out.U_global{i}(:, idx+(1:nu));
                    idx = idx + nu;
                end
            end

            out.U = cell(numel(obj.a_controller_local), 1);
            for i = 1:numel(obj.a_controller_local)
                c = obj.a_controller_local{i};
                out.U{i} = c.get_input_vectorized(out.t, out.Xk{i}, out.X(c.index_observe), out.V(c.index_observe),...
                    out.I(c.index_observe), U_bus(c.index_observe));
            end

            out.sols = sols;
            out.linear = linear;
        end

        function [Y_reduced, Ymat_reduced, A_reproduce, Amat_reproduce]...
                = reduce_admittance_matrix(obj, Y, index)
            n_bus = size(Y, 1);
            reduced = false(n_bus, 1);
            reduced(setdiff(1:n_bus, index)) = true;

            Y11 = Y(~reduced, ~reduced);
            Y12 = Y(~reduced, reduced);
            Y21 = Y(reduced, ~reduced);
            Y22 = Y(reduced, reduced);

            Y_reduced = Y11 - Y12/Y22*Y21;
            Ymat_reduced = tools_complex2matrix(Y_reduced);

            A_reproduce = zeros(n_bus, sum(~reduced));
            A_reproduce(~reduced, :) = eye(sum(~reduced));
            A_reproduce(reduced, :) = -Y22\Y21;
            Amat_reproduce = tools_complex2matrix(A_reproduce);
        end
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
    for itr = 1:numel(eq_consts)
        eq_consts{itr} = bus{itr}.get_constraint(Vr(itr), Vi(itr), Phat(itr), Qhat(itr));
    end
    out = vertcat(eq_consts{:});
end

function t_simulated = get_t_simulated(t_cand, uf, fault_f)
    has_difference = true(numel(t_cand)-1, 1);
    u = nan;
    f = nan;
    for i = 1:numel(t_cand)-1
        unew = uf((t_cand(i)+t_cand(i+1))/2);
        fnew = fault_f((t_cand(i)+t_cand(i+1))/2);
        if any(unew~=u) || numel(f) ~= numel(fnew) || any(fnew~=f)
            u = unew;
            f = fnew;
        else
            has_difference(i) = false;
        end
    end

    t_simulated = t_cand([has_difference; true]);
end

function f = idx2f(fault_time, idx_fault)
    if isempty(fault_time)
        f = @(t) [];
    else
        if ~iscell(fault_time)
            f = @(t) select_value((fault_time(1)<=t && t<fault_time(2)), idx_fault, []);
        else
            fs = cellfun(@idx2f, fault_time, idx_fault, 'UniformOutput', false);
            f = @(t) f_tmp(t, fs);
        end
    end
end

function idx = f_tmp(t, fs)
    idx = [];
    for itr = 1:numel(fs)
        idx = [idx; fs{itr}(t)]; %#ok
    end

    idx = unique(idx);
end

function out = select_value(isA, A, B)
    if isA
        out = A;
    else
        out = B;
    end
end

function f = sample2f(t, u)
    if isempty(u) || size(u, 2)==0
        f = @(t) [];
    else
        if size(u, 1) ~= numel(t) && size(u, 2) == numel(t)
            u = u';
        end
        f = @(T) u(find(t<=T, 1, 'last'),:)';
    end
end