classdef abstract < Component

    methods (Access={?Component})
        function obj =  abstract(index, parameter, varargin)
            obj@Component("SG"+index, varargin{:})
            obj.para_powerflow.Q = nan;
            
            if istable(parameter)
                mp = parameter(:,obj.sv_para);             
            else 
                datapath = fullfile(fileparts(mfilename("fullpath")), "parameter.csv");
                dataset  = readtable(datapath);                
                if ischar(parameter) || isstring(parameter)                
                    mp = dataset(string(parameter)==["NGT2";"NGT6";"NGT8"],obj.sv_para);
                else
                    mp = dataset(1,obj.sv_para);
                end
            end
            
            name = cellfun(@(d) string(d), mp.Properties.VariableNames);
            for i=1:numel(name)
                obj.para_dynamics.add_entry(name(i), mp.(name(i)), "double");
            end

            % obj.set_avr( component.generator.avr.base() );
            % obj.set_governor( component.generator.governor.base() );
            % obj.set_pss( component.generator.pss.base() );
            Hz = obj.para_base.Hz;
            obj.set_odefcn(Hz)            
        end
    end    

    properties(SetAccess = protected)
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
