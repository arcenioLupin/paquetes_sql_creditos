create or replace PACKAGE VENTA.PKG_SWEB_CRED_SOLI_MANT_TM AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 
    PROCEDURE SP_LISTAR_TIPO_MOVIMIENTO
  (
    P_COD_TM                     IN vve_cred_mae_tipo_movi.cod_tipo_mov%TYPE,
    P_COD_DESC_TM                IN VARCHAR2, 
    P_IND_NATU_TM                IN VARCHAR2,
    O_CURSOR                     OUT SYS_REFCURSOR,
    O_RET_ESTA                   OUT NUMBER,
    O_RET_MENS                   OUT VARCHAR2
  );

 PROCEDURE SP_LISTAR_TM_TODOS
  (
    O_CURSOR                     OUT SYS_REFCURSOR,
    O_RET_ESTA                   OUT NUMBER,
    O_RET_MENS                   OUT VARCHAR2
  );
  
  PROCEDURE SP_IS_TIPO_MOV_OPER
  (
    p_cod_soli_cred              IN vve_cred_soli.cod_soli_cred%TYPE,
    p_txt_nro_documento          IN vve_cred_soli_movi.txt_nro_documento%TYPE,
    p_cod_tipo_mov               IN vve_cred_mae_tipo_movi.cod_tipo_mov%TYPE,
    O_CURSOR                     OUT SYS_REFCURSOR,
    O_RET_ESTA                   OUT NUMBER,
    O_RET_MENS                   OUT VARCHAR2
  );
  
  PROCEDURE SP_ACT_TIPO_MOVI
  (
    p_cod_tipo_movi     IN vve_cred_mae_tipo_movi.cod_tipo_mov%TYPE,
    p_txt_desc_tipo_movi     IN vve_cred_mae_tipo_movi.txt_desc_tipo_movi%TYPE,
    p_ind_natu_tipo_movi     IN vve_cred_mae_tipo_movi.ind_natu_tipo_movi%TYPE,
    p_ind_inactivo    IN vve_cred_mae_tipo_movi.ind_inactivo%TYPE,
    p_fec_crea_regi      IN vve_cred_mae_tipo_movi.fec_crea_regi%TYPE,
    p_cod_usua_regi      IN vve_cred_mae_tipo_movi.cod_usua_regi%TYPE,
    p_fec_modi_regi    IN vve_cred_mae_tipo_movi.fec_modi_regi%TYPE,
    p_cod_usua_modi      IN vve_cred_mae_tipo_movi.cod_usua_modi%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
PROCEDURE SP_LISTAR_TABLA_MAES
  (
    O_CURSOR                     OUT SYS_REFCURSOR,
    O_RET_ESTA                   OUT NUMBER,
    O_RET_MENS                   OUT VARCHAR2
  );
  
END PKG_SWEB_CRED_SOLI_MANT_TM;