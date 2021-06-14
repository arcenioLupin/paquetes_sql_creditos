create or replace PACKAGE VENTA.PKG_SWEB_CRED_SOLI_ACTIVIDAD AS
 PROCEDURE sp_list_acti
 (
    --p_cod_soli_cred     IN vve_cred_fina_docu.cod_soli_cred%TYPE,  --<CC E2.1 ID225 LR 11.11.19>
    p_cod_soli_cred     IN vve_cred_soli.cod_soli_cred%TYPE,         --<CC E2.1 ID225 LR 11.11.19>
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_act_actual        OUT vve_cred_maes_activ.des_acti_cred%TYPE,  --<CC E2.1 ID225 LR 11.11.19>
    p_act_siguiente     OUT vve_cred_maes_activ.des_acti_cred%TYPE,  --<CC E2.1 ID225 LR 11.11.19>
   -- p_act_actual        OUT vve_cred_maes_acti.des_acti_cred%TYPE, --<CC E2.1 ID225 LR 11.11.19>
   -- p_act_siguiente     OUT vve_cred_maes_acti.des_acti_cred%TYPE, --<CC E2.1 ID225 LR 11.11.19>    
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
 
 /********************************************************************************
    Nombre:     sp_list_actividad_etapa
    Proposito:  Lista las actividades y las etapas
    Referencias:
    Parametros: p_cod_acti_cred    --> Filtro de Actividades,        
                p_cod_etap_cred    --> Filtro de Etapa,        
                p_cod_usua_sid     --> Codigo del Usuario,
                p_cod_usua_web      --> ID del Usuario,
                p_act_actual        --> Numero de pagina Actual, 
                p_act_siguiente     --> Numero de pagina Siguiente, 
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        24/04/2020  EBARBOZA        Creación del procedure.
  ********************************************************************************/ 
 PROCEDURE sp_list_actividad_etapa
 (
    p_cod_acti_cred    IN vve_cred_maes_activ.cod_acti_cred%TYPE,        
    p_cod_etap_cred    IN vve_cred_maes_activ.cod_etap_cred%TYPE,        
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_act_actual        OUT vve_cred_maes_activ.des_acti_cred%TYPE, 
    p_act_siguiente     OUT vve_cred_maes_activ.des_acti_cred%TYPE, 
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
 );
 
 /********************************************************************************
    Nombre:     sp_list_actividad_all
    Proposito:  Lista las actividades 
    Referencias:
    Parametros:       
                p_cod_usua_sid     --> Codigo del Usuario,
                p_cod_usua_web      --> ID del Usuario,
                p_act_actual        --> Numero de pagina Actual, 
                p_act_siguiente     --> Numero de pagina Siguiente, 
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        24/04/2020  EBARBOZA        Creación del procedure.
  ********************************************************************************/

    PROCEDURE sp_list_actividad_all (
       p_cod_usua_sid    IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_act_actual      OUT vve_cred_maes_activ.des_acti_cred%TYPE,
        p_act_siguiente   OUT vve_cred_maes_activ.des_acti_cred%TYPE,
        p_ret_cursor      OUT SYS_REFCURSOR,
        p_ret_cantidad    OUT NUMBER,
        p_ret_esta        OUT NUMBER,
        p_ret_mens        OUT VARCHAR2
    );
    
    /********************************************************************************
    Nombre:     sp_inser_acti_etapa
    Proposito:  Registrar una nueva actividad o etapa para el mantenimiento
    Referencias:
    Parametros: p_cod_acti_cred          	 IN 	vve_cred_maes_activ.cod_acti_cred%TYPE,
        p_cod_etap_cred          	 IN 	vve_cred_maes_activ.cod_etap_cred%TYPE,
        p_des_acti_cred          	 IN 	vve_cred_maes_activ.des_acti_cred%TYPE,
        p_ind_inactivo          	 IN 	vve_cred_maes_activ.ind_inactivo%TYPE,
        p_cod_estado_soli          	 IN 	vve_cred_maes_activ.cod_estado_soli%TYPE,
        p_num_orden          		 IN 	vve_cred_maes_activ.num_orden%TYPE,
        p_fec_crea_regi         	 IN 	vve_cred_maes_activ.fec_crea_regi%TYPE,
        p_cod_usua_crea_regi         IN 	vve_cred_maes_activ.cod_usua_crea_regi%TYPE,
        p_fec_modi_regi          	 IN 	vve_cred_maes_activ.fec_modi_regi%TYPE,
        p_cod_usua_modi_regi         IN 	vve_cred_maes_activ.cod_usua_modi_regi%TYPE,


    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        06/05/2020  EBARBOZA        Creación del procedure.
  ********************************************************************************/
  
  PROCEDURE sp_inser_acti_etapa (
        p_cod_acti_cred          	 IN 	vve_cred_maes_activ.cod_acti_cred%TYPE,
        p_cod_etap_cred          	 IN 	vve_cred_maes_activ.cod_etap_cred%TYPE,
        p_des_acti_cred          	 IN 	vve_cred_maes_activ.des_acti_cred%TYPE,
        p_ind_inactivo          	 IN 	vve_cred_maes_activ.ind_inactivo%TYPE,
        p_cod_estado_soli          	 IN 	vve_cred_maes_activ.cod_estado_soli%TYPE,
        p_num_orden          		 IN 	vve_cred_maes_activ.num_orden%TYPE,
        p_fec_crea_regi         	 IN 	VARCHAR2,
        p_cod_usua_crea_regi         IN 	vve_cred_maes_activ.cod_usua_crea_regi%TYPE,
        p_fec_modi_regi          	 IN 	VARCHAR2,
        p_cod_usua_modi_regi         IN 	vve_cred_maes_activ.cod_usua_modi_regi%TYPE,
        p_ret_esta                   OUT     NUMBER,
        p_ret_mens                   OUT     VARCHAR2
    );
    
    /********************************************************************************
    Nombre:     sp_actu_orden_activ
    Proposito:  Actualizar el actividades para el mantenimiento
    Referencias:
    Parametros: p_cod_acti_cred          	 IN 	vve_cred_maes_activ.cod_acti_cred%TYPE,
        p_num_orden          		 IN 	vve_cred_maes_activ.num_orden%TYPE,
        p_ret_esta                   OUT     NUMBER,
        p_ret_mens                   OUT     VARCHAR2


    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        08/05/2020  EBARBOZA        Creación del procedure.
  ********************************************************************************/
   PROCEDURE sp_actu_activ (
        p_cod_acti_cred				IN 	VVE_CRED_MAES_ACTIV.cod_acti_cred%TYPE,
        p_cod_etap_cred				IN 	VVE_CRED_MAES_ACTIV.cod_etap_cred%TYPE,
        p_des_acti_cred				IN 	VVE_CRED_MAES_ACTIV.des_acti_cred%TYPE,
        p_ind_inactivo				IN 	VVE_CRED_MAES_ACTIV.ind_inactivo%TYPE,
        p_cod_estado_soli			IN 	VVE_CRED_MAES_ACTIV.cod_estado_soli%TYPE,
        p_num_orden					IN 	VVE_CRED_MAES_ACTIV.num_orden%TYPE,
        p_fec_crea_regi				IN 	VVE_CRED_MAES_ACTIV.fec_crea_regi%TYPE,
        p_cod_usua_crea_regi		IN 	VVE_CRED_MAES_ACTIV.cod_usua_crea_regi%TYPE,	
        p_fec_modi_regi				IN 	VVE_CRED_MAES_ACTIV.fec_modi_regi%TYPE,
        p_cod_usua_modi_regi		IN 	VVE_CRED_MAES_ACTIV.cod_usua_modi_regi%TYPE,
        p_ret_esta                   OUT     NUMBER,
        p_ret_mens                   OUT     VARCHAR2
    );
    
    /********************************************************************************
    Nombre:     sp_actu_activ_tipo_cred
    Proposito:  Actualizar las actividades con tipo credito para el mantenimiento
    Referencias:
    Parametros:  p_cod_acti_cred			IN  vve_cred_acti_tipo_cred.cod_acti_cred%TYPE,
        p_cod_tipo_cred			IN  vve_cred_acti_tipo_cred.cod_tipo_cred%TYPE,
        p_ind_inactivo			IN  vve_cred_acti_tipo_cred.ind_inactivo%TYPE,
        p_ind_oblig				IN  vve_cred_acti_tipo_cred.ind_oblig%TYPE,
        p_cod_usua          	IN  vve_cred_acti_tipo_cred.cod_usua_modi_regi%TYPE,
        p_ret_esta                   OUT     NUMBER,
        p_ret_mens                   OUT     VARCHAR2
    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        10/05/2020  EBARBOZA        Creación del procedure.
  ********************************************************************************/
    PROCEDURE sp_actu_activ_tipo_cred (
        p_cod_acti_cred			IN  vve_cred_acti_tipo_cred.cod_acti_cred%TYPE,
        p_cod_tipo_cred			IN  vve_cred_acti_tipo_cred.cod_tipo_cred%TYPE,
        p_ind_inactivo			IN  vve_cred_acti_tipo_cred.ind_inactivo%TYPE,
        p_ind_oblig				IN  vve_cred_acti_tipo_cred.ind_oblig%TYPE,
        p_cod_usua          	IN  vve_cred_acti_tipo_cred.cod_usua_modi_regi%TYPE,
        p_ret_esta                   OUT     NUMBER,
        p_ret_mens                   OUT     VARCHAR2
    );
    
    /*
    -- BUSQUEDA DE ACTIVIDADES ETAPAS Y TIPO DE CREDITO MBARDALES
    */
    PROCEDURE sp_busqueda_act_eta_tip_cred
    (
      p_cod_acti_cred    IN VARCHAR2,        
      p_cod_etap_cred    IN VARCHAR2,  
      p_cod_tipo_cred    IN VARCHAR2, 
      p_cod_usua_sid     IN sistemas.usuarios.co_usuario%TYPE,
      p_cod_usua_web     IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE, 
      p_ret_cursor       OUT SYS_REFCURSOR,
      p_ret_cantidad     OUT NUMBER,
      p_ret_esta         OUT NUMBER,
      p_ret_mens         OUT VARCHAR2
    );
    
END PKG_SWEB_CRED_SOLI_ACTIVIDAD;