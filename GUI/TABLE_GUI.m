function varargout = TABLE_GUI(varargin)
% TABLE_GUI MATLAB code for TABLE_GUI.fig
%      TABLE_GUI, by itself, creates a new TABLE_GUI or raises the existing
%      singleton*.
%
%      H = TABLE_GUI returns the handle to a new TABLE_GUI or the handle to
%      the existing singleton*.
%
%      TABLE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TABLE_GUI.M with the given input arguments.
%
%      TABLE_GUI('Property','Value',...) creates a new TABLE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TABLE_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TABLE_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TABLE_GUI

% Last Modified by GUIDE v2.5 09-Dec-2015 11:02:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TABLE_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @TABLE_GUI_OutputFcn, ...
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


% --- Executes just before TABLE_GUI is made visible.
function TABLE_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TABLE_GUI (see VARARGIN)

% Choose default command line output for TABLE_GUI
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TABLE_GUI wait for user response (see UIRESUME)
% uiwait(handles.MarketDataGUI);


% --- Outputs from this function are returned to the command line.
function varargout = TABLE_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_symbol.
function pushbutton_symbol_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_symbol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

n = handles.popupmenu_symbol.Value;
t = handles.popupmenu_template.Value;
s = handles.popupmenu_strategies.Value;
a = handles.popupmenu_account.Value;
if n>1 && t>1
  handles.uitable.Data = [];
  handles.parent = handles.popupmenu_symbol.String{n};
  handles.template = handles.popupmenu_template.String{t};
  if s>0 && ~isempty(handles.popupmenu_strategies.String)
    handles.strategy = handles.popupmenu_strategies.String{s};
  else
    handles.strategy = '';
  end
  if a>0 && ~isempty(handles.popupmenu_account.String)
    handles.account = handles.popupmenu_account.String{a};
  else
    handles.account = '';
  end
  handles.popupmenu_serie.Value = 1;
end
%GUIrun;
% Update handles structure
guidata(hObject, handles);


% --- Executes on selection change in popupmenu_symbol.
function popupmenu_symbol_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_symbol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_symbol contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_symbol


% --- Executes during object creation, after setting all properties.
function popupmenu_symbol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_symbol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_serie.
function pushbutton_serie_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_serie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
n = handles.popupmenu_serie.Value;
if n>1
  handles.parent = handles.popupmenu_serie.String{n};
  handles.popupmenu_symbol.Value = 1;
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on selection change in popupmenu_serie.
function popupmenu_serie_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_serie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_serie contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_serie


% --- Executes during object creation, after setting all properties.
function popupmenu_serie_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_serie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_template.
function pushbutton_template_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_template (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
n = handles.popupmenu_template.Value;
if n>1
  cla(handles.ax_time_price);
  cla(handles.ax_volume_price);
  cla(handles.ax_time_volume);
  handles.template = handles.popupmenu_template.String{n};
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on selection change in popupmenu_template.
function popupmenu_template_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_template (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_template contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_template


% --- Executes during object creation, after setting all properties.
function popupmenu_template_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_template (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function MarketDataGUI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MarketDataGUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
handles = guihandles(hObject);
handles.symbol = ExchangeSymbols.empty;
handles.parent = '';
handles.template = '';
handles.Strategy = [];
handles.strategy = '';
handles.Account = [];
handles.account = '';
flisting = dir('./GUI/Tables/');
handles.popupmenu_template.String{1} = '';
s=2;
for f=3:length(flisting)
  handles.popupmenu_template.String{s} = flisting(f).name(1:end-2);
  s=s+1;
end
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbuttonTemplate.
function pushbuttonTemplate_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonTemplate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
n = handles.popupmenu_symbol.Value;
if n>1
  handles.parent = handles.popupmenu_symbol.String{n};
  handles.template = '';
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on selection change in popupmenu_template.
function popupmenu5_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_template (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_template contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_template


% --- Executes during object creation, after setting all properties.
function popupmenu5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_template (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuStrategies.
function popupmenuStrategies_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuStrategies (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuStrategies contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuStrategies


% --- Executes during object creation, after setting all properties.
function popupmenuStrategies_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuStrategies (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu_strategies.
function popupmenu_strategies_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_strategies (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_strategies contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_strategies


% --- Executes during object creation, after setting all properties.
function popupmenu_strategies_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_strategies (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton_plottrades.
function radiobutton_plottrades_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_plottrades (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_plottrades


% --- Executes on button press in radiobutton_plotoperations.
function radiobutton_plotoperations_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_plotoperations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_plotoperations


% --- Executes on selection change in popupmenu_account.
function popupmenu_account_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_account (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_account contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_account


% --- Executes during object creation, after setting all properties.
function popupmenu_account_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_account (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonBuy.
function pushbuttonBuy_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonBuy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbuttoSell.
function pushbuttoSell_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttoSell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
