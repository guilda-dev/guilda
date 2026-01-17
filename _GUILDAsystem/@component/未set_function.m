function set_function(obj,linear)
        arguments
            obj 
            linear = false;
        end
        if linear
            % Once initialize the nonlinear model fcn_xxx.
            obj.set_function(false); 
            % Recalculate approximate linearized model.(use set method for recalculation if system_matrix is empty.)
            obj.system_matrix = ss([]);
            sys = obj.system_matrix; 
            % Define fcn_xxx
            xst = obj.equilibrium.state;
            ust = obj.equilibrium.input;
            obj.fcn_diff   = @(t,x,u) sys.A*(x-xst) + sys.B*(u-ust);
            obj.fcn_output = @(t,x,u) sys.C*(x-xst) + sys.D*(u-ust);
            obj.fcn_input  = @(t,u) u;
        else  
            ufunc = obj.get_ufunc;
            nu = obj.get_nu;
            uidx = 1:nu;
            Vidx = nu+(1:2);
            Iidx = nu+(3:4);
            obj.fcn_diff   = @(t,x,u) obj.get_dx( t, x, u(Vidx), u(Iidx), ufunc( u(uidx) ) );
            if ~obj.is_parallel
                obj.fcn_output = @(t,x,u) [obj.get_y( t, x, u(Vidx), [0;0], ufunc(u(uidx)) );
                                           u(Vidx);
                                           0;0];
                return
            end

            % check constraint type
            switch ismethod(obj,'get_V') + 2*ismethod(obj,'get_I')
                case 1; obj.constraint = "voltage";
                case 2; obj.constraint = "current";
                case 3
                case 0; error([class(obj),': need to define "get_I" or "get_V" method.'])
            end

            switch obj.constraint
                case "voltage"
                    obj.fcn_output = @(t,x,u) [obj.get_y( t, x, u(Vidx), u(Iidx), ufunc( u(uidx) ) );...
                                               obj.get_V( t, x, u(Vidx), u(Iidx), ufunc( u(uidx) ) );...
                                               u(Iidx)];
                case "current"
                    obj.fcn_output = @(t,x,u) [obj.get_y( t, x, u(Vidx), u(Iidx), ufunc( u(uidx) ) );...
                                               u(Vidx);...
                                               obj.get_I( t, x, u(Vidx), u(Iidx), ufunc( u(uidx) ) )];
            end
        end
    end