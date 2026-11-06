function txt = msg(ID, varargin)
% Return the message text of a GUILDA message ID.
%
% Reads SystemTools/GUILDA/en/<Object>.xml and returns the entry of the key, with the
% placeholders {0}, {1}, ... replaced by the additional inputs.
%
% The caller must be the object named in the ID (a function in @Class/private counts as
% Class); otherwise msg stops with an error.
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
    % A function in @Class/private belongs to Class.
    s_folder = splitST{2}{end-1};
    if strcmp(s_folder,'private') && startsWith(splitST{2}{end-2},'@')
        s_folder = splitST{2}{end-2};
    end

    if ~isequal(msg{2},replace(s_folder,'@','')) || ~isequal(msg{1},'GUILDA')
        mfile = append(msg{2}, '.m');
        if ~isequal(mfile, splitST{2}{end})
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
