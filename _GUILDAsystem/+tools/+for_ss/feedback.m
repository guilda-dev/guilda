function sys = feedback(sys)

    in = string(sys.InputName(:)  );
    on = string(sys.OutputName(:) );
    sys_feedback = ss( double( in==on(:)' ) );
    sys = feedback( sys, sys_feedback, +1);

    sys = tools.for_ss.collect(sys);
end