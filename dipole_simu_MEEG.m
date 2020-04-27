
addpath('/home/maximilien.chaumon/ownCloud/MATLAB/fieldtrip/')
ft_defaults

load MEEG_game


cfg = [];
cfg.hmmeg = hmmeg;
cfg.hmeeg = hmeeg;
cfg.dippos = dippos;
cfg.dipmom = dipmom;
cfg.grad = grad;
cfg.elec = elec;
cfg.layeeg = layeeg;
cfg.laymegmag = laymegmag;
cfg.laymegplan = laymegplan;
cfg.mri = mri;

hfig = initplot(cfg);

setappdata(hfig,'cb_buttonpress',hfig.WindowButtonDownFcn);


setappdata(hfig,'myappdata',cfg);
set(hfig,'WindowButtonDownFcn',@mybuttondown)
opt = getappdata(hfig,'opt');
opt.ht5.Position = opt.ht5.Position + [-.1 -.2 0];

plotitall(hfig)

function hfig = initplot(cfg)

cfg.lfmeg = ft_compute_leadfield(cfg.dippos, cfg.grad, cfg.hmmeg,'dipoleunit','nA*m');
cfg.lfeeg = ft_compute_leadfield(cfg.dippos, cfg.elec, cfg.hmeeg,'dipoleunit','nA*m');

% hfig = figure(499);clf;

tmpcfg = [];
tmpcfg.method = 'ortho';
tmpcfg.colorbar = false;
tmpcfg.locationcoordinates = 'head';
tmpcfg.location = cfg.dippos*1000;
% tmpcfg.hfig = hfig;
tmpcfg.atlas = fullfile(fileparts(which('ft_defaults')),'template/atlas/brainnetome/BNA_MPM_thr25_1.25mm.nii');
tmpcfg.queryrange = 1;

ft_sourceplot(tmpcfg,cfg.mri)
opt = getappdata(gcf,'opt');
opt.ijkmom = [10 10 10]';
opt.cfg = cfg;
hfig = gcf;

h = findobj(gcf,'type','axes');
arrayfun(@(x)hold(x,'on'),h)
set(h,'units','pixels');
p = get(gcf,'position');
set(gcf,'position',p .* [1 1 3 1])
h(1).Units = 'normalized';

opt.handlestopo(1) = axes('position',[0.3508    0.1100    0.2    0.7],'tag','topo_mag');
opt.handlestopo(2) = axes('position',[0.5508    0.1100    0.2    0.7],'tag','topo_grad');
opt.handlestopo(3) = axes('position',[0.8    0.1100    0.2    0.7],'tag','topo_eeg');
opt.handlesaxes(1).Units = 'normalized';
opt.handlesaxes(2).Units = 'normalized';
opt.handlesaxes(3).Units = 'normalized';

setappdata(gcf,'opt',opt);

end


function plotitall(hfig)

opt = getappdata(hfig,'opt');

topomeg = opt.cfg.lfmeg * opt.cfg.dipmom;
topoeeg = opt.cfg.lfeeg * opt.cfg.dipmom;

if isfield(opt,'handlesorthoarrow') && all(ishandle(opt.handlesorthoarrow))
    delete(opt.handlesorthoarrow)
end
% opt.cfg.dippos;
% endpoint = opt.cfg.dippos + opt.cfg.dipmom';
% opt.ijk;
% endijk = inv(opt.functional.transform) * [endpoint(:);1] ;
% momijk = endijk(1:3) - opt.ijk(:);
% opt.momijk = momijk;
opt.handlesorthoarrow(1) = quiver3(opt.handlesaxes(1),opt.ijk(1),opt.ijk(2),opt.ijk(3),opt.ijkmom(1),0,opt.ijkmom(3),1,'r','MaxHeadSize',10,'linewidth',2);
opt.handlesorthoarrow(2) = quiver3(opt.handlesaxes(2),opt.ijk(1),opt.ijk(2),opt.ijk(3),0,opt.ijkmom(2),opt.ijkmom(3),1,'r','MaxHeadSize',10,'linewidth',2);
opt.handlesorthoarrow(3) = quiver3(opt.handlesaxes(3),opt.ijk(1),opt.ijk(2),opt.ijk(3),opt.ijkmom(1),opt.ijkmom(2),0,1,'r','MaxHeadSize',10,'linewidth',2);

opt.ht3.String = ['dipole momentum: [' num2str(opt.ijkmom','%g ') '] mm'];

axes(opt.handlestopo(1));cla
tmp = [];
tmp.avg = topomeg;
tmp.time = 1;
tmp.label = opt.cfg.grad.label;
tmp.grad = opt.cfg.grad;
tmp.dimord = 'chan_time';

cfg = [];
cfg.layout = opt.cfg.laymegmag;
cfg.zlim = [-1e-15 1e-15];%'maxabs';%
cfg.interactive = 'no';
cfg.comment = 'no';
cfg.hotkeys = 'no';
cfg.channel = 'megmag';
%     cfg.gridscale = 200;
ft_topoplotER(cfg,tmp);
title('MEG_{mag}','FontSize',20)

%%
tmpdata = [];
tmpdata.avg     = topomeg;
tmpdata.grad    = opt.cfg.grad;
tmpdata.label   = opt.cfg.grad.label;
tmpdata.time    = 0;
tmpdata.dimord  = 'chan_time';
tmpdata.cfg.trl = [0 0];

cfg.method       = 'sum';
cfg.updatesens   = 'yes';
cfg.demean       = 'no';
ft_warning off
tmpdata = ft_combineplanar(cfg,tmpdata);
ft_warning on
%%
axes(opt.handlestopo(2));cla
cfg = [];
cfg.layout = opt.cfg.laymegplan;
cfg.zlim = [-5e-14 5e-14];%'maxabs';%
cfg.interactive = 'no';
cfg.comment = 'no';
cfg.hotkeys = 'no';
cfg.channel = 'meggrad';
ft_topoplotER(cfg,tmpdata);
title('MEG_{grad}','FontSize',20)
%%
axes(opt.handlestopo(3));cla
tmp = [];
tmp.avg = topoeeg;
tmp.time = 1;
tmp.label = opt.cfg.elec.label;
tmp.elec = opt.cfg.elec;
tmp.dimord = 'chan_time';

cfg = [];
cfg.layout = opt.cfg.layeeg;
cfg.marker = 'on';
cfg.zlim = [-1e-8 1e-8];%'maxabs';%
cfg.interactive = 'no';
cfg.comment = 'no';
cfg.hotkeys = 'no';
%     cfg.gridscale = 200;
ft_topoplotER(cfg,tmp);
title('EEG','FontSize',20)

setappdata(hfig,'opt',opt)


end

function mybuttondown(hfig,eventdata)

persistent prevpos

switch get(hfig,'selectiontype')
    case 'normal'
        
        cb_buttonpress = getappdata(hfig,'cb_buttonpress');
        
        cb_buttonpress(hfig,eventdata)
    case 'extend' % shift
        cfg.dipmom = cb_setmom(hfig, eventdata);
end
opt = getappdata(hfig,'opt');

opt.cfg.dippos = opt.functional.transform * [opt.ijk(:);1] / 1000;
opt.cfg.dippos = opt.cfg.dippos(1:3)';
if isempty(prevpos) || ~all(opt.cfg.dippos == prevpos)
    opt.cfg.lfmeg = ft_compute_leadfield(opt.cfg.dippos, opt.cfg.grad, opt.cfg.hmmeg,'dipoleunit','nA*m');
    opt.cfg.lfeeg = ft_compute_leadfield(opt.cfg.dippos, opt.cfg.elec, opt.cfg.hmeeg,'dipoleunit','nA*m');
    prevpos = opt.cfg.dippos;
end

setappdata(hfig,'opt',opt)
plotitall(hfig);

end


function mom = cb_setmom(h, eventdata)

h   = getparent(h);
opt = getappdata(h, 'opt');
cfg = getappdata(h,'myappdata');
ijkorig = opt.ijk(:);

curr_ax = get(h,       'currentaxes');
pos     = mean(get(curr_ax, 'currentpoint'));

tag = get(curr_ax, 'tag');

ijk = ijkorig;
if ~isempty(tag)
    if strcmp(tag, 'ik')
        ijk([1 3])  = round(pos([1 3]));
    elseif strcmp(tag, 'ij')
        ijk([1 2])  = round(pos([1 2]));
    elseif strcmp(tag, 'jk')
        ijk([2 3])  = round(pos([2 3]));
    end
end
opt.ijkmom = ijk(:) - ijkorig(:);

tmptarg = opt.functional.transform * [ijk(:);1];
tmporig = opt.functional.transform * [ijkorig(:);1];

mm = (tmptarg(1:3) - tmporig(1:3)) / 1000;
mom = cfg.dipmom;
mom(mm ~= 0) = mm(mm ~= 0);

opt.cfg.dipmom = mom;

setappdata(h,'opt',opt)

end

function h = getparent(h)
p = h;
while p~=0
    h = p;
    p = get(h, 'parent');
end
end
