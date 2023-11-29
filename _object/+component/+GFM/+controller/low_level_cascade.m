classdef low_level_cascade < component.GFM.controller.AbstractClass

    methods
        function obj = low_level_cascade(para)
            if nargin==0
                para = readtable([mfilename("fullpath"),'.csv']);
            end
            obj.parameter = para;
        end

        function nx = get_nx(~)
            nx = 4;
        end

        function nu = get_nu(~)
            nu = 0;
        end

        function tag = naming_state(~)
            tag = {'xv_d','xv_q','xi_d','xi_q'};
        end

        function tag = naming_port(~)
            tag = [];
        end


        function [dx,m] = get_dx_mdq(obj, t, x, u, vdq, idq, isdq, vdq_hat, omega)%#ok
            x_vdq = x(1:2);
            x_idq = x(3:4);
            
            p  = obj.parameter;
            pc = obj.params_converter;

            
            %1. AC voltage control
            dx_vdq = vdq_hat - vdq;
            isdq_st = idq + pc.C * omega * [0, -1; 1, 0] * vdq + p.Kv_p * eye(2) * (vdq_hat - vdq) + p.Kv_i * eye(2) * x_vdq;

            %2. AC current limitation
            Inorm = norm(isdq);
            if Inorm > p.iac_max
                isdq_st = isdq_st *(p.iac_max/Inorm);
            end

            %3. AC current control
            dx_idq = isdq_st - isdq;
            vsdq_st = vdq + (pc.R * eye(2) + pc.L * omega * [0, -1; 1, 0]) * isdq + p.Ki_p * eye(2) * (isdq_st - isdq) + p.Ki_i * eye(2) * x_idq;

            %4. Modulation
            m = 2 * vsdq_st / obj.params_dc_source.vdc_st;

            dx = [dx_vdq; dx_idq];
        end

        function [xst,ust,mdq] = set_equilibrium(obj,vdq,isdq,omega,flag)
            xst = zeros(4,1);
            ust = [];

            pc = obj.params_converter;
            vsdq_st = vdq + (pc.R * eye(2) + pc.L * omega * [0, -1; 1, 0]) * isdq;
            mdq = 2 * vsdq_st / obj.params_dc_source.vdc_st;

        end

    end

end
