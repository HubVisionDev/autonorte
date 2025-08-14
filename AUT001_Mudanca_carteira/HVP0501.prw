#Include "Totvs.ch"
#INCLUDE "rwmake.ch"
#Include "Protheus.ch"
#Include 'TOPCONN.ch'
#Include 'TbiCONN.ch'
#Include 'FWMVCDef.ch'
/*
#---------------------------------------------------------------#
| Programa:| HVP0501                           Data:22/05/2025  |
|---------------------------------------------------------------|
| Autor:   | HubVision - Raphael Neves                          |
|---------------------------------------------------------------|
| Objetivo:| Tela para alteração dos vendedores                 |
|---------------------------------------------------------------|
|                        ALTERAÇÕES                             |
|---------------------------------------------------------------|
|     Analista      |   Data     |  Motivo                      |
|---------------------------------------------------------------|
|                   |            |                              |
|                   |            |                              |
#---------------------------------------------------------------#
LINK TDN: ** NÃO TEM **
*/
#Define ENTER CHR(13)+CHR(10)

User Function HVP0501()

	HVP0501A(IsBlind())

Return

Static Function HVP0501A(lJob)
	Local nContFlds := 0
	Local aSeek     := {}
	Local aColumns  := {}
	// Local aTamanho  := {}
	Local aStru     := FWSX3Util():GetAllFields("ZV2",.T.) //Segundo parâmetro diz se é para trazer os virtuais
	Local aIndice   := {"ZV2_CLIENT","ZV2_ULTVD","ZV2_DTPROC"}
	Local cNoField  := "ZV2_FILIAL,ZV2_OK"
	Local nX

	Private aAlter    := {}
	Private aFields   := {}
	Private cCmpMk    := "ZV2_OK"
	Private cMark     := ""
	Private oTempTable

	Private cCadastro := "Alteração de vendedores"
	Private oMark
	Private cAlias    := GetNextAlias()
	// Private cAlias    := "ZV2"
	Private cTabela   := "ZV2"

	oMark := FWMarkBrowse():New()
	cMark:= oMark:Mark()

	oMark:SetDescription(cCadastro)

	//Montagem de estrutura dos campos visiveis
	For nX := 1 to Len(aStru)
		aadd(aFields, {aStru[nX]  , FWSX3Util():GetDescription(aStru[nX])})
		IF GetSx3Cache(aStru[nX],"X3_VISUAL") <> "V"
			aAdd(aAlter,aStru[nX])
		Endif
	Next nX

	aadd(aFields, {"RECZV2"  , "RECNO"})

	//Adição dos índices
	For nX := 1 to Len(aIndice)
		// aTamanho := FWSX3Util():GetFieldStruct( aIndice[nX] )
		aAdd(aSeek,{GetSX3Cache(aIndice[nX], "X3_TITULO"), {{"", GetSX3Cache(aIndice[nX], "X3_TIPO"), GetSX3Cache(aIndice[nX], "X3_TAMANHO"), GetSX3Cache(aIndice[nX], "X3_DECIMAL"), AllTrim(GetSX3Cache(aIndice[nX], "X3_TITULO")), AllTrim(GetSX3Cache(aIndice[nX], "X3_PICTURE"))}} } )
		// aAdd(aSeek,{FWSX3Util():GetDescription(aIndice[nX]),{{"",aTamanho[2],aTamanho[3],aTamanho[4],aIndice[nX],aTamanho[5]}} } )
	Next

	// //Definição do preenchimento do campo e tamanho em tela
	For nContFlds := 1 To Len( aFields )
		If !(aFields[nContFlds][1] $ cNoField)
			AAdd( aColumns, FWBrwColumn():New() )

			aColumns[Len(aColumns)]:SetData( &("{ || " + aFields[nContFlds][1] + " }") )
			aColumns[Len(aColumns)]:SetTitle( aFields[nContFlds][2] )
			aColumns[Len(aColumns)]:SetPicture( GetSX3Cache(aFields[nContFlds][1], "X3_PICTURE"))
			aColumns[Len(aColumns)]:SetSize( 15 )
			aColumns[Len(aColumns)]:SetID( aFields[nContFlds] )
		Endif
	Next nContFlds

	// oMark:AddStatusColumns({ || BrwStatus() }, { || BrwLegend() })
	oMark:SetColumns( aColumns )

	MsgRun("Carregando dados...","Aguarde",{|| U_CarregaDados() })
	// MsgRun("Carregando dados...","Aguarde",{|| CarregaDados() })

	oMark:SetUseFilter(.T.)
	oMark:SetAlias( cAlias )
	oMark:SetTemporary()
	oMark:SetMenuDef('HVP0501')
	oMark:SetFieldMark( cCmpMk )
	oMark:SetSeek(.T.,aSeek)

	oMark:Activate()

	//---------------------------------
	//Exclui a tabela
	//---------------------------------
	oTempTable:Delete()
Return

User Function CarregaDados()
// Static Function CarregaDados()
	Local aSetField := {}
	Local aIndice   := {}
	Local aSetCmp   := aAlter
	Local aStrCmp   := aFields
	Local aCampos   := {}
	Local nI
	Local cQuery
	Local nX
	//-------------------
	//Criação do objeto
	//-------------------
	oTempTable := FWTemporaryTable():New( cAlias )
	//--------------------------
	//Monta os campos da tabela
	//--------------------------
	For nX := 1 to Len(aStrCmp)
		If "RECZV2" $ aStrCmp[nX][1]
			aadd(aCampos,{aStrCmp[nX][1],"N",10,0} )
		Else
			aadd(aCampos,{aStrCmp[nX][1],TamSX3(aStrCmp[nX][1])[3],TamSX3(aStrCmp[nX][1])[1],TamSX3(aStrCmp[nX][1])[2]} )
		Endif
	Next nX

	For nX := 1 to Len(aSetCmp)
		aadd(aSetField,{aSetCmp[nX],TamSX3(aSetCmp[nX])[3],TamSX3(aSetCmp[nX])[1],TamSX3(aSetCmp[nX])[2]} )
	Next nX

	oTemptable:SetFields( aCampos )
	aIndice := FWSIXUtil():GetAliasIndexes(cTabela)
	For nX := 1 to Len(aIndice)
		oTempTable:AddIndex(StrZero(nX,2), aIndice[nX] )
	Next

	//------------------
	//Criação da tabela
	//------------------
	oTempTable:Create()

	//------------------------------------
	//Executa query para leitura da tabela
	//----------------s--------------------

	cQuery := " SELECT A.*, A.R_E_C_N_O_ RECZV2 FROM " + RetSqlName("ZV2") + " A"
	cQuery += " WHERE D_E_L_E_T_ =' ' AND ZV2_DTREC = ' ' "

	// MPSysOpenQuery( cQuery, 'QRYTMP', aSetField )
	MPSysOpenQuery( cQuery, 'QRYTMP' )

	While QRYTMP->(!eof())
		Reclock(cAlias,.T.)
		For nI := 1 to (cAlias)->(fcount())
			IF FieldName(nI) <> "RECZV2"
				IF GetSx3Cache(FieldName(nI),"X3_CONTEXT") <> "V"
					If GetSx3Cache(FieldName(nI),"X3_TIPO") == "D"
						Replace (cAlias)->(&(FieldName(nI))) with StoD(&("QRYTMP->"+(FieldName(ni))))
					Else
						Replace (cAlias)->(&(FieldName(nI))) with &("QRYTMP->"+(FieldName(ni)))
					Endif
				Else
					Do Case
					Case Alltrim(FieldName(nI)) == "ZV2_NOMCLI"
						Replace (cAlias)->(&(FieldName(nI))) with POSICIONE("SA1",1,xFilial("SA1") + QRYTMP->ZV2_CLIENT + QRYTMP->ZV2_LOJA,"A1_NOME")
					Case Alltrim(FieldName(nI)) == "ZV2_NVANT"
						Replace (cAlias)->(&(FieldName(nI))) with POSICIONE("SA3",1,xFilial("SA3") + QRYTMP->ZV2_VANT,"A3_NOME")
					Case Alltrim(FieldName(nI)) == "ZV2_NVPAD"
						Replace (cAlias)->(&(FieldName(nI))) with POSICIONE("SA3",1,xFilial("SA3") + QRYTMP->ZV2_VPAD,"A3_NOME")
					EndCase

				Endif
			Else
				Replace (cAlias)->(&(FieldName(nI))) with &("QRYTMP->"+(FieldName(ni)))
			Endif
		Next nI
		(cAlias)->(MsUnlock())
		QRYTMP->(dbskip())
	Enddo

	QRYTMP->(dbCloseArea())
Return

Static Function MenuDef()
	Local aRotina := {}
	Local cUsers := SuperGetMv("MV_HVP0501",,"000000")

	IF RetCodUsr() $ cUsers
		ADD OPTION aRotina TITLE "Alt. Vend" ACTION "U_HVP0501B()"	OPERATION MODEL_OPERATION_UPDATE ACCESS 0
	Else
		MsgInfo("Usuário sem permissão para alterações. Rotina ocultará o menu. Verifique o parâmetro MV_HVP0501!")
	Endif

Return aRotina

User Function HVP0501B()

	Local aPergs := {}
	Local aRet 		:= {}
	Local cVend 	:= Space(TamSX3("A3_COD")[1])
	Private aItEnr := {}

	aAdd( aPergs ,{1,"Novo Vendedor:  ",cVend,"@!",'.T.',"SA3",'.T.',80,.T.})

	If ParamBox(aPergs ,"Parametros ",aRet)
		MsAguarde({|| U_ProcVend(aRet)},"Ajustando clientes ... ",SM0->M0_FILIAL)
	Endif

Return

User Function ProcVend(aRet)

	Local cCorpo := " "
	Local cMark  := oMark:Mark()

	cCorpo += " <!DOCTYPE html>
	cCorpo += " <html lang='pt-br'>
	cCorpo += " 	<head>
	cCorpo += " 		<title>Clientes alterados</title>
	cCorpo += " 		<meta charset='utf-8'>
	cCorpo += " 	</head>
	cCorpo += " 	<body>

	Do CASE
	Case Time() < "12:00"
		cCorpo += '  Bom dia,'
	Case Time() < "18:00" .AND. Time() > "12:00"
		cCorpo += '  Boa Tarde,'
	Case Time() > "18:00"
		cCorpo += '  Boa Noite,'
	EndCase

	cCorpo += "<br><br>"
	cCorpo += " Os seguintes clientes foram alterados :"
	cCorpo += "<br><br>"

	cCorpo += '<table class="minimalistBlack" style="border-collapse: collapse; width: 100%; height: 90px;" border="1" >'
	cCorpo += '<tbody>'
	cCorpo += '<tr style="height: 14px;  background-color: #000080; ">'
	cCorpo += '		<td style="width: 40%; height: 16px; text-align: center;color: #FFFFFF"><strong>Cliente</strong></td>'
	cCorpo += '		<td style="width: 30%; height: 16px; text-align: center;color: #FFFFFF"><strong>Vend. Anterior</strong></td>'
	cCorpo += '		<td style="width: 30%; height: 16px; text-align: center;color: #FFFFFF"><strong>Vend. Novo</strong></td>'
	cCorpo += '</tr>'

	(cAlias)->(DbGoTop())
	DbSelectArea("ZV2")
	DbSelectARea("SA1")
	While !(cAlias)->(Eof())
		IF (cAlias)->ZV2_OK == cMark
			// ZV2->(DbGoTo((cAlias)->(Recno())))
			ZV2->(DbGoTo((cAlias)->RECZV2))
			RecLock("ZV2",.F.)
			Replace ZV2->ZV2_DTREC with dDataBase
			Replace ZV2->ZV2_VNOVO with aRet[1]
			Replace ZV2->ZV2_USER  with RetCodUsr()
			Replace ZV2->ZV2_EML1  with UsrRetMail(RetCodUsr())
			ZV2->(MsUnlock())

			//Altera o cliente para o novo vendedor
			SA1->(MsSeek(xFilial("SA1") + ZV2->ZV2_CLIENT + ZV2->ZV2_LOJA))
			RecLock("SA1",.F.)
			SA1->A1_VEND := aRet[1]
			SA1->(MsUnlock())

			cCorpo += '<tr style="height: 12px; background-color: #DCDCDC">
			cCorpo += '		<td style="width: 40%; height: 14px; text-align: left;">' + ZV2->ZV2_CLIENT + " - " + Alltrim(SA1->A1_NOME) + '</td>'
			DbSelectArea("SA3")
			SA3->(DbSetOrder(1))
			SA3->(MsSeek(xFilial("SA3") + ZV2->ZV2_VANT ))

			cCorpo += '		<td style="width: 30%; height: 14px; text-align: left;">' + SA3->A3_COD + " - " + Alltrim(SA3->A3_NOME) + '</td>'
			
			DbSelectArea("SA3")
			SA3->(DbSetOrder(1))
			SA3->(MsSeek(xFilial("SA3") + aRet[1] ))

			cCorpo += '		<td style="width: 30%; height: 14px; text-align: left;">' + SA3->A3_COD + " - " + Alltrim(SA3->A3_NOME) + '</td>'
			cCorpo += '</tr>'
		EndIf
		(cAlias)->(DbSkip())
	EndDo

	cCorpo += '	</tbody>'
	cCorpo += '	</table>'
	cCorpo += " 	</body>
	cCorpo += " </html>

	cEmailTo := UsrRetMail(RetCodUsr())

	//Disparar e-mail com as alterações
	MsAguarde({|| U_MailVend(cEmailTo,"Mudança de Carteira - " + ALLTRIM(SM0->M0_FILIAL),cCorpo,"")},"Enviando e-mail para "+cEmailTo+" ... ",SM0->M0_FILIAL)

	oTempTable:Delete()

	MsgRun("Carregando dados...","Aguarde",{|| U_CarregaDados() })

Return

User Function MailVend(cEmailTo,cAssunto,cCorpo,cAnexo)

	Sleep(500)
	u_ENVMAIL(cEmailTo,cAssunto,cCorpo,cAnexo)

Return
