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
        odeResults
        odeSimStruct
    end

    properties (SetAccess=private, Hidden)
        % Version of this class       
        Ver (1,1) double = 1.1
    end

    methods
        function obj = odeSimulator(net, time, evs, opt)            
            arguments                
                net  (1,1) {mustBeA(net, 'PowerNetwork')}
                time 
                evs 
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

            obj.manage_time(time, evs);
            obj.initialize_odeSimulator;
        end        
    end
    
    methods (Access=private)       

        function manage_time(obj, time, varargin)
            % A method that generates a timetable for time events specified by a structure.
            % When performing dynamic simulation, events are extracted based on this timetable,
            % and the system is constructed and analyzed based on the extracted events.
            %
            % << Generated timetable >>
            %      Time   | event1 | event2 | event3 | event4 | event5 ...  
            %   ----------+--------+--------+--------+--------+-----------
            %     0~10[s] |   1    |    0   |    0   |   0    |   0   
            %    10~12[s] |   0    |    1   |    0   |   1    |   0   
            %    12~15[s] |   0    |    0   |    1   |   1    |   1   
            %       :         :         :        :       :        :
            %
            arguments
                obj
                time (:,2) double = zeros(0,2)                
            end
            arguments (Input, Repeating)
                varargin 
            end
            
            times = zeros(nargin-2,2);
            for k=1:nargin-2
                argi = varargin{k}.Time;
                if isscalar(argi)
                    times(k,:) = ones(1,2)*argi;
                else
                    times(k,:) = argi;
                end
            end
                        
            utimes = reshape(times, [], 1);
            if isempty(time) || ( max(time) <= max(utimes) )               
                time = [0, max(utimes)+10];
            end
            utime = unique([time(1); utimes; time(2)], "sorted", "first");
        
            all_time = [utime(1:end-1), utime(2:end)];
            
            vtab = size(all_time,1);
            rtab = size(times,1);
        
            tab = array2table(false(vtab,rtab));
            for i=1:vtab
                fti = all_time(i,1);
                eti = all_time(i,2);
                for j=1:rtab
                    ftj = times(j,1);
                    etj = times(j,2);
        
                    if (fti < etj) && (ftj < eti)
                        tab{i,j} = true;
                    elseif (fti == ftj) && (fti == etj)
                        tab{i,j} = true;
                    end
                end
            end

            if all(~tab{1,:})
                varargin = [{eventset("Time", all_time(1,:))}, varargin];
                tab = [array2table([true; false(vtab-1,1)], "VariableNames", "Var0"),tab];                
            end

            if all(~tab{end,:})
                varargin = [varargin, {eventset("Time", all_time(end,:))}];
                tab = [tab,array2table([false(vtab-1,1); true], "VariableNames", "Var "+"End")];
            end
            
            obj.ODEvnt = [obj.ODEvnt, varargin];
            obj.odeTimeTable = [array2table(all_time, "VariableNames", ["t1","t2"]), tab];
        end

        function clear_event(obj)
            obj.ODEvnt = [];
        end
     
        function manage_simResults(obj, sol, RM, EM, et)
            % Methods for managing simulation results.
            % Managed as table-type variables.
            % 
            % << Management of Simulation Results >>
            %
            %     Time [s]   | delta | omega |  eq  |  ed  | psiq ...  
            %   -------------+-------+-------+------+------+---------
            %         0      |  1.0  |   0   |  1.2 | 0.75 |  0.75   
            %         1      |  1.0  |   0   |  1.2 | 0.75 |  0.75   
            %         2      |  1.0  |   0   |  1.2 | 0.75 |  0.75   
            %         :         :        :       :        :
            %
            arguments
                obj 
                sol 
                RM %#ok
                EM
                et (1,1) logical = false
            end

            t = sol.Time;
            y = EM*sol.Solution;
            if isempty(obj.odeResults)
                ny = size(y,1);
                obj.odeResults = array2table(zeros(0,ny+1));
            end
            tab = array2table([t;y].');

            obj.odeResults = [obj.odeResults; tab];            

            if et
                a_bus = obj.odeNetwork.a_Bus;
                n_bus = numel(a_bus);                                

                sim = struct(  't',            [], ...
                               'X', cell(n_bus,1), ...
                             'ReV', cell(n_bus,1), ...
                             'ImV', cell(n_bus,1));

                odeTable = obj.odeResults(:,2:end);

                for i=1:n_bus
                    com = a_bus{i}.a_Component;
                    n_com = numel(com);

                    sim_com = cell(n_com,1);
                    for j=1:n_com
                        idx_com = com{j}.iv_odeX;
                        sim_com{j} = odeTable(:, idx_com);
                        sim_com{j}.Properties.VariableNames = com{j}.str_x;
                    end

                    sim(i).X = sim_com;            

                    sim(i).ReV = odeTable(:,a_bus{i}.iv_odeX(1));
                    sim(i).ImV = odeTable(:,a_bus{i}.iv_odeX(2));

                    sim(i).ReV.Properties.VariableNames = "Real";
                    sim(i).ImV.Properties.VariableNames = "Imag";

                    sim(i).t = obj.odeResults{:,1};
                end                

                obj.odeSimStruct = sim;
                
            end

        end

        function clear_simResults(obj)
            obj.odeResults = [];
        end

        function initialize_odeSimulator(obj)            
            % A method for assigning state variable numbers to each device and bus.
            % Execute this before performing analysis using the ODE solver.         

            bus = obj.odeNetwork.a_Bus;

            idx  = 0;
            idx_ = 0;
            for i=1:numel(bus)
                comp = bus{i}.a_Component;
                for j=1:numel(comp)
                    nx   = length(comp{j}.str_x);                        
                    idx_ = idx_ + nx;

                    % comp{j}.X_offset = zeros(size(comp{j}.str_x));
                    % comp{j}.U_offset = zeros(size(comp{j}.str_u));
        
                    if comp{j}.isController
                        con = comp{j}.a_LocalController{1};
        
                        con_nx = length(con.str_x);
                        con.iv_odeX = idx_ + (1:con_nx).';
                        idx_ = idx_ + con_nx;
        
                        nx = nx + con_nx;
            
                        if con.isController
                            sub_con = con.a_LocalController{1};                    
        
                            sub_con_nx = length(sub_con.str_x);
                            con.iv_odeX = idx_ + (1:sub_con_nx).';
                            idx_ = idx_ + sub_con_nx;
        
                            nx = nx + sub_con_nx;
                        end
                    end
        
                    comp{j}.iv_odeX = idx + (1:nx).';
                    idx = idx + nx;
                end
            end
        
            for i=1:numel(bus)
                bus{i}.iv_odeX = idx + (1:2).';
                idx = idx + 2;
            end

        end
        
    end

    methods (Hidden=true, Access={?odeSimulator, ?PowerNetwork})
        
        function odeX = getODEFunction(obj, t, x, Ymat, RM, EM, lg) %#ok 
            % A method for retrieving the DAE system to be analyzed.            
            
            x = EM*x; 

            odeX = zeros(size(x));
            odeV = zeros(size(obj.odeNetwork.a_Bus));

            net = obj.odeNetwork;
            bus = net.a_Bus;                                     

            for i=1:numel(bus)
                bi = bus{i};
                cm = bi.a_Component;
                Vi = x(bi.iv_odeX);                                

                for j=1:numel(cm)
                    cj = cm{j};
                    xi = x(cj.iv_odeX);        
                    ui = cj.cv_Uequilibrium + cj.U_offset;                    
            
                    dx = cj.fv_odeDiff(t, xi, Vi, ui);
                    Ix = cj.isConnect * cj.fv_odeI(t, xi, Vi, ui);
                                
                    odeX([cj.iv_odeX; bi.iv_odeX]) = odeX([cj.iv_odeX; bi.iv_odeX]) + [dx; -real(Ix); -imag(Ix)];                                        
                end

                odeV(i) = [1,1j]*Vi;
            end        

            I = Ymat*odeV;
            for i=1:numel(bus)
                idx = bus{i}.iv_odeX;
                odeX(idx) = odeX(idx) + [real(I(i)); imag(I(i))]; 
            end
                        
            odeX = odeX(lg); 
        end
                
        function jac = getODEJacobian(obj, t, x, Ymat, RM, EM, lg) %#ok    
            % A method for obtaining the Jacobian of the DAE system under analysis.

            x = EM*x;
            
            net = obj.odeNetwork;
            bus = net.a_Bus;

            jac = zeros(numel(x), numel(x));

            lv = zeros(size(bus));

            for i=1:numel(bus)
                bi = bus{i};
                cm = bi.a_Component;
                Vi = x(bi.iv_odeX);                

                for j=1:numel(cm)
                    cj = cm{j};
                    xi = x(cj.iv_odeX);        
                    ui = cj.cv_Uequilibrium + cj.U_offset;                    

                    lx = [cj.iv_odeX; bi.iv_odeX];
                                
                    jacA = cj.JacobiA(t, xi, Vi, ui);
                    jacB = cj.JacobiB(t, xi, Vi, ui);
                    jacC = cj.JacobiC(t, xi, Vi, ui);
                    jacD = cj.JacobiD(t, xi, Vi, ui);
            
                    jac(lx,lx) = jac(lx,lx) + [jacA, jacB; -jacC, -jacD]; 
                end

                lv(2*i+[-1;0]) = bi.iv_odeX; 
            end                               
        
            G = real(Ymat);
            B = imag(Ymat);

            lo = lv(1:2:end);
            le = lv(2:2:end);
            
            jac(lo,lo) = jac(lo,lo) + G;
            jac(lo,le) = jac(lo,le) - B;
            jac(le,lo) = jac(le,lo) + B;
            jac(le,le) = jac(le,le) + G; 
            
            jac = jac(lg,lg);

        end

        function [init, Mass] = getODESet(obj, x0, Mass, RM, EM)

            bus  = obj.odeNetwork.a_Bus;
            nbus = numel(bus);

            if isempty(x0)
                xi   = cell(nbus,1);
                vi   = cell(nbus,1);
                for i=1:nbus
                    busi  = bus{i};
                    xi{i} = cell2mat( cellfun(@(B) B.cv_Xequilibrium + B.X_offset, busi.a_Component, 'UniformOutput', false) );
                    vi{i} = [real(busi.c_Vequilibrium); imag(busi.c_Vequilibrium)];                 
                end             
    
                init = RM * [vertcat(xi{:}); vertcat(vi{:})];
            else
                init = RM*x0;
            end            
            
            if isempty(Mass)
                
                x    = EM*init;            
                nx   = numel(x);
                Mass = zeros(nx,nx);

                for i=1:nbus
                    Vi   = x(bus{i}.iv_odeX);                
                    comp = bus{i}.a_Component;
                    for j=1:numel(comp)                    
                        ci = comp{j}.iv_odeX;
                        ui = comp{j}.cv_Uequilibrium;
                        
                        xi = x(ci);
                        mi = comp{j}.rm_odeMass([], xi, Vi, ui);
                        Mass(ci,ci) = Mass(ci,ci) + mi; 
                    end
                end            
            end

            Mass = RM * Mass * RM.';            
        end
        
        function [EM, RM, lg] = getStateMatrix(obj, event, tab)
            bus = obj.odeNetwork.a_Bus;
            evs = event( tab{1,:} );
                    
            bnms = cell2mat( cellfun(@(B) B.FltBus, evs, 'UniformOutput', false) );
            cnms = cell2mat( cellfun(@(B) B.TrpCmp, evs, 'UniformOutput', false) );

            if isempty(bnms)
                bnms = "";
            end

            if isempty(cnms)
                cnms = "";
            end

            bnms_all = cell2mat( cellfun(@(B) repmat(B.str_tag, [2,1]), bus, 'UniformOutput', false) );

            cnms_all = cell(size(bus));
            for i=1:numel(bus)
                bnm = bus{i}.str_tag;
                bus{i}.l_isFault = ismember(bnm, bnms_all);


                cmp = bus{i}.a_Component;                                
                c_c = cell(size(cmp));
                for j=1:numel(cmp)
                    c_c{j} = repmat( cmp{j}.str_tag, size(cmp{j}.str_x) );
                    
                    cmp{j}.isConnect = ~ismember(cmp{j}.str_tag, cnms);
                end
                cnms_all{i} = cell2mat(c_c);
            end
            cnms_all = cell2mat(cnms_all);

            lg = ismember([cnms_all;bnms_all],[cnms;bnms]);

            nlg = length(lg);

            EM = eye(nlg);
            RM = eye(nlg);

            EM = EM(:,~lg);
            RM = RM(~lg,:);
            
        end

        function [x, Mass] = getTransitionSet(obj, x, Mass, RM, EM) %#ok
            bus  = obj.odeNetwork.a_Bus;
            nbus = numel(bus);

            x = EM*x;
            Mass = EM * Mass * EM.';

            for i=1:nbus
                com = bus{i}.a_Component;
                ncom = numel(com);

                for j=1:ncom
                    if isa(com{j}, 'component.generator.abstract') && ~com{j}.isConnect
                        c_idx = com{j}.iv_odeX;
                        b_idx = bus{i}.iv_odeX;
                        [x(c_idx), ~] = com{j}.get_equilibrium([1,1j]*x(b_idx), 0+1j*0);                         

                        Mass(c_idx, c_idx) = com{j}.rm_odeMass([], [], x(b_idx), []);
                    end
                end
            end            

        end

    end

    methods

        function [tab, stc] = simulate(obj)
            
            o = guilda.internal.ode(obj); 

            options = odeset("RelTol", o.RelativeTolerance, "AbsTol", o.AbsoluteTolerance);

            Ymat = obj.odeNetwork.get_admittance_matrix.Variables;

            if isempty(obj.ODEvnt)                
                obj.manage_time([0,10], eventset("Time", [0,10]));
            end

            tp = 1;
            np = size(obj.ODEvnt,2);

            obj.clear_simResults();

            x0   = [];
            Mass = [];

            while tp <= np          

                TT = obj.odeTimeTable(tp,:); % Retrieving events related to ground faults and circuit tripping.
                                
                [EM, RM, lg] = obj.getStateMatrix(obj.ODEvnt, TT(1,3:end)); 
                [x0, Mass] = obj.getODESet(x0, Mass, RM, EM);

                o.InitialValue = x0;
                o.ODEFcn       = @(t,x) obj.getODEFunction(t,x,Ymat,RM,EM,~lg);                                       
                o.Jacobian     = @(t,x) obj.getODEJacobian(t,x,Ymat,RM,EM,~lg);
                o.MassMatrix   = Mass;                
            
                try
                    t1 = TT{1, 't1'};
                    t2 = TT{1, 't2'};

                    startTime = tic;
                    stopTime  = 5;
                    o.EventDefinition = odeEvent("EventFcn",@(t,y) checkSimulationTime(t,y,startTime,stopTime),"Response","stop");        
                    
                    sol = solve(o, 0, t2-t1); % When solving the equation, specify [0, duration of each phase]

                    et = isequal(tp,np);     

                    sim_sol.Time = sol.Time + t1;
                    sim_sol.Solution = sol.Solution;
                    obj.manage_simResults(sim_sol, RM, EM, et);
                catch me                    

                    splitMSG = strsplit(me.identifier,':');                                        

                    switch splitMSG{end}

                        case 'IndexGTOne'

                            % If the DAE index is greater than 1, construct a new DAE sequence with a reduced index.
                            [ODEfcn, x0, options] = ReduceDAEIndex(obj, o, options);

                        case 'NeedBetterY0'

                            % If an error related to initial value inconsistencies occurs, 
                            % calculate a state that is consistent with the DAE system.
                            [ODEfcn, x0, options] = CalculateInitialCondition(o, options);

                        otherwise
                            throw(me)
                                                    
                    end
                   

                    % After performing error bundling, solve the DAE system again.
                    try
                        [t,y] = ode15s(ODEfcn, time, x0, options);
                        sol = struct(    'Time', t.', ...
                                     'Solution', y.');
                           
                        obj.manage_simResults( sol, RM, EM, isequal(tp,np) )

                    catch ME
                        error(msg('GUILDA:odeSimulator:UnfeasibleDAE'))
                    end
                end
                                

                tp = tp + 1;

                [x0, Mass] = obj.getTransitionSet(reshape(sol.Solution(:,end),[],1), o.MassMatrix.MassMatrix, RM, EM);
            end

            tab = obj.odeResults;
            stc = obj.odeSimStruct;
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
