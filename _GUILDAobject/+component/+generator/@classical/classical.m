classdef classical < component.generator.abstract

    properties (Constant)      
        key      = "gen-classical";
        str_x    = ["delta";"omega"];        
        str_u    = ["Pmech";"Vfield"];        
        str_y    = ["omega";"Efd";"Vabs"];        
        str_para = ["M","D","Xd","Xq"]        
    end
    

    methods        
        function set_odefcn(obj, omega0)                                
            tab_para = obj.tab_parameter;      
            array    = tab_para.dynamics{:,obj.str_para};
            
            obj.JacobiAxx = @(t, x, V, u) getJacobiAxx(t, x, V, u, array, omega0);
            obj.JacobiBxv = @(t, x, V, u) getJacobiBxv(t, x, V, u, array, omega0);
            obj.JacobiBxu = @(t, x, V, u) getJacobiBxu(t, x, V, u, array, omega0);
            
            obj.JacobiCix = @(t, x, V, u) getJacobiCix(t, x, V, u, array, omega0);
            obj.JacobiDiv = @(t, x, V, u) getJacobiDiv(t, x, V, u, array, omega0);         
            obj.JacobiDiu = @(t, x, V, u) getJacobiDiu(t, x, V, u, array, omega0);         

            obj.rm_odeMass = @(t, x, V, u) obj.fcn_Mass(t, x, V, u, array, omega0);
            obj.fv_odeDiff = @(t, x, V, u) obj.fcn_dx(t, x, V, u, array, omega0);
            obj.fv_odeI    = @(t, x, V, u) obj.fcn_I(t, x, V, u, array, omega0);
        end
        
        [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj, c_V, c_I)
    end        

    methods
        dx = fcn_dx(obj, t, x, V, u, param, omega0)
        I  = fcn_I(obj, t, x, V, u, param, omega0)
        M  = fcn_Mass(obj, t, x, V, u, param, omega0)
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

            Ax = obj.JacobiA(t, xst, Vst, ust);
            Bv = obj.JacobiB(t, xst, Vst, ust);
            Cx = obj.JacobiC(t, xst, Vst, ust);
            Dv = obj.JacobiD(t, xst, Vst, ust);                   

            Bu = [zeros(1,2);[0,1]];
            Du =  zeros(2,2);

            sys = ss(Ax, [Bv,Bu], Cx, [Dv,Du]);

            for i=1:numel(obj.str_x)                
                StateName = arrayfun(@(n) char(n+"_"+obj.str_tag), obj.str_x, 'UniformOutput', false);
            end

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

            % InputName = obj.attach_tag([["Vre";"Vim"]; obj.str_u]);
            % for i=1:numel(InputName)
            %     InputGroup.(InputName(i)) = i;       
            % end
            % 
            % OutputName = obj.attach_tag(["Ire";"Iim"]);
            % for i=1:numel(OutputName)
            %     OutputGroup.(OutputName(i)) = i;       
            % end
            
            sys.StateName   = StateName;
            sys.InputGroup  = InputGroup;
            sys.InputName   = InputName;
            sys.OutputGroup = OutputGroup;   
            sys.OutputName  = OutputName;            

            Ax = sys.A;
            Bv = sys.B(:,1:2);
            Bu = sys.B(:,3:4);
            Cx = sys.C;
            Dv = sys.D(:,1:2);
            Du = sys.D(:,3:4);

            obj.odeLinearSystem = sys;
        end                       
    end
end