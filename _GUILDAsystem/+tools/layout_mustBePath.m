function layout_mustBePath(path)
% Validate a Path of the graph parameters (for arguments blocks).
%
% A Path is a text "x y; x y" (see tools.layout_parse_path) or, where the caller accepts
% it, an n x 2 matrix of finite points. A text must be a scalar (mustBeTextScalar); a
% wrong list of points stops with GUILDA:layout_parse_path:InvalidPath.
%
% <@Examples>
% ```matlab
% arguments (Input)
%     opt.Path (1,1) string {tools.layout_mustBePath} = ""
% end
% ```
%
% See also tools.layout_parse_path
    arguments (Input)
        path  % Value to check: text (string scalar or char row) or an n x 2 double matrix.
    end
    if isnumeric(path)
        % rows as "x y"; a matrix without two columns or with a non-finite value fails the parse
        path = strjoin(join(compose("%.15g", real(path)), " ", 2), "; ");
    end
    mustBeTextScalar(path);
    tools.layout_parse_path(path);
end
