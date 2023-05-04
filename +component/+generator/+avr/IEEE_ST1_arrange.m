classdef IEEE_ST1_arrange < component.generator.avr.base
% モデル  ：IEEE_ST1モデル 
%親クラス：avrクラス
%実行方法：avr_IEEE_ST1(avr_tab)
%　引数　：・avr_tab：テーブル型の変数。「't_tr', 'k_ap','k0','gamma_max','gamma_min'」を列名として定義
%　出力　：avrクラスの変数

    properties
        parameter
        Vref
        k_ap
        t_tr
        t_ap
        k0
        gamma_max
        gamma_min
    end


    properties(Access=private)
        func_saturation
        nx = 3;
    end
    
    methods
        function obj = IEEE_ST1_arrange(parameter_table)
            obj.parameter = parameter_table;
            obj.organize_parameter;
        end

        function organize_parameter(obj)
            %% T. Sadamoto, A. Chakrabortty, T. Ishizaki, and J.-i. Imura. 
            % Dynamic modeling, stability, and control of power systems with distributed energy resources:
            % Handling faults using two control methods in tandem. IEEE Control Systems
            % Magazine, Vol. 39, No. 2, pp. 34–65, 2019 %%
            var_names                 = {'Ttr', 'Tap', 'Kap', 'gamma_max', 'gamma_min', 'K0','Tst', 'Kst'};
            default_para = array2table( [    0,  0,05,    20,         inf,        -inf,    0,    0,     0], 'VariableNames',var_names); 
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            var_para  = obj.parameter.Properties.VariableNames;
            var       = intersect(var_names,var_para);
            default_para(1,var) = obj.parameter(1,var);
            obj.parameter       = default_para;
        end
        
        function name_tag = get_state_name(obj)
            name_tag = {'Vfd'};
        end
        
        function nx = get_nx(obj)
            nx = obj.nx;
        end
        
        function x = initialize(obj, Vfd, V)
            obj.Vref = Vfd/obj.k_ap + V;
            x = V;
            obj.get_sys;

            gmin = obj.parameter{1,'gamma_max'};
            gmax = obj.parameter{1,'gamma_min'};
            K0   = obj.parameter{1,'K0'};
            switch isinf(gmax) + 2*isinf(gmin)
                case 0
                    obj.func_saturation = @(Vap,Vabs,Ifield) min( max(Vap, Vabs*gmin), Vabs*gmax-Ifield*K0);
                case 1
                    obj.func_saturation = @(Vap,Vabs,Ifield) max(Vap, Vabs*gmin);
                case 2
                    obj.func_saturation = @(Vap,Vabs,Ifield) min( Vap, Vabs*gmax-Ifield*K0);
                case 3
                    obj.func_saturation = @(Vap,Vabs,Ifield) Vap;
            end
        end
        
        function [dV_tr, Vfd, V_ap] = get_Vfd(obj, V_tr, Vabs, Efd, Vpss)
            dV_tr = (Vabs-V_tr)/obj.t_tr;
            V_ap = obj.k_ap*(obj.Vref+Vpss-V_tr);
            
            Vfd = obj.func_saturation(V_ap,Vabs,0);
        end
        
        function [dV_tr, Vfd, V_ap] = get_Vfd_linear(obj, V_tr, Vabs, Efd, u)
            [dV_tr, Vfd, V_ap] = get_Vfd(obj, V_tr, Vabs, Efd, u);
        end
        
        function [A, B, C, D] = get_linear_matrix(obj)
            if isempty(obj.sys)
                obj.get_sys;
            end
            A = obj.sys.A;
            B = obj.sys.B;
            C = obj.sys.C;
            D = obj.sys.D;
        end
        
        function sys = get_sys(obj)
            Ttr = obj.parameter{1,'Ttr'};
            Tap = obj.parameter{1,'Tap'};
            Kap = obj.parameter{1,'Kap'};
            %K0  = obj.parameter{1,'K0' };
            Tst = obj.parameter{1,'Tst'};
            Kst = obj.parameter{1,'Kst'};

            [Atr,Btr,Ctr,Dtr] = tf2ss(   1, [Ttr,1] );
            sys_tr = ss([Atr,Btr,Ctr,Dtr]);
            sys_tr.InputGroup.Vabs = 1;
            sys_tr.OutputGroup.Vtr = 1;

            sys_comparator = ss([1,1,-1,-1]);
            sys_comparator.InputGroup.Vref = 1;
            sys_comparator.InputGroup.Vpss = 2;
            sys_comparator.InputGroup.Vtr  = 3;
            sys_comparator.InputGroup.Vst  = 4;
            sys_comparator.OutputGroup.Vcom = 1;

            [Aap,Bap,Cap,Dap] = tf2ss( Kap, [Tap,1] );
            sys_ap = ss([Aap,Bap,Cap,Dap]);
            sys_ap.InputGroup.Vcom = 1;
            sys_ap.OutputGroup.Vap = 1;

            [Ast,Bst,Cst,Dst] = tf2ss( Kst, [Tst,1] );
            sys_st = ss([Ast,Bst,Cst,Dst]);
            sys_st.InputGroup.Vap  = 1;
            sys_st.OutputGroup.Vst = 1;


            G = blkdiag(sys_tr,sys_comparator,sys_ap,sys_st);
            ig = G.InputGroup;
            og = G.OutputGroup;
            feedin  = [ig.Vtr, ig.Vst, ig.Vcom, ig.Vap];
            feedout = [og.Vtr, og.Vst, ig.Vcom, ig.Vap];
            
            sys = feedback(G, eye(4), feedin, feedout, 1);


            A = -1/obj.t_tr;
            B = [1 0 0]/obj.t_tr;
            C = -obj.k_ap;
            D = [0 0 1]*obj.k_ap;

            sys = ss(A,B,C,D);
            sys.InputGroup.Vabs = 1;
            sys.InputGroup.Efd = 2;
            sys.InputGroup.u_avr = 3;
            sys.OutputGroup.Vfd = 1;
            obj.sys = sys;
        end
        
    end
end

function out = sat(x, x_min, x_max)
out = max(x, x_min);
out = min(out, x_max);
end
