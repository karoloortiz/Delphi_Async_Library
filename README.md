# Delphi_Async_Library

KLib Version = 3.0

A library with some async utilities for your Delphi Apps.

- FEATURES
	- FULL IMPLEMENTATION OF PROMISES FROM JAVASCRIPT WITH SUPPORT OF Promises chaining
		- SEE DOC https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
	- PROMISE.ALL
	- ASYNC FUNCTIONS

## Dependencies:
 - https://github.com/karoloortiz/Delphi_Utils_Library.git

# QUICK START

## PROMISE
```pascal
procedure myJob;
begin
//work
end;

procedure executionInAsyncModeWith_TPromise;
var
  _promise: TPromise;
begin
  _promise := TPromise.Create(
    procedure(resolve: TCallBack; reject: TCallBack)
    begin
      myJob;
      resolve('finish');
    end,
    procedure(value: String) // _then method
    begin
      //then method
    end,
    procedure(value: String) // _catch method
    begin
      //catch method
    end);

  // YOU CAN CHAIN THE PROMISE, USE _finally TO DESTROY THE PROMISE
  _promise._then(
    procedure(value: string)
    begin
      //then method2
    end)._then(
    procedure(value: string)
    begin
      //then method3
    end)._finally;
end;
```
## PROMISIFY
```pascal
procedure myJob;
begin
//work
end;

procedure executionInAsyncModeWith_Promisify;
var
  _callbacks: TCallBacks;
begin
  with _callbacks do
  begin
    resolve := procedure(msg: string)
      begin
        //resolve
      end;
    reject := procedure(msg: string)
      begin
	//catch
      end;
  end;
  
  promisify(myJob, _callbacks)._finally;
end;
```

## PROMISE.ALL
```pascal
procedure myJob1;
begin
//work
end;

procedure myJob2;
begin
//work
end;

procedure myJob3;
begin
//work
end;

procedure executionInAsyncModeWith_PromiseAll;
begin
  TPromise.all([myjob1, myjob2, myjob3])._then(
    procedure(value: String) // _then method
    begin
	//then
    end)._catch(
    procedure(value: String) // _catch method
    begin
    	//catch
    end)._finally;
end;
```

# Examples:
  - example-1-async.zip: an example of use "TPromise", "promisify", "TPromise.All" "asyncifyMethod", "TAsyncMethod" and "TAsyncMethods"


If you need support, add a star to the repository and don't hesitate to contact me at zitrokarol@gmail.com
