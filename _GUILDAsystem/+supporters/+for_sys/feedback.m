function sys_fb = feedback(sys,keep_ports)
% sysは"ss"クラス
% 同名の入出力ポートをfeedbackループで接続する
%
% keep_ports
%   ・false : feedbackで接続したポートを削除する
%   ・true  : feedbackで接続したポートを入出力ポートとして残す
%   
    arguments
        sys
        keep_ports = false;
    end

    name_input  = reshape( string(sys.InputName ), [],1);
    name_output = reshape( string(sys.OutputName), 1,[]);
    connect_matrix = name_input==name_output;
    
    sys_fb = feedback(sys,ss(connect_matrix));
    
    if ~keep_ports
        keep_port_input  = ~any(connect_matrix,2);
        keep_port_output = ~any(connect_matrix,1);

        sys_fb = sys_fb(keep_port_output,keep_port_input);
    end
end