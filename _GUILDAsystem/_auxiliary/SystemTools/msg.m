function txt = msg(ID, varargin)
% Return the message text of a GUILDA message ID.
%
% Reads SystemTools/GUILDA/en/<Object>.xml and returns the entry of the key, with the
% placeholders {0}, {1}, ... replaced by the additional inputs.
%
% The caller must be the object named in the ID (a function in @Class/private counts as
% Class) or a method of a subclass of that class; otherwise msg stops with an error. When
% show_msg calls msg, the caller is the function that called show_msg.
%
% <@Examples>
% Inside a method of ResultCPF:
% ```matlab
% error(msg("GUILDA:ResultCPF:UnknownBus", "B099"));
% ```
    arguments (Input)
        ID        % "GUILDA:<Object>:<Key>" (string or char); <Object> is the class or file that calls msg.
    end
    arguments (Input, Repeating)
        varargin  % Values for the placeholders of the message (string, char or number); as many as the message has.
    end
    arguments (Output)
        txt       % Message text (char).
    end

    if ~ischar(ID)
        if isstring(ID)
            ID = char(ID);
        else
            error("The first argument must be of type char or string.")
        end
    end

    msg     = strsplit(ID,':');
    if numel(msg) ~= 3
        error("The ID specification is invalid.")
    end
    
    ST      = dbstack("-completenames");
    splitST = arrayfun(@(s) strsplit(s.file,filesep), ST, 'UniformOutput', false);
    % show_msg passes the message on: the caller is the function that called show_msg.
    i_caller = 2;
    while i_caller < numel(splitST) && isequal(splitST{i_caller}{end}, 'show_msg.m')
        i_caller = i_caller + 1;
    end
    c_path = splitST{i_caller};
    % A function in @Class/private belongs to Class.
    s_folder = c_path{end-1};
    if strcmp(s_folder,'private') && startsWith(c_path{end-2},'@')
        s_folder = c_path{end-2};
    end

    if ~isequal(msg{2},replace(s_folder,'@','')) || ~isequal(msg{1},'GUILDA')
        mfile = append(msg{2}, '.m');
        if ~isequal(mfile, c_path{end}) && ~(isequal(msg{1},'GUILDA') && is_subclass(c_path, msg{2}))
            error("The ID specification is invalid.")
        end
    end    

    mfilepath = replace(mfilename("fullpath"),'msg','');
    readXML   = readstruct(fullfile(mfilepath,['GUILDA',filesep,'en',filesep],[msg{2},'.xml']));
    listMSG   = readXML.message.entry;                
            
    ns = numel(listMSG);
    for i=1:ns
        txt.(listMSG(i).keyAttribute) = listMSG(i).Text;
    end
    message = txt.(msg{3});            

    splitMSG = regexp(message, '\{(\d+)(,.*?)?\}', 'tokens');
    MSGnums  = length( cellfun(@(sM) sM(1), splitMSG) );

    if nargin < 2
        txt = char(message);
    else
        args = varargin;
        narg = numel(args);
        if MSGnums == narg
            txt = format_message(message, args);
        elseif MSGnums > narg
            en = MSGnums - narg;
            error("There are " + num2str(en) + " fewer arguments than specified.")
        else
            en = narg - MSGnums;
            error("There are " + num2str(en) + " more arguments than specified.")
        end
    end
end

function l_sub = is_subclass(c_path, s_class)
    % True when the class of the file at c_path (split into folders) is a subclass of s_class.
    % The class is @Class (with the +package folders before it) or, outside an @ folder, the
    % classdef file itself.
    i_at = find(startsWith(c_path(1:end-1), '@'), 1, 'last');
    if isempty(i_at)
        i_end   = numel(c_path);
        s_name  = regexprep(c_path{end}, '\.m$', '');
    else
        i_end   = i_at;
        s_name  = c_path{i_at}(2:end);
    end
    i_pkg = i_end - 1;
    while i_pkg >= 1 && startsWith(c_path{i_pkg}, '+')
        s_name = [c_path{i_pkg}(2:end), '.', s_name]; %#ok<AGROW>
        i_pkg  = i_pkg - 1;
    end
    mc    = meta.class.fromName(s_name);
    l_sub = ~isempty(mc) && ismember(s_class, superclasses(s_name));
end

function txt = format_message(message, args)
    % Fill the placeholders with the quote rules of Java MessageFormat: '' is one quote and
    % text between single quotes is literal. {n} is the (n+1)-th argument as text ('' when it
    % is empty or missing); {n,number,integer} rounds a number to an integer.
    message  = char(message);
    txt      = '';
    l_quoted = false;
    i = 1;
    while i <= numel(message)
        c = message(i);
        if c == '''' && i < numel(message) && message(i+1) == ''''
            txt(end+1) = ''''; %#ok<AGROW>
            i = i + 1;
        elseif c == ''''
            l_quoted = ~l_quoted;
        elseif c == '{' && ~l_quoted
            i_end     = i + find(message(i+1:end) == '}', 1);
            c_part    = strtrim(strsplit(message(i+1:i_end-1), ','));
            l_integer = isequal(c_part(2:end), {'number', 'integer'});
            if ~(isscalar(c_part) || l_integer)
                error("msg does not support the placeholder {" + message(i+1:i_end-1) + "}.")
            end
            val = args{str2double(c_part{1}) + 1};
            if isempty(val) || isstring(val) && isscalar(val) && ismissing(val)
                s_val = '';
            elseif ischar(val) || isstring(val) && isscalar(val)
                s_val = char(val);
            elseif (isnumeric(val) || islogical(val)) && isscalar(val) && l_integer
                s_val = char(string(round(val)));
            elseif (isnumeric(val) || islogical(val)) && isscalar(val)
                s_val = char(string(val));
            else
                error("msg cannot show a " + class(val) + " of size " + join(string(size(val)), "x") + ".")
            end
            txt = [txt, s_val]; %#ok<AGROW>
            i   = i_end;
        else
            txt(end+1) = c; %#ok<AGROW>
        end
        i = i + 1;
    end
end
