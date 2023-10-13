classdef vsc < handle

    properties
        L_f
        R_f
        C_f
        L_g
        R_g
    end

    methods

        function obj = vsc(vsc_params)
            obj.L_f = vsc_params{:, 'L_f'};
            obj.R_f = vsc_params{:, 'R_f'};
            obj.C_f = vsc_params{:, 'C_f'};
            obj.L_g = vsc_params{:, 'L_g'};
            obj.R_g = vsc_params{:, 'R_g'};
        end

        function nx = get_nx(obj)
            nx = 6;
        end

        function nu = get_nu(obj)
            nu = 0;
        end

        function [d_isdq, d_vdq, d_idq] = get_dx(obj, isdq, idq, omega, vdq, vsdq, Vdq)
            d_isdq = (-(obj.R_f * eye(2) + omega * obj.L_f * [0, -1; 1, 0]) * isdq - vdq + vsdq) / obj.L_f;
            d_vdq =  (-obj.C_f * omega * [0, -1; 1, 0] * vdq + isdq - idq) / obj.C_f;
            d_idq = (-(obj.R_g * eye(2) + omega * obj.L_g * [0, -1; 1, 0]) * idq - Vdq + vdq) / obj.L_g;
        end

    end

end
