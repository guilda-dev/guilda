% 教科書の図を GUILDA v4 で描くプログラムを、例の番号を選んで実行します。
%
% GUILDA を起動してから（GUILDA.addpath）、コマンドウィンドウで exe_figures_textbook
% を実行し、例の番号（例 2.3 なら 2.3 または 2_3）を入力します。図が描かれ、
% エディターに対応するプログラムが開きます。対応表は README.md にあります。
close all; clear; clc;
addpath(fullfile(fileparts(mfilename("fullpath")), "figures_textbook"));

disp('生成したいグラフに対応する例や節の番号を入力してください');
disp('  ex) 例2.3 → 2.3または2_3');
num_ = input('→ ', "s");
num_cell = strsplit(num_, {'.', '_'});
disp(newline);
if numel(num_cell) ~= 2
    error('ファイル名は例えば、例2.3の場合は 2.3 や 2_3 のように入力してください')
end
name_ = "example_" + num_cell{1} + "_" + num_cell{2};
if ~isfile(fullfile(fileparts(mfilename("fullpath")), "figures_textbook", name_ + ".m"))
    error('入力した番号に対応するファイルは存在しません')
end
feval(name_);
open(name_ + ".m");

disp(newline);
disp(strcat('例/節:', num_, 'に対応するプログラムを実行し、グラフの生成を行い、エディターに対応するプログラムを開きました'));
disp(newline);
