function tag = manage_tag(mode,tag,cls)
% [System-Only Method. Do Not Use.]
% This method is responsible for managing tags of instantiated objects. 
% It is intended for internal use within the script and should not be used by the user.

    arguments
        mode (1,1) string {mustBeMember(mode,["add","remove","clear","disp","get"])} = "disp"
        tag  (1,1) string {mustBeValidVariableName} = "unknown"
        cls  (1,1) string = "unknown";
    end
    
    if ismember(mode,["add","remove"]) && tag=="unknown"
        return
    end

    str_path = fullfile(GUILDA.pwd,'@GUILDA','user',"TagList.txt");
    if ~isfile(str_path)
        writelines('',str_path)
    end
    
    fileID = fopen(str_path, 'r');
    cell_dataFromTxt = textscan(fileID, '%s%s%s', 'Delimiter', '\t');
    str_dataFromTxt  = string(horzcat(cell_dataFromTxt{:}))';
    fclose(fileID);

    
    switch mode
        case "add"
            time   = string(datetime("now","Format","uuuu/MM/dd-HH:mm:ss"));
            if numel(str_dataFromTxt) >= 3
                cell_tags = str_dataFromTxt(2,:);
                if ismember(tag,cell_tags)
                    i = 2;
                    while ismember(tag+"_"+i, cell_tags)
                        i = i +1;
                    end
                    tag = tag+"_"+i;
                    disp("Tag changed due to overlaps detected >> "+tag)
                end
                fileID = fopen(str_path, 'w');
                fprintf(fileID, '%s\t%s\t%s\n', [str_dataFromTxt,[time;tag;"@"+cls]]);
                fclose(fileID);
                return
            else
                fileID = fopen(str_path, 'w');
                fprintf(fileID, '%s\t%s\t%s\n', [time;tag;"@"+cls]);
                fclose(fileID);
                return
            end
        case "remove"
            lv = ismember(str_dataFromTxt(2,:),tag);
            fileID = fopen(str_path, 'w');
            fprintf(fileID, '%s\t%s\t%s\n', str_dataFromTxt(:,~lv));
            fclose(fileID);
        case "clear"
            answer = questdlg('All element tags in GUILDA must be unique. Resetting the tag list creates unmanaged elements and may cause bugs. We recommend using "clear" to reset your workspace. Proceed with reset?', ...
                'Warning', ...
                'clear','cancel','cancel');
            switch answer
                case 'clear'
                    fileID = fopen(str_path, 'w');
                    fprintf(fileID, '%s\t%s\t%s\n', string(zeros(3,0)));
                    fclose(fileID);
                case 'cancel'
            end
        case "disp"
            if numel(str_dataFromTxt) >= 3
                disp(array2table(str_dataFromTxt',"VariableNames",["Last Updated","Tag","class"]))
            else
                disp("No Tag")
            end
        case "get"
            if numel(str_dataFromTxt) >= 3
                tag = array2table(str_dataFromTxt',"VariableNames",["Last Updated","Tag","class"]);
            else
                tag = array2table(zeros(0,3),"VariableNames",["Last Updated","Tag","class"]);
            end
            return
    end
    tag = [];

end