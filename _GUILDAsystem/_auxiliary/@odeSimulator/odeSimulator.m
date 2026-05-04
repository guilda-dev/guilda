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
    end
    properties (SetAccess=private, Hidden)
        odeNetwork 
        odeTimeTable                
        odeYmat
        odeResult
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

            obj.odeYmat = net.get_admittance_matrix.Variables;
        end        
        
    end
    
    methods (Access=private)                       

        function initialize_odeSimulator(obj)            
            % Method for assigning state variable numbers to each device and bus.
            % Execute this before performing analysis using the ODE solver.         
            
            a_bus = obj.odeNetwork.a_Bus;

            idx_TGT = 0;

            gcon = obj.odeNetwork.a_GlobalController;
            if ~isempty(gcon)
                gcon{1}.iv_odeX = idx_TGT + 1;
                idx_TGT = idx_TGT + 1;
            end
            
            for i=1:numel(a_bus)
                a_comp = a_bus{i}.a_Component;

                for j=1:numel(a_comp)                    
                    set_idx(a_comp{j});                                                                            

                    if ~isempty(a_comp{j}.a_LocalController)
                        a_LC1 = a_comp{j}.a_LocalController{1};
                        set_idx(a_LC1);                                                

                        a_LC1.iv_odeY = a_comp{j}.iv_odeU( a_comp{j}.str_u=="Vfield" );                        

                        if ~isempty(a_LC1.a_LocalController)
                            a_LC2 = a_LC1.a_LocalController{1};
                            set_idx(a_LC2);                                      

                            a_LC2.iv_odeY = a_LC1.iv_odeU( a_LC1.str_u=="Vpss" );
                            a_comp{j}.iv_odeY = a_LC2.iv_odeU;
                        end
                    end                    
                end
            end

            for i=1:numel(a_bus)
                a_bus{i}.iv_odeX = idx_TGT + (1:2).';
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
            odeV = zeros(size(obj.odeNetwork.a_Bus));
            
            a_bus = obj.odeNetwork.a_Bus;                                     

            for i=1:numel(a_bus)
                a_comp = a_bus{i}.a_Component;
                Vi = x(a_bus{i}.iv_odeX);                                

                for j=1:numel(a_comp)
                    cj = a_comp{j};
                    xi = x(cj.iv_odeX);        
                    ui = x(cj.iv_odeU);
                    yi = a_comp{j}.fv_odeY(t,xi,Vi,ui);

                    ue = cj.cv_Uequilibrium;                                   

                    if ~isempty(cj.a_LocalController)
                        a_LC1  = cj.a_LocalController{1};                        
                        yi_LC2 = 0;

                        if ~isempty(a_LC1.a_LocalController)
                            a_LC2  = a_LC1.a_LocalController{1};   
                            
                            xi_LC2 = x(a_LC2.iv_odeX);                            
                            ui_LC2 = x(a_LC2.iv_odeU);
                            dx_LC2 = a_LC2.fv_odeDiff(t, xi_LC2, Vi, ui_LC2);
                            yi_LC2 = a_LC2.fv_odeConY(t, xi_LC2, Vi, ui_LC2);                            

                            odeX([a_LC2.iv_odeX; a_LC2.iv_odeU]) = odeX([a_LC2.iv_odeX; a_LC2.iv_odeU]) + [dx_LC2; ui_LC2 - yi];
                        end

                        xi_LC1 = x(a_LC1.iv_odeX);
                        ui_LC1 = x(a_LC1.iv_odeU);
                        dx_LC1 = a_LC1.fv_odeDiff(t, xi_LC1, Vi, ui_LC1);
                        yi_LC1 = a_LC1.fv_odeConY(t, xi_LC1, Vi, ui_LC1);
                        
                        ue_LC1 = a_LC1.cv_Uequilibrium;
                        ue_LC1( a_LC1.str_u=="Vpss" ) = yi_LC2;
                        odeX([a_LC1.iv_odeX; a_LC1.iv_odeU]) = odeX([a_LC1.iv_odeX; a_LC1.iv_odeU]) + [dx_LC1; ui_LC1 - ue_LC1];
                        
                        ue( a_comp{j}.str_u=="Vfield" ) = yi_LC1;
                    end                    

                    ue = ue + cj.U_offset(t);

                    dx = cj.fv_odeDiff(t, xi, Vi, ui);
                    Ix = cj.isConnect * cj.fv_odeI(t, xi, Vi, ui);

                    odeX([cj.iv_odeX; cj.iv_odeU; a_bus{i}.iv_odeX]) = odeX([cj.iv_odeX; cj.iv_odeU; a_bus{i}.iv_odeX]) + [dx; ui - ue; -real(Ix); -imag(Ix)];                                        
                    
                end

                odeV(i) = [1,1j]*Vi;
            end        

            I = obj.odeYmat*odeV;
            for i=1:numel(a_bus)
                idx = a_bus{i}.iv_odeX;
                odeX(idx) = odeX(idx) + [real(I(i)); imag(I(i))]; 
            end

            odeX = odeX(lg); 

        end
                
        function odeJac = getODEJacobian(obj, t, x, RM, EM, lg) %#ok    
            % Method for obtaining the Jacobian of the DAE system under analysis.

            x = EM*x;
            
            a_bus = obj.odeNetwork.a_Bus;

            odeJac = zeros(numel(x), numel(x));

            lv_Bus = zeros(0,1);

            for i=1:numel(a_bus)                
                cm = a_bus{i}.a_Component;
                Vi = x(a_bus{i}.iv_odeX);                

                for j=1:numel(cm)
                    cj = cm{j};
                    xi = x(cj.iv_odeX);        
                    ui = x(cj.iv_odeU);                                

                    lu = cj.iv_odeU;
                    lh = [cj.iv_odeX; cj.iv_odeU; a_bus{i}.iv_odeX];
                    lv = [cj.iv_odeX; a_bus{i}.iv_odeX];
                    
                    if ~isempty(cj.a_LocalController)
                        a_LC1 = cj.a_LocalController{1};                                            

                        if ~isempty(a_LC1.a_LocalController)
                            a_LC2 = a_LC1.a_LocalController{1};

                            xi_LC2 = x(a_LC2.iv_odeX);                            
                            ui_LC2 = x(a_LC2.iv_odeU);                                                        

                            Axx_LC2 = a_LC2.JacobiAxx(t, xi_LC2, Vi, ui_LC2);
                            Bxv_LC2 = a_LC2.JacobiBxv(t, xi_LC2, Vi, ui_LC2);
                            Bxu_LC2 = a_LC2.JacobiBxu(t, xi_LC2, Vi, ui_LC2);                                    
        
                            Cyx_LC2 = a_LC2.JacobiCyx(t, xi_LC2, Vi, ui_LC2);
                            Dyv_LC2 = a_LC2.JacobiDyv(t, xi_LC2, Vi, ui_LC2);
                            Dyu_LC2 = a_LC2.JacobiDyu(t, xi_LC2, Vi, ui_LC2);

                            lu_LC2 = a_LC2.iv_odeU;
                            lh_LC2 = [a_LC2.iv_odeX; a_LC2.iv_odeU; a_bus{i}.iv_odeX];
                            lv_LC2 = [a_LC2.iv_odeX; a_LC2.iv_odeY];

                            odeJac(lv_LC2, lh_LC2) = odeJac(lv_LC2, lh_LC2) + [ Axx_LC2,  Bxu_LC2,  Bxv_LC2; ...
                                                                               -Cyx_LC2, -Dyu_LC2, -Dyv_LC2];                            

                            
                            odeJac(lu_LC2, lu_LC2) = odeJac(lu_LC2, lu_LC2) + eye(length(lu_LC2));
                            
                        end                        

                        xi_LC1 = x(a_LC1.iv_odeX);
                        ui_LC1 = x(a_LC1.iv_odeU);                                                

                        Axx_LC1 = a_LC1.JacobiAxx(t, xi_LC1, Vi, ui_LC1);
                        Bxv_LC1 = a_LC1.JacobiBxv(t, xi_LC1, Vi, ui_LC1);
                        Bxu_LC1 = a_LC1.JacobiBxu(t, xi_LC1, Vi, ui_LC1);                                    
    
                        Cyx_LC1 = a_LC1.JacobiCyx(t, xi_LC1, Vi, ui_LC1);
                        Dyv_LC1 = a_LC1.JacobiDyv(t, xi_LC1, Vi, ui_LC1);
                        Dyu_LC1 = a_LC1.JacobiDyu(t, xi_LC1, Vi, ui_LC1);

                        Cyx = cj.JacobiCyx(t, xi, Vi, ui);
                        Dyv = cj.JacobiDyv(t, xi, Vi, ui);
                        Dyu = cj.JacobiDyu(t, xi, Vi, ui);                    

                        lu_LC1 = a_LC1.iv_odeU;
                        lh_LC1 = [a_LC1.iv_odeX; a_LC1.iv_odeU; a_bus{i}.iv_odeX];
                        lv_LC1 = [a_LC1.iv_odeX; a_LC1.iv_odeY];

                        odeJac(lv_LC1, lh_LC1) = odeJac(lv_LC1, lh_LC1) + [ Axx_LC1,  Bxu_LC1,  Bxv_LC1; ...                                                                                   
                                                                           -Cyx_LC1, -Dyu_LC1, -Dyv_LC1];

                        odeJac(lu_LC1, lu_LC1) = odeJac(lu_LC1, lu_LC1) + eye(length(lu_LC1));

                        odeJac(cj.iv_odeY, lh) = [-Cyx, -Dyu, -Dyv];
                    end                                        
                                
                    Axx = cj.JacobiAxx(t, xi, Vi, ui);
                    Bxv = cj.JacobiBxv(t, xi, Vi, ui);
                    Bxu = cj.JacobiBxu(t, xi, Vi, ui);

                    Cix = cj.JacobiCix(t, xi, Vi, ui);
                    Div = cj.JacobiDiv(t, xi, Vi, ui);
                    Diu = cj.JacobiDiu(t, xi, Vi, ui);                    
            
                    odeJac(lv,lh) = odeJac(lv,lh) + [ Axx,  Bxu,  Bxv; ...
                                                     -Cix, -Diu, -Div]; 

                    odeJac(lu,lu) = odeJac(lu,lu) + eye(length(lu));

                end

                lv_Bus(2*i+[-1;0]) = a_bus{i}.iv_odeX; 
            end                               
        
            G = real(obj.odeYmat);
            B = imag(obj.odeYmat);

            lo = lv_Bus(1:2:end);
            le = lv_Bus(2:2:end);
            
            odeJac(lo,lo) = odeJac(lo,lo) + G;
            odeJac(lo,le) = odeJac(lo,le) - B;
            odeJac(le,lo) = odeJac(le,lo) + B;
            odeJac(le,le) = odeJac(le,le) + G; 
            
            odeJac = odeJac(lg,lg);

        end       

        function [x0, M0] = getNextPhase(obj, x0, M0, RM, EM) %#ok
            a_bus  = obj.odeNetwork.a_Bus;            

            x0 = EM * x0;
            M0 = EM * M0 * EM.';

            for i=1:numel(a_bus)
                a_Comp = a_bus{i}.a_Component;                

                for j=1:numel(a_Comp)
                    if isa(a_Comp{j}, 'component.generator.abstract') && ~a_Comp{j}.isConnect
                        c_idx = a_Comp{j}.iv_odeX;
                        b_idx = a_bus{i}.iv_odeX;
                        [x0(c_idx), u_equilibrium] = a_Comp{j}.get_equilibrium([1,1j]*x0(b_idx), 0+1j*0);                         
                        
                        if ~isempty(a_Comp{j}.a_LocalController)
                            a_LC1 = a_Comp{j}.a_LocalController{1};

                            v_LC1 = a_LC1.iv_odeX;                            
                            [x0(v_LC1), ~] = a_LC1.get_equilibrium([1,1j]*x0(b_idx), u_equilibrium);                         

                            M0(v_LC1, v_LC1) = a_LC1.rm_odeMass([], [], [], []);
                            
                            if ~isempty(a_LC1.a_LocalController)
                                a_LC2 = a_LC1.a_LocalController{1};

                                v_LC2 = a_LC2.iv_odeX;                                
                                [x0(v_LC2), ~] = a_LC2.get_equilibrium([1,1j]*x0(b_idx), []);                         

                                M0(v_LC2, v_LC2) = a_LC2.rm_odeMass([], [], [], []);
                            end
                        end

                        M0(c_idx, c_idx) = a_Comp{j}.rm_odeMass([], [], [], []);
                    end
                end
            end            
        end

    end

    methods

        function out = simulate(obj)
            
            o = ode;
        
            cls = metaclass(o);
            pList = arrayfun(@(P) P.Name, cls.PropertyList, 'UniformOutput', false);
            pLogc = arrayfun(@(P) strcmp(P.SetAccess, 'public'), cls.PropertyList);
        
            props = pList(pLogc);
            
            nprops = numel(props);
            ip = 1;
            while ip <= nprops        
                o.(props{ip}) = obj.(props{ip});
                ip = ip + 1;        
            end

            options = odeset("RelTol", o.RelativeTolerance, "AbsTol", o.AbsoluteTolerance);                        

            tp = 1;
            np = size(obj.odeTimeTable,1);                   

            x0   = [];
            Mass = [];

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
            
                try                     
                    startTime = tic;
                    stopTime  = 8;
                    SimulationTimer = @(t,y) checkSimulationTime(t,y,startTime,stopTime);
                    o.EventDefinition = odeEvent("EventFcn", SimulationTimer, "Response", "stop");
                    
                    % When solving the equation, specify [0, duration of each phase]                                        
                    sol = solve(o, 0, t2-t1); 
                catch me                    

                    splitMSG = strsplit(me.identifier,':');                                        

                    switch splitMSG{end}

                        case 'IndexGTOne'

                            % If the DAE index is greater than 1, construct a new DAE sequence with a reduced index.
                            [ODEfcn, x0, options] = ReduceDAEIndex(obj, o, options);

                        case 'NeedBetterY0'

                            % If an error related to initial value inconsistencies occurs, calculate a state that is consistent with the DAE system.
                            [ODEfcn, x0, options] = CalculateInitialCondition(o, options);

                        otherwise
                            throw(me)
                                                    
                    end
                   

                    % After performing error bundling, solve the DAE system again.
                    try
                        [t,y] = ode15s(ODEfcn, [0,t2-t1], x0, options);
                        sol = struct('Time', t.', 'Solution', y.');

                    catch ME
                        error(msg('GUILDA:odeSimulator:UnfeasibleDAE'))
                    end
                end
                                
                obj.odeResult{tp} = Event2State( odeEvents{:}, "ODEResults", struct('Time', (sol.Time + t1)', 'Solution', (EM * sol.Solution).'), "ODEYmatrix", obj.odeYmat );                                
                

                [x0, Mass] = obj.getNextPhase(reshape(sol.Solution(:,end),[],1), o.MassMatrix.MassMatrix, RM, EM);

                tp = tp + 1;
            end        

            out = odeSimulationResult(obj.odeNetwork, obj.odeResult);            

        end
    end
end


function [ODEfcn, x0, options] = ReduceDAEIndex(cls, ode, options)

    a_bus = cls.odeNetwork.a_Bus;
    n_bus = numel(a_bus);
    str_x = cell(n_bus,1);
    str_v = cell(n_bus,1);
    for i=1:n_bus
        a_comp = a_bus{i}.a_Component;                        

        str_v{i} = ["Vre";"Vim"]+"_"+string(a_bus{i})+"(t)";
        str_x{i} = cell2mat( cellfun(@(c) string(c)+"_"+c.str_x+"(t)", a_comp, 'UniformOutput', false) );                            
    end        
    sym_t = sym("t");
    sym_x = str2sym(cell2mat([str_x;str_v]));                        

    Mass = ode.MassMatrix.MassMatrix;
    Func = ode.ODEFcn;
       
    eqns = Mass*sym_x == Func(sym_t, sym_x);

    if ~isLowIndexDAE(eqns, sym_x)
        [newEqns, newX] = reduceDAEIndex(eqns, sym_x);
        if ~isLowIndexDAE(newEqns, newX)
            error(me.message)
        else
            [newEqns,newX] = reduceRedundancies(newEqns,newX);

            ODEfcn = matlabFunction(newEqns, Vars={newX});
            x0_est  = zeros(size(newX));
            xp0_est = x0_est;                        

            [x0,xp0] = decic(ODEfcn, 0, x0_est, [], xp0_est, [], options); 
                        
            options.InitialSlope = xp0;
        end
    else
        throw(me)
    end
end


function [ODEfcn, x0, options] = CalculateInitialCondition(o, options)

    Mass = @(t,y) o.MassMatrix.MassMatrix;
    Func = o.ODEFcn;

    x0_est  = o.InitialValue;
    xp0_est = x0_est;
    
    dae = @(t,y,yp) Mass(t,y)*yp-Func(t,y);                        
    [x0,xp0] = decic(dae, 0, x0_est, [], xp0_est, [], options); 

    options.Mass = Mass;
    options.InitialSlope = xp0;                        

    ODEfcn = Func;
end
