% F93 disp_tree と disp_connection のクラス名のリンク
%
%   クラス名 (@ClassName) のリンクは GUILDA のクラスリファレンスを開く GUILDA.doc("class", 名前)
%   を呼び、MATLAB 組み込みの doc は呼ばない。dictionary の [doc] リンクと同じ書き方。
%   リンクはクリックしないので、ブラウザは開かない。
%
% 実行: runtests("DebugScript.test_F93_disp_tree_doc_link")  または  DebugScript.run_all("Features","F93")

%% disp_tree links every class to GUILDA.doc
net = network.Tutorial10bus();
txt = net.disp_tree();
assert(~contains(txt, "matlab:doc("), txt)
% リンクはすべて GUILDA.doc を呼ぶ
c_href = regexp(txt, 'href="([^"]*)"', "tokens");
assert(~isempty(c_href))
assert(all(cellfun(@(c) startsWith(c{1}, "matlab:GUILDA.doc('class', '"), c_href)), txt)
% パッケージ内のクラスも完全な名前で渡し、表示は @ClassName のまま
s_class = class(net.a_Bus{1}.a_Component{1});
assert(contains(s_class, "."), s_class)
assert(contains(txt, "<a href=""matlab:GUILDA.doc('class', '" + s_class + "')"">@" + s_class + "</a>"), txt)
assert(contains(txt, "<a href=""matlab:GUILDA.doc('class', '" + class(net) + "')"">@" + class(net) + "</a>"), txt)


%% disp_connection links every class to GUILDA.doc
net = network.Tutorial10bus();
txt = net.disp_connection();
assert(~contains(txt, "matlab:doc("), txt)
c_href = regexp(txt, 'href="([^"]*)"', "tokens");
assert(~isempty(c_href))
assert(all(cellfun(@(c) startsWith(c{1}, "matlab:GUILDA.doc('class', '"), c_href)), txt)
assert(contains(txt, "<a href=""matlab:GUILDA.doc('class', 'controller.avr.AVR_DC1')"">@controller.avr.AVR_DC1</a>"), txt)
