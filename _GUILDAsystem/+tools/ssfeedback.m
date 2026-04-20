function sysout = ssfeedback(sys1,sys2)
    arguments
        sys1 ss
        sys2 ss
    end

    str_ig1 = string(sys1.InputName(:));
    str_ig2 = string(sys2.InputName(:));
    str_og1 = string(sys1.OutputName(:).');
    str_og2 = string(sys2.OutputName(:).');

    n_ig1 = numel(str_ig1);
    n_ig2 = numel(str_ig2);
    n_og1 = numel(str_og1);
    n_og2 = numel(str_og2);

    ConnectMap = [ zeros(n_ig1,n_og1), str_ig1 == str_og2; ...
                   str_ig2 == str_og1, zeros(n_ig2,n_og2)];

    sys_blkdiag  = blkdiag(sys1,sys2);
    sys_feedback = ss(ConnectMap);

    sysout = feedback( sys_blkdiag, sys_feedback, +1);
end