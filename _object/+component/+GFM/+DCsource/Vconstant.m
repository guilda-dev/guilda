classdef Vconstant < handle

    properties
        parameter  % P_st,vdc_st,idc_max,tau_dc,k_dc,R_dc
    end

    methods

        function obj = Vconstant(params)
            if nargin==0
                c = class(obj);
                idx = find(c=='.',1,"last");
                params = eval([c(1:idx),'params.',c(idx+1:end),'();']);
            end
            obj.parameter = params(:,'vdc_st');
        end

        function nx = get_nx(~)
            nx = 0;
        end

        function nu = get_nu(~)
            nu = 0;
        end

        function tag = naming_state(~)
            tag = [];
        end

        function tag = naming_port(~)
            tag = [];
        end

        function [dx,vdc] =  get_dx_vdc(obj, varargin)
            dx  = [];
            vdc = obj.parameter.vdc_st;
        end

        function [xst,ust] = set_equilibrium(varargin)
            xst = [];
            ust = [];
        end
    end

end