create or replace PACKAGE    VENTA.PKG_SWEB_CRED_SOLI_ACTIVIDAD AS
 PROCEDURE sp_list_acti
 (
    p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_act_actual        OUT vve_cred_maes_acti.des_acti_cred%TYPE,
    p_act_siguiente     OUT vve_cred_maes_acti.des_acti_cred%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
 );  

    /********************************************************************************
    Nombre:     sp_actu_acti
    Proposito:  Actualiza la fecha de ejecución de la etapa, si todas sus activiades han sido ejecutadas
    Referencias:
    Parametros: p_cod_soli_cred          ---> Código de la solicitud de crédito.
                p_etapa                  ---> Etapa correspondiente a la actividad ejecutada.
                p_acti                   ---> Actividad ejecutada
                P_COD_USUA_SID           ---> Código del usuario.
                P_RET_ESTA               ---> Código de estado resultante del procedure.
                P_RET_MENS               ---> Mensaje de estado resultante del procedure.


    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        12/06/2019  AVILCA        Creación del procedure.
  ********************************************************************************/ 
 PROCEDURE sp_actu_acti
 (      
     p_cod_soli_cred   IN   vve_cred_soli.cod_soli_cred%TYPE,
     p_etapa           IN   VARCHAR2, 
     p_acti            IN   VARCHAR2,
     p_cod_usua_sid    IN   sistemas.usuarios.co_usuario%TYPE,
     p_ret_esta        OUT  NUMBER,
     p_ret_mens        OUT  VARCHAR2
 );
END PKG_SWEB_CRED_SOLI_ACTIVIDAD; 
