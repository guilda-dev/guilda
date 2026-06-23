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
        CONSTANT (:,1) double = []
        rm_BusRM (:,:) double
        rm_BusEM (:,:) double
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
                if obj.CPFUseInternal
                    obj.CPFFcn = @(x) obj.get_PFeq_GBus(x,Ymat);                
                else
                    obj.CPFFcn = @(x) obj.get_PFeq_Bus(x,Ymat);                
                end                    
            end
            obj.CPF_NRM = Newton_Raphson_Method("NRMFcn",obj.CPFFcn,"NRMJac",[],"NRMVal",0);
            obj.CPFJac  = obj.CPF_NRM.NRMJac;       

            if isempty(obj.CPFBus)
                warning(msg('GUILDA:Continuation_Power_Flow:EmptyBus'))
            end                                                        

            a_Bus = net.a_Bus;
            n_Bus = numel(a_Bus);
            V_BRM = cell(n_Bus,1);            
            V_BEM = cell(n_Bus,1);           

            init  = cell(n_Bus,1);            
            CONST = cell(n_Bus,1);            
            idx_V = 0;

            useInt = obj.CPFUseInternal;
            idx23  = [useInt,~useInt]*[3;2];
            for i=1:n_Bus
                i_Bus  = a_Bus{i};                
                tab_PF = i_Bus.get_pf_set();                
                rv_Veq = [abs(i_Bus.c_Vequilibrium);angle(i_Bus.c_Vequilibrium)];                

                ExtraX  = eye(3);
                switch tab_PF{:,"Type"}                    
                    case "PV"                                                
                        rv_Xeq = i_Bus.a_Component{1}.cv_Xequilibrium(1);

                        C = [diag([~useInt,0]) * rv_Veq; zeros(useInt,1)];
                        R = idx_V + [1,ones(useInt,1)*[2,3]];
                        E = idx_V + [  ones(1,useInt),2,ones(1,useInt)*3];
                        
                        init{i} = ExtraX([useInt,true,useInt],:) * [rv_Veq;rv_Xeq];

                    case "PQ"   
                        C = ExtraX([true(1,2),useInt],:) * zeros(3,1);
                        R = idx_V + (1:2);
                        E = R;

                        init{i} = rv_Veq;

                    case "slack"                                  
                        rv_Xeq = i_Bus.a_Component{1}.cv_Xequilibrium(1);

                        C = [~useInt * eye(2) * rv_Veq; rv_Xeq(useInt)];
                        R = idx_V + zeros(useInt,1) + (1:2);
                        E = R;

                        init{i} = rv_Veq(repmat(useInt,2,1));
                end     

                a_Comp = i_Bus.a_Component{1};                
                params = a_Comp.tab_parameter.dynamics{:,a_Comp.str_para};
                a_Comp.PQ2BusG = @(x,V,u) a_Comp.getCompPQG(x,V,u,params);
                a_Comp.PQ2BusL = @(x,V,u) a_Comp.getCompPQL(x,V,u,params);
                
                V_BRM{i} = R';
                V_BEM{i} = E';
                CONST{i} = C;

                idx_V = idx_V + idx23;
            end

            iv_BRM_all = vertcat(V_BRM{:});
            iv_BEM_all = vertcat(V_BEM{:});            

            RM = eye(idx23*n_Bus);
            EM = eye(idx23*n_Bus);

            obj.rm_BusRM = RM(ismember(1:idx23*n_Bus,iv_BRM_all),:);
            obj.rm_BusEM = EM(:,ismember(1:idx23*n_Bus,iv_BEM_all));
            obj.CONSTANT = vertcat(CONST{:});

            obj.CPFInitVal = vertcat(init{:});
        end

        [sol,sol_pred] = solve(obj);                               
    end

    methods (Access = {?Continuation_Power_Flow})
        func = get_PFeq_Bus(obj,x,Ymat);
        func = get_PFeq_GBus(obj,x,Ymat);                                                    
    end

    methods (Access=private, Hidden)
        x_pred = Predict(obj,x_current,x_past);                        
        [x_correct,x_current,N] = Correct(obj,x_current,x_pred);                              
    end
end