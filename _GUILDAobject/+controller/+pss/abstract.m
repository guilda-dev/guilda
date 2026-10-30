classdef abstract < LocalController
% Base class of the power system stabilizers (PSS) attached to an AVR.
% A PSS observes the frequency deviation `omega` [pu] of the generator and outputs
% the stabilizing signal `Vpss` [pu], which is the `Vpss` input of the AVR it is
% attached to. The base class has no state and outputs 0.
%
% See also controller.pss.PSS1, controller.avr.abstract
    properties (SetAccess=protected, Hidden)
        key      
        sv_x    
        sv_u = "omega"   
        sv_y = "Vpss"   
        sv_para 
    end    
    methods
        function obj = abstract(tag)
        % Create the PSS base object with the tag "CP" + tag.
            arguments                            
                tag = "base" % Tag suffix; the controller tag is "CP" + tag.
            end            
            %
            % Outputs:
            % - `obj` PSS object.
            obj@LocalController("CP"+tag)                                                            

        end        
        
        function get_equilibrium(obj, V, u) %#ok
        % Set the equilibrium state and input of the PSS to 0.
        %
        % Inputs:
        % - `V` [pu] Complex terminal voltage of the generator at the equilibrium (unused).
        % - `u` [pu] Equilibrium input of the generator (unused).
            obj.rv_Xequilibrium = 0;
            obj.rv_Uequilibrium = 0;
        end
    end

    methods
        function dx = fcn_dx(obj, t, x, V, u, para, omega0) %#ok
            % Return the empty right-hand side of the base PSS (it has no state).
            %
            % Inputs are those of controller.pss.PSS1.fcn_dx; the base PSS uses none of them.
            %
            % Outputs:
            % - `dx` Empty right-hand side.
            dx = [];
        end
        function y  = fcn_y(obj, t, x, V, u, para, omega0) %#ok
            % Return the output of the base PSS, which is always 0.
            %
            % Inputs are those of controller.pss.PSS1.fcn_dx; the base PSS uses none of them.
            %
            % Outputs:
            % - `y` [pu] Stabilizing signal `Vpss` (0).
            y = 0;
        end
        function M  = fcn_Mass(obj, t, x, V, u, para, omega0) %#ok
            % Return the empty mass matrix of the base PSS (it has no state).
            %
            % Inputs are those of controller.pss.PSS1.fcn_dx; the base PSS uses none of them.
            %
            % Outputs:
            % - `M` Empty mass matrix.
            M = [];
        end
    end
end