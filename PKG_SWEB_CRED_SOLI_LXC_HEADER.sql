create or replace PACKAGE  VENTA.PKG_SWEB_CRED_SOLI_LXC AS

  PROCEDURE sp_list_docu_rela
    (
    p_no_cliente          IN                arccmd.no_cliente%TYPE,
    p_cod_soli_cred       IN                vve_cred_soli_pedi_veh.cod_soli_cred%TYPE,
    p_no_cia              IN                arccmd.no_cia%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_cursor_total    OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
    );

  PROCEDURE sp_list_tipo_docu
    (
    p_no_cia              IN                arcctd.no_cia%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
    );

  PROCEDURE sp_list_tipo_gasto
    (
    p_no_cia              IN                arcctd.no_cia%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
    );

  PROCEDURE sp_list_gastos
    (
    p_cod_soli_cred       IN                vve_cred_simu.cod_soli_cred%TYPE,
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_cursor_total    OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
    );

  PROCEDURE sp_list_repre_legal
    (
    p_cod_cliente         IN                gen_persona.cod_perso%TYPE,
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
    );

  PROCEDURE sp_list_repro_oper
    (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_no_cia              IN                arlcop.no_cia%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ind_paginado        IN                VARCHAR2,
    p_limitinf            IN                INTEGER,
    p_limitsup            IN                INTEGER,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_cantidad            OUT               NUMBER,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
    );

  PROCEDURE sp_list_oper_regi
    (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_docu            OUT               SYS_REFCURSOR,
    p_ret_docu_total      OUT               SYS_REFCURSOR,
    p_ret_gasto           OUT               SYS_REFCURSOR,
    p_ret_gasto_total     OUT               SYS_REFCURSOR,
    p_ret_aval            OUT               SYS_REFCURSOR,
    p_ret_oper_regi       OUT               SYS_REFCURSOR,
	p_ret_tipo_credito_lxc    OUT               vve_cred_soli_para.val_para_car%TYPE,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2 
    );

  PROCEDURE sp_list_crono_lxc
    (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_totales         OUT               SYS_REFCURSOR,
    p_ret_datos_gen       OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
    );

END PKG_SWEB_CRED_SOLI_LXC; 