classdef abstract < Component
    methods
        function obj =  abstract(macpara)
            arguments
                macpara = "NGT2";
            end
            obj@Component()
            obj.tab_parameter.para_powerflow{1,["P","Q"]} = [1,nan];
            obj.tab_parameter.para_OPF{1,["P_min","P_max","Q_min","Q_max"]} = [0.1,1.5,-0.5,1.5];
            obj.tag = 'Gen';
            
            if istable(macpara)
                obj.parameter.model = macpara(:,obj.pvars); 
            elseif ischar(macpara) || isstring(macpara)
                parameter = char(macpara);
                datapath  = fullfile(fileparts(mfilename("fullpath")), "parameter.csv");
                dataset   = readtable(datapath);
                switch parameter
                    case 'NGT2'
                        obj.parameter.model = dataset(1,obj.pvars);
                    case 'NGT6'
                        obj.parameter.model = dataset(2,obj.pvars);
                    case 'NGT8'
                        obj.parameter.model = dataset(3,obj.pvars);
                    otherwise
                        error(GUILDAconfig.lang(parameter+" : 不明なパラメータです",parameter+" : Unknown parameter"))
                end
            end

            % obj.set_avr( component.generator.avr.base() );
            % obj.set_governor( component.generator.governor.base() );
            % obj.set_pss( component.generator.pss.base() );
        end
    end

    methods
        ust = get_uequilibrium(obj,c_V,c_I)
    end

    properties(SetAccess = private)
        avr
        pss
        governor
    end

    methods
        set_governor(obj, con)
        set_avr(obj, con)
        set_pss(obj, con)
        function c = get.governor(obj); c = obj.SpecificControllers{1}; end    
        function c = get.avr(obj);      c = obj.SpecificControllers{2}; end    
        function c = get.pss(obj);      c = obj.SpecificControllers{3}; end    
    end

end
