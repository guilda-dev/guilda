classdef solver < handle
    
    properties
        time
        network

         additional_V0bus
         additional_I0bus
         additional_odeopt = {};
    end


    properties(Dependent)
        options
    end


    properties(Access=private)
        factory_options
        factory_simulation
    end

    
    methods

        function obj = solver(net, t, varargin)
            obj.time = [t(1),t(end)];
            obj.network  = net;

            if nargin < 3 || isstruct(varargin{1}) || ischar(varargin{1})
                op = supporters.for_simulate.Factory_Option(obj.time,net,varargin{:});
            else
                op = supporters.for_simulate.Factory_Option(obj.time,net,varargin{3:end});
                udata = struct;
                udata.time   = t;
                udata.index  = varargin{1};
                udata.u      = varargin{2};
                udata.method = op.options.method;
                if isstruct(op.options.u)
                    op.options.u(end+1) = udata;
                else
                    op.options.u = udata;
                end
            end
            obj.factory_options = op;
        end    

        function op = get.options(obj)
            op = obj.factory_options.options;
        end
        function set.options(obj,data)
            obj.factory_options.options = data;
            obj.factory_options.initialize;
        end

        function out = run(obj)

            % 各component classの'get_dx_con_func'に関数を代入
            obj.set_function;
            % optionデータから各データを処理するクラスを定義主に'fault,parallel,input'）
            obj.factory_options.initialize;
            % Factory_Optionsクラスから、時刻インデックスを整理したデータを取得
            tlist = obj.factory_options.timelist;

            net = obj.network;
            nbus = (1:numel(net.a_bus))';
        
            % Factory_Optionsクラスから、初期値のデータを取得
            [x0sys,x0cl,x0cg,V0,I0,V0vir] = obj.factory_options.get_initialVal();
            % get_V0busとget_I0busは「f=@(t)」型のfunction_handleクラス。時刻を代入すると地絡条件や並解列条件からbus番号を吐き出す関数
            get_V0bus = obj.factory_options.get_bus('V0const');
            get_I0bus = obj.factory_options.get_bus('I0const');
            % get_ufuncは「f=@([ts,te])」型のfunction_handleクラス。時刻の範囲を設定するとその間の入力データを吐き出す関数
            get_ufunc = obj.factory_options.get_ufunc();

            % 頻繁に必要となるnetwork内のインデックスを整理するmethodを一通り備えたクラス
            tool = supporters.for_netinfo.organizer_net_index(net,true);
            % whileループ中で各フェーズで計算されたodeの結果を整理してデータを格納しておくmethodを備えたクラス。
            storage = supporters.for_simulate.Factory_odeData(net);
            % 制約項の初期値を計算する際のfsolveのoptionあを予め定義
            optimoption = optimoptions('fsolve', 'MaxFunEvals', inf, 'MaxIterations', 100, 'Display','none');%'iter-detailed');
        
            % whileループで用いるインデックス
            phase     = 0;              % 現在のフェーズ番号
            num_phase = numel(tlist)-1; % 全フェース数
            go_next   = true;           % フェーズが終了したかの判別バイナリ、Events等で中断した際は、条件設定を変えて同一のフェーズで再ループする必要がある。
        
            %データを予め格納
            stash.num.bus= numel(net.a_bus);
            stash.num.cl = numel(net.a_controller_local);
            stash.num.cg = numel(net.a_controller_global);
            stash.utemp  = tools.arrayfun(@(i) zeros(net.a_bus{i}.component.get_nu,1),nbus);
        

            while phase < num_phase
        
                % switch phase
                if go_next
                    phase   = phase + 1;
                    go_next = false;
                    t0   = tlist(phase);
                    tend = tlist(phase+1);
                end
        
        
                % build DAE
                %stash.idx_V0const = get_V0bus(t0);
                %stash.idx_I0const = get_I0bus(t0);
                stash.idx_V0const = union( get_V0bus(t0), obj.additional_V0bus);
                stash.idx_I0const = union( get_I0bus(t0), obj.additional_I0bus);
                stash.ufunc = get_ufunc([t0,tend]);
                stash.no_reduced_bus  = union(setdiff(tool.get_i,stash.idx_I0const(:)'),stash.idx_V0const(:)');
                [Y,Yall] = net.get_admittance_matrix;
                [~,stash.Yred,~, mat_reproduce]= net.reduce_admittance_matrix(Y, stash.no_reduced_bus);
                stash.simulated_bus = union(tool.get_i,stash.idx_V0const(:)');
                stash.simulated_cl  = tool.get_ic('local' );
                stash.simulated_cg  = tool.get_ic('global');
                stash.logimat = logical(...
                                blkdiag( tool.logimat_x   ,...
                                         tool.logimat_xcl ,...
                                         tool.logimat_xcg ,...
                                         true(2*numel(stash.no_reduced_bus),1) ,...
                                         true(2*numel(stash.idx_V0const)   ,1) ,...
                                         true(2*numel(stash.idx_I0const)   ,1) ));
                func = @(t,x) supporters.for_simulate.fx(t,x,net,stash);
                
                
        
                % calsulate initial value of constraint
                storage.setidx(tool,mat_reproduce,Yall,stash.no_reduced_bus,stash.idx_I0const,stash.idx_V0const);
                [x0,const0] = storage.get_x0(x0sys,x0cl,x0cg,V0,I0,V0vir);
                constfunc   = @(var) get_const(func,t0,x0,var,[false(size(x0));true(size(const0))]);
                const0 = fsolve(constfunc, const0, optimoption);
        

                % solve DAE
                Msys = tools.darrayfun(@(i) obj.network.a_bus{i}.component.Mass, stash.simulated_bus);
                Mcl  = tools.dcellfun( @(c) c.Mass, obj.network.a_controller_local );
                Mcg  = tools.dcellfun( @(c) c.Mass, obj.network.a_controller_global);
                Mcon = zeros( numel(const0), numel(const0) );
                Mass = blkdiag(Msys,Mcl,Mcg,Mcon);
                odeopt = obj.factory_options.get_odeoption('Mass',Mass,obj.additional_odeopt{:});
                % odeopt = obj.factory_options.get_odeoption('Mass',Mass);
                sol = ode15s(func, [t0,tend], [x0;const0], odeopt);
        

                % save data & The final value of the simulation is set as the initial value for the next phase of the simulation.
                [x0sys,x0cl,x0cg,V0,I0,V0vir] = storage.add_data(sol);
        
                if sol.x(end)==tend
                    go_next=true; 
                else
                    t0 = sol.x(end);
                end
            end
        
        
            tool.ignore(false)
            lx =  tool.logimat_x;
            lcl = tool.logimat_xcl;
            lcg = tool.logimat_xcg;
            
            out = struct();
            out.t = storage.t;
            out.V = tools.arrayfun(@(i) storage.V(2*i+[-1,0],:).' , nbus);
            out.I = tools.arrayfun(@(i) storage.I(2*i+[-1,0],:).' , nbus);
            out.X = tools.arrayfun(@(i) storage.x(lx(:,i),:).' , nbus);
            
            out.Xcon = struct('local',[],'global',[]);
            if stash.num.cl~=0
                out.Xcon.local = tools.arrayfun(@(i) storage.xcl(lcl(:,i),:).' , 1:stash.num.cl);
            end
            if stash.num.cg~=0
                out.Xcon.global = tools.arrayfun(@(i) storage.xcg(lcg(:,i),:).' , 1:stash.num.cg);
            end

            out.Ucon = struct('local',[],'global',[]);
            out.Ucon.local     = cell(numel(net.a_controller_local), 1);
            out.Ucon.global    = cell(numel(net.a_controller_global), 1);
            U_bus  = tools.arrayfun(@(i) zeros(numel(out.t), net.a_bus{i}.component.get_nu()), nbus);
            U_bus0 = tools.arrayfun(@(i) zeros(numel(out.t), net.a_bus{i}.component.get_nu()), nbus);
            for i = 1:numel(net.a_controller_global)
                c = net.a_controller_global{i};
                out.Ucon.global{i}  = c.get_input_vectorized(out.t, out.Xcon.global{i}, out.X(c.index_observe), out.V(c.index_observe),out.I(c.index_observe), U_bus0(c.index_observe));
                
                idx = 0;
                for j = 1:numel(c.index_input)
                    nu = size(U_bus{j}, 2);
                    U_bus{j} = U_bus{j} + out.Ucon.global{i}(:,idx+(1:nu));
                    idx = idx + nu;
                end
            end
        
            for i = 1:numel(net.a_controller_local)
                c = net.a_controller_local{i};
                out.Ucon.local{i}   = c.get_input_vectorized(out.t,out.Xcon.local{i}, out.X(c.index_observe), out.V(c.index_observe),out.I(c.index_observe), U_bus(c.index_observe));
            end

            out.option.data = obj.options;
            out.option.fault = obj.factory_options.branch_fault;
            out.option.input = obj.factory_options.branch_input;
            out.option.pallalel.component         = obj.factory_options.branch_parallel_mac;
            out.option.pallalel.local_controller  = obj.factory_options.branch_parallel_cl;
            out.option.pallalel.global_controller = obj.factory_options.branch_parallel_cg;

            
        end
    end

    methods(Access=private)


        function set_function(obj)

            net = obj.network;
        
            if obj.options.linear
                for i = 1:numel(net.a_controller_global)
                    c = net.a_controller_global{i};
                    c.get_dx_u_func = @c.get_dx_u_linear;
                end
                for i = 1:numel(net.a_controller_local )
                    c = net.a_controller_local{i};
                    c.get_dx_u_func = @c.get_dx_u_linear;
                end
                for i = 1:numel(net.a_bus)
                    c = net.a_bus{i}.component;
                    c.get_dx_con_func = @c.get_dx_constraint_linear;
                end
            else
                for i = 1:numel(net.a_controller_global)
                    c = net.a_controller_global{i};
                    c.get_dx_u_func = @c.get_dx_u;
                end
                for i = 1:numel(net.a_controller_local )
                    c = net.a_controller_local{i};
                    c.get_dx_u_func = @c.get_dx_u;
                end
                for i = 1:numel(net.a_bus)
                    c = net.a_bus{i}.component;
                    c.get_dx_con_func = @c.get_dx_constraint;
                end
            end
        end
    end


end


        
function dconst = get_const(f,t,x0,const,idx)
    dx = f(t,[x0;const]);
    dconst = dx(idx);
end


