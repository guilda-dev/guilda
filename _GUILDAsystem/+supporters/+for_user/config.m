function data = config(field)
    fn = [tools.pwd,filesep,'config.json'];
    fn_sys = [tools.pwd,filesep,'_GUILDAsystem',filesep,'+supporters',filesep,'+for_user',filesep,'config.json'];
    try 
        data = readstruct(fn_sys);
    catch
        data = jsondecode(fileread(fn_sys));
    end


    if isfile(fn)
        try
            user = readstruct(fn);
        catch
            user = jsondecode(fileread(fn));
        end
    else
        user = struct();
    end
    data = updateConfig(data,user);
    data = format(data);

    if nargin==1
        data = data.(field);
    end
end


function config = updateConfig(config, newConfig)
    fields = fieldnames(newConfig);
    for i = 1:numel(fields)
        field = fields{i};
        if isfield(config, field)
            if isstruct(newConfig.(field))
                if length(config.(field)) > 1 && isstruct(config.(field)(1))
                    config.(field)(end+1) = updateConfig(struct(), newConfig.(field)); % 構造体配列に新しい要素を追加
                else
                    config.(field) = updateConfig(config.(field), newConfig.(field));
                end
            else
                config.(field) = newConfig.(field);
            end
        else
            config.(field) = newConfig.(field);
        end
    end

end

function out = format(in)
    fn  = fieldnames(in);
    out = struct();

    for i = 1:numel(fn)
        f = fn{i};

        in_i = in.(f);

        if isstruct(in_i)
            out_i = format(in_i(1));
            for j = 2:numel(in_i)
                out_i(j) = format(in_i(j));
            end
            out.(f) = out_i;

        elseif numel(in_i)>1 && isstring(in_i)
            out.(f) = cell(size(in_i(:)));
            [out.(f){:}] = in_i{:};

        elseif iscell(in_i)
            out.(f) = in_i(:);
        
        elseif isstring(in_i)
            out.(f) = char(in_i);
    
        elseif isnumeric(in_i) && isempty(in_i)
            out.(f) = [];
    
        else
            out.(f) = in_i;
        end
    end
end



% 
% function data = merge(data,user,fn)
%     if isempty(fn)
%         user_i = user;
%     else
%         user_i = getfield(user,fn{:});
%     end
% 
%     if isstruct(user_i)
%         fnames = fieldnames(user_i);
%         for i = 1:numel(fnames)
%             data_i = getfield(data,fn{:},fnames{i});
%             if isscalar(data_i) || ischar(data_i)
%                 data = merge(data,user,[fn,fnames(i)]);
%             else
%                 try
%                     data = setfield(data,fn{:},fnames{i},...
%                           [data_i,user_i.(fnames{i})]);
%                 catch
%                     error('構造体のフィールド名が異なります。')
%                 end
%             end
%         end
%     else
%         data = setfield(data,fn{:},user_i);
%     end
% end
