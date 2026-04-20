function txt = msg(ID, varargin)
% MSG generates a STRING based on the SPECIFIED ID.
%    TXT = MSG(ID, ARG1, ARG2, ARG3, ...) reads XML files and outputs text 
%    based on the specified ID. When additional input is required 
%    during text output multiple arguments can be specified after the ID.
%
%
% MSG INPUT AND OUTPUT ARGUMENTS
%
% ID - Error ID [ string or char ]
%    The identifier consists of three elements. The first is the name of the software
%    the second is the name of the object calling the msg function, and the third is a key
%    for specifying the error message. These elements are specified as an ID 
%    by separating them in the above order using colons (:).
%
% VARARGIN - Other Inputs [string, char, Integer or double]
%    When outputting errors, additional arguments may be required. 
%    For example, when outputting errors related to specific characters or values. 
%    In such cases, specify as many additional inputs as needed. 
%
% TXT - Output Text [ char ]
%    This is the text string output based on the specified ID. It is output as a char type.
%
%
% Example
%       1.  mg = msg('A:B:C')
%       2.  mg = msg('A:B:C', val1, val2)
%       3.  error(msg('A:B:C'))
%    To output an error message triggered by key C within object B implemented in software A,
%    use the syntax shown in steps 1 to 3 above. Steps 1 and 2 output text only,
%    while step 3 outputs an error based on the outputted text.
%

    
    import java.text.MessageFormat    

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
    
    if ~isequal(msg{2},replace(splitST{2}{end-1},'@','')) || ~isequal(msg{1},'GUILDA')
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
            subs_txt = MessageFormat.format(message, args);
            txt      = char(subs_txt);
        elseif MSGnums > args
            en = MSGnums - args;
            error("There are " + num2str(en) + " fewer arguments than specified.")
        else
            en = args - MSGnums;
            error("There are " + num2str(en) + " more arguments than specified.")
        end
    end
end