function [svec_x, svec_v, svec_w, svec_u, svec_y] = get_ODE_vars(obj,lscl_flagtag)
    arguments
        obj 
        lscl_flagtag (1,1) logical = true;
    end

    [svec_v,svec_w] = obj.Bus.get_ODE_vars(lscl_flagtag);
    
    [str_x, str_u, str_y] = obj.name_xuy_vars();
    
    if lscl_flagtag
        str_x = obj.attach_tag( str_x );
        str_u = obj.attach_tag( str_u );
        str_y = obj.attach_tag( str_y );
    end

    svec_x = sym( str_x(:) );
    svec_u = sym( str_u(:) );
    svec_y = sym( str_y(:) );
    assume([svec_x;svec_u;svec;y],"real")

    % validation
    svec_all = [svec_x; svec_u; svec_y];
    svec_uni = unique(svec_all);
    assert( numel(svec_all) == numel( svec_uni ),...
            config.lang( "状態・入力・出力変数名の重複は許可されていません。", ...
                         "Duplicate state, input, and output variable names are not permitted.") ...
          );
        
end