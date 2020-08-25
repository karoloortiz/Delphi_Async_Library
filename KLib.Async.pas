unit KLib.Async;

interface

uses
  System.Classes, Winapi.Windows, System.SysUtils,
  KLib.Types;

procedure asyncifyProcedure(myProcedureWithThrowException: TProcedureOfObject; reply: TAsyncifyProcedureReply);

implementation

procedure asyncifyProcedure(myProcedureWithThrowException: TProcedureOfObject; reply: TAsyncifyProcedureReply);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        myProcedureWithThrowException;
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
