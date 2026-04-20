function stop = OutputFcn(obj, x, optimValues, state)
    stop = false;
    switch state
        case 'init'
            obj.i_iteration = 0;
            obj.rm_response = [];
            obj.rr_stepsize = [];
        case 'iter'
            i_iter = obj.i_iteration + 1;
            if mod(i_iter,1000) == 0
                obj.rm_response = [obj.rm_response, nan(numel(x),1000)];
                obj.rr_stepsize = [obj.rr_stepsize, nan(1,1000)];
            end
            obj.rm_response(:,i_iter) = x;
            obj.rr_stepsize(:,i_iter) = optimValues.stepsize;
            obj.i_iteration = i_iter;
        case 'done'
            obj.rm_response = obj.rm_response(:,1:obj.i_iteration);
            obj.rr_stepsize = obj.rr_stepsize(:,1:obj.i_iteration);
    end
end