create or replace PACKAGE       VENTA.PKG_SWEB_CRED_SOLI_FLUJO_CAJA AS

  PROCEDURE sp_inse_param_camiones 
    (      
     p_cod_soli_cred                IN      vve_cred_soli.cod_soli_cred%TYPE,
     p_no_cia                       IN      vve_cred_soli.cod_empr%TYPE,
     p_list_ingr_egre               IN      VVE_TYTA_LIST_INGR_EGRE,
     p_indi_tipo_fc                 IN      VARCHAR2,
     p_cod_usua_sid                 IN      sistemas.usuarios.co_usuario%TYPE,
     p_ret_esta                     OUT     NUMBER,
     p_ret_mens                     OUT     VARCHAR2
    );


  PROCEDURE sp_inse_fact_mes 
    (      
     p_cod_soli_cred                IN      vve_cred_soli.cod_soli_cred%TYPE,
     p_no_cia                       IN      vve_cred_soli.cod_empr%TYPE,
     p_fac_cons_ingr                IN      NUMERIC,
     p_ind_fac_fijo_vari_ingr       IN      VARCHAR2,
     p_fac_cons_egre                IN      NUMERIC,
     p_ind_fac_fijo_vari_egre       IN      VARCHAR2,
     p_fec_ini_fact_ingr            IN      VARCHAR2,
     p_fec_fin_fact_ingr            IN      VARCHAR2,
     p_fec_ini_fact_egre            IN      VARCHAR2,
     p_fec_fin_fact_egre            IN      VARCHAR2,
     p_list_fact_mes                IN      VVE_TYTA_LIST_FACT_MES,
     p_indi_tipo_fc                 IN      VARCHAR2,
     p_cant_ruta                    IN      NUMBER,
     p_cod_usua_sid                 IN      sistemas.usuarios.co_usuario%TYPE,
     p_ret_esta                     OUT     NUMBER,
     p_ret_mens                     OUT     VARCHAR2
    );

  PROCEDURE sp_calc_proy_cami 
    (      
     p_cod_soli_cred                IN      vve_cred_soli.cod_soli_cred%TYPE,
     p_indi_tipo_fc                 IN      VARCHAR2,
     p_cod_usua_sid                 IN      sistemas.usuarios.co_usuario%TYPE,
     p_ret_cursor                   OUT     SYS_REFCURSOR,
     p_ret_colu_ano                 OUT     SYS_REFCURSOR,
     p_ret_esta                     OUT     NUMBER,
     p_ret_mens                     OUT     VARCHAR2
    );

  FUNCTION fn_ret_text
    (
     p_val_ano                       IN      NUMBER
    ) RETURN VARCHAR2;

  FUNCTION fn_ret_val_cred_soli_fact_fc
    (
     p_cod_soli_cred                 IN      vve_cred_soli_fact_fc.cod_soli_cred%TYPE,
     p_cod_cred_para_fact            IN      vve_cred_soli_fact_fc.cod_cred_para_fact%TYPE,
     p_val_mes                       IN      vve_cred_soli_fact_fc.val_mes%TYPE, 
     p_val_ano                       IN      vve_cred_soli_fact_fc.val_ano%TYPE,
     p_ind_tipo_fc                   IN      vve_cred_soli_fact_fc.ind_tipo_fc%TYPE   
    ) RETURN NUMBER;


  FUNCTION fn_ret_val_cred_soli_para_fc
    (
     p_cod_soli_cred                 IN      vve_cred_soli_para_fc.cod_soli_cred%TYPE,
     p_cod_cred_para_fc              IN      vve_cred_soli_para_fc.cod_cred_para_fc%TYPE,
     p_ind_tipo_fc                   IN      vve_cred_soli_para_fc.ind_tipo_fc%TYPE   
    ) RETURN NUMBER;


  PROCEDURE sp_list_para_fc
    (      
     p_cod_soli_cred                IN      vve_cred_soli.cod_soli_cred%TYPE,
     p_ind_tipo_fc                  IN      vve_cred_soli_para_fc.ind_tipo_fc%TYPE,
     p_cod_usua_sid                 IN      sistemas.usuarios.co_usuario%TYPE,
     p_ret_cursor                   OUT     SYS_REFCURSOR,
     p_ret_cabe_urba                OUT     SYS_REFCURSOR,
     p_ret_fact_cons_if             OUT     SYS_REFCURSOR, 
     p_ret_fact_cons_ef             OUT     SYS_REFCURSOR, 
     p_ret_fact_ajus_if             OUT     SYS_REFCURSOR, 
     p_ret_fact_ajus_ef             OUT     SYS_REFCURSOR,
     p_ret_colu_ano                 OUT     SYS_REFCURSOR, 
     p_ret_fc_proy                  OUT     SYS_REFCURSOR, 
     p_ret_esta                     OUT     NUMBER,
     p_ret_mens                     OUT     VARCHAR2
    );



  PROCEDURE sp_repo_fluj_caja
    (      
     p_cod_soli_cred                IN      vve_cred_soli.cod_soli_cred%TYPE,
     p_indi_tipo_fc                 IN      VARCHAR2,
     p_cod_usua_sid                 IN      sistemas.usuarios.co_usuario%TYPE,
     p_ret_fact_ingr                OUT     SYS_REFCURSOR,
     p_ret_fact_egre                OUT     SYS_REFCURSOR,
     p_ret_fact_caja                OUT     SYS_REFCURSOR,
     p_ret_fc_proy                  OUT     SYS_REFCURSOR, 
     p_txtComentario                OUT     VARCHAR2,
     p_ret_esta                     OUT     NUMBER,
     p_ret_mens                     OUT     VARCHAR2
    );
    

  PROCEDURE sp_obte_info_fc
  (
     p_cod_soli_cred IN  vve_cred_soli.cod_soli_cred%TYPE,
     p_cod_usua_sid  IN  sistemas.usuarios.co_usuario%TYPE,
     p_ret_cursor    OUT SYS_REFCURSOR, 
     p_ret_esta      OUT NUMBER,
     p_ret_mens      OUT VARCHAR2    
  );

END PKG_SWEB_CRED_SOLI_FLUJO_CAJA;