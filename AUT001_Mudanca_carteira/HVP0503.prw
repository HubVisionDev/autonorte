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
| Objetivo:| Tela para cadastro de regra da carteira            |
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

User Function HVP0503()

Local cVldDel := "HVP05031"
Local cVldAlt := "HVP05032"
Private cTabela := "ZV1"
Private cCadastro := "Regra de Carteira"

dbSelectArea(cTabela)
(cTabela)->(dbSetOrder(1))

IF ExistBlock(cVldDel)
    cVldDel := "U_"+cVldDel+"()"
Else
    cVldDel := ".T."
Endif

IF ExistBlock(cVldAlt)
    cVldAlt := "U_"+cVldAlt+"()"
Else
    cVldAlt := ".T."
Endif

AxCadastro(cTabela, cCadastro, cVldDel, cVldAlt)

Return

User Function HVP05032()
	Local lRet 		:= .T.
    Local cQuery := ""

    //Verificar se já tem a combinação em alguma outra regra
    cQuery := " SELECT COUNT(*) QUANTIDADE FROM " + RetSqlName("ZV1")
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += " AND ZV1_ID <> '"+M->ZV1_ID+"' "
    cQuery += " AND ZV1_FILIAL = '"+xFilial("ZV1")+"'"
    cQuery += " AND ZV1_SEGTO  = '"+M->ZV1_SEGTO+"'"

    cQuery := ChangeQuery(cQuery,"XZV2")

    IF !XZV2->(Eof())
        MsgStop("Regra já cadastrada. Problema de chave duplicada!")
        lRet := .F.
    Endif

Return lRet

User Function HVP05031()
    Local lRet := .T.
    Local cQuery := ""

    cQuery := " SELECT COUNT(*) QUANTIDADE FROM " + RetSqlName("ZV2")
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += " AND ZV2_ID = '"+ZV1->ZV1_ID+"' "

    cQuery := ChangeQuery(cQuery,"XZV2")

    IF !XZV2->(Eof())
        MsgStop("Regra já utilizada. Não pode ser excluída!")
        lRet := .F.
    Endif

Return lRet
