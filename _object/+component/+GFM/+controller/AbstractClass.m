classdef AbstractClass < handle

    properties
        parameter  % Property for storing parameter(table)
        converter  % Address of connected GFMI class
    end

    properties(Dependent)
        params_converter
        params_dc_source
    end


    methods(Abstract)
        nx = get_nx(obj)    % Methods that return the number of states
        nu = get_nu(obj)    % Methods that return the number of input ports

        [dx,m] = get_dx_mdq(obj, t, x, u, vdq, idq, isdq, vdq_hat, omega)   % Methods to define controller dynamics
        [xst,ust,mdq] = set_equilibrium(obj,vdq,isdq,omega,flag)            % Methods to calculate the equilibrium point and steady-state input values of controller
    end

    methods
        % Methods that return state variable names
        function tag = naming_state(obj)
            tag = tools.arrayfun(@(i) ['x',num2str(i)], 1:obj.get_nx);
        end

        % Methods that return the port name of the input
        function tag = naming_port(obj)
            tag = tools.arrayfun(@(i) ['u',num2str(i)], 1:obj.get_nu);
        end

        % Get method
            % Property "params_converter" corresponding to the converter parameter
            function p = get.params_converter(obj)
                p = obj.converter.parameter;
            end
    
            % Property "params_dc_source" corresponding to the DC source
            function p = get.params_dc_source(obj)
                p = obj.converter.dc_source.parameter;
            end

    end
end