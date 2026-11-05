function sv = label(owner, sv_name)
% Tagged name, as in the Label column of get_variable_map
    if isempty(sv_name)
        sv = strings(0,1);
    else
        sv = reshape(string(owner.attach_tag(sv_name)), [], 1);
    end
end
