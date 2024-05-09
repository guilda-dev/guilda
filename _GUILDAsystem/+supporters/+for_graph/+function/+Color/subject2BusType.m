function c = subject2BusType(obj)
    switch class(obj)
        case 'bus_slack'
            c = [0.4940 0.1840 0.5560];
        case 'bus_PV'
            c = [0.8500 0.3250 0.0980];
        case 'bus_PQ'
            c = [0 0.4470 0.7410];
    end
end