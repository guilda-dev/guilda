function disp_init(obj,t)
    arguments (Input)
        obj
        t  % [s] Simulation time; t(1) is the start of the phase.
    end
    fprintf([' phase', num2str(obj.phase,"%.2d"),' |'])
    per = (t(1)-obj.tlim(1))/obj.tspan;
    if per>= 0.01
        roundper = floor(per*100);
        fprintf([repmat(' ',1,roundper-1),'|'])
        obj.tlast = roundper/100 * obj.tspan + obj.tlim(1);
    end
end
