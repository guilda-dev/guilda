function f = Fcn_Event(obj,varargin)
    f = obj.ToBeStop;
    if obj.ToBeStop
        obj.ToBeStop=true;
    end
end