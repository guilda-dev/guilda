function size = BusSize_Q(bus, V, I)
    size = V(2)*I(1) - V(1)*I(2);
end