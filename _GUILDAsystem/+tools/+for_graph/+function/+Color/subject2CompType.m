function color = subject2CompType(obj)
    cName = class(obj);
    if contains( cName, 'generator')
        color = [0.8500 0.3250 0.0980];
    elseif contains( cName, 'load')
        color = [0 0.4470 0.7410];
    elseif contains( cName, {'solar','wind'})
        color = [0.4660 0.6740 0.1880];
    elseif contains( cName, {'GFM','gfm'})
        color = [0.4940 0.1840 0.5560];
    elseif contains( cName, {'Battery','battey','Storage','storage'})
        color = [0.9290 0.6940 0.1250];
    elseif contains( cName, {'ConstSource'})
        color = [0.3010 0.7450 0.9330];
    else
        color = [0 0 0];
    end
end