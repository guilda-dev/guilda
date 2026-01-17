classdef abstract < component

    properties(SetAccess = private)
        avr
        pss
        governor
    end

    methods
        function obj =  abstract(parameter)
            obj.Tag = 'Gen';
            obj.InputType = 'Add';
            obj.sudo_set_CostFunction;

            if istable(parameter)
                obj.parameter = parameter;
                
            elseif isstruct(parameter)
                obj.parameter = struct2table(parameter);

            elseif ischar(parameter) || isstring(parameter)
                parameter = char(parameter);
                dataset = readtable('_object/+component/+generator/parameter.csv');
                switch parameter
                    case 'NGT2'
                        obj.parameter = dataset(1,:);
                    case 'NGT6'
                        obj.parameter = dataset(2,:);
                    case 'NGT8'
                        obj.parameter = dataset(3,:);
                end
            end
        end
        
        function set_avr(obj, avr)
            obj.set_controller(avr,'avr')
        end
        
        function set_pss(obj, pss)
            obj.set_controller(pss,'pss')
        end

        function set_governor(obj, governor)
            obj.set_controller(governor,'governor')
        end
        
    end

    methods(Access=private)
        function set_controller(obj,cls,type)
            if isa(cls, ['component.generator.',type,'.base'])
                obj.(type) = cls;
                obj.editted(type);
            else
                error(['Variable is not "',type,'" class.'])
            end
        end
    end
end
