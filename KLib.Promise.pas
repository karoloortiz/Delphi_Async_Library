unit KLib.Promise;

interface

uses
  KLib.Types;

type

  TAwaitPromiseAll = class  //TODO REVIEW
  public
    _exit: boolean;
    result: string;
    constructor Create(methods: TArrayOfMethods); reintroduce; overload;
  end;

  TPromiseAll = class
  private
    methods: TArrayOfMethods;
    anonymousMethods: TArrayOfAnonymousMethods;
    thenCallback: TCallBack;
    catchCallback: TCallback;
    typeOfProcedure: TTypeOfProcedure;
    numberProcedures: integer;
    countProceduresDone: integer;
    _exit: boolean;
    constructor Create(_then: TCallBack; _catch: TCallback); reintroduce; overload;
    procedure executeProcedures;
    procedure createPromise(_method: TMethod); overload;
    procedure createPromise(_anonymousMethod: TAnonymousMethod); overload;
    procedure incCountProceduresDone;
  public
    status: string;
    constructor Create(methods: TArrayOfMethods; callBacks: TCallbacks); reintroduce; overload;
    constructor Create(methods: TArrayOfMethods; _then: TCallBack; _catch: TCallback); reintroduce; overload;
    constructor Create(anonymousMethods: TArrayOfAnonymousMethods; callBacks: TCallbacks); reintroduce; overload;
    constructor Create(anonymousMethods: TArrayOfAnonymousMethods; _then: TCallBack; _catch: TCallback); reintroduce; overload;
  end;

  TExecutorFunction = reference to procedure(resolve: TCallBack; reject: TCallback);

  TPromise = class
  private
    executorFunction: TExecutorFunction;
    thenCallback: TCallBack;
    catchCallback: TCallback;
    alreadyExecuted: boolean;
    enabledThenCallback: boolean;
    enabledCatchCallback: boolean;
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

function awaitPromiseAll(procedures: TArrayOfMethods): string;

implementation

uses
  VCL.Forms,
  Winapi.ActiveX,
  System.SysUtils, System.Classes;

function awaitPromiseAll(procedures: TArrayOfMethods): string; //TODO REVIEW
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

constructor TAwaitPromiseAll.Create(methods: TArrayOfMethods);
var
  _promiseAll: TPromiseAll;
begin
  _promiseAll := TPromiseAll.Create(methods,
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

constructor TPromiseAll.Create(methods: TArrayOfMethods; callBacks: TCallbacks);
begin
  Create(methods, TCallBack(callBacks.resolve), TCallback(callBacks.reject));
end;

constructor TPromiseAll.Create(methods: TArrayOfMethods; _then: TCallBack; _catch: TCallback);
begin
  self.methods := methods;
  typeOfProcedure := TTypeOfProcedure._method;
  Create(_then, _catch);
end;

constructor TPromiseAll.Create(anonymousMethods: TArrayOfAnonymousMethods; callBacks: TCallbacks);
begin
  Create(anonymousMethods, TCallBack(callBacks.resolve), TCallback(callBacks.reject));
end;

constructor TPromiseAll.Create(anonymousMethods: TArrayOfAnonymousMethods; _then: TCallBack; _catch: TCallback);
begin
  self.anonymousMethods := anonymousMethods;
  typeOfProcedure := TTypeOfProcedure._anonymousMethod;
  Create(_then, _catch);
end;

constructor TPromiseAll.Create(_then: TCallBack; _catch: TCallback);
begin
  case typeOfProcedure of
    TTypeOfProcedure._method:
      self.numberProcedures := Length(methods);
    TTypeOfProcedure._anonymousMethod:
      self.numberProcedures := Length(anonymousMethods);
  end;
  self.countProceduresDone := 0;
  status := 'created';
  thenCallback := _then;
  catchCallback := _catch;
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
    case typeOfProcedure of
      TTypeOfProcedure._method:
        createPromise(self.methods[i]);
      TTypeOfProcedure._anonymousMethod:
        createPromise(self.anonymousMethods[i]);
    end;
  end;
end;

procedure TPromiseAll.createPromise(_method: TMethod);
var
  _promise: TPromise;
begin
  _promise := TPromise.Create(
    procedure(resolve: TCallBack; reject: TCallback)
    begin
      if not _exit then
      begin
        _method;
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
        catchCallback(value);
        _exit := true;
      end;
    end);
end;

procedure TPromiseAll.createPromise(_anonymousMethod: TAnonymousMethod);
var
  _promise: TPromise;
begin
  _promise := TPromise.Create(
    procedure(resolve: TCallBack; reject: TCallback)
    begin
      if not _exit then
      begin
        _anonymousMethod;
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
        catchCallback(value);
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
    thenCallback('');
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
  enabledThenCallback := true;
  thenCallback := value;
  enabledExecute := enabledThenCallback and enabledCatchCallback;
  if enabledExecute then
  begin
    execute;
  end;
end;

procedure TPromise._catch(value: TCallback);
var
  enabledExecute: boolean;
begin
  enabledCatchCallback := true;
  catchCallback := value;
  enabledExecute := enabledThenCallback and enabledCatchCallback;
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
  thenCallback(msg);
  raise EExitPromise.Create('force exit in resolve procedure');
end;

procedure TPromise.reject(msg: string);
begin
  catchCallback(msg);
  raise EExitPromise.Create('force exit in reject procedure');
end;

end.
