function sys = feedback(sys)
% Close the loops of a state-space model from each output to the input with the same name.
%
% Positive feedback; ports that share a name are combined afterwards (tools.for_ss.collect).

    in = string(sys.InputName(:)  );
    on = string(sys.OutputName(:) );
    sys_feedback = ss( double( in==on(:)' ) );
    sys = feedback( sys, sys_feedback, +1);

    sys = tools.for_ss.collect(sys);
end