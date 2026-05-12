classdef power < component.load.abstract
    
    properties
        PQ_st
    end

    properties(Constant)
        key      = "load-power";
        str_x    = [];
        str_u    = ["Pload","Qload"];
        str_y    = [];
        str_para = [];
        Prefix = "LP";
    end

    methods(Access={?Bus})
        function obj = power(index, ~, varargin)
            obj@component.load.abstract("PQ"+index, varargin{:})
        end
    end

    methods        
        set_odefcn(obj,omega0)
    end
    
    methods
        [cv_Xequilibrium, cv_Uequilibrium]  = get_equilibrium(obj, c_V, c_I);    
    end

    methods
        dx = fcn_dx(obj, t, x, V, I, u, para);
        I  = fcn_I(obj, t, x, V, I, u, para);
        y  = fcn_Y(obj, t, x, V, I, u, para);
        M  = fcn_Mass(obj, t, x, V, I, u, para);
    end

    methods       
        function [Ax, Bv, Bu, Cx, Dv, Du] = getLinearSystem(obj, t, xst, Vst, ust)         

            arguments
                obj                 
                t   (1,1) double = 0;
                xst (:,1) double = obj.cv_Xequilibrium
                Vst (:,1) double = [real(obj.parent.c_Vequilibrium); imag(obj.parent.c_Vequilibrium)]
                ust (:,1) double = obj.cv_Uequilibrium
            end

            Dv   = obj.JacobiD(t, xst, Vst, ust);                                           
            Vabs = abs([1,1j]*Vst);
            Du   = [Vst(1)/Vabs^2,  Vst(2)/Vabs^2;
                    Vst(2)/Vabs^2, -Vst(1)/Vabs^2];

            sys = ss([Dv,Du]);            

            str_i = [["Vre";"Vim"]; obj.str_u];
            for i=1:numel(str_i)
                InputGroup.(str_i(i)+"_"+obj.str_tag) = i;                    
                InputName = arrayfun(@(n) char(n+"_"+obj.str_tag), str_i, 'UniformOutput', false);
            end

            str_o = ["Ire";"Iim"];
            for i=1:numel(str_o)
                OutputGroup.(str_o(i)+"_"+obj.str_tag) = i;                    
                OutputName = arrayfun(@(n) char(n+"_"+obj.str_tag), str_o, 'UniformOutput', false);
            end
                        
            sys.InputGroup  = InputGroup;
            sys.InputName   = InputName;
            sys.OutputGroup = OutputGroup;   
            sys.OutputName  = OutputName;            

            Ax = [];
            Bv = [];
            Bu = [];
            Cx = [];
            Dv = sys.D(:,1:2);
            Du = sys.D(:,3:4);

            obj.odeLinearSystem = sys;
        end                           
    end
end
