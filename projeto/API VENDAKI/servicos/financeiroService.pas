unit financeiroService;

interface

uses
  XData.Server.Module,
  XData.Service.Common,
  funcoes;

type
  [ServiceContract]
  Ifinanceiros= interface(IInvokable)
    ['{04FB9CCB-F5E2-477C-9AD3-639CCB8D5592}']
    [HttpGet] function Sum(A, B: double): double;
    // By default, any service operation responds to (is invoked by) a POST request from the client.

  end;



implementation




initialization


end.

