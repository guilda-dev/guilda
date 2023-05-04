classdef odefunc_factory < handle
    
    properties
        % n_hoge はhogeの個数を指すスカラーを格納
        % l_hoge はhogeのインデックスをtrueとするlogical配列を格納
        % i_hoge はhogeのインデクス番号のdouble配列を格納
        % f_hoge は関数ハンドルを格納したcell配列

        %入力データ
        linear   = false;
        i_input  = [];
        i_fault  = [];


        % local controller の制御入力を加えるか決定するバイナリ変数
        consider_dynamic_local_controller  = true;

        % glabal controller の制御入力を加えるか決定するバイナリ変数
        consider_dynamic_global_controller = true;

        % 解列された機器の状態発展を計算し続けるか決定するバイナリ変数
        consider_dynamic_unlink_component  = true;

        % 他クラスの各種処理用に状態を格納しておくクラス
        StateHolder = [];

    end

    properties(Access=private)
    %% simulate中の計算量軽減のための一時保存データ %%

        % 頻繁に呼び出されるデータ
            power_network
            n_bus
            n_br
            n_cl
            n_cg

            zeros_u
            l_nonunit
            l_Vvirtual_unlink 

            % 状態の個数をlogical配列で格納したもの
                cl_xmac_all
                cl_xcl_all
                cl_xcg_all

        % simulationの条件設定によって決定されるデータ
            % odeソルバーで扱う状態xと各機器の変数の対応関係を記述
                l_xmac_simulated
                l_xcl_simulated
                l_xcg_simulated
                l_Vall_simulated
                l_Ibus_fault
                l_constraint
                l_input
                nX
            % simulation中に各要素の扱いを判別するための変数
                i_simulated_mac
                i_simulated_bus
                i_simulated_cl
                i_simulated_cg
            % アドミタンス行列
                Ymat
                Ymat_all
                Ymat_reproduce
                
    end

    methods
        function obj = odefunc_factory(net, linear, Holder)
            arguments
                net
                linear = false;
                Holder = []
            end
            obj.power_network = net;
            obj.linear = linear;

            obj.n_bus = numel(net.a_bus);
            obj.n_br  = numel(net.a_branch);
            obj.n_cl  = numel(net.a_controller_local);
            obj.n_cg  = numel(net.a_controller_global);

            if linear
                for i = 1:obj.n_cg
                    c = net.a_controller_global{i};
                    c.get_dx_u_func = @c.get_dx_u_linear;
                end
                for i = 1:obj.n_cl
                    c = net.a_controller_local{i};
                    c.get_dx_u_func = @c.get_dx_u_linear;
                end
                for i = 1:obj.n_bus
                    c = net.a_bus{i}.component;
                    c.get_dx_con_func = @c.get_dx_constraint_linear;
                end
            else
                for i = 1:obj.n_cg
                    c = net.a_controller_global{i};
                    c.get_dx_u_func = @c.get_dx_u;
                end
                for i = 1:obj.n_cl
                    c = net.a_controller_local{i};
                    c.get_dx_u_func = @c.get_dx_u;
                end
                for i = 1:obj.n_bus
                    c = net.a_bus{i}.component;
                    c.get_dx_con_func = @c.get_dx_constraint;
                end
            end

            nx   = @(i) net.a_bus{i}.component.get_nx; 
            obj.cl_xmac_all = tools.arrayfun(@(i) true(nx(i),1), 1:obj.n_bus);
            
            nx   = @(i) net.a_controller_local{i}.get_nx; 
            obj.cl_xcl_all  = tools.arrayfun(@(i) true(nx(i),1), 1:obj.n_cl);

            nx   = @(i) net.a_controller_global{i}.get_nx; 
            obj.cl_xcg_all  = tools.arrayfun(@(i) true(nx(i),1), 1:obj.n_cg);

            obj.zeros_u     = tools.cellfun(@(b) zeros(b.component.get_nu,1), net.a_bus);
            obj.l_nonunit   = tools.hcellfun(@(b) contains(class(b.component),{'component_empty','component.empty'}), net.a_bus);

            if ~isempty(Holder)
                obj.StateHolder = Holder;
            end
        end

        function [lx,lxcl,lxcg,lu] = get_state_idx(obj)
            lx  = blkdiag(obj.cl_xmac_all{:});
            lxcl= blkdiag(obj.cl_xcl_all{:});
            lxcg= blkdiag(obj.cl_xcg_all{:});
            lu  = obj.l_input;
        end
        
        function [lx,lxcl,lxcg] = get_state_simulated_idx(obj)
            lx   = obj.l_xmac_simulated;
            lxcl = obj.l_xcl_simulated;
            lxcg = obj.l_xcg_simulated;
        end

        function [Ymat_all,Ymat_reproduce] = get_Ymat_reproduce(obj)
            Ymat_reproduce = obj.Ymat_reproduce;
            Ymat_all = obj.Ymat_all;
        end

        % シミュレーションを開始する前に予め計算しておける変数を計算するメソッド
            MassMatrix = SimulationSetting(obj, idx_fault, idx_input)

        % ode15sの出力結果"y"から各構成要素ごとの状態に分解・整理する
            [Xmac, Xcl, Xcg, Vall, Iall, Vvirtual] = reshape_odeX2allX( obj, ode_X)

        % reshape_odeX2allXの逆．odeソルバーに投げる初期値の計算に使用
            [x0,const0] = reshape_allX2initX( obj, x, xcl, xcg, V, I, Vvirtual)
            
        % odeソルバーに代入する微分方程式
            dx = fx(obj, t, x, u)

    end

end