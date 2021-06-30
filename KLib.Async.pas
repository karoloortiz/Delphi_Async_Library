{
  KLib Version = 1.0
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

procedure asyncifyMethod(executorMethod: TMethod); overload;

procedure asyncifyMethod(executorMethod: TMethod; callBacks: TCallbacks); overload;
procedure asyncifyMethod(executorMethod: TMethod; _then: TCallBack; _catch: TCallback); overload;

procedure asyncifyMethod(executorMethod: TMethod; reply: TAsyncifyMethodReply); overload;

implementation

uses
  Winapi.Windows,
  System.Classes, System.SysUtils;

procedure asyncifyMethod(executorMethod: TMethod);
begin
  asyncifyMethod(executorMethod, TCallBack(nil), TCallback(nil));
end;

procedure asyncifyMethod(executorMethod: TMethod; callBacks: TCallbacks);
begin
  asyncifyMethod(executorMethod, TCallBack(callBacks.resolve), TCallback(callBacks.reject));
end;

procedure asyncifyMethod(executorMethod: TMethod; _then: TCallBack; _catch: TCallback);
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

procedure asyncifyMethod(executorMethod: TMethod; reply: TAsyncifyMethodReply);
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
