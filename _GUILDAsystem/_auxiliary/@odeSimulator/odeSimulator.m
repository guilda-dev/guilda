classdef (Sealed = true) odeSimulator < handle 

    properties        
        ODEvnt        
        MassMatrix   (1,1) {mustBeA( MassMatrix, ["odeMassMatrix" ,"function_handle" ])} = odeMassMatrix        
        ODEFcn       (1,1) {mustBeA(     ODEFcn, [       "odeFcn" ,"function_handle" ])} = @(t,x)[]                   
        Jacobian     (1,1) {mustBeA(   Jacobian, [  "odeJacobian" ,"function_handle" ])} = odeJacobian                
        InitialTime  (1,1) double {mustBeReal} = 0               
        Parameters   (:,1) double = []        
        InitialSlope (:,1) double = []                        
        InitialValue (:,1) double = []        
        NonNegativeVariables {mustBePositive, mustBeInteger} = []        
        DelayDefinition = []        
        Sensitivity     = []        
        EventDefinition = []
        EquationType  (1,1) string {mustBeMember(EquationType, ["standard","fullyimplicit","delay"])} = "standard"        
        Solver        matlab.ode.SolverID = "ode15s"                
        SolverOptions matlab.ode.Options  = matlab.ode.options.ODE15s         
        AbsoluteTolerance (1,1) double {mustBePositive, mustBeBetween(AbsoluteTolerance,1e-15,1e-3, "closed")} = 1e-6        
        RelativeTolerance (1,1) double {mustBePositive, mustBeBetween(RelativeTolerance,1e-15,1e-3, "closed")} = 1e-4
        SeparateComplexParts matlab.lang.OnOffSwitchState = "off"
        Reporter  (1,1) string {mustBeMember(Reporter,["none","disp","dialog"])} = "dialog"
        TimeLimit (1,1) double = 8;
    end
    properties (SetAccess=private, Hidden)
        odeNetwork 
        odeTimeTable                
        odeYmat
        odeResult
    end
    properties %(Access=private)
        rv_odeV
    end

    properties (SetAccess=private, Hidden)
        % Version of this class       
        Ver (1,1) double = 1.1
    end

    methods
        function obj = odeSimulator(net, time, varargin, opt)            
            arguments                
                net  (1,1) {mustBeA(net, 'PowerNetwork')}                
                time (:,1) double = []
            end
            arguments (Input, Repeating)
                varargin {mustBeA(varargin, 'odeEventSet')}
            end
            arguments                
                opt.?odeSimulator
            end                                    
            obj.odeNetwork = net;

            cls = metaclass(obj);
            propNames = arrayfun(@(p) p.Name, cls.PropertyList, 'UniformOutput', false);
            
            strNames = fieldnames(opt);
            
            i=1;
            while i<=length(strNames)
                stri = strNames{i};
                if ~strcmpi(propNames, stri)
                    error(msg('GUILDA:odeSimulator:NoPropNames', string(stri)))
                else
                    obj.(stri) = opt.(stri);
                end
                i=i+1;
            end
            
            [obj.odeTimeTable, obj.ODEvnt] = table(varargin{:}, "time", time);
            obj.initialize_odeSimulator;

            odeYmat = tools.complex2matrix(net.get_admittance_matrix.Variables);
            rv_odeV = cell2mat(tools.cellfun(@(b) b.iv_odeX, net.a_Bus));

            obj.odeYmat = odeYmat;
            obj.rv_odeV = rv_odeV;
        end        
        
    end
    
    methods (Access=private)                       

        function initialize_odeSimulator(obj)            
            % Method for assigning state variable numbers to each device and bus.
            % Execute this before performing analysis using the ODE solver.         
            
            a_bus = obj.odeNetwork.a_Bus;

            idx_TGT = 0;                       
            
            for i=1:numel(a_bus)
                a_comp = a_bus{i}.a_Component;

                for j=1:numel(a_comp)                    
                    set_idx(a_comp{j});                                                                            

                    if ~isempty(a_comp{j}.a_LocalController)
                        a_LC1 = a_comp{j}.a_LocalController{1};
                        set_idx(a_LC1);                                                

                        a_LC1.iv_odeY = a_comp{j}.iv_odeU( a_comp{j}.str_u==a_LC1.str_y );                        

                        if ~isempty(a_LC1.a_LocalController)
                            a_LC2 = a_LC1.a_LocalController{1};
                            set_idx(a_LC2);                                      

                            a_LC2.iv_odeY = a_LC1.iv_odeU( a_LC1.str_u==a_LC2.str_y );
                            a_comp{j}.iv_odeY = a_LC2.iv_odeU;
                        end
                    end                    
                end
            end

            idx = 1;
            if ~isempty(obj.odeNetwork.a_GlobalController)
                gcon = obj.odeNetwork.a_GlobalController{1};
                nxgc = length(gcon.str_x);
                gcon.iv_odeX = idx_TGT + (1:nxgc)';
                idx_TGT = idx_TGT + nxgc;

                nConUnit = gcon.controlledUnits;
                while idx <= numel(nConUnit)
                    gcon.iv_odeU(idx) = nConUnit{idx}.iv_odeX( nConUnit{idx}.str_x==gcon.str_u );
                    gcon.iv_odeY(idx) = nConUnit{idx}.iv_odeU( nConUnit{idx}.str_u==gcon.str_y );

                    idx = idx + 1;
                end
            end

            for i=1:numel(a_bus)
                a_bus{i}.iv_odeX = idx_TGT + (1:2).';
                idx_TGT = idx_TGT + 2;
                a_bus{i}.iv_odeI = idx_TGT + (1:2).';                
                idx_TGT = idx_TGT + 2;                
            end

            function set_idx(OBJ)
                nx = length(OBJ.str_x);
                nu = length(OBJ.str_u);

                OBJ.iv_odeX = idx_TGT + (1:nx)';    
                idx_TGT = idx_TGT + nx;

                OBJ.iv_odeU = idx_TGT + (1:nu)';
                idx_TGT = idx_TGT + nu;                
            end
            
        end
        
    end

    methods (Hidden=true, Access={?odeSimulator, ?PowerNetwork})
                

        function odeX = getODEFunction(obj, t, x, RM, EM, lg) %#ok 
            % Method for retrieving the DAE system to be analyzed.            
            
            x = EM*x; 

            odeX = zeros(size(x));
            odeV = x(obj.rv_odeV);

            I = obj.odeYmat*odeV;
            
            a_bus = obj.odeNetwork.a_Bus;

            y_GC = zeros(size(x), 'like', x);
            a_GC.str_y = "Pmech";
            if ~isempty(obj.odeNetwork.a_GlobalController)
                a_GC = obj.odeNetwork.a_GlobalController{1};

                x_GC = x(a_GC.iv_odeX);
                u_GC = x(a_GC.iv_odeU);

                odeX(a_GC.iv_odeX) = a_GC.fv_odeDiff(t,x_GC,[],[],u_GC);                
                y_GC(a_GC.iv_odeY) = a_GC.fv_odeY(t,x_GC,[],[],u_GC);
            end

            for i=1:numel(a_bus)
                a_comp = a_bus{i}.a_Component;

                idx_V = a_bus{i}.iv_odeX;
                idx_I = a_bus{i}.iv_odeI;

                Vi = x(idx_V);                                                                                             
                Ii = x(idx_I);                                                                                             

                for j=1:numel(a_comp)
                    cj = a_comp{j};
                    ue = cj.cv_Uequilibrium;       
                    uy = cj.str_u==a_GC.str_y;
                    ue( uy ) = ue( uy ) + y_GC( cj.iv_odeU( uy ) ); 
                    ue = ue + cj.U_offset(t);
                    
                    odeX = get_dx_algebraic(cj, t, x, Vi, Ii, ue, odeX);
                end                

                odeX([idx_V;idx_I]) = odeX([idx_V;idx_I]) + [Ii;Ii - I([-1;0]+2*i)];
                
            end                    

            odeX = odeX(lg); 

        end

        function odeJac = getODEJacobian(obj, t, x, RM, EM, lg) %#ok    
            % Method for obtaining the Jacobian of the DAE system under analysis.

            x = EM*x;
            
            a_bus = obj.odeNetwork.a_Bus;

            odeJac = zeros(numel(x), numel(x));

            rv_Bus_V = zeros(0,1);
            rv_Bus_I = zeros(0,1);

            if ~isempty(obj.odeNetwork.a_GlobalController)
                a_GC = obj.odeNetwork.a_GlobalController{1};
                
                lh_GC = [a_GC.iv_odeX; a_GC.iv_odeU];
                lv_GC = [a_GC.iv_odeX; a_GC.iv_odeY];

                x_GC = x(a_GC.iv_odeX);
                u_GC = x(a_GC.iv_odeU);

                [Axx_GC, Bxu_GC, Bxv_GC, Bxi_GC, Cyx_GC, Dyu_GC, Dyv_GC, Dyi_GC, ~, ~, ~, ~] = getSubJacobian(a_GC, t, x_GC, [], [], u_GC);                

                odeJac(lv_GC, lh_GC) = odeJac(lv_GC, lh_GC) + [ Axx_GC,  Bxv_GC,  Bxu_GC, Bxi_GC;
                                                                Cyx_GC,  Dyv_GC,  Dyu_GC, Dyi_GC];
                               
            end

            for i=1:numel(a_bus)                
                cm = a_bus{i}.a_Component;

                idx_V = a_bus{i}.iv_odeX;
                idx_I = a_bus{i}.iv_odeI;

                Vi = x(idx_V);
                Ii = x(idx_I);

                for j=1:numel(cm)
                    cj = cm{j};

                    idx_X = cj.iv_odeX;
                    idx_U = cj.iv_odeU;
                    idx_Y = cj.iv_odeY;

                    xi = x(idx_X);        
                    ui = x(idx_U);                 

                    [Axx, Bxu, Bxv, Bxi, Cyx, Dyu, Dyv, Dyi, Cix, Diu, Div, Dii] = getSubJacobian(cj,t,xi,Vi,Ii,ui);

                    rh = [idx_X; idx_U; idx_V; idx_I];
                    rv = [idx_X; idx_V];
                    
                    if ~isempty(cj.a_LocalController)
                        a_LC1 = cj.a_LocalController{1};                                            

                        if ~isempty(a_LC1.a_LocalController)
                            a_LC2 = a_LC1.a_LocalController{1};

                            idx_X_LC2 = a_LC2.iv_odeX;
                            idx_U_LC2 = a_LC2.iv_odeU;
                            idx_Y_LC2 = a_LC2.iv_odeY;

                            xi_LC2 = x(idx_X_LC2);                            
                            ui_LC2 = x(idx_U_LC2);                                                        

                            [Axx_LC2, Bxu_LC2, Bxv_LC2, Bxi_LC2, Cyx_LC2, Dyu_LC2, Dyv_LC2, Dyi_LC2, ~, ~, ~, ~] = getSubJacobian(a_LC2, t, xi_LC2, Vi, Ii, ui_LC2);                                                                            
                            
                            rh_LC2 = [idx_X_LC2; idx_U_LC2; idx_V; idx_I];
                            rv_LC2 = [idx_X_LC2; idx_Y_LC2];

                            odeJac(rv_LC2, rh_LC2) = odeJac(rv_LC2, rh_LC2) + [ Axx_LC2,  Bxu_LC2,  Bxv_LC2,  Bxi_LC2; ...
                                                                               -Cyx_LC2, -Dyu_LC2, -Dyv_LC2, -Dyi_LC2];                            

                            
                            odeJac(idx_U_LC2,idx_U_LC2) = odeJac(idx_U_LC2,idx_U_LC2) + eye(length(idx_U_LC2));

                            odeJac(idx_Y, rh) = odeJac(idx_Y, rh) + [-Cyx, -Dyu, -Dyv, -Dyi];
                            
                        end 

                        idx_X_LC1 = a_LC1.iv_odeX;
                        idx_U_LC1 = a_LC1.iv_odeU;
                        idx_Y_LC1 = a_LC1.iv_odeY;


                        xi_LC1 = x(idx_X_LC1);
                        ui_LC1 = x(idx_U_LC1);                                      

                        [Axx_LC1, Bxu_LC1, Bxv_LC1, Bxi_LC1, Cyx_LC1, Dyu_LC1, Dyv_LC1, Dyi_LC1, ~, ~, ~, ~] = getSubJacobian(a_LC1, t, xi_LC1, Vi, Ii, ui_LC1);                                                
                        
                        rh_LC1 = [idx_X_LC1; idx_U_LC1; idx_V; idx_I];
                        rv_LC1 = [idx_X_LC1; idx_Y_LC1];

                        odeJac(rv_LC1, rh_LC1) = odeJac(rv_LC1, rh_LC1) + [ Axx_LC1,  Bxu_LC1,  Bxv_LC1,  Bxi_LC1; ...                                                                                   
                                                                           -Cyx_LC1, -Dyu_LC1, -Dyv_LC1, -Dyi_LC1];

                        odeJac(idx_U_LC1,idx_U_LC1) = odeJac(idx_U_LC1,idx_U_LC1) + eye(length(idx_U_LC1));
                        
                    end                                                                                                                                    
            
                    odeJac(rv,rh) = odeJac(rv,rh) + [ Axx,  Bxu,  Bxv,  Bxi;...                                                     
                                                     -Cix, -Diu, -Div, -Dii]; 

                    odeJac(idx_U,idx_U) = odeJac(idx_U,idx_U) + eye(length(idx_U));

                end

                rv_Bus_V(2*i+[-1;0]) = idx_V; 
                rv_Bus_I(2*i+[-1;0]) = idx_I; 
            end                               
                   
            odeJac(rv_Bus_I,rv_Bus_V) = odeJac(rv_Bus_I,rv_Bus_V) - obj.odeYmat;

            odeJac([rv_Bus_V; rv_Bus_I], rv_Bus_I) = odeJac([rv_Bus_V; rv_Bus_I], rv_Bus_I) + [eye(2*i); eye(2*i)];
            
            odeJac = odeJac(lg,lg);            

        end       
                
        

        function [x0, M0] = getNextPhase(obj, x0, M0, RM, EM) %#ok
            a_bus  = obj.odeNetwork.a_Bus;            

            x0 = EM * x0;
            M0 = EM * M0 * EM.';

            for i=1:numel(a_bus)
                a_Comp = a_bus{i}.a_Component;                

                b_idx_V = a_bus{i}.iv_odeX;
                b_idx_I = a_bus{i}.iv_odeI;

                for j=1:numel(a_Comp)
                    if isa(a_Comp{j}, 'component.generator.abstract') && ~a_Comp{j}.isConnect
                        c_idx = a_Comp{j}.iv_odeX;
                        b_idx = a_bus{i}.iv_odeX;
                        [x0(c_idx), u_equilibrium] = a_Comp{j}.get_equilibrium([1,1j]*x0(b_idx), 0+1j*0);                         
                        
                        if ~isempty(a_Comp{j}.a_LocalController)
                            a_LC1 = a_Comp{j}.a_LocalController{1};

                            v_LC1 = a_LC1.iv_odeX;                            
                            [x0(v_LC1), ~] = a_LC1.get_equilibrium([1,1j]*x0(b_idx), u_equilibrium);                         

                            M0(v_LC1, v_LC1) = a_LC1.rm_odeMass([], [], [], [],[]);
                            
                            if ~isempty(a_LC1.a_LocalController)
                                a_LC2 = a_LC1.a_LocalController{1};

                                v_LC2 = a_LC2.iv_odeX;                                
                                [x0(v_LC2), ~] = a_LC2.get_equilibrium([1,1j]*x0(b_idx), []);                         

                                M0(v_LC2, v_LC2) = a_LC2.rm_odeMass([], [], [], [],[]);
                            end
                        end

                        M0(c_idx, c_idx) = a_Comp{j}.rm_odeMass([], [], [], [], []);
                    end
                end

                if a_bus{i}.l_isFault
                    x0([b_idx_V;b_idx_I]) = [real(a_bus{i}.c_Vequilibrium);
                                             imag(a_bus{i}.c_Vequilibrium);
                                             real(a_bus{i}.c_Iequilibrium);
                                             imag(a_bus{i}.c_Iequilibrium)];
                end
            end            
        end

    end

    methods

        function [out,flag] = simulate(obj)
            
            [o,x0,Mass,tp,np,flag,options] = makeODE(obj);            

            % Set reporter
            str_evt = string(obj.odeTimeTable.Properties.VariableNames(3:end));
            ts = obj.odeTimeTable{  1,"t1"};
            te = obj.odeTimeTable{end,"t2"};
            odeProg  = odeProgress( obj.Reporter, [ts,te], obj.TimeLimit);
            o.SolverOptions.OutputFcn = odeProg.OutputFcn;            
            o.EventDefinition = odeEvent("EventFcn", @(t,x) odeProg.Events(), "Response", "stop");
                
            while tp <= np          

                % Retrieving events related to ground faults and circuit tripping.                                               
                TT = obj.odeTimeTable(tp,:); 

                odeEvents = obj.ODEvnt( TT{:,3:end} );                

                t1 = TT{1, 't1'};
                t2 = TT{1, 't2'};

                setEventCondition(odeEvents{:}, "TimePhase", [t1,t2], "Iteration", tp);

                [EM, RM, lv_FBorTC, x0, Mass] = getInitialCondition(odeEvents{:}, "x0", x0, "M0", Mass);

                o.InitialValue = x0;                
                o.MassMatrix   = Mass;                
                o.ODEFcn       = @(t,x) obj.getODEFunction(t,x,RM,EM,~lv_FBorTC);                                       
                o.Jacobian     = @(t,x) obj.getODEJacobian(t,x,RM,EM,~lv_FBorTC);                
            
                % update reporter
                odeProg.timeoffset = t1;
                odeProg.message  = "|";
                if tp~=np
                    str_evti = str_evt( obj.odeTimeTable{tp+1,3:end} );
                    str_evti = str_evti(~contains(str_evti,"NoAction"));
                    if ~isempty(str_evti)
                        odeProg.message  = "|("+join(str_evti,",")+": t="+t2+")";
                    end
                end
                
                try         
                    % When solving the equation, specify [0, duration of each phase]                         
                    sol = solve(o, 0, t2-t1); 
                catch me                    

                    splitMSG = strsplit(me.identifier,':');                                        

                    if isequal(splitMSG{end},'NeedBetterY0')                    
                        [ODEfcn, x0, options] = CalculateInitialCondition(o, options);
                    else
                        odeProg.OutputFcn([],[],"break")
                        throw(me)                                                    
                    end
                   

                    % After performing error bundling, solve the DAE system again.
                    try
                        [t,y] = ode15s(ODEfcn, [0,t2-t1], x0, options);
                        sol = struct('Time', t.', 'Solution', y.');

                    catch ME
                        odeProg.OutputFcn([],[],"break")
                        error(msg('GUILDA:odeSimulator:UnfeasibleDAE'))
                    end
                end
                                   
                obj.odeResult{tp} = Event2State( odeEvents{:}, "ODEResults", struct('Time', (sol.Time + t1)', 'Solution', (EM * sol.Solution).'), "ODEYmatrix", obj.odeYmat );                     
                if sol.Time(end) < (t2-t1)
                    flag = true;
                    break;
                end

                [x0, Mass] = obj.getNextPhase(reshape(sol.Solution(:,end),[],1), o.MassMatrix.MassMatrix, RM, EM);

                tp = tp + 1;
            end        

            out = odeSimulationResult(obj.odeNetwork, obj.odeResult);                        
        end
    end
end

function [Axx, Bxu, Bxv, Bxi, Cyx, Dyu, Dyv, Dyi, Cix, Diu, Div, Dii] = getSubJacobian(OBJ, t, xi, Vi, Ii, ui)
                
    Axx = OBJ.JacobiAxx(t,xi,Vi,Ii,ui);
    Bxv = OBJ.JacobiBxv(t,xi,Vi,Ii,ui);
    Bxi = OBJ.JacobiBxi(t,xi,Vi,Ii,ui);                         
    Bxu = OBJ.JacobiBxu(t,xi,Vi,Ii,ui);                         

    Cyx = OBJ.JacobiCyx(t,xi,Vi,Ii,ui);
    Dyv = OBJ.JacobiDyv(t,xi,Vi,Ii,ui);
    Dyi = OBJ.JacobiDyi(t,xi,Vi,Ii,ui);
    Dyu = OBJ.JacobiDyu(t,xi,Vi,Ii,ui);

    Cix = OBJ.JacobiCix(t,xi,Vi,Ii,ui);
    Div = OBJ.JacobiDiv(t,xi,Vi,Ii,ui);
    Dii = OBJ.JacobiDii(t,xi,Vi,Ii,ui);
    Diu = OBJ.JacobiDiu(t,xi,Vi,Ii,ui);
end