{
  KLib Version = 2.0
  The Clear BSD License

  Copyright (c) 2020 by Karol De Nery Ortiz LLave. All rights reserved.
  zitrokarol@gmail.com

  Redistribution and use in source and binary forms, with or without
  modification, are permitted (subject to the limitations in the disclaimer
  below) provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

  * Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY
  THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
  CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
}

unit KLib.Async;

interface

uses
  KLib.Types;

procedure asyncifyProcedure(executorProcedure: KLib.Types.TProcedure); overload;

procedure asyncifyProcedure(executorProcedure: KLib.Types.TProcedure; myCallBacks: KLib.Types.TCallbacks); overload;

procedure asyncifyProcedure(executorProcedure: KLib.Types.TProcedure; _then: KLib.Types.TCallBack; _catch: KLib.Types.TCallback); overload;

procedure asyncifyProcedure(executorProcedure: KLib.Types.TProcedure; reply: KLib.Types.TAsyncifyMethodReply); overload;

//##################################################################################################
procedure asyncifyAnonymousMethod(executorAnonymousMethod: KLib.Types.TAnonymousMethod); overload;

procedure asyncifyAnonymousMethod(executorAnonymousMethod: KLib.Types.TAnonymousMethod; myCallBacks: KLib.Types.TCallbacks); overload;

procedure asyncifyAnonymousMethod(executorAnonymousMethod: KLib.Types.TAnonymousMethod; _then: TCallBack; _catch: KLib.Types.TCallback); overload;

procedure asyncifyAnonymousMethod(executorAnonymousMethod: KLib.Types.TAnonymousMethod; reply: KLib.Types.TAsyncifyMethodReply); overload;
//##################################################################################################
procedure asyncifyMethod(executorMethod: KLib.Types.TMethod); overload;

procedure asyncifyMethod(executorMethod: KLib.Types.TMethod; myCallBacks: KLib.Types.TCallbacks); overload;

procedure asyncifyMethod(executorMethod: KLib.Types.TMethod; _then: TCallBack; _catch: KLib.Types.TCallback); overload;

procedure asyncifyMethod(executorMethod: KLib.Types.TMethod; reply: KLib.Types.TAsyncifyMethodReply); overload;

implementation

uses
  Winapi.Windows,
  System.Classes, System.SysUtils;

procedure asyncifyProcedure(executorProcedure: KLib.Types.TProcedure);
begin
  asyncifyProcedure(executorProcedure, KLib.Types.TCallBack(nil), KLib.Types.TCallback(nil));
end;

procedure asyncifyProcedure(executorProcedure: KLib.Types.TProcedure; myCallBacks: KLib.Types.TCallbacks);
begin
  asyncifyProcedure(executorProcedure, KLib.Types.TCallBack(myCallBacks.resolve), KLib.Types.TCallback(myCallBacks.reject));
end;

procedure asyncifyProcedure(executorProcedure: KLib.Types.TProcedure; _then: KLib.Types.TCallBack; _catch: KLib.Types.TCallback);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        executorProcedure;
        if Assigned(_then) then
        begin
          _then;
        end;
      except
        on E: Exception do
        begin
          if Assigned(_catch) then
          begin
            _catch;
          end;
        end;
      end;
    end).Start;
end;

procedure asyncifyProcedure(executorProcedure: KLib.Types.TProcedure; reply: KLib.Types.TAsyncifyMethodReply);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        executorProcedure;
        PostMessage(reply.handle, reply.msg_resolve, 0, 0);
      except
        on E: Exception do
        begin
          PostMessage(reply.handle, reply.msg_reject, 0, Integer(pansichar(ansistring(e.Message))));
        end;
      end;
    end).Start;
end;

//##################################################################################################

procedure asyncifyAnonymousMethod(executorAnonymousMethod: KLib.Types.TAnonymousMethod);
begin
  asyncifyAnonymousMethod(executorAnonymousMethod, KLib.Types.TCallBack(nil), KLib.Types.TCallback(nil));
end;

procedure asyncifyAnonymousMethod(executorAnonymousMethod: KLib.Types.TAnonymousMethod; myCallBacks: KLib.Types.TCallbacks);
begin
  asyncifyAnonymousMethod(executorAnonymousMethod, KLib.Types.TCallBack(myCallBacks.resolve), KLib.Types.TCallback(myCallBacks.reject));
end;

procedure asyncifyAnonymousMethod(executorAnonymousMethod: KLib.Types.TAnonymousMethod; _then: KLib.Types.TCallBack; _catch: KLib.Types.TCallback);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        executorAnonymousMethod;
        if Assigned(_then) then
        begin
          _then;
        end;
      except
        on E: Exception do
        begin
          if Assigned(_catch) then
          begin
            _catch;
          end;
        end;
      end;
    end).Start;
end;

procedure asyncifyAnonymousMethod(executorAnonymousMethod: KLib.Types.TAnonymousMethod; reply: KLib.Types.TAsyncifyMethodReply);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        executorAnonymousMethod;
        PostMessage(reply.handle, reply.msg_resolve, 0, 0);
      except
        on E: Exception do
        begin
          PostMessage(reply.handle, reply.msg_reject, 0, Integer(pansichar(ansistring(e.Message))));
        end;
      end;
    end).Start;
end;

//##################################################################################################
procedure asyncifyMethod(executorMethod: KLib.Types.TMethod);
begin
  asyncifyMethod(executorMethod, KLib.Types.TCallBack(nil), KLib.Types.TCallback(nil));
end;

procedure asyncifyMethod(executorMethod: KLib.Types.TMethod; myCallBacks: KLib.Types.TCallbacks);
begin
  asyncifyMethod(executorMethod, KLib.Types.TCallBack(myCallBacks.resolve), KLib.Types.TCallback(myCallBacks.reject));
end;

procedure asyncifyMethod(executorMethod: KLib.Types.TMethod; _then: KLib.Types.TCallBack; _catch: KLib.Types.TCallback);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        executorMethod;
        if Assigned(_then) then
        begin
          _then;
        end;
      except
        on E: Exception do
        begin
          if Assigned(_catch) then
          begin
            _catch;
          end;
        end;
      end;
    end).Start;
end;

procedure asyncifyMethod(executorMethod: KLib.Types.TMethod; reply: KLib.Types.TAsyncifyMethodReply);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        executorMethod;
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
