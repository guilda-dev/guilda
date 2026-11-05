function disp_header(obj, t)
    arguments (Input)
        obj
        t  % [s] Simulation time; t(1) is the start of the phase.
    end
    disp(' ')
    t0 = [num2str( obj.tlim(1)  ),'s'];
    te = [num2str( obj.tlim(end)),'s'];
    disp(['         ',t0,repmat(' ',[1,101-numel([t0,te])]),te])
    disp(['         |        10%       20%       30%       40%       50%       60%       70%       80%       90%        |',newline,...
          '         |---------o---------o---------o---------o---------o---------o---------o---------o---------o---------|'])

    obj.tlast     = t(1);
    obj.last_warn = lastwarn;
end
