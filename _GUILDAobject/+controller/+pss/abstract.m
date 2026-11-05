classdef abstract < LocalController
% Base class of the power system stabilizers (PSS) attached to an AVR.
% A PSS observes the frequency deviation `omega` [pu] of the generator and has the
% output signal `Vpss` [pu], which is the `Vpss` input of the AVR it is
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
            arguments (Input)
                tag = "base" % Tag suffix; the controller tag is "CP" + tag.
            end            
            arguments (Output)
                obj  % PSS object.
            end
            obj@LocalController("CP"+tag)                                                            

        end        
        
        function get_equilibrium(obj, V, u) %#ok
        % Set the equilibrium state and input of the PSS to 0.
            arguments (Input)
                obj
                V    % [pu] Complex terminal voltage of the generator at the equilibrium (unused).
                u    % [pu] Equilibrium input of the generator (unused).
            end
            obj.rv_Xequilibrium = 0;
            obj.rv_Uequilibrium = 0;
        end
    end

    methods
        function dx = fcn_dx(obj, t, x, V, I, u, para, omega0) %#ok
            % Return the empty right-hand side of the base PSS (it has no state).
            %
            % Inputs are those of controller.pss.PSS1.fcn_dx; the base PSS uses none of them.
            arguments (Input)
                obj
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                para   double        % Dynamic parameters in the order of `sv_para`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                dx  % Empty right-hand side.
            end
            dx = [];
        end
        function y  = fcn_y(obj, t, x, V, I, u, para, omega0) %#ok
            % Return the output of the base PSS, which is always 0.
            %
            % Inputs are those of controller.pss.PSS1.fcn_dx; the base PSS uses none of them.
            arguments (Input)
                obj
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                para   double        % Dynamic parameters in the order of `sv_para`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                y  % [pu] Stabilizing signal `Vpss` (0).
            end
            y = 0;
        end
        function M  = fcn_Mass(obj, t, x, V, I, u, para, omega0) %#ok
            % Return the empty mass matrix of the base PSS (it has no state).
            %
            % Inputs are those of controller.pss.PSS1.fcn_dx; the base PSS uses none of them.
            arguments (Input)
                obj
                t      double        % [s] Time.
                x      double        % States in the order of `sv_x`.
                V      double        % [pu] Terminal voltage of the parent [real; imag].
                I      double        % [pu] Terminal current of the parent [real; imag].
                u      double        % Inputs in the order of `sv_u`.
                para   double        % Dynamic parameters in the order of `sv_para`.
                omega0 (1,1) double  % [Hz] Nominal frequency of the network.
            end
            arguments (Output)
                M  % Empty mass matrix.
            end
            M = [];
        end
    end
end