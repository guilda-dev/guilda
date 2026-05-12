xeq = net.a_Bus{1}.a_Component{1}.a_LocalController{1}.cv_Xequilibrium;
ueq = net.a_Bus{1}.a_Component{1}.a_LocalController{1}.cv_Uequilibrium;
veq = net.a_Bus{1}.a_Component{1}.c_Vequilibrium;

V = [real(veq); imag(veq)];

net.a_Bus{1}.a_Component{1}.a_LocalController{1}.get_sys(xeq, V, ueq, "full", true)

xeq = net.a_Bus{1}.a_Component{1}.a_LocalController{2}.cv_Xequilibrium;
ueq = net.a_Bus{1}.a_Component{1}.a_LocalController{2}.cv_Uequilibrium;
veq = net.a_Bus{1}.a_Component{1}.c_Vequilibrium;

V = [real(veq); imag(veq)];

net.a_Bus{1}.a_Component{1}.a_LocalController{2}.get_sys(xeq, V, ueq, "full", true)
