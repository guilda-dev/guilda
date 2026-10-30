function txt = msg(ID, varargin)
% Return the message text of a GUILDA message ID.
%
% Reads SystemTools/GUILDA/en/<Object>.xml and returns the entry of the key, with the
% placeholders {0}, {1}, ... replaced by the additional inputs.
%
% Inputs:
% - `ID`: "GUILDA:<Object>:<Key>" (string or char). <Object> is the class or file that
%   calls msg.
% - `varargin`: values for the placeholders of the message (string, char or number); as
%   many as the message has.
%
% Output `txt`: the message text (char).
%
% The caller must be the object named in the ID; otherwise msg stops with an error.
%
% <@Examples>
% Inside a method of CPFResult:
% ```matlab
% error('GUILDA:CPFResult:UnknownBus', '%s', msg('GUILDA:CPFResult:UnknownBus', "B099"));
% ```

    
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