classdef abstract < LocalController
% Base class of the power system stabilizers (PSS) attached to an AVR.
% A PSS observes the frequency deviation `omega` [pu] of the generator and has the
% output signal `Vpss` [pu], which is the `Vpss` input of the AVR it is
% attached to. The base class has no state and outputs 0.
%
% See also controller.pss.PSS1, controller.avr.abstract
    properties (SetAccess=protected, Hidden) % Model definition
        key  % Kind of controller (set by the concrete PSSs).
        sv_x  % Names of the states (set by the concrete PSSs).
        sv_u = "omega"  % Names of the inputs: frequency deviation of the generator.
        sv_y = "Vpss"  % Names of the outputs: Vpss input of the AVR.
        sv_para  % Names of the dynamic parameters (set by the concrete PSSs).
    end    
    methods
        function obj = abstract(tag)
        % Create the PSS base object with the tag "CP" + tag.
            arguments (Input)
                tag = "base" % Tag suffix; the controller tag is "CP" + tag.
            end            
            arguments (Output)
                obj  % PSS object.
            end
            obj@LocalController("CP"+tag)                                                            

        end        
    end

end
