function varargout = MatrixTraderGUI(varargin)
% SIM MATLAB code for SIM.fig
%      SIM, by itself, creates a new SIM or raises the existing
%      singleton*.
%
%      H = SIM returns the handle to a new SIM or the handle to
%      the existing singleton*.
%
%      SIM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIM.M with the given input arguments.
%
%      SIM('Property','Value',...) creates a new SIM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SIM_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SIM_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MatrixTraderGUI

% Last Modified by GUIDE v2.5 15-Jul-2016 18:00:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MatrixTraderGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @MatrixTraderGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);

if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before MatrixTraderGUI is made visible.
function MatrixTraderGUI_OpeningFcn(hObject, eventdata, handles, varargin)
  % This function has no output args, see OutputFcn.
  % hObject    handle to figure
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  % varargin   command line arguments to MatrixTraderGUI (see VARARGIN)
  addpath(genpath('./'));
  % Choose default command line output for MatrixTraderGUI
  handles.output = hObject;
  %set(hObject,'WindowStyle', 'docked'); %dock gui
  set(hObject,'Name', 'MatrixTrader Simulation'); %name gui
  handles.Market = [];
  handles.MarketData = [];
  handles.nMD_GUI = 0;
  handles.nACCOUNT_GUI = 0;
  handles.nRISK_GUI = 0;
  handles.startdate.String = datestr(now,'yyyy-mm-dd');
  handles.enddate.String = datestr(now,'yyyy-mm-dd');
  flisting = dir('./Init/');
  fcount = 0;
  for f=3:length(flisting)
    fcount = fcount + 1;
    handles.popupmenu_init.String{fcount} = flisting(f).name;
  end

  [a,map]=imread('play.jpg');
  [r,c,d]=size(a); 
  x=ceil(r/30); 
  y=ceil(c/30); 
  g=a(1:x:end,1:y:end,:);
  g(g==255)=5.5*255;
  set(handles.startbutton,'CData',g);

  [a,map]=imread('pause.jpg');
  [r,c,d]=size(a); 
  x=ceil(r/30); 
  y=ceil(c/30); 
  g=a(1:x:end,1:y:end,:);
  g(g==255)=5.5*255;
  set(handles.pausebutton,'CData',g);

  [a,map]=imread('stop.jpg');
  [r,c,d]=size(a); 
  x=ceil(r/30); 
  y=ceil(c/30); 
  g=a(1:x:end,1:y:end,:);
  g(g==255)=5.5*255;
  set(handles.stopbutton,'CData',g);

  [a,map]=imread('new.jpg');
  [r,c,d]=size(a); 
  x=ceil(r/30); 
  y=ceil(c/30); 
  g=a(1:x:end,1:y:end,:);
  g(g==255)=5.5*255;
  set(handles.newbutton,'CData',g);

  [a,map]=imread('load.jpg');
  [r,c,d]=size(a); 
  x=ceil(r/30); 
  y=ceil(c/30); 
  g=a(1:x:end,1:y:end,:);
  g(g==255)=5.5*255;
  set(handles.openbutton,'CData',g);

  [a,map]=imread('save.jpg');
  [r,c,d]=size(a); 
  x=ceil(r/30); 
  y=ceil(c/30); 
  g=a(1:x:end,1:y:end,:);
  g(g==255)=5.5*255;
  set(handles.savebutton,'CData',g);

  % Update handles structure
  guidata(hObject, handles);

% UIWAIT makes MatrixTraderGUI wait for user response (see UIRESUME)
% uiwait(handles.figureMatrixTraderGUI);

% --- Outputs from this function are returned to the command line.
function varargout = MatrixTraderGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in startbutton.
function startbutton_Callback(hObject, eventdata, handles)
% hObject    handle to startbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc
%upath = userpath;
%upath=upath(1:end-1);
%cd(upath);
%addpath(genpath('./'));
handles.sim_stop = false;
handles.sim_pause = false;
handles.update = true;
% Clear Charts 
fnames = fieldnames(handles);
for f=1:length(fnames)
  if strcmp(fnames{f},'MD_GUI')
    handles.nMD_GUI = length(handles.MD_GUI);
    for c=1:handles.nMD_GUI
      curr_fig = handles.MD_GUI(c);
      if isvalid(curr_fig)
        cfighandles = guidata(curr_fig);
        cla(cfighandles.ax_time_price);
        cla(cfighandles.ax_volume_price);
        cla(cfighandles.ax_time_volume);
      end
    end
  end
end
% Update handles structure
guidata(hObject, handles);
% Start Execution
if handles.radiobuttonSIM.Value
  SIMrun;
elseif handles.radiobuttonBT.Value
  BTrun;
elseif handles.radiobuttonRT.Value
  RTrun;
end


% --- Executes on button press in stopbutton.
function stopbutton_Callback(hObject, eventdata, handles)
% hObject    handle to stopbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.sim_stop = true;
guidata(hObject, handles); % Update handles structure


% --- Executes on button press in pausebutton.
function pausebutton_Callback(hObject, eventdata, handles)
% hObject    handle to pausebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.sim_pause = ~handles.sim_pause;
guidata(hObject, handles); % Update handles structure


function startdate_Callback(hObject, eventdata, handles)
% hObject    handle to startdate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of startdate as text
%        str2double(get(hObject,'String')) returns contents of startdate as a double


% --- Executes during object creation, after setting all properties.
function startdate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startdate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chartsON.
function chartsON_Callback(hObject, eventdata, handles)
% hObject    handle to chartsON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chartsON
handles.chartON = handles.chartsON.Value;
guidata(hObject, handles); % Update handles structure


function enddate_Callback(hObject, eventdata, handles)
% hObject    handle to enddate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of enddate as text
%        str2double(get(hObject,'String')) returns contents of enddate as a double


% --- Executes during object creation, after setting all properties.
function enddate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to enddate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function dt_Callback(hObject, eventdata, handles)
% hObject    handle to dt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dt as text
%        str2double(get(hObject,'String')) returns contents of dt as a double


% --- Executes during object creation, after setting all properties.
function dt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chartsONLY.
function chartsONLY_Callback(hObject, eventdata, handles)
% hObject    handle to chartsONLY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chartsONLY
  
  if handles.chartsONLY.Value == 0
    if handles.radiobuttonRT.Value
      handles.startdate.Enable = 'off';
      handles.enddate.Enable = 'off';
      handles.dt.Enable = 'off';
    elseif handles.radiobuttonSIM.Value
      handles.startdate.Enable = 'on';
      handles.enddate.Enable = 'on';
      handles.dt.Enable = 'on';
    end
  else
      handles.startdate.Enable = 'on';
      handles.enddate.Enable = 'off';
      handles.dt.Enable = 'off';
  end
  guidata(hObject, handles); % Update handles structure

% --- Executes on button press in radiobuttonRT.
function radiobuttonRT_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonRT
  handles.radiobuttonSIM.Value = ~handles.radiobuttonRT.Value;
  handles.radiobuttonBT.Value = ~handles.radiobuttonRT.Value;
  if handles.radiobuttonSIM.Value
    editEnable = 'on';
  else
    editEnable = 'off';
  end
  
  if handles.chartsONLY.Value == 0
    handles.startdate.Enable = editEnable;
    handles.enddate.Enable = editEnable;
    handles.dt.Enable = editEnable;
  else
    handles.startdate.Enable = 'on';
    handles.enddate.Enable = 'off';
    handles.dt.Enable = 'off';
  end
  guidata(hObject, handles); % Update handles structure

% --- Executes on button press in radiobuttonSIM.
function radiobuttonSIM_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonSIM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonSIM
  handles.radiobuttonRT.Value = ~handles.radiobuttonSIM.Value;
  handles.radiobuttonBT.Value = ~handles.radiobuttonSIM.Value;
  if handles.radiobuttonSIM.Value
    editEnable = 'on';
  else
    editEnable = 'off';
  end
  
  if handles.chartsONLY.Value == 0
    handles.startdate.Enable = editEnable;
    handles.enddate.Enable = editEnable;
    handles.dt.Enable = editEnable;
  else
    handles.startdate.Enable = 'on';
    handles.enddate.Enable = 'off';
    handles.dt.Enable = 'off';
  end
  guidata(hObject, handles); % Update handles structure

% --- Executes on button press in pushbuttonMD.
function pushbuttonMD_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.nMD_GUI = handles.nMD_GUI + 1;
handles.MD_GUI(handles.nMD_GUI) = openfig('MD_GUI.fig','new');
guidata(hObject, handles); % Update handles structure

% --- Executes on button press in pushbuttonACC.
function pushbuttonACC_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonACC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.nACCOUNT_GUI = handles.nACCOUNT_GUI + 1;
handles.ACCOUNT_GUI(handles.nACCOUNT_GUI) = openfig('TABLE_GUI.fig','new');
guidata(hObject, handles); % Update handles structure

% --- Executes on button press in checkboxChartsOn.
function checkboxChartsOn_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxChartsOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxChartsOn


% --- Executes on button press in radiobuttonBT.
function radiobuttonBT_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonBT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobuttonBT
  handles.radiobuttonRT.Value = ~handles.radiobuttonBT.Value;
  handles.radiobuttonSIM.Value = ~handles.radiobuttonBT.Value;
  if handles.radiobuttonBT.Value
    editEnable = 'on';
  else
    editEnable = 'off';
  end

  if handles.chartsONLY.Value == 0
    handles.startdate.Enable = editEnable;
    handles.enddate.Enable = editEnable;
    handles.dt.Enable = editEnable;
  else
    handles.startdate.Enable = 'on';
    handles.enddate.Enable = 'off';
    handles.dt.Enable = 'off';
  end
  guidata(hObject, handles); % Update handles structure


% --- Executes on button press in pushbutton_update.
function pushbutton_update_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_update (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  handles.update = true;
  guidata(hObject, handles); % Update handles structure


% --- Executes on selection change in popupmenu_init.
function popupmenu_init_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_init (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_init contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_init

% --- Executes during object creation, after setting all properties.
function popupmenu_init_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_init (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonRISK.
function pushbuttonRISK_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRISK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.nRISK_GUI = handles.nRISK_GUI + 1;
handles.RISK_GUI(handles.nRISK_GUI) = openfig('RISK_GUI.fig','new');
guidata(hObject, handles); % Update handles structure


% --- Executes on button press in newbutton.
function newbutton_Callback(hObject, eventdata, handles)
% hObject    handle to newbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Market = [];
handles.MarketData = [];
guidata(hObject, handles); % Update handles structure

% --- Executes on button press in savebutton.
function savebutton_Callback(hObject, eventdata, handles)
% hObject    handle to savebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename,filepath] = uiputfile('*.mat');
if filename~=0
  temp = handles.Market;
  save(strcat(filepath,filename),'temp');
end
guidata(hObject, handles); % Update handles structure

% --- Executes on button press in openbutton.
function openbutton_Callback(hObject, eventdata, handles)
% hObject    handle to openbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename,filepath] = uigetfile('*.mat');
if filename~=0
  load(strcat(filepath,filename));
end
