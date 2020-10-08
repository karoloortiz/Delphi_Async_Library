unit KLib.Async;

interface

uses
  System.Classes, Winapi.Windows, System.SysUtils,
  KLib.Types;

procedure asyncifyMethod(methodWithThrowException: TMethod; reply: TAsyncifyProcedureReply);

implementation

procedure asyncifyMethod(methodWithThrowException: TMethod; reply: TAsyncifyProcedureReply);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        methodWithThrowException;
        PostMessage(reply.handle, reply.msg_resolve, 0, 0);
      except
        on E: Exception do
        begin
          PostMessage(reply.handle, reply.msg_reject, 0, Integer(pansichar(ansistring(e.Message))));
        end;
      end;
    end).Start;
end;

end.
