%% Tutorial3bus systrem
% GUILDA Docで作成した3busテストシステム
%
% type_generator>> string型:"1axis","classical"のいづれかを指定（デフォルトは1axis）
%

function net = Tutorial3bus()
    fname = mfilename("fullpath");
    fn = fullfile(fname);
    if nargin<1
        net = network.build(fn);
    else
        net = network.build(fn, type_generator);
    end
end