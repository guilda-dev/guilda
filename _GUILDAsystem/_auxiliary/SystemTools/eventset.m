function options = eventset(varargin)
% EVENTSET provides options for dynamic simulation in the form of a structure.
%    EVENTSET = (Name1, Val1, Names2, Val2, ...) is a function that outputs options 
% 　　for dynamic mutation in the form of a structure. Options can be specified 
% 　　by selecting properties and assigning values, or by passing other structures as arguments. 
%
% EVENTSET PROPERTIES
%
% Time - Simulation Time [ positive vector ]
%    This two-dimensional vector of positive double constants represents the integration time for a phase. 
%    Since eventset outputs events within a time phase in structured format, when multiple events exist, 
%    you must create a struct corresponding to each time event from the eventset function.
%
% InitOffset - Perturbation Applied to The State [ double scalar or vector ]
%    This property specifies perturbations applied to the state of equipment such as generators. 
%    Perturbations are specified as a scalar or a vector depending on the number of state variables 
%    to which the perturbation is applied. The specific state variables to which the perturbation 
%    applied are specified later using OffsetX.
% 
% OffsetCmp - Generator with Perturbation Applied to State Variables [ string or integer\scalar or vector ]
%    Specify the generator that applies perturbations to the state variables.
% 　　You can also specify an integer scalar or vector, or a device tag.
%
% OffsetX - Perturbation-induced state [ string or integer\scalar or vector ]
%    Specify the state variables to which perturbations are applied. State variables can be specified 
%    by number or by name. Both scalar and vector specifications are accepted.
%
% FltBus - Fault Bus [ string or integer\scalar or vector ]
%    Specify the busbar causing the ground fault. Specify either the busbar number or the busbar tag. 
%    Accepts input as a scalar or vector.
%
% TrpBus - Trip Bus [ string or integer\scalar or vector ]
%    Specify this property when performing a simulation involving equipment disconnection. 
%    When this property is specified, all equipment connected to the specified busbar will be disconnected. 
%    It accepts integer or string scalars and vectors.
%
% TrpCmp - Trip Component [ string or integer\scalar or vector ]
%    Specify the device to be disassembled. You can specify the device's tag or number using a scalar or vector.
%
% Load - Load fluctuations [ string or integer\scalar or vector ]
%    Specify this property when you want to simulate the impact on the system caused by fluctuations 
%    in the supply-demand balance due to load variations. 
%    You can specify the equipment type or number as a scalar or vector.
% 
% LoadRate - Load fluctuation [ scalar, vector or function_handle ] 
%    You can specify the extent of load variation using constants or function handles. 
%    You can specify the number of loads experiencing demand variation in vector form. 
%    Additionally, when simulating complex load variations, you can specify inputs using function handles.    
%
%

    arguments (Input, Repeating)        
        varargin {mustBeA(varargin, {'struct','char','string','double','integer'})}
    end

    if isequal(nargin, 0) && isequal(nargout, 0)
        disp("             Time: [           positive vector          ] ");
        disp("       InitOffset: [       double scalar or vector      ] ");
        disp("        OffsetCmp: [ string or integer\scalar or vector ] ");
        disp("          OffsetX: [ string or integer\scalar or vector ] ");
        disp("           FltBus: [ string or integer\scalar or vector ] "); 
        disp("           TrpBus: [ string or integer\scalar or vector ] ");
        disp("           TrpCmp: [ string or integer\scalar or vector ] ");
        disp("             Load: [ string or integer\scalar or vector ] ");
        disp("         LoadRate: [ scalar, vector or function_handle  ] ");      
        return
    end           
    
    options = struct(      'Time', [], ...
                      'OffsetCmp', [], ...
                     'InitOffset', [], ...
                        'OffsetX', [], ...
                         'FltBus', [], ...
                         'TrpBus', [], ...
                         'TrpCmp', [], ...
                           'Load', [], ...
                       'LoadRate', []);    

    fn = fieldnames(options);
    sf = cellfun(@(f) string(f), fn);
    for i = 1:nargin
        arg = varargin{i};
        if ischar(arg) || (isstring(arg) && isscalar(arg)) 
            break
        end
        if ~isempty(arg)                                 
            for j = 1:numel(sf)
                sfj = sf(j);
                if any(strcmp(fieldnames(arg), sfj))                    
                    options.(sfj) = arg.(sfj);
                else
                    error(msg('GUILDA:eventset:NoPropName', sfj))
                end
            end
        end        
    end        
    
    if mod(nargin,2) ~= 0
        error(msg('GUILDA:eventset:ArgNameMismatch'))
    end

    flag = false;
    for i = 1:nargin
        arg = varargin{i};
        
        if ~flag                    
            j = startsWith(sf,arg,'IgnoreCase',true);            
            if ~any(j)
                error(msg('GUILDA:eventset:InvalidPropName', arg))
            elseif sum(j) > 1                            
                k = strcmpi(sf,arg);
                if isequal(sum(k), 1)
                    j = k;
                else                    
                    sfj = sf(j);
                    error(msg('GUILDA:eventset:AmbiguousPropName', arg, join(sfj, ', ')))
                end
            end
            flag = true;                               
        else            
            options.(sf(j)) = arg;
            flag = false;
        
        end        
    end        
end