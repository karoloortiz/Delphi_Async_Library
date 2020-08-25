unit KLib.Promise;

interface

uses
  Vcl.Controls, Winapi.Messages, System.SysUtils, VCL.Forms, Winapi.Windows, System.Classes,

  ActiveX,

  KLib.Types;

const
  WM_PROMISE_EXECUTE = WM_USER + 102;

type

  TResolve = reference to procedure(msg: String);
  TReject = reference to procedure(msg: String);
  TPromiseFull = reference to procedure(resolve: TResolve; reject: TResolve);

  TPromiseResolve = reference to procedure(resolve: TResolve);
  TPromiseReject = reference to procedure(reject: TReject);

  TPromise = class(TWinControl)
  private
    _mainProcedureFull: TPromiseFull;
    _mainProcedureOnlyResolve: TPromiseResolve;
    _mainProcedureOnlyReject: TPromiseReject;
    thenProcedure: TResolve;
    catchProcedure: TReject;
    alreadyExecuted: boolean;
    enabledExecute: boolean;
    enabledThen: boolean;
    enabledCatch: boolean;
    procedure onPromiseExecute(var Msg: TMessage); message WM_PROMISE_EXECUTE;
    procedure executeInAnonymousThread;
    procedure mainProcedure;
    procedure resolve(msg: string);
    procedure reject(msg: string);
  public
    procedure _then(value: TResolve);
    procedure _catch(value: TReject);
    constructor Create(mainProcedureOnlyResolve: TPromiseResolve); reintroduce; overload;
    constructor Create(mainProcedureOnlyReject: TPromiseReject); reintroduce; overload;

    constructor Create(mainProcedureFull: TPromiseFull; _then: TResolve; _catch: TReject); reintroduce; overload;
    constructor Create(mainProcedureFull: TPromiseFull); reintroduce; overload;
  end;

  TAwaitPromiseAll = class(TWinControl)
  public
    _exit: boolean;
    result: string;
    constructor Create(procedures: TArrayOfProcedures); reintroduce; overload;
  end;

  TPromiseAll = class(TWinControl)
  private
    procedures: TArrayOfProcedures;
    numberProcedures: integer;
    countProceduresDone: integer;
    thenProcedure: TResolve;
    catchProcedure: TReject;

    status: string;
    _exit: boolean;
    procedure executeProcedures;
    procedure createPromise(_procedure: TProcedureOfObject);

    procedure incCountProceduresDone;
  public
    //
    //    procedure _then(value: TResolve);
    //    procedure _catch(value: TReject);
    constructor Create(procedures: TArrayOfProcedures; _then: TResolve; _catch: TReject); reintroduce; overload;
  end;

  EExitPromise = class(EAbort);

function awaitPromiseAll(procedures: TArrayOfProcedures): string;

implementation

function awaitPromiseAll(procedures: TArrayOfProcedures): string; // REVIEW
var
  _awaitPromiseAll: TAwaitPromiseAll;
  _result: string;
begin
  _awaitpromiseAll := TAwaitPromiseAll.Create(procedures);
  while not _awaitPromiseAll._exit do
  begin
    Application.ProcessMessages;
    sleep(500);
  end;
  _result := _awaitPromiseAll.result;
  FreeAndNil(_awaitPromiseAll);
  result := _result;
end;

constructor TAwaitPromiseAll.Create(procedures: TArrayOfProcedures);
var
  _promiseAll: TPromiseAll;
begin
  _promiseAll := TPromiseAll.Create(procedures,
    procedure(value: String)
    begin
      result := value;
      _exit := true;
    end,
    procedure(value: String)
    begin
      raise Exception.Create(value);
    end);
end;

constructor TPromiseAll.Create(procedures: TArrayOfProcedures; _then: TResolve; _catch: TReject);
begin
  self.procedures := procedures;
  self.numberProcedures := Length(procedures);
  self.countProceduresDone := 0;
  Create(nil);
  Parent := Application.MainForm;

  //  status := 'created';
  thenProcedure := _then;
  catchProcedure := _catch;
  executeProcedures;
end;

procedure TPromiseAll.executeProcedures;
var
  i: integer;
begin
  //  status := 'pending';
  _exit := false;
  i := 0;
  while not _exit do
  begin
    if i < numberProcedures then
    begin
      createPromise(self.procedures[i]);
      inc(i);
    end
    else
    begin
      _exit := true;
    end;
  end;
end;

procedure TPromiseAll.createPromise(_procedure: TProcedureOfObject);
var
  _promise: TPromise;
begin
  _promise := TPromise.Create(
    procedure(resolve: TResolve; reject: TResolve)
    begin
      _procedure;
      resolve('');
    end,
    procedure(value: String)
    begin
      incCountProceduresDone;
    end,
    procedure(value: String)
    begin
      //      status := 'reject';
      catchProcedure(value);
      _exit := true;
    end);
end;

procedure TPromiseAll.incCountProceduresDone;
begin
  inc(countProceduresDone);
  if countProceduresDone = numberProcedures then
  begin
    //    status := 'resolve';
    thenProcedure('');
  end;
end;

constructor TPromise.Create(mainProcedureOnlyResolve: TPromiseResolve);
begin
  self._mainProcedureOnlyResolve := mainProcedureOnlyResolve;
  enabledCatch := true;
  Create(nil);
  Parent := Application.MainForm;
end;

constructor TPromise.Create(mainProcedureOnlyReject: TPromiseReject);
begin
  self._mainProcedureOnlyReject := mainProcedureOnlyReject;
  enabledThen := true;
  Create(nil);
  Parent := Application.MainForm;
end;

constructor TPromise.Create(mainProcedureFull: TPromiseFull; _then: TResolve; _catch: TReject);
begin
  Create(mainProcedureFull);
  self._then(_then);
  self._catch(_catch);
end;

constructor TPromise.Create(mainProcedureFull: TPromiseFull);
begin
  self._mainProcedureFull := mainProcedureFull;
  Create(nil);
  Parent := Application.MainForm;
end;

procedure TPromise._then(value: TResolve);
begin
  enabledThen := true;
  thenProcedure := value;
  enabledExecute := enabledThen and enabledCatch;
  if enabledExecute then
  begin
    PostMessage(self.Handle, WM_PROMISE_EXECUTE, 0, 0);
  end;
end;

procedure TPromise._catch(value: TReject);
begin
  enabledCatch := true;
  catchProcedure := value;
  enabledExecute := enabledThen and enabledCatch;
  if enabledExecute then
  begin
    PostMessage(self.Handle, WM_PROMISE_EXECUTE, 0, 0);
  end;
end;

procedure TPromise.onPromiseExecute(var Msg: TMessage);
begin
  if not alreadyExecuted then
  begin
    alreadyExecuted := true;
    executeInAnonymousThread;
  end;
end;

procedure TPromise.executeInAnonymousThread;
//var
//  _thread: TThread;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      CoInitialize(nil);
      try
        mainProcedure;
      except
        on e: Exception do
        begin
          if (e.ClassType <> EExitPromise) then
          begin
            CoUninitialize;
            reject(e.Message);
          end;
        end;
      end;
      CoUninitialize;
    end).Start;

  //  TThread.Synchronize(nil,
  //    procedure
  //    begin
  //      CoInitialize(nil);
  //      try
  //        mainProcedure;
  //      except
  //        on e: Exception do
  //        begin
  //          if (e.ClassType <> EExitPromise) then
  //          begin
  //            CoUninitialize;
  //            reject(e.Message);
  //          end;
  //        end;
  //      end;
  //      CoUninitialize;
  //    end);
end;

procedure TPromise.mainProcedure;
begin
  if Assigned(_mainProcedureFull) then
  begin
    _mainProcedureFull(resolve, reject);
  end
  else if Assigned(_mainProcedureOnlyResolve) then
  begin
    _mainProcedureOnlyResolve(resolve);
  end
  else if Assigned(_mainProcedureOnlyReject) then
  begin
    _mainProcedureOnlyReject(reject);
  end;
end;

procedure TPromise.resolve(msg: string);
begin
  thenProcedure(msg);
  raise EExitPromise.Create('force exit in resolve procedure');
end;

procedure TPromise.reject(msg: string);
begin
  catchProcedure(msg);
  raise EExitPromise.Create('force exit in reject procedure');
end;

end.
