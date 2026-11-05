function [Axx, Bxu, Bxv, Bxi, Cyx, Dyu, Dyv, Dyi, Cix, Diu, Div, Dii] = getSubJacobian(OBJ, t, xi, Vi, Ii, ui)

    Axx = OBJ.JacobiAxx(t,xi,Vi,Ii,ui);
    Bxv = OBJ.JacobiBxv(t,xi,Vi,Ii,ui);
    Bxi = OBJ.JacobiBxi(t,xi,Vi,Ii,ui);
    Bxu = OBJ.JacobiBxu(t,xi,Vi,Ii,ui);

    Cyx = OBJ.JacobiCyx(t,xi,Vi,Ii,ui);
    Dyv = OBJ.JacobiDyv(t,xi,Vi,Ii,ui);
    Dyi = OBJ.JacobiDyi(t,xi,Vi,Ii,ui);
    Dyu = OBJ.JacobiDyu(t,xi,Vi,Ii,ui);

    Cix = OBJ.JacobiCix(t,xi,Vi,Ii,ui);
    Div = OBJ.JacobiDiv(t,xi,Vi,Ii,ui);
    Dii = OBJ.JacobiDii(t,xi,Vi,Ii,ui);
    Diu = OBJ.JacobiDiu(t,xi,Vi,Ii,ui);
end
