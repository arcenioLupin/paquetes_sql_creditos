create or replace PACKAGE   VENTA.PKG_SWEB_CRED_MAESTRO AS
PROCEDURE sp_list_maestro
  (
    p_tipo              IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );  
END PKG_SWEB_CRED_MAESTRO; 