create or replace PACKAGE VENTA.PKG_SWEB_CRED_SOLI_MANT_TMSIMU AS 

 /********************************************************************************
    Nombre:     SP_ACT_TIPO_MOVI
    Proposito:  Permite insertar y actualizar los tipo de movimientos desde el simulador de credito.
    Referencias:
    Parametros: cod_id_soli_tipm          -->  Actualiza el campo que lleva su nombre.
                cod_soli_cred             -->  Actualiza el campo que lleva su nombre.
                cod_tipo_movi_pago        -->  Actualiza el campo que lleva su nombre.
                fec_movi_pago             -->  Actualiza el campo que lleva su nombre.
                cod_banco                 -->  Actualiza el campo que lleva su nombre.
                cod_moneda                -->  Actualiza el campo que lleva su nombre.
                val_monto_pago            -->  Actualiza el campo que lleva su nombre.
                txt_nro_documento         -->  Actualiza el campo que lleva su nombre.
                ind_inactivo              -->  Actualiza el campo que lleva su nombre.
                ind_tipo_docu             -->  Actualiza el campo que lleva su nombre.
                cod_empresa_cargo         -->  Actualiza el campo que lleva su nombre.
                fec_crea_regi             -->  Actualiza el campo que lleva su nombre. 
                cod_usua_crea_regi        -->  Actualiza el campo que lleva su nombre.
                fec_modi_regi             -->  Actualiza el campo que lleva su nombre.
                cod_usua_modi_regi        -->  Actualiza el campo que lleva su nombre.          
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        24/01/2020  EBARBOZA        Creación del procedure.
  ********************************************************************************/    
  
  PROCEDURE SP_ACT_TIPO_MOVI_SIMU
  (
    p_cod_id_soli_tipm IN  vve_cred_soli_movi.cod_id_soli_tipm%TYPE,
    p_cod_soli_cred IN  vve_cred_soli_movi.cod_soli_cred%TYPE,
    p_cod_tipo_movi_pago IN  vve_cred_soli_movi.cod_tipo_movi_pago%TYPE,
    p_fec_movi_pago IN  VARCHAR2,
    p_cod_banco IN  vve_cred_soli_movi.cod_banco%TYPE,
    p_cod_moneda IN  vve_cred_soli_movi.cod_moneda%TYPE,
    p_val_monto_pago IN  vve_cred_soli_movi.val_monto_pago%TYPE,
    p_txt_nro_documento IN  vve_cred_soli_movi.txt_nro_documento%TYPE,
    p_ind_inactivo IN  vve_cred_soli_movi.ind_inactivo%TYPE,
    p_ind_tipo_docu IN  vve_cred_soli_movi.ind_tipo_docu%TYPE,
    p_cod_empresa_cargo IN  vve_cred_soli_movi.cod_empresa_cargo%TYPE,
    p_fec_crea_regi IN  vve_cred_soli_movi.fec_crea_regi%TYPE,
    p_cod_usua_crea_regi IN  vve_cred_soli_movi.cod_usua_crea_regi%TYPE,
    p_fec_modi_regi IN  vve_cred_soli_movi.fec_modi_regi%TYPE,
    p_cod_usua_modi_regi IN  vve_cred_soli_movi.cod_usua_modi_regi%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE SP_LISTAR_TIPO_MOVIMIENTO_SIMU
  (
    p_cod_soli_cred IN  vve_cred_soli_movi.cod_soli_cred%TYPE,
    O_CURSOR                     OUT SYS_REFCURSOR,
    O_RET_ESTA                   OUT NUMBER,
    O_RET_MENS                   OUT VARCHAR2
  );
 

END PKG_SWEB_CRED_SOLI_MANT_TMSIMU;