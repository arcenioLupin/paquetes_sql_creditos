create or replace PACKAGE       VENTA.PKG_SWEB_CRED_SOLI_SEGURO IS
/*-----------------------------------------------------------------------------
Nombre : SP_LIST_SOLI_CRED_SEGURO
Proposito : CONSULTA DE SEGURO DE SOLICITUD DE CRÉDITO
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
  06/02/2019   MGRASSO  
----------------------------------------------------------------------------*/
PROCEDURE SP_LIST_SOLI_CRED_SEGURO(
   p_cod_soli_cred IN vve_cred_soli.cod_soli_cred%TYPE,
   p_ret_cursor        OUT SYS_REFCURSOR,
   p_ret_esta          OUT NUMBER,
   p_ret_mens          OUT VARCHAR2
  ) ;
  
  /*-----------------------------------------------------------------------------
Nombre : SP_LIST_SOLI_CRED_SEGURO_DET
Proposito : CONSULTA DE DETALLE DE SEGURO DE SOLICITUD DE CRÉDITO
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
  07/02/2019   MGRASSO  
----------------------------------------------------------------------------*/
PROCEDURE SP_LIST_SOLI_CRED_SEGURO_DET(
   p_cod_soli_cred IN vve_cred_soli_even.cod_soli_cred%TYPE,
   p_ret_cursor        OUT SYS_REFCURSOR,
   p_ret_esta          OUT NUMBER,
   p_ret_mens          OUT VARCHAR2
  ) ;
  
  /*-----------------------------------------------------------------------------
Nombre : sp_actu_estado_soli_seg
Proposito : ACTUALIZA EL ESTADO DEL SEGURO DE LA SOLICITUD
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
  07/02/2019   MGRASSO  
----------------------------------------------------------------------------*/
PROCEDURE sp_actu_estado_soli_seg(
    p_cod_soli_cred IN vve_cred_soli.COD_SOLI_CRED%TYPE,
    p_ind_resp_apro_tseg IN vve_cred_soli.ind_resp_apro_tseg%TYPE,
    p_txt_obse_rech_tseg IN vve_cred_soli.txt_obse_rech_tseg%TYPE,
    p_cod_usua_gest_seg IN vve_cred_soli.cod_usua_gest_seg%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  ) ;
  
/*-----------------------------------------------------------------------------
Nombre : sp_actu_estado_soli_seg
Proposito : ACTUALIZA LOS DATOS DEL SEGURO
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
  20/02/2019   MGRASSO  
  13/03/2020   AVILCA      Req. 87567 E2.1 
----------------------------------------------------------------------------*/
PROCEDURE SP_ACTU_DATOS_SOLI_SEG(
    P_COD_SOLI_CRED IN vve_cred_soli.COD_SOLI_CRED%TYPE,
    P_NRO_POLI_SEG IN vve_cred_soli.NRO_POLI_SEG%TYPE,
    P_FEC_INIC_VIGE_POLI IN VARCHAR2,
    P_FEC_FIN_VIGE_POLI IN VARCHAR2,
    P_FEC_PRIM_PAGO_POLI_ENDO IN VARCHAR2,
    P_FEC_ULTI_PAGO_POLI_ENDO IN VARCHAR2,
    P_TXT_RUTA_POLI_ENDO IN vve_cred_soli.TXT_RUTA_POLI_ENDO%TYPE,
    P_TXT_RUTA_FACT  IN vve_cred_soli.TXT_RUTA_FACT%TYPE,
    P_FEC_ACT_POLI  IN VARCHAR2,
    P_COD_USUA_MODI IN vve_cred_soli.COD_USUA_MODI%TYPE,
    P_COD_CIA_SEG IN VARCHAR2,
    P_VAL_PORC_TEA_SIGV IN vve_cred_soli.VAL_TASA_SEGU%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  );
  
  /*-----------------------------------------------------------------------------
Nombre : SP_ACTU_PLACA_SOLI_SEG
Proposito : ACTUALIZA LA PLACA DEL VEHICULO A ASEGURAR
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
  20/02/2019   MGRASSO  
----------------------------------------------------------------------------*/
PROCEDURE SP_ACTU_PLACA_SOLI_SEG(
    P_COD_GARANTIA IN VVE_CRED_MAES_GARA.COD_GARANTIA%TYPE,
    P_NUM_PLACA_VEH IN VVE_PEDIDO_VEH.NUM_PLACA_VEH %TYPE,
    P_CO_USUARIO_MOD_REG IN VVE_PEDIDO_VEH.CO_USUARIO_MOD_REG%TYPE,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  ) ;

  /*-----------------------------------------------------------------------------
Nombre : SP_LIST_POLI_SEG
Proposito : LISTA LAS POLIZAS DE SEGURO
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 01/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
PROCEDURE SP_LIST_POLI_SEG(
    P_COD_SOLI_CRED IN vve_cred_soli.COD_SOLI_CRED%TYPE,
    P_NRO_POLI_SEG IN vve_cred_soli.NRO_POLI_SEG%TYPE,
    P_FEC_INIC_VIGE_POLI IN VARCHAR2,
    P_FEC_FIN_VIGE_POLI IN VARCHAR2,
    P_IND_TIPO_SEGU in vve_cred_soli.IND_TIPO_SEGU%TYPE,
    P_COD_CIA_SEG in vve_cred_soli.COD_CIA_SEG%TYPE,
    P_COD_AREA_VTA in vve_cred_soli.COD_AREA_VTA%TYPE,
    P_COD_ESTA_POLI in vve_cred_soli.COD_ESTA_POLI%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta OUT NUMBER,
    p_ret_mens OUT VARCHAR2
  ) ; 
 
 
   /*-----------------------------------------------------------------------------
Nombre : sp_gen_plantilla_correo_segu
Proposito : Crea plantilla para envio de correo de seguros
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
 08/03/2019   MGRASSO  
----------------------------------------------------------------------------*/
  PROCEDURE sp_gen_plantilla_correo_segu
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
/*-----------------------------------------------------------------------------
    Nombre : SP_LIST_SOLI_CRED_SEGURO_TRAMA
    Proposito : Reporte de Trama de seguros
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     13/11/2019    AVILCA  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LIST_SOLI_CRED_SEGURO_TRAMA(
   p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE,
   p_ret_cursor        OUT SYS_REFCURSOR,
   p_ret_esta          OUT NUMBER,
   p_ret_mens          OUT VARCHAR2
  );
/*-----------------------------------------------------------------------------
    Nombre : SP_LIST_SOLI_CRED_VENC_SEGURO
    Proposito : Lista las polizas con vencimiento igual a {p_fec_vencimiento}
    Referencias : E2.1 ID 113-114 JUANQUINTANILLA
    Parametros : p_fec_vencimiento
    Log de Cambios 
      Fecha        Autor         Descripcion
     09/01/2020    JQUINTANILLA  
----------------------------------------------------------------------------*/
  PROCEDURE SP_LIST_SOLI_CRED_VENC_SEGURO
  (
    p_fec_vencimiento   IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
/*-----------------------------------------------------------------------------
    Nombre : sp_gen_plantilla_correo_rech_tasa_segu
    Proposito : Genera plantilla correo de rechazo tasa menor en seguros
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     06/10/2020    AVILCA  
----------------------------------------------------------------------------*/  
    PROCEDURE sp_gen_plantilla_rech_tasa
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_asunto_input      IN VARCHAR2,
    p_obs_rechazo_input IN VARCHAR2,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ); 
/*-----------------------------------------------------------------------------
    Nombre : sp_gen_plantilla_correo_rech_tasa_segu
    Proposito : Genera plantilla correo de aprobación tasa menor en seguros
    Referencias : 
    Parametros :
    Log de Cambios 
      Fecha        Autor         Descripcion
     06/10/2020    AVILCA  
----------------------------------------------------------------------------*/    
   PROCEDURE sp_gen_plantilla_aprob_tasa
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );  

END PKG_SWEB_CRED_SOLI_SEGURO;