function warning(msg,varargin)
    switch config.systemFunc.get("ENV","warning","Value")
        case "ON";   warning(msg,varargin{:})
        case "DISP"; disp(msg)
        case "OFF";  return
    end
end