function XA = align_batch(x, S)
%ALIGN_BATCH  Warp a segment onto each prototype's time axis along the DTW path.
%   XA = ALIGN_BATCH(x, S)
%   x  : [D x L]     S : [n x D x L x L] step matrices from dtw_batch
%   XA : [n x D x L], XA(j,c,k) = mean of x(c,i) over all path cells (i,k)
    [n, D, L, ~] = size(S);
    if n == 0, XA = zeros(0, D, L); return; end
    sumA = zeros(n, D, L); cnt = zeros(n, D, L);
    [JJ, CC] = ndgrid(1:n, 1:D);  JJ = JJ(:); CC = CC(:);
    I = L*ones(n*D,1); K = I; active = true(n*D,1);
    while any(active)
        a = find(active);
        lin = sub2ind([n D L], JJ(a), CC(a), K(a));
        sumA(lin) = sumA(lin) + x(sub2ind([D L], CC(a), I(a)));
        cnt(lin)  = cnt(lin) + 1;
        s = S(sub2ind([n D L L], JJ(a), CC(a), I(a), K(a)));
        atStart = I(a)==1 & K(a)==1;
        dI = (s==1 | s==2);  dK = (s==1 | s==3);
        I(a) = I(a) - double(dI & ~atStart);
        K(a) = K(a) - double(dK & ~atStart);
        active(a(atStart)) = false;
    end
    XA = sumA ./ cnt;
end
