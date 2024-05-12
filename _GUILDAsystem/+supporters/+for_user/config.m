function data = config(field)
    fn = [tools.pwd,filesep,'config.json'];
    data = readstruct([tools.pwd,filesep,'_GUILDAsystem',filesep,'+supporters',filesep,'+for_user',filesep,'config.json']);

    if isfile(fn)
        user = readstruct(fn);
    else
        user = struct();
    end
    data = merge(data,user,{});

    if nargin==1
        data = data.(field);
    end
end

function data = merge(data,user,fn)
    if isempty(fn)
        user_i = user;
    else
        user_i = getfield(user,fn{:});
    end

    if isstruct(user_i)
        fnames = fieldnames(user_i);
        for i = 1:numel(fnames)
            data_i = getfield(data,fn{:},fnames{i});
            if isscalar(data_i)
                data = merge(data,user,[fn,fnames(i)]);
            else
                try
                    data = setfield(data,fn{:},fnames{i},...
                          [data_i,user_i.(fnames{i})]);
                catch
                    error('構造体のフィールド名が異なります。')
                end
            end
        end
    else
        data = setfield(data,fn{:},user_i);
    end
end




