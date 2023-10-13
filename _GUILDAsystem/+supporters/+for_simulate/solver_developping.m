classdef solver_developping < handle
    
    properties
        time
        network

        ToBeStop
    end

    properties(SetAccess=protected)
        a_component
        a_controller_local
        a_controller_global
    end


    properties(Dependent)
        options
    end


    properties(Access=private)
        factory_options
        factory_simulation
    end

    
    methods

        function obj = solver_developping(net, t, varargin)
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

        function build_unit(obj)
            lin = obj.options.linear;
            
            func = @(a_data) tools.arrayfun(@(i) supporters.for_simulate.obj_unit(a_data{i},obj,i,lin), (1:numel(c))' );
            
            a_comp = tools.cellfun(@(b) b.component, obj.network.a_bus);
            obj.a_component = func(a_comp);
            obj.a_controller_local  = func(obj.network.a_controller_local );
            obj.a_controller_global = func(obj.network.a_controller_global);
        end


        function op = get.options(obj)
            op = obj.factory_options.options;
        end

        function set.options(obj,data)
            obj.factory_options.options = data;
            obj.factory_options.initialize;
        end


        function f = EventFcn(obj,varargin)
            f = obj.ToBeStop;
            if obj.ToBeStop
                obj.ToBeStop=true;
            end
        end


        function out = run(obj)

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
        
            %データを予め格納
            stash.num.bus= numel(net.a_bus);
            stash.num.cl = numel(net.a_controller_local);
            stash.num.cg = numel(net.a_controller_global);
            stash.utemp  = tools.arrayfun(@(i) zeros(net.a_bus{i}.component.get_nu,1),nbus);
        

            tlast = obj.time(1);
            while tlast < obj.time(end)
        
                tlist = obj.option.get_all_time;

                t0   = tlast;
                tend = tlist(find(tlist>t,1,"first"));
                

        
                % build DAE
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

end


        
function dconst = get_const(f,t,x0,const,idx)
    dx = f(t,[x0;const]);
    dconst = dx(idx);
end


