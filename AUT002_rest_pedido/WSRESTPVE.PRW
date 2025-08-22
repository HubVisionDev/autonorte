#Include "TOTVS.CH"
#Include "RESTFUL.CH"
#Include "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} WSRESTPVE
Função WSRESTPVE
@param Recebe parâmetros
@return Confirmação
@author Totvs Nordeste
@owner Totvs S/A
@version Protheus 10, Protheus 11 e V12
@since 25/08/2017
@sample
// WSRESTPVE - Web Service (REST) para cadastrar pedido de venda
Return
@obs Rotina de cadastro de pedido de venda
@project
@history
25/08/2017 - Desenvolvimento da Rotina.
/*/

WSRestFul VENDA Description "Pedido Venda"
	WSMethod POST   Description "Inclusão do Pedido Venda" WSSYNTAX  "/VENDA/{id}"
	WSMethod PUT    Description "Alteração do Pedido Venda" WSSYNTAX "/VENDA/{id}"
	WSMethod DELETE Description "Exclusão do Pedido Venda" WSSYNTAX  "/VENDA/{id}"

	WsData RECEIVE as String

End WSRestFul

/*========================================
--  Função: Incluir pedido de venda     --
==========================================*/
WSMethod POST WSReceive RECEIVE WSService VENDA

	Local cJSON      := Self:GetContent()   // Pega a string do JSON
	Local aRetorno := {}
	Local nId

	Private oParseJSON := Nil

	conout("Thread "+cValToChar(ThreadID())+" -- >"+"Inicio " + time())

	::SetContentType("application/json")
	
	// ---- Deserializa a string JSON
	// FWJsonDeserialize(cJson, @oParseJSON)
	oParseJSON := JsonObject():New()
	oParseJSON:FromJson(cJson)	
 	
 

	//conout("Thread "+cValToChar(ThreadID())+" -- >"+"Chamada MsExecAuto " + time())

	aRetorno := U_PROCPED(oParseJSON,3)
	
	//conout("Thread "+cValToChar(ThreadID())+" -- >"+"Fim Chamada MsExecAuto " + time())
	
	::SetResponse('[')

	For nId := 1 To Len(aRetorno[2])
		::SetResponse(aRetorno[2][nId][01])

		If nId < Len(aRetorno[2])
			::SetResponse(',')
		EndIf
	Next

	::SetResponse(']')
	
	conout("Thread "+cValToChar(ThreadID())+" -- >"+"FIM " + time())
	
Return aRetorno[1]

WSMethod PUT WSReceive RECEIVE WSService VENDA

	Local cJSON      := Self:GetContent()   // Pega a string do JSON
	Local oParseJSON := Nil
	Local aRetorno := {}
	Local nId

	::SetContentType("application/json")

	// ---- Deserializa a string JSON
	// FWJsonDeserialize(cJson, @oParseJSON)
	oParseJSON := JsonObject():New()
	oParseJSON:FromJson(cJson)	

	aRetorno := U_PROCPED(oParseJSON,4)

	::SetResponse('[')

	For nId := 1 To Len(aRetorno[2])
		::SetResponse(aRetorno[2][nId][01])

		If nId < Len(aRetorno[2])
			::SetResponse(',')
		EndIf
	Next

	::SetResponse(']')

Return aRetorno[1]

WSMethod DELETE WSReceive RECEIVE WSService VENDA

	Local cJSON      := Self:GetContent()   // Pega a string do JSON
	Local oParseJSON := Nil
	Local aRetorno := {}
	Local nId

	::SetContentType("application/json")

	// ---- Deserializa a string JSON
	// FWJsonDeserialize(cJson, @oParseJSON)
	oParseJSON := JsonObject():New()
	oParseJSON:FromJson(cJson)	

	aRetorno := U_PROCPED(oParseJSON,5)

	::SetResponse('[')

	For nId := 1 To Len(aRetorno[2])
		::SetResponse(aRetorno[2][nId][01])

		If nId < Len(aRetorno[2])
			::SetResponse(',')
		EndIf
	Next

	::SetResponse(']')

Return aRetorno[1]

User Function PROCPED(oJson,nOpcao)

	Local lRet       := .T.
	Local aItem      := {}
	Local aMensag    := {}                  // Array com mensagem de retorno
	Local cJsonRet   := ""
	Local cErro      := ""
	Local lItem      := .T.
	Local aRetorno	 := {}
	Local cTes		 := ""
	Local cOper		 := ""
	Local cTipo		 := ""
	Local cCliente	 := ""
	Local cLoja		 := ""
	Local cOriPrd	 := ""//origem do produto (B1_ORIGEM)
	Local cXfilCD	 := CriaVar("C6_XFILCD",.F.)
	//Local cNumSC5    := ""
	Local nX
	//Condição Pra depois
	Local cCondDep := AllTrim(SuperGetMv("MV_XPRADEP",.F.,"41"))
	Local cToken	 := ""
	Local nId        		:= 0

	Private nId1       := 0
	Private aRegSC5    := {}                  // Array para ExecAuto do MATA410 (Cabeçalho)
	Private aRegSC6    := {}                  // Array para ExecAuto do MATA410 (Itens)
	Private aZ26	   := {}			      // Array para gravação da Z26 (log conversão produto)

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.
	
	Private nIdJ		   := 0
	Private oParseJSON	   := oJson

	//conout("Thread "+cValToChar(ThreadID())+" -- >"+"Lendo Pedido " + time())

	For nId := 1 to Len(oParseJSON:PEDIDO)

		//Limpa todas as variáveis
		lRet       := .T.
		nId1       := 0
		aRegSC5    := {}                  // Array para ExecAuto do MATA410 (Cabeçalho)
		aRegSC6    := {}                  // Array para ExecAuto do MATA410 (Itens)
		aItem      := {}
		aMensag    := {}                  // Array com mensagem de retorno
		cJsonRet   := ""
		cErro      := ""
		lItem      := .T.

		If Alltrim(oParseJSON:PEDIDO[nId]:C5_XPEDORI) $ 'KKI/B2B/B2C'
			aRetPed := PedidoDupl(oParseJSON:PEDIDO[nId]:C5_XIDPED)
			If aRetPed[1][1] > 0
				aAdd(aMensag, {'{"Retorno":"103","Mensagem":"Pedido de Venda ja incluido no Protheus","Pedido":"' + aRetPed[1][2] + '"}'})
				Loop
			EndIf
		EndIf

		//italo maciel - 07/02/2025
		//incluir pagamento do mercado pago no protheus
		If Alltrim(oParseJSON:PEDIDO[nId]:C5_XPEDORI) == 'B2C'
			If PgtDuplB2C(oParseJSON:PEDIDO[nId]:Z39_ENDID)
				conout("ID "+oParseJSON:PEDIDO[nId]:Z39_ENDID+" já existe.")
			Else
				dbSelectArea("Z66")
				Reclock("Z66", .T.)
				Replace Z66_FILIAL with oParseJSON:PEDIDO[nId]:Z39_FILIAL
				Replace Z66_DATAPG with CTOD(oParseJSON:PEDIDO[nId]:Z39_DATAPG)
				Replace Z66_CGCPG  with oParseJSON:PEDIDO[nId]:Z39_CGC
				Replace Z66_HRPG   with SubStr(oParseJSON:PEDIDO[nId]:Z39_HORAPG,1,5)
				Replace Z66_VALOR  with Val(oParseJSON:PEDIDO[nId]:Z39_VALOR)
				Replace Z66_IDMP   with oParseJSON:PEDIDO[nId]:Z39_ENDID
				Z66->(MsUnlock())
			EndIf
		EndIf

		cTipo := oParseJSON:PEDIDO[nId]:C5_TIPO

		cFilPed := oParseJSON:PEDIDO[nId]:C5_FILIAL
		cEmpAnt := "01"
		cFilAnt := cFilPed
		//conout("OpenFile - Antes - " + cFilAnt)
		//conout("OpenFile - Antes - " + xFilial("SC5"))
		//Atualiza empresa logada
		OpenFile(cEmpAnt + cFilAnt)
		//conout("OpenFile - Depois - " + cFilAnt)
		//conout("OpenFile - Depois - " + xFilial("SC5"))
		If cTipo == "D"
			dbSelectArea("SA2")
			SA2->(dbSetOrder(1))

			If ! SA2->(dbSeek(xFilial("SA2") + PadR(oParseJSON:PEDIDO[nId]:C5_CLIENTE,TamSX3("A2_COD")[1]) + PadR(oParseJSON:PEDIDO[nId]:C5_LOJA,TamSX3("A2_LOJA")[1])))
				aAdd(aMensag, {'{"Retorno":"200","Mensagem":"Fornecedor '+PadR(oParseJSON:PEDIDO[nId]:C5_CLIENTE,TamSX3("A2_COD")[1]) + PadR(oParseJSON:PEDIDO[nId]:C5_LOJA,TamSX3("A2_LOJA")[1])+' nao cadastrado"}'})
				Loop
			Else
				cTipoCli := ""
				cCliente := SA2->A2_COD
				cLoja	 := SA2->A2_LOJA
			EndIf
		Else
			// ---- Pegar dados do cliente
			dbSelectArea("SA1")
			SA1->(dbSetOrder(1))

			If ! SA1->(dbSeek(xFilial("SA1") + PadR(oParseJSON:PEDIDO[nId]:C5_CLIENTE,TamSX3("A1_COD")[1]) + PadR(oParseJSON:PEDIDO[nId]:C5_LOJA,TamSX3("A1_LOJA")[1])))
				aAdd(aMensag, {'{"Retorno":"200","Mensagem":"Cliente '+PadR(oParseJSON:PEDIDO[nId]:C5_CLIENTE,TamSX3("A1_COD")[1]) + PadR(oParseJSON:PEDIDO[nId]:C5_LOJA,TamSX3("A1_LOJA")[1])+' nao cadastrado"}'})
				Loop
			Else
				cTipoCli := SA1->A1_TIPO
				cCliente := SA1->A1_COD
				cLoja	 := SA1->A1_LOJA
			EndIf
		Endif
   
		lItem   := .T.
		aItem   := {}
		aRegSC6 := {}
		nTotBrut := 0
		nTotLiq  := 0
		nTotDesc := 0

		//Item do Pedido
		_cItem := "00"

		For nId1 := 1 To Len(oParseJSON:PEDIDO[nId]:ITENS)
			//Italo Maciel 15/04/21
			//Verifica saldo dos produtos
			cCod := PadR(oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_PRODUTO,TamSX3("B1_COD")[1])
			nQtd := Val(oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_QTDVEN)
			nSaldo := fExistSaldo(cCod,cFilAnt)
	
			// ---- Verificar se produto existe
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))

			cOrigem := oParseJSON:PEDIDO[nId]:C5_XPEDORI
			cMestre := oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_PRODUTO
			nQtd    := Val(oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_QTDVEN)

			If Type("oParseJSON:PEDIDO[nId]:ITENS[nId1]:B1_ORIGEM") <> "U"
				cOriPrd := oParseJSON:PEDIDO[nId]:ITENS[nId1]:B1_ORIGEM
			EndIf
			// ----- Montar itens do Pedido de Venda
			If oParseJSON:PEDIDO[nId]:C5_FILIAL == '020141'
				cXfilCD := oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_FILIAL
				//Conout("C6_FILIAL - " + cXfilCD)
			EndIf
			
			aProd := GetProd(cMestre,nQtd,cOriPrd)

			//Gustavo Costa 07/04/2025
			//Se for ANL Diesel, e o produto nao tiver saldo, inclui do mesmo jeito
			If cFilAnt $ "020141" .AND. Len(aProd) = 0
				AADD(aProd,{cMestre, nQtd})
			EndIf

			//italo maciel 20/09/23
			//Gravar tag xped
			cxPed := ""
			cItemPed := ""
			If At("xped", LOWER(oParseJSON:PEDIDO[nId]:C5_XOBS)) > 0
				//Converte OBS para minusculo
				cxPed := LOWER(oParseJSON:PEDIDO[nId]:C5_XOBS)
				//Recupera numero do pedido dentro da obs
				cxPed := SubStr(cxPed, At("xped", cxPed)+5, At(" ", cxPed, At("xped", cxPed)+5) - (At("xped", cxPed)+5) )
			EndIf
			
			For nX := 1 to Len(aProd)
				
				If ! SB1->(dbSeek(xFilial("SB1") + aProd[nX][1] ))
					cStatus  := "A"

					aAdd(aMensag, {'{"Retorno":"200","Mensagem":"Produto '+aProd[nX][1]+' nao cadastrado."}'})

					lItem := .F.

					loop
				EndIf

				If nOpcao <> 5
					cOper := oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_XOPER
					cTes := MaTesInt( 2 , cOper, cCLiente, cLoja, iif(cTipo == 'D','F',"C"), SB1->B1_COD, nil)

					IF Empty(cTes)
						aAdd(aMensag, {'{"Retorno":"200","Mensagem":"TES Inteligente nao cadastrado para a operacao '+cOper+' - Produto '+SB1->B1_COD+'"}'})
						lItem := .F.
						Loop
					Endif
				Endif

				cPrUnit := StrTran(oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_PRUNIT,",",".")
				
				nValDesc := Round(Val(cPrUnit) * aProd[nX][2],2) - ;
				Round(Val(oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_PRCVEN)*aProd[nX][2],2)

				nPDesc := Round((nValDesc / Round(Val(cPrUnit) * aProd[nX][2],2)) * 100,2)

				_cItem := Soma1(_cItem)

				//italo maciel 20/09/23
				//Gravar tag xped
				If !Empty(cxPed)
					cItemPed := _cItem
				EndIf
				
				aItem := {;
				{"C6_ITEM"    , _cItem         									   ,nil},;    // Item do pedido
				{"C6_PRODUTO" , SB1->B1_COD                                        ,nil},;    // Produto
				{"C6_DESCRI"  , SB1->B1_DESC							       	   ,nil},;    // Produto
				{"C6_UM"      , SB1->B1_UM                                         ,nil},;    // Unidade de medida do produto
				{"C6_QTDVEN"  , aProd[nX][2]  									   ,nil},;    // Quantidade Vendida
				{"C6_PRUNIT"  , Val(cPrUnit)									   ,nil},;    // Preço de Lista			
				{"C6_QTDLIB"  , aProd[nX][2]									   ,nil},;    // Quantidade Liberada						
				{"C6_PRCVEN"  , Val(oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_PRCVEN)  ,nil},;    // Preço de Lista			
				{"C6_XLETRA"  , oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_XLETRA       ,nil},;    // Letra Comissao
				{"C6_LOCAL"   , oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_LOCAL        ,nil},;    // Local padrão do produto (Armazem)
				{"C6_CC"      , oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_CC           ,nil},;    // Centro de Custo
				{"AUTDELETA"  , "N"                                                ,nil},;     // Deleta registro "S" ou "N"
				{"C6_OPER"    , cOper 										       ,nil},;   // Operação (Ativar TES Inteligente)		
				{"C6_XDESCON" , nPDesc										       ,nil},; 
				{"C6_XVALDES" , nValDesc									       ,nil},;
				{"C6_NUMPCOM" , cxPed	 									       ,nil},;
				{"C6_ITEMPC"  , cItemPed										   ,nil},;
				{"C6_XFILCD"  , cXfilCD											   ,nil},;
				{"C6_TES"     , cTes 										       ,nil}}    // TES

				/*
				"C6_XUSRDES": "HUMBERTO LINO", -Campo novo
          		"C6_XPERDGE": "5.01" - Campo novo
				*/
				
				// IF oParseJSON["PEDIDO"][nId]["ITENS"][nId1]:hasProperty("C6_XUSRDES")
				IF oParseJSON:PEDIDO[nId]:ITENS[nId1]:hasProperty("C6_XUSRDES")
					aAdd(aItem,{"C6_XUSRDES",oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_XUSRDES,Nil})
				Endif

				// IF oParseJSON["PEDIDO"][nId]["ITENS"][nId1]:hasProperty("C6_XPERDGE")
				IF oParseJSON:PEDIDO[nId]:ITENS[nId1]:hasProperty("C6_XPERDGE")
					aAdd(aItem,{"C6_XPERDGE",Val(oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_XPERDGE),Nil})
				Endif
				
				nTotLiq   += Round(Val(oParseJSON:PEDIDO[nId]:ITENS[nId1]:C6_PRCVEN)*aProd[nX][2],2)
				nTotDesc  += nValDesc
				nTotBrut  := nTotDesc + nTotLiq
				
				aAdd(aRegSC6, aItem)
			Next nX
		Next nId1

		If SA1->A1_XCOBDSP == '1'
			nTotBrut += Val(oParseJSON:PEDIDO[nId]:C5_FRETE) + GETMV("MV_XDESPAC")
			nTotLiq  += Val(oParseJSON:PEDIDO[nId]:C5_FRETE) + GETMV("MV_XDESPAC")
		Else
			nTotBrut += Val(oParseJSON:PEDIDO[nId]:C5_FRETE)
			nTotLiq  += Val(oParseJSON:PEDIDO[nId]:C5_FRETE)
		EndIf	

		If !Empty(aRegSC6)
			nIdJ := nId //atribui para uma variavel private para poder usar o "type"
			If SA1->A1_XDEPOIS == 'S' .and.;
				(((Type("oParseJSON:PEDIDO[nIdJ]:Z39_TXID") <> "U" .and. Empty(oParseJSON:PEDIDO[nIdJ]:Z39_TXID)) .and.;
				(Type("oParseJSON:PEDIDO[nIdJ]:Z40_NSU")  <> "U" .and. Empty(oParseJSON:PEDIDO[nIdJ]:Z40_NSU))) .or.;
				(Type("oParseJSON:PEDIDO[nIdJ]:Z39_TXID") == "U" .and. Type("oParseJSON:PEDIDO[nIdJ]:Z40_NSU") == "U" ))

				cCondPed := cCondDep
			Else
				cCondPed := oParseJSON:PEDIDO[nId]:C5_CONDPAG
			EndIf

			//conout("Thread "+cValToChar(ThreadID())+" -- >"+"Filial " + xFilial("SC5"))
			//conout("Thread "+cValToChar(ThreadID())+" -- >"+"Cliente " + SA1->A1_COD + SA1->A1_NOME)
			//conout("Thread - oParseJSON:PEDIDO[nId]:C5_FILIAL  " + oParseJSON:PEDIDO[nId]:C5_FILIAL )
			//conout("Thread - cFilAnt " + cFilAnt)
			//conout("Thread - xFilial() " + xFilial("SC5"))
		
			If Type("oParseJSON:PEDIDO[nIdj]:C5_XTOKEN") <> "U"
				cToken	:= oParseJSON:PEDIDO[nId]:C5_XTOKEN
			EndIf

			aRegSC5 := {;
			{"C5_FILIAL"  , xFilial("SC5")                         , Nil},;     // Filial do pedido
			{"C5_TIPO"    , oParseJSON:PEDIDO[nId]:C5_TIPO         , Nil},;     // Tipo do pedido
			{"C5_CLIENTE" , SA1->A1_COD     					   , Nil},;     // Cliete
			{"C5_LOJA"    , SA1->A1_LOJA         				   , Nil},;     // Loja
			{"C5_EMISSAO" , CToD(oParseJSON:PEDIDO[nId]:C5_EMISSAO), Nil},;  // Data de Emissão
			{"C5_CLIENT"  , SA1->A1_COD      					   , Nil},;     // Código do cliente entrega
			{"C5_LOJAENT" , SA1->A1_LOJA         				   , Nil},;     // Loja do cliente entrega
			{"C5_CONDPAG" , cCondPed					       	   , Nil},;     // Condição de Pagamento
			{"C5_TPFRETE" , oParseJSON:PEDIDO[nId]:C5_TPFRETE      , Nil},;     // Tipo do frete
			{"C5_TRANSP"  , oParseJSON:PEDIDO[nId]:C5_TRANSP       , Nil},;
			{"C5_FRETE"   , Val(oParseJSON:PEDIDO[nId]:C5_FRETE)   , Nil},;
			{"C5_MENNOTA" , If(Alltrim(oParseJSON:PEDIDO[nId]:C5_MENNOTA)=="null","",Alltrim(oParseJSON:PEDIDO[nId]:C5_MENNOTA)), Nil},;
			{"C5_VEND1"   , oParseJSON:PEDIDO[nId]:C5_VEND1        , Nil},;
			{"C5_VEND2"   , oParseJSON:PEDIDO[nId]:C5_VEND2        , Nil},;
			{"C5_VEND3"   , oParseJSON:PEDIDO[nId]:C5_VEND3        , Nil},;
			{"C5_VEND4"   , oParseJSON:PEDIDO[nId]:C5_VEND4        , Nil},;
			{"C5_VEND5"   , oParseJSON:PEDIDO[nId]:C5_VEND5        , Nil},;
			{"C5_NATUREZ" , oParseJSON:PEDIDO[nId]:C5_NATUREZ      , Nil},;
			{"C5_TIPLIB"  , "1"                                    , Nil},;      // Permitir liberar o pedido parcialmente
			{"C5_LIBEROK" , "S"                                    , Nil},;
			{"C5_XIMPORT" , "VOL"                                  , Nil},;      // Origem do pedido de venda
			{"C5_XTELVEN" , oParseJSON:PEDIDO[nId]:C5_XTELVEN      , Nil},;      // TELEVENDA: S = Sim / N = Não
			{"C5_XVENCLI" , SA1->A1_XVEND                          , Nil},;
			{"C5_XTOTBRU" , nTotBrut                          	   , Nil},;		//Total Bruto
			{"C5_XTOTLIQ" , nTotLiq                          	   , Nil},;
			{"C5_XOBS"    , If(Alltrim(oParseJSON:PEDIDO[nId]:C5_XOBS)=="null","",Alltrim(oParseJSON:PEDIDO[nId]:C5_XOBS)), Nil},;
			{"C5_XPEDORI" , oParseJSON:PEDIDO[nId]:C5_XPEDORI      , Nil},;
			{"C5_XIDPED " , oParseJSON:PEDIDO[nId]:C5_XIDPED  	   , Nil},;
			{"C5_XTOKEN " , cToken  	   						   , Nil},;
			{"C5_XPGTONL" , If(Type("oParseJSON:PEDIDO[nIdj]:C5_XPGTONL")<>"U",oParseJSON:PEDIDO[nIdj]:C5_XPGTONL,""), Nil},;
			{"C5_XTDESIT" , U_TDESCIT(aRegSC6)		               , Nil}}

		EndIf

		lMsErroAuto := .F.

		If !Empty(aRegSC6)

			//Italo Maciel - 16/03/2023
			//se a condição for para funcionário, valida se o cliente tbm é
			dbSelectArea("SE4")
			SE4->(dbSetOrder(1))
			If SE4->(dbSeek(xFilial("SE4") + cCondPed))
				If "FUNCIONARIO" $ SE4->E4_DESCRI
					dbSelectArea("SRA")
					SRA->(dbSetOrder(20))//RA_CIC+RA_FILIAL+RA_MAT
					If SA1->A1_PESSOA == 'J' .OR. !SRA->(dbSeek(Alltrim(SA1->A1_CGC)))
						aAdd(aMensag, {'{"Retorno":"200" ,"Mensagem":"Pedido Nao Enviado -> A Condicao de Pgto '+cCondPed+' deve ser usada apenas para FUNCIONARIOS. Altere a Condicao no pedido antes de enviar."}'})

						aAdd(aRetorno,lRet)
						aAdd(aRetorno,aMensag)
					
						Return(aRetorno)
					EndIf
				EndIf
			EndIf
			
			//conout("Thread "+cValToChar(ThreadID())+" -- > PEDIDO KKI "+oParseJSON:PEDIDO[nId]:C5_XIDPED+" - Execução MsExecAuto " + time())
			
			If !SA1->(DBRLock(SA1->(Recno())))
				aAdd(aMensag, {'{"Retorno":"200" ,"Mensagem":"Pedido Nao Enviado -> O cadastro do cliente: '+SA1->A1_COD+' - '+SA1->A1_NOME+' esta em uso e o pedido nao pode ser enviado. Favor solicitar ao setor Financeiro que libere o cadastro e apos liberacao, envie o pedido novamente."}'})

				aAdd(aRetorno,lRet)
				aAdd(aRetorno,aMensag)
			
				Return(aRetorno)
			Else
				SA1->(DBRUnlock(SA1->(Recno())))
			EndIf
			//conout("MSExecAuto - Antes - cFilAnt " + cFilAnt)
			//conout("MSExecAuto - Antes - " + xFilial("SC5"))
			MSExecAuto({|x,y,z| Mata410(x,y,z)},aRegSC5,aRegSC6,nOpcao)
			//conout("MSExecAuto - Depois - " + xFilial("SC5"))
			//Destrava último pedido incluído
			SC5->(DBRUnlock())
			SC6->(DBRUnlock())
			SB2->(DBRUnlock())
			SA1->(DBRUnlock())

			//conout("Thread "+cValToChar(ThreadID())+" -- > PEDIDO KKI "+oParseJSON:PEDIDO[nId]:C5_XIDPED+" - Fim MsExecAuto " + time())
			
			If lMsErroAuto
				aAutoErro := GETAUTOGRLOG()
				cErro     := TrataErro(aAutoErro)   // Pegar o motivo do erro do execauto
				aAdd(aMensag, {'{"Retorno":"200" ,"Mensagem":"'+cErro+'"}'})
			else
				ConfirmSX8()

				// Cesar: Gravar o status do pedido...					
				U_fAtuZ25(SC5->C5_FILIAL, SC5->C5_NUM, SC5->C5_XIDPED, 'AP')

				//Italo Maciel - 24/01/2022 - Gravar tabela do pedido original
				GrvLogPed(oParseJSON:PEDIDO[nId]:ITENS)
				//Italo Maciel - 24/01/2022 - Gravar tabela de conversão do produto
				If !Empty(aZ26)
					GrvLogPrd(aZ26)
				EndIf

				//ITALO MACIEL 15/06/2023 - gravar dados de pagamento pix
				nIdJ := nId //atribui para uma variavel private para poder usar o "type"
				If Type("oParseJSON:PEDIDO[nIdJ]:Z39_TXID") <> "U" .and. !Empty(oParseJSON:PEDIDO[nIdJ]:Z39_TXID)
					Reclock("SC5",.F.)
					Replace C5_XPGTONL with "1"
					Replace C5_DESPESA with 0
					SC5->(MsUnlock())

					GravaZ39(oParseJSON)

					BxPgtOn()
				EndIf
				//ITALO MACIEL 06/07/2023 - gravar dados de pagamento cartão
				If Type("oParseJSON:PEDIDO[nIdJ]:Z40_NSU") <> "U" .and. !Empty(oParseJSON:PEDIDO[nIdJ]:Z40_NSU)
					Reclock("SC5",.F.)
					Replace C5_XPGTONL with "2"
					Replace C5_DESPESA with 0
					SC5->(MsUnlock())

					GravaZZA(oParseJSON)
				EndIf

				//italo maciel - 07/02/2025
				//Grava numero do pedido na Z66
				If Alltrim(oParseJSON:PEDIDO[nId]:C5_XPEDORI) == 'B2C'
					Reclock("SC5",.F.)
					//Replace C5_XPGTONL with "3"
					Replace C5_DESPESA with 0
					SC5->(MsUnlock())

					dbSelectArea("Z66")
					Z66->(dbSetOrder(1))
					If Z66->(dbSeek(xFilial("Z66")+oParseJSON:PEDIDO[nId]:Z39_ENDID))
						Reclock("Z66",.F.)
						Replace Z66_RECPED with SC5->(RECNO())
						Z66->(MsUnlock())
					EndIf
				EndIf

				aAdd(aMensag, {'{"Retorno":"100","Mensagem":"Pedido de Venda gravado com sucesso","Pedido":"' + SC5->C5_NUM + '"}'})
			EndIf

		Else
			aAdd(aMensag, {'{"Retorno":"200" ,"Mensagem":"Pedido Nao Enviado -> O Pedido nao possui nenhum produto com saldo para faturar."}'})
		EndIf
	Next

	aAdd(aRetorno,lRet)
	aAdd(aRetorno,aMensag)
 
Return(aRetorno)

// Italo Maciel 19/06/2023
// Baixa os titulos com pagamento online
Static Function BxPgtOn()
	Local aAreaSE1 := SE1->(GetArea())
	Local aBaixa := {}
	Local nVlrPgt := 0
	Local cPrfRA := "PIX"
	Local aConta := {;
		{"02","001","3433","111266"},;
		{"03","001","3433","7194"};
		}

	//conout("Thread "+cValToChar(ThreadID())+" -- > PEDIDO KKI "+Alltrim(SC5->C5_XIDPED)+" - Gerando RA " + time())

	dbSelectArea("Z39")
	Z39->(dbSetOrder(1))
	If Z39->(dbSeek(xFilial("Z39") + SC5->C5_NUM))
		nVlrPgt := Z39->Z39_VALOR
	Else
		FWAlertError("Pagamento não localizado para o Pedido "+SC5->C5_NUM+" na Filial "+xFilial("Z39")+". Procure o administrador do sistema.","Atenção")
		Return
	EndIf

	nPosCta := aScan(aConta,{|x| x[1] == SubStr(xFilial("SE1"),1,2) })

	aBaixa := {}
	lMsErroAuto := .F.

	//Gera RA
	aArray := { { "E1_PREFIXO"  , cPrfRA       , NIL },;
		{ "E1_NUM"      , SC5->C5_NUM       , NIL },;
		{ "E1_TIPO"     , "RA"              , NIL },;
		{ "E1_NATUREZ"  , "1101099"         , NIL },;
		{ "E1_CLIENTE"  , SC5->C5_CLIENTE   , NIL },;
		{ "E1_LOJA"     , SC5->C5_LOJACLI   , NIL },;
		{ "E1_EMISSAO"  , dDataBase			, NIL },;
		{ "E1_VENCTO"   , dDataBase			, NIL },;
		{ "E1_VENCREA"  , DataValida(dDataBase,.t.), NIL },;
		{ "CBCOAUTO"    , aConta[nPosCta][2], NIL },;
		{ "CAGEAUTO"    , aConta[nPosCta][3], NIL },;
		{ "CCTAAUTO"    , aConta[nPosCta][4], NIL },;
		{ "E1_HIST"     , "Adt. PIX Ref. Pedido "+Alltrim(SC5->C5_NUM), NIL },;
		{ "E1_VALOR"    , nVlrPgt           , NIL }}

	MsExecAuto( { |x,y| FINA040(x,y)} , aArray, 3)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão

	If lMsErroAuto
		aAutoErro := GETAUTOGRLOG()
		cErro     := TrataErro(aAutoErro)   // Pegar o motivo do erro do execauto

		//conout("Thread "+cValToChar(ThreadID())+" -- > PEDIDO KKI "+cErro)

		Reclock("Z39",.F.)
		Replace Z39_INFOPG with SubStr(cErro, 1, 254)
		Z39->(MsUnlock())
	Else

		//Atualiza campo de origem KKI
		Reclock("SE1",.F.)
		Replace E1_XORIGEM with "1"
		SE1->(MsUnlock())

		//conout("Thread "+cValToChar(ThreadID())+" -- > PEDIDO KKI "+Alltrim(SC5->C5_XIDPED)+" - Gerando Amarração RA x Pedido " + time())

		//vincula RA ao Pedido
		dbSelectArea("FIE")
		FIE->(dbSetOrder(1))
		If !FIE->(dbSeek(xFilial("FIE")+"R"+SC5->C5_NUM))
			Reclock("FIE", .T.)
			Replace FIE_FILIAL with xFilial("FIE")
			Replace FIE_CART   with "R"
			Replace FIE_PEDIDO with SC5->C5_NUM
			Replace FIE_PREFIX with cPrfRA
			Replace FIE_NUM    with SC5->C5_NUM
			Replace FIE_VALOR  with nVlrPgt
			Replace FIE_TIPO   with "RA"
			Replace FIE_CLIENT with SC5->C5_CLIENTE
			Replace FIE_LOJA   with SC5->C5_LOJACLI
			Replace FIE_FILORI with xFilial("FIE")
			Replace FIE_SALDO  with nVlrPgt
			FIE->(MsUnlock())
		EndIf

	Endif

	RestArea(aAreaSE1)
Return

Static Function TrataErro(pAutoErro)
	Local cRet     := ""
	Local cTexto   := ""
	Local nX       := 0
	Local nY       := 0
	Local aAcentos := {"ÁA","áa","ÉE","ée","ÓO","óo","ÍI","íi","ÇC","çc","ÃA","ãa","ÕO","õo","ÊE","êe","ÀA","àa"}

	For nX := 1 To Len(pAutoErro)
		cTexto := pAutoErro[nX]

		For nY := 1 To Len(aAcentos)
			cTexto := StrTran(cTexto,Substr(aAcentos[nY],1,1),Substr(aAcentos[nY],2,1))
		Next

		cRet += StrTran(cTexto,Chr(13) + Chr(10)," ")
	Next
Return cRet

//Retorna produtos pelo codigo mestre
Static Function GetProd(cMestre,nQtd,cOrigem)
	Local aProd    := {}
	Local cQuery   := ""
	Local cAlias   := ""
	Local aAreaSB2 := SB2->(GetArea())
	Local nSaldo   := 0
	
	Default cOrigem := ""

	cQuery := " SELECT B1_COD, B1_ORIGEM FROM "+RetSqlName("SB1")
	cQuery += " WHERE D_E_L_E_T_ = ' ' "
	cQuery += " AND B1_XALTIMP = '"+Alltrim(cMestre)+"' "
	cQuery += " AND B1_FILIAL = '"+xFilial("SB1")+"' "
	If cOrigem == '0'
		cQuery += " ORDER BY B1_ORIGEM ASC "
	ElseIf cOrigem == '2'
		cQuery += " ORDER BY B1_ORIGEM DESC "
	EndIf
	
	cQuery := ChangeQuery(cQuery)
	cAlias := MPSysOpenQuery(cQuery)

	dbSelectArea("SB2")
	//conout("GetProd - cFilAnt - " + cFilAnt)
	While !(cAlias)->(EOF()) .and. nQtd > 0

		//italo maciel 02/08/2023
		//Se for filial ES, considera apenas produtos da mesma origem solicitada
		If !Empty(cOrigem)
			If cFilAnt $ "020113/030113"
				If cOrigem <> (cAlias)->B1_ORIGEM
					(cAlias)->(dbSkip())
					Loop
				EndIf
			EndIf
		EndIf

		nSaldo := 0
		SB2->( dbSetOrder(1) )

		If xFilial("SB2") $ '020104#030104'
			If xFilial("SB2") == '020104'
				cxFilial := '020101'
			//primaparts
			ElseIf xFilial("SB2") == '030104'
				cxFilial := '030101'
			EndIf
		ElseIF xFilial("SB2") $ '020171'
			cxFilial := '020113'
		ElseIF xFilial("SB2") $ '020172'
			cxFilial := '020101'
		Else
			cxFilial := xFilial("SB2")
		EndIf
		
		If SB2->( dbSeek(cxFilial + (cAlias)->B1_COD + "01") )
			nSaldo := SaldoSB2()
 
			If cxFilial == '020101'
				If SB2->( dbSeek("020104" + (cAlias)->B1_COD + "01") )
					nSaldo += SaldoSB2()
				EndIf
			Endif
			//primaparts
			If cxFilial == '030101'
				If SB2->( dbSeek("030104" + (cAlias)->B1_COD + "01") )
					nSaldo += SaldoSB2()
				EndIf
			Endif

			If nSaldo >= nQtd
				AADD(aProd,{(cAlias)->B1_COD, nQtd})
				//log conversao
				AADD(aZ26,{ cMestre, (cAlias)->B1_COD, nQtd, nQtd })
				nQtd := 0
			ElseIf nSaldo > 0 .AND. nSaldo < nQtd
				AADD(aProd,{(cAlias)->B1_COD, nSaldo})
				//log conversao
				AADD(aZ26,{ cMestre, (cAlias)->B1_COD, nQtd, nSaldo })
				nQtd -= nSaldo
			ElseIf nSaldo <= 0
				//log conversao
				AADD(aZ26,{ cMestre, (cAlias)->B1_COD, nQtd, 0 })
			EndIf
		EndIf

		(cAlias)->(dbSkip())	
	EndDo

	(cAlias)->(dbCloseArea())
	//conout("GetProd Fim - cFilAnt - " + cFilAnt)

	RestArea(aAreaSB2)
Return aProd

/*/
	GrvLogPed
	Gravação da tabelas Z23 para posterior 
	auditoria dos pedidos enviado pelo B2B/VOL
	@type  Static Function
	@author Italo Maciel
	@since 24/01/2022
	@version 1.0
	@param  
		oCabec = objeto json do cabeçalho do pedido
		oItens = objeto json dos itens do pedido
	@return NIL
/*/
Static Function GrvLogPed(oItens)
	Local nX

	dbSelectArea("Z23")
	Z23->(dbSetOrder(1))
	If !Z23->(dbSeek(xFilial("SC5") + SC5->C5_NUM )) //Z23_FILIAL+Z23_NUM+Z23_PRODUT
		For nX := 1 to Len(oItens)
			
			dbSelectArea("SB1")
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1") + oItens[nX]:C6_PRODUTO))

			Reclock("Z23",.T.)
			Z23_FILIAL := xFilial("SC5")
			Z23_NUM    := SC5->C5_NUM
			Z23_ITEM   := oItens[nX]:C6_ITEM
			Z23_PRODUT := SB1->B1_COD
			Z23_DESPRO := SB1->B1_DESC
			Z23_CC     := oItens[nX]:C6_CC
			Z23_LETRA  := oItens[nX]:C6_XLETRA
			Z23_ENTREG := CToD(oItens[nX]:C6_ENTREG)
			Z23_LOCAL  := oItens[nX]:C6_LOCAL
			Z23_PRCVEN := Val(oItens[nX]:C6_PRCVEN)
			Z23_PRUNIT := Val(StrTran(oItens[nX]:C6_PRUNIT,",","."))
			Z23_QTDLIB := Val(oItens[nX]:C6_QTDVEN)
			Z23_QTDVEN := Val(oItens[nX]:C6_QTDVEN)
			Z23_UM     := SB1->B1_UM
			Z23_VALDES := Val(oItens[nX]:C6_VALDESC)
			Z23_VALOR  := Val(oItens[nX]:C6_VALOR)
			Z23->(MsUnlock())
		Next nX
	EndIf
Return

Static Function PgtDuplB2C(cID)
	Local lRet := .F.

	cQuery := " SELECT COUNT(*) QUANT
	cQuery += " FROM " + RetSqlName("Z66")
	cQuery += " WHERE D_E_L_E_T_ = ' ' "
	cQuery += " AND Z66_IDMP = '"+Alltrim(cID)+"' "

	TCQUERY cQuery NEW ALIAS "QDUPL"

	If QDUPL->QUANT > 0
		lRet := .T.
	EndIf

	QDUPL->(dbCloseArea())

Return lRet

/*/
	GrvLogPrd
	Gravação da tabela Z26 (conversão do código de produto)
	@type  Static Function
	@author Italo Maciel
	@since 24/01/2022
	@version 1.0
	@param 
		aLog = Array com a conversão do código do produto		
	@return NIL
/*/
Static Function GrvLogPrd(aLog)
	Local nX

	dbSelectArea("Z26")
	For nX := 1 to Len(aLog)
		Reclock("Z26",.T.)
		Replace Z26_FILIAL with SC5->C5_FILIAL
		Replace Z26_NUM    with SC5->C5_NUM
		Replace Z26_CODORI with aLog[nX][1]
		Replace Z26_CODPRO with aLog[nX][2]
		Replace Z26_QTDORI with aLog[nX][3]
		Replace Z26_QTDPRO with aLog[nX][4]
		Z26->(MsUnlock())
	Next nX
	
Return

Static Function fExistSaldo(cCod,cFilAnt)
	Local nRet := 0

	cQuery := " SELECT "
	cQuery += " CASE 
	cQuery += " 	WHEN LER_SALDO(B1_COD,'"+cFilAnt+"') IS NULL "
	cQuery += " 	THEN 0 "
	cQuery += " 	ELSE LER_SALDO(B1_COD,'"+cFilAnt+"') "
	cQuery += " END SALDO "
	cQuery += " FROM "+RetSqlName("SB1")+" A "
	cQuery += " WHERE A.D_E_L_E_T_ = ' ' "
	cQuery += " AND B1_COD = '"+cCod+"' "

	TCQUERY cQuery NEW ALIAS "QSALDO"

	nRet := QSALDO->SALDO

	QSALDO->(dbCloseArea())

Return nRet

Static Function PedidoDupl(cPedido)
	Local aRet := {}

	cQuery := " SELECT COUNT(*) QUANT, C5_NUM 
	cQuery += " FROM " + RetSqlName("SC5")
	cQuery += " WHERE D_E_L_E_T_ = ' ' "
	cQuery += " AND C5_XIDPED = '"+Alltrim(cPedido)+"' "
	cQuery += " GROUP BY C5_NUM "

	TCQUERY cQuery NEW ALIAS "QDUPL"

	aadd(aRet,{QDUPL->QUANT, QDUPL->C5_NUM})

	QDUPL->(dbCloseArea())

Return aRet

Static Function GravaZ39(oParseJSON)
	Local nX

	For nX := 1 to Len(oParseJSON:PEDIDO)

		dbSelectArea("Z39")
		RecLock("Z39",.T.)
		
		Replace Z39_PEDIDO	with SC5->C5_NUM
		Replace Z39_FILIAL 	with oParseJSON:PEDIDO[nX]:Z39_FILIAL
		Replace Z39_TXID 	with oParseJSON:PEDIDO[nX]:Z39_TXID
		Replace Z39_ENDID 	with oParseJSON:PEDIDO[nX]:Z39_ENDID
		Replace Z39_CGC 	with oParseJSON:PEDIDO[nX]:Z39_CGC
		Replace Z39_PGADOR 	with oParseJSON:PEDIDO[nX]:Z39_PGADOR
		Replace Z39_DATAPG 	with CToD(oParseJSON:PEDIDO[nX]:Z39_DATAPG)
		Replace Z39_HORAPG 	with oParseJSON:PEDIDO[nX]:Z39_HORAPG
		Replace Z39_VALOR 	with Val(oParseJSON:PEDIDO[nX]:Z39_VALOR)
		Replace Z39_INFOPG 	with oParseJSON:PEDIDO[nX]:Z39_INFOPG

		Z39->(MsUnlock())

	Next nX

Return

Static Function GravaZZA(oParseJSON)
	Local nX := 0
	Local y := 0
	Local x := 0
	Local nTaxa

	Private nXX

	For nX := 1 to Len(oParseJSON:PEDIDO)
		cBand := fBand(Upper(oParseJSON:PEDIDO[nX]:Z40_BANDEIRA), Upper(oParseJSON:PEDIDO[nX]:Z40_TIPOPG))

		DbSelectArea("SAE")
		SAE->(DbSetOrder(1))
		SAE->(MsSeek(xFilial("SAE") + cBand))

		DbSelectArea("MEN")
		MEN->(DbSetOrder(2))
		MEN->(MsSeek(xFilial("MEN") + SAE->AE_COD ))

		nTaxa := SAE->AE_TAXA

		While SAE->AE_COD == MEN->MEN_CODADM
			IF Val(oParseJSON:PEDIDO[nX]:Z40_QTDPARCELAS) >= MEN->MEN_PARINI .and. Val(oParseJSON:PEDIDO[nX]:Z40_QTDPARCELAS) <= MEN->MEN_PARFIN
				nTaxa := MEN->MEN_TAXADM

				Exit
			EndIf

			MEN->(DbSkip())
		EndDo

		dbSelectArea("ZZA")
		RecLock("ZZA",.T.)

		nParcAnt := Val(ZZA->ZZA_PARCEL)

		REPLACE ZZA_FILIAL 	WITH xFilial("ZZA")
		REPLACE ZZA_NSU 	WITH oParseJSON:PEDIDO[nX]:Z40_NSU
		REPLACE ZZA_DTVEND 	WITH CToD(oParseJSON:PEDIDO[nX]:Z40_DATAPG)
		REPLACE ZZA_BAND 	WITH cBand
		REPLACE ZZA_VALOR 	WITH Val(oParseJSON:PEDIDO[nX]:Z40_TOTALPED)
		REPLACE ZZA_TIPO 	WITH fTpCart(Upper(oParseJSON:PEDIDO[nX]:Z40_TIPOPG))//C ou D
		REPLACE ZZA_TAXA 	WITH 0//nTaxa
		REPLACE ZZA_ESTABE 	WITH oParseJSON:PEDIDO[nX]:Z40_CODESTABELECIMENTO
		REPLACE ZZA_PARCEL 	WITH StrZero(Val(oParseJSON:PEDIDO[nX]:Z40_QTDPARCELAS), 3)
		REPLACE ZZA_PEDIDO  WITH SC5->C5_XIDPED
		REPLACE ZZA_JRCART	WITH Val(oParseJSON:PEDIDO[nX]:Z40_JRCART)
		REPLACE ZZA_POS 	WITH SuperGetMV("AN_POSKKI",,"11820440") //FIXO POS VENDA WEB
		REPLACE ZZA_FILVND	WITH oParseJSON:PEDIDO[nX]:C5_FILIAL
		//variavel private para o type
		nXX := nX
		If type("oParseJSON:PEDIDO[nXX]:Z40_ENDID") <> "U"
			REPLACE ZZA_ENDID with oParseJSON:PEDIDO[nX]:Z40_ENDID
		Endif

		ZZA->(MsUnlock())

		nTotalZZA := Val(oParseJSON:PEDIDO[nX]:Z40_TOTALPED)
		nParc := Val(oParseJSON:PEDIDO[nX]:Z40_QTDPARCELAS)

		If empty(nParc)
			nParc := 1 
		Endif

		dEmissa := CToD(oParseJSON:PEDIDO[nX]:C5_EMISSAO)
		dVencto := dEmissa + SAE->AE_DIAS

		//Italo Maciel 28/09/2020
		dEmisFin := dEmissa

		For x := 1 To nParc

			If x > 1
				IF SAE->AE_FIXADIA == "2" //Emissão dia Fixo
					IF Month(dEmissa) == 12
						cMes := "01"
						cAno := StrZero(Year(dEmissa) + 1,4)
					Else
						cMes := StrZero(Month(dEmissa) + 1,2)
						cAno := StrZero(Year(dEmissa),4)
					EndIf

					cDia    := StrZero(Day(dEmissa),2)  

					If Val(cDia) > 28 .and. Val(cMes) == 2
						dEmissa := LastDay(SToD(cAno + cMes + "01"))
					ElseIf Val(cDia) > 30 .and. cMes $ '04,06,09,11'
						dEmissa := LastDay(SToD(cAno + cMes + "01"))
					Else
						dEmissa := CtoD(cDia + "/" + cMes + "/" + cAno)
					EndIf
				Else
					dEmissa := dEmissa + SAE->AE_DIAS
				Endif

				dVencto := dEmissa + SAE->AE_DIAS
			EndIf

			IF x == 1
				nDif := nTotalZZA - (round(Val(oParseJSON:PEDIDO[nX]:Z40_TOTALPED) / nParc,2) * nParc)
				nValParc := round(Val(oParseJSON:PEDIDO[nX]:Z40_TOTALPED) / nParc,2) + nDif
			Else
				nValParc := round(Val(oParseJSON:PEDIDO[nX]:Z40_TOTALPED) / nParc,2)
			Endif

			IF nParcAnt > nParc
				//Deleta as parcelas que estao à mais no sistema
				For y := (nParc+1) to nParcAnt
					DbSelectArea("ZZY")
					ZZY->(DbSetOrder(4))
					IF ZZY->(MsSeek(xFilial("ZZY") + ZZA->ZZA_NSU + ZZA->ZZA_ESTABE + ZZA->ZZA_POS + DToS(ZZA->ZZA_DTVEND) + STRZERO(y,3)))
						RecLock("ZZY",.F.)
						ZZY->(DbDelete())
						ZZY->(MsUnlock())
					Endif
				Next
			EndIf

			DbSelectArea("ZZY")
			ZZY->(DbSetOrder(4))
			IF ZZY->(MsSeek(xFilial("ZZY") + ZZA->ZZA_NSU + ZZA->ZZA_ESTABE + ZZA->ZZA_POS + DToS(ZZA->ZZA_DTVEND) + STRZERO(X,3)))
				RecLock("ZZY",.F.)
			Else
				RecLock("ZZY",.T.)
			Endif

			Replace ZZY_FILIAL WITH xFilial("ZZY") 
			Replace ZZY_NSU    WITH oParseJSON:PEDIDO[nX]:Z40_NSU
			REPLACE ZZY_DTVEND WITH CToD(oParseJSON:PEDIDO[nX]:Z40_DATAPG)
			Replace ZZY_BAND   WITH cBand
			Replace ZZY_VALOR  WITH nValParc
			Replace ZZY_TIPO   WITH fTpCart(Upper(oParseJSON:PEDIDO[nX]:Z40_TIPOPG))
			Replace ZZY_TAXA   WITH 0//nTaxa
			Replace ZZY_ESTABE WITH oParseJSON:PEDIDO[nX]:Z40_CODESTABELECIMENTO
			Replace ZZY_PARCEL WITH STRZERO(X,3)
			REPLACE ZZY_POS	   WITH SuperGetMV("AN_POSKKI",,"11820440") //FIXO VENDA WEB
			Replace ZZY_EMISSA WITH dEmisFin//dEmissa
			Replace ZZY_VENCTO WITH dVencto
			Replace ZZY_PEDIDO WITH SC5->C5_XIDPED

			ZZY->(MsUnlock())

		Next x

	Next nX

Return

Static Function fTpCart(cTpPag)
	Local cRet := ""

	If "CREDITO" $ cTpPag
		cRet := "C"
	EndIf

	If "DEBITO" $ cTpPag
		cRet := "D"
	EndIf

Return cRet

Static Function fBand(cBand, cTipo)
	Local cBandCart := ""
	Local cRet := ""
	Local nCont := 0

	If "CREDITO" $ cTipo
		cBandCart := cBand + '%' + "CREDITO"
	EndIf

	If "DEBITO" $ cTipo
		cBandCart := cBand + '%' + "DEBITO"
	EndIf

	cQuery := " SELECT AE_COD " 
	cQuery += " FROM " + RetSqlName("SAE")
	cQuery += " WHERE D_E_L_E_T_ = ' ' "
	cQuery += " AND AE_DESC LIKE '%"+cBandCart+"%' "
	cQuery += " AND AE_FILIAL = '"+XFILIAL("SAE")+"'"

	TCQUERY cQuery NEW ALIAS "QSAE"

	While !QSAE->(EOF())
		
		cRet := QSAE->AE_COD

		nCont++

		QSAE->(dbSkip())
	EndDo

	QSAE->(dbCloseArea())

	If nCont > 1
		cRet := ""
	EndIf

Return cRet
