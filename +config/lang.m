function out = lang(strJP,strEN)
arguments
    strJP (1,1) string = "error"
    strEN (1,1) string = "error"
end
    switch config.systemFunc.get("ENV","language","Value")
        case "JP"; out = strJP;
        case "EN"; out = strEN;
    end
end