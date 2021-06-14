create or replace PACKAGE VENTA.PKG_SWEB_CRED_SOLI_PROFORMA AS

  /********************************************************************************
    Nombre:     SP_LIST_CRED_SOLI_PROFORMA
    Proposito:  Listar las proformas asociadas a una solicitud de crédito.
    Referencias:
    Parametros: P_COD_SOLI_CRED     ---> Código de solicitud.
                P_COD_USUA_SID      ---> Código del usuario.
                P_COD_USUA_WEB      ---> Id del usuario.
                P_IND_PAGINADO      ---> Indica si se realizara la paginación S:SI, N:NO
                P_LIMITINF          ---> Inicio de regisitros
                P_LIMITSUP          ---> Fin de registros
                P_RET_CURSOR        ---> Listado de solicitudes.
                P_RET_ESTA          ---> Estado del proceso.
                P_RET_MENS          ---> Resultado del proceso.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        24/12/2018  PHRAMIREZ        Creación del procedure.
  ********************************************************************************/
  PROCEDURE sp_list_cred_soli_proforma
  (
    p_cod_soli_cred  IN vve_cred_soli.cod_soli_cred%TYPE,   
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ind_paginado   IN VARCHAR2,
    p_limitinf       IN INTEGER,
    p_limitsup       IN INTEGER,    
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_cantidad       OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  );  

END PKG_SWEB_CRED_SOLI_PROFORMA; 
