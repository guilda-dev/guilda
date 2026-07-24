classdef (Sealed = true) NewtonRaphsonMethod < auxiliary
% NEWTON_RAPHSON_METHOD provides functionality related to the Newton-Raphson method.
%    NEWTON_RAPHSON_METHOD(Name1, Val1, Names2, Val2, ...) provides functions 
% 　　related to the Newton-Raphson method. It solves the specified equation using the `solve` method.
%
% ODEEVENTSET PROPERTIES
%
% NRMFcn - The Equation to Be Solved [ function handle or sym ]
%    This is the equation to be solved, expressed in the form F(x) = b or F(x) = 0. 
%    Specify it using a function handle or a symbolic expression. If the user 
%    does not specify this variable, the solver automatically generates the 
%    current equation based on the main line and the current conditions.
%
% NRMJac - Jacobian of NRMFcn [ function handle or sym ]
%    This is the Jacobian of the current equation, either specified by the user 
%    or constructed by this program. If the Jacobian is not specified, 
%    it is calculated using numerical differentiation. 
%    Generally, calculations are faster when the user specifies the Jacobian.
%
% NRMVal - Values of NRMFcn [ double vector ]
%    Specify the values for the current equation. Specifically, 
%    specify a double-precision numeric vector corresponding to 
%    the value of b when F(x) = b. If this is not specified, 
%    the equation will be solved assuming F(x) = 0.
%
% ConvTol - Convergence Tolerance [ double scalar ]
%    This is the absolute tolerance used to determine convergence in the 
% 　　Newton method. Specify it as a positive scalar value.
%
% MaxIter - Max Iteration [ double scalar ]
%    Specify the maximum number of iterations for the Newton method. 
%    If the calculation does not converge to the absolute tolerance 
%    after the specified number of iterations, the solver will return an error.
%
% InitVal - Initial Values [ double scalar or vector ]
%    This is the initial value used in the iterative calculations of Newton's method.
%
% Increment - Parameter for Numerical Differentiation [ double scalar ]
%    This is a parameter used in numerical differentiation. 
%    A smaller value allows you to calculate a gradient that is closer to the analytical solution.
%
% StepSize - Component Input [ string scalar or vector ]
%    This parameter is used in the iterative calculations of the Newton method. 
%    The state variables are updated based on this parameter. If the parameter is large, 
%    fewer iterations are required, but the algorithm may fail to converge. 
%    On the other hand, if the parameter is small, the number of iterations increases, 
%    and the calculation takes longer.
%
    
    properties (Access=public)       
        NRMFcn 
        NRMJac          
        NRMVal 
        
        ConvTol   (1,1) double  = 1e-5;
        MaxIter   (1,1) double  = 1000;
        InitVal   (:,1) double  = 1;
        Increment (1,1) double  = 1e-4;
        StepSize  (1,1) double  = 1;        
    end
    
    methods
        function obj = NewtonRaphsonMethod(opt)            
            arguments                
                opt.?NewtonRaphsonMethod
            end            

            fnames = fieldnames(opt);
            argi = 1;
            while argi <= numel(fnames)
                fname_i = fnames{argi};
                obj.(fname_i) = opt.(fname_i);

                argi = argi + 1;
            end            

            if isempty(obj.NRMJac)
                func  = obj.NRMFcn;
                delta = obj.Increment;
                switch class(func)
                    case {'function_handle','double'}                        
                        obj.NRMJac = @(x) obj.numerical_differentiation(x,func,delta);
                    case 'sym'
                        sv_x = symvar(func);
                        Jacobian = jacobian(func,sv_x);
        
                        obj.NRMFcn = matlabFunction(func    ,"Vars",sv_x);
                        obj.NRMJac = matlabFunction(Jacobian,"Vars",sv_x);                    
                    otherwise
                        error(msg('GUILDA:NewtonRaphsonMethod:InvalidInput'))
                end                
            end

            if isempty(obj.NRMVal)                
                obj.NRMVal = zeros(size(obj.InitVal));
            end
            
        end
    end

    methods (Access=private,Hidden)
        function Jacobian = numerical_differentiation(obj, x, OBJFcn, del) %#ok                                               
            nx  = numel(x);
            Jacobian = cell2mat( arrayfun(@(ITER) ( OBJFcn(x+[zeros(ITER-1,1);del;zeros(nx-ITER,1)]) - ...
                OBJFcn(x-[zeros(ITER-1,1);del;zeros(nx-ITER,1)]) ) / 2 / del, 1:nx, 'UniformOutput', false) );
        end
        function flag = isConvergence(obj,dx,Tol) %#ok
            flag = all(abs(dx) < Tol);
        end
    end

    methods (Access=public)        

        function [xi,iteration] = solve(obj)            

            AbsTol = obj.ConvTol;
            Gamma  = obj.StepSize;
            MaxIt  = obj.MaxIter;

            NRMF = obj.NRMFcn;
            NRMJ = obj.NRMJac;
            NRMV = obj.NRMVal;

            xi = obj.InitVal;

            isConvergence = false;
            iteration     = 1;
            while ~isConvergence && iteration <= MaxIt
                Ferror = NRMF(xi) - NRMV;    
                Jacobi = NRMJ(xi);
                dx = Jacobi \ Ferror;

                if obj.isConvergence(dx,AbsTol)
                    isConvergence = true;                
                else
                    xi = xi - Gamma * dx;
                    iteration = iteration + 1;
                end                
            end

            if iteration >= MaxIt                
                warning(msg('GUILDA:NewtonRaphsonMethod:MaxIteration'))            
            end
        end        
    end
end