create or replace PACKAGE  VENTA.PKG_SWEB_CRED_SOLI_DOCUMENTO AS
  PROCEDURE sp_list_docu_soli
  (
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_ind_mancomunado   IN generico.gen_persona.ind_mancomunado%TYPE,
    p_cod_tipo_perso    IN generico.gen_persona.cod_tipo_perso%TYPE,
    p_cod_estado_civil  IN generico.gen_persona.cod_estado_civil%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_act_docu_soli 
  (
    p_cod_docu_eval        IN vve_cred_fina_docu.cod_docu_eval%TYPE,
    p_cod_soli_cred        IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_txt_ruta_doc         IN vve_cred_fina_docu.txt_ruta_doc%TYPE,
    p_fec_emis_doc         IN VARCHAR2,
    p_operacion            IN VARCHAR2,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
   );
   
  PROCEDURE sp_list_docu_general
  (
    p_tipo_docu         IN VARCHAR2,
    p_cod_proceso       IN VARCHAR2,
    p_ind_tipo_docu     IN vve_cred_mae_docu.ind_tipo_docu%TYPE,
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_ind_mancomunado   IN generico.gen_persona.ind_mancomunado%TYPE,
    p_cod_tipo_perso    IN generico.gen_persona.cod_tipo_perso%TYPE,
    p_cod_estado_civil  IN generico.gen_persona.cod_estado_civil%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_act_docu_general 
  (
    p_tipo_docu            IN VARCHAR2,
    p_cod_proceso          IN VARCHAR2,
    p_cod_docu_eval        IN vve_cred_fina_docu.cod_docu_eval%TYPE,
    p_cod_soli_cred        IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_txt_ruta_doc         IN vve_cred_fina_docu.txt_ruta_doc%TYPE,
    p_fec_emis_doc         IN VARCHAR2,
    p_operacion            IN VARCHAR2,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
   );

END PKG_SWEB_CRED_SOLI_DOCUMENTO; 