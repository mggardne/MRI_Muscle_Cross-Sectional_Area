%#######################################################################
%
%                     * MUSCle THRESHold Program *
%
%          M-file which reads a T1 FFE image file, crops the image, and 
%     thresholds the image.  The user then selects subcutaneous fat,
%     femur and muscle in the left and right thighs.  The program
%     finds all connected muscle and subcutaneous fat tissues.  The
%     femur is filled and used to exclude the femur and marrow from the
%     noncontractile elements within the muscles.  The program prompts
%     the user to create a polygon region of interest around the flexor
%     muscles.  This is used to divide the muscles into extensor and
%     flexor muscles.  The cross-sectional areas for the muscles,
%     subcutaneous fat and noncontractile elements are displayed in the
%     command window.  Creates plots of the raw images, threshold
%     histogram, muscles, subcutaneous fat and noncontractile elements.
%     Optionally, the left and right muscle images may be saved to
%     separate files. 
%
%     NOTES:  1.  DICOM images are not scaled.  Only raw pixel values
%             are used to segment the muscle tissue.  Designed for
%             Philips 3T T1 FFE MRI images.  The background is set to
%             zero by Philips.
%
%             2.  Program assumes images are gray scale images.
%
%             3.  Otsu's method is used to pick the two thresholds.
%             The lower threshold colors pixels below the lower
%             threshold red and the upper threshold colors pixels above
%             the upper threshold green.  The thresholds are shown on
%             plots of the signal intensity histogram.
%
%             4.  See Polygon_ROI_Guide.pdf for tips on creating the
%             polygon ROI.  See musc_thresh.pdf for a guide to using
%             this program.
%
%             5.  Plots are written to Postscript file mthresh_*.ps,
%             where "*" is the image name.
%
%     21-Oct-2020 * Mack Gardner-Morse
%
%     24-Nov-2020 * Mack Gardner-Morse * Included polygon ROI for
%     extensor and flexor muscles.  Included subcutaneous fat and 
%     noncontractile elements measures.
%

%#######################################################################
%
% Postscript Output File for Plots
%
pfile = 'mthresh';      % Postscript output file
%
% Write TIF Files for Left and Right Thigh
%
itif = false;           % Do not write TIF files
%
% Get T1 FFE Image File Name
%
[fnam,pnam] = uigetfile({'*.*',  'All files (*.*)'; ...
                         '*.tif*;*.png*;*.dcm*;*.jpe*;*.jpg*', ...
            'Image files (*.tif*, *.png*, *.dcm*, *.jpe*, *.jpg*)'}, ...
            'Please Select Image File', ...
            'MultiSelect', 'off');
%
ffnam = fullfile(pnam,fnam);
%
% Get Image Name
%
idot = strfind(fnam,'.');
if ~isempty(idot)
  imgnam = fnam(1:idot(end)-1);
else
  imgnam = fnam;
end
%
pfile = [pfile '_' imgnam '.ps'];      % Postscript output file
%
% Read T1 FFE Image from File and Get Range
% 
id = isdicom(ffnam);
if id                   % DICOM image format
  info = dicominfo(ffnam);
  img = dicomread(info);
else                    % Other image formats
   img = imread(ffnam);
end
%
im_sz = size(img);
if length(im_sz)>2
  img = img(:,:,1);     % Assume all channels are equal (gray scale)
end
%
rmin = min(img(:));
rmax = max(img(:));
%
% Setup T1 FFE Figure Window
%
hf1 = figure;
orient landscape;
set(hf1,'WindowState','maximized');
pause(0.1);
drawnow;
%
% Set Up Color Map
%
cmap = gray(128);
cmap(1,:) = [1 0 0];                   % Red for lower threshold
cmap(128,:) = [0 0.7 0];               % Green for upper threshold
%
% Display T1 FFE Image
%
imagesc(img,[rmin rmax]);
colormap gray;
axis image;
axis off;
title({imgnam; 'Original T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage',pfile);
%
% Crop Background From Image
%
[i,j] = find(img>rmin+1);              % Background
idi = min(i):max(i);
idj = min(j):max(j);
%
imgc = img(idi,idj);    % Cropped image
%
% Plot Cropped Image
%
hf2 = figure;
orient landscape;
set(hf2,'WindowState','maximized');
pause(0.1);
drawnow;
%
imagesc(imgc,[rmin rmax]);
colormap gray;
axis image;
axis off;
title({imgnam; 'Cropped T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
% Get Thresholds and Plot Image Histogram
%
lvls = multithresh(imgc,2);            % Otsu's method
%
hf3 = figure;
orient landscape;
set(hf3,'WindowState','maximized');
pause(0.1);
drawnow;
%
histogram(imgc,'FaceAlpha',1,'FaceColor',[0 0 0.8]);
hold on;
axlim = axis;
plot(repmat(lvls(1),2,1),axlim(3:4)','r-','LineWidth',1.0);
plot(repmat(lvls(2),2,1),axlim(3:4)','g-','Color',[0 0.7 0], ...
     'LineWidth',1.0);
%
yt = get(gca,'YTick');
yt = yt(end-1);
text(double(lvls(1))+2,yt,int2str(lvls(1)),'FontSize',12,'Color','r');
text(double(lvls(2))+2,yt,int2str(lvls(2)),'FontSize',12, ...
     'Color',[0 0.7 0]);
%
xlabel('Signal Intensity','FontSize',12,'FontWeight','bold');
ylabel('Frequency','FontSize',12,'FontWeight','bold');
title('T1 FFE Image Histogram','FontSize',16,'FontWeight','bold');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
% Apply Thresholds and Plot
%
imgt = imgc;            % Image with thresholding
%
imgt(imgt<lvls(1)) = rmin;
imgt(imgt>lvls(2)) = rmax;
%
hf4 = figure;
orient landscape;
set(hf4,'WindowState','maximized');
pause(0.1);
drawnow;
%
imagesc(imgt,[rmin rmax]);
colormap(cmap);
axis image;
axis off;
title({imgnam; 'T1 FFE Image with Thresholds'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
% Get Left Thigh Subcutaneous Fat
%
uiwait(msgbox(['Pick a point within the left thigh subcutaneous ', ...
       'fat.'],'Input','modal'));
[xl,yl] = ginput(1);
xl = round(xl);
yl = round(yl);
%
bwl = grayconnected(imgt,yl,xl,1);     % Get subcutaneous fat
imgl = imgc;
imgl(~bwl) = 0;
%
[i,j] = find(imgl>rmin+1);             % Crop background
idil = min(i):max(i);
idjl = min(j):max(j);
imgl = imgl(idil,idjl); % Cropped image
%
rminl = min(imgl(:));
rmaxl = max(imgl(:));
%
% Get Left Thigh (Leg) Femur
%
uiwait(msgbox('Pick a point within the left thigh femur.', ...
       'Input','modal'));
[xl,yl] = ginput(1);
xl = round(xl);
yl = round(yl);
%
bwfl = grayconnected(imgt,yl,xl,1);    % Get femur
bwfl = imfill(bwfl,'holes');           % Femur and marrow
%
% Get Left Thigh (Leg) Muscle
%
uiwait(msgbox('Pick a point within the left muscle.','Input','modal'));
[xl,yl] = ginput(1);
xl = round(xl);
yl = round(yl);
%
imgbwl = imgt;
imgbwl(imgbwl==rmax) = 0;
imgbwl(imgbwl>=lvls(1)&imgbwl<=lvls(2)) = rmax;
%
bwml = grayconnected(imgbwl,yl,xl,1);  % Get connected muscle
imgml = imgt;
imgml(~bwml) = 0;
imgml = imgml(idil,idjl);              % Cropped image
%
% Get Right Thigh Subcutaneous Fat
%
uiwait(msgbox(['Pick a point within the right thigh subcutaneous ', ...
       'fat.'],'Input','modal'));
[xr,yr] = ginput(1);
xr = round(xr);
yr = round(yr);
%
bwr = grayconnected(imgt,yr,xr,1);     % Get subcutaneous fat
imgr = imgc;
imgr(~bwr) = 0;
%
[i,j] = find(imgr>rmin+1);             % Crop background
idir = min(i):max(i);
idjr = min(j):max(j);
imgr = imgr(idir,idjr); % Cropped image
%
rminr = min(imgr(:));
rmaxr = max(imgr(:));
%
% Get Right Thigh (Leg) Femur
%
uiwait(msgbox('Pick a point within the right thigh femur.', ...
       'Input','modal'));
[xr,yr] = ginput(1);
xr = round(xr);
yr = round(yr);
%
bwfr = grayconnected(imgt,yr,xr,1);    % Get femur
bwfr = imfill(bwfr,'holes');           % Femur and marrow
%
% Get Right Thigh (Leg) Muscle
%
uiwait(msgbox('Pick a point within the right muscle.','Input','modal'));
[xr,yr] = ginput(1);
xr = round(xr);
yr = round(yr);
%
imgbwr = imgt;
imgbwr(imgbwr==rmax) = 0;
imgbwr(imgbwr>=lvls(1)&imgbwr<=lvls(2)) = rmax;
%
bwmr = grayconnected(imgbwr,yr,xr,1);  % Get connected muscle
imgmr = imgt;
imgmr(~bwmr) = 0;
imgmr = imgmr(idir,idjr);              % Cropped image
%
% Set Up Call Backs
%
cb1 = ['chk = get(h1,''Checked''); if strcmp(chk,''off''); ', ...
       'set(hw,''Visible'',''on''); set(h1,''Checked'',''on''); ', ...
       'set(he,''Visible'',''off''); set(h2,''Checked'',''off''); ', ...
       'set(hf,''Visible'',''off''); set(h3,''Checked'',''off''); ', ...
       'end'];
%
cb2 = ['chk = get(h2,''Checked''); if strcmp(chk,''off''); ', ...
       'set(he,''Visible'',''on''); set(h2,''Checked'',''on''); ', ...
       'set(hw,''Visible'',''off''); set(h1,''Checked'',''off''); ', ...
       'set(hf,''Visible'',''off''); set(h3,''Checked'',''off''); ', ...
       'end'];
%
cb3 = ['chk = get(h3,''Checked''); if strcmp(chk,''off''); ', ...
       'set(hf,''Visible'',''on''); set(h3,''Checked'',''on''); ', ...
       'set(hw,''Visible'',''off''); set(h1,''Checked'',''off''); ', ...
       'set(he,''Visible'',''off''); set(h2,''Checked'',''off''); ', ...
       'end'];
%
cb4 = ['chk = get(h4,''Checked''); if strcmp(chk,''off''); ', ...
       'set(hm,''Visible'',''on''); set(h4,''Checked'',''on''); ', ...
       'else; set(hm,''Visible'',''off''); set(h4,''Checked'',' ...
       '''off''); end'];
%
% Get ROI for Left Flexor Muscles
%
imgfl = imgc(idil,idjl);
hf5 = figure;
orient landscape;
set(hf5,'WindowState','maximized');
pause(0.1);
drawnow;
%
imagesc(imgfl);
colormap gray;
axis image;
ha5 = gca;
axis off;
title({imgnam; 'Left Thigh Muscle T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
%
uiwait(msgbox({'Please digitize the left flexor muscle.'; ' '; ...
       'Press <Enter> when finished.'},'Input','modal'));
%
hlroi = images.roi.Polygon(ha5,'LineWidth',1);
addlistener(hlroi,'MovingROI',@roi_mov);
hlroi.draw;
%
kchk = true;
%
while kchk
%
     hlroi.wait;
     lfm = hlroi.createMask;           % Left extensor mask
     pts = hlroi.Position;
     pts = [pts; pts(1,:)];
%
% Get Extensors and Flexors
%
     imgmle = imgml;
     imgmle(lfm) = 0;
     imgmlf = imgml;
     imgmlf(~lfm) = 0;
%
% Set Up Figure and Figure Menus
%
     hl = figure;
     orient landscape;
     set(hl,'WindowState','maximized');
     pause(0.1);
     drawnow;
%
     hw = imagesc(imgml);
     colormap gray;
     axis image;
     axis off;
     title({imgnam; 'Left Thigh Muscle T1 FFE Image'},'FontSize',16, ...
           'FontWeight','bold','Interpreter','none');
     hold on;
%
     he = imagesc(imgmle);
     set(he,'Visible','off');
     hf = imagesc(imgmlf);
     set(hf,'Visible','off');
     hm = plot(pts(:,1),pts(:,2),'r-','LineWidth',1);
%
     h0 = uimenu(hl ,'Label','Muscles');
     h1 = uimenu(h0,'Label','Whole Muscle','Checked','on', ...
                 'CallBack',cb1);
     h2 = uimenu(h0,'Label','Extensors','Checked','off','CallBack',cb2);
     h3 = uimenu(h0,'Label','Flexors','Checked','off','CallBack',cb3);
     h4 = uimenu(h0,'Label','ROI','Checked','on','CallBack',cb4);
%
     kchk = logical(menu('Extensor/Flexor Muscles OK?','Yes','No')-1);
%
     close(hl);
%
     if kchk
       figure(hf5);
     end
%
end
%
close(hf5);
%
% Get ROI for Right Flexor Muscles
%
imgfr = imgc(idir,idjr);
hf6 = figure;
orient landscape;
set(hf6,'WindowState','maximized');
pause(0.1);
drawnow;
%
imagesc(imgfr);
colormap gray;
axis image;
ha6 = gca;
axis off;
title({imgnam; 'Right Thigh Muscle T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
%
uiwait(msgbox({'Please digitize the right flexor muscle.'; ' '; ...
       'Press <Enter> when finished.'},'Input','modal'));
%
hrroi = images.roi.Polygon(ha6,'LineWidth',1);
addlistener(hrroi,'MovingROI',@roi_mov);
hrroi.draw;
%
kchk = true;
%
while kchk
     hrroi.wait;
     rfm = hrroi.createMask;           % Right extensor mask
     pts = hrroi.Position;
     pts = [pts; pts(1,:)];
%
% Get Extensors and Flexors
%
     imgmre = imgmr;
     imgmre(rfm) = 0;
     imgmrf = imgmr;
     imgmrf(~rfm) = 0;
%
% Set Up Figure and Figure Menus
%
     hr = figure;
     orient landscape;
     set(hr,'WindowState','maximized');
     pause(0.1);
     drawnow;
%
     hw = imagesc(imgmr);
     colormap gray;
     axis image;
     axis off;
     title({imgnam; 'Right Thigh Muscle T1 FFE Image'},'FontSize', ...
            16,'FontWeight','bold','Interpreter','none');
     hold on;
%
     he = imagesc(imgmre);
     set(he,'Visible','off');
     hf = imagesc(imgmrf);
     set(hf,'Visible','off');
     hm = plot(pts(:,1),pts(:,2),'r-','LineWidth',1);
%
     h0 = uimenu(hr,'Label','Muscles');
     h1 = uimenu(h0,'Label','Whole Muscle','Checked','on', ...
                 'CallBack',cb1);
     h2 = uimenu(h0,'Label','Extensors','Checked','off','CallBack',cb2);
     h3 = uimenu(h0,'Label','Flexors','Checked','off','CallBack',cb3);
     h4 = uimenu(h0,'Label','ROI','Checked','on','CallBack',cb4);
%
     kchk = logical(menu('Extensor/Flexor Muscles OK?','Yes','No')-1);
%
     close(hr);
%
     if kchk
       figure(hf6);
     end
%
end
%
close(hf6);
%
% Get Left Thigh (Leg) Noncontractile Elements
%
bwlf = imfill(bwml,'holes');           % Get whole muscle area
bwlf = bwlf&~bwfl;      % Remove femur and marrow
imgncl = imgc;
imgncl(~bwlf) = 0;
imgncl = imgncl(idil,idjl);
bwncl = imgncl>lvls(2);
imgncl(~bwncl) = 0;
%
% Get Right Thigh (Leg) Noncontractile Elements
%
bwrf = imfill(bwmr,'holes');           % Get whole muscle area
bwrf = bwrf&~bwfr;      % Remove femur and marrow
imgncr = imgc;
imgncr(~bwrf) = 0;
imgncr = imgncr(idir,idjr);
bwncr = imgncr>lvls(2);
imgncr(~bwncr) = 0;
%
% Get Pixel Size
%
if isfield(info,'PixelSpacing')
  pix2cm = prod(info.PixelSpacing)/100;% Conversion from pixel to cm
  units = 'cm^2';
else
  pix2cm = 1;
  units = 'pixel^2';
  warning([' *** Warning in musc_thresh:  Pixel size not found! ', ...
           ' Cross-sectional areas will be in pixel^2 and not cm^2!']);
end
%
% Calculate and Print Out Muscle Cross-Sectional Areas
%
areaml = sum(bwml(:))*pix2cm;          % Total left muscle
areamr = sum(bwmr(:))*pix2cm;          % Total right muscle
%
bwmle = bwml(idil,idjl);
bwmle(lfm) = 0;
areamle = sum(bwmle(:))*pix2cm;        % Left extensors
bwmlf = bwml(idil,idjl);
bwmlf(~lfm) = 0;
areamlf = sum(bwmlf(:))*pix2cm;        % Left flexors
%
bwmre = bwmr(idir,idjr);
bwmre(rfm) = 0;
areamre = sum(bwmre(:))*pix2cm;        % Right extensors
bwmrf = bwmr(idir,idjr);
bwmrf(~rfm) = 0;
areamrf = sum(bwmrf(:))*pix2cm;        % Right flexors
%
fprintf(1,'\n\nMUSCLE CROSS-SECTIONAL AREAS FOR %s\n',imgnam);
fprintf(1,'Left Thigh Cross-Sectional Area = %.1f %s\n',areaml,units);
fprintf(1,'  Extensors Cross-Sectional Area = %.1f %s\n',areamle, ...
        units);
fprintf(1,'  Flexors Cross-Sectional Area = %.1f %s\n',areamlf,units);
%
fprintf(1,'Right Thigh Cross-Sectional Area = %.1f %s\n',areamr, ...
        units);
fprintf(1,'  Extensors Cross-Sectional Area = %.1f %s\n',areamre, ...
        units);
fprintf(1,'  Flexors Cross-Sectional Area = %.1f %s\n',areamrf,units);
%
% Calculate and Print Out Subcutaneous Fat Cross-Sectional Areas
%
areal = sum(bwl(:))*pix2cm;
arear = sum(bwr(:))*pix2cm;
%
fprintf(1,'\nSUBCUTANEOUS FAT CROSS-SECTIONAL AREAS FOR %s\n',imgnam);
fprintf(1,'Left Thigh Cross-Sectional Area = %.1f %s\n',areal,units);
fprintf(1,'Right Thigh Cross-Sectional Area = %.1f %s\n',arear,units);
%
% Calculate and Print Out Noncontractile Elements Cross-Sectional Areas
%
areancl = sum(bwncl(:))*pix2cm;
areancr = sum(bwncr(:))*pix2cm;
%
fprintf(1,['\nNONCONTRACTILE ELEMENTS CROSS-SECTIONAL AREAS ', ...
           'FOR %s\n'],imgnam);
fprintf(1,'Left Thigh Cross-Sectional Area = %.1f %s\n',areancl,units);
fprintf(1,'Right Thigh Cross-Sectional Area = %.1f %s\n\n\n', ...
        areancr,units);
%
% Write Results to Output File
%

%
% Plot Final Left Thigh Muscle and Left Extensors and Flexors
%
hf5 = figure;
orient landscape;
set(hf5,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgml);
colormap gray;
axis image;
axis off;
hold on;
%
text(2,2,sprintf('Cross-sectional area = %.1f %s\n',areaml, ...
     units),'HorizontalAlign','left','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({imgnam; 'Left Thigh Muscle T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
hf6 = figure;
orient tall;
set(hf6,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
subplot(2,1,1);
imagesc(imgmle);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmle);
xt = dims(2)/2;
yt = 0.85*dims(1);
text(xt,yt,sprintf('Cross-sectional area = %.1f %s\n',areamle, ...
     units),'HorizontalAlign','center','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({'Left Thigh Muscle T1 FFE Image'; 'Extensor Muscles'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
%
subplot(2,1,2);
imagesc(imgmlf);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmlf);
xt = dims(2)/2;
yt = 0.02*dims(1);
text(xt,yt,sprintf('Cross-sectional area = %.1f %s\n',areamlf, ...
     units),'HorizontalAlign','center','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title('Flexor Muscles','FontSize',16,'FontWeight','bold');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
% Plot Final Right Thigh Muscle and Right Extensors and Flexors
%
hf7 = figure;
orient landscape;
set(hf7,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgmr);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmr,2);
text(dims-1,2,sprintf('Cross-sectional area = %.1f %s\n',areamr, ...
     units),'HorizontalAlign','right','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({imgnam; 'Right Thigh Muscle T1 FFE Image'},'FontSize',16, ...
      'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
hf8 = figure;
orient tall;
set(hf8,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
subplot(2,1,1);
imagesc(imgmre);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmre);
xt = dims(2)/2;
yt = 0.85*dims(1);
text(xt,yt,sprintf('Cross-sectional area = %.1f %s\n',areamre, ...
     units),'HorizontalAlign','center','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({'Right Thigh Muscle T1 FFE Image'; 'Extensor Muscles'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
%
subplot(2,1,2);
imagesc(imgmrf);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgmrf);
xt = dims(2)/2;
yt = 0.02*dims(1);
text(xt,yt,sprintf('Cross-sectional area = %.1f %s\n',areamrf, ...
     units),'HorizontalAlign','center','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title('Flexor Muscles','FontSize',16,'FontWeight','bold');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
% Display Left Thigh Subcutaneous Fat T1 FFE Image
%
hf9 = figure;
orient landscape;
set(hf9,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgl,[rminl rmaxl]);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgl,2);
text(dims-1,2,sprintf('Cross-sectional area = %.1f %s\n',areal, ...
     units),'HorizontalAlign','right','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({imgnam; 'Left Thigh Subcutaneous Fat T1 FFE Image'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
% Display Right Thigh Subcutaneous Fat T1 FFE Image
%
hf10 = figure;
orient landscape;
set(hf10,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgr,[rminr rmaxr]);
colormap gray;
axis image;
axis off;
hold on;
%
text(2,2,sprintf('Cross-sectional area = %.1f %s\n',arear, ...
     units),'HorizontalAlign','left','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({imgnam; 'Right Thigh Subcutaneous Fat T1 FFE Image'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
% Display Left Thigh Noncontractile Elements T1 FFE Image
%
hf11 = figure;
orient landscape;
set(hf11,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgncl,[rminl rmaxl]);
colormap gray;
axis image;
axis off;
hold on;
%
text(2,2,sprintf('Cross-sectional area = %.1f %s\n',areancl, ...
     units),'HorizontalAlign','left','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({imgnam; 'Left Thigh Noncontractile Elements T1 FFE Image'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
% Display Right Thigh Noncontractile Elements T1 FFE Image
%
hf12 = figure;
orient landscape;
set(hf12,'WindowState','maximized','InvertHardcopy','off');
pause(0.1);
drawnow;
%
imagesc(imgncr,[rminr rmaxr]);
colormap gray;
axis image;
axis off;
hold on;
%
dims = size(imgncr,2);
text(dims-1,2,sprintf('Cross-sectional area = %.1f %s\n',areancr, ...
     units),'HorizontalAlign','right','VerticalAlignment','top', ...
     'Color','w','FontSize',11,'FontWeight','bold','Color','w');
%
title({imgnam; 'Right Thigh Noncontractile Elements T1 FFE Image'}, ...
      'FontSize',16,'FontWeight','bold','Interpreter','none');
print('-dpsc2','-r600','-fillpage','-append',pfile);
%
% Write Left and Right Thigh Muscle T1 FFE Images to TIFF Files
%
if itif
%
  tifnaml = [imgnam 'L.tif'];
  tifnamr = [imgnam 'R.tif'];
%
  imwrite(imgl*65535/rmaxl,tifnaml,'tif');
  imwrite(imgr*65535/rmaxr,tifnamr,'tif');
%
end
%
return