function stop = OutputFcn(obj, x, ~, state)
    stop = false;
    switch state
        case 'init'
            obj.i_iteration = 0;
            obj.rm_response = [];
        case 'done'
            rm_res = obj.rm_response(:,1:obj.i_iteration);
            cm_res = rm_res(1:2:end,:) + 1j*rm_res(2:2:end,:);

            obj.rm_response = zeros(size(rm_res));
            obj.rm_response(1:2:end) = angle(cm_res);
            obj.rm_response(2:2:end) = abs(cm_res);
            
        otherwise  % case 'iter' or  []
            i_iter = obj.i_iteration + 1;
            if mod(i_iter,1000) == 0
                obj.rm_response = [obj.rm_response, nan(numel(x),1000)];
            end
            obj.rm_response(:,i_iter) = x;
            obj.i_iteration = i_iter;

    end
end