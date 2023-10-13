classdef base < component

    properties(SetAccess = private)
        avr
        pss
        governor
    end

    methods
        function obj =  base()
            obj.Tag = 'Gen';
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
