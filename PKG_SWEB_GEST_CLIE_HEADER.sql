create or replace PACKAGE       VENTA.PKG_SWEB_GEST_CLIE AS
PROCEDURE SP_LIST_CLIE --SP_LISTADO_CLIENTE
  (
    P_CADENAB     IN VARCHAR,
    P_DOC         IN VARCHAR,
    P_COD_CLIENTE IN VARCHAR,
    P_LIMITINF    IN VARCHAR,
    P_LIMITSUP    IN INTEGER,
    L_CURSOR      OUT SYS_REFCURSOR,
    L_CANTIDAD    OUT VARCHAR
  );
FUNCTION fu_vali_tipo_clie(
  p_cod_clie VARCHAR2
  ) RETURN NUMBER;
  
PROCEDURE sp_list_enti_fina(
   p_ret_curs           OUT SYS_REFCURSOR
  ,p_ret_esta           OUT NUMBER
  ,p_ret_mens           OUT VARCHAR2 
  );  
  
PROCEDURE sp_cliente_sap
(
  p_Cod_Clie_Sap IN Cxc_Mae_Clie.Cod_Clie_Sap%TYPE,
  p_cod_clie_sid OUT vve_proforma_veh.cod_clie%TYPE,
  p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
  p_cod_usua_web IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_ret_esta     OUT NUMBER,
  p_Ret_mens     OUT VARCHAR2
);

PROCEDURE sp_lista_cta_banco
(
  p_no_cia       IN vve_cta_banco.no_cia%TYPE,
  p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
  p_cod_usua_web IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
  p_ret_curs     OUT SYS_REFCURSOR,
  p_ret_esta     OUT NUMBER,
  p_Ret_mens     OUT VARCHAR2
);
/*-----------------------------------------------------------------------------
Nombre : fu_vali_mail_clie
Proposito : función que valida si la persona tiene cuenta de correo. 
Referencias : 
Parametros :
Log de Cambios 
  Fecha        Autor         Descripcion
  26/12/2017   MGELDRES         84921 Creacion
----------------------------------------------------------------------------*/
FUNCTION fu_vali_mail_clie(
  p_cod_clie VARCHAR2
  ) RETURN NUMBER;
  
    /*-----------------------------------------------------------------------------
  Nombre : SP_LIST_CLIE_ASIG_PEDIDOS
  Proposito : función que valida si la persona tiene cuenta de correo. 
  Referencias : 
  Parametros :
  Log de Cambios 
    Fecha        Autor         Descripcion
    26/12/2017   ARAMOS         84921 Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE SP_LIST_CLIE_ASIG_PEDIDOS
  (
    P_CADENAB     IN VARCHAR,
    P_DOC         IN VARCHAR,
    P_COD_CLIENTE IN VARCHAR,
    P_LIMITINF    IN VARCHAR,
    P_LIMITSUP    IN INTEGER,
    L_CURSOR      OUT SYS_REFCURSOR,
    L_CANTIDAD    OUT VARCHAR
  );    
END PKG_SWEB_GEST_CLIE;