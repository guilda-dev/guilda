function iv_size = write_frame(vw, h_capture, iv_size, n_repeat)
% Write the current picture of a figure or axes to an open video n_repeat times.
%
% The size of the first frame, cut to even numbers, is kept for all frames: a frame is
% cut or padded with white to it.
    arguments (Input)
        vw (1,1) VideoWriter    % Open video.
        h_capture               % Figure or axes to record.
        iv_size                 % [px] Height and width of the frames; [] at the first frame.
        n_repeat (1,1) double   % Number of times the frame is written.
    end
    arguments (Output)
        iv_size (1,2) double    % [px] Height and width of the frames.
    end
    img = frame2im(getframe(h_capture));
    if isempty(iv_size)
        iv_size = 2 * floor([size(img, 1), size(img, 2)] / 2);
    end
    img_out = 255 * ones(iv_size(1), iv_size(2), 3, "uint8");
    n_h = min(iv_size(1), size(img, 1));
    n_w = min(iv_size(2), size(img, 2));
    img_out(1:n_h, 1:n_w, :) = img(1:n_h, 1:n_w, :);
    for i = 1:n_repeat
        writeVideo(vw, img_out);
    end
end
