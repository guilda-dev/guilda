classdef abstract < LocalController
% Base class of the automatic voltage regulators (AVR) attached to a generator.
% An AVR observes the terminal voltage `V` [pu] of the generator and takes the
% input signals `u = [Vref; Vpss]` [pu]: the voltage reference and the output of an
% attached PSS. Its output signal `Vfield` [pu] is the field voltage input of the
% generator. A PSS is attached to the AVR as its own local controller.
%
% See also controller.avr.AVR_ST1, controller.avr.AVR_DC1, controller.pss.abstract
    properties (SetAccess=protected, Hidden) % Model definition
        key  % Kind of controller (set by the concrete AVRs).
        sv_x  % Names of the states (set by the concrete AVRs).
        sv_u = ["Vref";"Vpss"]  % Names of the inputs: voltage reference and PSS output.
        sv_y = ["Vfield"]  % Names of the outputs: field voltage of the generator.
        sv_para  % Names of the dynamic parameters (set by the concrete AVRs).
    end    
    methods
        function obj = abstract(tag) 
        % Create the AVR base object with the tag "CA" + tag.
            arguments (Input)
                tag = "base" % Tag suffix; the controller tag is "CA" + tag.
            end
            arguments (Output)
                obj % AVR object.
            end
            obj@LocalController("CA"+tag)                                                                                           
        end                
    end
    
end
