function sys = feedback_legacy(sys1,sys2)

    Input1  = string( sys1.InputName  );
    Output1 = string( sys1.OutputName );
    Input2  = string( sys2.InputName  );
    Output2 = string( sys2.OutputName );

    
    sys_diag = blkdiag(sys1,sys2);

    mat12 = Input1(:)==Output2(:)';
    mat21 = Input2(:)==Output1(:)';
    mat11 = zeros( numel( Input1), numel(Output1) );
    mat22 = zeros( numel( Input2), numel(Output2) );

    mat   = [mat11, mat12 ;...
             mat21, mat22];

    sys = feedback(sys_diag, mat, +1);
    sys = sys({'x','xcon','y','ycon','Vbus','Ibus'},{'u','ucon','Ibus'});

    sys = sstools.collect(sys);
end