create or replace PACKAGE VENTA.PKG_SWEB_CRED_SOLI_EVENTO AS
/********************************************************************************
  Nombre:     SP_REGLAS_NEGOCIO_FV
  Proposito:  Valida las reglas del negocio de la ficha de venta.
  Referencias:
  Parametros: p_cod_item_even_refe  ---> Codigo Item de Referencia del Evento Padre,
              p_cod_soli_cred       ---> Codigo de Solicitud de Credito,
              p_txt_asun            ---> Asunto del mensaje relacionado al Evento,
              p_txt_comen           ---> Comentario del mensaje relacionado al Evento,
              p_cod_usua_sid        ---> Identificador del usuario,
              p_cod_usua_web        ---> Codigo del Usuario,  
              p_cod_item_even       ---> Codigo autogenerado del Evento,
              P_RET_ESTA            ---> Estado del proceso,
              P_RET_MENS            ---> Resultado del proceso.

  REVISIONES:
  Version    Fecha       Autor            Descripcion
  ---------  ----------  ---------------  ------------------------------------
  1.0         29/11/2018  EGONZALES           Creación del procedure.
  *********************************************************************************/
  PROCEDURE sp_inse_cred_soli_even 
  (
    p_cod_item_even_refe   IN vve_cred_soli_even.cod_item_even_refe%TYPE,
    p_cod_soli_cred        IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_txt_asun             IN vve_cred_soli_even.txt_asun%TYPE,
    p_txt_comen            IN vve_cred_soli_even.txt_comen%TYPE,
    p_list_cod_usu         IN VARCHAR2,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,  
    p_ret_cod_item_even        OUT vve_cred_soli_even.cod_item_even%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
   );
    /********************************************************************************
      Nombre:     SP_LIST_CRED_SOLI_EVEN
      Proposito:  Lista los mensajes relacionados a los eventos.
      Referencias:
      Parametros: P_COD_ITEM_EVEN       ---> Codigo de Evento
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         29/11/2018  EGONZALES           Creación del procedure.
  *********************************************************************************/
    FUNCTION fu_list_cred_soli_dest
    (
        p_cod_item_even IN vve_cred_soli_even.cod_item_even%TYPE
    )
    RETURN VARCHAR2;
    /********************************************************************************
      Nombre:     SP_LIST_CRED_SOLI_EVEN
      Proposito:  Lista los mensajes relacionados a los eventos.
      Referencias:
      Parametros: P_COD_SOLI_CRED       ---> Codigo de Solicitud de Credito,
                  P_RET_ESTA            ---> Estado del proceso,
                  P_RET_MENS            ---> Resultado del proceso.
    
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         29/11/2018  EGONZALES           Creación del procedure.
  *********************************************************************************/
  PROCEDURE sp_list_cred_soli_even 
    (
        p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
        p_fec_item_even_ini IN VARCHAR2,
        p_fec_item_even_fin IN VARCHAR2,
        p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ind_paginado   IN VARCHAR2,
        p_limitinf       IN INTEGER,
        p_limitsup       IN INTEGER, 
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_cantidad      OUT NUMBER,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    );
 
  PROCEDURE sp_gen_plantilla_correo_even
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_gen_plantilla_correo_aprob
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_asunto_input      IN VARCHAR2,
    p_cuerpo_input      IN VARCHAR2,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_gen_plant_correo_soli_apro
  (
    p_cod_soli_cred     IN      vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_clie          IN      vve_cred_soli.cod_clie%TYPE,
    p_id_usuario        IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correo        OUT     NUMBER,
    p_ret_esta          OUT     NUMBER,
    p_ret_mens          OUT     VARCHAR2
  );
  
  PROCEDURE sp_gen_plant_correo_apro_usu
  (
    p_cod_soli_cred     IN      vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_clie          IN      vve_cred_soli.cod_clie%TYPE,
    p_estado            IN      VARCHAR2,
    p_observacion       IN      VARCHAR2,    
    p_id_usuario        IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correo        OUT     NUMBER,
    p_ret_esta          OUT     NUMBER,
    p_ret_mens          OUT     VARCHAR2
  );
  
  PROCEDURE sp_inse_correo
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
    p_copia             IN vve_correo_prof.copia%TYPE,
    p_asunto            IN vve_correo_prof.asunto%TYPE,
    p_cuerpo            IN vve_correo_prof.cuerpo%TYPE,
    p_correoorigen      IN vve_correo_prof.correoorigen%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN vve_correo_prof.tipo_ref_proc%TYPE,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_obtener_plantilla
  (
    p_cod_cor_prof  IN vve_correo_prof.cod_correo_prof%TYPE,
    p_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correos   OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
  );
  
  PROCEDURE sp_actualizar_envio
  (
    p_cod_cor_prof      IN vve_correo_prof.cod_correo_prof%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_list_docu_soli
  (
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  PROCEDURE sp_gen_plant_vcto_seguro
  (
    p_dias_consulta     IN NUMBER,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
   PROCEDURE sp_gen_plant_correo_ope_lxc
  (
    p_cod_soli_cred     IN      vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_clie          IN      vve_cred_soli.cod_clie%TYPE,
    p_id_usuario        IN      sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_correo        OUT     NUMBER,
    p_ret_esta          OUT     NUMBER,
    p_ret_mens          OUT     VARCHAR2
  );
  
   /********************************************************************************
      Nombre:     SP_LIST_EVEN_NOTARIA
      Proposito:  Lista los eventos notaria.
      Referencias:
      Parametros: p_cod_oper_rel        ---> Codigo de Evento
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         16/04/2020  EBARBOZA           Creación del procedure.
  *********************************************************************************/
  
  PROCEDURE SP_LIST_EVEN_NOTARIA
  (
    p_cod_oper_rel      IN vve_cred_soli.cod_oper_rel%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  
  /********************************************************************************
      Nombre:     sp_inse_even_notaria
      Proposito:  Insertar eventos notaria.
      Referencias:
      Parametros: p_txt_nro_contrato		--> codigo del evento que se registra,
                  p_fec_susc_cont			--> fecha del evento del documento contratos,
                  p_fec_susc_anex			--> fecha del evento del documento anexos,
                  p_fec_susc_letr			--> fecha del evento del documento letras,
                  p_fec_susc_gara			--> fecha del evento del documento garantias,
                  p_fec_susc_aval			--> fecha del evento del documento avales,
                  p_cod_estado			--> estado en que cambia el tramite, estado legalizado ES09,
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         21/04/2020  EBARBOZA           Creación del procedure.
  *********************************************************************************/
  
  PROCEDURE sp_inse_even_notaria (
        p_cod_soli_cred         IN vve_cred_soli.cod_soli_cred%TYPE,
        p_cod_oper_rel          IN vve_cred_soli.cod_oper_rel%TYPE,
        p_txt_nro_contrato      IN vve_cred_soli.txt_nro_contrato%TYPE,
        p_fec_susc_cont			IN VARCHAR2,
        p_fec_susc_anex			IN VARCHAR2,
        p_fec_susc_letr			IN VARCHAR2,
        p_fec_susc_gara			IN VARCHAR2,
        p_fec_susc_aval			IN VARCHAR2,
        p_cod_estado			IN vve_cred_soli.cod_estado%TYPE,
        p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_cod_item_even    OUT vve_cred_soli_even.cod_item_even%TYPE,
        p_ret_esta             OUT NUMBER,
        p_ret_mens             OUT VARCHAR2
    );
    
    /********************************************************************************
      Nombre:     sp_gene_plan_evento_notaria
      Proposito:  Generar Planilla para correo evento notaria.
      Referencias:
      Parametros: p_cod_soli_cred		--> Numero de la solicitus de  creadito que la genero,
                  p_cod_oper_rel			--> Numero de la operacion de la solicitud que la genero,
                  p_cod_usua_sid			--> Usuario que realizo el procedimiento,
                  p_cod_usua_web			--> Usuario que realizo el procedimiento,
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         21/04/2020  EBARBOZA           Creación del procedure.
  *********************************************************************************/
     PROCEDURE sp_gene_plan_evento_notaria
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_cod_oper_rel      IN vve_cred_soli.cod_oper_rel%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_correo        OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
END PKG_SWEB_CRED_SOLI_EVENTO;