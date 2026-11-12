function s_file = export(obj, filename, opt)
% Write the bus/branch table or the iteration history to a file.
%
% Writes the result to a file. The format follows the extension of filename:
%   .csv / .txt / .xlsx / .xls : the bus table (tab_bus) or, with Table="branch", the
%                                branch table (tab_branch); phasors as complex numbers.
%   .json                      : the iteration history for the GridSpring viewer
%                                (https://ta-nish18.github.io/GridSpring/). It uses the
%                                stored power flow conditions (tab_PFcondition) and
%                                admittance matrix (cm_Y).
% A relative filename is relative to the current folder.
    arguments (Input)
        obj
        filename  (1,1) string = string(datetime("now","Format","uuMMdd_HHmmss")) + "_PowerFlow.csv" % Output file; its extension selects the format.
        opt.Table (1,1) string {mustBeMember(opt.Table,["bus","branch"])} = "bus" % Table written to a CSV or Excel file.
    end
    arguments (Output)
        s_file % Path of the written file.
    end
    s_file = filename;
    [~, ~, s_ext] = fileparts(s_file);

    switch lower(s_ext)
        case {".csv", ".txt", ".xlsx", ".xls"}
            if opt.Table == "bus"
                tab = obj.tab_bus;
            else
                tab = obj.tab_branch;
            end
            writetable(tab, s_file, "WriteRowNames", true);
        case ".json"
            export_json(obj, s_file);
        otherwise
            error(msg("GUILDA:ResultPF:ExportFormat", char(s_ext)));
    end
end


function export_json(obj, s_file)
% Iteration history in the format of the GridSpring viewer
    arguments (Input)
        obj
        s_file  % Path of the JSON file to write.
    end
    tab_PFcondition = obj.tab_PFcondition;
    cm_Y            = obj.cm_Y;
    if height(tab_PFcondition) == 0 || isempty(cm_Y)
        error(msg("GUILDA:ResultPF:NoNetwork"));
    end
    n_Bus     = size(tab_PFcondition,1);

    out = struct();

    l_slack = tab_PFcondition.Type'=="slack";
    l_PV    = tab_PFcondition.Type'=="PV";
    l_PQ    = tab_PFcondition.Type'=="PQ";

    out.Text =   n_Bus+"Bus Model" +newline + ...
                 " > slack : "              + mat2str(find(l_slack)) + newline + ...
                 " > PV ("+sum(l_PV)+") : " + mat2str(find(l_PV))    + newline +...
                 " > PQ ("+sum(l_PQ)+") : " + mat2str(find(l_PQ))    ;

    out.nodes(n_Bus) = struct('Color',[], 'Label',[], 'Hover',[], ...
                              'Varg' ,[], 'Vabs' ,[] );

    cr_Vbus  = obj.cm_Vhistory;
    rr_Varg  = unwrap(angle(cr_Vbus), [], 2);
    rr_Vabs  = abs(cr_Vbus);
    cr_Ibus  = cm_Y * cr_Vbus;
    cr_Sbus  = cr_Vbus .* conj(cr_Ibus);
    rr_Pflow = -real(cr_Sbus);
    rr_Iflow = -imag(cr_Sbus) ./ rr_Vabs;

    for i_bus = 1:n_Bus
        tab_i = tab_PFcondition(i_bus,:);

        type = tab_i.Type;
        h = "Bus"+i_bus+" ("+type+")"+newline;
        p = nan;
        q = nan;
        switch type
            case "PV"
                c = [0,1,0,1];
                p = {tab_i.P};
                h = h+"P="+tab_i.P+", V="+tab_i.V;
            case "PQ"
                c = [1,0,0,1];
                p = {tab_i.P};
                q = {tab_i.Q};
                h = h+"P="+tab_i.P+", Q="+tab_i.Q;
            case "slack"
                c = [0,0,1,1];
                h = h+"Varg="+tab_i.Varg+", V="+tab_i.V;
            otherwise
                c = [0,0,0,1];
        end
        l = num2str(i_bus);

        out.nodes(i_bus).Color = c;
        out.nodes(i_bus).Label = l;
        out.nodes(i_bus).Hover = h;
        out.nodes(i_bus).Pset  = p;
        out.nodes(i_bus).Qset  = q;
        out.nodes(i_bus).Pflow = rr_Pflow(i_bus,:);
        out.nodes(i_bus).Iflow = rr_Iflow(i_bus,:);
        out.nodes(i_bus).Varg  = rr_Varg(i_bus,:);
        out.nodes(i_bus).Vabs  = rr_Vabs(i_bus,:);
    end
    g = graph(abs(cm_Y),'omitselfloops');
    out.edges = reshape(g.Edges.EndNodes.', [], 1).';

    jsonStr = jsonencode(out,"PrettyPrint",true);
    fid     = fopen(s_file, 'w');
    if fid < 0
        error(msg("GUILDA:ResultPF:FileOpen", char(s_file)));
    end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);

    disp("<INFO>")
    disp("  Exported json file: "+s_file);
    disp("  You can upload this json file to the following link to visualize the calculation process.");
    fprintf('  <a href="https://ta-nish18.github.io/GridSpring/">https://ta-nish18.github.io/GridSpring/</a>\n\n')
end
