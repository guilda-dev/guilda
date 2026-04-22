function evnt = checkSimulationTime(t,y,start,timeout) %#ok    
    evnt = timeout - toc(start);
end