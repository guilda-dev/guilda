classdef (Sealed = true) odeEventSet < auxiliary
% Disturbance event of a time simulation (net.simulate).
%
% An event names a time span and what happens during it: a bus fault, a unit trip, an
% offset of the initial states, or an input added to a component. Give the events to
% net.simulate; the simulation is split into phases where the set of active events does
% not change. An event refers to the network it was created for.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.initialize();
% fault  = odeEventSet("fault", net, "TimeSpan", [1, 1.05], "FaultBus", "B008");
% trip   = odeEventSet("trip",  net, "TimeSpan", [1, 2], "TripUnit", "SG1B002");
% offset = odeEventSet("offset", net, "TimeSpan", 0, "OffsetUnit", "SG1B001", ...
%                      "OffsetState", "delta", "OffsetValue", 0.1);
% input  = odeEventSet("input", net, "TimeSpan", [1, 1.5], "InputUnit", "SG1B002", ...
%                      "InputName", ["Pmech"; "Vfield"], "InputValue", {0.05; @(t) 0.01*t});
% result = net.simulate([0, 10], fault, input);
% ```
%
% See also odeSimulator, odeSimulationResult, PowerNetwork.simulate

    properties (Access=private,Hidden) % Tag
        str_tag 
    end

    properties (Access=public) % Event
        % [s] Time span of the event: [t_start, t_end], or t_start alone.
        % An offset (OffsetUnit) applies at t_start; a fault, trip or input lasts from t_start
        % to t_end.
        % <@Type> double (1x1 or 1x2)
        TimeSpan    {mustBeRow, validateTimeSpanSize} = [0,10]

        % Tag of the component whose initial states are offset.
        OffsetUnit  (1,1) string 

        % Names of the states to offset (e.g. "delta", "omega").
        OffsetState (:,1) string 

        % Offsets added to the states of OffsetState, in the same order.
        OffsetValue (:,1) double 

        % Tags of the buses with a ground fault (voltage 0) during the event.
        FaultBus    (:,1) string 

        % Tags of the components or global controllers disconnected during the event.
        TripUnit    (:,1) string         

        % Tag of the component to which an input is added.
        InputUnit   (1,1) string

        % Names of the inputs of InputUnit (e.g. "Pmech", "Vfield").
        InputName   (:,1) string

        % Values added to the inputs of InputName, in the same order.
        % A number, or a cell of numbers and function handles f(t) of the time since t_start.
        % <@Type> double | cell | function_handle (n x 1)
        InputValue  (:,1) {mustBeA(InputValue, {'double','cell','function_handle'})}
    end

    properties (Access=private) % Simulation data
        odeNetwork        
        odeTimeSpan
        odeIteration (1,1) double = nan
    end

    properties (Access=private) % Index data
        sv_Btag
        sv_Ctag
        rv_Brep
        rv_Crep
    end

    properties (SetAccess=private, Hidden) % Version
        Ver (1,1) double = 1.1 % Version of this class.
    end

    methods
        function obj = odeEventSet(tag, net, opt)
        % Create an event for net.simulate.
        %
        % The Name-Value options are the public properties (TimeSpan, FaultBus, TripUnit,
        % OffsetUnit, OffsetState, OffsetValue, InputUnit, InputName, InputValue).
            arguments
                tag (1,1) string % Name of the event, shown in the phase table.
                net {mustBeA(net, 'PowerNetwork')} % Network the event belongs to.
                opt.?odeEventSet
            end   
            obj.str_tag = tag;
            obj.odeNetwork = net;                                                            

            strNames = fieldnames(opt);

            idx = 1;
            while idx <= numel(strNames)
                idx_name = strNames{idx};                
                obj.(idx_name) = opt.(idx_name);
                idx = idx + 1;
            end            

            cv_bus = net.a_Bus;            
            sv_tag = cell(size(cv_bus));                
            rv_rep = cell(size(cv_bus));                          

            for i=1:numel(cv_bus)                              
                a_Comp = cv_bus{i}.a_Component;                                                   
                [sv_tag{i}, rv_rep{i}] = getTM(a_Comp);                                
            end

            % global controllers follow the components in the state vector (see odeSimulator)
            a_GCs = obj.odeNetwork.a_GlobalController;
            for k = 1:numel(a_GCs)
                sv_tag = [sv_tag; {a_GCs{k}.str_tag}]; %#ok
                rv_rep = [rv_rep; {numel(a_GCs{k}.sv_x)}]; %#ok
            end

            obj.sv_Btag = string(net.a_Bus);
            obj.sv_Ctag = vertcat(sv_tag{:});

            obj.rv_Brep = 4*ones(i,1);            
            obj.rv_Crep = vertcat(rv_rep{:});
            
        end
    end    

    methods (Access={?odeSimulator})
        function [odeTimeTable, odeEvents] = table(obj, varargin, opt)
            % Method that generates a timetable for time events specified by a structure.
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
            
            arguments
                obj                
            end
            arguments (Input, Repeating)
                varargin {mustBeA(varargin, 'odeEventSet')}
            end
            arguments
                opt.time (:,1) double
            end

            odeEvents = [{obj},varargin];
            cellfun(@(o) o.validate_input(), odeEvents);
            
            times = zeros(nargin,2);
            for k=1:nargin
                argi = odeEvents{k}.TimeSpan;
                if isscalar(argi)
                    times(k,:) = ones(1,2)*argi;
                else
                    times(k,:) = argi;
                end
            end
                        
            if numel(opt.time) >= 2
                lv_out = times(:,2) < opt.time(1) | times(:,1) > opt.time(end);
                for k = find(lv_out(:))'
                    warning('GUILDA:odeEventSet:OutsideTimeSpan', '%s', ...
                        msg('GUILDA:odeEventSet:OutsideTimeSpan', char(odeEvents{k}.str_tag), ...
                            mat2str(odeEvents{k}.TimeSpan), mat2str(opt.time([1,end]).')));
                end
            end

            all_time = getTimeSpan(times, opt.time);                   
            
            vtab = size(all_time,1);
            rtab = size(times,1);
        
            varNames = cellfun(@(o) o.str_tag, odeEvents);
            tab = array2table(false(vtab,rtab), "VariableNames", varNames);
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

            for IT = 1:vtab
                if all( ~tab{IT,:} )
                    lv_tab     = false(vtab,1);
                    lv_tab(IT) = true;
                    tabInsert  = table(lv_tab, 'VariableNames', "NoAction"+num2str(IT));
                    oevInsert  = odeEventSet("NoAction"+num2str(IT), obj.odeNetwork, "TimeSpan", all_time(IT,:));

                    tab = [tab, tabInsert]; %#ok
                    odeEvents = [odeEvents, {oevInsert}]; %#ok
                end
            end
                                        
            odeTimeTable = [array2table(all_time, "VariableNames", ["t1","t2"]), tab];
        end
        
        function setEventCondition(obj, varargin, opt)
            arguments
                obj                                 
            end
            arguments (Input, Repeating)
                varargin {mustBeA(varargin, 'odeEventSet')}
            end
            arguments
                opt.TimePhase 
                opt.Iteration {mustBeInteger}
            end
            
            net = obj.odeNetwork;
            bus = net.a_Bus;

            odeEvents = [{obj},varargin]';            

            osU = cellfun(@(c) c.OffsetUnit,  odeEvents);
            % An offset is applied only once, in the phase where its event starts.
            lv_osStart = cellfun(@(c) c.TimeSpan(1) == opt.TimePhase(1), odeEvents) | opt.Iteration == 1;
            osU(~lv_osStart) = "";
            osX = cellfun(@(c) c.OffsetState, odeEvents, 'UniformOutput', false);
            osV = cellfun(@(c) c.OffsetValue, odeEvents, 'UniformOutput', false);            

            inU = cellfun(@(c) c.InputUnit,  odeEvents);
            inN = cellfun(@(c) c.InputName,  odeEvents, 'UniformOutput', false);
            inV = cellfun(@(c) c.InputValue, odeEvents, 'UniformOutput', false);

            for i=1:numel(bus)
                comp = bus{i}.a_Component;
                for j=1:numel(comp)                    
                    c_tag = comp{j}.str_tag;
                    l_osU = ismember(osU, c_tag);
                    l_inU = ismember(inU, c_tag);                    
                    
                    comp{j}.rv_Xoffset = zeros(size(comp{j}.sv_x(:)));                                       

                    % Offsets and inputs are matched by name and summed over the events.
                    for k = find(l_osU(:))'
                        [lv_X, loc] = ismember(osX{k}, comp{j}.sv_x);
                        osVk = osV{k} .* ones(size(osX{k}));
                        comp{j}.rv_Xoffset(loc(lv_X)) = comp{j}.rv_Xoffset(loc(lv_X)) + osVk(lv_X);
                    end

                    ini = repmat({@(t) 0}, size(comp{j}.sv_u(:)));
                    lv_set = false(size(ini));
                    for k = find(l_inU(:))'
                        [lv_N, loc] = ismember(inN{k}, comp{j}.sv_u);

                        exV = inV{k};
                        if ~iscell(exV)
                            if isa(exV, 'function_handle')
                                exV = {exV};
                            else
                                exV = num2cell(exV);
                            end
                        end
                        if isscalar(exV)
                            exV = repmat(exV, size(inN{k}));
                        end

                        for ni = find(lv_N(:))'
                            f1 = event2fhandle(exV{ni}, odeEvents{k});
                            if lv_set(loc(ni))
                                f0 = ini{loc(ni)};
                                ini{loc(ni)} = @(t) f0(t) + f1(t);
                            else
                                ini{loc(ni)} = f1;
                                lv_set(loc(ni)) = true;
                            end
                        end
                    end
                    comp{j}.rv_Uoffset = @(t) cellfun(@(f) f(t), ini);
                end
            end            

            for ev = 1:numel(odeEvents)
                odeEvents{ev}.odeIteration = opt.Iteration; 
            end

            function exV = event2fhandle(exV, oev)
                if isa(exV, 'double')
                    exV = @(t) exV;

                elseif isa(exV, 'function_handle')
                    if nargin(exV) ~= 1
                        error('GUILDA:odeEventSet:InvalidNargin', '%s', msg('GUILDA:odeEventSet:InvalidNargin'))
                    end

                    % t of each phase starts at 0; the function takes the time since the event start.
                    ts = opt.TimePhase(1) - oev.TimeSpan(1);
                    exV = @(t) exV(t+ts);
                else
                    error('GUILDA:odeEventSet:InvalidInputType', '%s', msg('GUILDA:odeEventSet:InvalidInputType'))
                end

            end
        end

        function [EM, RM, lv_FBorTC, varargout] = getInitialCondition(obj, varargin, opt)
            arguments
                obj                 
            end
            arguments (Input, Repeating)
                varargin {mustBeA(varargin, 'odeEventSet')} 
            end
            arguments
                opt.x0 (:,1) double = []
                opt.M0 (:,:) double = []
            end

            a_bus = obj.odeNetwork.a_Bus;
            odeEvents = [{obj},varargin]';
                    
            BusFault = cell2mat( cellfun(@(B) B.FaultBus, odeEvents, 'UniformOutput', false) );
            CompTrip = cell2mat( cellfun(@(B) B.TripUnit, odeEvents, 'UniformOutput', false) );                                    
            
            rm_M = zeros(0,0);
            rv_V = cell(size(a_bus));
            rv_X = cell(size(a_bus));            

            for i=1:numel(a_bus)
                iBus = a_bus{i};                
                iBus.l_isFault = ismember(iBus.str_tag, BusFault);

                Ieq = iBus.c_Iequilibrium;
                Veq = iBus.c_Vequilibrium;

                rv_V{i} = [real(Veq); imag(Veq); real(Ieq); imag(Ieq)];

                a_Comp = iBus.a_Component;                                                                              
                [rv_X{i}, rm_M, CompTrip] = getXM(a_Comp, rv_X{i}, rm_M, CompTrip);                
            end

            a_GCs = obj.odeNetwork.a_GlobalController;
            for k = 1:numel(a_GCs)
                a_GC = a_GCs{k};

                rm_M(a_GC.iv_odeX, a_GC.iv_odeX) = a_GC.f_Mass([], [], [], [], []);
                rv_X = [rv_X; {a_GC.rv_Xequilibrium}]; %#ok
            end            

            Btag_all  = repelem(obj.sv_Btag, obj.rv_Brep);
            Ctag_all  = repelem(obj.sv_Ctag, obj.rv_Crep);
            lv_FBorTC = ismember([Ctag_all; Btag_all], [CompTrip; BusFault]);

            nFBorTC = length(lv_FBorTC);

            EM = eye(nFBorTC);
            RM = eye(nFBorTC);

            EM = EM(:, ~lv_FBorTC);
            RM = RM(~lv_FBorTC, :);
            
            x0 = opt.x0;
            if isempty(x0)
                x0 = [vertcat(rv_X{:}); vertcat(rv_V{:})];
            else
                % Offsets of the events starting in this phase (see setEventCondition)
                for i=1:numel(a_bus)
                    a_Comp = a_bus{i}.a_Component;
                    for j=1:numel(a_Comp)
                        idx = a_Comp{j}.iv_odeX;
                        x0(idx) = x0(idx) + a_Comp{j}.rv_Xoffset;
                    end
                end
            end
            varargout{1} = RM * x0;                        
            
            M0 = opt.M0;
            if isempty(M0)
                nB = numel(a_bus);
                M0 = blkdiag(rm_M, zeros(nB*4, nB*4));
            end
            varargout{2} = RM * M0 * RM.';                    
                                    
        end    

        function EventSettings = Event2State(obj, varargin, opt)
            arguments
                obj                                 
            end
            arguments (Input, Repeating)
                varargin {mustBeA(varargin, 'odeEventSet')}
            end
            arguments                
                opt.ODEResults 
                opt.ODEYmatrix
            end

            a_bus = obj.odeNetwork.a_Bus;
            a_cmp = cellfun(@(bi) bi.a_Component, a_bus, 'UniformOutput', false);
            a_cmp = vertcat(a_cmp{:});
            odeEvents = [{obj},varargin]';
                                
            CompTrip = cell2mat( cellfun(@(B) B.TripUnit, odeEvents, 'UniformOutput', false) );                                    
            
            % Tripped units by tag (sv_Ctag also lists local and global controllers, so its
            % positions do not match a_cmp); a tripped global controller is marked too
            a_unit   = [a_cmp; obj.odeNetwork.a_GlobalController];
            lv_Ctagi = ismember(string(a_unit), CompTrip);
            
            B_sti = cell2mat( cellfun(@(bi) bi.iv_odeX, a_bus, 'UniformOutput', false) );
            C_sti = cell2mat( cellfun(@(ci) ci.iv_odeX, a_unit(lv_Ctagi), 'UniformOutput', false) );                        

            Time = opt.ODEResults.Time;
            xsol = opt.ODEResults.Solution;

            if any(lv_Ctagi)
                xsol(:, C_sti) = NaN;
            end

            Vsol = xsol(:, B_sti);
            Isol = opt.ODEYmatrix * Vsol.';
            
            t = array2table(Time);
            x = array2table(xsol);
            I = array2table(Isol.');

            EventSettings = table(t,x,I, 'VariableNames', {'t','x','i'});
        end
        
    end

    methods (Access=private)
        function validate_input(obj)
            % InputUnit, InputName and InputValue are checked before the integration starts.
            if strlength(obj.InputUnit) == 0 && isempty(obj.InputName)
                return
            end
            a_comp = cellfun(@(b) b.a_Component, obj.odeNetwork.a_Bus, 'UniformOutput', false);
            a_comp = vertcat(a_comp{:});
            sv_tag = string(cellfun(@(c) c.str_tag, a_comp, 'UniformOutput', false));
            lv_cmp = sv_tag == obj.InputUnit;
            if ~any(lv_cmp)
                error('GUILDA:odeEventSet:UnknownInputUnit', '%s', ...
                    msg('GUILDA:odeEventSet:UnknownInputUnit', char(obj.str_tag), char(obj.InputUnit)));
            end
            sv_u = string(a_comp{find(lv_cmp,1)}.sv_u(:));
            lv_bad = ~ismember(obj.InputName, sv_u);
            if any(lv_bad)
                error('GUILDA:odeEventSet:UnknownInputName', '%s', ...
                    msg('GUILDA:odeEventSet:UnknownInputName', char(obj.str_tag), ...
                        char(join(obj.InputName(lv_bad), ", ")), char(obj.InputUnit), char(join(sv_u, ", "))));
            end
            exV = obj.InputValue;
            if ~iscell(exV)
                exV = {exV};
            end
            for k = 1:numel(exV)
                if isa(exV{k}, 'function_handle') && nargin(exV{k}) ~= 1
                    error('GUILDA:odeEventSet:InvalidNargin', '%s', msg('GUILDA:odeEventSet:InvalidNargin'));
                end
            end
        end
    end

end


function [sv_tag, rv_rep] = getTM(OBJs, sv_tag, rv_rep)
    if nargin < 2
        sv_tag = [];
        rv_rep = [];
    end

    for no = 1:numel(OBJs)
        OBJ = OBJs{no};
        rs_idx = numel([OBJ.sv_x; OBJ.sv_u]);                
        
        sv_tag = [sv_tag; OBJ.str_tag]; %#ok
        rv_rep = [rv_rep; rs_idx];      %#ok  

        if ~isempty(OBJ.a_LocalController)
            a_LC = OBJ.a_LocalController(1);
            [sv_tag, rv_rep] = getTM(a_LC, sv_tag, rv_rep);
        end
    end
end

function [rv_x0, rm_Mass, TC] = getXM(OBJs, rv_x0, rm_Mass, TC)

    for no = 1:numel(OBJs)
        OBJ = OBJs{no};
        rx_idx = [OBJ.iv_odeX; OBJ.iv_odeU]; 
        nu_idx = numel(OBJ.iv_odeU); 
        
        OBJ.l_isConnect = ~ismember(OBJ.str_tag, TC);  
        rv_x0 = [rv_x0; OBJ.rv_Xequilibrium + OBJ.rv_Xoffset; OBJ.rv_Uequilibrium + OBJ.rv_Uoffset(0)]; %#ok
        
        rm_Mass(rx_idx, rx_idx) = blkdiag(OBJ.f_Mass([],[],[],[],[]), zeros(nu_idx, nu_idx));

        if ~isempty(OBJ.a_LocalController)
            a_LC = OBJ.a_LocalController(1);
            [rv_x0, rm_Mass, TC] = getXM(a_LC, rv_x0, rm_Mass, TC);
        end
    end
end