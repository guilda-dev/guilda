function TimeSpan = getTimeSpan(times)
    tcat = reshape(times,[],1);
    tmax = max(tcat);    
    t0te = [0, ceil(tmax/10)*10];            

    if isequal(max(t0te), tmax)
        t0te(2) = t0te(2) + 10;
    end
    time = unique([t0te(1); tcat; t0te(2)], "sorted", "first");

    TimeSpan = [time(1:end-1), time(2:end)];
end