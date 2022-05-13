function varargout = RISK_GUI(varargin)
% RISK_GUI MATLAB code for RISK_GUI.fig
%      RISK_GUI, by itself, creates a new RISK_GUI or raises the existing
%      singleton*.
%
%      H = RISK_GUI returns the handle to a new RISK_GUI or the handle to
%      the existing singleton*.
%
%      RISK_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RISK_GUI.M with the given input arguments.
%
%      RISK_GUI('Property','Value',...) creates a new RISK_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RISK_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RISK_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RISK_GUI

% Last Modified by GUIDE v2.5 28-Sep-2016 17:34:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RISK_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @RISK_GUI_OutputFcn, ...
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


% --- Executes just before RISK_GUI is made visible.
function RISK_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RISK_GUI (see VARARGIN)

% Choose default command line output for RISK_GUI
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RISK_GUI wait for user response (see UIRESUME)
% uiwait(handles.MarketDataGUI);

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
% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = RISK_GUI_OutputFcn(hObject, eventdata, handles) 
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
s = handles.popupmenu_strategies.Value;
a = handles.popupmenu_account.Value;
if n>1
  handles.parent = handles.popupmenu_symbol.String{n};
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



% --- Executes on button press in pushbuttoSell.
function pushbuttoSell_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttoSell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function edit_balance_Callback(hObject, eventdata, handles)
% hObject    handle to edit_balance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_balance as text
%        str2double(get(hObject,'String')) returns contents of edit_balance as a double


% --- Executes during object creation, after setting all properties.
function edit_balance_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_balance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_leverage_Callback(hObject, eventdata, handles)
% hObject    handle to edit_leverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_leverage as text
%        str2double(get(hObject,'String')) returns contents of edit_leverage as a double


% --- Executes during object creation, after setting all properties.
function edit_leverage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_leverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_stop_Callback(hObject, eventdata, handles)
% hObject    handle to edit_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_stop as text
%        str2double(get(hObject,'String')) returns contents of edit_stop as a double


% --- Executes during object creation, after setting all properties.
function edit_stop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_strategy_equity_Callback(hObject, eventdata, handles)
% hObject    handle to edit_strategy_equity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_strategy_equity as text
%        str2double(get(hObject,'String')) returns contents of edit_strategy_equity as a double


% --- Executes during object creation, after setting all properties.
function edit_strategy_equity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_strategy_equity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_strategy_stop_Callback(hObject, eventdata, handles)
% hObject    handle to edit_strategy_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_strategy_stop as text
%        str2double(get(hObject,'String')) returns contents of edit_strategy_stop as a double


% --- Executes during object creation, after setting all properties.
function edit_strategy_stop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_strategy_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_position_equity_Callback(hObject, eventdata, handles)
% hObject    handle to edit_position_equity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_position_equity as text
%        str2double(get(hObject,'String')) returns contents of edit_position_equity as a double


% --- Executes during object creation, after setting all properties.
function edit_position_equity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_position_equity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_position_stop_Callback(hObject, eventdata, handles)
% hObject    handle to edit_position_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_position_stop as text
%        str2double(get(hObject,'String')) returns contents of edit_position_stop as a double


% --- Executes during object creation, after setting all properties.
function edit_position_stop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_position_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_account_override.
function checkbox_account_override_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_account_override (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_account_override


% --- Executes on button press in checkbox_strategy_override.
function checkbox_strategy_override_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_strategy_override (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_strategy_override


% --- Executes on button press in checkbox_position_override.
function checkbox_position_override_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_position_override (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_position_override


% --- Executes on button press in checkbox_position_auto.
function checkbox_position_auto_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_position_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_position_auto



function edit_booktop_Callback(hObject, eventdata, handles)
% hObject    handle to edit_booktop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_booktop as text
%        str2double(get(hObject,'String')) returns contents of edit_booktop as a double


% --- Executes during object creation, after setting all properties.
function edit_booktop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_booktop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_position_contracts_Callback(hObject, eventdata, handles)
% hObject    handle to edit_position_contracts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_position_contracts as text
%        str2double(get(hObject,'String')) returns contents of edit_position_contracts as a double


% --- Executes during object creation, after setting all properties.
function edit_position_contracts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_position_contracts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonBuy.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonBuy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function editQty_Callback(hObject, eventdata, handles)
% hObject    handle to editQty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editQty as text
%        str2double(get(hObject,'String')) returns contents of editQty as a double


% --- Executes during object creation, after setting all properties.
function editQty_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editQty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function editPx_Callback(hObject, eventdata, handles)
% hObject    handle to editPx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPx as text
%        str2double(get(hObject,'String')) returns contents of editPx as a double


% --- Executes during object creation, after setting all properties.
function editPx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editStopQty_Callback(hObject, eventdata, handles)
% hObject    handle to editStopQty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStopQty as text
%        str2double(get(hObject,'String')) returns contents of editStopQty as a double


% --- Executes during object creation, after setting all properties.
function editStopQty_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStopQty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editStopPx_Callback(hObject, eventdata, handles)
% hObject    handle to editStopPx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editStopPx as text
%        str2double(get(hObject,'String')) returns contents of editStopPx as a double


% --- Executes during object creation, after setting all properties.
function editStopPx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editStopPx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_position_apply.
function pushbutton_position_apply_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_position_apply (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if ~isempty(handles.Position)
  position = handles.Position;
  position.ApplyPosition();
end

% --- Executes on button press in pushbuttonNewLimit.
function pushbuttonNewLimit_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonNewLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if ~isempty(handles.Position)
  px = str2double(handles.editPx.String);
  qty = str2double(handles.editQty.String);
  OMS = handles.Position.OMS(handles.Position.activeOMS);
  OMS.NewLimitOrder(px,qty);
end
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbuttonNewStop.
function pushbuttonNewStop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonNewStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if ~isempty(handles.Position)
  px = str2double(handles.editPx.String);
  qty = str2double(handles.editQty.String);
  OMS = handles.Position.OMS(handles.Position.activeOMS);
  OMS.NewStopOrder(px,qty);
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushbuttonCancelAll.
function pushbuttonCancelAll_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonCancelAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if ~isempty(handles.Position)
  oms = handles.Position.OMS(handles.Position.activeOMS);
  if ~isempty(oms)
    rcol = oms.OMSReports.cols;
    osize = oms.norders;
    activeidx = oms.activeidx(1:osize);
    activeids = find(activeidx);
    for i=1:length(activeids)
      currid = activeids(i);
      px = oms.orders(currid,rcol.price);
      qty = oms.orders(currid,rcol.value);
      orderid = oms.orders(currid,rcol.orderid);
      oms.CancelOrder(orderid,px,qty);
    end
  end
end
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbuttonClose.
function pushbuttonClose_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if ~isempty(handles.Position)
  symbol = handles.Position.Symbol;
  md = symbol.PriceMarket;
  mdcol = md.IO.buffer.cols;
  tcol = handles.Position.Trades.buffer.cols;
  nt = handles.Position.Trades.ntrades;
  currpos = handles.Position.Trades.positioncontracts(nt,tcol.value);
  if currpos < 0
    if md.bestbid(mdcol.price)~=0
      ba = md.bestask(mdcol.price);
      handles.Position.Requests.NewIOCOrder(ba,-currpos);
    end
  elseif currpos > 0
    if md.bestask(mdcol.price)~=0
      bb = md.bestbid(mdcol.price);
      handles.Position.Requests.NewIOCOrder(bb,-currpos);
    end
  end
end
% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in pushbuttonBuy.
function pushbuttonBuy_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonBuy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if ~isempty(handles.Position)
  symbol = handles.Position.Symbol;
  n = symbol.n;
  quotes = handles.Position.Main.quotes;
  lastp = quotes.close(n,quotes.lastbar(end));
  OMS = handles.Position.OMS(handles.Position.activeOMS);
  OMS.NewIOCOrder(lastp+symbol.ticksize*2,symbol.lotmin);
end
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbuttonSell.
function pushbuttonSell_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSell (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
if ~isempty(handles.Position)
  symbol = handles.Position.Symbol;
  n = symbol.n;
  quotes = handles.Position.Main.quotes;
  lastp = quotes.close(n,quotes.lastbar(end));
  OMS = handles.Position.OMS(handles.Position.activeOMS);
  OMS.NewIOCOrder(lastp-symbol.ticksize*2,-symbol.lotmin);
end
% Update handles structure
guidata(hObject, handles);


% --- Executes on selection change in popupmenu_oms.
function popupmenu_oms_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_oms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_oms contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_oms


% --- Executes during object creation, after setting all properties.
function popupmenu_oms_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_oms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_clear.
function pushbutton_clear_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
OMS = handles.Position.OMS(handles.Position.activeOMS);
OMS.reqpendingidx=false(size(OMS.reqpendingidx));
OMS.reqcancelidx=false(size(OMS.reqcancelidx));
OMS.reportpendingidx=false(size(OMS.reportpendingidx));
% Update handles structure
guidata(hObject, handles);
