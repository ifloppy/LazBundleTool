unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, jsonparser, fpjson, process;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Convert: TButton;
    cbxSig: TComboBox;
    ckbSign: TCheckBox;
    editOptPara: TEdit;
    kstoreKAlias: TLabeledEdit;
    kstoreKPass: TLabeledEdit;
    kstoreName: TLabeledEdit;
    kstorePath: TLabeledEdit;
    kstorePass: TLabeledEdit;
    LabeledEditJVM: TLabeledEdit;
    LabeledEditOutput: TLabeledEdit;
    LabeledEditBundleTool: TLabeledEdit;
    kstoreList: TListBox;
    LabeledEditAAB: TLabeledEdit;
    log: TMemo;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    OpenDialog3: TOpenDialog;
    OpenDialog4: TOpenDialog;
    PageControl1: TPageControl;
    Process1: TProcess;
    SaveDialog1: TSaveDialog;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure ConvertClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure kstoreListSelectionChange(Sender: TObject; User: boolean);
  private
    procedure signatureRenderList();
  public

  end;

const
  CONF_FN = 'settings.json';

var
  Form1: TForm1;
  sj: TJSONObject;
  sf: TextFile;


implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then LabeledEditBundleTool.Text := OpenDialog1.FileName;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  sj.Strings['bundle_tool_path'] := LabeledEditBundleTool.Text;
  sj.Strings['java_path'] := LabeledEditJVM.Text;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if OpenDialog2.Execute then kstorePath.Text := OpenDialog2.FileName;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if kstoreName.Text = '' then begin
    MessageDlg('Error', 'Keystore human-readable name is required.', mtError, [mbOK], 0);
  end;
  if sj.Find('signature') = nil then
  begin
    sj.Add('signature', GetJSON('{}'));
  end;
  if sj.Objects['signature'].find(kstoreName.Text) = nil then
  begin
    sj.Objects['signature'].Add(kstoreName.Text, GetJSON('{}'));
  end;
  sj.Objects['signature'].Objects[kstoreName.Text].Strings['path'] := kstorePath.Text;
  sj.Objects['signature'].Objects[kstoreName.Text].Strings['kspswd'] := kstorePass.Text;
  sj.Objects['signature'].Objects[kstoreName.Text].Strings['alias'] := kstoreKAlias.Text;
  sj.Objects['signature'].Objects[kstoreName.Text].Strings['pswd'] := kstoreKPass.Text;
  signatureRenderList();
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  if kstoreList.SelCount = 0 then exit;
  sj.Objects['signature'].Delete(kstoreList.GetSelectedText);
  signatureRenderList();
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  if OpenDialog3.Execute then LabeledEditAAB.Text := OpenDialog3.FileName;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  if SaveDialog1.Execute then LabeledEditOutput.Text := SaveDialog1.FileName;
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  if OpenDialog4.Execute then LabeledEditJVM.Text := OpenDialog4.FileName;
end;

procedure TForm1.ConvertClick(Sender: TObject);
begin
  Process1.Parameters.Clear;
  Process1.Executable := LabeledEditJVM.Text;
  Process1.Parameters.Add('-jar');
  Process1.Parameters.Add(LabeledEditBundleTool.text);
  process1.Parameters.Add('build-apks');
  process1.Parameters.Add('--bundle='+LabeledEditAAB.Text);
  process1.Parameters.Add('--output='+LabeledEditOutput.Text);
  process1.Parameters.Add(editOptPara.Text);
  if ckbSign.Checked then begin
    if cbxSig.Text = '' then begin
      MessageDlg('Error', 'You must select a keystore to enable "sign file"', mtError, [mbOK], 0);
    end;
       process1.Parameters.Add('--ks='+sj.Objects['signature'].Objects[cbxSig.Text].Strings
    ['path']);
       process1.Parameters.Add('--ks-pass=pass:'+sj.Objects['signature'].Objects[cbxSig.Text].Strings
    ['kspswd']);
       process1.Parameters.Add('--ks-key-alias='+sj.Objects['signature'].Objects[cbxSig.Text].Strings
    ['alias']);
       process1.Parameters.Add('--key-pass=pass:'+sj.Objects['signature'].Objects[cbxSig.Text].Strings
    ['pswd']);
  end;
  Process1.Execute;
  log.Lines.LoadFromStream(Process1.Output);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  s: string;
begin
  AssignFile(sf, CONF_FN);
  if FileExists(CONF_FN) then reset(sf)
  else
  begin
    Rewrite(sf);
    CloseFile(sf);
    Reset(sf);
  end;

  while not EOF(sf) do
  begin
    Read(sf, s);
  end;
  CloseFile(sf);
  if s.IsEmpty then
  begin
    sj := GetJSON('{}') as TJSONObject;
  end
  else
  begin
    sj := GetJSON(s) as TJSONObject;
  end;
  signatureRenderList();

  try
  LabeledEditBundleTool.Text := sj.Strings['bundle_tool_path'];
  except
  end;

  try
  LabeledEditJVM.Text := sj.Strings['java_path'];
  except
  end;

end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  s, sn: string;
begin
  Reset(sf);
  if not EOF(sf) then Read(sf, s);
  CloseFile(sf);
  sn := sj.AsJSON;
  if s <> sn then
  begin
    DeleteFile(CONF_FN);
    Rewrite(sf);
    Write(sf, sn);
    CloseFile(sf);
  end;
  sj.Free;
end;

procedure TForm1.kstoreListSelectionChange(Sender: TObject; User: boolean);
begin
  if kstoreList.SelCount = 0 then exit;
  kstorePath.Text := sj.Objects['signature'].Objects[kstoreList.GetSelectedText].Strings
    ['path'];
  kstorePass.Text := sj.Objects['signature'].Objects[kstoreList.GetSelectedText].Strings
    ['kspswd'];
  kstoreKAlias.Text := sj.Objects['signature'].Objects[kstoreList.GetSelectedText].Strings
    ['alias'];
  kstoreKPass.Text := sj.Objects['signature'].Objects[kstoreList.GetSelectedText].Strings
    ['pswd'];
  kstoreName.Text := kstoreList.GetSelectedText;
end;

procedure TForm1.signatureRenderList();
var
  i: uint8;
begin
  if sj.Find('signature') = nil then
  begin
    exit;
  end;
  kstoreList.Clear;
  cbxSig.Clear;
  if sj.Objects['signature'].Count = 0 then exit;
  for i := 0 to Pred(sj.Objects['signature'].Count) do
  begin
    with sj.Objects['signature'] as TJSONObject do
    begin
      kstoreList.Items.Add(Names[i]);
      cbxSig.Items.Add(Names[i]);
    end;
  end;
end;

end.
