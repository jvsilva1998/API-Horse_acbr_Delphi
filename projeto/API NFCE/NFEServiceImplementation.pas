unit nfe;

interface

uses
  XData.Server.Module,
  XData.Service.Common,
  NFEService;

type
  [ServiceImplementation]
  TNFEService = class(TInterfacedObject, INFEService)
  private
    function Sum(A, B: double): double;
    function EchoString(Value: string): string;
  end;

implementation

function TNFEService.Sum(A, B: double): double;
begin
  Result := A + B;
end;

function TNFEService.EchoString(Value: string): string;
begin
  Result := Value;
end;

initialization
  RegisterServiceType(TNFEService);

end.
