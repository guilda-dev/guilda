function rm_pf = powerflow_matrix(cv_V, cv_I)
% Solution of a power flow as the array of Format "powerflow(mat)".
%
% One row per bus: V and I are the complex voltage and current injection phasors, P and Q
% the real power injections into the network (S = V.*conj(I)), stored as complex numbers
% with zero imaginary part.
    arguments (Input)
        cv_V (:,1) double  % [pu] Complex bus voltages.
        cv_I (:,1) double  % [pu] Complex current injections into the network.
    end
    arguments (Output)
        rm_pf (:,4) double % [pu] Columns V, I, P, Q.
    end
    cv_S  = cv_V .* conj(cv_I);
    rm_pf = [cv_V, cv_I, complex(real(cv_S)), complex(imag(cv_S))];
end
