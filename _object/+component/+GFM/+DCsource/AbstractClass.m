classdef AbstractClass < handle

    properties
        parameter  % Property for storing parameter(table)
        converter  % Address of connected GFMI class
    end

    methods(Abstract)
        nx = get_nx(obj)    % Methods that return the number of states
        nu = get_nu(obj)    % Methods that return the number of input ports

        [ dx, vdc] = get_dx_vdc( t, x, u, V, I, ix);    % Methods for defining the dynamics of a DC source
        [xst, ust] = set_equilibrium(V,I,ix_st,flag);   % Methods to calculate the equilibrium point and steady-state input values of a DC source
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
    end
end