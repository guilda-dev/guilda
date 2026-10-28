function varargout = quiet(fcn)
% 関数を実行し、コマンドウィンドウへの表示を抑制する
%
%   [flag, tab, out] = DebugScript.helper.quiet(@() net.initialize);
%
% GUILDA の処理は INFO 表示が多いため、テストの出力を読みやすくするために使う。
% エラーはそのまま呼び出し元へ伝わる。
    out = cell(1, nargout);
    if nargout == 0
        evalc("fcn();");
    else
        evalc("[out{:}] = fcn();");
    end
    varargout = out;
end
