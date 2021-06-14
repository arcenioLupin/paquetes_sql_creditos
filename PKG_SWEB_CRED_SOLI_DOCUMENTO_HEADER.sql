create or replace PACKAGE   VENTA.PKG_SWEB_CRED_SOLI_DOCUMENTO AS
  /*-----------------------------------------------------------------------------
  Nombre : sp_list_docu_soli
  Proposito : Listado de documentos por solicitud
  Referencias : Para adjuntar archivos al registro
  Parametros : [
    p_cod_soli_cred     -> Codigo de la solicitud credito
    p_cod_docu_eval     -> Codigo de documento adjunto
    p_TXT_DES_ARCHIVO   -> Descripcion de Archivo
    p_ind_mancomunado   ->
    p_cod_tipo_perso    -> Codigo Tipo de Persona: N,J(Natural,Juridica)
    p_cod_estado_civil  -> Codito Estado Civil: S,C(Soltero, Casado/Conviviente)
    p_cod_usua_sid      -> Codigo de Usuario
    p_cod_usua_web      -> Login de Usuario
    ]
  Log de Cambios
    Fecha        Autor         Descripcion
    -------     Anonimo        Creado
    15/04/2020  Dante Artica   Modificacion:90028-carga-de-documentos-multiples
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_docu_soli
  (
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    ------I-90028  
    p_cod_docu_eval     IN vve_cred_fina_docu.cod_docu_eval%TYPE,  
    p_TXT_DES_ARCHIVO   IN vve_cred_fina_docu.TXT_DES_ARCHIVO%TYPE,  
    ------F-90028  
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
    /*-----------------------------------------------------------------------------
  Nombre : sp_act_docu_soli
  Proposito : Actualizar documentos por solicitud
  Referencias : Para adjuntar archivos al registro
  Parametros : [
    p_cod_docu_eval     -> Codigo de documento adjunto
    p_cod_soli_cred     -> Codigo de la solicitud credito
    p_cod_sec_archivo   -> Secuencia por tipo de documento
    p_TXT_DES_ARCHIVO   -> Descripcion de Archivo
    p_ind_mancomunado   ->
    p_cod_tipo_perso    -> Codigo Tipo de Persona: N,J(Natural,Juridica)
    p_cod_estado_civil  -> Codito Estado Civil: S,C(Soltero, Casado/Conviviente)  p_txt_ruta_doc         IN vve_cred_fina_docu.txt_ruta_doc%TYPE,
    p_fec_emis_doc      -> Fecha de emison del documento
    p_operacion         -> Codigo de Operacion
    p_cod_usua_sid      -> Codigo de Usuario
    p_cod_usua_web      -> Login de Usuario
    ]
  Log de Cambios
    Fecha        Autor         Descripcion
    -------     Anonimo        Creado
    15/04/2020  Dante Artica   Modificacion:90028-carga-de-documentos-multiples
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_act_docu_soli 
  (
    p_cod_docu_eval        IN vve_cred_fina_docu.cod_docu_eval%TYPE,
    p_cod_soli_cred        IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    ------I-90028  
    p_cod_sec_archivo     IN vve_cred_fina_docu.cod_sec_archivo%TYPE,  
    p_TXT_DES_ARCHIVO     IN vve_cred_fina_docu.TXT_DES_ARCHIVO%TYPE,  
    ------I-90028  
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
   
 /*-----------------------------------------------------------------------------
  Nombre : sp_list_docu_soli_combo
  Proposito : Lista tipo de documetos para adjuntar a ls ocilicitud de creditoa
  Referencias : Para adjuntar archivos al proceso
  Log de Cambios
    Fecha        Autor         Descripcion
    13/04/2019   Dante Artica   Creado
  ----------------------------------------------------------------------------*/ 
   PROCEDURE sp_list_docu_soli_combo
  (
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
   /*-----------------------------------------------------------------------------
  Nombre : sp_lista_adjuntos_anteriores
  Proposito : Lista de adjuntos anteriores de la solicitud de credito
  Referencias : Para adjuntar archivos al proceso
  Log de Cambios
    Fecha        Autor         Descripcion
    13/04/2019   Dante Artica   Creado
  ----------------------------------------------------------------------------*/  
 PROCEDURE sp_lista_adjuntos_anteriores
  ( p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
END PKG_SWEB_CRED_SOLI_DOCUMENTO;
