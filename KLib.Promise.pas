unit KLib.Promise;

interface

uses
  Vcl.Controls, VCL.Forms,
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  ActiveX,

  KLib.Types;

type

  TAwaitPromiseAll = class
  public
    _exit: boolean;
    result: string;
    constructor Create(procedures: TArrayOfObjectProcedures); reintroduce; overload;
  end;

  TPromiseAll = class
  private
    objectProcedures: TArrayOfObjectProcedures;
    procedures: TArrayOfProcedures;
    thenProcedure: TCallBack;
    catchProcedure: TCallback;
    proceduresAreObject: boolean;
    numberProcedures: integer;
    countProceduresDone: integer;
    _exit: boolean;
    constructor Create(_then: TCallBack; _catch: TCallback); reintroduce; overload;
    procedure executeProcedures;
    procedure createPromise(_procedure: TProcedureOfObject); overload;
    procedure createPromise(_procedure: TProcedure); overload;
    procedure incCountProceduresDone;
  public
    status: string;
    constructor Create(procedures: TArrayOfObjectProcedures; callBacks: TCallbacks); reintroduce; overload;
    constructor Create(procedures: TArrayOfObjectProcedures; _then: TCallBack; _catch: TCallback); reintroduce; overload;
    constructor Create(procedures: TArrayOfProcedures; callBacks: TCallbacks); reintroduce; overload;
    constructor Create(procedures: TArrayOfProcedures; _then: TCallBack; _catch: TCallback); reintroduce; overload;
  end;

  TExecutorFunction = reference to procedure(resolve: TCallBack; reject: TCallback);

  TPromise = class
  private
    executorFunction: TExecutorFunction;
    thenProcedure: TCallBack;
    catchProcedure: TCallback;
    alreadyExecuted: boolean;
    enabledThen: boolean;
    enabledCatch: boolean;
    procedure execute;
    procedure executeInAnonymousThread;
    procedure resolve(msg: string);
    procedure reject(msg: string);
  public
    constructor Create(executorFunction: TExecutorFunction; _then: TCallBack; _catch: TCallback); reintroduce; overload;
    constructor Create(executorFunction: TExecutorFunction); reintroduce; overload;
    procedure _then(value: TCallBack);
    procedure _catch(value: TCallback);
  end;

function awaitPromiseAll(procedures: TArrayOfObjectProcedures): string;

implementation

function awaitPromiseAll(procedures: TArrayOfObjectProcedures): string; // REVIEW
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

constructor TAwaitPromiseAll.Create(procedures: TArrayOfObjectProcedures);
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

constructor TPromiseAll.Create(procedures: TArrayOfObjectProcedures; callBacks: TCallbacks);
begin
  Create(procedures, TCallBack(callBacks.resolve), TCallback(callBacks.reject));
end;

constructor TPromiseAll.Create(procedures: TArrayOfObjectProcedures; _then: TCallBack; _catch: TCallback);
begin
  self.objectProcedures := procedures;
  proceduresAreObject := true;
  Create(_then, _catch);
end;

constructor TPromiseAll.Create(procedures: TArrayOfProcedures; callBacks: TCallbacks);
begin
  Create(procedures, TCallBack(callBacks.resolve), TCallback(callBacks.reject));
end;

constructor TPromiseAll.Create(procedures: TArrayOfProcedures; _then: TCallBack; _catch: TCallback);
begin
  self.procedures := procedures;
  proceduresAreObject := false;
  Create(_then, _catch);
end;

constructor TPromiseAll.Create(_then: TCallBack; _catch: TCallback);
begin
  if proceduresAreObject then
  begin
    self.numberProcedures := Length(objectProcedures);
  end
  else
  begin
    self.numberProcedures := Length(procedures);
  end;
  self.countProceduresDone := 0;

  status := 'created';
  thenProcedure := _then;
  catchProcedure := _catch;
  executeProcedures;
end;

procedure TPromiseAll.executeProcedures;
var
  i: integer;
begin
  status := 'pending';
  _exit := false;
  i := 0;

  for i := 0 to numberProcedures - 1 do
  begin
    if proceduresAreObject then
    begin
      createPromise(self.objectProcedures[i]);
    end
    else
    begin
      createPromise(self.procedures[i]);
    end;
  end;
end;

procedure TPromiseAll.createPromise(_procedure: TProcedureOfObject);
var
  _promise: TPromise;
begin
  _promise := TPromise.Create(
    procedure(resolve: TCallBack; reject: TCallback)
    begin
      if not _exit then
      begin
        _procedure;
        resolve('');
      end;
    end,
    procedure(value: String)
    begin
      incCountProceduresDone;
    end,
    procedure(value: String)
    begin
      status := 'reject';
      if not _exit then
      begin
        catchProcedure(value);
        _exit := true;
      end;
    end);
end;

procedure TPromiseAll.createPromise(_procedure: TProcedure);
var
  _promise: TPromise;
begin
  _promise := TPromise.Create(
    procedure(resolve: TCallBack; reject: TCallback)
    begin
      if not _exit then
      begin
        _procedure;
        resolve('');
      end;
    end,
    procedure(value: String)
    begin
      incCountProceduresDone;
    end,
    procedure(value: String)
    begin
      status := 'reject';
      if not _exit then
      begin
        catchProcedure(value);
        _exit := true;
      end;
    end);
end;

procedure TPromiseAll.incCountProceduresDone;
begin
  inc(countProceduresDone);
  if (countProceduresDone = numberProcedures) then
  begin
    status := 'resolve';
    thenProcedure('');
  end;
end;

type
  EExitPromise = class(EAbort);

constructor TPromise.Create(executorFunction: TExecutorFunction; _then: TCallBack; _catch: TCallback);
begin
  Create(executorFunction);
  self._then(_then);
  self._catch(_catch);
end;

constructor TPromise.Create(executorFunction: TExecutorFunction);
begin
  self.executorFunction := executorFunction;
end;

procedure TPromise._then(value: TCallBack);
var
  enabledExecute: boolean;
begin
  enabledThen := true;
  thenProcedure := value;
  enabledExecute := enabledThen and enabledCatch;
  if enabledExecute then
  begin
    execute;
  end;
end;

procedure TPromise._catch(value: TCallback);
var
  enabledExecute: boolean;
begin
  enabledCatch := true;
  catchProcedure := value;
  enabledExecute := enabledThen and enabledCatch;
  if enabledExecute then
  begin
    execute;
  end;
end;

procedure TPromise.execute;
begin
  if not alreadyExecuted then
  begin
    alreadyExecuted := true;
    executeInAnonymousThread;
  end;
end;

procedure TPromise.executeInAnonymousThread;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      CoInitialize(nil);
      try
        executorFunction(resolve, reject);
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
