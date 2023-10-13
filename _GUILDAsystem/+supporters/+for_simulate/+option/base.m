classdef base < handle

    properties(Access=protected)
        network
        time
    end
    
    properties(SetAccess=protected)
        data
    end

    methods
        function obj = base(net,t,data)
            obj.time    = t; 
            obj.network = net;
            obj.data    = data;
            obj.organize;
            if ~isempty(obj.data)
                tlist = {obj.data.time};
                if isempty(horzcat(tlist{:}))
                    obj.data = [];
                end
            end
        end
       
        function out = timelist(obj)
            if isempty(obj.data)
                tlist = [];
            else
                tlist = {obj.data.time};
                tlist = tools.hcellfun(@(t) t(:).', tlist);
            end
            out = unique([tlist,obj.time(1),obj.time(end)],'sorted');
            idx = out>=obj.time(1) & out<= obj.time(end);
            out = out(idx); 
        end
    end

    methods(Abstract)
        [tlist,out] = timetable(obj)
        plot(obj,ax)
        word = sentence(obj,language)
    end

    methods(Abstract, Access=protected)
        organize(obj)
    end

end