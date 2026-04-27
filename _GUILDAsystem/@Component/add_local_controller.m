function add_local_controller(obj, varargin)
    arguments
        obj        
    end
    arguments (Input,Repeating)
        varargin (1,1) {mustBeA(varargin, 'LocalController')}
    end    
        
    str_setKeys = ["avr";"pss"];    
    str_extKeys = cellfun(@(con) con.key, obj.a_LocalController);

    if numel(obj.a_LocalController) == 2
        warning(msg('GUILDA:Component:NumOfController'))        

        idx = 1;
        while idx <= nargin-1
            obj.a_LocalController(str_extKeys==varargin{idx}.key) = varargin(idx);
            obj.a_LocalController{1}.add_local_controller(obj.a_LocalController{2})            
            
            cellfun(@(con,parent) con.set_parent(parent), obj.a_LocalController, {obj,obj.a_LocalController{1}});

            idx = idx + 1;
        end
    else
        idx = 1;
        while idx <= nargin-1
            str_extKeys = cellfun(@(con) con.key, obj.a_LocalController);

            if isempty(str_extKeys)
                str_extKeys = "";
            end

            new_con = varargin{idx};
            if ismember(new_con.key, str_extKeys)
                tag = new_con.str_tag;
                warning(msg('GUILDA:Component:AldExtCon', tag))
            end            

            if strcmp(new_con.key, "pss")
               if ~ismember("avr", str_extKeys) 
                   error(msg('GUILDA:Component:NotExtAvr'))
               else
                   avr = obj.a_LocalController{1};
                   avr.add_local_controller(new_con)

                   avr.set_parent(obj)
                   new_con.set_parent(avr)                   
               end
            end

            obj.a_LocalController(str_setKeys==new_con.key) = {new_con};            

            idx = idx + 1;
        end
    end
    
end