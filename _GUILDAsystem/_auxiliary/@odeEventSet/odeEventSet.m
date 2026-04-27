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

        end
    end    

    methods (Access={?odeSimulator})
        function [odeTimeTable, events] = table(obj, varargin, opt)
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

            fnp={};
            enp={};
            if all(~tab{1,:})         
                fnp = {odeEventSet("fNoOP", obj.odeNetwork, "TimeSpan", times(1,:))};
                tab = [array2table([true; false(vtab-1,1)], "VariableNames", "fNoOp"),tab];                
            end

            if all(~tab{end,:})                                
                enp = {odeEventSet("eNoOP", obj.odeNetwork, "TimeSpan", times(end,:))};
                tab = [tab,array2table([false(vtab-1,1); true], "VariableNames", "eNoOp")];
            end
                            
            events = [fnp, odeEvents, enp];
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
                    
                    comp{j}.X_offset = zeros(size(comp{j}.str_x));                                       

                    if any(l_osU)
                        lv_X = ismember(comp{j}.str_x, osX{l_osU});                        
                        comp{j}.X_offset(lv_X) = comp{j}.X_offset(lv_X) + osV{l_osU};
                    end                    

                    ini = repmat({@(t,x) 0}, size(comp{j}.str_u));
                    if any(l_inU)
                        l_inN = ismember(comp{j}.str_u, inN{l_inU});                                                
                        
                        exV = inV{l_inU};                                                                        
                        if iscell(exV)
                            for ni = 1:numel(exV)
                                if isa(exV{ni}, 'double')
                                    exV{ni} = @(t,x) exV{ni};

                                elseif isa(exV{ni}, 'function_handle')
                                    if nargin(exV{ni}) ~= 2
                                        error(msg('GUILDA:odeEventSet:InvalidNargin'))
                                    end

                                    ts = opt.TimePhase(1) - odeEvents{l_inU}.TimePhase(1);
                                    if odeEvents{l_inU}.odeIteration+1 == opt.Iteration
                                        exV{ni} = @(t,x) exV{ni}(t+ts,x);
                                    end
                                else
                                    error(msg('GUILDA:odeEventSet:InvalidInputType'))
                                end
                            end
                            ini(l_inN) = exV;
                        else                            
                            if isa(exV, 'double')
                                ini(l_inN) = arrayfun(@(in) @(t,x) in, exV, 'UniformOutput', false);      

                            elseif isa(exV, 'function_handle')
                                if nargin(exV) ~= 2
                                    error(msg('GUILDA:odeEventSet:InvalidNargin'))
                                end
                                ini{l_inN} = exV;

                            else
                                error(msg('GUILDA:odeEventSet:InvalidInputType'))
                            end
                        end                        
                    end
                    comp{j}.U_offset = @(t,x) cellfun(@(f) f(t,x), ini);
                end
            end            

            for ev = 1:numel(odeEvents)
                odeEvents{ev}.odeIteration = opt.Iteration; 
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

            Btag_all = cell2mat( cellfun(@(B) repmat(B.str_tag, [2,1]), a_bus, 'UniformOutput', false) );

            Ctag_all = cell(size(a_bus));
            
            rm_M = zeros(0,0);
            rv_V = cell(size(a_bus));
            rv_X = cell(size(a_bus));
            for i=1:numel(a_bus)
                Btag = a_bus{i}.str_tag;
                a_bus{i}.l_isFault = ismember(Btag, BusFault);

                rv_V{i} = [real(a_bus{i}.c_Vequilibrium); imag(a_bus{i}.c_Vequilibrium)];

                a_Comp = a_bus{i}.a_Component;                                
                c_Ctag = cell(size(a_Comp));

                rv_Cstate = cell(size(a_Comp));
                for j=1:numel(a_Comp)
                    c_Ctag{j} = repmat( a_Comp{j}.str_tag, size(a_Comp{j}.str_x) );                    
                    a_Comp{j}.isConnect = ~ismember(a_Comp{j}.str_tag, CompTrip);

                    rv_Cstate{j} = a_Comp{j}.cv_Xequilibrium + a_Comp{j}.X_offset;

                    rm_M(a_Comp{j}.iv_odeX, a_Comp{j}.iv_odeX) = a_Comp{j}.rm_odeMass([], [], [], []);
                end

                rv_X{i} = vertcat(rv_Cstate{:});                
                Ctag_all{i} = cell2mat(c_Ctag);
            end
            Ctag_all = cell2mat(Ctag_all);

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
                M0 = blkdiag(rm_M, zeros(nB*2, nB*2));
            end
            varargout{2} = RM * M0 * RM.';                    
            
        end    

        function EventSettings = Event2State(obj, varargin, opt)
            arguments
                obj                                 
            end
            arguments (Input, Repeating)
                varargin 
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
            Ctag_all = cell2mat( cellfun(@(B) string(B.a_Component), a_bus, 'UniformOutput', false) );                                
            
            lv_Ctagi = ismember(Ctag_all, CompTrip);            
            
            B_sti = cell2mat( cellfun(@(bi) bi.iv_odeX, a_bus, 'UniformOutput', false) );
            C_sti = cell2mat( cellfun(@(ci) ci.iv_odeX, a_cmp(lv_Ctagi), 'UniformOutput', false) );            

            Time = opt.ODEResults.Time;
            xsol = opt.ODEResults.Solution;

            if any(lv_Ctagi)
                xsol(:, C_sti) = NaN;
            end

            Vsol = xsol(:, B_sti);
            Isol = opt.ODEYmatrix * ( Vsol(:,1:2:end) + 1j*Vsol(:,2:2:end) ).';

            Isol2RI = zeros(size(Vsol));
            Isol2RI(:, 1:2:end) = real(Isol.');
            Isol2RI(:, 2:2:end) = imag(Isol.');
           
            t = array2table(Time);
            x = array2table(xsol);
            I = array2table(Isol2RI);

            EventSettings = table(t,x,I, 'VariableNames', {'t','x','i'});
        end
        
    end

end