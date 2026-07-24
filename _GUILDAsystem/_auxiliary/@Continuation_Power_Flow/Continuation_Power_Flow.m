classdef (Sealed = true) Continuation_Power_Flow < handle

% CONTINUATION_POWER_FLOW provides provides functions for continuation power flow.
%    CONTINUATION_POWER_FLOW(Name1, Val1, Names2, Val2, ...) provides functions 
%    for calculating continuous power flow.
%    It is used for calculating load fluctuations and plotting PV curves, among other things.
%
% CONTINUATION_POWER_FLOW PROPERTIES
%
% CPFFcn - The Equation to Be Solved [ function handle or sym ]
%    This is the equation to be solved, expressed in the form F(x) = b or F(x) = 0. 
%    Specify it using a function handle or a symbolic expression. If the user 
%    does not specify this variable, the solver automatically generates the 
%    current equation based on the main line and the current conditions.
%
% CPFJac - Jacobian of NRMFcn [ function handle or sym ]
%    This is the Jacobian of the current equation, either specified by the user 
%    or constructed by this program. If the Jacobian is not specified, 
%    it is calculated using numerical differentiation. 
%    Generally, calculations are faster when the user specifies the Jacobian.
%
% CPFNet - Power System Under Analysis [ PowerNetwork class ]
%    This is the power system to be analyzed. It must be an instance of the
%    `PowerNetwork` class or an object with the same functionality.
%
% CPFBus - Bus Name [ string or Bus class ]
%    Specify the name or class of the busbar that causes load fluctuations.
%
% CFPInitVal - Initial Value [ double vector ]
%    Specify the initial values for the continuous tidal current calculation. 
%    If no values are specified, the system will automatically calculate 
%    the solution obtained from the tidal current equations and biogeochemical modeling.
%
% CPFInitLam - Initial Value of Load Variation [ scalar ]
%    This is the initial value of the parameter when considering load fluctuations. 
% 　　Typically, 0 is specified.
%
% CPFMaxIter - Max Iteration [ scalar, postive ]
%    Specify the maximum number of times to repeat the sequence of steps for 
%    calculating and adjusting the continuous current. Normally, 
%    the calculation terminates when the load variation rate becomes less than 0
%    or when the Newton method fails to converge; however, if the step size or 
%    arc length is too small, satisfactory results may not be obtained even after 
%    running the calculation up to the maximum number of iterations. 
%    In such cases, take measures such as increasing the value of this parameter.
%
% CPFStepSize - Step Size [ scalar ]
%    Specify the step size for updating the variable. 
%    As a rule of thumb, specify a value larger than the position.
%
% CPFArcL - Arc Length [ double scalar ]
%    Specify the radius of the arc length.
%
% CPFUseInternal - Input Value [ double \ scalar or vector, function_handle ]
%    Specify whether to solve the power flow equations while taking into account 
%    the internal state of the generator.
%
    properties (Access=public)
       CPFFcn
       CPFJac
       CPFNet
       CPFBus         (:,1) string = ""
       CPFInitVal     (:,1) double = []       
       CPFInitLam     (1,1) double = 0
       CPFMaxIter     (1,1) {mustBePositive} = 500
       CPFStepSize    (1,1) {mustBePositive} = 0.5       
       CPFArcL        (1,1) {mustBePositive} = 10^-3
       CPFUseInternal (1,1) logical = false
    end

    properties (SetAccess=private)
        CPF_NRM    (1,1) {mustBeA(CPF_NRM,'Newton_Raphson_Method')} = Newton_Raphson_Method();
        CPF_Result 
    end

    properties (Access = private)
        rv_POLD  (:,1) double = []
        CONSTANT (:,1) double = []
        rm_BusRM (:,:) double
        rm_BusEM (:,:) double
        rv_BusVi (:,1) double
    end
    
    methods
        function obj = Continuation_Power_Flow(net,opt)
            arguments
                net                                 
                opt.?Continuation_Power_Flow 
            end

            obj.CPFNet = net; 

            fnames = fieldnames(opt);
            argi = 1;
            while argi <= numel(fnames)
                fname_i = fnames{argi};
                obj.(fname_i) = opt.(fname_i);

                argi = argi + 1;
            end            

            if isempty(obj.CPFFcn)
                Ymat = net.get_admittance_matrix.Variables;                
                obj.CPFFcn = @(x) obj.get_PFeq(x,Ymat);
            end
            obj.CPF_NRM = Newton_Raphson_Method("NRMFcn",obj.CPFFcn,"NRMJac",[],"NRMVal",0);
            obj.CPFJac  = obj.CPF_NRM.NRMJac;       

            if isempty(obj.CPFBus)
                warning(msg('GUILDA:Continuation_Power_Flow:EmptyBus'))
            end                                                                                

            useInt = obj.CPFUseInternal;
            a_Bus = net.a_Bus;
            n_Bus = numel(a_Bus);
            id_VX = 0;
            
            R = cell(1,n_Bus);
            E = cell(1,n_Bus);
            C = cell(n_Bus,1);
            I = cell(n_Bus,1);

            for i=1:n_Bus
                i_Bus = a_Bus{i};
                a_Comp = i_Bus.a_Component;
                n_Comp = numel(a_Comp);    
            
                tab_PF = i_Bus.get_pf_set();                
                rv_Veq = [abs(i_Bus.c_Vequilibrium);angle(i_Bus.c_Vequilibrium)];                    
            
                Ci = cell(n_Comp,1);
                Ri = cell(1,n_Comp);
                Ei = cell(1,n_Comp);
                Ii = cell(n_Comp,1);
                
                switch tab_PF{:,"Type"}
                    case "slack"  
                        i_Bus.iv_CPFV = id_VX + (1:2);            

                        i_BusC = ~useInt * eye(2) * rv_Veq;
                        i_BusR = id_VX + zeros(useInt,1) + (1:2);
                        i_BusE = i_BusR;
                        i_BusI = rv_Veq(repmat(useInt,2,1));

                        id_VX = id_VX + 2;
                                    
                        for j=1:n_Comp
                            i_Comp = a_Comp{j};        
                            rv_Xeq = i_Comp.rv_Xequilibrium;
                            r_Xlen = numel(rv_Xeq);
                            
                            if useInt                                                            
                                i_Comp.iv_CPFX = id_VX + (1:r_Xlen);
                                iv_CX = 3:r_Xlen;
            
                                Ci{j} = [rv_Xeq(1);zeros(r_Xlen-1,1)];
                                Ri{j} = id_VX + iv_CX;
                                Ei{j} = Ri{j};       
                                Ii{j} = rv_Xeq(iv_CX);
            
                                id_VX = id_VX + r_Xlen;                                                                
                            end
                            setPQ2Bus(i_Comp);
                              
                        end            
                    case "PV"            
                        i_Bus.iv_CPFV = id_VX + (1:2);     

                        i_BusC = diag([~useInt,0]) * rv_Veq;
                        i_BusR = id_VX + [1,ones(useInt,1)*2];
                        i_BusE = id_VX + [  ones(1,useInt),2];
                        i_BusI = rv_Veq([useInt,true]);

                        id_VX = id_VX + 2;
                        
                        for j=1:numel(a_Comp)
                            i_Comp = a_Comp{j};        
                            rv_Xeq = i_Comp.rv_Xequilibrium;
                            r_Xlen = numel(rv_Xeq);
            
                            if useInt && ~isempty(rv_Xeq)
                                i_Comp.iv_CPFX = id_VX + (1:r_Xlen);
                                iv_CX = [1,3:r_Xlen];
            
                                Ci{j} = zeros(r_Xlen,1);
                                Ri{j} = id_VX + iv_CX;
                                Ei{j} = Ri{j};
                                Ii{j} = rv_Xeq(iv_CX);
            
                                id_VX = id_VX + r_Xlen;                                                                   
                            end
                            setPQ2Bus(i_Comp);
                        end        
                    case "PQ"
                        i_Bus.iv_CPFV = id_VX + (1:2);            

                        i_BusC = zeros(2,1);
                        i_BusR = id_VX + (1:2);
                        i_BusE = i_BusR;
                        i_BusI = rv_Veq;
            
                        id_VX = id_VX + 2;

                        a_Comp = i_Bus.a_Component;
                        for j=1:numel(a_Comp)
                            i_Comp = a_Comp{j};                            
                            setPQ2Bus(i_Comp);
                        end
                end
            
                R{i} = [i_BusR,Ri{:}];
                E{i} = [i_BusE,Ri{:}];
                C{i} = [i_BusC;Ci{:}];
                I{i} = [i_BusI;Ii{:}];
            end

            iv_BRM_all = horzcat(R{:});
            iv_BEM_all = horzcat(E{:});            

            RM = eye(id_VX);
            EM = eye(id_VX);            

            iv_BusVi = cell2mat( cellfun(@(b) b.iv_CPFV, a_Bus', 'UniformOutput', false) );

            obj.rv_BusVi = reshape(iv_BusVi,[],1);
            obj.rm_BusRM = RM(ismember(1:id_VX,iv_BRM_all),:);
            obj.rm_BusEM = EM(:,ismember(1:id_VX,iv_BEM_all));
            obj.CONSTANT = vertcat(C{:});

            obj.CPFInitVal = vertcat(I{:});

            function setPQ2Bus(i_Comp)                
                CompVeq = i_Comp.c_Vequilibrium;
                CompIeq = i_Comp.c_Iequilibrium;
                CompSeq = CompVeq * conj(CompIeq);
                
                params = i_Comp.tab_parameter.dynamics{:,i_Comp.sv_para};                
                if useInt 
                    i_Comp.PQ2Bus = @(x,V,u) i_Comp.getCompPQ(x,V,u,params);
                else
                    i_Comp.PQ2Bus = @(x,V,u) [real(CompSeq);imag(CompSeq)];
                end                
            end
        end

        [sol,sol_pred] = solve(obj);                               
    end

    methods (Access = {?Continuation_Power_Flow})
        func = get_PFeq(obj,x,Ymat);        
    end

    methods (Access=private, Hidden)
        x_pred = Predict(obj,x_current,x_past);                        
        [x_correct,x_current,N] = Correct(obj,x_current,x_pred);                              
    end
end