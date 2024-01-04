classdef base < component

    properties(SetAccess = private)
        avr
        pss
        governor
    end

    methods
        function obj =  base(parameter)
            obj.Tag = 'Gen';
            obj.set_InputType('Add');

            if istable(parameter)
                obj.parameter = parameter;
                
            elseif isstruct(parameter)
                obj.parameter = struct2table(parameter);

            elseif ischar(parameter) || isstring(parameter)
                parameter = char(parameter);
                dataset = readtable('_object/+component/+generator/_default_para.csv');
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
            if isa(avr, 'component.generator.avr.base')
                obj.avr = avr;
            else
               error(''); 
            end
        end
        
        function set_pss(obj, pss)
            if isa(pss, 'component.generator.pss.base')
                obj.pss = pss;
            else
                error('');
            end
        end

        function set_governor(obj, governor)
            if isa(governor, 'component.generator.governor.base')
                obj.governor = governor;
            else
                error('');
            end
        end
        
    end
end
