classdef Delay1order_model < handle

    properties
        parameter  % P_st,vdc_st,idc_max,tau_dc,Kdc,R_dc 
        P_st
    end

    methods

        function obj = Delay1order_model(params)
            if nargin==0
                params = readtable([mfilename("fullpath"),'.csv']);
            end
            obj.parameter = params(:,{'vdc_st','idc_max','tau_dc','Kdc','Gdc','Cdc'});
        end

        function nx = get_nx(~)
            nx = 2;
        end

        function nu = get_nu(~)
            nu = 0;
        end

        function tag = naming_state(~)
            tag = {'vdc','i_t'};
        end

        function tag = naming_port(~)
            tag = [];
        end

        function [dx,vdc] =  get_dx_vdc(obj, ~, x, ~, v_dq, i_dq, ix)
            
            vdc = x(1);
            i_t = x(2);
            p = obj.parameter;

            Power = v_dq.'*i_dq;

            % DC Voltage Control
                idc_st =   p.Kdc * (p.vdc_st - vdc) ...
                         + (obj.P_st/p.vdc_st) + (p.Gdc*vdc) + ((vdc*ix - Power) / p.vdc_st);

            % DC Energy Source Model
                di_t = (idc_st - i_t) / p.tau_dc;

                if abs(i_t) >= abs(p.idc_max)
                    idc = sign(i_t)*p.idc_max;
                else
                    idc = i_t;
                end

            % Converter
                dvdc = (idc - p.Gdc*vdc - ix ) / p.Cdc; 

            dx = [dvdc;di_t];
        end
        
        function [xst,ust] = set_equilibrium(obj,V,I,ix,flag)
            if strcmp(flag,'init')
                obj.P_st = V.' * I;
            end

            p = obj.parameter;
            it_st = p.vdc_st*p.Gdc + ix;
            

            xst = [p.vdc_st;it_st];
            ust = [];
        end
    end

end