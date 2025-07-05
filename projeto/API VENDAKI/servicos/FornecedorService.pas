unit FornecedorService;

interface

uses
  XData.Server.Module,
  XData.Service.Common,
  funcoes,
  parametros,
  fornecedor,
  System.JSON;

type
  [ServiceContract]
  Ifornecedores= interface(IInvokable)
    ['{04FB9CCB-F5E2-477C-9AD3-639CCB8D5592}']

  end;

  [ServiceImplementation]
  TIfornecedores = class(TInterfacedObject, Ifornecedores)
  private

  end;

implementation



{ TIfornecedores }











initialization
  RegisterServiceType(TypeInfo(Ifornecedores));
  RegisterServiceType(TIfornecedores);

end.

