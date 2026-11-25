% 例3.12（プログラム3-14）の GUILDA v4 版: 送電線からアドミタンス行列を作ります。
% 旧版の branch(from, to, y) は送電線のアドミタンス y を与えます。
% v4 の pi 型送電線はインピーダンス R + jX で与えるため、R + jX = 1/y とします。

y12 = 1.3652 - 11.6040j;
y23 = -10.5107j;

net = PowerNetwork();
for k = 1:3
    net.add_bus();
end
net.add_branch("pi", [1,2], R=real(1/y12), X=imag(1/y12));
net.add_branch("pi", [2,3], R=real(1/y23), X=imag(1/y23));

tab_Y = net.get_admittance_matrix();   % 行と列の名前が母線のタグの table
Y = tab_Y{:,:}
