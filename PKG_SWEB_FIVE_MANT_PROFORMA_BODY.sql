create or replace PACKAGE BODY  VENTA.PKG_SWEB_FIVE_MANT_PROFORMA AS

  /*-----------------------------------------------------------------------------
    Nombre : SP_LIST_PROF_ASIG_FICHA
    Proposito : Lista las proformas asociadas una ficha de venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    11/05/2017   AVILCA         Creacion
    20/10/2017   MEGUILUZ       Req. 84611 Notificacion PROF y FDV
    20/11/2017   BPALACIOS      Sprint 4 Ficha de venta
	12/11/2018   SOPORTE LEGADOS Req. 86268 Modificacion de visualizacion de FV
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_prof_asig_ficha
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_proforma_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_proforma_veh.num_prof_veh%TYPE,
    p_co_usuario        IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS

  v_ano_fabricacion varchar2(6); --<86268 soporte legados- variable para guardar el año de fabricacion>--

  BEGIN

    --<I-86268 obteniendo el año de fabricación>
    /*
     BEGIN  
      SELECT
           DISTINCT  vpv.ano_fabricacion_veh
        INTO  v_ano_fabricacion   
        FROM vve_pedido_veh a, v_pedido_veh vpv, vve_ficha_vta_pedido_veh z
       WHERE a.num_pedido_veh = vpv.num_pedido_veh
         AND a.cod_cia = vpv.cod_cia
         AND a.cod_prov = vpv.cod_prov
         AND a.num_pedido_veh = z.num_pedido_veh
         AND a.cod_cia = z.cod_cia
         AND a.cod_prov = z.cod_prov
         AND nvl(z.ind_inactivo, 'N') = 'N'
         AND z.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND (p_num_prof_veh IS NULL OR z.num_prof_veh = p_num_prof_veh);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_ano_fabricacion :=NULL;
     END;  
     */    
     --<F-86268 obteniendo el año de fabricación>

    OPEN p_ret_cursor FOR
      SELECT pv.num_ficha_vta_veh,
             pv.nur_ficha_vta_prof,
             pv.num_prof_veh,
             pv.ind_prenda,
             pv.ind_soli_capacitacion,
             pv.cod_color_veh,
             pv.des_color_veh,
             pc.cod_tipo_importacion,
             ti.des_tipo_importacion,
             pd.cod_familia_veh,
             fv.des_familia_veh,
             pd.cod_marca,
             gm.nom_marca,
             pd.cod_baumuster,
             pkg_sweb_mae_gene.fu_desc_modelo_eett(pd.cod_familia_veh,
                                              pd.cod_marca,
                                             pd.cod_baumuster,
                                             pd.cod_config_veh) des_baumuster,--CAMBIOS POR REQUERIMIENTO 90585 EBARBOZA 12 07 2020,
             pd.cod_config_veh,
             cv.des_config_veh,
             pd.cod_tipo_veh,
             vt.des_tipo_veh,
             pd.can_veh,
             pd.val_vta_veh,
             pd.val_pre_veh,
             pd.can_veh * pd.val_pre_veh total,
             pd.cod_prov,
             pv.cod_avta_fam_uso,
             pc.cod_area_vta,
             pc.cod_filial,
             cv.sku_sap
             --<I 84611>
            ,
             pc.fec_crea_reg    AS fech_crea,
             pc.cod_moneda_prof AS tipo_mone,
             pd.val_dcto_veh    AS valo_desc
             --, (PD.CAN_VEH*PD.VAL_PRE_VEH)/1.18 - PD.VAL_DCTO_VEH AS VALO_NETO
            ,
             pd.val_vtn_veh AS valo_neto
             --<F 84611>
            ,
             pc.fec_crea_reg AS fech_tentativa , -- FECHA TENTATIVA
             nvl(v_ano_fabricacion,'')  ano_fabricacion_veh --< 86268 año de fabricacion

        FROM venta.vve_proforma_veh           pc,
             venta.vve_proforma_veh_det       pd,
             venta.vve_tipo_importacion       ti,
             venta.vve_familia_veh            fv,
             generico.gen_marca               gm,
             venta.vve_baumuster              bm,
             venta.vve_config_veh             cv,
             venta.vve_tipo_veh               vt,
             venta.vve_ficha_vta_proforma_veh pv
       WHERE pc.num_prof_veh = pd.num_prof_veh(+)
         AND pc.cod_tipo_importacion = ti.cod_tipo_importacion(+)
         AND pd.cod_familia_veh = fv.cod_familia_veh(+)
         AND pd.cod_marca = gm.cod_marca(+)
         AND pd.cod_familia_veh = bm.cod_familia_veh(+)
         AND pd.cod_marca = bm.cod_marca(+)
         AND pd.cod_baumuster = bm.cod_baumuster(+)
         AND pd.cod_familia_veh = cv.cod_familia_veh(+)
         AND pd.cod_marca = cv.cod_marca(+)
         AND pd.cod_baumuster = cv.cod_baumuster(+)
         AND pd.cod_config_veh = cv.cod_config_veh(+)
         AND pd.cod_tipo_veh = vt.cod_tipo_veh(+)
         AND pv.num_prof_veh = pc.num_prof_veh(+)
            --<I 84611>
         AND pv.num_ficha_vta_veh =
             nvl(p_num_ficha_vta_veh, pv.num_ficha_vta_veh)
            --<F 84611>
         AND pc.num_prof_veh = nvl(p_num_prof_veh, pc.num_prof_veh)
         AND pv.ind_inactivo = 'N'
       ORDER BY pc.fec_prof_veh DESC;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PROF_FICH',
                                          p_co_usuario,
                                          'Error al listar las proformas de ficha la ficha de venta',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);

  END;

  /*-----------------------------------------------------------------------------
  Nombre : SP_LIST_PROF_FICHA_VENTA
  Proposito : Lista las proformas que coinciden con los campos de ficha de venta
  Referencias :
  Parametros :
  Log de Cambios
    Fecha        Autor         Descripcion
    11/05/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
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
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT pc.cod_cia,
             pc.cod_area_vta,
             pc.cod_sucursal,
             pc.cod_filial,
             pc.num_prof_veh,
             pc.vendedor,
             pc.cod_clie,
             pc.cod_estado_prof,
             pc.cod_tipo_pago
        FROM venta.vve_proforma_veh     pc,
             venta.vve_proforma_veh_det pd,
             venta.vve_tipo_importacion ti,
             venta.vve_familia_veh      fv,
             generico.gen_marca         gm,
             venta.vve_baumuster        bm,
             venta.vve_config_veh       cv,
             venta.vve_tipo_veh         vt
       WHERE pc.num_prof_veh = pd.num_prof_veh(+)
         AND pc.cod_cia = p_cod_cia
         AND pc.cod_area_vta = p_cod_area_vta
         AND pc.cod_clie = p_cod_clie
         AND pc.cod_filial = p_cod_filial
         AND pc.vendedor = p_cod_vendedor
         AND pc.cod_tipo_importacion = ti.cod_tipo_importacion(+)
         AND pd.cod_familia_veh = fv.cod_familia_veh(+)
         AND pd.cod_marca = gm.cod_marca(+)
         AND pd.cod_familia_veh = bm.cod_familia_veh(+)
         AND pd.cod_marca = bm.cod_marca(+)
         AND pd.cod_baumuster = bm.cod_baumuster(+)
         AND pd.cod_familia_veh = cv.cod_familia_veh(+)
         AND pd.cod_marca = cv.cod_marca(+)
         AND pd.cod_baumuster = cv.cod_baumuster(+)
         AND pd.cod_config_veh = cv.cod_config_veh(+)
         AND pd.cod_tipo_veh = vt.cod_tipo_veh(+);

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PROF_FICHA_VENTA',
                                          p_cod_id_usuario,
                                          'Error al listar proformas de ficha',
                                          p_ret_mens,
                                          p_cod_cia);
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_ACTU_PROF_FICHA
     Proposito : Actualiza datos de la proforma en la ficha de venta
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     14/04/2017   AVILCA        Creacion
  ----------------------------------------------------------------------------*/
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
  ) AS
  BEGIN
    UPDATE venta.vve_ficha_vta_proforma_veh
       SET num_ficha_vta_veh     = p_num_ficha_vta_veh,
           num_prof_veh          = p_num_prof_veh,
           num_soli_cred_veh     = p_num_soli_cred_veh,
           ind_prenda            = p_ind_prenda,
           ind_soli_capacitacion = p_ind_soli_capacitacion,
           ind_inactivo          = p_ind_inactivo,
           co_usuario_inactiva   = p_co_usuario_inactiva,
           fec_inactiva          = p_fec_inactiva,
           cod_perso_dir         = p_cod_perso_dir,
           num_reg_dir           = p_num_reg_dir,
           cod_perso_usu         = p_cod_perso_usu,
           num_reg_usu           = p_num_reg_usu,
           cod_contac_clie       = p_cod_contac_clie,
           cod_contac_usu        = p_cod_contac_usu,
           tipo_carrocero        = p_tipo_carrocero,
           nom_carrocero         = p_nom_carrocero,
           nom_lugar_entrega     = p_nom_lugar_entrega,
           fec_entrega_aprox     = p_fec_entrega_aprox,
           cod_doc_fact          = p_cod_doc_fact,
           ind_sol_fact          = p_ind_sol_fact,
           cod_color_veh         = p_cod_color_veh,
           cod_perso_prop        = p_cod_perso_prop,
           num_reg_prop          = p_num_reg_prop,
           cod_contac_prop       = p_cod_contac_prop,
           des_color_veh         = p_des_color_veh,
           obs_facturacion       = p_obs_facturacion,
           cod_color_veh_ant     = p_cod_color_veh_ant,
           cod_avta_fam_uso      = p_cod_avta_fam_uso,
           co_usuario_crea_reg   = p_cod_usua_web,
           fec_crea_reg          = SYSDATE
     WHERE num_prof_veh = p_num_prof_veh
       AND num_ficha_vta_veh = p_num_ficha_vta_veh;

    COMMIT;

    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTU_PROF_FICHA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_PROF_FICHA',
                                          p_cod_id_usuario,
                                          'ALCTUALIZA condiciones',
                                          p_ret_mens,
                                          p_num_prof_veh);
      ROLLBACK;
  END;

  /*-----------------------------------------------------------------------------
    Nombre : SP_INSE_PROF_FICHA
    Proposito : Inserta proforma en la ficha de venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    12/05/2017   AVILCA         Creacion
  ---------------------------------------------------------------------------*/
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
  ) AS
    v_num_reg_nur_ficha_prof NUMBER;

    v_tem_mens VARCHAR2(4000);
    v_tem_retu NUMBER(10);

  BEGIN
    SAVEPOINT a;
    SELECT nvl(MAX(a.nur_ficha_vta_prof), 0)
      INTO v_num_reg_nur_ficha_prof
      FROM venta.vve_ficha_vta_proforma_veh a
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;

    v_num_reg_nur_ficha_prof := v_num_reg_nur_ficha_prof + 1;

    INSERT INTO venta.vve_ficha_vta_proforma_veh
      (num_ficha_vta_veh,
       nur_ficha_vta_prof,
       num_prof_veh,
       num_soli_cred_veh,
       ind_prenda,
       ind_soli_capacitacion,
       ind_inactivo,
       co_usuario_inactiva,
       fec_inactiva,
       cod_perso_dir,
       num_reg_dir,
       cod_perso_usu,
       num_reg_usu,
       cod_contac_clie,
       cod_contac_usu,
       tipo_carrocero,
       nom_carrocero,
       nom_lugar_entrega,
       fec_entrega_aprox,
       cod_doc_fact,
       ind_sol_fact,
       cod_color_veh,
       cod_perso_prop,
       num_reg_prop,
       cod_contac_prop,
       des_color_veh,
       obs_facturacion,
       cod_color_veh_ant,
       cod_avta_fam_uso,
       co_usuario_crea_reg,
       fec_crea_reg)
    VALUES
      (p_num_ficha_vta_veh,
       v_num_reg_nur_ficha_prof,
       p_num_prof_veh,
       p_num_soli_cred_veh,
       p_ind_prenda,
       p_ind_soli_capacitacion,
       'N',
       p_co_usuario_inactiva,
       p_fec_inactiva,
       p_cod_perso_dir,
       p_num_reg_dir,
       p_cod_perso_usu,
       p_num_reg_usu,
       p_cod_contac_clie,
       p_cod_contac_usu,
       p_tipo_carrocero,
       p_nom_carrocero,
       p_nom_lugar_entrega,
       p_fec_entrega_aprox,
       p_cod_doc_fact,
       p_ind_sol_fact,
       p_cod_color_veh,
       p_cod_perso_prop,
       p_num_reg_prop,
       p_cod_contac_prop,
       p_des_color_veh,
       p_obs_facturacion,
       p_cod_color_veh_ant,
       p_cod_avta_fam_uso,
       p_cod_id_usuario,
       SYSDATE)
    RETURNING nur_ficha_vta_prof INTO v_num_reg_nur_ficha_prof;

    COMMIT;

    BEGIN
      --envia datos a CRM
      pkg_sweb_gest_five.sp_envi_five_crm(p_num_ficha_vta_veh,
                       'CREACION FIVE',
                       p_cod_id_usuario,
                       NULL,
                       v_tem_retu,
                       v_tem_mens);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    BEGIN
      --envia datos a CRM
      pkg_sweb_vta_prof_proc.sp_envi_prof_crm(p_num_prof_veh,
                                              'ASOCIAR FIVE',
                                              p_cod_id_usuario,
                                              NULL,
                                              v_tem_retu,
                                              v_tem_mens);
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;

    --<I 84952>      
    DECLARE
      vestado      VARCHAR2(30);
      v_log_error1 VARCHAR2(4000);
    BEGIN
      --se realiza la invocacion del sp del servicio bpm bonita
      pkg_sid_tree_bpm.sp_crear_fv_veh_bpm(p_num_ficha_vta_veh,
                                           p_num_prof_veh,
                                           '',
                                           '',
                                           '',
                                           p_cod_id_usuario,
                                           vestado);

    EXCEPTION
      WHEN OTHERS THEN
        v_log_error1 := SQLERRM;
        pkg_factu_elect.regi_rlog_erro('SP_CREA_FICH_PROF',
                                       v_log_error1,
                                       p_num_prof_veh,
                                       NULL);
    END;

    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_PEDI',
                                          p_cod_id_usuario,
                                          'numProf:' || p_num_prof_veh ||
                                          '-v_num_reg_nur_ficha_prof:' ||
                                          v_num_reg_nur_ficha_prof,
                                          p_ret_mens,
                                          p_num_prof_veh);
      ROLLBACK;
  END;
  /*-----------------------------------------------------------------------------
     Nombre : SP_GRABAR_PROF_FICHA_VENTA
     Proposito : Graba proforma relacionada a la ficha
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     12/05/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
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
  ) AS

    ve_error EXCEPTION;
    v_existe INTEGER;
  BEGIN
    SELECT COUNT(*)
      INTO v_existe
      FROM venta.vve_ficha_vta_proforma_veh a
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND a.num_prof_veh = p_num_prof_veh;

    IF v_existe > 0 THEN

      sp_actu_prof_ficha(p_num_ficha_vta_veh,
                         p_num_prof_veh,
                         p_num_soli_cred_veh,
                         p_ind_prenda,
                         p_ind_soli_capacitacion,
                         p_ind_inactivo,
                         p_co_usuario_inactiva,
                         p_fec_inactiva,
                         p_cod_perso_dir,
                         p_num_reg_dir,
                         p_cod_perso_usu,
                         p_num_reg_usu,
                         p_cod_contac_clie,
                         p_cod_contac_usu,
                         p_tipo_carrocero,
                         p_nom_carrocero,
                         p_nom_lugar_entrega,
                         p_fec_entrega_aprox,
                         p_cod_doc_fact,
                         p_ind_sol_fact,
                         p_cod_color_veh,
                         p_cod_perso_prop,
                         p_num_reg_prop,
                         p_cod_contac_prop,
                         p_des_color_veh,
                         p_obs_facturacion,
                         p_cod_color_veh_ant,
                         p_cod_avta_fam_uso,
                         p_cod_id_usuario,
                         p_cod_usua_web,
                         p_ret_esta,
                         p_ret_mens);

      IF (p_ret_esta <> 1) THEN
        RAISE ve_error;
      END IF;
    ELSE
      sp_inse_prof_ficha(p_num_ficha_vta_veh,
                         p_num_prof_veh,
                         p_num_soli_cred_veh,
                         p_ind_prenda,
                         p_ind_soli_capacitacion,
                         p_ind_inactivo,
                         p_co_usuario_inactiva,
                         p_fec_inactiva,
                         p_cod_perso_dir,
                         p_num_reg_dir,
                         p_cod_perso_usu,
                         p_num_reg_usu,
                         p_cod_contac_clie,
                         p_cod_contac_usu,
                         p_tipo_carrocero,
                         p_nom_carrocero,
                         p_nom_lugar_entrega,
                         p_fec_entrega_aprox,
                         p_cod_doc_fact,
                         p_ind_sol_fact,
                         p_cod_color_veh,
                         p_cod_perso_prop,
                         p_num_reg_prop,
                         p_cod_contac_prop,
                         p_des_color_veh,
                         p_obs_facturacion,
                         p_cod_color_veh_ant,
                         p_cod_avta_fam_uso,
                         p_cod_id_usuario,
                         p_ret_esta,
                         p_ret_mens);

      IF (p_ret_esta <> 1) THEN
        RAISE ve_error;
      END IF;
    END IF;

    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN

      p_ret_esta := -1;
      p_ret_mens := 'SP_GUARDA_PROF_FICHA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GRABAR_PROF_FICH',
                                          p_cod_id_usuario,
                                          'Graba condiciones',
                                          p_ret_mens,
                                          p_num_prof_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_PROF_PEDI_FICHA
      Proposito : Lista las proformas asociadas que ya ha sido asignada a una
                ficha de venta
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      15/05/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_prof_pedi_ficha
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_prof_veh      IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT p.num_prof_veh,
             num_reg_det_prof,
             f.ind_prenda,
             f.cod_perso_dir,
             f.num_reg_dir,
             f.cod_perso_usu,
             f.num_reg_usu,
             f.cod_contac_clie,
             f.cod_contac_usu,
             f.tipo_carrocero,
             f.nom_carrocero,
             f.nom_lugar_entrega,
             f.fec_entrega_aprox,
             f.cod_doc_fact,
             f.ind_sol_fact,
             f.cod_color_veh,
             f.cod_perso_prop,
             f.num_reg_prop,
             f.cod_contac_prop,
             f.des_color_veh,
             f.obs_facturacion,
             cv.sku_sap,
             pd.cod_familia_veh,
             pd.cod_marca,
             pd.cod_baumuster

        FROM venta.vve_proforma_veh           p,
             venta.vve_proforma_veh_det       pd,
             venta.vve_ficha_vta_proforma_veh f,
             venta.vve_config_veh             cv
       WHERE p.num_prof_veh = pd.num_prof_veh
         AND p.num_prof_veh = f.num_prof_veh
         AND f.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND p.num_prof_veh = p_num_prof_veh
         AND nvl(f.ind_inactivo, 'N') = 'N'
         AND pd.cod_familia_veh = cv.cod_familia_veh(+)
         AND pd.cod_marca = cv.cod_marca(+)
         AND pd.cod_baumuster = cv.cod_baumuster(+)
         AND pd.cod_config_veh = cv.cod_config_veh(+);

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PROF_PEDI_FICHA',
                                          NULL,
                                          'Error al listar proformas de ficha',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_PROF
      Proposito : Lista las proformas asociadas a una ficha de venta
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      24/05/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_prof
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_prof_veh      IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR
      SELECT num_ficha_vta_veh,
             num_prof_veh,
             cod_moneda_prof,
             ind_inactivo,
             num_reg_det_prof,
             cod_marca,
             nom_marca,
             cod_baumuster,
             des_baumuster,
             cod_familia_veh,
             cod_config_veh,
             des_config_veh,
             can_veh,
             val_vta_veh,
             val_dcto_veh,
             val_vtn_veh,
             val_pre_veh

        FROM venta.v_ficha_vta_proforma_veh
       WHERE nvl(ind_inactivo, 'N') = 'N'
         AND num_prof_veh = p_num_prof_veh
         AND num_ficha_vta_veh = p_num_ficha_vta_veh;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PROF',
                                          NULL,
                                          'Error al listar las proformas',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*--------------------------------------------------------------------------
      Nombre : SP_LIST_CAPA_FICHA_VENTA
      Proposito : Lista las capacitaciones asociadas a la ficha de venta
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      01/06/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_capa_ficha_venta
  (
    p_num_ficha_vta_veh  IN vve_soli_cap_veh.num_ficha_vta_veh%TYPE,
    p_nur_ficha_vta_prof IN vve_soli_cap_veh.nur_ficha_vta_prof%TYPE,
    p_num_prof_veh       IN vve_soli_cap_veh.num_prof_veh%TYPE,
    p_cod_id_usuario     IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor         OUT SYS_REFCURSOR,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR

      SELECT num_horario_cap,
             cod_area_vta,
             cod_familia_veh,
             cod_marca,
             cod_clase_veh,
             cod_baumuster,
             fec_horario_cap,
             fec_hora_ini,
             fec_hora_fin,
             cod_cap_veh,
             co_usuario_inst,
             nom_lugar_cap,
             nro_participantes,
             cod_estado_horario,
             obs_horario_cap,
             obs_horario_anul,
             ind_inactivo,
             fec_horario_cap_fin,
             des_objetivos,
             val_nota_base,
             des_capacitacion,
             cod_modalidad_capa,
             cod_dpto,
             cod_capaci
        FROM venta.vve_horario_cap
       WHERE nvl(ind_inactivo, 'N') = 'N'
         AND num_horario_cap IN
             (SELECT d.num_horario_cap
                FROM venta.vve_horario_cap_det d
               WHERE nvl(d.ind_inactivo, 'N') = 'N'
                 AND d.num_soli_cap_veh IN
                     (SELECT s.num_soli_cap_veh
                        FROM venta.vve_soli_cap_veh s
                       WHERE s.num_ficha_vta_veh = p_num_ficha_vta_veh
                         AND s.num_prof_veh = p_num_prof_veh
                         AND s.nur_ficha_vta_prof = p_nur_ficha_vta_prof
                         AND nvl(s.ind_inactivo, 'N') = 'N'
                       GROUP BY s.num_soli_cap_veh))
       ORDER BY num_horario_cap;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_CAPA_FICH',
                                          p_cod_id_usuario,
                                          'Error al listar las capacitaciones',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_INACTIVA_PROF_FICHA
     Proposito :  Des asignar la proforma en la ficha de venta
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     15/06/2017   AVILCA        Creacion
     23/01/2018   LQS           modificacion : validar la elimnacion de proformas 
  ----------------------------------------------------------------------------*/
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
  ) AS
    ve_error EXCEPTION;
    vn_exist_pedido NUMBER;

  BEGIN
    -- Verificamos si existen pedidos asociados a  la proforma en ela ficha de venta
    SELECT COUNT(*)
      INTO vn_exist_pedido
      FROM venta.v_ficha_vta_pedido_veh vve_ficha_vta_pedido_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
       AND num_prof_vehf = p_num_prof_veh
       AND ind_inactivo = 'N';

    IF vn_exist_pedido > 0 THEN
      p_ret_mens := 'La Proforma tiene pedidos asociados, no se puede desasignar de la ficha de venta.';
      p_ret_esta := 0;

    END IF;

    IF (vn_exist_pedido = 0) THEN
      UPDATE venta.vve_ficha_vta_proforma_veh
         SET ind_inactivo        = 'S',
             co_usuario_inactiva = p_co_usuario_inactiva,
             fec_inactiva        = SYSDATE
       WHERE num_prof_veh = p_num_prof_veh
         AND num_ficha_vta_veh = p_num_ficha_vta_veh;

      COMMIT;

      p_ret_mens := 'Se inactivo correctamente la proforma de la ficha de venta';
      p_ret_esta := 1;
    END IF;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_INACTIVA_PROF_FICHA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INACTIVA_PROF_FICHA',
                                          p_cod_id_usuario,
                                          'Inactiva proforma en ficha de venta',
                                          p_ret_mens,
                                          p_num_prof_veh);
      ROLLBACK;
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_LIST_PROF_NOFV
     Proposito :  busca proformas que no se encuentren relacionadas a ficha de venta
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     01/08/2017   LVALDERRAMA   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_prof_nofv
  (
    p_num_prof_veh IN vve_proforma_veh.num_prof_veh%TYPE,
    p_nom_perso    IN gen_persona.nom_perso%TYPE,
    p_cod_estados  IN VARCHAR,
    p_co_usuario   IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR
  ) AS
    v_query VARCHAR2(10000);
    v_where VARCHAR2(10000);
    v_order VARCHAR2(10000);
  BEGIN
    v_query := 'SELECT P.NUM_PROF_VEH,
                   P.COD_CLIE,
                   G.NOM_PERSO,
                   P.COD_FILIAL,
                   P.COD_AREA_VTA,
                   PD.COD_MARCA,
                   PD.COD_FAMILIA_VEH
            FROM VVE_PROFORMA_VEH P
            INNER JOIN GEN_PERSONA G
            ON P.COD_CLIE = G.COD_PERSO
            INNER JOIN VVE_PROFORMA_VEH_DET PD
            ON P.NUM_PROF_VEH = PD.NUM_PROF_VEH
            WHERE G.IND_INACTIVO = ''N''
            AND NOT EXISTS(
              SELECT ''X''
              FROM VVE_FICHA_VTA_PROFORMA_VEH V
              WHERE V.NUM_PROF_VEH = P.NUM_PROF_VEH
                AND V.IND_INACTIVO = ''N''
            ) AND ';

    v_where := v_where ||
               ' EXISTS(SELECT 1
                                   FROM SISTEMAS.SIS_VIEW_USUA_PORG U,
                                        SISTEMAS.SIS_VIEW_PORG_AREA A
                                   WHERE U.COD_ID_PERFIL_ORG = A.COD_ID_PERFIL_ORG
                                    AND A.COD_AREA_VTA = P.COD_AREA_VTA
                                    AND U.TXT_USUARIO = ''' ||
               p_co_usuario || ''')';

    IF p_nom_perso IS NOT NULL THEN
      v_where := v_where || ' AND UPPER(G.NOM_PERSO) LIKE ''%' ||
                 upper(p_nom_perso) || '%''';
    END IF;

    IF p_num_prof_veh IS NOT NULL THEN
      v_where := v_where || ' AND P.NUM_PROF_VEH LIKE ''%' ||
                 p_num_prof_veh || '%''';
    END IF;

    IF p_cod_estados IS NOT NULL THEN
      v_where := v_where || ' AND P.COD_ESTADO_PROF IN (' ||
                 upper(p_cod_estados) || ')';
    END IF;

    v_query := v_query || v_where;

    v_order := ' ORDER BY P.NUM_PROF_VEH DESC ';

    v_query := v_query || v_order;
    --PKG_SWEB_FICHA_VENTA_LARRY.CUSTOM_OUTPUT(V_QUERY);
    OPEN p_ret_cursor FOR v_query;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PROF_NOFV',
                                          p_co_usuario,
                                          'Error al listar las proformas que no tienen ficha de venta',
                                          p_ret_mens,
                                          NULL);
  END;
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
  ) AS
    ve_error EXCEPTION;
    v_query    VARCHAR2(4000);
    c_codchek  SYS_REFCURSOR;
    v_cod_chek VARCHAR2(4);
  BEGIN
    IF p_cod_chek IS NULL OR p_cod_chek = '' THEN
      p_ret_mens := 'Debe Ingresar al menos un Codigo de Check';
      RAISE ve_error;
    END IF;
    IF p_cod_chek IS NOT NULL THEN
      v_query := 'SELECT CODCHEK.COD_CHEK  FROM VVE_MANT_CHEK_AVTA CODCHEK WHERE CODCHEK.COD_AREA_VTA=' ||
                 p_cod_area_vta || ' AND CODCHEK.COD_CHEK IN (' ||
                 p_cod_chek || ')';
    END IF;
    OPEN c_codchek FOR v_query;
    LOOP
      FETCH c_codchek
        INTO v_cod_chek;
      EXIT WHEN c_codchek%NOTFOUND;

      INSERT INTO vve_five_prof_chek
        (cod_five_prof_chek,
         num_ficha_vta_veh,
         num_prof_veh,
         cod_chek,
         cod_area_vta,
         ind_inactivo,
         fec_crea_reg,
         cod_usuario_crea)
      VALUES
        (seq_vve_five_prof_chek.nextval,
         p_num_ficha_vta_veh,
         p_num_prof_veh,
         v_cod_chek,
         p_cod_area_vta,
         'N',
         SYSDATE,
         p_cod_usua_web);
    END LOOP;
    CLOSE c_codchek;

    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;
    COMMIT;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
      ROLLBACK;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_CHEK_PROF_FIVE',
                                          p_cod_usua_sid,
                                          'Error al insertar check en la proforma',
                                          p_ret_mens);
  END;
  /*-----------------------------------------------------------------------------
    Nombre : SP_INSE_COLO_PROF_FIVE
    Proposito : Inserta color asociado a una proforma en la ficha de venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor         Descripcion
    30/05/2017   JFLORESM      Creacion
    19/09/2017   JFLORESM      Modificacion de sp
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
  ) AS
    ve_error EXCEPTION;

    v_query   VARCHAR2(4000);
    c_codcolr SYS_REFCURSOR;
    v_cod_col VARCHAR2(4);
  BEGIN
    IF p_cod_colo IS NULL OR p_cod_colo = '' THEN
      p_ret_mens := 'Debe Ingresar al menos un Codigo de Color';
      RAISE ve_error;
    END IF;
    IF p_cod_colo IS NOT NULL THEN
      v_query := 'SELECT COLR.COD_COLOR_FABRICA_VEH FROM VVE_COLOR_FABRICA_VEH COLR  WHERE COLR.COD_COLOR_FABRICA_VEH IN (' ||
                 p_cod_colo || ')';
    END IF;

    UPDATE vve_five_prof_colo t
       SET t.ind_inactivo = 'S'
     WHERE t.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND t.num_prof_veh = p_num_prof_veh;

    OPEN c_codcolr FOR v_query;
    LOOP
      FETCH c_codcolr
        INTO v_cod_col;
      EXIT WHEN c_codcolr%NOTFOUND;

      INSERT INTO vve_five_prof_colo
        (cod_five_prof_colo,
         num_ficha_vta_veh,
         cod_color_fabrica_veh,
         num_prof_veh,
         ind_inactivo,
         fec_crea_reg,
         cod_usuario_crea)
      VALUES
        (seq_vve_five_prof_colo.nextval,
         p_num_ficha_vta_veh,
         v_cod_col,
         p_num_prof_veh,
         'N',
         SYSDATE,
         p_cod_usua_web);
    END LOOP;
    CLOSE c_codcolr;

    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;
    COMMIT;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
      ROLLBACK;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_COLO_PROF_FIVE',
                                          p_cod_usua_sid,
                                          'Error al insertar color en la proforma',
                                          p_ret_mens);
  END;
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
  ) AS
    ve_error EXCEPTION;

  BEGIN
    IF p_num_colo = 0 THEN
      INSERT INTO vve_five_prof_colo
        (cod_five_prof_colo,
         num_ficha_vta_veh,
         cod_color_fabrica_veh,
         num_prof_veh,
         ind_inactivo,
         fec_crea_reg,
         cod_usuario_crea)
      VALUES
        (seq_vve_five_prof_colo.nextval,
         p_num_ficha_vta_veh,
         p_cod_color,
         p_num_prof_veh,
         'N',
         SYSDATE,
         p_cod_usua_web);
    ELSE
      UPDATE vve_five_prof_colo
         SET cod_color_fabrica_veh = p_cod_color,
             fec_modi_reg          = SYSDATE,
             cod_usuario_modi      = p_cod_usua_web
       WHERE cod_five_prof_colo = p_num_colo;
    END IF;

    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;
    COMMIT;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
      ROLLBACK;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_UPDA_COLO_PROF_FIVE',
                                          p_cod_usua_sid,
                                          'Error al actualizar color en la proforma',
                                          p_ret_mens);
  END;
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
  ) AS
    ve_error EXCEPTION;
  BEGIN

    IF p_num_chek = 0 THEN
      INSERT INTO vve_five_prof_chek
        (cod_five_prof_chek,
         num_ficha_vta_veh,
         num_prof_veh,
         cod_chek,
         cod_area_vta,
         ind_inactivo,
         fec_crea_reg,
         cod_usuario_crea)
      VALUES
        (seq_vve_five_prof_chek.nextval,
         p_num_ficha_vta_veh,
         p_num_prof_veh,
         p_cod_chek,
         p_cod_area_vta,
         'N',
         SYSDATE,
         p_cod_usua_web);
    ELSE
      IF p_ind_inactivo = 'Y' THEN
        UPDATE vve_five_prof_chek
           SET ind_inactivo = p_ind_inactivo
         WHERE cod_five_prof_chek = p_num_chek;
      ELSE
        UPDATE vve_five_prof_chek
           SET cod_chek         = p_cod_chek,
               fec_modi_reg     = SYSDATE,
               cod_usuario_modi = p_cod_usua_web,
               ind_inactivo     = p_ind_inactivo
         WHERE cod_five_prof_chek = p_num_chek;
      END IF;

    END IF;
    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;
    -- COMMIT;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
      -- ROLLBACK;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      -- ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_CHEK_PROF_FIVE',
                                          p_cod_usua_sid,
                                          'Error al actualizar check de proforma',
                                          p_ret_mens);
  END;
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
	   10/10/2018	FGRANDEZ	REQ-86364, se crea la variable p_lista para la
								condicional del listado.
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
  ) AS

  BEGIN
    IF p_lista IS NOT NULL THEN
       OPEN p_ret_cursor FOR
        SELECT codcolr.cod_five_prof_colo,
             codcolr.cod_color_fabrica_veh,
             descolr.des_color_fabrica_veh,
             descsunarp.cod_color_sunarp,
             descsunarp.des_color_sunarp
        FROM vve_five_prof_colo codcolr
       INNER JOIN vve_color_fabrica_veh descolr
          ON codcolr.cod_color_fabrica_veh = descolr.cod_color_fabrica_veh
       INNER JOIN vve_mov_color_sunarp descsunarp
          ON descsunarp.cod_color_sunarp = descolr.cod_color_sunarp
       WHERE codcolr.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND codcolr.num_prof_veh = p_num_prof_veh;
         --AND nvl(codcolr.ind_inactivo, 'N') = 'N';
     ELSE
       OPEN p_ret_cursor FOR
       SELECT codcolr.cod_five_prof_colo,
             codcolr.cod_color_fabrica_veh,
             descolr.des_color_fabrica_veh,
             descsunarp.cod_color_sunarp,
             descsunarp.des_color_sunarp
        FROM vve_five_prof_colo codcolr
       INNER JOIN vve_color_fabrica_veh descolr
          ON codcolr.cod_color_fabrica_veh = descolr.cod_color_fabrica_veh
       INNER JOIN vve_mov_color_sunarp descsunarp
          ON descsunarp.cod_color_sunarp = descolr.cod_color_sunarp
       WHERE codcolr.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND codcolr.num_prof_veh = p_num_prof_veh
         AND nvl(codcolr.ind_inactivo, 'N') = 'N';
     END IF;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_COLO_PROF_FIVE',
                                          p_cod_usua_sid,
                                          'Error al listar los colores de una proforma',
                                          p_ret_mens);
  END;

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
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR
      SELECT chekpro.cod_five_prof_chek,
             chekpro.cod_area_vta,
             chekarea.cod_chek,
             chekarea.des_chek
        FROM vve_five_prof_chek chekpro
       INNER JOIN vve_mant_chek chekarea
          ON chekarea.cod_chek = chekpro.cod_chek
       WHERE chekpro.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND chekpro.num_prof_veh = p_num_prof_veh
         AND nvl(chekpro.ind_inactivo, 'N') = 'N';

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_CHEK_PROF_FIVE',
                                          p_cod_usua_sid,
                                          'Error al listar los check de una proforma',
                                          p_ret_mens);
  END;

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
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR
      SELECT cod.cod_chek, des.des_chek, cod.ind_default
        FROM vve_mant_chek_avta cod
       INNER JOIN vve_mant_chek des
          ON cod.cod_chek = des.cod_chek
       WHERE cod.cod_area_vta = p_cod_area_vta
         AND nvl(cod.ind_inactivo, 'N') = 'N'
         AND nvl(des.ind_inactivo, 'N') = 'N';

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_CHEK_COND',
                                          p_cod_usua_sid,
                                          'Error al listar los check de la condicion para la proforma',
                                          p_ret_mens);
  END;

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
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT SUM(v.val_tot_equipo_local_veh) AS val_tot_equipo_local_veh

        FROM vve_prof_equipo_local_veh v, vve_equipo_local_veh e
       WHERE v.cod_equipo_local_veh = e.cod_equipo_local_veh
         AND v.val_equipo_local_veh > 0
         AND v.can_equipo_local_veh > 1
            --AND E.COD_TIPO_EQUIPO_LOCAL_VEH    = '94'
         AND v.num_prof_veh = p_num_prof_veh;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_OBTE_VALOR_TOTAL_BONO_PROF',
                                          NULL,
                                          'Error al obtener información de la suma total de bonos',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

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
  ) AS
    v_cod_five_bono NUMBER;
  BEGIN

    SELECT seq_vve_five_bono.nextval INTO v_cod_five_bono FROM dual;

    -- V_NUM_REG_NUR_FICHA_PROF := P_COD_FIVE_BONO + 1;

    INSERT INTO vve_five_bono
      (cod_five_bono,
       num_ficha_vta_veh,
       num_prof_veh,
       cod_tipo_bono,
       cod_moneda_bono,
       monto_total_bono,
       obs_bono,
       ind_inactivo,
       fec_crea_reg,
       cod_usuario_crea,
       fec_modi_reg,
       cod_usuario_modi)
    VALUES
      (v_cod_five_bono,
       p_num_ficha_vta_veh,
       p_num_prof_veh,
       p_cod_tipo_bono,
       p_cod_moneda_bono,
       p_monto_total_bono,
       p_obs_bono,
       'N',
       SYSDATE,
       p_cod_id_usuario,
       SYSDATE,
       p_cod_id_usuario);

    INSERT INTO vve_five_bono_vale
      (cod_vale_five_bono,
       cod_five_bono,
       num_ficha_vta_veh,
       num_prof_veh,
       can_vale_bono,
       monto_vale,
       monto_vale_total,
       cod_esta_vale,
       ind_inactivo,
       fec_crea_reg,
       cod_usuario_crea,
       fec_modi_reg,
       cod_usuario_modi)
    VALUES
      (v_cod_five_bono,
       v_cod_five_bono,
       p_num_ficha_vta_veh,
       p_num_prof_veh,
       p_can_vale_bono,
       p_monto_vale,
       p_monto_vale_total,
       'N',
       'N',
       SYSDATE,
       p_cod_id_usuario,
       SYSDATE,
       p_cod_id_usuario);

    INSERT INTO vve_five_bono_vehi
      (cod_vehi_five_bono,
       cod_five_bono,
       num_ficha_vta_veh,
       num_prof_veh,
       cod_cia,
       num_pedido_veh,
       cod_prov,
       ind_inactivo,
       fec_crea_reg,
       cod_usuario_crea,
       fec_modi_reg,
       cod_usuario_modi)
    VALUES
      (v_cod_five_bono,
       v_cod_five_bono,
       p_num_ficha_vta_veh,
       p_num_prof_veh,
       p_cod_cia,
       p_num_pedido_veh,
       p_cod_prov,
       'N',
       SYSDATE,
       p_cod_id_usuario,
       SYSDATE,
       p_cod_id_usuario);

    p_ret_mens := 'Se inserto correctamente';
    p_ret_esta := 1;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_PEDI',
                                          p_cod_id_usuario,
                                          'numProf:' || p_num_prof_veh ||
                                          '-v_num_reg_nur_ficha_prof:' ||
                                          v_cod_five_bono,
                                          p_ret_mens,
                                          p_num_prof_veh);
      ROLLBACK;

  END;

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
  ) AS
  BEGIN
    UPDATE vve_five_bono_vale
       SET cod_esta_vale      = p_cod_esta_vale,
           cod_usua_auto_vale = p_cod_usua_auto_vale,
           cod_usuario_modi   = p_cod_usua_sid,
           fec_modi_reg       = SYSDATE
     WHERE cod_five_bono = p_cod_five_bono
       AND num_prof_veh = p_num_prof_veh
       AND num_ficha_vta_veh = p_num_ficha_vta_veh;

    COMMIT;

    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTU_ESTADO_PROF_BONO_VALE:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_ESTADO_PROF_BONO_VALE',
                                          p_cod_usua_sid,
                                          'ALCTUALIZA condiciones',
                                          p_ret_mens,
                                          p_num_prof_veh);
      ROLLBACK;
  END;

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
  ) AS

    v_where       VARCHAR(2000);
    v_query       VARCHAR(2000);
    v_query_final VARCHAR(2000);
    v_final       VARCHAR2(10000);
  BEGIN

    v_query := 'SELECT  A.COD_FIVE_BONO,
              A.NUM_FICHA_VTA_VEH,
              A.NUM_PROF_VEH,
              A.COD_MONEDA_BONO,
              A.MONTO_TOTAL_BONO,
              A.OBS_BONO,
              B.CAN_VALE_BONO,
              B.MONTO_VALE,
              B.MONTO_VALE_TOTAL,
              B.COD_ESTA_VALE,
              B.COD_USUA_AUTO_VALE,
              B.FEC_AUTO_VALE,
              C.COD_CIA,
              C.COD_PROV,
              C.NUM_PEDIDO_VEH
  FROM  VVE_FIVE_BONO A,
        VVE_FIVE_BONO_VALE B,
        VVE_FIVE_BONO_VEHI C
  WHERE A.COD_FIVE_BONO = B.COD_FIVE_BONO
        AND B.COD_FIVE_BONO = C.COD_FIVE_BONO ';

    IF p_num_ficha_vta_veh IS NOT NULL AND p_num_ficha_vta_veh <> '' THEN
      v_where := v_where || ' AND  A.NUM_FICHA_VTA_VEH = ' ||
                 p_num_ficha_vta_veh || '';
    END IF;

    v_query_final := v_query || v_where;

    v_final := 'SELECT * FROM (' || v_final || ') X ';
    v_final := 'SELECT ROWNUM RM, X.* FROM (' || v_query_final || ') X ';

    OPEN p_ret_cursor FOR v_final;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LISTAR_PEDIDOS_BONOS',
                                          NULL,
                                          'Error al obtener información de la suma total de bonos',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);

  END;

END PKG_SWEB_FIVE_MANT_PROFORMA; 
