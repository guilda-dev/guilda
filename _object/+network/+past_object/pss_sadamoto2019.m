classdef pss_sadamoto2019 < component.generator.abstract.SubClass
% クラス名： pss_sadamoto2019
% 親クラス： component.generator.abstract.SubClass
% 実行方法： network.past_object.sadamoto2019(parameter)
%
% 　引数　： parameter>>table型.「'Kpss','Tpss','TL1p','TL1','TL2p','TL2'」を列名として定義
%
%<<モデル概要>>
% T.sadamoto, Dynamic Modeling, Stability, and Control of Power Systems With Distributed Energy Resources: Handling Faults Using Two Control Methods in Tandem, IEEE Control Systems Magazine, 2019.
% 　Kpss, Tpss, TL1p, TL1,  TL2p, TL2
% 　250,  10,   0.07, 0.02, 0.07, 0.02

    properties(SetAccess=protected)
        mode
    end

    methods
        function obj = pss_sadamoto2019(parameter)
            obj@component.generator.abstract.SubClass("PSS")
            if nargin<1
                parameter = struct('Kpss', 250, 'Tpss', 10, 'TL1p', 0.07, 'TL1', 0.02, 'TL2p', 0.07, 'TL2', 0.02);
                obj.parameter = struct2table(parameter);
            else
                obj.parameter = parameter(:,{'Kpss','Tpss','TL1p','TL1','TL2p','TL2'});
            end
        end

        function set_parameter(obj,para)
            flag = para{:,{'Tpss','TL1','TL2'}}~=0;
            obj.mode = array2table(flag,'VariableNames',{'pss','L1','L2'});
        end

        function name_tag = naming_state(obj)
            name = {'xi_pss','xi1','xi2'};
            name_tag = name(obj.mode.Variables);
        end

        function nx = get_nx(obj)
            nx =sum(obj.mode.Variables);
        end

        function [dx, v_pss] = get_dx_u(obj, x_pss, u_pss, omega)%#ok
            sys  = obj.system_matrix;

            dx   = sys.A*x_pss + sys.B*omega;
            v_pss = sys.C*x_pss + sys.D*omega;
        end

        function [x_st, u_st] = get_equilibrium(obj, omega_st)%#ok
            x_st = zeros(3,1);
            x_st = x_st(obj.mode.Variables);
            u_st = [];
        end

        function [A,B,C,D] = get_linear_matrix(obj, x_st, u_st, omega_st)%#ok
                para = obj.parameter{:,{'Kpss','Tpss','TL1p','TL1','TL2p','TL2'}};
                Kpss = para(1);     Tpss = para(2);
                TL1p = para(3);     TL1  = para(4);
                TL2p = para(5);     TL2  = para(6);

                E = diag(1./[Tpss,TL1,TL2]);
                A = E*[  -1, 0, 0;
                        -(Kpss/Tpss)*(1-TL1p/TL1), -1, 0;
                        -(Kpss*TL1p/Tpss/TL1)*(1-TL2p/TL2), (1-TL2p/TL2), -1 ];
                B = -A(:,1);
                C = [-(Kpss/Tpss)*(TL1p/TL1)*(TL2p/TL2), TL2p/TL2, 1];
                D = -C(:,1);
        end
    end

    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
end
