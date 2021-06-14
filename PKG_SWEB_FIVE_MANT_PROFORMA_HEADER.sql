create or replace PACKAGE       VENTA.PKG_SWEB_FIVE_MANT_PROFORMA AS
  /* TODO enter package declarations (types, exceptions, methods etc) here */
  PROCEDURE sp_list_prof_asig_ficha
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_proforma_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_co_usuario        IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  PROCEDURE sp_list_prof_ficha_venta
  (
    p_cod_cia        IN vve_proforma_veh.cod_cia%TYPE,
    p_cod_area_vta   IN vve_proforma_veh.cod_area_vta%TYPE,
    p_num_pedido_veh IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_clie       IN vve_proforma_veh.cod_clie%TYPE,
    p_cod_filial     IN vve_proforma_veh.cod_filial%TYPE,
    p_cod_vendedor   IN vve_proforma_veh.vendedor%TYPE,
    p_cod_id_usuario IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR
  );

  PROCEDURE sp_actu_prof_ficha
  (
    p_num_ficha_vta_veh     IN vve_ficha_vta_proforma_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh          IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_num_soli_cred_veh     IN vve_ficha_vta_proforma_veh.num_soli_cred_veh%TYPE,
    p_ind_prenda            IN vve_ficha_vta_proforma_veh.ind_prenda%TYPE,
    p_ind_soli_capacitacion IN vve_ficha_vta_proforma_veh.ind_soli_capacitacion%TYPE,
    p_ind_inactivo          IN vve_ficha_vta_proforma_veh.ind_inactivo%TYPE,
    p_co_usuario_inactiva   IN vve_ficha_vta_proforma_veh.co_usuario_inactiva%TYPE,
    p_fec_inactiva          IN vve_ficha_vta_proforma_veh.fec_inactiva%TYPE,
    p_cod_perso_dir         IN vve_ficha_vta_proforma_veh.cod_perso_dir%TYPE,
    p_num_reg_dir           IN vve_ficha_vta_proforma_veh.num_reg_dir%TYPE,
    p_cod_perso_usu         IN vve_ficha_vta_proforma_veh.cod_perso_usu%TYPE,
    p_num_reg_usu           IN vve_ficha_vta_proforma_veh.num_reg_usu%TYPE,
    p_cod_contac_clie       IN vve_ficha_vta_proforma_veh.cod_contac_clie%TYPE,
    p_cod_contac_usu        IN vve_ficha_vta_proforma_veh.cod_contac_usu%TYPE,
    p_tipo_carrocero        IN vve_ficha_vta_proforma_veh.tipo_carrocero%TYPE,
    p_nom_carrocero         IN vve_ficha_vta_proforma_veh.nom_carrocero%TYPE,
    p_nom_lugar_entrega     IN vve_ficha_vta_proforma_veh.nom_lugar_entrega%TYPE,
    p_fec_entrega_aprox     IN vve_ficha_vta_proforma_veh.fec_entrega_aprox%TYPE,
    p_cod_doc_fact          IN vve_ficha_vta_proforma_veh.cod_doc_fact%TYPE,
    p_ind_sol_fact          IN vve_ficha_vta_proforma_veh.ind_sol_fact%TYPE,
    p_cod_color_veh         IN vve_ficha_vta_proforma_veh.cod_color_veh%TYPE,
    p_cod_perso_prop        IN vve_ficha_vta_proforma_veh.cod_perso_prop%TYPE,
    p_num_reg_prop          IN vve_ficha_vta_proforma_veh.num_reg_prop%TYPE,
    p_cod_contac_prop       IN vve_ficha_vta_proforma_veh.cod_contac_prop%TYPE,
    p_des_color_veh         IN vve_ficha_vta_proforma_veh.des_color_veh%TYPE,
    p_obs_facturacion       IN vve_ficha_vta_proforma_veh.obs_facturacion%TYPE,
    p_cod_color_veh_ant     IN vve_ficha_vta_proforma_veh.cod_color_veh_ant%TYPE,
    p_cod_avta_fam_uso      IN vve_ficha_vta_proforma_veh.cod_avta_fam_uso%TYPE,
    p_cod_id_usuario        IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web          IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR2
  );

  PROCEDURE sp_inse_prof_ficha
  (
    p_num_ficha_vta_veh     IN vve_ficha_vta_proforma_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh          IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_num_soli_cred_veh     IN vve_ficha_vta_proforma_veh.num_soli_cred_veh%TYPE,
    p_ind_prenda            IN vve_ficha_vta_proforma_veh.ind_prenda%TYPE,
    p_ind_soli_capacitacion IN vve_ficha_vta_proforma_veh.ind_soli_capacitacion%TYPE,
    p_ind_inactivo          IN vve_ficha_vta_proforma_veh.ind_inactivo%TYPE,
    p_co_usuario_inactiva   IN vve_ficha_vta_proforma_veh.co_usuario_inactiva%TYPE,
    p_fec_inactiva          IN vve_ficha_vta_proforma_veh.fec_inactiva%TYPE,
    p_cod_perso_dir         IN vve_ficha_vta_proforma_veh.cod_perso_dir%TYPE,
    p_num_reg_dir           IN vve_ficha_vta_proforma_veh.num_reg_dir%TYPE,
    p_cod_perso_usu         IN vve_ficha_vta_proforma_veh.cod_perso_usu%TYPE,
    p_num_reg_usu           IN vve_ficha_vta_proforma_veh.num_reg_usu%TYPE,
    p_cod_contac_clie       IN vve_ficha_vta_proforma_veh.cod_contac_clie%TYPE,
    p_cod_contac_usu        IN vve_ficha_vta_proforma_veh.cod_contac_usu%TYPE,
    p_tipo_carrocero        IN vve_ficha_vta_proforma_veh.tipo_carrocero%TYPE,
    p_nom_carrocero         IN vve_ficha_vta_proforma_veh.nom_carrocero%TYPE,
    p_nom_lugar_entrega     IN vve_ficha_vta_proforma_veh.nom_lugar_entrega%TYPE,
    p_fec_entrega_aprox     IN vve_ficha_vta_proforma_veh.fec_entrega_aprox%TYPE,
    p_cod_doc_fact          IN vve_ficha_vta_proforma_veh.cod_doc_fact%TYPE,
    p_ind_sol_fact          IN vve_ficha_vta_proforma_veh.ind_sol_fact%TYPE,
    p_cod_color_veh         IN vve_ficha_vta_proforma_veh.cod_color_veh%TYPE,
    p_cod_perso_prop        IN vve_ficha_vta_proforma_veh.cod_perso_prop%TYPE,
    p_num_reg_prop          IN vve_ficha_vta_proforma_veh.num_reg_prop%TYPE,
    p_cod_contac_prop       IN vve_ficha_vta_proforma_veh.cod_contac_prop%TYPE,
    p_des_color_veh         IN vve_ficha_vta_proforma_veh.des_color_veh%TYPE,
    p_obs_facturacion       IN vve_ficha_vta_proforma_veh.obs_facturacion%TYPE,
    p_cod_color_veh_ant     IN vve_ficha_vta_proforma_veh.cod_color_veh_ant%TYPE,
    p_cod_avta_fam_uso      IN vve_ficha_vta_proforma_veh.cod_avta_fam_uso%TYPE,
    p_cod_id_usuario        IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR2
  );

  PROCEDURE sp_grabar_prof_ficha_venta
  (
    p_num_ficha_vta_veh     IN vve_ficha_vta_proforma_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh          IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_num_soli_cred_veh     IN vve_ficha_vta_proforma_veh.num_soli_cred_veh%TYPE,
    p_ind_prenda            IN vve_ficha_vta_proforma_veh.ind_prenda%TYPE,
    p_ind_soli_capacitacion IN vve_ficha_vta_proforma_veh.ind_soli_capacitacion%TYPE,
    p_ind_inactivo          IN vve_ficha_vta_proforma_veh.ind_inactivo%TYPE,
    p_co_usuario_inactiva   IN vve_ficha_vta_proforma_veh.co_usuario_inactiva%TYPE,
    p_fec_inactiva          IN vve_ficha_vta_proforma_veh.fec_inactiva%TYPE,
    p_cod_perso_dir         IN vve_ficha_vta_proforma_veh.cod_perso_dir%TYPE,
    p_num_reg_dir           IN vve_ficha_vta_proforma_veh.num_reg_dir%TYPE,
    p_cod_perso_usu         IN vve_ficha_vta_proforma_veh.cod_perso_usu%TYPE,
    p_num_reg_usu           IN vve_ficha_vta_proforma_veh.num_reg_usu%TYPE,
    p_cod_contac_clie       IN vve_ficha_vta_proforma_veh.cod_contac_clie%TYPE,
    p_cod_contac_usu        IN vve_ficha_vta_proforma_veh.cod_contac_usu%TYPE,
    p_tipo_carrocero        IN vve_ficha_vta_proforma_veh.tipo_carrocero%TYPE,
    p_nom_carrocero         IN vve_ficha_vta_proforma_veh.nom_carrocero%TYPE,
    p_nom_lugar_entrega     IN vve_ficha_vta_proforma_veh.nom_lugar_entrega%TYPE,
    p_fec_entrega_aprox     IN vve_ficha_vta_proforma_veh.fec_entrega_aprox%TYPE,
    p_cod_doc_fact          IN vve_ficha_vta_proforma_veh.cod_doc_fact%TYPE,
    p_ind_sol_fact          IN vve_ficha_vta_proforma_veh.ind_sol_fact%TYPE,
    p_cod_color_veh         IN vve_ficha_vta_proforma_veh.cod_color_veh%TYPE,
    p_cod_perso_prop        IN vve_ficha_vta_proforma_veh.cod_perso_prop%TYPE,
    p_num_reg_prop          IN vve_ficha_vta_proforma_veh.num_reg_prop%TYPE,
    p_cod_contac_prop       IN vve_ficha_vta_proforma_veh.cod_contac_prop%TYPE,
    p_des_color_veh         IN vve_ficha_vta_proforma_veh.des_color_veh%TYPE,
    p_obs_facturacion       IN vve_ficha_vta_proforma_veh.obs_facturacion%TYPE,
    p_cod_color_veh_ant     IN vve_ficha_vta_proforma_veh.cod_color_veh_ant%TYPE,
    p_cod_avta_fam_uso      IN vve_ficha_vta_proforma_veh.cod_avta_fam_uso%TYPE,
    p_cod_id_usuario        IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web          IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR2
  );

  PROCEDURE sp_list_prof_pedi_ficha
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_prof_veh      IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  PROCEDURE sp_list_prof
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_prof_veh      IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

  PROCEDURE sp_list_capa_ficha_venta
  (
    p_num_ficha_vta_veh  IN vve_soli_cap_veh.num_ficha_vta_veh%TYPE,
    p_nur_ficha_vta_prof IN vve_soli_cap_veh.nur_ficha_vta_prof%TYPE,
    p_num_prof_veh       IN vve_soli_cap_veh.num_prof_veh%TYPE,
    p_cod_id_usuario     IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor         OUT SYS_REFCURSOR,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR
  );

  PROCEDURE sp_inactiva_prof_ficha
  (
    p_num_ficha_vta_veh   IN vve_ficha_vta_proforma_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh        IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_ind_inactivo        IN vve_ficha_vta_proforma_veh.ind_inactivo%TYPE,
    p_co_usuario_inactiva IN vve_ficha_vta_proforma_veh.co_usuario_inactiva%TYPE,
    p_cod_id_usuario      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta            OUT NUMBER,
    p_ret_mens            OUT VARCHAR2
  );

  PROCEDURE sp_list_prof_nofv
  (
    p_num_prof_veh IN vve_proforma_veh.num_prof_veh%TYPE,
    p_nom_perso    IN gen_persona.nom_perso%TYPE,
    p_cod_estados  IN VARCHAR,
    p_co_usuario   IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR
  );
  /*-----------------------------------------------------------------------------
    Nombre : SP_INSE_CHEK_PROF_FIVE
    Proposito : Inserta check asociado a una proforma en la ficha de venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    19/09/2017   GUCORREA      Creacion
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_inse_chek_prof_five
  (
    p_num_ficha_vta_veh IN vve_five_prof_colo.num_ficha_vta_veh%TYPE,
    p_cod_chek          IN VARCHAR2,
    p_cod_area_vta      IN gen_area_vta.cod_area_vta%TYPE,
    p_num_prof_veh      IN vve_five_prof_colo.num_prof_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  /*-----------------------------------------------------------------------------
    Nombre : SP_INSE_COLO_PROF_FIVE
    Proposito : Inserta color asociado a una proforma en la ficha de venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    30/05/2017   JFLORESM      Creacion
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_inse_colo_prof_five
  (
    p_num_ficha_vta_veh IN vve_five_prof_colo.num_ficha_vta_veh%TYPE,
    p_cod_colo          IN VARCHAR2,
    p_num_prof_veh      IN vve_five_prof_colo.num_prof_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  /*-----------------------------------------------------------------------------
    Nombre : SP_ACTU_COLO_PROF_FIVE
    Proposito : Actualiza color asociado a una proforma en la ficha de venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    20/09/2017   GUCORREA      Actualizar
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_actu_colo_prof_five
  (
    p_num_colo          IN vve_five_prof_colo.cod_five_prof_colo%TYPE,
    p_num_ficha_vta_veh IN vve_five_prof_colo.num_ficha_vta_veh%TYPE,
    p_cod_color         IN vve_five_prof_colo.cod_color_fabrica_veh%TYPE,
    p_num_prof_veh      IN vve_five_prof_colo.num_prof_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  /*-----------------------------------------------------------------------------
    Nombre : SP_ACTU_CHEK_PROF_FIVE
    Proposito : Actualiza check asociado a una proforma en la ficha de venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    20/09/2017   GUCORREA      Actualizar
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_actu_chek_prof_five
  (
    p_num_chek          IN vve_five_prof_chek.cod_five_prof_chek%TYPE,
    p_num_ficha_vta_veh IN vve_five_prof_chek.num_ficha_vta_veh%TYPE,
    p_cod_chek          IN vve_five_prof_chek.cod_chek%TYPE,
    p_cod_area_vta      IN gen_area_vta.cod_area_vta%TYPE,
    p_num_prof_veh      IN vve_five_prof_chek.num_prof_veh%TYPE,
    p_ind_inactivo      IN vve_five_prof_chek.ind_inactivo%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );
  /*--------------------------------------------------------------------------
       Nombre : SP_LIST_COLO_PROF_FIVE
       Proposito : Listado de colores asociados a una proforma
       Referencias :
       Parametros : P_NUM_FICHA_VTA_VEH ---> Código de ficha de venta.
                    P_NUM_PROF_VEH    ---> Código de proforma.
                    P_COD_USUA_SID    ---> Código del Usuario
                    P_RET_CURSOR      ---> Resultado de la busqueda.
                    P_RET_ESTA        ---> Estado del proceso.
                    P_RET_MENS        ---> Resultado del proceso.
       Log de Cambios
       Fecha        Autor         Descripcion
       19/09/2017   GUCORREA     Creación del procedure
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_colo_prof_five
  (
    p_num_ficha_vta_veh IN vve_five_prof_colo.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_five_prof_colo.num_prof_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR,
	p_lista             IN VARCHAR2 DEFAULT NULL
  );

  /*--------------------------------------------------------------------------
       Nombre : SP_LIST_CHEK_PROF_FIVE
       Proposito : Listado de checks de condicion,  asociados a una proforma
       Referencias :
       Parametros : P_NUM_FICHA_VTA_VEH ---> Código de ficha de venta.
                    P_NUM_PROF_VEH    ---> Código de proforma.
                    P_COD_USUA_SID    ---> Código del Usuario
                    P_RET_CURSOR      ---> Resultado de la busqueda.
                    P_RET_ESTA        ---> Estado del proceso.
                    P_RET_MENS        ---> Resultado del proceso.
       Log de Cambios
       Fecha        Autor         Descripcion
       19/09/2017   GUCORREA     Creación del procedure
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_chek_prof_five
  (
    p_num_ficha_vta_veh IN vve_five_prof_colo.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_five_prof_colo.num_prof_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );
  /*--------------------------------------------------------------------------
       Nombre : SP_LIST_CHEK_COND
       Proposito : Listado de check para la condicion de ficha de venta
       Referencias :
       Parametros : P_COD_AREA_VTA    ---> Código de área de venta.
                    P_COD_USUA_SID    ---> Código del Usuario
                    P_RET_CURSOR      ---> Resultado de la busqueda.
                    P_RET_ESTA        ---> Estado del proceso.
                    P_RET_MENS        ---> Resultado del proceso.
       Log de Cambios
       Fecha        Autor         Descripcion
       18/09/2017   GUSTAVO.CORREA     Creación del procedure
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_chek_cond
  (
    p_cod_area_vta IN VARCHAR2,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR
  );

  /*-----------------------------------------------------------------------------
    Nombre : SP_OBTE_VALOR_TOTAL_BONO_PROF
    Proposito : Obtiene la suma total del bono asociado a una proforma.
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    21/11/2017   BPALACIOS     Actualizar
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_obte_valor_total_bono_prof
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_prof_veh      IN VARCHAR2,
    --P_RET_VALOR_TOTAL      OUT VARCHAR,
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  );

  /*-----------------------------------------------------------------------------
   Nombre : SP_INSE_PEDIDOS_BONOS
   Proposito : registra la solicitud de facturacion de un pedido en tránsito
   Referencias :
   Parametros :
   Log de Cambios
   Fecha        Autor         Descripcion
   20/11/2017   BPALACIOS     Se crea el metodo para insertar en las tablas
                              de bonos de los pedidos.
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_inse_pedidos_bonos
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.cod_cia%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_cod_tipo_bono     IN vve_five_bono.cod_tipo_bono%TYPE,
    p_cod_chek          IN VARCHAR2,
    p_cod_moneda_bono   IN vve_five_bono.cod_moneda_bono%TYPE,
    p_monto_total_bono  IN vve_five_bono.monto_total_bono%TYPE,
    p_obs_bono          IN vve_five_bono.obs_bono%TYPE,
    p_can_vale_bono     IN vve_five_bono_vale.can_vale_bono%TYPE,
    p_monto_vale        IN vve_five_bono_vale.monto_vale%TYPE,
    p_monto_vale_total  IN vve_five_bono_vale.monto_vale_total%TYPE,
    p_cod_cia           IN vve_five_bono_vehi.cod_cia%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_id_usuario    IN NUMBER,
    p_cod_prov          IN vve_five_bono_vehi.cod_prov%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  );

  /*-----------------------------------------------------------------------------
    Nombre : SP_ACTU_ESTADO_PROF_BONO_VALE
    Proposito : Actualiza el estado de pendiente a confirmado del estado
                 del Bono Vale.
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    20/11/2017   BPALACIOS     Actualizar
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_actu_estado_prof_bono_vale
  (
    p_cod_five_bono      IN vve_five_bono_vale.cod_five_bono%TYPE,
    p_num_ficha_vta_veh  IN vve_five_prof_chek.num_ficha_vta_veh%TYPE,
    p_num_prof_veh       IN vve_five_prof_chek.num_prof_veh%TYPE,
    p_cod_esta_vale      IN vve_five_bono_vale.cod_esta_vale%TYPE,
    p_cod_usua_auto_vale IN vve_five_bono_vale.cod_usua_auto_vale%TYPE,
    p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  );

  /*-----------------------------------------------------------------------------
    Nombre : SP_LISTAR_BONOS_FICHA
    Proposito : Obtiene la lista de ls bonos asociado a una proforma.
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    30/11/2017   BPALACIOS     Listar bonos
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_listar_bonos_ficha
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  );

END PKG_SWEB_FIVE_MANT_PROFORMA; 