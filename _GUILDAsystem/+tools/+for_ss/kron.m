function sysKron = kron(sys)

    idx = logical(diag(sys.E));
    if isempty(idx)
        sysKron = sys;
        return
    end

    A = sys.A;
    B = sys.B;
    C = sys.C;
    D = sys.D;
    invE = eye(sum(~idx)) / A(~idx,~idx);

    Amat = A(idx, idx) - A( idx, ~idx) * invE * A(~idx, idx);
    Bmat = B(idx,  : ) - A( idx, ~idx) * invE * B(~idx,  : );
    Cmat = C( : , idx) - C(  : , ~idx) * invE * A(~idx, idx);
    Dmat = D           - C(  : , ~idx) * invE * B(~idx,  : );

    sysKron = ss(Amat,Bmat,Cmat,Dmat);
    sysKron.InputName   = sys.InputName;
    sysKron.OutputName  = sys.OutputName;
    sysKron.InputGroup  = sys.InputGroup;
    sysKron.OutputGroup = sys.OutputGroup;
    sysKron.StateName   = sys.StateName(idx);
end

% dx  = |A11,A12| |x| + 
% con = |A21,A22| |V|size