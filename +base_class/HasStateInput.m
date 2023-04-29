classdef HasStateInput < base_class.handleCopyable

    methods
        function x_name = get_state_name(obj)
            x_name = obj.get_name('naming_state','x');
        end

        function u_name = get_port_name(obj)
            u_name = obj.get_name('naming_port','u');
        end
    end

    methods(Access=private)
        function name = get_name(obj,get_name,para)
            if ismember(get_name,method(obj))
                name = obj.(get_name);
            else
                name = {};
            end
            n = obj.(['get_n',para]);
            if numel(name)>n
                name(n+1:end) = [];
                warning('the number of variable names exceeds the number of variables')
                disp([para,' of ',class(obj),' :']); disp(u_name)
            elseif numel(name)<n
                for i = numel(name)+1:nu
                    name{i} = [para,num2str(i)];
                end
            end
        end
    end

    methods(Access=protected)
        function PropEditor_Set(obj,prop,val)
            obj.(prop) = val;
        end
        function val = PropEditor_Get(obj,prop)
            val = obj.(prop);
        end
    end
end