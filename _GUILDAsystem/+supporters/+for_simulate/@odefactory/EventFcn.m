function f = EventFcn(obj,varargin)
    f = obj.ToBeStop;
    if obj.ToBeStop
        obj.ToBeStop=true;
    end
end