function [cv_Xequilibrium, cv_Uequilibrium] = get_equilibrium(obj,c_V,c_I,~,~)
    obj.Z = -c_V/c_I;
    cv_Xequilibrium = zeros(0,1);
    cv_Uequilibrium = [real(obj.Z); imag(obj.Z)];
end