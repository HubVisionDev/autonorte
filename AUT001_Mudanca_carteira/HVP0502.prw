#Include "Totvs.ch"
#INCLUDE "rwmake.ch"
#Include 'TOPCONN.ch'
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

/*
#---------------------------------------------------------------#
| Programa:| HVP0502                           Data:22/05/2025  |
|---------------------------------------------------------------|
| Autor:   | HubVision - Raphael Neves                          |
|---------------------------------------------------------------|
| Objetivo:| JOB para geração da ZV2                            |
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

User Function HVP0502(aParam)

	Default aParam := {"01","020101"}

	PREPARE ENVIRONMENT EMPRESA aParam[1] FILIAL aParam[2]

	HVP0502A(IsBlind())

	RESET ENVIRONMENT

Return

User Function HVP0502X()

	HVP0502A(IsBlind())

Return

Static Function HVP0502A(lJob)
	Local cQuery := ""
	Local nI

	DbSelectArea("ZV1")
	ZV1->(DbSetOrder(1))
	While !ZV1->(Eof())

		IF dDataBase > ZV1->ZV1_DULT + ZV1->ZV1_PER

            Begin Transaction 

			cQuery := ""
			cQuery += " SELECT  " + ENTER
			cQuery += " 	'"+xFilial("ZV2")+"'              AS ZV2_FILIAL, " + ENTER
			cQuery += " 	'  '                              AS ZV2_OK, " + ENTER
			cQuery += " 	'"+ZV1->ZV1_ID+"'                 AS ZV2_ID, " + ENTER
			cQuery += " 	'"+DtoS(dDataBase)+"'             AS ZV2_DTPROC, " + ENTER
			cQuery += "     D2_CLIENTE                        AS ZV2_CLIENT, " + ENTER
			cQuery += "     D2_LOJA                           AS ZV2_LOJA, " + ENTER
			cQuery += "     A1_VEND                           AS ZV2_VANT, " + ENTER
            IF !Empty(ZV1->ZV1_SEGTO)
			    cQuery += "     B1_XSEG                           AS ZV2_SEGTO, " + ENTER
            Else
			    cQuery += "     ' '                           AS ZV2_SEGTO, " + ENTER
            Endif
			cQuery += "     "+cValToChar(ZV1->ZV1_VLMIN)+"    AS ZV2_VLMIN, " + ENTER
			cQuery += "     SUM(D2_TOTAL)                     AS ZV2_VLVEN, " + ENTER
			cQuery += "     '"+ZV1->ZV1_VPAD+"'               AS ZV2_VPAD, " + ENTER
			// cQuery += "     '"+ZV1->ZV1_EML1+"'               AS ZV2_EML1, " + ENTER
			// cQuery += "     '"+ZV1->ZV1_EML2+"'               AS ZV2_EML2, " + ENTER
			cQuery += "     ' '                               AS ZV2_VNOVO, " + ENTER
			cQuery += "     ' '                               AS ZV2_DTREC, " + ENTER
			cQuery += "     A1_ULTCOM                         AS ZV2_ULTVD, " + ENTER
			cQuery += "     SUM((SELECT NVL(SUM(D1_TOTAL),0) FROM "+RetSqlName("SD1") + ENTER
			cQuery += "                                 WHERE D_E_L_E_T_ =' '  " + ENTER
			cQuery += "                                 AND D1_FILORI = D2_FILIAL  " + ENTER
			cQuery += "                                 AND D1_NFORI = D2_DOC  " + ENTER
			cQuery += "                                 AND D1_SERIORI = D2_SERIE  " + ENTER
			cQuery += "                                 AND D1_ITEMORI = D2_ITEM)) AS ZV2_TDEV  " + ENTER
			cQuery += " FROM "+RetSqlName("SD2")+" A  " + ENTER
			cQuery += " INNER JOIN "+RetSqlName("SB1")+"  B " + ENTER
			cQuery += "     ON B.D_E_L_E_T_ =' ' " + ENTER
			cQuery += "     AND B.B1_COD = A.D2_COD " + ENTER
			cQuery += " INNER JOIN "+RetSqlName("SA1")+"  C " + ENTER
			cQuery += "     ON C.D_E_L_E_T_ =' ' " + ENTER
			cQuery += "     AND A1_COD = D2_CLIENTE " + ENTER
			cQuery += "     AND A1_LOJA = D2_LOJA " + ENTER
			cQuery += " INNER JOIN "+RetSqlName("SA3")+"  D " + ENTER
			cQuery += "     ON D.D_E_L_E_T_ =' ' " + ENTER
			cQuery += "     AND A1_VEND = A3_COD " + ENTER
			cQuery += " INNER JOIN SF2010 E "
			cQuery += " 	ON E.D_E_L_E_T_ = ' ' "
			cQuery += " 	AND F2_FILIAL = D2_FILIAL "
			cQuery += " 	AND F2_SERIE = D2_SERIE "
			cQuery += " 	AND F2_DOC = D2_DOC "
			cQuery += " 	AND F2_TIPO = D2_TIPO "
			cQuery += " 	AND F2_CLIENTE = D2_CLIENTE "
			cQuery += " 	AND F2_LOJA = D2_LOJA "
			cQuery += " 	AND F2_VEND1 = A1_VEND "
			cQuery += " WHERE A.D_E_L_E_T_ = ' ' " + ENTER
			cQuery += "     AND D2_FILIAL = '"+xFilial("SD2")+"' " + ENTER
			cQuery += "     AND D2_XOPER = '01' " + ENTER
			cQuery += "     AND D2_EMISSAO >= '"+DtoS(ZV1->ZV1_DULT+1)+"' " + ENTER
			cQuery += "     AND D2_EMISSAO <= '"+DtoS(dDataBase)+"' " + ENTER
			cQuery += "     AND D2_TIPO = 'N' " + ENTER
            IF !Empty(ZV1->ZV1_SEGTO)
			    cQuery += "     AND B1_XSEG = '"+ZV1->ZV1_SEGTO+"' " + ENTER
			    cQuery += " GROUP BY D2_FILIAL,D2_CLIENTE, D2_LOJA, A1_VEND, B1_XSEG, A1_ULTCOM " + ENTER
            Else
				cQuery += MenosSegto()
			    cQuery += " GROUP BY D2_FILIAL,D2_CLIENTE, D2_LOJA, A1_VEND, A1_ULTCOM " + ENTER
            EndIf

			MPSysOpenQuery( cQuery, 'QRYTMP' )

            DbSelectArea("ZV2")
            DbSelectArea("SA1")
			While QRYTMP->(!eof())
				//Verifica se a soma das vendas está abaixo da meta
				//TODO: Verificar uma forma de melhorar desempenho
				IF QRYTMP->(ZV2_VLMIN) < ZV1->ZV1_VLMIN
					RecLock("ZV2",.T.)
					For nI := 1 to ZV2->(fcount())
						IF Alltrim(FieldName(nI)) <> "ZV2_USER"
							If GetSx3Cache(FieldName(nI),"X3_TIPO") == "D"
								Replace ZV2->(&(FieldName(nI))) with StoD(&("QRYTMP->"+(FieldName(ni))))
							Else
								Replace ZV2->(&(FieldName(nI))) with &("QRYTMP->"+(FieldName(ni)))
							Endif
						Endif
					Next nI
					ZV2->(MsUnlock())

					//Altera o cliente para o vendedor padrão
					SA1->(MsSeek(xFilial("SA1") + ZV2->ZV2_CLIENT + ZV2->ZV2_LOJA))
					RecLock("SA1",.F.)
					SA1->A1_VEND := ZV1->ZV1_VPAD
					SA1->(MsUnlock())
				EndIf

				QRYTMP->(dbskip())
			Enddo

			QRYTMP->(dbCloseArea())


			RecLock("ZV1",.F.)
			ZV1->ZV1_DULT := dDataBase
			ZV1->(MsUnlock())

            End Transaction
		Endif
		ZV1->(DbSkip())
	EndDo


Return

Static Function MenosSegto()

	Local cRet := ""
	//TODO: Verificar se tem regras com segmentos para abater quando estiver com algum em branco.

Return cRet 
