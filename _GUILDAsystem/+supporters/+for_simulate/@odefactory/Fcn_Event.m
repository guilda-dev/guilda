function [value,isterminal,direction] = Fcn_Event(obj,t,x)

    if (datetime - obj.start_time) > obj.time_limit && ~obj.ToBeStop
        obj.ToBeStop = true;
        fprintf('| \n\nThe simulation is terminated because the specified time limit has been exceeded\n\n')
    end

    isterminal = 1;
    direction  = 0;
    value = obj.GoNext;

end