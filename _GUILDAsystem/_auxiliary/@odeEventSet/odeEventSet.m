classdef (Sealed = true) odeEventSet < handle

% DODEEVENTSET provides options for dynamic simulation in the form of a structure.
%    EVENTSET = (Name1, Val1, Names2, Val2, ...) is a function that outputs options 
% 　　for dynamic mutation in the form of a structure. Options can be specified 
% 　　by selecting properties and assigning values, or by passing other structures as arguments. 
%
% ODEEVENTSET PROPERTIES
%
% TimeSpan - Simulation Time Span [ scalar or 1x2 double vecator ]
%    This two-dimensional vector of positive double constants represents the integration time for a phase. 
%    Since eventset outputs events within a time phase in structured format, when multiple events exist, 
%    you must create a struct corresponding to each time event from the eventset function.
%
% OffsetUnit - Generator with Perturbation Applied to State Variables [ string scalar ]
%    Specify the generator that applies perturbations to the state variables.
% 　　You can also specify an integer scalar or vector, or a device tag.
%
% OffsetState - Perturbation-induced state [ string scalar or vector ]
%    Specify the state variables to which perturbations are applied. State variables can be specified 
%    by number or by name. Both scalar and vector specifications are accepted.
%
% OffsetValue - Perturbation Applied to The State [ double scalar or vector ]
%    This property specifies perturbations applied to the state of equipment such as generators. 
%    Perturbations are specified as a scalar or a vector depending on the number of state variables 
%    to which the perturbation is applied. The specific state variables to which the perturbation 
%    applied are specified later using OffsetX.
%
% FaultBus - Fault Bus [ string scalar or vector ]
%    Specify the busbar causing the ground fault. Specify either the busbar number or the busbar tag. 
%    Accepts input as a scalar or vector.
%
% TripUnit - Trip Component [ string scalar or vector ]
%    Specify the device to be disassembled. You can specify the device's tag or number using a scalar or vector.
%
% InputUnit - Component to which an input is applied [ string scalar  ]
%    Specify which machine to apply the input to when requesting an input response. 
%    The term "machine" here refers to synchronous generators or synchronous phase-shifting machines.
%
% InputName - Component Input [ string scalar or vector ]
%    Specify which input to focus on when implementing the input response. 
%    For example, in the case of a synchronous generator, 
%    specify either the mechanical input from the turbine or the field voltage.
%
% InputValue - Input Value [ double \ scalar or vector, function_handle ]
%    When requesting an input response, specify the magnitude of the input using a scalar or a vector.
%
    properties (Access=private,Hidden)
        str_tag 
    end

    properties (Access=public)
        TimeSpan    {mustBeRow, validateTimeSpanSize} = [0,10]
        OffsetUnit  (1,1) string 
        OffsetState (:,1) string 
        OffsetValue (:,1) double 
        FaultBus    (:,1) string 
        TripUnit    (:,1) string         
        InputUnit   (1,1) string
        InputName   (:,1) string
        InputValue  (:,1) {mustBeA(InputValue, {'double','cell','function_handle'})}
    end

    properties (Access=private)
        odeNetwork        
        odeTimeSpan
        odeIteration (1,1) double = nan
    end

    properties (Access=private)
        sv_Btag
        sv_Ctag
        rv_Brep
        rv_Crep
    end

    properties (SetAccess=private, Hidden)        
        Ver (1,1) double = 1.1
    end

    methods
        function obj = odeEventSet(tag, net, opt)
            arguments
                tag (1,1) string
                net {mustBeA(net, 'PowerNetwork')}
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

            if ~isempty(obj.odeNetwork.a_GlobalController)
                a_GC = obj.odeNetwork.a_GlobalController{1};                
                sv_tag = [sv_tag; {a_GC.str_tag}];
                rv_rep = [rv_rep; {numel(a_GC.str_x)}];
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
            
            times = zeros(nargin,2);
            for k=1:nargin
                argi = odeEvents{k}.TimeSpan;
                if isscalar(argi)
                    times(k,:) = ones(1,2)*argi;
                else
                    times(k,:) = argi;
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
                    
                    comp{j}.X_offset = zeros(size(comp{j}.str_x(:)));                                       

                    if any(l_osU)
                        lv_X = ismember(comp{j}.str_x, osX{l_osU});                        
                        comp{j}.X_offset(lv_X) = comp{j}.X_offset(lv_X) + osV{l_osU};
                    end                    

                    ini = repmat({@(t) 0}, size(comp{j}.str_u(:)));
                    if any(l_inU)
                        l_inN = ismember(comp{j}.str_u, inN{l_inU});                                                
                        
                        exV = inV{l_inU};                                                                                                
                        if ~iscell(exV)
                            if isa(exV, 'function_handle')
                                exV = {exV};
                            else
                                exV = arrayfun(@(exv) {exv}, exV);                            
                            end                            
                        end

                        for ni = 1:numel(exV)                                
                            exV{ni} = event2fhandle(exV{ni});
                        end
                        ini(l_inN) = exV;
                    end
                    comp{j}.U_offset = @(t) cellfun(@(f) f(t), ini);
                end
            end            

            for ev = 1:numel(odeEvents)
                odeEvents{ev}.odeIteration = opt.Iteration; 
            end

            function exV = event2fhandle(exV)
                if isa(exV, 'double')
                    exV = @(t) exV;

                elseif isa(exV, 'function_handle')
                    if nargin(exV) ~= 1
                        error(msg('GUILDA:odeEventSet:InvalidNargin'))
                    end

                    ts = opt.TimePhase(1) - odeEvents{l_inU}.TimeSpan(1);
                    if odeEvents{l_inU}.odeIteration+1 == opt.Iteration
                        exV = @(t) exV(t+ts);
                    end
                else
                    error(msg('GUILDA:odeEventSet:InvalidInputType'))
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

            if ~isempty(obj.odeNetwork.a_GlobalController)
                a_GC = obj.odeNetwork.a_GlobalController{1};

                rm_M(a_GC.iv_odeX, a_GC.iv_odeX) = a_GC.rm_odeMass([], [], [], [], []);
                rv_X = [rv_X; {a_GC.cv_Xequilibrium}];                
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
            
            lv_Ctagi = ismember(obj.sv_Ctag, CompTrip);            
            
            B_sti = cell2mat( cellfun(@(bi) bi.iv_odeX, a_bus, 'UniformOutput', false) );
            C_sti = cell2mat( cellfun(@(ci) ci.iv_odeX, a_cmp(lv_Ctagi), 'UniformOutput', false) );                        

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

end


function [sv_tag, rv_rep] = getTM(OBJs, sv_tag, rv_rep)
    if nargin < 2
        sv_tag = [];
        rv_rep = [];
    end

    for no = 1:numel(OBJs)
        OBJ = OBJs{no};
        rs_idx = numel([OBJ.str_x; OBJ.str_u]);                
        
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
        
        OBJ.isConnect = ~ismember(OBJ.str_tag, TC);  
        rv_x0 = [rv_x0; OBJ.cv_Xequilibrium + OBJ.X_offset; OBJ.cv_Uequilibrium + OBJ.U_offset(0)]; %#ok
        
        rm_Mass(rx_idx, rx_idx) = blkdiag(OBJ.rm_odeMass([],[],[],[],[]), zeros(nu_idx, nu_idx));

        if ~isempty(OBJ.a_LocalController)
            a_LC = OBJ.a_LocalController(1);
            [rv_x0, rm_Mass, TC] = getXM(a_LC, rv_x0, rm_Mass, TC);
        end
    end
end