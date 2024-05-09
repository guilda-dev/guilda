function text_data = get_component_dynamics(net,varargin)
    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p, 'vpaN', 2);
    parse(p, varargin{:});
    set = p.Results;

    out = tools.vcellfun(@(bus) get_dx_con(bus,set.vpaN), net.a_bus);
    text_data = tools.harrayfun(@(i) data2text(out,i,class(net.a_bus{i}.component)),1:numel(net.a_bus));
    
end

function out = get_dx_con(bus,vpaN)
    x = bus.component.get_state_name;
    x = sym(x(:));
    u = bus.component.get_port_name;
    u = sym(u(:));

    t = sym('t');
    
    %V = sym('V');
    %I = sym('I');
    %[dx, con] = bus.component.get_dx_constraint(t,x,[real(V);imag(V)],[real(I);imag(I)],u);
    V = sym({'Vr';'Vi'});
    I = sym({'Ir';'Ii'});
    [dx, con] = bus.component.get_dx_constraint(t,x,V,I,u);


    if numel(dx)~=0
        try
            dx  = simplify(dx);
        catch
        end
    end
    if numel(con)~=0 || ~all(con==0)
        try
            con = simplify(con);
        catch
        end
    end

    out.dx  = vpa(dx ,vpaN);
    out.con = vpa(con,vpaN);

    if numel(x) == 0
        out.dx  = 'dx &=& nan \text{  (there is no state)}';
    else
        out.dx  = ['\frac{d}{dt}',latex(x(:)),'&=&',latex(out.dx)];
    end
    out.con = ['constraint &=& ',latex(out.con)];

end

function out = data2text(data,i,component_name)
    idx = component_name == '_';
    component_name(idx) = ' ';
    out = [...
    newline,...
    '\textbf{機器',num2str(i),' (',component_name,')のダイナミクス}',...
    newline,...
    '\footnotesize',...
    newline,...
    '\begin{eqnarray*}',...
    newline,...
    data(i).dx,'\\',...
    newline,...
    data(i).con,...
    newline,...
    '\end{eqnarray*}',...
    newline,...
    '\normalsize',...
    newline,...
    '\newline',...
    newline];
end


