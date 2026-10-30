classdef abstract < LocalController
% Base class of the automatic voltage regulators (AVR) attached to a generator.
% An AVR observes the terminal voltage `V` [pu] of the generator and takes the
% input `u = [Vref; Vpss]` [pu]: the voltage reference and the output of an
% attached PSS. Its output `Vfield` [pu] is the field voltage input of the
% generator. A PSS is attached to the AVR as its own local controller.
%
% See also controller.avr.AVR_ST1, controller.avr.AVR_DC1, controller.pss.abstract
    properties (SetAccess=protected, Hidden)
        key      
        sv_x    
        sv_u = ["Vref";"Vpss"]   
        sv_y = ["Vfield"]    
        sv_para 
    end    
    methods
        function obj = abstract(tag) 
        % Create the AVR base object with the tag "CA" + tag.
            arguments
                tag = "base" % Tag suffix; the controller tag is "CA" + tag.
            end
            arguments (Output)
                obj % AVR object.
            end
            obj@LocalController("CA"+tag)                                                                                           
        end                

        function get_equilibrium(obj, V, u)      
        % Set the equilibrium state and input of the AVR and of its PSS.
        % The base AVR stores the field voltage `u(2)` as its equilibrium state.
        %
        % Inputs:
        % - `V` [pu] Complex terminal voltage of the generator at the equilibrium.
        % - `u` [pu] Equilibrium input of the generator `[Pmech; Vfield]`.
            obj.rv_Xequilibrium = u(2);
            obj.rv_Uequilibrium = [];
            cellfun(@(c) c.get_equilibrium(V,u), obj.a_LocalController);
        end
        
        function set_PSS(obj, cls) %#ok
        % Attach a PSS to the AVR.
        % The base implementation ignores `cls`; the concrete AVRs attach `cls`.
        %
        % Inputs:
        % - `cls` PSS object (a controller.pss.abstract subclass).
            obj.a_LocalController{1} = controller.pss.base;
            obj.l_hasController = true;
        end
        
    end
    
end