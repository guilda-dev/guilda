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
    % Fill the placeholders like Java MessageFormat: '' is one quote, text between single
    % quotes is literal, {n} is the (n+1)-th argument and {n,number,integer} it rounded to an
    % integer. Java shows [] and '' as null, a logical as true / false.
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
            if isempty(val) && ~isstring(val) || isstring(val) && isscalar(val) && ismissing(val)
                s_val = 'null';
            elseif ~l_integer && (ischar(val) || isstring(val) && isscalar(val))
                s_val = char(val);
            elseif ~l_integer && islogical(val) && isscalar(val)
                s_val = char(string(val));
            elseif isnumeric(val) && isscalar(val) && isreal(val)
                s_val = format_number(val, 3 * ~l_integer);
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

function s = format_number(val, n_frac)
    % Number as Java NumberFormat shows it: the shortest decimal digits of the value,
    % rounded to n_frac decimals, trailing zeros dropped, digits grouped by three.
    if isnan(val)
        s = 'NaN';
        return
    end
    s_sign = '';
    if val < 0 || (val == 0 && ~isinteger(val) && 1/double(val) < 0)
        s_sign = '-';
    end
    if isinf(val)
        s = [s_sign, char(8734)];
        return
    end
    r = abs(double(val));
    if isinteger(val)
        s_int  = sprintf('%d', abs(val));
        s_frac = '';
    elseif r >= 2^53 && r < 2^63
        % Java takes the exact integer and rounds off its last digits half up.
        n_off  = floor(max(0, floor(log2(r)) - 54) * log10(2));
        u      = uint64(r);
        u_pow  = uint64(10)^n_off;
        u_keep = idivide(u, u_pow, 'floor') + uint64(mod(u, u_pow) >= u_pow / 2);
        s_int  = [sprintf('%d', u_keep), repmat('0', 1, n_off)];
        s_frac = '';
    else
        for n_digit = 1:17
            s_e = sprintf('%.*e', n_digit - 1, r);
            if str2double(s_e) == r
                break
            end
        end
        c_e     = strsplit(s_e, 'e');
        s_digit = erase(c_e{1}, '.');
        n_int   = str2double(c_e{2}) + 1;
        if n_int <= 0
            s_int  = '0';
            s_frac = [repmat('0', 1, -n_int), s_digit];
        else
            s_digit = [s_digit, repmat('0', 1, n_int - numel(s_digit))];
            s_int   = s_digit(1:n_int);
            s_frac  = s_digit(n_int+1:end);
        end
        if numel(s_frac) == n_frac + 1 && s_frac(end) == '5'
            % The digits end in a tie: Java rounds the binary value half to even.
            c_f    = strsplit(sprintf('%.*f', n_frac, r), '.');
            s_int  = c_f{1};
            s_frac = strjoin(c_f(2:end), '');
        elseif numel(s_frac) > n_frac
            % Otherwise the digits round half up.
            s_keep = [s_int, s_frac(1:n_frac)];
            if s_frac(n_frac+1) >= '5'
                i_up = find(s_keep ~= '9', 1, 'last');
                if isempty(i_up)
                    s_keep = ['1', repmat('0', 1, numel(s_keep))];
                else
                    s_keep = [s_keep(1:i_up-1), char(s_keep(i_up) + 1), repmat('0', 1, numel(s_keep) - i_up)];
                end
            end
            s_int  = s_keep(1:end-n_frac);
            s_frac = s_keep(end-n_frac+1:end);
        end
        s_frac = regexprep(s_frac, '0+$', '');
    end
    s_int = regexprep(s_int, '(\d)(?=(\d{3})+$)', '$1,');
    if isempty(s_frac)
        s = [s_sign, s_int];
    else
        s = [s_sign, s_int, '.', s_frac];
    end
end
