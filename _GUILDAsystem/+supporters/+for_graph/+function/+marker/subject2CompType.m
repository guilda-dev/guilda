function mark = subject2CompType(obj)
    cName = class(obj);
    if contains( cName, 'generator')
        mark = 'o';
    elseif contains( cName, 'load')
        mark = 'v';
    elseif contains( cName, {'solar','wind'})
        mark = 'hexagram';
    elseif contains( cName, {'GFM','gfm'})
        mark = 'diamond';
    elseif contains( cName, {'Battery','battey','Storage','storage'})
        mark = '^';
    elseif contains( cName, {'empty'})
        mark = 'none';
    else
        mark = 's';
    end
end