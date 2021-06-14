create or replace PACKAGE    VENTA.PKG_SWEB_CRED_MAESTRO AS
PROCEDURE sp_list_maestro
  (
    p_tipo              IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ); 
  
  --I Req. 87567 E2.1 ID:28 avilca 10/09/2020  
  PROCEDURE sp_list_filial_zona
  (
    p_cod_zona          IN VARCHAR2,
    p_cod_depa          IN VARCHAR2, -- Req. Obs Consulta clientes MBardales 15/10/2020
    p_cod_prov          IN VARCHAR2, -- Req. Obs Consulta clientes MBardales 15/10/2020
    p_cod_dist          IN VARCHAR2, -- Req. Obs Consulta clientes MBardales 15/10/2020
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  --F Req. 87567 E2.1 ID:28 avilca 10/09/2020 
END PKG_SWEB_CRED_MAESTRO;