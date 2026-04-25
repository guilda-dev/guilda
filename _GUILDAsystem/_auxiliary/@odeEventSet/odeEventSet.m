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
% OffsetUnit - Generator with Perturbation Applied to State Variables [ string scalar or vector ]
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
% LoadChange - Load fluctuations [ string scalar or vector ]
%    Specify this property when you want to simulate the impact on the system caused by fluctuations 
%    in the supply-demand balance due to load variations. 
%    You can specify the equipment type or number as a scalar or vector.
% 
% LoadRate - Load fluctuation [ double vector or function_handle ] 
%    You can specify the extent of load variation using constants or function handles. 
%    You can specify the number of loads experiencing demand variation in vector form. 
%    Additionally, when simulating complex load variations, you can specify inputs using function handles.    
%
% InputUnit - Component to which an input is applied [ string scalar or vector ]
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
    properties(Access=private,Hidden)
        str_tag 
    end

    properties(Access=public)
        TimeSpan    {mustBeRow, validateTimeSpanSize} = [0,10]
        OffsetUnit  (:,1) string 
        OffsetState (:,1) string 
        OffsetValue (:,1) double 
        FaultBus    (:,1) string 
        TripUnit    (:,1) string 
        LoadChange  (:,1) string 
        LoadRate    (:,1) {mustBeA(LoadRate,   {'double','cell','function_handle'})} 
        InputUnit   (:,1) string
        InputName   (:,1) string
        InputValue  (:,1) {mustBeA(InputValue, {'double','cell','function_handle'})}
    end

    properties(Access=private)
        odeNetwork
        odeOptions
    end
    properties (SetAccess=private, Hidden)
        % Version of this class       
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

            cls = metaclass(obj);
            lv_propName = arrayfun(@(p) p.Name, cls.PropertyList, 'UniformOutput', false);
            lv_isPublic = arrayfun(@(p) strcmp(p.SetAccess, 'public'), cls.PropertyList);

            lv_OptFname = lv_propName(lv_isPublic);
            lv_OptArray = cell(size(lv_OptFname));
            options     = cell2struct(lv_OptArray, lv_OptFname);

            strNames = fieldnames(opt);

            idx = 1;
            while idx <= numel(strNames)
                idx_name = strNames{idx};
                options.(idx_name) = opt.(idx_name);
                obj.(idx_name) = opt.(idx_name);
                idx = idx + 1;
            end

            obj.odeOptions = options;

        end
    end    

    methods 
        function [odeTimeTable, options] = table(obj, varargin)
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
                        
            all_time = getTimeSpan(times);                   
            
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
                            
            options = [fnp, odeEvents, enp];
            odeTimeTable = [array2table(all_time, "VariableNames", ["t1","t2"]), tab];
        end
    end

end