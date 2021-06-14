create or replace PACKAGE BODY   VENTA.pkg_sweb_five_mant_pedido AS
  /******************************************************************************
     NAME:    PKG_SWEB_VVE_RESE_VEHI
     PURPOSE: Contiene funciones de OPERACIONES con proforma tipo aceptar, crear, etc..

     REVISIONS:
     Ver        Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     10.0        18/06/2018  acruz            req.86227  reserva DC y Lineup
     11.         11/07/2018  garroyo          req.86330  corregir asigancion con alerta a line up
     12          06/08/2018  SOPORTELEGADOS   REQ-86491 Modificacion el armado del cursor p_ret_cursor
     13          28/09/2018  SOPORTELEGADOS   REQ 86868 Lista ordenado los colores de los pedidos
  ******************************************************************************/

  k_val_s CONSTANT VARCHAR2(1) := 'S';

  PROCEDURE sp_list_pedi_pedi_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT z.num_ficha_vta_veh,
             a.num_prof_veh,
             a.num_pedido_veh,
             vpv.num_vin num_chasis,
             vpv.ano_fabricacion_veh,
             a.cod_color_veh,
             (SELECT col.des_color_fabrica_veh
                FROM vve_color_fabrica_veh col
               WHERE a.cod_color_veh = col.cod_color_fabrica_veh) des_color_veh,
             vpv.des_situ_pedido,
             vpv.des_ubica_pedido_veh,
             vpv.sku_sap,
             a.cod_cia,
             a.cod_prov,
             a.num_motor_veh,
             z.fec_crea_reg,
             --<REQ-86366>
             (SELECT gp.cod_clie
                FROM cxc.cxc_mae_clie gp
               WHERE gp.cod_clie = a.cod_clie) cod_cliente,
             (SELECT gp.cod_clie
                FROM cxc.cxc_mae_clie gp
               WHERE gp.cod_clie = a.cod_propietario_veh) cod_propietario_veh,
             --<REQ-86366>
             (SELECT gp.nom_clie
                FROM cxc.cxc_mae_clie gp
               WHERE gp.cod_clie = a.cod_clie) des_cliente,
             z.nur_ficha_vta_pedido,
             (SELECT des_estado_pedido
                FROM vve_estado_pedido
               WHERE cod_estado_pedido = a.cod_estado_pedido_veh) est_pedido,

             pkg_sweb_five_mant_pedido.fn_ind_desaduanaje(z.cod_cia,
                                                          z.cod_prov,
                                                          z.num_pedido_veh) ind_correo_aduana,
             (SELECT COUNT(1)
                FROM vve_pedido_veh a
               WHERE a.cod_ubica_pedido_veh IN
                     ((SELECT cod_ubica_pedido
                        FROM vve_ubica_pedido
                       WHERE upper(des_ubica_pedido) LIKE '%WARRA%'))
                 AND a.num_pedido_veh = z.num_pedido_veh
                 AND a.cod_cia = z.cod_cia
                 AND a.cod_prov = z.cod_prov) ind_correo_warrant,
             z.fec_compro_entrega,
             '1' ind_fech_aprob

        FROM vve_pedido_veh a, v_pedido_veh vpv, vve_ficha_vta_pedido_veh z
       WHERE a.num_pedido_veh = vpv.num_pedido_veh
         AND a.cod_cia = vpv.cod_cia
         AND a.cod_prov = vpv.cod_prov
         AND a.num_pedido_veh = z.num_pedido_veh
         AND a.cod_cia = z.cod_cia
         AND a.cod_prov = z.cod_prov
         AND nvl(z.ind_inactivo, 'N') = 'N'
         AND z.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND (p_num_prof_veh IS NULL OR z.num_prof_veh = p_num_prof_veh)
       ORDER BY z.nur_ficha_vta_pedido DESC;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PEDI_PEDI_FICHA_VENTA',
                                          p_cod_usuario,
                                          'Error al listar los pedidos',
                                          p_ret_mens,
                                          p_num_prof_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_PEDI_USOCOLR_FV
      Proposito : Devuelve los colores
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      28/09/2018   SOPORTELEGADOS     REQ 86868 Lista ordenado los colores de los pedidos
  ----------------------------------------------------------------------------*/

  PROCEDURE sp_list_pedi_usocolr_fv
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cabe          OUT SYS_REFCURSOR,
    p_ret_det           OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
  BEGIN

    OPEN p_ret_cabe FOR
      SELECT fvped.num_ficha_vta_veh,
             ped.num_prof_veh,
             ped.num_pedido_veh,
             vpv.num_vin num_chasis,
             uso.des_uso_veh,
             ped.cod_cia,
             ped.cod_prov,
             (SELECT des_estado_pedido
                FROM vve_estado_pedido
               WHERE cod_estado_pedido = ped.cod_estado_pedido_veh) est_pedido,
             fvped.cod_avta_fam_uso,
             pkg_sweb_five_mant_pedido.fn_ind_desaduanaje(fvped.cod_cia,
                                                          fvped.cod_prov,
                                                          fvped.num_pedido_veh) ind_correo_aduana,
             (SELECT COUNT(1)
                FROM vve_pedido_veh a
               WHERE a.cod_ubica_pedido_veh IN
                     ((SELECT cod_ubica_pedido
                        FROM vve_ubica_pedido
                       WHERE upper(des_ubica_pedido) LIKE '%WARRA%'))
                 AND a.num_pedido_veh = fvped.num_pedido_veh
                 AND a.cod_cia = fvped.cod_cia
                 AND a.cod_prov = fvped.cod_prov) ind_correo_warrant,
             fvped.fec_compro_entrega,
             '1' ind_fech_aprob -- devuelve el 1 si tiene una fecha pendiente de aprobacion
        FROM vve_pedido_veh           ped,
             vve_ficha_vta_pedido_veh fvped,
             v_pedido_veh             vpv,
             vve_mov_avta_uso_veh     uso
       WHERE ped.num_pedido_veh = vpv.num_pedido_veh
         AND ped.cod_cia = vpv.cod_cia
         AND ped.cod_prov = vpv.cod_prov
         AND ped.num_pedido_veh = fvped.num_pedido_veh
         AND ped.cod_cia = fvped.cod_cia
         AND ped.cod_prov = fvped.cod_prov
            --AND ped.cod_area_vta = uso.cod_area_vta(+)
            --AND ped.cod_familia_veh = uso.cod_familia_veh(+)
         AND fvped.cod_avta_fam_uso = uso.cod_avta_fam_uso(+)
         AND nvl(fvped.ind_inactivo, 'N') = 'N'
         AND fvped.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND fvped.num_prof_veh = p_num_prof_veh
       ORDER BY fvped.nur_ficha_vta_pedido DESC;

    OPEN p_ret_det FOR
      SELECT fvped.num_ficha_vta_veh,
             ped.num_prof_veh,
             ped.num_pedido_veh,
             vpv.num_vin num_chasis,
             cf.des_color_fabrica_veh,
             cs.des_color_sunarp,
             ped.cod_cia,
             ped.cod_prov
        FROM vve_pedido_veh            ped,
             vve_ficha_vta_pedido_veh  fvped,
             v_pedido_veh              vpv,
             vve_color_fabrica_veh     cf,
             vve_mov_color_sunarp      cs,
             vve_ficha_vta_ped_col_veh cv
       WHERE ped.num_pedido_veh = vpv.num_pedido_veh
         AND ped.cod_cia = vpv.cod_cia
         AND ped.cod_prov = vpv.cod_prov
         AND ped.num_pedido_veh = fvped.num_pedido_veh
         AND ped.cod_cia = fvped.cod_cia
         AND ped.cod_prov = fvped.cod_prov
         AND cf.cod_color_sunarp = cs.cod_color_sunarp(+)
         AND cv.cod_color_fabrica_veh = cf.cod_color_fabrica_veh(+)
         AND cv.num_ficha_vta_veh = fvped.num_ficha_vta_veh
         AND cv.nur_ficha_vta_pedido = fvped.nur_ficha_vta_pedido
         AND nvl(fvped.ind_inactivo, 'N') = 'N'
         AND nvl(cv.ind_inactivo, 'N') = 'N'
         AND fvped.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND fvped.num_prof_veh = p_num_prof_veh
      --<I-86868>
       ORDER BY cv.num_colfab_veh ASC;
    --<F-86868>

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cabe;
      CLOSE p_ret_det;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PEDI_USOCOLR_FV',
                                          p_cod_usuario,
                                          'Error al listar los pedidos',
                                          p_ret_mens,
                                          p_num_prof_veh);
  END;
  PROCEDURE sp_list_pedi_vali_fv
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cabe          OUT SYS_REFCURSOR,
    p_ret_det           OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
  BEGIN
    OPEN p_ret_cabe FOR
      SELECT fvped.num_ficha_vta_veh,
             ped.num_prof_veh,
             ped.num_pedido_veh,
             vpv.num_vin num_chasis,
             ped.cod_cia,
             ped.cod_prov,
             (SELECT des_estado_pedido
                FROM vve_estado_pedido
               WHERE cod_estado_pedido = ped.cod_estado_pedido_veh) est_pedido
        FROM vve_pedido_veh           ped,
             vve_ficha_vta_pedido_veh fvped,
             v_pedido_veh             vpv
       WHERE ped.num_pedido_veh = vpv.num_pedido_veh
         AND ped.cod_cia = vpv.cod_cia
         AND ped.cod_prov = vpv.cod_prov
         AND ped.num_pedido_veh = fvped.num_pedido_veh
         AND ped.cod_cia = fvped.cod_cia
         AND ped.cod_prov = fvped.cod_prov
         AND nvl(fvped.ind_inactivo, 'N') = 'N'
         AND fvped.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND fvped.num_prof_veh = p_num_prof_veh
       ORDER BY ped.num_pedido_veh DESC;

    OPEN p_ret_det FOR
      SELECT DISTINCT fa.num_ficha_vta_veh,
                      pr.num_prof_veh,
                      fa.nur_aut_ficha_vta_veh,
                      fa.cod_aut_ficha_vta,
                      au.des_aut_ficha_vta,
                      fa.num_orden,
                      fa.co_usuario_aut,
                      (SELECT txt_nombres || ' ' || txt_apellidos
                         FROM sistemas.sis_mae_usuario
                        WHERE txt_usuario = fa.co_usuario_aut) nom_aut,
                      fa.fec_usuario_aut,
                      fa.cod_aprob_ficha_vta_aut,
                      fa.ind_inactivo,
                      fa.cod_cia,
                      fa.cod_prov,
                      fa.num_pedido_veh,
                      au.ind_aplica_hito,
                      au.cod_hito_five,
                      pkg_sweb_mae_gene.fu_desc_maes(41, au.cod_hito_five) des_hito_five,
                      au.num_orden_hito,
                      au.num_orden_act,
                      au.ind_req_aut_hito,
                      fa.ind_act_realizada,
                      pkg_sweb_five_mant.fu_auto_five_usu(p_cod_usuario,
                                                          p_cod_id_usuario,
                                                          fa.cod_aut_ficha_vta,
                                                          p_num_ficha_vta_veh,
                                                          fa.num_pedido_veh,
                                                          fa.cod_cia,
                                                          fa.cod_prov) ind_autoriza
        FROM venta.vve_ficha_vta_proforma_veh pr,
             venta.vve_ficha_vta_veh_aut      fa,
             venta.vve_aut_ficha_vta          au
       WHERE pr.num_ficha_vta_veh = fa.num_ficha_vta_veh
         AND fa.cod_aut_ficha_vta = au.cod_aut_ficha_vta
         AND nvl(pr.ind_inactivo, 'N') = 'N'
         AND nvl(fa.ind_inactivo, 'N') = 'N'
         AND (p_num_ficha_vta_veh IS NULL OR
             fa.num_ficha_vta_veh = p_num_ficha_vta_veh)
         AND (p_num_prof_veh IS NULL OR pr.num_prof_veh = p_num_prof_veh)
         AND au.ind_aplica_hito = 'P'
         AND au.ind_req_aut_hito = 'S'
       ORDER BY fa.num_pedido_veh, au.num_orden_hito, au.num_orden_act;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cabe;
      CLOSE p_ret_det;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PEDI_USOCOLR_FV',
                                          p_cod_usuario,
                                          'Error al listar los pedidos',
                                          p_ret_mens,
                                          p_num_prof_veh);
  END;
  PROCEDURE sp_list_pedi_trac_fv
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cabe          OUT SYS_REFCURSOR,
    p_ret_det           OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
  BEGIN
    OPEN p_ret_cabe FOR
      SELECT fvped.num_ficha_vta_veh,
             ped.num_prof_veh,
             ped.num_pedido_veh,
             vpv.num_vin num_chasis,
             ped.cod_cia,
             ped.cod_prov,
             (SELECT des_estado_pedido
                FROM vve_estado_pedido
               WHERE cod_estado_pedido = ped.cod_estado_pedido_veh) est_pedido,
             pkg_sweb_five_mant_pedido.fn_ind_desaduanaje(fvped.cod_cia,
                                                          fvped.cod_prov,
                                                          fvped.num_pedido_veh) ind_correo_aduana,
             (SELECT COUNT(1)
                FROM vve_pedido_veh a
               WHERE a.cod_ubica_pedido_veh IN
                     ((SELECT cod_ubica_pedido
                        FROM vve_ubica_pedido
                       WHERE upper(des_ubica_pedido) LIKE '%WARRA%'))
                 AND a.num_pedido_veh = fvped.num_pedido_veh
                 AND a.cod_cia = fvped.cod_cia
                 AND a.cod_prov = fvped.cod_prov) ind_correo_warrant,
             fvped.fec_compro_entrega,
             '1' ind_fech_aprob -- devuelve el 1 si tiene una fecha pendiente de aprobacion
        FROM vve_pedido_veh           ped,
             vve_ficha_vta_pedido_veh fvped,
             v_pedido_veh             vpv
       WHERE ped.num_pedido_veh = vpv.num_pedido_veh
         AND ped.cod_cia = vpv.cod_cia
         AND ped.cod_prov = vpv.cod_prov
         AND ped.num_pedido_veh = fvped.num_pedido_veh
         AND ped.cod_cia = fvped.cod_cia
         AND ped.cod_prov = fvped.cod_prov
         AND nvl(fvped.ind_inactivo, 'N') = 'N'
         AND fvped.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND fvped.num_prof_veh = p_num_prof_veh
       ORDER BY fvped.nur_ficha_vta_pedido DESC;

    OPEN p_ret_det FOR
      SELECT fa.num_ficha_vta_veh,
             pr.num_prof_veh,
             fa.nur_aut_ficha_vta_veh,
             fa.cod_aut_ficha_vta,
             au.des_aut_ficha_vta,
             fa.num_orden,
             fa.co_usuario_aut,
             (SELECT txt_nombres || ' ' || txt_apellidos
                FROM sistemas.sis_mae_usuario
               WHERE txt_usuario = fa.co_usuario_aut) nom_aut,
             fa.fec_usuario_aut,
             fa.cod_aprob_ficha_vta_aut,
             fa.ind_inactivo,
             fa.cod_cia,
             fa.cod_prov,
             fa.num_pedido_veh,
             au.ind_aplica_hito,
             au.cod_hito_five,
             pkg_sweb_mae_gene.fu_desc_maes(41, au.cod_hito_five) des_hito_five,
             au.num_orden_hito,
             au.num_orden_act,
             au.ind_req_aut_hito,
             fa.ind_act_realizada
        FROM venta.vve_ficha_vta_proforma_veh pr,
             venta.vve_ficha_vta_veh_aut      fa,
             venta.vve_aut_ficha_vta          au
       WHERE pr.num_ficha_vta_veh = fa.num_ficha_vta_veh
         AND fa.cod_aut_ficha_vta = au.cod_aut_ficha_vta
         AND nvl(pr.ind_inactivo, 'N') = 'N'
         AND nvl(fa.ind_inactivo, 'N') = 'N'
         AND (p_num_ficha_vta_veh IS NULL OR
             fa.num_ficha_vta_veh = p_num_ficha_vta_veh)
         AND (p_num_prof_veh IS NULL OR pr.num_prof_veh = p_num_prof_veh)
         AND au.ind_aplica_hito = 'P'
       ORDER BY fa.num_pedido_veh, au.num_orden_hito, au.num_orden_act;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cabe;
      CLOSE p_ret_det;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PEDI_USOCOLR_FV',
                                          p_cod_usuario,
                                          'Error al listar los pedidos',
                                          p_ret_mens,
                                          p_num_prof_veh);
  END;
  /*-----------------------------------------------------------------------------
      Nombre : sp_list_pedi_fact_fv
      Proposito : Lista los pedidos tab facturación en la ficha de venta
      Referencias :
      Parametros :P_NUM_FICHA_VTA_VEH ---> Número de ficha de venta.
                  P_NUM_PROF_VEH     ---> Número de Proforma.
                  p_cod_id_usuario   --->  Id. de usuario
                  p_cod_usuario      --->  Cod. usuario
                  p_ret_cabe         ---> Lista de cabecera pedido.
                  p_ret_det          ---> Lista de detalle pedido.
                  P_RET_ESTA          ---> Estado del proceso.
                  P_RET_MENS          ---> Resultado del proceso.
      Log de Cambios
      Fecha        Autor           Descripcion
                                 Creación
      18/08/2018   AVILCA          Modificacion -  Req. 86370Se agrega el campo tipo_sol_fact
                                                   para mostrarlo en la cabecera de los pedidos
       01/10/2018    FGRANDEZ    REQ-86111 Se modifico el script para obtener las variables de titulos
                correo adicional
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_pedi_fact_fv
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_cod_id_usuario    IN sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usuario       IN sis_mae_usuario.txt_usuario%TYPE,
    p_ret_cabe          OUT SYS_REFCURSOR,
    p_ret_det           OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
  BEGIN
    OPEN p_ret_cabe FOR
      SELECT fvped.num_ficha_vta_veh,
             ped.num_prof_veh,
             ped.num_pedido_veh,
             vpv.num_vin num_chasis,
             ped.cod_cia,
             ped.cod_prov,
             ec.cod_estado_cancelacion_ped,

             vpv.cod_propietario_veh cod_propietario_veh,
             f.nom_perso des_propietario_veh,
             f.num_docu_iden dni_prop,
             f.num_ruc ruc_prop,
             vpv.cod_clie cod_clie,
             e.nom_perso des_clie,
             e.num_docu_iden dni_clie,
             e.num_ruc ruc_clie,
             vpv.cod_usuario_veh cod_usuario_veh,
             g.nom_perso des_usuario_veh,
             g.num_docu_iden dni_usua,
             g.num_ruc ruc_usua,
             (SELECT des_estado_pedido
                FROM vve_estado_pedido
               WHERE cod_estado_pedido = ped.cod_estado_pedido_veh) est_pedido,
             pkg_sweb_five_mant_pedido.fn_ind_desaduanaje(fvped.cod_cia,
                                                          fvped.cod_prov,
                                                          fvped.num_pedido_veh) ind_correo_aduana,
             (SELECT COUNT(1)
                FROM vve_pedido_veh a
               WHERE a.cod_ubica_pedido_veh IN
                     ((SELECT cod_ubica_pedido
                        FROM vve_ubica_pedido
                       WHERE upper(des_ubica_pedido) LIKE '%WARRA%'))
                 AND a.num_pedido_veh = fvped.num_pedido_veh
                 AND a.cod_cia = fvped.cod_cia
                 AND a.cod_prov = fvped.cod_prov) ind_correo_warrant,
             fvped.fec_compro_entrega,
             '1' ind_fech_aprob,
             (CASE pkg_pedido_veh.f_ind_fact_transito(fvped.num_ficha_vta_veh,
                                                  ped.cod_cia,
                                                  ped.cod_prov,
                                                  ped.num_pedido_veh)
               WHEN 'S' THEN
                'TRANSITO'
               ELSE
                'STOCK'
             END) tipo_sol_fact, -- Se agrega por Req. 86370- Soporte Legados
             --<REQ-86111>
             ped.num_titulo_rpv,
             ped.fec_titulo_rpv,
             ped.fec_carg_titu
      --<REQ-86111>
        FROM vve_pedido_veh             ped,
             vve_ficha_vta_pedido_veh   fvped,
             v_pedido_veh               vpv,
             vve_pedido_veh_estado_canc ec,
             gen_persona                f,
             gen_persona                e,
             gen_persona                g
       WHERE ped.num_pedido_veh = vpv.num_pedido_veh
         AND ped.cod_cia = vpv.cod_cia
         AND ped.cod_prov = vpv.cod_prov
         AND ped.num_pedido_veh = fvped.num_pedido_veh
         AND ped.cod_cia = fvped.cod_cia
         AND ped.cod_prov = fvped.cod_prov
         AND nvl(fvped.ind_inactivo, 'N') = 'N'
         AND fvped.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND fvped.num_prof_veh = p_num_prof_veh

         AND vpv.cod_clie = e.cod_perso(+)
         AND vpv.cod_propietario_veh = f.cod_perso(+)
         AND vpv.cod_usuario_veh = g.cod_perso(+)

         AND ped.num_pedido_veh = ec.num_pedido_veh(+)
         AND ped.cod_cia = ec.cod_cia(+)
         AND ped.cod_prov = ec.cod_prov(+)
      --AND nvl(ec.ind_inactivo, 'N') = 'N'

       ORDER BY fvped.nur_ficha_vta_pedido DESC;

    OPEN p_ret_det FOR
      SELECT fvped.num_ficha_vta_veh,
             p.num_prof_veh,
             a.no_cia,
             a.nu_prove,
             a.no_orden_desc,
             p.num_vin,
             nvl((SELECT DISTINCT cp.des_estado_cancelacion_ped
                   FROM vve_pedido_veh_estado_canc ce,
                        vve_estado_cancelacion_ped cp
                  WHERE cp.cod_estado_cancelacion_ped =
                        ce.cod_estado_cancelacion_ped
                    AND ce.cod_cia = a.no_cia
                    AND ce.cod_prov = a.nu_prove
                    AND ce.num_pedido_veh = a.no_orden_desc
                    AND nvl(ce.ind_inactivo, 'N') = 'N'
                    AND ce.fec_crea_reg =
                        (SELECT MAX(ce2.fec_crea_reg)
                           FROM vve_pedido_veh_estado_canc ce2
                          WHERE ce2.cod_cia = a.no_cia
                            AND ce2.cod_prov = a.nu_prove
                            AND ce2.num_pedido_veh = a.no_orden_desc
                            AND nvl(ce2.ind_inactivo, 'N') = 'N')),
                 'SIN CANCELAR') des_estado_cancela,
             --a.no_cliente, a.nbr_cliente,
             desc_fact.cod_perso     cod_cli_fact,
             desc_fact.nom_perso     nom_perso_fact,
             desc_fact.num_docu_iden num_docu_fact,
             desc_fact.num_ruc       num_ruc_fact,
             desc_prop.cod_perso     cod_cli_prop,
             desc_prop.nom_perso     nom_perso_prop,
             desc_prop.num_docu_iden num_docu_prop,
             desc_prop.num_ruc       num_ruc_prop,
             desc_usua.cod_perso     cod_cli_usua,
             desc_usua.nom_perso     nom_perso_usua,
             desc_usua.num_docu_iden num_docu_usua,
             desc_usua.num_ruc       num_ruc_usua,
             a.no_factu,
             a.fecha,
             a.val_pre_docu
        FROM arfafe                   a,
             arcctd                   t,
             vve_pedido_veh           p,
             vve_ficha_vta_pedido_veh fvped,
             gen_persona              desc_usua,
             gen_persona              desc_prop,
             gen_persona              desc_fact
       WHERE a.no_cia = t.no_cia
         AND a.tipo_doc = t.tipo
         AND a.no_cia = p.cod_cia
         AND a.nu_prove = p.cod_prov
         AND a.no_orden_desc = p.num_pedido_veh
         AND p.num_pedido_veh = fvped.num_pedido_veh
         AND p.cod_cia = fvped.cod_cia
         AND p.cod_prov = fvped.cod_prov
         AND p.cod_usuario_veh = desc_usua.cod_perso(+)
         AND p.cod_propietario_veh = desc_prop.cod_perso(+)
         AND p.cod_clie = desc_fact.cod_perso(+)
            -- AND a.estado = 'D'
         AND fvped.ind_inactivo = 'N'
         AND t.grupo_doc IN ('F', 'B')
         AND fvped.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND fvped.num_prof_veh = p_num_prof_veh
       ORDER BY a.no_orden_desc, a.fecha DESC;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cabe;
      CLOSE p_ret_det;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PEDI_USOCOLR_FV',
                                          p_cod_usuario,
                                          'Error al listar los pedidos',
                                          p_ret_mens,
                                          p_num_prof_veh);
  END;
  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_PEDI_FICH
      Proposito : Lista los pedidos asociados a la ficha de venta
      Referencias :
      Parametros :P_NUM_FICHA_VTA_VEH ---> Número de ficha de venta.
                  P_NUM_PROF_VEH     ---> Número de Proforma.
                  P_RET_CURSOR        ---> Lista de pedidos.
                  P_RET_ESTA          ---> Estado del proceso.
                  P_RET_MENS          ---> Resultado del proceso.
      Log de Cambios
      Fecha        Autor           Descripcion
      01/06/2017   AVILCA          Creacion
      17/07/2017   LVALDERRAMA     Modificacion
      17/11/2017   BPALACIOS       Modificacion - Se agrega el campo P_NUM_PROF_VEH
                                                   para la obtencion de pedidos
                                                   y saber los bonos de descuento
                                                   asociados
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_pedi_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR
      SELECT a.num_pedido_veh,
             pkg_sweb_five_mant_pedido.fun_ped_modelo(a.cod_area_vta,
                                                      a.ind_nuevo_usado,
                                                      a.cod_familia_veh,
                                                      a.cod_marca,
                                                      a.cod_baumuster,
                                                      a.cod_config_veh) des_modelo,
             decode(z.cod_doc_fact, 'FA', 'FACTURA', 'BOLETA') des_tipo_doc,
             a.val_vta_pedido_veh,
             (h.des_familia_veh || ' ' || i.nom_marca) des_marca,
             decode(a.cod_moneda_pedido_veh, 'DOL', 'DOLARES', 'SOLES') des_moneda,
             z.des_color_veh,
             a.num_chasis,
             a.num_prof_veh,
             a.cod_propietario_veh,
             f.nom_perso des_propietario_veh,
             f.num_docu_iden dni_prop,
             f.num_ruc ruc_prop,
             fd.dir_domicilio dir_domicilio_prop,
             fd.num_telf1 num_telf_prop,
             fd.num_fax num_fax_prop,
             a.cod_clie,
             e.nom_perso des_clie,
             e.num_docu_iden dni_clie,
             e.num_ruc ruc_clie,
             ed.dir_domicilio dir_domicilio_clie,
             ed.num_telf1 num_telf_clie,
             ed.num_fax num_fax_clie,
             a.cod_usuario_veh,
             g.nom_perso des_usuario_veh,
             g.num_docu_iden dni_usua,
             g.num_ruc ruc_usua,
             gd.dir_domicilio dir_domicilio_usua,
             gd.num_telf1 num_telf_usua,
             gd.num_fax num_fax_usua,
             z.fec_entrega_aprox,
             z.nom_lugar_entrega,
             (SELECT txt_forma_pago
                FROM venta.vve_proforma_veh
               WHERE num_prof_veh = a.num_prof_veh) des_form_pago,
             z.obs_facturacion,
             z.num_ficha_vta_veh,
             z.nur_ficha_vta_pedido,
             z.cod_cia,
             z.cod_prov,
             REPLACE(REPLACE((SELECT pkg_promocion.fun_proforma_prom(a.num_prof_veh,
                                                                    'A')
                               FROM dual),
                             0,
                             'N'),
                     '1',
                     'S') ind_promocion,
             z.ind_prenda,
             a.vendedor,
             s.descripcion des_vendedor,
             z.fec_compro_entrega,
             z.fec_asig_definitiva,
             a.num_vin,
             a.ano_fabricacion_veh,
             s.des_situ_pedido,
             u.des_ubica_pedido des_ubica_pedido_veh,
             a.sku_sap
        FROM vve_pedido_veh a,
             --V_PEDIDO_VEH VPV,
             vve_ficha_vta_pedido_veh z,
             vve_familia_veh          h,
             gen_marca                i,
             gen_persona              f,
             gen_persona              e,
             gen_persona              g,
             gen_dir_perso            fd,
             gen_dir_perso            ed,
             gen_dir_perso            gd,
             arccve                   s,
             vve_ubica_pedido         u,
             vve_situ_pedido          s
       WHERE
      --VPV.NUM_PEDIDO_VEH=A.NUM_PEDIDO_VEH
       a.cod_cia = z.cod_cia
       AND a.cod_prov = z.cod_prov
       AND a.num_pedido_veh = z.num_pedido_veh
       AND a.cod_clie = e.cod_perso(+)
       AND a.cod_propietario_veh = f.cod_perso(+)
       AND a.cod_usuario_veh = g.cod_perso(+)
       AND a.cod_familia_veh = h.cod_familia_veh(+)
       AND a.cod_marca = i.cod_marca(+)
       AND e.cod_perso = ed.cod_perso(+)
       AND f.cod_perso = fd.cod_perso(+)
       AND g.cod_perso = gd.cod_perso(+)
       AND a.cod_ubica_pedido_veh = u.cod_ubica_pedido(+)
       AND a.cod_situ_pedido = s.cod_situ_pedido(+)
       AND nvl(z.ind_inactivo, 'N') = 'N'
       AND nvl(ed.ind_inactivo, 'N') = 'N'
       AND nvl(fd.ind_inactivo, 'N') = 'N'
       AND nvl(gd.ind_inactivo, 'N') = 'N'
       AND nvl(ed.ind_dir_defecto, 'N') = 'S'
       AND nvl(fd.ind_dir_defecto, 'N') = 'S'
       AND nvl(gd.ind_dir_defecto, 'N') = 'S'
       AND a.vendedor = s.vendedor(+)
       AND z.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND ((p_num_prof_veh IS NULL) OR (z.num_prof_veh = p_num_prof_veh))
       AND ((p_num_pedido_veh IS NULL) OR (z.num_pedido_veh = p_num_pedido_veh));

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PEDI_FICHA_VENTA',
                                          NULL,
                                          'Error al listar los pedidos',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_GRABAR_PEDI_FICHA_VENTA
      Proposito : Preasignacion de pedidos
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor           Descripcion

  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_pedi_ficha_venta
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_nur_ficha_vta_pedido IN NUMBER,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_num_prof_veh         IN VARCHAR2,
    p_ind_prenda           IN VARCHAR2,
    p_ind_inactivo         IN VARCHAR2,
    p_cod_clie             IN VARCHAR2,
    p_cod_propietario_veh  IN VARCHAR2,
    p_cod_usuario_veh      IN VARCHAR2,
    p_vendedor             IN VARCHAR2,
    p_fec_compro_entrega   IN VARCHAR2,
    p_con_pago             IN VARCHAR2,
    p_tipo_pago            IN VARCHAR2,
    p_cod_id_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_nur_ficha_vta_pedido vve_ficha_vta_pedido_veh.nur_ficha_vta_pedido%TYPE;
    v_cod_filial           vve_ficha_vta_veh.cod_filial%TYPE;
    v_val_pre_veh          vve_proforma_veh_det.val_pre_veh%TYPE;
    v_cod_moneda_prof      vve_proforma_veh.cod_moneda_prof%TYPE;
    --<i84905>Color interno
    v_cod_tapiz_veh_ped  vve_pedido_veh.cod_tapiz_veh%TYPE;
    v_cod_tapiz_veh_prof vve_proforma_veh_det.cod_tapiz_veh%TYPE;
    v_area_vta           vve_proforma_veh.cod_area_vta%TYPE;
    v_familia_veh        vve_proforma_veh_det.cod_familia_veh%TYPE;
    v_marca              vve_proforma_veh_det.cod_marca%TYPE;
    v_baumuster          vve_proforma_veh_det.cod_baumuster%TYPE;
    v_config_veh         vve_proforma_veh_det.cod_config_veh%TYPE;
    v_tipo_veh           vve_proforma_veh_det.cod_tipo_veh%TYPE;
    v_ind_reser_colorint VARCHAR(1);
    v_dato_numerico      NUMBER;
    v_dato_cadena        VARCHAR(1);
    v_rpta               NUMBER;
    v_rpta_msj           VARCHAR(50);
    --<f84905> Color interno
  BEGIN
    --<i84905>Color interno
    SELECT a.cod_area_vta,
           b.cod_familia_veh,
           b.cod_marca,
           b.cod_baumuster,
           b.cod_config_veh,
           b.cod_tipo_veh,
           b.cod_tapiz_veh
      INTO v_area_vta,
           v_familia_veh,
           v_marca,
           v_baumuster,
           v_config_veh,
           v_tipo_veh,
           v_cod_tapiz_veh_prof
      FROM vve_proforma_veh a
     INNER JOIN vve_proforma_veh_det b
        ON a.num_prof_veh = b.num_prof_veh
     WHERE a.num_prof_veh = p_num_prof_veh;
    --<f84905> Color interno

    pkg_sweb_mant_datos_mae.sp_dato_gen(v_area_vta,
                                        v_familia_veh,
                                        v_marca,
                                        v_baumuster,
                                        v_config_veh,
                                        v_tipo_veh,
                                        NULL,
                                        12, --12 = RESERVA CON COLOR INTERNO
                                        v_dato_numerico,
                                        v_dato_cadena,
                                        v_ind_reser_colorint,
                                        v_rpta,
                                        v_rpta_msj);
    IF (v_rpta <> 1) THEN
      v_ind_reser_colorint := 'N';
    END IF;

    IF v_ind_reser_colorint = 'S' THEN
      SELECT a.cod_tapiz_veh
        INTO v_cod_tapiz_veh_ped
        FROM vve_pedido_veh a
       WHERE a.num_pedido_veh = p_num_pedido_veh
         AND a.cod_cia = p_cod_cia
         AND a.cod_prov = p_cod_prov;

      IF NOT (nvl(v_cod_tapiz_veh_ped, '') = nvl(v_cod_tapiz_veh_prof, '')) THEN
        p_ret_mens := 'En color interno del vehículo no coincide con el color de la Proforma';
        RAISE ve_error;
      END IF;

    END IF;

    IF p_nur_ficha_vta_pedido IS NULL OR p_nur_ficha_vta_pedido = 0 THEN
      BEGIN
        SELECT nvl(MAX(nur_ficha_vta_pedido), 0) + 1
          INTO v_nur_ficha_vta_pedido
          FROM vve_ficha_vta_pedido_veh
         WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
      EXCEPTION
        WHEN OTHERS THEN
          v_nur_ficha_vta_pedido := 1;
      END;

      sp_inse_pedi_ficha_venta(p_num_ficha_vta_veh,
                               v_nur_ficha_vta_pedido,
                               p_cod_cia,
                               p_cod_prov,
                               p_num_pedido_veh,
                               p_num_prof_veh,
                               p_cod_clie,
                               p_cod_propietario_veh,
                               p_cod_usuario_veh,
                               p_ind_prenda,
                               p_fec_compro_entrega,
                               p_con_pago,
                               p_tipo_pago,
                               p_cod_id_usuario,
                               p_ret_esta,
                               p_ret_mens);
      IF p_ret_esta != 1 THEN
        RAISE ve_error;
      END IF;

    ELSE
      sp_actu_pedi_ficha_venta(p_num_ficha_vta_veh,
                               p_nur_ficha_vta_pedido,
                               p_cod_cia,
                               p_cod_prov,
                               p_num_pedido_veh,
                               p_num_prof_veh,
                               p_cod_clie,
                               p_cod_propietario_veh,
                               p_cod_usuario_veh,
                               p_ind_prenda,
                               p_ind_inactivo,
                               p_fec_compro_entrega,
                               p_con_pago,
                               p_tipo_pago,
                               p_cod_id_usuario,
                               p_ret_esta,
                               p_ret_mens);
    END IF;

    SELECT p.val_pre_veh, p.cod_moneda_prof, f.cod_filial
      INTO v_val_pre_veh, v_cod_moneda_prof, v_cod_filial
      FROM vve_ficha_vta_proforma_veh a,
           vve_ficha_vta_veh          f,
           v_proforma_veh             p
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND a.num_prof_veh = p_num_prof_veh
       AND a.num_ficha_vta_veh = f.num_ficha_vta_veh
       AND a.num_prof_veh = p.num_prof_veh
       AND nvl(a.ind_inactivo, 'N') = 'N';

    UPDATE vve_pedido_veh a
       SET cod_clie                  = p_cod_clie,
           cod_propietario_veh       = p_cod_propietario_veh,
           cod_usuario_veh           = p_cod_usuario_veh,
           vendedor                  = p_vendedor,
           num_prof_veh              = p_num_prof_veh,
           cod_estado_pedido_veh     = 'P',
           cod_moneda_vta_pedido_veh = decode(ind_nuevo_usado,
                                              'N',
                                              v_cod_moneda_prof,
                                              cod_moneda_vta_pedido_veh),
           val_vta_pedido_veh        = decode(ind_nuevo_usado,
                                              'N',
                                              v_val_pre_veh,
                                              val_vta_pedido_veh),
           val_pre_vta_final         = decode(ind_nuevo_usado,
                                              'U',
                                              v_val_pre_veh,
                                              val_pre_vta_final),
           cod_filial                = v_cod_filial
     WHERE cod_cia = p_cod_cia
       AND cod_prov = p_cod_prov
       AND num_pedido_veh = p_num_pedido_veh;

    COMMIT;

    IF p_ret_esta = -1 OR p_ret_esta = 0 THEN
      RAISE ve_error;
    END IF;

    p_ret_mens := 'Se grabó correctamente ' || p_fec_compro_entrega;
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GRABAR_PEDI_FICHA_VENTA',
                                          p_cod_id_usuario,
                                          'Error al grabar el pedido',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GRABAR_PEDI_FICHA_VENTA',
                                          p_cod_id_usuario,
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_INSE_PEDI_FICHA
     Proposito : Inserta pedidos asociado a una ficha de venta
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     02/06/2017   AVILCA         Creacion
     19/12/2017   JFLORESM       Modificacion
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_inse_pedi_ficha_venta
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_nur_ficha_vta_pedido IN NUMBER,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_num_prof_veh         IN VARCHAR2,
    p_cod_clie             IN VARCHAR2,
    p_cod_propietario_veh  IN VARCHAR2,
    p_cod_usuario_veh      IN VARCHAR2,
    p_ind_prenda           IN VARCHAR2,
    p_fec_compro_entrega   IN VARCHAR2,
    p_con_pago             IN VARCHAR2,
    p_tipo_pago            IN VARCHAR2,
    p_cod_id_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    x_contador           NUMBER := 0;
    v_query              VARCHAR2(2000);
    v_cod_situ_pedido    vve_pedido_veh.cod_situ_pedido%TYPE;
    v_cod_color_veh      vve_pedido_veh.cod_color_veh%TYPE;
    v_cod_familia_veh    vve_pedido_veh.cod_familia_veh%TYPE;
    v_nur_ficha_vta_prof vve_ficha_vta_pedido_veh.nur_ficha_vta_pedido%TYPE;
    v_cod_filial         vve_ficha_vta_veh.cod_filial%TYPE;
    v_val_pre_veh        vve_proforma_veh_det.val_pre_veh%TYPE;
    v_cod_moneda_prof    vve_proforma_veh.cod_moneda_prof%TYPE;
    l_is_auto            NUMBER;
    l_area_vta           vve_ficha_vta_veh.cod_area_vta%TYPE;
  BEGIN

    SELECT a.cod_situ_pedido, a.cod_color_veh, a.cod_familia_veh
      INTO v_cod_situ_pedido, v_cod_color_veh, v_cod_familia_veh
      FROM vve_pedido_veh a
     WHERE a.cod_cia = p_cod_cia
       AND a.cod_prov = p_cod_prov
       AND a.num_pedido_veh = p_num_pedido_veh;

    /*SELECT a.nur_ficha_vta_prof
     INTO v_nur_ficha_vta_prof
     FROM vve_ficha_vta_proforma_veh a
    WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
      AND a.num_prof_veh = p_num_prof_veh
      AND nvl(a.ind_inactivo, 'N') = 'N';*/

    SELECT a.num_reg_det_prof
      INTO v_nur_ficha_vta_prof
      FROM vve_proforma_veh_det a
     WHERE a.num_prof_veh = p_num_prof_veh;

    INSERT INTO vve_ficha_vta_pedido_veh
      (num_ficha_vta_veh,
       nur_ficha_vta_pedido,
       cod_cia,
       cod_prov,
       num_pedido_veh,
       num_prof_veh,
       ind_prenda,
       fec_compro_entrega,
       ind_inactivo,
       co_usuario_crea_reg,
       fec_crea_reg,
       con_pago,
       tipo_pago,
       cod_perso_dir,
       cod_perso_prop,
       cod_perso_usu,
       num_reg_det_prof,
       cod_color_veh,
       cod_situ_pedido_asigna)
    VALUES
      (p_num_ficha_vta_veh,
       p_nur_ficha_vta_pedido,
       p_cod_cia,
       p_cod_prov,
       p_num_pedido_veh,
       p_num_prof_veh,
       p_ind_prenda,
       to_date(p_fec_compro_entrega, 'DD/MM/YYYY'),
       'N',
       p_cod_id_usuario,
       SYSDATE,
       p_con_pago,
       p_tipo_pago,
       p_cod_clie,
       p_cod_propietario_veh,
       p_cod_usuario_veh,
       v_nur_ficha_vta_prof,
       v_cod_color_veh,
       v_cod_situ_pedido);

    ------------------------------------------------------------
    -- Se va a registrar las actividades de la ficha de venta --
    BEGIN
      SELECT MAX(nur_aut_ficha_vta_veh)
        INTO x_contador
        FROM vve_ficha_vta_veh_aut a
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;

      FOR i IN (SELECT act.cod_aut_ficha_vta
                  FROM venta.vve_aut_ficha_vta act
                 WHERE act.ind_aplica_hito = 'P'
                   AND act.ind_inactivo = 'N')
      LOOP

        IF (i.cod_aut_ficha_vta = 14 AND v_cod_familia_veh = 1) THEN
          x_contador := x_contador;
        ELSE
          x_contador := x_contador + 1;
          pkg_sweb_five_mant_veh_aut.sp_inse_ficha_vta_veh_aut(p_num_ficha_vta_veh,
                                                               x_contador,
                                                               i.cod_aut_ficha_vta,
                                                               p_cod_cia,
                                                               p_cod_prov,
                                                               p_num_pedido_veh,
                                                               1,
                                                               p_ret_esta,
                                                               p_ret_mens);
        END IF;

      END LOOP;
      BEGIN
        SELECT a.cod_area_vta
          INTO l_area_vta
          FROM vve_ficha_vta_veh a
         WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;

        l_is_auto := pkg_ficha_vta.fun_tipo_vehiculo('00',
                                                     'VEHAUTOM',
                                                     l_area_vta);
      EXCEPTION
        WHEN OTHERS THEN
          l_is_auto := 0;
      END;
      /*IF (l_is_auto = 0) THEN
        UPDATE vve_ficha_vta_veh_aut a
           SET fec_compromiso      = to_date(p_fec_compro_entrega,
                                             'DD/MM/YYYY'),
               a.obs_ficha_vta_aut = 'Actualizado en Preasignación'

         WHERE cod_aut_ficha_vta = '11'
           AND cod_cia = p_cod_cia
           AND cod_prov = p_cod_prov
           AND a.num_pedido_veh = p_num_pedido_veh
           AND a.num_ficha_vta_veh = p_num_ficha_vta_veh;
      END IF;*/

      pkg_sweb_five_mant_veh_aut.sp_actu_auto_fich(p_num_ficha_vta_veh,
                                                   '17',
                                                   p_num_pedido_veh,
                                                   'A',
                                                   p_cod_cia,
                                                   p_cod_prov,
                                                   p_cod_id_usuario,
                                                   p_cod_id_usuario,
                                                   NULL,
                                                   p_ret_esta,
                                                   p_ret_mens,
                                                   p_num_prof_veh);
      IF (p_ret_esta <> 1) THEN
        RAISE ve_error;
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := SQLERRM;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR!',
                                            'SP_INSE_PEDI_FICHA_VENTA',
                                            p_cod_id_usuario,
                                            p_ret_mens,
                                            p_num_ficha_vta_veh);
    END;

    COMMIT;

    p_ret_mens := 'Se inserto correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_PEDI_FICHA',
                                          p_cod_id_usuario,
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_ACTU_PEDI_FICH
     Proposito : Actualiza los pedidos pertenecientes a la ficha
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     02/06/2017   AVILCA        Creacion
     13/12/2017   BPALACIOS     Modificacion se agrega un campo de input
                                P_FEC_COMPRO_ENTREGA para solucionar error de
                                asignar un pedido a una ficha de venta
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_actu_pedi_ficha_venta
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_nur_ficha_vta_pedido IN NUMBER,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_num_prof_veh         IN VARCHAR2,
    p_cod_clie             IN VARCHAR2,
    p_cod_propietario_veh  IN VARCHAR2,
    p_cod_usuario_veh      IN VARCHAR2,
    p_ind_prenda           IN VARCHAR2,
    p_ind_inactivo         IN VARCHAR2,
    p_fec_compro_entrega   IN VARCHAR2,
    p_con_pago             IN VARCHAR2,
    p_tipo_pago            IN VARCHAR2,
    p_cod_id_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  ) AS

    ve_error EXCEPTION;
  BEGIN

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_PRUEBA',
                                        'SP_ACTU_PEDI_FICHA_VENTA',
                                        p_cod_id_usuario,
                                        p_ret_mens,
                                        p_num_pedido_veh);

    UPDATE venta.vve_ficha_vta_pedido_veh
       SET cod_cia            = p_cod_cia,
           cod_prov           = p_cod_prov,
           num_pedido_veh     = p_num_pedido_veh,
           num_prof_veh       = p_num_prof_veh,
           ind_prenda         = p_ind_prenda,
           ind_inactivo       = p_ind_inactivo,
           fec_compro_entrega = to_date(p_fec_compro_entrega, 'DD/MM/YYYY'),
           con_pago           = p_con_pago,
           tipo_pago          = p_tipo_pago
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
       AND nur_ficha_vta_pedido = p_nur_ficha_vta_pedido;

    COMMIT;

    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;

  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTU_PEDI_FICHA_VENTA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_PEDI_FICHA_VENTA',
                                          p_cod_id_usuario,
                                          p_ret_mens,
                                          p_num_pedido_veh);
  END;

  /*--------------------------------------------------------------------------
      Nombre : SP_OBTENER_INFO_FACT
      Proposito : Obtiene información de facturación para un pedido
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      05/06/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_obte_info_fact
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
                                          'SP_OBTENER_INFO_FACT',
                                          NULL,
                                          'Error al obtener información de facturación',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_ANUL_PEDIDO_VEH
      Proposito : Anula la asignacion de pedido
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      30/05/2017   AVILCA        Creacion
      20/12/2017   PHRAMIREZ     Se agrega validaciones de estado y area de venta
                                 para la verificación de la desasignación del
                                 pedido.
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_anul_pedido_veh
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_nur_ficha_vta_pedido IN NUMBER,
    p_cod_id_usuario       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_motivo           IN VARCHAR2,
    p_observa_desasigna    IN VARCHAR2,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  ) AS
    query VARCHAR(2000);
    ve_error EXCEPTION;
    v_des_estado_pedido vve_estado_pedido.des_estado_pedido%TYPE;
    v_vehautom          NUMBER;
    v_vehcomercial      NUMBER;
    v_cod_area_vta      vve_ficha_vta_veh.cod_area_vta%TYPE;
    v_ind_crm           gen_lval_det.des_valdet%TYPE;
    v_log               VARCHAR2(10);
    v_estado_pedido     VARCHAR2(1);
    v_tra               VARCHAR2(5000);
    ---I 88820 Notificación de desasignación
    v_asunto          VARCHAR2(2000);
    v_mensaje         CLOB;
    v_html_head       VARCHAR2(2000);
    v_correoori       usuarios.di_correo%TYPE;
    v_cont            INTEGER;
    v_cod_correo      vve_correo_prof.cod_correo_prof%TYPE;
    l_destinatarios   vve_correo_prof.destinatarios%TYPE;
    v_cod_id_usuario  sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_desc_filial     VARCHAR(500);
    v_desc_area_venta VARCHAR(500);
    v_desc_cia        VARCHAR(500);
    v_desc_vendedor   VARCHAR(500);
    ---F 88820 Notificación de desasignación
    CURSOR c_enviar_mail IS
      SELECT DISTINCT a.txt_correo
        FROM sistemas.sis_mae_usuario a
       INNER JOIN sistemas.sis_mae_perfil_usuario b
          ON a.cod_id_usuario = b.cod_id_usuario
         AND b.ind_inactivo = 'N'
       INNER JOIN sistemas.sis_mae_perfil_procesos c
          ON b.cod_id_perfil = c.cod_id_perfil
         AND c.ind_inactivo = 'N'
       WHERE c.cod_id_procesos = 124
         AND txt_correo IS NOT NULL;

    ---88820

  BEGIN
    v_tra := '
    p_num_ficha_vta_veh    =>' || p_num_ficha_vta_veh ||
             chr(10) || '
    p_num_pedido_veh       =>' || p_num_pedido_veh || chr(10) || '
    p_cod_cia              =>' || p_cod_cia || chr(10) || '
    p_cod_prov             =>' || p_cod_prov || chr(10) || '
    p_nur_ficha_vta_pedido =>' || p_nur_ficha_vta_pedido ||
             chr(10) || '
    p_cod_id_usuario       =>' || p_cod_id_usuario || chr(10) || '
    p_cod_motivo           =>' || p_cod_motivo || chr(10) || '
    p_observa_desasigna    =>' || p_observa_desasigna;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_TRAMA',
                                        'sp_anul_pedido_veh',
                                        p_cod_id_usuario,
                                        NULL,
                                        v_tra,
                                        p_num_ficha_vta_veh);
    BEGIN
      SELECT des_estado_pedido
        INTO v_des_estado_pedido
        FROM vve_pedido_veh pv, vve_estado_pedido ep
       WHERE pv.cod_estado_pedido_veh = ep.cod_estado_pedido
         AND pv.cod_estado_pedido_veh NOT IN ('P', 'A', 'D', 'I')
         AND pv.num_pedido_veh = p_num_pedido_veh
         AND pv.cod_cia = p_cod_cia
         AND pv.cod_prov = p_cod_prov;
    EXCEPTION
      WHEN no_data_found THEN
        v_des_estado_pedido := NULL;
    END;

    IF v_des_estado_pedido IS NOT NULL THEN
      p_ret_mens := 'Error, el Pedido se encuentra : ' ||
                    v_des_estado_pedido ||
                    ', No es Posible Eliminar/Inactivar la Asignación';
      RAISE ve_error;
    END IF;

    --Obtener el estado del pedido

    SELECT cod_estado_pedido_veh
      INTO v_estado_pedido
      FROM vve_pedido_veh
     WHERE cod_cia = p_cod_cia
       AND cod_prov = p_cod_prov
       AND num_pedido_veh = p_num_pedido_veh;

    IF v_des_estado_pedido IS NOT NULL THEN
      p_ret_mens := 'Error, al obtener el estado del pedido : ' ||
                    v_des_estado_pedido;
      RAISE ve_error;
    END IF;

    --Desasignacion de pedido, de acuerdo al tipo de estado del pedido
    --ESTADO : ASIGNADO

    IF v_estado_pedido = 'D' THEN
      /*GARROYO no es necesario 09/05/2018
            UPDATE venta.vve_soli_fact_vehi
               SET ind_inactivo = 'N'
             WHERE nur_ficha_vta_pedido = p_nur_ficha_vta_pedido;
      */
      UPDATE vve_ficha_vta_pedido_veh
         SET ind_inactivo        = 'N',
             co_usuario_inactiva = p_cod_id_usuario,
             fec_inactiva        = SYSDATE,
             cod_motivo          = p_cod_motivo,
             observa_desasigna   = p_observa_desasigna,
             tipo_desasigna      = 1
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
         AND nur_ficha_vta_pedido = p_nur_ficha_vta_pedido;

      UPDATE venta.vve_pedido_veh
         SET cod_estado_pedido_veh = 'P',
             co_usuario_mod_reg    = p_cod_id_usuario,
             fec_modi_reg          = SYSDATE
       WHERE cod_cia = p_cod_cia
         AND cod_prov = p_cod_prov
         AND num_pedido_veh = p_num_pedido_veh;

      UPDATE vve_ficha_vta_pedido_veh
         SET ind_asig_def        = 'N',
             fec_asig_definitiva = NULL
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
         AND nur_ficha_vta_pedido = p_nur_ficha_vta_pedido;

          PKG_CMS_LEGADO.SP_CMS_FICHAVENTA(p_num_ficha_vta_veh,
                                        P_COD_CIA,
                                        P_COD_PROV,
                                        p_num_pedido_veh,
                                        '0');

      --ESTADO : PREASIGNADO
    ELSIF v_estado_pedido = 'P' THEN

      UPDATE venta.vve_soli_fact_vehi a
         SET ind_inactivo = 'S',
             fec_modi_reg = SYSDATE
       WHERE cod_cia = p_cod_cia
         AND cod_prov = p_cod_prov
         AND num_pedido_veh = p_num_pedido_veh
         AND num_ficha_vta_veh = p_num_ficha_vta_veh;

      UPDATE vve_ficha_vta_pedido_veh
         SET ind_inactivo        = 'S',
             co_usuario_inactiva = p_cod_id_usuario,
             fec_inactiva        = SYSDATE,
             cod_motivo          = p_cod_motivo,
             observa_desasigna   = p_observa_desasigna,
             tipo_desasigna      = 1
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
         AND nur_ficha_vta_pedido = p_nur_ficha_vta_pedido;

      UPDATE vve_pedido_veh
         SET cod_clie              = NULL,
             cod_propietario_veh   = NULL,
             cod_usuario_veh       = NULL,
             vendedor              = NULL,
             cod_estado_pedido_veh = 'A',
             co_usuario_mod_reg    = p_cod_id_usuario,
             fec_modi_reg          = SYSDATE
       WHERE cod_cia = p_cod_cia
         AND cod_prov = p_cod_prov
         AND num_pedido_veh = p_num_pedido_veh;

      -------------------eliminar las autorizaciones ---
      UPDATE vve_ficha_vta_veh_aut a
         SET a.ind_inactivo = 'S'
       WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND a.cod_cia = p_cod_cia
         AND a.cod_prov = p_cod_prov
         AND a.num_pedido_veh = p_num_pedido_veh
         AND a.ind_inactivo = 'N';

    END IF;

    -- Eliminacion de elementos Adicionales
    DELETE FROM venta.vve_pedido_equipo_local_veh
     WHERE cod_cia = p_cod_cia
       AND cod_prov = p_cod_prov
       AND num_pedido_veh = p_num_pedido_veh;

    DELETE FROM venta.vve_pedido_equipo_esp_adic
     WHERE cod_cia = p_cod_cia
       AND cod_prov = p_cod_prov
       AND num_pedido_veh = p_num_pedido_veh;

    DELETE FROM venta.vve_pedido_equipo_esp_veh
     WHERE cod_cia = p_cod_cia
       AND cod_prov = p_cod_prov
       AND num_pedido_veh = p_num_pedido_veh;

    BEGIN
      SELECT cod_area_vta
        INTO v_cod_area_vta
        FROM vve_ficha_vta_veh
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := 'No hay datos disponibles de la ficha de venta seleccionada';
        RAISE ve_error;
    END;
    BEGIN
      BEGIN
        -- Verificar si es automóvil
        v_vehautom := pkg_ficha_vta.fun_tipo_vehiculo('00',
                                                      'VEHAUTOM',
                                                      v_cod_area_vta);
      EXCEPTION
        WHEN OTHERS THEN
          v_vehautom := 0;
      END;
      BEGIN
        -- Verificar si es vehículo comercial
        v_vehcomercial := pkg_ficha_vta.fun_tipo_vehiculo('00',
                                                          'VEHCOMER',
                                                          v_cod_area_vta);
      EXCEPTION
        WHEN OTHERS THEN
          v_vehcomercial := 0;
      END;

      IF v_vehautom > 0 THEN
        -- Si es automóvil
        -- Actualizar fecha de compromiso en la autorización de ficha
        UPDATE vve_ficha_vta_veh_aut
           SET fec_compromiso = NULL
         WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
           AND cod_cia = p_cod_cia
           AND cod_prov = p_cod_prov
           AND num_pedido_veh = p_num_pedido_veh
           AND cod_aut_ficha_vta = '15';
      END IF;
      IF v_vehcomercial > 0 THEN
        -- Si es automóvil
        -- Actualizar fecha de compromiso en la autorización de ficha
        UPDATE vve_ficha_vta_veh_aut
           SET fec_compromiso = NULL
         WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
           AND cod_cia = p_cod_cia
           AND cod_prov = p_cod_prov
           AND num_pedido_veh = p_num_pedido_veh
           AND cod_aut_ficha_vta = '11';

           pkg_cms_legado.sp_cms_fecha_comp_vendedor(p_num_ficha_vta_veh,
                                                p_cod_cia,
                                                p_cod_prov,
                                                p_num_pedido_veh,
                                                1,
                                                'En desasignacion');
      END IF;
    END;

    BEGIN
      SELECT lvd.des_valdet
        INTO v_ind_crm
        FROM gen_lval lv, gen_lval_det lvd
       WHERE lv.no_cia = lvd.no_cia
         AND lv.cod_val = lvd.cod_val
         AND lvd.cod_valdet = 'VEHFICVTA'
         AND lv.cod_val = 'LEGA_CRM';
    EXCEPTION
      WHEN no_data_found THEN
        v_ind_crm := 'NO';
    END;

    IF nvl(v_ind_crm, 'NO') = 'SI' AND p_num_ficha_vta_veh IS NOT NULL AND
       p_num_pedido_veh IS NOT NULL THEN
      --<I - REQ.90500 - SOPORTE LEGADOS - 25/06/2020>
      /*
    v_log := pkg_crm_legado.fun_crm_sap_vehi_ficvta(p_cod_cia,
                                                      p_cod_prov,
                                                      p_num_pedido_veh);
      */
    V_LOG := PKG_CRM_LEGADO.FUN_CRM_SAP_VEHI_FICVTA_N (P_COD_CIA,
                                                         P_COD_PROV,
                                                         P_NUM_PEDIDO_VEH
                            );
    --<F - REQ.90500 - SOPORTE LEGADOS - 25/06/2020>
    IF v_log = 'PEN' THEN
        p_ret_mens := 'Error al enviar el Pedido de Vehículo ' ||
                      p_num_pedido_veh || ' al SAP-CRM';
        RAISE ve_error;
      END IF;
    END IF;

    COMMIT;

    --88820 correo de desasignación----------------------------------------

    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo, a.cod_id_usuario
        INTO v_correoori, v_cod_id_usuario
        FROM sistemas.sis_mae_usuario a
       WHERE a.txt_usuario = p_cod_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;
    -----destiunatarios
    v_cont := 1;
    FOR c_mail IN c_enviar_mail
    LOOP
      IF (v_cont = 1) THEN
        l_destinatarios := l_destinatarios || c_mail.txt_correo;
      ELSE
        l_destinatarios := l_destinatarios || ',' || c_mail.txt_correo;
      END IF;
      v_cont := v_cont + 1;

    END LOOP;

    --Contenido de mensaje
    -- ESTRUCTURA DEL CORREO
    BEGIN
      SELECT ax.txt_asun_pla, ax.txt_cabe_pla, ax.txt_deta_pla
        INTO v_asunto, v_html_head, v_mensaje
        FROM sis_maes_plan ax
       WHERE ax.cod_plan_reg = 3
         AND nvl(ax.ind_inac_pla, 'N') = 'N';
    EXCEPTION
      WHEN no_data_found THEN
        v_asunto    := NULL;
        v_html_head := NULL;
        v_mensaje   := NULL;
      WHEN OTHERS THEN
        v_mensaje   := NULL;
        v_html_head := NULL;
        v_mensaje   := NULL;
    END;

    SELECT pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor)

      INTO v_desc_filial, v_desc_area_venta, v_desc_cia, v_desc_vendedor

      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;

    /*  l_cuerpo_dano_indi := replace_clob(l_cuerpo_dano_indi,
    '#descriocionDanos#',
    c_cursor_dano.descripcion);*/
    v_asunto := REPLACE(v_asunto, '#pedido#', p_num_pedido_veh);
    v_asunto := REPLACE(v_asunto, '#ficha#', p_num_ficha_vta_veh);

    v_mensaje := v_html_head || v_mensaje;
    v_mensaje := logistica_web.pkg_correo_log.replace_clob(v_mensaje,
                                                           '#FILIAL#',
                                                           v_desc_filial);
    v_mensaje := logistica_web.pkg_correo_log.replace_clob(v_mensaje,
                                                           '#AREA_VENTA#',
                                                           v_desc_area_venta);
    v_mensaje := logistica_web.pkg_correo_log.replace_clob(v_mensaje,
                                                           '#COMPANIA#',
                                                           v_desc_cia);
    v_mensaje := logistica_web.pkg_correo_log.replace_clob(v_mensaje,
                                                           '#VENDEDOR#',
                                                           v_desc_vendedor);
    v_mensaje := logistica_web.pkg_correo_log.replace_clob(v_mensaje,
                                                           '#FICHA_VENTA#',
                                                           p_num_ficha_vta_veh);
    v_mensaje := logistica_web.pkg_correo_log.replace_clob(v_mensaje,
                                                           '#PEDIDO#',
                                                           p_num_pedido_veh);
    BEGIN
      SELECT MAX(cod_correo_prof) INTO v_cod_correo FROM vve_correo_prof;
    EXCEPTION
      WHEN OTHERS THEN
        v_cod_correo := 0;
    END;

    v_cod_correo := v_cod_correo + 1;

    INSERT INTO vve_correo_prof
      (cod_correo_prof,
       cod_ref_proc,
       tipo_ref_proc,
       destinatarios,
       copia,
       asunto,
       cuerpo,
       correoorigen,
       ind_enviado,
       ind_inactivo,
       fec_crea_reg,
       cod_id_usuario_crea)
    VALUES
      (v_cod_correo,
       p_num_ficha_vta_veh || p_num_pedido_veh || 'DA', --P_COD_PLAN_ENTR_VEHI,
       'DA',
       l_destinatarios,
       NULL,
       v_asunto,
       v_mensaje,
       v_correoori,
       'N',
       'N',
       SYSDATE,
       v_cod_id_usuario);
    --------------------------------------------------

    p_ret_mens := 'Se anulo correctamente.';
    p_ret_esta := 1;

  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ANUL_PEDIDO_VEH:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ANUL_PEDIDO_VEH',
                                          p_cod_id_usuario,
                                          'ANULAR PEDIDO',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_ACTU_ASIG_DEFI
      Proposito : Actualiza estado de pedido a Asignación Definitiva
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      05/06/2017   AVILCA        Creacion
      26/12/2017   PHRAMIREZ     Agregar validaciones de LineUp
      21/02/2018   PHRAMIREZ     Se Agregaron validaciones WARRANT,
                                 EQUIPOS, AUTORIZACIONES, DESADUANAJE y CRM.
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_actu_asig_defi
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_nur_ficha_vta_pedido IN VARCHAR2,
    p_num_pedido_veh       IN VARCHAR2,
    p_num_prof_veh         IN VARCHAR2,
    p_tipo_ref_proc        IN VARCHAR2,
    p_cod_clie             IN VARCHAR2,
    p_ind_asig_def         IN VARCHAR2,
    p_cod_cia              IN VARCHAR2,
    p_cod_prov             IN VARCHAR2,
    p_vendedor             IN VARCHAR2,
    p_cod_filial           IN VARCHAR2,
    p_cod_propietario      IN VARCHAR2,
    p_id_usuario           IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_ind_correo           IN VARCHAR2,
    p_fechacompromiso      IN VARCHAR2,
    p_fechaasidef          IN VARCHAR2,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  ) AS

    ve_error EXCEPTION;
    v_error_crm VARCHAR2(100);
    PRAGMA EXCEPTION_INIT(ve_error, -20001);
    v_rolcomex               VARCHAR2(5);
    v_query                  VARCHAR2(4000);
    c_usuarios               SYS_REFCURSOR;
    v_correoori              usuarios.di_correo%TYPE;
    v_asunto                 VARCHAR2(100);
    v_cant                   NUMBER;
    v_html_head              VARCHAR2(2000);
    v_mensaje                VARCHAR2(5000);
    v_txt_nombres            VARCHAR2(200);
    v_txt_correo             VARCHAR2(200);
    v_line_up                CHAR(1);
    v_cod_area_vta           vve_pedido_veh.cod_area_vta%TYPE;
    v_warrant_mail_to        vve_correo_prof.destinatarios%TYPE;
    v_warrant_mail_cc        vve_correo_prof.copia%TYPE;
    v_habil_fact_transito    vve_ficha_vta_pedido_veh.habil_fact_transito%TYPE;
    n_veh_comercial          NUMBER;
    v_ind_crm                gen_lval_det.des_valdet%TYPE;
    v_log                    VARCHAR2(10);
    v_tip_prof_veh           vve_proforma_veh.tip_prof_veh%TYPE;
    v_cod_cia                vve_ficha_vta_veh_aut.cod_cia%TYPE;
    v_cod_prov               vve_ficha_vta_veh_aut.cod_prov%TYPE;
    v_fec_usuario_aut        vve_ficha_vta_veh_aut.fec_usuario_aut%TYPE;
    v_veh_comercial          NUMBER;
    v_fec_compro_entrega     vve_ficha_vta_pedido_veh.fec_compro_entrega%TYPE;
    v_gen_fec_compro_entrega vve_ficha_vta_pedido_veh.fec_compro_entrega%TYPE;
    v_query_fecha_compromiso VARCHAR2(20000);
    v_respuesta              VARCHAR2(20000);
    v_cod_filial             vve_ficha_vta_veh.cod_filial%TYPE;
    v_val_pre_veh            vve_proforma_veh_det.val_pre_veh%TYPE;
    v_cod_moneda_prof        vve_proforma_veh.cod_moneda_prof%TYPE;
    l_is_auto                NUMBER;
    l_area_vta               vve_ficha_vta_veh.cod_area_vta%TYPE;
    l_cant_color             NUMBER;
  BEGIN

    ---------------------------------------
    --Validacion de pedido transitivo
    IF (pkg_pedido_veh.fun_tipo_stock_sit_pedido(p_cod_cia,
                                                 p_cod_prov,
                                                 p_num_pedido_veh) = '2') THEN
      p_ret_mens := 'El pedido:' || p_num_pedido_veh ||
                    ' Está en transito, no se puede realizar la asignación definitiva';

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                          'SP_ACTU_ASIG_DEFI',
                                          p_cod_usua_sid,
                                          'Segumiento 0',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);

      RAISE ve_error;

    END IF;
    ----------------------------------------
    ----------------------------------------

    IF p_fechaasidef IS NULL THEN
      p_ret_mens := 'Debe ingresar la Fecha de Asignación Definitiva.';
      RAISE ve_error;
    END IF;
    ------------------------------------
    ---Obtenemos el correo origen o remitente
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;

    -------------------------------------
    ---Solicitud de Desaduanaje
    ---Obtener el tipo de proforma
    SELECT tip_prof_veh, p.cod_area_vta
      INTO v_tip_prof_veh, v_cod_area_vta
      FROM vve_proforma_veh p
     WHERE num_prof_veh = p_num_prof_veh;

    sp_solic_desaduanaje(p_num_ficha_vta_veh,
                         v_cod_area_vta,
                         p_cod_cia,
                         p_cod_prov,
                         p_num_pedido_veh,
                         p_cod_clie,
                         p_cod_propietario,
                         v_tip_prof_veh,
                         p_tipo_ref_proc,
                         p_cod_usua_sid,
                         p_id_usuario,
                         p_ret_esta,
                         p_ret_mens);
    v_respuesta := p_ret_mens;

    IF p_ret_esta = -1 THEN
      RAISE ve_error;
    END IF;

    ------------------------------------
    ---Validación de Warrant
    BEGIN
      SELECT COUNT(1)
        INTO v_cant
        FROM vve_pedido_veh a
       WHERE a.cod_ubica_pedido_veh IN
             ((SELECT cod_ubica_pedido
                FROM vve_ubica_pedido
               WHERE upper(des_ubica_pedido) LIKE '%WARRA%'))
         AND a.num_pedido_veh = p_num_pedido_veh
         AND a.cod_cia = p_cod_cia
         AND a.cod_prov = p_cod_prov;
      IF v_cant > 0 THEN
        sp_alerta_correo_warrant(p_num_ficha_vta_veh,
                                 p_num_prof_veh,
                                 p_cod_cia,
                                 p_cod_prov,
                                 p_num_pedido_veh,
                                 p_cod_clie,
                                 p_tipo_ref_proc,
                                 p_cod_usua_sid,
                                 p_id_usuario,
                                 p_ret_esta,
                                 p_ret_mens);
        IF p_ret_esta <= 0 THEN
          RAISE ve_error;
        END IF;
      END IF;
    END;

    -------------------------------------
    ---Validación de LineUp
    BEGIN
      SELECT cod_area_vta
        INTO v_cod_area_vta
        FROM vve_pedido_veh
       WHERE cod_cia = p_cod_cia
         AND cod_prov = p_cod_prov
         AND num_pedido_veh = p_num_pedido_veh;

      v_line_up := f_pedido_line_up(p_cod_cia,
                                    p_cod_prov,
                                    p_num_pedido_veh,
                                    p_cod_clie);
      IF v_line_up = 'S' THEN
        sp_alerta_correo_line_up(v_cod_area_vta,
                                 p_cod_cia,
                                 p_cod_prov,
                                 p_num_pedido_veh,
                                 p_tipo_ref_proc,
                                 p_cod_usua_sid,
                                 p_id_usuario,
                                 p_ret_esta,
                                 p_ret_mens,
                                 p_num_ficha_vta_veh);
        IF p_ret_esta <= 0 THEN
          RAISE ve_error;
        END IF;
      END IF;
    END;

    -------------------------------------
    ---Liberar Reserva
    BEGIN
      UPDATE vve_pedido_veh_reserva
         SET cod_estado_reserva_pedido = '003'
       WHERE cod_cia = p_cod_cia
         AND cod_prov = (SELECT cod_prov
                           FROM vve_proforma_veh
                          WHERE num_prof_veh = p_num_prof_veh)
         AND num_pedido_veh = p_num_pedido_veh
         AND cod_estado_reserva_pedido <> '003';
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := 'No es posible liberar la reserva';
        RAISE ve_error;
    END;

    -------------------------------------
    ---Actualizar fecha de compromiso comercial
    BEGIN
      BEGIN
        SELECT fec_compro_entrega
          INTO v_fec_compro_entrega
          FROM vve_ficha_vta_pedido_veh
         WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
           AND cod_cia = p_cod_cia
           AND cod_prov = p_cod_prov
           AND num_pedido_veh = p_num_pedido_veh
           AND ind_inactivo = 'N';
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_mens := 'No hay fecha de compromiso de entrega';
          RAISE ve_error;
      END;

    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := 'No es posible actualizar la fecha de compromiso comercial';
        RAISE ve_error;
    END;

    -------------------------------------
    ---Carga de las autorizaciones
    ---Se condiciona la generación de autorizaciones por la facturación en tránsito
    BEGIN
      v_habil_fact_transito := pkg_pedido_veh.f_ind_fact_transito(p_num_ficha_vta_veh,
                                                                  p_cod_cia,
                                                                  p_cod_prov,
                                                                  p_num_pedido_veh);
      IF nvl(v_habil_fact_transito, 'N') = 'N' THEN
        pkg_ficha_vta.pro_autorizaciones_pedido(p_num_ficha_vta_veh,
                                                p_num_prof_veh,
                                                1,
                                                p_cod_cia,
                                                p_cod_prov,
                                                p_num_pedido_veh,
                                                'AN');
      ELSE
        pkg_ficha_vta.pro_autorizaciones_pedido(p_num_ficha_vta_veh,
                                                p_num_prof_veh,
                                                1,
                                                p_cod_cia,
                                                p_cod_prov,
                                                p_num_pedido_veh,
                                                'PD');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := 'Ocurrio un problema al cargar las autorizaciones';
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'sp_actu_asig_defi',
                                            '',
                                            'ASIGNACION DEL PEDIDO',
                                            'sp_actu_asig_defi:' || SQLERRM,
                                            p_num_ficha_vta_veh);
        RAISE ve_error;
    END;

    -------------------------------------
    ---Carga equipos especiales
    BEGIN
      FOR especiales IN (SELECT num_prof_veh,
                                num_reg_det_prof,
                                num_reg_equipo_esp_prof,
                                des_det_equipo_esp_veh,
                                cod_equipo_esp_veh,
                                no_cia,
                                clase,
                                categoria,
                                no_arti,
                                ind_inactivo,
                                can_equipo_esp_veh,
                                obs_prof_equipo_esp,
                                cod_moneda_equipo_esp,
                                val_precio_compra,
                                fec_modi_precio,
                                cod_prov
                           FROM venta.vve_proforma_equipo_esp_veh
                          WHERE num_prof_veh = p_num_prof_veh
                            AND num_reg_det_prof = 1
                            AND nvl(ind_inactivo, 'N') = 'N'
                          ORDER BY num_reg_equipo_esp_prof)
      LOOP
        INSERT INTO venta.vve_pedido_equipo_esp_veh
          (cod_cia,
           cod_prov,
           num_pedido_veh,
           num_reg_equipo_esp_pedido,
           des_det_equipo_esp_veh,
           co_usuario_crea_reg,
           fec_crea_reg,
           cod_equipo_esp_veh,
           no_cia,
           clase,
           categoria,
           no_arti,
           obs_equipo_local,
           can_equipo_esp_veh,
           cod_moneda_equipo_esp,
           val_precio_compra,
           fec_modi_precio,
           ind_inactivo,
           cod_prov_equi_esp)
        VALUES
          (p_cod_cia,
           p_cod_prov,
           p_num_pedido_veh,
           especiales.num_reg_equipo_esp_prof,
           especiales.des_det_equipo_esp_veh,
           p_cod_usua_sid,
           SYSDATE,
           especiales.cod_equipo_esp_veh,
           especiales.no_cia,
           especiales.clase,
           especiales.categoria,
           especiales.no_arti,
           especiales.obs_prof_equipo_esp,
           especiales.can_equipo_esp_veh,
           especiales.cod_moneda_equipo_esp,
           especiales.val_precio_compra,
           especiales.fec_modi_precio,
           'N',
           especiales.cod_prov);
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := 'Ocurrio un problema al cargar los equipos especiales';
        RAISE ve_error;
    END;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                        'SP_ACTU_ASIG_DEFI',
                                        p_cod_usua_sid,
                                        'Segumiento 8',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
    -------------------------------------
    ---Envio de correo de Asignación de Pedido
    BEGIN
      BEGIN
        SELECT cod_cia, cod_prov, fec_usuario_aut
          INTO v_cod_cia, v_cod_prov, v_fec_usuario_aut
          FROM vve_ficha_vta_veh_aut
         WHERE num_pedido_veh = p_num_pedido_veh
           AND cod_aut_ficha_vta = '06'
           AND cod_aprob_ficha_vta_aut = 'A';
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;

      sp_envia_correo_autorizacion(NULL,
                                   '06',
                                   p_num_ficha_vta_veh,
                                   p_num_prof_veh,
                                   v_cod_area_vta,
                                   p_cod_filial,
                                   v_cod_cia,
                                   v_cod_prov,
                                   p_num_pedido_veh,
                                   v_fec_usuario_aut,
                                   p_tipo_ref_proc,
                                   p_cod_usua_sid,
                                   p_id_usuario,
                                   p_ret_esta,
                                   p_ret_mens);

      IF p_ret_esta <= 0 THEN
        RAISE ve_error;
      END IF;
    END;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                        'SP_ACTU_ASIG_DEFI',
                                        p_cod_usua_sid,
                                        'Segumiento 9',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
    -------------------------------------
    --Cambio el estado del pedido a ASIGNADO

    SELECT p.val_pre_veh, p.cod_moneda_prof, f.cod_filial
      INTO v_val_pre_veh, v_cod_moneda_prof, v_cod_filial
      FROM vve_ficha_vta_proforma_veh a,
           vve_ficha_vta_veh          f,
           v_proforma_veh             p
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND a.num_prof_veh = p_num_prof_veh
       AND a.num_ficha_vta_veh = f.num_ficha_vta_veh
       AND a.num_prof_veh = p.num_prof_veh
       AND nvl(a.ind_inactivo, 'N') = 'N';

    BEGIN
      UPDATE venta.vve_pedido_veh
         SET cod_estado_pedido_veh     = decode(cod_estado_pedido_veh,
                                                'F',
                                                cod_estado_pedido_veh,
                                                'D'),
             cod_moneda_vta_pedido_veh = decode(ind_nuevo_usado,
                                                'N',
                                                v_cod_moneda_prof,
                                                cod_moneda_vta_pedido_veh),
             val_vta_pedido_veh        = decode(ind_nuevo_usado,
                                                'N',
                                                v_val_pre_veh,
                                                val_vta_pedido_veh),
             val_pre_vta_final         = decode(ind_nuevo_usado,
                                                'U',
                                                v_val_pre_veh,
                                                val_pre_vta_final),
             cod_filial                = v_cod_filial,
             co_usuario_mod_reg        = p_cod_usua_sid,
             fec_modi_reg              = SYSDATE
       WHERE cod_cia = p_cod_cia
         AND cod_prov = p_cod_prov
         AND num_pedido_veh = p_num_pedido_veh;
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := 'No es posible actualizar el estado del pedido a ASIGNADO';
        RAISE ve_error;
    END;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                        'SP_ACTU_ASIG_DEFI',
                                        p_cod_usua_sid,
                                        'Segumiento 10',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
    -------------------------------------
    ---Actualiza indicador de pedido con asignación definitiva y fecha
    BEGIN
      UPDATE vve_ficha_vta_pedido_veh
         SET ind_asig_def        = 'S',
             fec_asig_definitiva = to_date(p_fechaasidef, 'dd-mm-yyyy')
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
         AND nur_ficha_vta_pedido = p_nur_ficha_vta_pedido;

         PKG_CMS_LEGADO.SP_CMS_FICHAVENTA(p_num_ficha_vta_veh,
                                        P_COD_CIA,
                                        P_COD_PROV,
                                        p_num_pedido_veh,
                                        '1');

    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := 'No es posible actualizar el indicador de Asignación Definitiva';
        RAISE ve_error;
    END;

    p_ret_mens := 'Se actualizó correctamente';
    ---------------
    --Actualiza autorización de ficha venta(trackin)-------------------
    pkg_sweb_five_mant_veh_aut.sp_actu_auto_fich(p_num_ficha_vta_veh,
                                                 '19',
                                                 p_num_pedido_veh,
                                                 'A',
                                                 p_cod_cia,
                                                 p_cod_prov,
                                                 p_cod_usua_sid,
                                                 p_cod_usua_sid,
                                                 p_id_usuario,
                                                 p_ret_esta,
                                                 p_ret_mens,
                                                 p_num_prof_veh);
    IF (p_ret_esta <> 1) THEN
      RAISE ve_error;
    END IF;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                        'SP_ACTU_ASIG_DEFI',
                                        p_cod_usua_sid,
                                        'Segumiento 11',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);
    -------------------------------------
    ---Envio a SAP-CRM
    BEGIN
      SELECT lvd.des_valdet
        INTO v_ind_crm
        FROM gen_lval lv, gen_lval_det lvd
       WHERE lv.no_cia = lvd.no_cia
         AND lv.cod_val = lvd.cod_val
         AND lvd.cod_valdet = 'VEHFICVTA'
         AND lv.cod_val = 'LEGA_CRM';
    EXCEPTION
      WHEN no_data_found THEN
        v_ind_crm := 'NO';
    END;

    BEGIN
      v_error_crm := 'Se actualizó correctamente pero no se pudo enviar el Pedido de Vehículo ' ||
                     p_num_pedido_veh || ' al SAP-CRM';
      IF nvl(v_ind_crm, 'NO') = 'SI' AND p_num_ficha_vta_veh IS NOT NULL AND
         p_num_pedido_veh IS NOT NULL THEN
        --<I - REQ.90500 - SOPORTE LEGADOS - 25/06/2020>
    /*
    v_log := pkg_crm_legado.fun_crm_sap_vehi_ficvta(p_cod_cia,
                                                        p_cod_prov,
                                                        p_num_pedido_veh);
        */
    V_LOG := PKG_CRM_LEGADO.FUN_CRM_SAP_VEHI_FICVTA_N (P_COD_CIA,
                                                           P_COD_PROV,
                                                           P_NUM_PEDIDO_VEH
                              );
        --<F - REQ.90500 - SOPORTE LEGADOS - 25/06/2020>
    IF v_log = 'PEN' THEN
          p_ret_mens := v_error_crm;
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := v_error_crm;
    END;

    BEGIN
      SELECT a.cod_area_vta
        INTO l_area_vta
        FROM vve_ficha_vta_veh a
       WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;

      l_is_auto := pkg_ficha_vta.fun_tipo_vehiculo('00',
                                                   'VEHAUTOM',
                                                   l_area_vta);
    EXCEPTION
      WHEN OTHERS THEN
        l_is_auto := 0;
    END;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                        'SP_ACTU_ASIG_DEFI',
                                        p_cod_usua_sid,
                                        'Segumiento 12',
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);

    IF (l_is_auto = 0) THEN
      UPDATE vve_ficha_vta_veh_aut a
         SET fec_compromiso      = to_date(nvl(p_fechacompromiso,
                                               to_char(v_fec_compro_entrega,
                                                       'DD/MM/YYYY')),
                                           'DD/MM/YYYY'),
             a.obs_ficha_vta_aut = 'Actualizado en la asignación definitiva'

       WHERE cod_aut_ficha_vta = '11'
         AND cod_cia = p_cod_cia
         AND cod_prov = p_cod_prov
         AND a.num_pedido_veh = p_num_pedido_veh
         AND a.num_ficha_vta_veh = p_num_ficha_vta_veh;

         pkg_cms_legado.sp_cms_fecha_comp_vendedor(p_num_ficha_vta_veh,
                                                p_cod_cia,
                                                p_cod_prov,
                                                p_num_pedido_veh,
                                                0,
                                                'Actualizado en la asignación definitiva');
    ELSE
      ----------------Actualizamos colores para los pedidos
      BEGIN
        FOR colores IN (SELECT codcolr.cod_color_fabrica_veh
                          FROM vve_five_prof_colo codcolr
                         WHERE codcolr.num_ficha_vta_veh =
                               p_num_ficha_vta_veh
                           AND codcolr.num_prof_veh = p_num_prof_veh
                           AND nvl(codcolr.ind_inactivo, 'N') = 'N')
        LOOP
          SELECT COUNT(*)
            INTO l_cant_color
            FROM vve_ficha_vta_ped_col_veh a
           WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
             AND a.nur_ficha_vta_pedido = p_nur_ficha_vta_pedido
             AND a.ind_inactivo = 'N';

          IF l_cant_color > 0 THEN
            UPDATE vve_ficha_vta_ped_col_veh a
               SET a.ind_inactivo        = 'S',
                   a.co_usuario_inactiva = p_cod_usua_sid,
                   a.fec_inactiva        = SYSDATE

             WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
               AND a.nur_ficha_vta_pedido = p_nur_ficha_vta_pedido
               AND a.ind_inactivo = 'N';

          END IF;
          pkg_sweb_five_mant_color_veh.sp_inse_colo_pedi_ficha(0,
                                                               p_num_ficha_vta_veh,
                                                               p_nur_ficha_vta_pedido,
                                                               colores.cod_color_fabrica_veh,
                                                               'N',
                                                               p_cod_usua_sid,
                                                               p_id_usuario,
                                                               p_ret_esta,
                                                               p_ret_mens);

        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_mens := 'Ocurrio un problema al cargar';
          RAISE ve_error;
      END;

    END IF;

    p_ret_mens := p_ret_mens || ' - ' || v_respuesta;
    p_ret_esta := 1;

    COMMIT;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_ASIG_DEFI',
                                          p_cod_usua_sid,
                                          'Error controlado',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
      ROLLBACK;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_ASIG_DEFI',
                                          p_cod_usua_sid,
                                          'Actualiza estado a Asignación Definitiva',
                                          p_ret_mens ||
                                          '- SP_ACTU_ASIG_DEFI:' || SQLERRM,
                                          p_num_ficha_vta_veh);
      ROLLBACK;
  END;

  /*--------------------------------------------------------------------------
      Nombre : SP_LIST_SOLI_FACT
      Proposito : Obtiene información de solicitud de facturación
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      05/06/2017   LVALDERRAMA         Creacion
      21/12/2017   BPALACIOS     Modificacion, se agregam los inputs de
                                 nro de proforma y nro de pedido.
    06/08/2018   SOPORTELEGADOS REQ-86491 Modificacion el armado del cursor p_ret_cursor
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_soli_fact
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS

    v_nom_cliente VARCHAR2(1000);
    v_nom_marca   VARCHAR2(200);
    v_ruc         VARCHAR2(200);
    v_dni         VARCHAR2(200);
    v_cod_cliente VARCHAR2(200);

  BEGIN

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_LIST_SOLI_FACT_PASO_4',
                                        NULL,
                                        p_num_ficha_vta_veh || '- ' ||
                                        p_num_prof_veh || '-' ||
                                        p_num_pedido_veh,
                                        p_ret_mens,
                                        p_num_ficha_vta_veh);

    IF nvl(p_num_prof_veh, '0') NOT IN ('0') AND
       p_num_pedido_veh IS NOT NULL THEN
      OPEN p_ret_cursor FOR

        SELECT sf.cod_soli_fact_vehi,
               sf.num_ficha_vta_veh,
               sf.num_prof_veh,
               sf.cod_cia,
               sf.cod_prov,
               sf.num_pedido_veh,
               sf.cod_perso_dir,
               sf.num_reg_dir,
               sf.cod_doc_fact,
               sf.cod_tipo_pago,
               sf.cod_tipo_soli,
               sf.cod_entidad_finan,
               pkg_sweb_mae_gene.fu_desc_maes(4, sf.cod_tipo_pago) des_tipo_pago,
               pkg_gen_select.func_sel_gen_persona(sf.cod_entidad_finan) des_entidad_financiera,
               pkg_sweb_mae_gene.fu_desc_maes(44, sf.cod_doc_fact) des_doc_fact,
               pkg_sweb_mae_gene.fu_desc_maes(45, '0' || sf.cod_tipo_soli) des_tipo_soli,
               sf.obs_sol_facturacion,
               sf.ind_inactivo,
               sf.fec_crea_reg,
               sf.cod_usuario_crea,
               fv.cod_clie,
               g.num_docu_iden,
               g.num_ruc,
               g.nom_perso,
               g.nom_comercial,
               sf.nur_ficha_vta_pedido,
               f.nom_perso nom_clie,
               e.nom_perso nom_propietario,
               h.nom_perso nom_usuario
          FROM venta.vve_soli_fact_vehi sf,
               vve_ficha_vta_veh        fv,
               vve_pedido_veh           fvp,
               gen_persona              g,
               gen_persona              f,
               gen_persona              e,
               gen_persona              h

         WHERE sf.num_ficha_vta_veh = fv.num_ficha_vta_veh
           AND fv.cod_clie = g.cod_perso
           AND sf.num_ficha_vta_veh = p_num_ficha_vta_veh
           AND sf.num_prof_veh = p_num_prof_veh
           AND sf.num_pedido_veh = p_num_pedido_veh
           AND fvp.cod_cia = sf.cod_cia
           AND fvp.cod_prov = sf.cod_prov
           AND fvp.num_pedido_veh = sf.num_pedido_veh
           AND fvp.cod_clie = f.cod_perso(+)
           AND fvp.cod_propietario_veh = e.cod_perso(+)
           AND fvp.cod_usuario_veh = h.cod_perso(+);

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_SOLI_FACT_PASO_1',
                                          NULL,
                                          'Error al obtener información de solicitud de facturación',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);

    ELSE

      IF nvl(p_num_prof_veh, '0') NOT IN ('0') AND p_num_pedido_veh IS NULL THEN
        OPEN p_ret_cursor FOR

          SELECT sf.cod_soli_fact_vehi,
                 sf.num_ficha_vta_veh,
                 sf.num_prof_veh,
                 sf.cod_cia,
                 sf.cod_prov,
                 sf.num_pedido_veh,
                 sf.cod_perso_dir,
                 sf.num_reg_dir,
                 sf.cod_doc_fact,
                 sf.cod_tipo_pago,
                 sf.cod_tipo_soli,
                 sf.cod_entidad_finan,
                 sf.obs_sol_facturacion,
                 sf.ind_inactivo,
                 sf.fec_crea_reg,
                 sf.cod_usuario_crea,
                 fv.cod_clie,
                 g.num_docu_iden,
                 g.num_ruc,
                 g.nom_perso,
                 g.nom_comercial,
                 pkg_sweb_mae_gene.fu_desc_maes(4, sf.cod_tipo_pago) des_tipo_pago,
                 pkg_gen_select.func_sel_gen_persona(sf.cod_entidad_finan) des_entidad_financiera,
                 pkg_sweb_mae_gene.fu_desc_maes(44, sf.cod_doc_fact) des_doc_fact,
                 pkg_sweb_mae_gene.fu_desc_maes(45, '0' || sf.cod_tipo_soli) des_tipo_soli,
                 sf.nur_ficha_vta_pedido
            FROM venta.vve_soli_fact_vehi sf,
                 vve_ficha_vta_veh        fv,
                 gen_persona              g
           WHERE sf.num_ficha_vta_veh = fv.num_ficha_vta_veh
             AND fv.cod_clie = g.cod_perso
             AND sf.num_ficha_vta_veh = p_num_ficha_vta_veh
             AND sf.num_prof_veh = p_num_prof_veh;

        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_LIST_SOLI_FACT_PASO_2',
                                            NULL,
                                            'Error al obtener información de solicitud de facturación',
                                            p_ret_mens,
                                            p_num_ficha_vta_veh);

      ELSE
        IF nvl(p_num_prof_veh, '0') IN ('0') AND
           p_num_pedido_veh IS NOT NULL THEN
          OPEN p_ret_cursor FOR

            SELECT sf.cod_soli_fact_vehi,
                   sf.num_ficha_vta_veh,
                   sf.num_prof_veh,
                   sf.cod_cia,
                   sf.cod_prov,
                   sf.num_pedido_veh,
                   sf.cod_perso_dir,
                   sf.num_reg_dir,
                   sf.cod_doc_fact,
                   sf.cod_tipo_pago,
                   sf.cod_tipo_soli,
                   sf.cod_entidad_finan,
                   sf.obs_sol_facturacion,
                   sf.ind_inactivo,
                   sf.fec_crea_reg,
                   sf.cod_usuario_crea,
                   fv.cod_clie,
                   g.num_docu_iden,
                   g.num_ruc,
                   g.nom_perso,
                   g.nom_comercial,
                   pkg_sweb_mae_gene.fu_desc_maes(4, sf.cod_tipo_pago) des_tipo_pago,
                   pkg_gen_select.func_sel_gen_persona(sf.cod_entidad_finan) des_entidad_financiera,
                   pkg_sweb_mae_gene.fu_desc_maes(44, sf.cod_doc_fact) des_doc_fact,
                   pkg_sweb_mae_gene.fu_desc_maes(45,
                                                  '0' || sf.cod_tipo_soli) des_tipo_soli,
                   sf.nur_ficha_vta_pedido
              FROM venta.vve_soli_fact_vehi sf,
                   vve_ficha_vta_veh        fv,
                   gen_persona              g
             WHERE sf.num_ficha_vta_veh = fv.num_ficha_vta_veh
               AND fv.cod_clie = g.cod_perso
               AND sf.num_ficha_vta_veh = p_num_ficha_vta_veh
               AND sf.num_pedido_veh = p_num_pedido_veh;

          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'SP_LIST_SOLI_FACT_PASO_3',
                                              NULL,
                                              'Error al obtener información de solicitud de facturación',
                                              p_ret_mens,
                                              p_num_ficha_vta_veh);

        ELSE

          OPEN p_ret_cursor FOR

            SELECT sf.cod_soli_fact_vehi,
                   sf.num_ficha_vta_veh,
                   sf.num_prof_veh,
                   sf.cod_cia,
                   sf.cod_prov,
                   sf.num_pedido_veh,
                   sf.cod_perso_dir,
                   sf.num_reg_dir,
                   sf.cod_doc_fact,
                   sf.cod_tipo_pago,
                   sf.cod_tipo_soli,
                   sf.cod_entidad_finan,
                   sf.obs_sol_facturacion,
                   sf.ind_inactivo,
                   sf.fec_crea_reg,
                   sf.cod_usuario_crea,
                   fv.cod_clie,
                   g.num_docu_iden,
                   g.num_ruc,
                   g.nom_perso,
                   g.nom_comercial,
                   --<I-86491>
                   /*vsfc.txt_nombre,
                   vsfc.txt_correo,*/
                   x.nombre txt_nombre,
                   x.correo txt_correo,
                   --<F-86491>
                   pkg_sweb_mae_gene.fu_desc_maes(4, sf.cod_tipo_pago) des_tipo_pago,
                   pkg_gen_select.func_sel_gen_persona(sf.cod_entidad_finan) des_entidad_financiera,
                   pkg_sweb_mae_gene.fu_desc_maes(44, sf.cod_doc_fact) des_doc_fact,
                   pkg_sweb_mae_gene.fu_desc_maes(45,
                                                  '0' || sf.cod_tipo_soli) des_tipo_soli,
                   sf.nur_ficha_vta_pedido
              FROM venta.vve_soli_fact_vehi sf,
                   vve_ficha_vta_veh        fv,
                   gen_persona              g,
                   --<I- 86491>
                   --vve_soli_fact_cont       vsfc
                   /* Se modificó el inner join a la tabla cod_soli_fact_vehi, por el codigo líneas abajo,
                   * dónde se crea la lógica para el armado de concatenar los nombres y/o correos de las
                   * solicitudes que pueda tener un número de pedido.       */
                   (SELECT cod_soli_fact_vehi,
                           ltrim(MAX(sys_connect_by_path(txt_nombre, ', ')),
                                 ',') correo,
                           ltrim(MAX(sys_connect_by_path(txt_correo, '; ')),
                                 ';') nombre
                      FROM (SELECT txt_nombre,
                                   txt_correo,
                                   cod_soli_fact_vehi,
                                   row_number() over(PARTITION BY cod_soli_fact_vehi ORDER BY txt_nombre) rn
                              FROM vve_soli_fact_cont)
                     START WITH rn = 1
                    CONNECT BY PRIOR rn = rn - 1
                           AND PRIOR cod_soli_fact_vehi = cod_soli_fact_vehi
                     GROUP BY cod_soli_fact_vehi
                     ORDER BY cod_soli_fact_vehi) x
            --<F-86491>
             WHERE sf.num_ficha_vta_veh = fv.num_ficha_vta_veh
               AND fv.cod_clie = g.cod_perso
               AND sf.num_ficha_vta_veh = p_num_ficha_vta_veh
               AND sf.cod_soli_fact_vehi = x.cod_soli_fact_vehi;

          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'SP_LIST_SOLI_FACT_PASO_4',
                                              NULL,
                                              'Error al obtener información de solicitud de facturación',
                                              p_ret_mens,
                                              p_num_ficha_vta_veh);

        END IF;

      END IF;

    END IF;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_SOLI_FACT',
                                          NULL,
                                          'Error al obtener información de solicitud de facturación',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_GRABAR_SOLI_FACT
     Proposito : registra la solicitud de facturacion de un pedido
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor           Descripcion
     22/06/2017   LVALDERRAMA     Creacion
     04/12/2017   CSTI-BPALACIOS  Modificacion se agrega el inserta a la
                  tabla VVE_SOLI_FACT_VEHI

  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_soli_fact
  (
    p_num_ficha_vta_veh    IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh         IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_num_pedido_veh       IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_cod_doc_fact         IN vve_ficha_vta_pedido_veh.cod_doc_fact%TYPE,
    p_ind_sol_fact         IN vve_ficha_vta_pedido_veh.ind_sol_fact%TYPE,
    p_obs_facturacion      IN vve_ficha_vta_pedido_veh.obs_facturacion%TYPE,
    p_tipo_sol_fact        IN vve_ficha_vta_pedido_veh.tipo_sol_fact%TYPE,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario           IN vve_soli_fact_vehi.cod_usuario_crea%TYPE,
    p_cod_cia              IN vve_soli_fact_vehi.cod_cia%TYPE,
    p_cod_prov             IN vve_soli_fact_vehi.cod_prov%TYPE,
    p_cod_perso_dir        IN vve_soli_fact_vehi.cod_perso_dir%TYPE,
    p_num_reg_dir          IN vve_soli_fact_vehi.num_reg_dir%TYPE,
    p_cod_tipo_pago        IN vve_soli_fact_vehi.cod_tipo_pago%TYPE,
    p_cod_tipo_soli        IN vve_soli_fact_vehi.cod_tipo_soli%TYPE,
    p_cod_entidad_finan    IN vve_soli_fact_vehi.cod_entidad_finan%TYPE,
    p_obs_sol_facturacion  IN vve_soli_fact_vehi.obs_sol_facturacion%TYPE,
    p_ind_inactivo         IN VARCHAR2, --IN VVE_SOLI_FACT_VEHI.IND_INACTIVO%TYPE,
    p_nur_ficha_vta_pedido IN vve_soli_fact_vehi.nur_ficha_vta_pedido%TYPE,
    p_ret_codigo_solicitud OUT NUMBER,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR2
  ) AS

    ve_error EXCEPTION;
    v_cod_soli_fact_vehi NUMBER;

  BEGIN
    UPDATE venta.vve_ficha_vta_pedido_veh
       SET cod_doc_fact         = p_cod_doc_fact,
           ind_sol_fact         = p_ind_sol_fact,
           obs_facturacion      = p_obs_facturacion,
           tipo_sol_fact        = p_cod_tipo_soli,
           co_usuario_sol_fact  = p_cod_usua_sid,
           fec_usuario_sol_fact = SYSDATE,
           cod_tipo_pago        = p_cod_tipo_pago,
           cod_entidad_finan    = nvl(p_cod_entidad_finan, cod_entidad_finan)
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
       AND num_prof_veh = p_num_prof_veh
       AND num_pedido_veh = p_num_pedido_veh
       AND ind_inactivo = 'N';
    COMMIT;
    --

    --SE EXTRAE EL PK DE LA TABLA    VVE_SOLI_FACT_VEHI
    SELECT seq_vve_soli_fact_vehi.nextval
      INTO v_cod_soli_fact_vehi
      FROM dual;

    INSERT INTO venta.vve_soli_fact_vehi
      (cod_soli_fact_vehi,
       num_ficha_vta_veh,
       num_prof_veh,
       cod_cia,
       cod_prov,
       num_pedido_veh,
       cod_perso_dir,
       num_reg_dir,
       cod_doc_fact,
       cod_tipo_pago,
       cod_tipo_soli,
       cod_entidad_finan,
       obs_sol_facturacion,
       ind_inactivo,
       fec_crea_reg,
       cod_usuario_crea,
       fec_modi_reg,
       cod_usuario_modi,
       nur_ficha_vta_pedido)
    VALUES
      (v_cod_soli_fact_vehi,
       p_num_ficha_vta_veh,
       p_num_prof_veh,
       p_cod_cia,
       p_cod_prov,
       p_num_pedido_veh,
       p_cod_perso_dir,
       p_num_reg_dir,
       p_cod_doc_fact,
       p_cod_tipo_pago,
       p_cod_tipo_soli,
       p_cod_entidad_finan,
       p_obs_sol_facturacion,
       p_ind_inactivo,
       SYSDATE,
       p_id_usuario,
       SYSDATE,
       p_id_usuario,
       p_nur_ficha_vta_pedido);

    -----------------------
    -------Actualiza trackin-------------
    pkg_sweb_five_mant_veh_aut.sp_actu_auto_fich(p_num_ficha_vta_veh,
                                                 '21',
                                                 p_num_pedido_veh,
                                                 'A',
                                                 p_cod_cia,
                                                 p_cod_prov,
                                                 p_cod_usua_sid,
                                                 p_cod_usua_sid,
                                                 p_id_usuario,
                                                 p_ret_esta,
                                                 p_ret_mens,
                                                 p_num_prof_veh);
    IF (p_ret_esta <> 1) THEN
      RAISE ve_error;
    END IF;
    IF p_cod_tipo_soli = 3 THEN
      sp_grabar_soli_fact_tran(p_num_ficha_vta_veh => p_num_ficha_vta_veh,
                               p_cod_cia           => p_cod_cia,
                               p_cod_prov          => p_cod_prov,
                               p_num_pedido_veh    => p_num_pedido_veh,
                               p_cod_usua_sid      => p_cod_usua_sid,
                               p_cod_id_usuario    => p_id_usuario,
                               p_ret_esta          => p_ret_esta,
                               p_ret_mens          => p_ret_mens);

      IF (p_ret_esta <> 1) THEN
        RAISE ve_error;
      END IF;
    END IF;
    COMMIT;

    p_ret_mens             := 'Se guardó solicitud de facturación';
    p_ret_esta             := 1;
    p_ret_codigo_solicitud := v_cod_soli_fact_vehi;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GRABAR_SOLI_FACT:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GRABAR_SOLI_FACT',
                                          p_id_usuario,
                                          p_ret_mens,
                                          p_num_pedido_veh);
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_GRABAR_CLI_CONTACTO
     Proposito : registra contacto de un cliente de facturacion
     Referencias :
     Parametros :P_COD_CONTACTO    ---> codigo de contacto
                 P_COD_CLIENTE     ---> codigo de cliente
                 P_NOM_COMPLETO    ---> nombre completo de contacto
                 P_DIR_CORREO      ---> direccion de correo de contacto
                 P_IND_INACTIVO    ---> indicador de inactivo
                 P_COD_USUA_SID    ---> codigo de usuario
     Log de Cambios
     Fecha        Autor         Descripcion
     22/06/2017   LVALDERRAMA   Creacion
     04/12/2017   JVELEZ        Modificacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_cli_contacto
  (
    p_cod_contacto IN vve_ped_veh_cli_con.cod_contacto%TYPE,
    p_cod_cliente  IN vve_ped_veh_cli_con.cod_cliente%TYPE,
    p_nom_completo IN vve_ped_veh_cli_con.nom_completo%TYPE,
    p_dir_correo   IN vve_ped_veh_cli_con.dir_correo%TYPE,
    p_ind_inactivo IN vve_ped_veh_cli_con.ind_inactivo%TYPE,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_contacto vve_ped_veh_cli_con.cod_contacto%TYPE;
  BEGIN
    IF p_cod_contacto IS NULL OR p_cod_contacto = 0 THEN
      BEGIN
        SELECT nvl(MAX(cod_contacto), 0) + 1
          INTO v_cod_contacto
          FROM vve_ped_veh_cli_con;
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_mens := 'Error no es posible crear código contacto';
          RAISE ve_error;
      END;

      sp_inse_cli_contacto(v_cod_contacto,
                           p_cod_cliente,
                           p_nom_completo,
                           p_dir_correo,
                           p_ind_inactivo,
                           p_cod_usua_sid,
                           p_id_usuario,
                           p_ret_esta,
                           p_ret_mens);
    ELSE
      sp_actu_cli_contacto(p_cod_contacto,
                           p_cod_cliente,
                           p_nom_completo,
                           p_dir_correo,
                           p_ind_inactivo,
                           p_cod_usua_sid,
                           p_id_usuario,
                           p_ret_esta,
                           p_ret_mens);
    END IF;

    IF p_ret_esta = -1 OR p_ret_esta = 0 THEN
      RAISE ve_error;
    END IF;

    p_ret_mens := 'El contacto se grabó correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      IF nvl(p_ret_esta, 0) = 0 THEN
        p_ret_esta := 0;
      END IF;
      ROLLBACK;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GRABAR_CLI_CONTACTO',
                                          p_cod_usua_sid,
                                          'Error al grabar el contacto',
                                          p_ret_mens,
                                          '');
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GRABAR_CLI_CONTACTO',
                                          p_cod_usua_sid,
                                          p_ret_mens,
                                          '');
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_INSE_CLI_CONTACTO
     Proposito : Inserta contactos asociado a un cliente de facturacion
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     23/06/2017   LVALDERRAMA   Creacion
     04/12/2017   JVELEZ        Modificacion
  ---------------------------------------------------------------------------*/
  PROCEDURE sp_inse_cli_contacto
  (
    p_cod_contacto IN vve_ped_veh_cli_con.cod_contacto%TYPE,
    p_cod_cliente  IN vve_ped_veh_cli_con.cod_cliente%TYPE,
    p_nom_completo IN vve_ped_veh_cli_con.nom_completo%TYPE,
    p_dir_correo   IN vve_ped_veh_cli_con.dir_correo%TYPE,
    p_ind_inactivo IN vve_ped_veh_cli_con.ind_inactivo%TYPE,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
  BEGIN

    INSERT INTO venta.vve_ped_veh_cli_con
      (cod_contacto,
       cod_cliente,
       nom_completo,
       dir_correo,
       ind_inactivo,
       co_usuario_crea_reg,
       fec_crea_reg)
    VALUES
      (p_cod_contacto,
       p_cod_cliente,
       p_nom_completo,
       p_dir_correo,
       p_ind_inactivo,
       p_id_usuario,
       SYSDATE);

    COMMIT;

    p_ret_mens := 'Se insertó correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_CLI_CONTACTO',
                                          p_cod_usua_sid,
                                          p_ret_mens,
                                          '');
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_ACTU_CLI_CONTACTO
     Proposito : Actualiza los pedidos pertenecientes a la ficha
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     23/06/2017   LVALDERRAMA   Creacion
     04/12/2017   JVELEZ        Modificacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_actu_cli_contacto
  (
    p_cod_contacto IN vve_ped_veh_cli_con.cod_contacto%TYPE,
    p_cod_cliente  IN vve_ped_veh_cli_con.cod_cliente%TYPE,
    p_nom_completo IN vve_ped_veh_cli_con.nom_completo%TYPE,
    p_dir_correo   IN vve_ped_veh_cli_con.dir_correo%TYPE,
    p_ind_inactivo IN vve_ped_veh_cli_con.ind_inactivo%TYPE,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR2
  ) AS

    ve_error EXCEPTION;
  BEGIN
    UPDATE venta.vve_ped_veh_cli_con
       SET cod_cliente         = p_cod_cliente,
           nom_completo        = p_nom_completo,
           dir_correo          = p_dir_correo,
           ind_inactivo        = p_ind_inactivo,
           co_usuario_modi_reg = p_id_usuario,
           fec_modi_reg        = SYSDATE
     WHERE cod_contacto = p_cod_contacto;

    COMMIT;

    p_ret_mens := 'Se actualizó correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_ACTU_CLI_CONTACTO:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACTU_CLI_CONTACTO',
                                          p_cod_usua_sid,
                                          p_ret_mens,
                                          '');
  END;

  /*-----------------------------------------------------------------------------
     Nombre : SP_GRABAR_SOLI_FACT_TRAN
     Proposito : registra la solicitud de facturacion de un pedido en tránsito
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     07/07/2017   AVILCA        Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_soli_fact_tran
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_cod_cia           IN vve_ficha_vta_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_ficha_vta_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_id_usuario    IN sistemas.usuarios.co_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS

    ve_error EXCEPTION;
    vhabil_fact_transito vve_ficha_vta_pedido_veh.habil_fact_transito%TYPE;
    ve_flag_fact_tran    BOOLEAN := TRUE;
  BEGIN

    vhabil_fact_transito := pkg_pedido_veh.f_ind_fact_transito(p_num_ficha_vta_veh,
                                                               p_cod_cia,
                                                               p_cod_prov,
                                                               p_num_pedido_veh);

    IF nvl(vhabil_fact_transito, 'N') = 'S' THEN
      p_ret_mens := 'El pedido ya tiene habilitado la Facturación en Tránsito';
      p_ret_esta := 0;
    ELSE
      pkg_pedido_veh.p_act_fact_transito(p_num_ficha_vta_veh,
                                         p_cod_cia,
                                         p_cod_prov,
                                         p_num_pedido_veh,
                                         'S');
      p_ret_mens := 'Se guardó solicitud de facturación en tránsito';
      p_ret_esta := 1;
    END IF;

  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_GRABAR_SOLI_FACT_TRAN:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GRABAR_SOLI_FACT_TRAN',
                                          p_cod_id_usuario,
                                          p_ret_mens,
                                          p_num_pedido_veh);
  END;

  /*-----------------------------------------------------------------------------
     Nombre : F_VALIDA_PED_ENTREGADO
     Proposito : Valida si los pedidos de la ficha han sido entregados
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     27/06/2017   AVILCA        Creacion
  ----------------------------------------------------------------------------*/
  FUNCTION f_valida_ped_entregado(p_num_ficha_vta_veh vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE)
    RETURN BOOLEAN IS
    x_contador NUMBER := 0;
    resultado  BOOLEAN;
  BEGIN
    FOR i IN (SELECT cod_estado_pedido_veh
                FROM venta.vve_pedido_veh           p,
                     venta.vve_ficha_vta_pedido_veh f
               WHERE p.cod_cia = f.cod_cia
                 AND p.cod_prov = f.cod_prov
                 AND p.num_pedido_veh = f.num_pedido_veh
                 AND nvl(f.ind_inactivo, 'N') = 'N'
                 AND f.num_ficha_vta_veh = p_num_ficha_vta_veh)
    LOOP

      IF i.cod_estado_pedido_veh NOT IN ('E') THEN
        x_contador := x_contador + 1;
      END IF;

    END LOOP;

    IF x_contador > 0 THEN
      resultado := FALSE;
    ELSE
      resultado := TRUE;
    END IF;

    RETURN resultado;
  END;

  /*-----------------------------------------------------------------------------
     Nombre : FUN_VALIDA_CLIENTE_PEDIDO
     Proposito : Valida al cliente del pedido
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     27/06/2017   AVILCA        Creacion
  ----------------------------------------------------------------------------*/

  FUNCTION fun_valida_cliente_pedido
  (
    p_cod_cia        arcgmc.no_cia%TYPE,
    p_cod_prov       v_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh v_pedido_veh.num_pedido_veh%TYPE,
    p_men_sal        OUT VARCHAR2
  ) RETURN BOOLEAN IS
    wn_tot                 NUMBER(3) := 0;
    wc_no_cia_sap          arcgmc.no_cia_sap%TYPE;
    wc_cod_clie            gen_persona.cod_perso%TYPE;
    wc_des_clie            gen_persona.nom_perso%TYPE;
    wc_cod_propietario_veh gen_persona.cod_perso%TYPE;
    wc_des_propietario_veh gen_persona.nom_perso%TYPE;
    wb_result              BOOLEAN := TRUE;
  BEGIN
    --------------------------------------------------
    -- Obtiene el código SAP de la compañía
    --------------------------------------------------
    BEGIN
      SELECT no_cia_sap
        INTO wc_no_cia_sap
        FROM arcgmc
       WHERE no_cia = p_cod_cia;
    EXCEPTION
      WHEN no_data_found THEN
        wc_no_cia_sap := '0';
    END;

    BEGIN
      SELECT cod_clie, des_clie, cod_propietario_veh, des_propietario_veh
        INTO wc_cod_clie,
             wc_des_clie,
             wc_cod_propietario_veh,
             wc_des_propietario_veh
        FROM v_pedido_veh
       WHERE cod_cia = p_cod_cia
         AND cod_prov = p_cod_prov
         AND num_pedido_veh = p_num_pedido_veh;
    EXCEPTION
      WHEN no_data_found THEN
        wb_result := FALSE;
    END;

    ---------------------------------------------------------------------------------------------------------------
    -- Valida que el cliente de facturación del pedido se encuentre creado en la sociedad que se le va a facturar
    ---------------------------------------------------------------------------------------------------------------
    BEGIN
      SELECT COUNT(a.cod_persona)
        INTO wn_tot
        FROM venta.datos_venta_sap a
       WHERE a.cod_persona = wc_cod_clie
         AND a.bukrs = wc_no_cia_sap;
    EXCEPTION
      WHEN OTHERS THEN
        wn_tot := 0;
    END;

    IF wn_tot = 0 THEN
      wb_result := FALSE;
      p_men_sal := 'Error: El cliente ' || wc_cod_clie || ' - ' ||
                   wc_des_clie || ' no esta creado en la sociedad ' ||
                   wc_no_cia_sap;
    END IF;

    ---------------------------------------------------------------------------------------------------------------
    -- Valida que el cliente propietario del pedido se encuentre creado en la sociedad que se le va a facturar
    ---------------------------------------------------------------------------------------------------------------
    BEGIN
      SELECT COUNT(a.cod_persona)
        INTO wn_tot
        FROM venta.datos_venta_sap a
       WHERE a.cod_persona = wc_cod_propietario_veh
         AND a.bukrs = wc_no_cia_sap;
    EXCEPTION
      WHEN OTHERS THEN
        wn_tot := 0;
    END;

    IF wn_tot = 0 THEN
      wb_result := FALSE;
      p_men_sal := 'Error: El propietario ' || wc_cod_propietario_veh ||
                   ' - ' || wc_des_propietario_veh ||
                   ' no esta creado en la sociedad ' || wc_no_cia_sap;
    END IF;
    RETURN wb_result;
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_PEDI
      Proposito : Lista los pedidos asociados a la ficha de venta
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      24/05/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_pedi
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_prof_veh      IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR
      SELECT cod_cia,
             num_ficha_vta_veh,
             num_prof_vehf,
             num_reg_det_prof,
             ind_prenda,
             ind_inactivo,
             des_cia,
             cod_prov,
             des_prov,
             num_pedido_veh,
             cod_prov_origen_veh,
             cod_prov_carro,
             cod_area_vta,
             des_area_vta,
             ind_origen_pedido_veh,
             ind_nuevo_usado,
             fec_coloca_pedido_veh,
             fec_prod_soli_pedido_veh,
             fec_prod_pedido_veh,
             fec_sal_fabrica,
             fec_embarque,
             fec_llegada_embarque,
             fec_ing_deposito_aduana,
             fec_sal_deposito_aduana,
             fec_vence_deposito_aduana,
             fec_dui_veh,
             fec_ing_patio,
             fec_ing_patio,
             fec_ult_ing_patio,
             fec_entrega_clie,
             fec_ini_garantia_veh,
             fec_carro,
             num_semana_prod_pedido_veh,
             num_dui_deposito,
             num_dui_veh,
             cod_clie,
             des_clie,
             cod_propietario_veh,
             des_propietario_veh,
             cod_usuario_veh,
             des_usuario_veh,
             cod_familia_veh,
             des_familia_veh,
             cod_marca,
             des_marca,
             cod_baumuster,
             des_baumuster,
             cod_config_veh,
             cod_moneda_pedido_veh,
             cod_tipo_veh,
             val_pre_config_veh,
             val_pre_veh,
             vendedor,
             des_vendedor,
             val_vta_pedido_veh,
             cod_moneda_vta_pedido_veh,
             cod_estado_pedido_veh,
             cod_situ_pedido,
             des_situ_pedido,
             cod_adquisicion_pedido_veh,
             cod_ubica_pedido_veh,
             des_ubica_pedido_veh,
             cod_tipo_importacion,
             des_tipo_importacion,
             cod_tipo_embarque,
             des_tipo_embarque,
             cod_embalaje,
             des_embalaje,
             cod_clausula_compra,
             ind_diplomatico,
             cod_deposito_aduana,
             des_deposito_aduana,
             cod_prov_agente_aduana,
             cod_almacen_veh,
             des_almacen_veh,
             num_chasis,
             cod_cmf,
             cod_cmf2,
             baumuster,
             fabrica,
             num_corre,
             num_vin,
             num_motor_veh,
             num_km_garantia_veh,
             obs_pedido_veh,
             num_placa_veh,
             num_prof_veh,
             des_modelo_veh_usado,
             nom_propietario_veh_usado,
             cod_situ_inmatri_pedido,
             des_situ_inmatri_pedido,
             num_dias_rpv,
             fec_titulo_rpv,
             cod_clasi_veh_conta,
             ano_fabricacion_veh,
             fec_prod_carro,
             ind_costeo,
             num_km_veh,
             num_tarjeta_propiedad_veh,
             val_pre_equipo_opci_veh,
             val_pre_tapiz_veh,
             val_pre_pintura_veh,
             cod_clase_veh,
             des_adquisicion_pedido_veh,
             co_usuario_remitir_exp,
             num_titulo_rpv,
             hor_titulo_rpv,
             fec_docu_clie,
             fec_esti_llegada_embarque,
             cod_color_veh,
             cod_super_pintura_veh,
             num_dias,
             fec_sal_stock,
             cod_tipo_docu_sal_stock,
             num_docu_sal_stock,
             fec_inscripcion_rpv,
             ind_sal_stock_conta,
             des_uso_veh
        FROM venta.v_ficha_vta_pedido_veh
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
                                          'SP_LIST_PEDI',
                                          NULL,
                                          'Error al listar los pedidos',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*--------------------------------------------------------------------------
      Nombre : SP_OBTENER_INFO_FACT
      Proposito : Obtiene información de facturación para un pedido
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      05/06/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_obtener_info_fact
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
                                          'SP_OBTENER_INFO_FACT',
                                          NULL,
                                          'Error al obtener información de facturación',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_EST_SOLI_CRED
      Proposito : Lista los estados de solicitud de credito
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      05/06/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_est_soli_cred
  (
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR
      SELECT des_estado_soli_cred, cod_estado_soli_cred
        FROM venta.vve_estado_soli_cred
       WHERE nvl(ind_inactivo, 'N') = 'N';

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_EST_SOLI_CRED',
                                          NULL,
                                          'Error al listar los estados de solicitud de crédito',
                                          p_ret_mens);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_DOCU_FACT
      Proposito : Lista documentos de facturación
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      06/06/2017   AVILCA         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_docu_fact
  (
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR
      SELECT 'FACTURA' nom, 'FA' cod
        FROM dual
      UNION
      SELECT 'BOLETA', 'BO' FROM dual;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_DOCU_FACT',
                                          NULL,
                                          'Error al listar los documentos',
                                          p_ret_mens);
  END;

  /********************************************************************************
    Nombre:     FUN_PED_MODELO
    Proposito:  retorna la descripcion del modelo de un pedido
    Referencias:
    Parametros: P_COD_AREA_VTA      ---> codigo del area de venta
                P_IND_NUEVO_USADO   ---> indicador si es nuevo o usado
                P_COD_FAMILIA_VEH   ---> codigo de familia.
                P_COD_MARCA         ---> Código marca.
                P_COD_BAUMUSTER     ---> codigo baumuster.
                P_COD_CONFIG_VEH    ---> codigo configuracion.

    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        17/07/2017  LVALDERRAMA        Creación del procedure.
  ********************************************************************************/
  FUNCTION fun_ped_modelo
  (
    p_cod_area_vta    vve_pedido_veh.cod_area_vta%TYPE,
    p_ind_nuevo_usado vve_pedido_veh.ind_nuevo_usado%TYPE,
    p_cod_familia_veh vve_pedido_veh.cod_familia_veh%TYPE,
    p_cod_marca       vve_pedido_veh.cod_marca%TYPE,
    p_cod_baumuster   vve_pedido_veh.cod_baumuster%TYPE,
    p_cod_config_veh  vve_pedido_veh.cod_config_veh%TYPE
  ) RETURN VARCHAR2 IS
    wc_des_config_veh VARCHAR2(80);
    p_report          VARCHAR2(9);
  BEGIN
    IF p_cod_area_vta IN ('001', '003') THEN
      p_report := 'RVV40_94';
    ELSE
      p_report := 'RVV40_95';
    END IF;

    IF p_report = 'RVV40_95' AND p_ind_nuevo_usado != 'N' THEN
      SELECT des_baumuster
        INTO wc_des_config_veh
        FROM vve_baumuster
       WHERE cod_familia_veh = p_cod_familia_veh
         AND cod_marca = p_cod_marca
         AND cod_baumuster = p_cod_baumuster;
    ELSE
      SELECT des_config_veh
        INTO wc_des_config_veh
        FROM venta.vve_config_veh
       WHERE cod_familia_veh = p_cod_familia_veh
         AND cod_marca = p_cod_marca
         AND cod_baumuster = p_cod_baumuster
         AND cod_config_veh = p_cod_config_veh;
    END IF;
    RETURN wc_des_config_veh;
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_FACT_FICHA_VENTA
      Proposito : Lista de todos los pedidos de facturacion
      Referencias :
      Parametros :
          P_NUM_FICHA_VTA_VEH ---> Número de ficha de venta.
                  P_RET_CURSOR        ---> Lista de pedidos.
                  P_RET_ESTA          ---> Estado del proceso.
                  P_RET_MENS          ---> Resultado del proceso.
      Log de Cambios
      Fecha        Autor           Descripcion
        21/11/2017 ARAMOS          Modificacion
        28/11/2017 BPALACIOS       Se agrega el campo P_NUM_PEDIDO_VEH para filtrar
                                   si viene el nro de pedido en la consulta.
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_list_fact_ficha_venta
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_ind_paginado      IN VARCHAR2,
    p_limitinf          IN VARCHAR2,
    p_limitsup          IN VARCHAR2,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
    v_query VARCHAR(20000);
    v_final VARCHAR(20000);
  BEGIN

    v_query := ' SELECT
          Z.NUM_FICHA_VTA_VEH,
          Z.NUM_PROF_VEH,
          Z.NUR_FICHA_VTA_PEDIDO,
          Z.COD_CIA,
          Z.COD_PROV,
          Z.NUM_PEDIDO_VEH,
          FVP.COD_PROPIETARIO_VEH COD_PROPIETARIO_VEH,
          F.NOM_PERSO DES_PROPIETARIO_VEH,
          F.NUM_DOCU_IDEN DNI_PROP,
          F.NUM_RUC RUC_PROP,
          FVP.COD_CLIE COD_CLIE,
          E.NOM_PERSO DES_CLIE,
          E.NUM_DOCU_IDEN DNI_CLIE,
          E.NUM_RUC RUC_CLIE,
          FVP.COD_USUARIO_VEH COD_USUARIO_VEH,
          G.NOM_PERSO DES_USUARIO_VEH,
          G.NUM_DOCU_IDEN DNI_USUA,
          G.NUM_RUC RUC_USUA,
         Z.CO_USUARIO_SOL_FACT,
         (SELECT X.TXT_NOMBRES || ''' || ' ' ||
               ''' || X.TXT_APELLIDOS FROM  SISTEMAS.SIS_MAE_USUARIO X WHERE X.TXT_USUARIO = Z.CO_USUARIO_SOL_FACT) NOM_USUARIO_SOL_FACT,
         Z.OBS_FACTURACION,
         Z.COD_DOC_FACT,
         PKG_SWEB_MAE_GENE.FU_DESC_MAES(44,Z.COD_DOC_FACT) DES_DOC_FACT,
         Z.COD_TIPO_PAGO,
         PKG_SWEB_MAE_GENE.FU_DESC_MAES(4,Z.COD_TIPO_PAGO) DES_TIPO_PAGO,
         Z.COD_ENTIDAD_FINAN,
         PKG_GEN_SELECT.FUNC_SEL_GEN_PERSONA(Z.COD_ENTIDAD_FINAN) DES_ENTIDAD_FINANCIERA,
         Z.TIPO_SOL_FACT,
         Z.FEC_USUARIO_SOL_FACT,
         pkg_sweb_five_mant_pedido.FN_FACT_TRANSITO_FV(Z.COD_CIA,Z.COD_PROV,Z.NUM_PEDIDO_VEH,COD_ESTADO_PEDIDO_VEH) ESTADO_TRANSITO_FACT
      FROM
         VVE_FICHA_VTA_PEDIDO_VEH Z,
         vve_proforma_veh PV,
         VVE_PEDIDO_VEH FVP,
         VVE_FICHA_VTA_VEH FVV ,
         GEN_PERSONA F,
         GEN_PERSONA E,
         GEN_PERSONA G
       WHERE
         PV.NUM_PROF_VEH=Z.NUM_PROF_VEH
         AND FVP.COD_CIA=Z.COD_CIA
         AND FVP.COD_PROV=Z.COD_PROV
         AND FVP.NUM_PEDIDO_VEH=Z.NUM_PEDIDO_VEH
         AND FVV.NUM_FICHA_VTA_VEH=Z.NUM_FICHA_VTA_VEH
         AND FVP.COD_CLIE = E.COD_PERSO(+)
         AND FVP.COD_PROPIETARIO_VEH = F.COD_PERSO(+)
         AND FVP.COD_USUARIO_VEH = G.COD_PERSO(+)
         AND FVV.COD_ESTADO_FICHA_VTA_VEH   = ''V''
         AND NVL(Z.IND_INACTIVO,''N'') = ''N'' ';

    IF p_num_ficha_vta_veh IS NOT NULL THEN
      v_query := v_query || ' AND Z.NUM_FICHA_VTA_VEH = ''' ||
                 p_num_ficha_vta_veh || '''' || chr(10);
    END IF;

    IF p_num_pedido_veh IS NOT NULL THEN
      v_query := v_query || ' AND Z.NUM_PEDIDO_VEH = ''' ||
                 p_num_pedido_veh || '''' || chr(10);
    END IF;

    EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM (' || v_query || ')'
      INTO p_ret_cantidad;
    v_final := 'SELECT ROWNUM RM, X.* FROM (' || v_query || ') X ';

    IF nvl(upper(p_ind_paginado), 'S') = 'S' THEN
      v_final := 'SELECT * FROM (' || v_final || ') X WHERE RM BETWEEN ' ||
                 p_limitinf || ' AND ' || p_limitsup;
    END IF;

    --Log de Query
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI',
                                        'SP_LIST_FACT_FICHA_VENTA',
                                        NULL,
                                        'Listar los pedidos',
                                        v_final,
                                        p_num_ficha_vta_veh);

    OPEN p_ret_cursor FOR v_final;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_FACT_FICHA_VENTA',
                                          NULL,
                                          'Error al listar los pedidos',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_GRABAR_FACT_FICHA_VENTA
      Proposito : Lista de todos los pedidos de facturacion
      Referencias :
      Parametros :
                  P_NUM_FICHA_VTA_VEH ---> Número de ficha de venta.
                  P_NUM_PROF_VEH      ---> Número de proforma.
                  P_NUM_PEDIDO_VEH    ---> Número de pedido.
                  COD_CLIE            ---> Codigo de usuario facturacion.
                  COD_PROPIETARIO_VEH ---> Codigo de usuario propietario.
                  COD_USUARIO_VEH     ---> Codigo de usuario usuario.
                  P_RET_ESTA          ---> Estado del proceso.
                  P_RET_MENS          ---> Resultado del proceso.
      Log de Cambios
      Fecha        Autor           Descripcion
        21/11/2017   ARAMOS     Modificacion

  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_fact_ficha_venta
  (
    p_num_ficha_vta_veh   IN vve_ficha_vta_pedido_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh        IN vve_ficha_vta_pedido_veh.num_prof_veh%TYPE,
    p_num_pedido_veh      IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_cod_clie            IN vve_ficha_vta_pedido_veh.cod_perso_dir%TYPE,
    p_cod_propietario_veh IN vve_ficha_vta_pedido_veh.cod_perso_prop%TYPE,
    p_cod_usuario_veh     IN vve_ficha_vta_pedido_veh.cod_perso_usu%TYPE,
    p_id_usuario          IN vve_ficha_vta_pedido_veh.cod_perso_prop%TYPE,
    p_cod_usuario         IN vve_ficha_vta_pedido_veh.cod_perso_usu%TYPE,
    p_ret_esta            OUT NUMBER,
    p_ret_mens            OUT VARCHAR
  ) AS
    v_query                VARCHAR(20000);
    v_final                VARCHAR(20000);
    v_cod_cia              VARCHAR(50);
    v_cod_prov             VARCHAR(50);
    v_nur_ficha_vta_pedido vve_ficha_vta_pedido_veh.nur_ficha_vta_pedido%TYPE;
  BEGIN

    SELECT a.nur_ficha_vta_pedido, cod_cia, cod_prov
      INTO v_nur_ficha_vta_pedido, v_cod_cia, v_cod_prov
      FROM vve_ficha_vta_pedido_veh a
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh
       AND num_pedido_veh = p_num_pedido_veh
       AND ind_inactivo = 'N';

    v_query := ' UPDATE VENTA.VVE_FICHA_VTA_PEDIDO_VEH
    SET
      COD_PERSO_DIR = ''' || p_cod_clie || ''',
      COD_PERSO_PROP =''' || p_cod_propietario_veh || ''',
      COD_PERSO_USU = ''' || p_cod_usuario_veh || '''
    WHERE
      NUM_FICHA_VTA_VEH = ''' || p_num_ficha_vta_veh || '''
      AND NUM_PEDIDO_VEH = ''' || p_num_pedido_veh || '''
      AND nur_ficha_vta_pedido = ''' ||
               v_nur_ficha_vta_pedido || ''''

     ;

    EXECUTE IMMEDIATE v_query;
    COMMIT;

    v_query := '  UPDATE VENTA.VVE_PEDIDO_VEH SET
          COD_CLIE =''' || p_cod_clie || ''',
          COD_PROPIETARIO_VEH =''' || p_cod_propietario_veh || ''',
          COD_USUARIO_VEH = ''' || p_cod_usuario_veh || '''
      WHERE
           NUM_PEDIDO_VEH =''' || p_num_pedido_veh || '''
           AND COD_CIA = ''' || v_cod_cia || '''
           AND COD_PROV =''' || v_cod_prov || '''';

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_GRABAR_FACT_PEDIDO',
                                        NULL,
                                        'SP_GRABAR_FACT_FICHA_VENTA',
                                        v_query,
                                        p_num_ficha_vta_veh);

    EXECUTE IMMEDIATE v_query;
    COMMIT;

    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GRABAR_FACT_FICHA_VENTA',
                                          NULL,
                                          'Error al listar los pedidos',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /********************************************************************************
      Nombre:     SP_INSE_CORREO_SOLI_FACTURACION
      Proposito:  Registra en la tabla Correo las solicitudes de facturacion
      Referencias:
      Parametros: P_NUM_FICHA_VTA_VEH  ---> Numero de ficha de venta.
                  P_DESTINATARIOS      ---> correo destinatario.
                  P_COPIA              ---> Lista de correos CC.
                  P_ASUNTO             ---> Asunto.
                  P_CUERPO             ---> Contenido del correo.
                  P_CORREOORIGEN       ---> Correo remitente.
                  P_COD_USUA_SID       ---> Código del usuario.
                  P_COD_USUA_WEB       ---> Id del usuario.
                  P_RET_ESTA           ---> Estado del proceso.
                  P_RET_MENS           ---> Resultado del proceso.
      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0        12/12/2017  BPALACIOS        Creación del procedure.
  ********************************************************************************/

  PROCEDURE sp_inse_correo_soli_fact(
                                     --P_COD_PLAN_ENTR_VEHI     IN VARCHAR2,
                                     p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
                                     p_destinatarios     IN vve_correo_prof.destinatarios%TYPE,
                                     p_copia             IN vve_correo_prof.copia%TYPE,
                                     p_asunto            IN vve_correo_prof.asunto%TYPE,
                                     p_cuerpo            IN vve_correo_prof.cuerpo%TYPE,
                                     p_correoorigen      IN vve_correo_prof.correoorigen%TYPE,
                                     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
                                     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
                                     p_tipo_ref_proc     IN VARCHAR2,
                                     p_ret_esta          OUT NUMBER,
                                     p_ret_mens          OUT VARCHAR2) AS
    ve_error EXCEPTION;
    v_cod_correo vve_correo_prof.cod_correo_prof%TYPE;
  BEGIN

    BEGIN
      SELECT MAX(cod_correo_prof) INTO v_cod_correo FROM vve_correo_prof;
    EXCEPTION
      WHEN OTHERS THEN
        v_cod_correo := 0;
    END;

    v_cod_correo := v_cod_correo + 1;

    INSERT INTO vve_correo_prof
      (cod_correo_prof,
       cod_ref_proc,
       tipo_ref_proc,
       destinatarios,
       copia,
       asunto,
       cuerpo,
       correoorigen,
       ind_enviado,
       ind_inactivo,
       fec_crea_reg,
       cod_id_usuario_crea)
    VALUES
      (v_cod_correo,
       p_num_ficha_vta_veh, --P_COD_PLAN_ENTR_VEHI,
       p_tipo_ref_proc, --'ET',
       p_destinatarios,
       p_copia,
       p_asunto,
       p_cuerpo,
       p_correoorigen,
       'N',
       'N',
       SYSDATE,
       p_cod_usua_web);

    COMMIT;

    p_ret_mens := 'Se registró correctamente';
    p_ret_esta := 1;
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_CORREO',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /********************************************************************************
      Nombre:     SP_GEN_CORREO_SOLI_FACT
      Proposito:  Proceso que me permite Obtener los correos de los usuarios y generar la plantilla del correo.
      Referencias:
      Parametros: P_NUM_FICHA_VTA_VEH   ---> Numero de Ficha de Venta
                  P_NUM_PEDIDO_VEH      ---> Numero de Pedido
                  P_TIPO_CORREO         ---> Tipo de Correo.
                  P_DESTINATARIOS       ---> Lista de direcciones de los destinatarios,
                  P_ID_USUARIO          ---> Id del usuario.
                  P_TIPO_REF_PROC       ---> Tipo de Referencia del proceso.
                  P_COD_PER_DIR         ---> Codigo Personal de Direccion.
                  P_DIRECCION           ---> Direccion de la empresa.
                  P_CONTACTOS_ADIC      ---> Contactos Adicionales.
                  P_DOCUMENTO           ---> Factura o Boleta.
                  P_TIPO_SOLI           ---> Tipo de solicitud.
                  P_TIPO_PAGO           ---> Tipo de pago.
                  P_NOMBRE_ENTIDAD      ---> Nombre de le entidad.
                  P_OBSERVACIONES       ---> Observaciones
                  P_NOMBRE_CLIENTE      ---> Nombre del cliente.
                  P_RET_ESTA            ---> Estado del proceso.
                  P_RET_MENS            ---> Resultado del proceso.

      TIPO DE CORREO: 1 Solicitud Facturacion

      REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0         01/12/2017  BPALACIOS       Genera la plantilla y lo guarda
                                              para enviar en el cuerpo del correo.
  *********************************************************************************/
  PROCEDURE sp_gen_correo_soli_fact
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_pedido_veh    IN vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_tipo_correo       IN VARCHAR2,
    p_destinatarios     IN VARCHAR2,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,

    p_cod_per_dir    IN VARCHAR2, -- OBTENGO NOMBRE, RUC, DNI DEL CLIENTE
    p_direccion      IN VARCHAR2,
    p_contactos_adic IN VARCHAR2,
    p_documento      IN VARCHAR2,
    p_tipo_soli      IN VARCHAR2,
    p_tipo_pago      IN VARCHAR2,
    p_nombre_entidad IN VARCHAR2,
    p_observaciones  IN VARCHAR2,

    p_nombre_cliente IN VARCHAR2,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_asunto              VARCHAR2(2000);
    v_mensaje             CLOB;
    v_html_head           VARCHAR2(2000);
    v_correoori           usuarios.di_correo%TYPE;
    v_query               VARCHAR2(4000);
    c_usuarios            SYS_REFCURSOR;
    v_cod_id_usuario      sistemas.sis_mae_usuario.cod_id_usuario%TYPE;
    v_txt_correo          sistemas.sis_mae_usuario.txt_correo%TYPE;
    v_txt_usuario         sistemas.sis_mae_usuario.txt_usuario%TYPE;
    v_txt_nombres         sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_txt_apellidos       sistemas.sis_mae_usuario.txt_apellidos%TYPE;
    v_num_pedido_veh      vve_plan_entr_vehi.num_pedido_veh%TYPE;
    v_nom_cliente         VARCHAR2(1000);
    v_ruc                 VARCHAR2(200);
    v_dni                 VARCHAR2(200);
    v_cod_cliente         VARCHAR2(200);
    v_nom_filial          generico.gen_filiales.nom_filial%TYPE;
    v_fec_programada      vve_plan_entr_vehi.fec_programada%TYPE;
    v_nom_usua_resp       VARCHAR2(500);
    v_noti_adicional      VARCHAR2(2000);
    v_ambiente            VARCHAR2(100);
    v_motivo_notificacion VARCHAR2(200);

  BEGIN

    IF (p_destinatarios IS NULL OR p_destinatarios = '') THEN
      p_ret_mens := 'Debe Ingresar al menos un Destinatario';
      RAISE ve_error;
    END IF;

    -- Obtenemos el ambiente del servidor
    SELECT decode(upper(instance_name),
                  'DESA',
                  'Desarrollo',
                  'QA',
                  'Pruebas',
                  'PROD',
                  'Producción')
      INTO v_ambiente
      FROM v$instance;

    -- Obtenemos los correos a Notificar
    IF p_destinatarios IS NOT NULL THEN
      v_query := 'SELECT COD_ID_USUARIO, TXT_CORREO, TXT_USUARIO, TXT_NOMBRES, TXT_APELLIDOS
                   FROM SISTEMAS.SIS_MAE_USUARIO WHERE COD_ID_USUARIO IN (' ||
                 p_destinatarios || ') ';
    END IF;

    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO v_correoori
        FROM sistemas.sis_mae_usuario
       WHERE cod_id_usuario = p_id_usuario;
    EXCEPTION
      WHEN OTHERS THEN
        v_correoori := 'apps@divemotor.com.pe';
    END;

    -- OBTENEMOS EL COD CLIENTE CON EL NRO DE FICHA
    SELECT cod_clie
      INTO v_cod_cliente
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;

    SELECT g.num_docu_iden
      INTO v_dni
      FROM gen_persona g
     WHERE cod_perso = v_cod_cliente; --COD_CLIE

    SELECT g.num_ruc
      INTO v_ruc
      FROM gen_persona g
     WHERE cod_perso = v_cod_cliente; --COD_CLIE

    --Contenido de mensaje
    v_asunto := 'SOLICITUD DE FACTURACION: ' ||
                rtrim(ltrim(to_char(p_num_ficha_vta_veh)));

    v_html_head := '<head>
        <title>Divemotor - Solicitud de Facturacion</title>
        <meta charset="utf-8">

        <style>
          div, p, a, li, td { -webkit-text-size-adjust:none; }

          @media screen and (max-width: 500px) {
            .mainTable,.mailBody,.to100{
              width:100% !important;
            }

          }
        </style>
        <style>
          @media screen and (max-width: 500px) {
            .mailBody{
              padding: 20px 18px !important
            }
            .col3{
              width: 100%!important
            }
          }

        </style>
      </head>';

    --Para Solicitudes de Facturación--
    IF p_tipo_correo = '1' THEN

      OPEN c_usuarios FOR v_query;
      LOOP
        FETCH c_usuarios
          INTO v_cod_id_usuario,
               v_txt_correo,
               v_txt_usuario,
               v_txt_nombres,
               v_txt_apellidos;
        EXIT WHEN c_usuarios%NOTFOUND;

        v_mensaje := '<!DOCTYPE html>
      <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
        ' || v_html_head || '
       <body style="background-color: #eeeeee; margin: 0;">
        <table width="500" class="to100" border="0" align="center" cellpadding="0" cellspacing="0" class="mainTable" style="border-spacing: 0;">
          <tr>
            <td style="padding: 0;">

              <table class="to100" height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="border-spacing: 0;">
                <tr>
                  <td style="padding: 0;">
                    <table height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="background-color: #222222; border-spacing: 0; padding-left: 25px; padding-right: 30px;">
                      <tr style="background-color: #222222;">
                        <td style="background-color: #222222; padding: 0; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">DIVEMOTOR</td>
                        <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Solicitud de Facturacion </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                <tr>
                  <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                    <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Notificación ' ||
                     v_motivo_notificacion ||
                     ' </h1>
                    <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                     rtrim(ltrim(v_txt_nombres)) ||
                     '</span>, se ha generado una notificación solicitud de facturacion de vehículos al cliente final:</p>

                    <div style="padding: 10px 0;">

                    </div>

                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                      <tr>
                        <td>
                          <div class="to100" style="display:inline-block;width: 265px">
                            <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' ||
                     rtrim(ltrim(p_nombre_cliente)) ||
                     '</span></p>
                          </div>
                         </td>
                         <td>
                            <div class="to100" style="display:inline-block;width: 110px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Ficha de Venta </p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"><a href="#" style="color:#0076ff">' ||
                     rtrim(ltrim(p_num_ficha_vta_veh)) ||
                     '</a></p>
                            </div>
                          </td>

                      </tr>
                      <tr>

                          <td>
                            <div class="to100" style="display:inline-block;width: 110px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nro de Pedidos </p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"><a href="#" style="color:#0076ff">' ||
                     rtrim(ltrim(p_num_pedido_veh)) ||
                     '</a></p>
                            </div>
                          </td>
                      </tr>
                    </table>
                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee;">
                      <tr>
                        <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Cliente de facturación</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(p_nombre_cliente)) ||
                     '</p>

                            </div>
                          </td>
                          <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Código de cliente</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(v_cod_cliente)) ||
                     '</p>

                            </div>
                          </td>

                          <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">RUC</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(v_ruc)) ||
                     '</p>

                            </div>
                          </td>
                          <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> DNI</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(v_dni)) ||
                     '</p>

                            </div>
                          </td>
                      </tr>
                    </table>

                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee;">
                      <tr>
                        <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Direccion </p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(p_direccion)) ||
                     '</p>

                            </div>
                          </td>
                          <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Contactos Adicionales</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(p_contactos_adic)) ||
                     '</p>

                            </div>
                          </td>
                      </tr>
                    </table>

                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee;">
                      <tr>
                        <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Documento</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(p_documento)) ||
                     '</p>

                            </div>
                          </td>
                          <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Tipo de pago</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(p_tipo_pago)) ||
                     '</p>

                            </div>
                          </td>

                          <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Entidad financiera </p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(p_nombre_entidad)) ||
                     '</p>

                            </div>
                          </td>
                      </tr>
                    </table>


                     <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee;">
                      <tr>
                        <td>
                            <div class="to100" style="display:inline-block;width: 190px">
                              <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">Tipo de Solicitud</p>
                              <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(p_tipo_soli)) ||
                     '</p>

                            </div>
                          </td>
                      </tr>
                    </table>

                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                      <tr>
                        <td style="padding: 0;">
                          <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Observaciones</span></p>
                          <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                     rtrim(ltrim(p_observaciones)) ||
                     '</p>
                        </td>
                      </tr>
                    </table>


                    <div style="padding: 10px 0;">

                    </div>

                    <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                  </td>
                </tr>
              </table>
              <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                     rtrim(ltrim(v_ambiente)) || '</p>
              </div>
            </td>
          </tr>
        </table>
       </body>
      </html>';

        sp_inse_correo_soli_fact(p_num_ficha_vta_veh, --P_COD_REF_PROC,
                                 v_txt_correo,
                                 NULL,
                                 v_asunto,
                                 v_mensaje,
                                 v_correoori,
                                 NULL,
                                 p_id_usuario,
                                 p_tipo_ref_proc,
                                 p_ret_esta,
                                 p_ret_mens);

      END LOOP;
      CLOSE c_usuarios;

    END IF;

    p_ret_esta := 1;
    p_ret_mens := 'Se ejecuto correctamente';
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_PRO_ENVIAR_EMAIL:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_PRO_ENVIAR_EMAIL',
                                          NULL,
                                          'Error',
                                          p_ret_mens || ' ' ||
                                          p_destinatarios,
                                          p_num_ficha_vta_veh);
  END;

  FUNCTION fn_cod_moneda_prof(p_num_prof_veh VARCHAR) RETURN VARCHAR2 IS
    wc_cod_moneda_prof VARCHAR2(3);
  BEGIN
    SELECT DISTINCT cod_moneda_prof
      INTO wc_cod_moneda_prof
      FROM venta.v_proforma_veh
     WHERE num_prof_veh = p_num_prof_veh;

    RETURN wc_cod_moneda_prof;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION fn_val_pre_veh(p_num_prof_veh VARCHAR) RETURN NUMBER IS
    wc_val_pre_veh NUMBER;
  BEGIN
    SELECT DISTINCT val_pre_veh
      INTO wc_val_pre_veh
      FROM venta.v_proforma_veh
     WHERE num_prof_veh = p_num_prof_veh;

    RETURN wc_val_pre_veh;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  PROCEDURE sp_alerta_correo_warrant
  (
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_proforma_veh.num_prof_veh%TYPE,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_clie          IN VARCHAR2,
    p_tipo_ref_proc     IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) IS
    ve_error EXCEPTION;
    v_warrant_mail_to vve_correo_prof.destinatarios%TYPE;
    v_warrant_mail_cc VARCHAR2(4000);
    v_rolcomex        VARCHAR2(5);
    v_query           VARCHAR2(4000);
    c_usuarios        SYS_REFCURSOR;
    v_correoori       usuarios.di_correo%TYPE;
    v_asunto          VARCHAR2(100);
    v_cant            NUMBER;
    v_html_head       VARCHAR2(32000);
    v_mensaje         VARCHAR2(32000);
    v_txt_nombres     VARCHAR2(200);
    v_txt_correo      VARCHAR2(200);
    v_line_up         CHAR(1);
    v_des_baumuster   v_pedido_veh.des_baumuster%TYPE;
    wc_string         VARCHAR(10);
    url_ficha_venta   VARCHAR(150);

    v_ambiente       VARCHAR2(100);
    v_query          VARCHAR2(4000);
    c_usuarios       SYS_REFCURSOR;
    v_cliente        VARCHAR(500);
    v_documento      VARCHAR(20);
    v_cod_cli        VARCHAR(20);
    v_usuario_ap_nom VARCHAR(50);
    v_dato_usuario   VARCHAR(50);

    v_desc_filial       VARCHAR(500);
    v_desc_area_venta   VARCHAR(500);
    v_desc_cia          VARCHAR(500);
    v_desc_vendedor     VARCHAR(500);
    v_fec_ficha_vta_veh VARCHAR(500);
    v_contactos         VARCHAR(2000);
    v_instancia         VARCHAR(20);
    v_contador          INTEGER;
    l_correos           vve_correo_prof.destinatarios%TYPE;

  BEGIN

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                        'SP_ALERTA_CORREO_WARRANT',
                                        p_cod_usua_sid,
                                        'fv:' || p_num_ficha_vta_veh,
                                        NULL);

    SELECT des_baumuster
      INTO v_des_baumuster
      FROM venta.v_pedido_veh
     WHERE cod_cia = p_cod_cia
       AND cod_prov = p_cod_prov
       AND num_pedido_veh = p_num_pedido_veh;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_GEN_PLANTILLA_CORREO_CESTAD_alx11111',
                                        NULL,
                                        'Error',
                                        '',
                                        '');

    ------------------------------------
    ---Obtenemos los correos de los destinatarios a notificar liberación de Warrant
    FOR destinatarios IN (SELECT lower(x.di_correo) correo,
                                 initcap(rtrim(ltrim(rtrim(ltrim(x.paterno)) || ' ' ||
                                                     rtrim(ltrim(x.materno)) || ' ' ||
                                                     rtrim(ltrim(x.nombre1)) || ' ' ||
                                                     rtrim(ltrim(x.nombre2))))) nomper
                            FROM usuarios x --CAMBIAR SIS_MAE_USUARIO
                           WHERE x.co_usuario = rtrim(ltrim(p_cod_usua_sid))
                          UNION ALL
                          SELECT lower(y.di_correo),
                                 initcap(rtrim(ltrim(rtrim(ltrim(y.paterno)) || ' ' ||
                                                     rtrim(ltrim(y.materno)) || ' ' ||
                                                     rtrim(ltrim(y.nombre1)) || ' ' ||
                                                     rtrim(ltrim(y.nombre2)))))
                            FROM vve_ficha_vta_veh a, arccve x, usuarios y
                           WHERE a.num_ficha_vta_veh =
                                 rtrim(ltrim(p_num_ficha_vta_veh))
                             AND x.vendedor = a.vendedor
                             AND y.no_emple = x.no_emple)
    LOOP
      IF destinatarios.correo IS NOT NULL THEN

        v_warrant_mail_to := rtrim(ltrim(destinatarios.correo)) || ',' ||
                             v_warrant_mail_to;
      END IF;
    END LOOP;

    v_rolcomex := pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                              '000000071',
                                                              'ROLCOMEX');

    SELECT (txt_apellidos || ', ' || txt_nombres)
      INTO v_dato_usuario
      FROM sistemas.sis_mae_usuario
     WHERE cod_id_usuario = p_id_usuario;
    ------------------------------------
    ---Obtenemos los correos con copia a notificar liberación de Warrant
    /*
      cambiar por los que tienen recibir warrant

    --CURSOR c_enviar_mail IS
        SELECT DISTINCT a.txt_correo
          FROM sistemas.sis_mae_usuario a
         INNER JOIN sistemas.sis_mae_perfil_usuario b
            ON a.cod_id_usuario = b.cod_id_usuario
           AND b.ind_inactivo = 'N'
         INNER JOIN sistemas.sis_mae_perfil_procesos c
            ON b.cod_id_perfil = c.cod_id_perfil
           AND c.ind_inactivo = 'N'
           AND C.IND_RECIBE_CORREO='S'
         WHERE c.cod_id_procesos = 94
           AND txt_correo IS NOT NULL;
     */

    v_contador := 1;
    l_correos  := '';

    FOR copia IN (SELECT lower(b.di_correo) correo,
                         initcap(rtrim(ltrim(rtrim(ltrim(b.paterno)) || ' ' ||
                                             rtrim(ltrim(b.materno)) || ' ' ||
                                             rtrim(ltrim(b.nombre1)) || ' ' ||
                                             rtrim(ltrim(b.nombre2))))) nomper
                    FROM usuarios_rol_usuario a, usuarios b
                   WHERE a.cod_rol_usuario = v_rolcomex
                     AND b.co_usuario = a.co_usuario
                  UNION ALL
                  SELECT DISTINCT a.txt_correo correo, txt_apellidos
                    FROM sistemas.sis_mae_usuario a
                   INNER JOIN sistemas.sis_mae_perfil_usuario b
                      ON a.cod_id_usuario = b.cod_id_usuario
                     AND b.ind_inactivo = 'N'
                   INNER JOIN sistemas.sis_mae_perfil_procesos c
                      ON b.cod_id_perfil = c.cod_id_perfil
                     AND c.ind_inactivo = 'N'
                     AND c.ind_recibe_correo = 'S'
                   WHERE c.cod_id_procesos = 94
                     AND txt_correo IS NOT NULL)
    LOOP
      IF copia.correo IS NOT NULL THEN

        IF (v_contador = 1) THEN
          v_warrant_mail_cc := v_warrant_mail_cc ||
                               rtrim(ltrim(copia.correo));
        ELSE
          v_warrant_mail_cc := v_warrant_mail_cc || ', ' ||
                               rtrim(ltrim(copia.correo));
        END IF;
        v_contador := v_contador + 1;

      END IF;
    END LOOP;

    v_asunto := 'Liberar de Warrant el Pedido: ' ||
                rtrim(ltrim(to_char(p_num_pedido_veh)));

    v_html_head := '<head>
        <title>Divemotor - Ficha de Venta</title>
        <meta charset="utf-8">
        <style>
          div, p, a, li, td { -webkit-text-size-adjust:none; }
          @media screen and (max-width: 500px) {
            .mainTable,.mailBody,.to100{
              width:100% !important;
            }
          }
        </style>
        <style>
          @media screen and (max-width: 500px) {
            .mailBody{
              padding: 20px 18px !important
            }
            .col3{
              width: 100%!important
            }
          }
        </style>
      </head>';

    /*
    v_mensaje := '<!DOCTYPE html>
      <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
        ' || v_html_head || '
       <body style="background-color: #eeeeee; margin: 0;">
        <table width="500" class="to100" border="0" align="center" cellpadding="0" cellspacing="0" class="mainTable" style="border-spacing: 0;">
          <tr>
            <td style="padding: 0;">
              <table class="to100" height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="border-spacing: 0;">
                <tr>
                  <td style="padding: 0;">
                    <table height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="background-color: #222222; border-spacing: 0; padding-left: 25px; padding-right: 30px;">
                      <tr style="background-color: #222222;">
                        <td style="background-color: #222222; padding: 0; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">DIVEMOTOR</td>
                        <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Ficha de Venta</td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                <tr>
                  <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                    <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Notificación Liberar de Warrant el Pedido </h1>
                    <p style="margin: 0;">Se ha generado una notificación dentro del módulo de Ficha de Venta:</p>
                    <div style="padding: 10px 0;">
                    </div>
                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                      <tr>
                        <td style="padding: 0;">
                          <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Nro. Pedido</span></p>
                          <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(ltrim(p_num_pedido_veh)) ||
                 '</p>
                        </td>
                      </tr>
                    </table>
                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                      <tr>
                        <td style="padding: 0;">
                          <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Nro. Proforma</span></p>
                          <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(ltrim(p_num_prof_veh)) ||
                 '</p>
                        </td>
                      </tr>
                    </table>
                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                      <tr>
                        <td style="padding: 0;">
                          <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Cliente</span></p>
                          <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(ltrim(p_cod_clie)) ||
                 '</p>
                        </td>
                      </tr>
                    </table>
                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                      <tr>
                        <td style="padding: 0;">
                          <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Núm. Ficha de Venta</span></p>
                          <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(ltrim(p_num_ficha_vta_veh)) ||
                 '</p>
                        </td>
                      </tr>
                    </table>
                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                      <tr>
                        <td style="padding: 0;">
                          <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Modelo</span></p>
                          <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(ltrim(v_des_baumuster)) ||
                 '</p>
                        </td>
                      </tr>
                    </table>
                    <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                      <tr>
                        <td style="padding: 0;">
                          <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Usuario generación de correo</span></p>
                          <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(ltrim(p_cod_usua_sid)) || '</p>
                        </td>
                      </tr>
                    </table>
                    <div style="padding: 10px 0;">
                    </div>
                    <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
       </body>
      </html>';
      */

    SELECT NAME INTO v_instancia FROM v$database;

    IF v_instancia = 'PROD' THEN
      v_instancia := 'Producción';
    END IF;

    -- Obtener datos de la ficha
    SELECT cod_clie,
           pkg_gen_select.func_sel_gen_filial(cod_filial),
           pkg_gen_select.func_sel_gen_area_vta(cod_area_vta),
           pkg_log_select.func_sel_tapcia(cod_cia),
           pkg_cxc_select.func_sel_arccve(vendedor),
           to_date(fec_ficha_vta_veh, 'DD/MM/YY')
      INTO v_cod_cli,
           v_desc_filial,
           v_desc_area_venta,
           v_desc_cia,
           v_desc_vendedor,
           v_fec_ficha_vta_veh
      FROM vve_ficha_vta_veh
     WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;

    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;

    v_mensaje := '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
                <meta charset="utf-8">

                <style>
                  div, p, a, li, td { -webkit-text-size-adjust:none; }

                  @media screen and (max-width: 500px) {
                    .mainTable,.mailBody,.to100{
                      width:100% !important;
                    }

                  }
                </style>
                <style>
                  @media screen and (max-width: 500px) {
                    .mailBody{
                      padding: 20px 18px !important
                    }
                    .col3{
                      width: 100%!important
                    }
                  }
                </style>
              </head>
              <body style="background-color: #eeeeee; margin: 0;">
                <table width="500" class="to100" border="0" align="center" cellpadding="0" cellspacing="0" class="mainTable" style="border-spacing: 0;">
                  <tr>
                    <td style="padding: 0;">

                      <table class="to100" height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="border-spacing: 0;">
                        <tr>
                          <td style="padding: 0;">
                            <table height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="background-color: #222222; border-spacing: 0; padding-left: 25px; padding-right: 30px;">
                              <tr style="background-color: #222222;">
                                <td style="background-color: #222222; padding: 0; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">DIVEMOTOR</td>
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Notificación Liberar de Warrant el Pedido  </h1>
                            <p style="margin: 0;"><span style="font-weight: bold;">Hola ' ||
                 rtrim(v_txt_nombres) ||
                 '</span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">

                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">' || '' ||
                 '</span></p>
                                  </div>

                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nro de Ficha Venta</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;">
                                        <a href="' ||
                 url_ficha_venta || 'fichas-venta/' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') ||
                 '" style="color:#0076ff">
                                          ' ||
                 lpad(p_num_ficha_vta_veh, 12, '0') || '
                                        </a>
                                      </p>
                                  </div>
                                </td>
                              </tr>
                            </table>

                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Filial</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_filial) ||
                 '.</p>
                                </td>

                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Area de Venta</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_area_venta) ||
                 '.</p>
                                </td>

                                 <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Compañia</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_cia) ||
                 '.</p>
                                </td>

                              </tr>

                            </table>

                          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Vendedor</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_desc_vendedor) ||
                 '.</p>
                                </td>
                              </tr>


                           </table>


                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Solicitante</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;">' ||
                 rtrim(v_dato_usuario) ||
                 '</p>
                                </td>

                              </tr>
                            </table>

                       <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #f5f5f5; border-radius: 0px 0px 5px 5px;">
                              <tr>
                                <td style="padding: 0;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;">Notificaciones Adicionales</span></p>
                                  <p style=" font-family: helvetica, arial, sans-serif; line-height: 1.35; margin: 0;"> ' ||
                 rtrim(v_contactos) ||
                 '.</p>
                                </td>
                              </tr>

                        </table>

                            <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                          </td>
                        </tr>
                      </table>
                      <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                        <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - ' ||
                 v_instancia || '</p>
                      </div>
                    </td>
                  </tr>
                </table>
              </body>
          </html>';

    pkg_sweb_five_mant.sp_inse_correo_fv(p_num_ficha_vta_veh ||
                                         p_num_pedido_veh || 'AD', --  P_COD_REF_PROC,
                                         v_warrant_mail_to,
                                         v_warrant_mail_cc,
                                         v_asunto,
                                         v_mensaje,
                                         v_correoori,
                                         p_cod_usua_sid,
                                         p_id_usuario,
                                         p_tipo_ref_proc,
                                         p_ret_esta,
                                         p_ret_mens);

    p_ret_esta := 1;
    p_ret_mens := 'Se ha enviado un correo a la(s) persona(s) responsable(s).';
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'Error Warrant, no se pudo enviar el correo ...' ||
                    substr(SQLERRM, 1, 500);
  END sp_alerta_correo_warrant;

  PROCEDURE sp_alerta_correo_line_up
  (
    p_cod_area_vta      IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_tipo_ref_proc     IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario        IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2,
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE DEFAULT NULL
  ) IS
    ----
    --wc_mensaje     VARCHAR2(20000);  --<86330 comentado>
    wc_mensaje     CLOB; --<86330>
    wc_ret         VARCHAR2(4000);
    wc_des_usuario VARCHAR2(100);
    wc_asunto      VARCHAR2(100);
    wc_area_vta    VARCHAR2(10);
    wc_verifica    VARCHAR2(1);
    wc_style_table VARCHAR2(700) := 'style="clear:both; margin:0.5em auto; border:1px solid #E5D4A1;font: 8pt Arial;"';
    wc_style_cell  VARCHAR2(400) := 'style="background-color:#FAF5E6;"';
    ----
    CURSOR c_sku_reemplazo IS
      SELECT sku_reemplazo,
             cod_config_veh,
             des_config_veh,
             cod_color_veh,
             des_color_fabrica,
             des_ubica_pedido,
             num_pedido_veh
        FROM vve_tmp_sku_reemplazo s
       WHERE s.fec_llegada_embarque =
             (SELECT MAX(m.fec_llegada_embarque)
                FROM vve_tmp_sku_reemplazo m
               WHERE m.sku_reemplazo = s.sku_reemplazo
                 AND m.cod_config_veh = s.cod_config_veh
                 AND m.cod_color_veh = s.cod_color_veh
                 AND m.des_ubica_pedido = s.des_ubica_pedido
                 AND m.num_pedido_veh = s.num_pedido_veh)
      --      AND s.sku_reemplazo=2648
       ORDER BY s.fec_llegada_embarque DESC;
    ----
    CURSOR c_lista(ccod_ubica VARCHAR2) IS
      SELECT u.di_correo,
             u.nombre1 || ' ' || u.paterno || ' ' || u.materno nom_usuario
        FROM usuarios_area_ubicacion c, usuarios u
       WHERE c.cod_area_vta = p_cod_area_vta
         AND c.cod_ubica_pedido = ccod_ubica --'0005'
         AND u.co_usuario = c.co_usuario;
    ----
    cnum_chasis      vve_pedido_veh.num_vin%TYPE;
    nnum_sku         vve_pedido_veh.sku_sap%TYPE;
    vmodelo          VARCHAR2(90);
    vubicacion       VARCHAR2(60);
    vcod_baumuster   vve_pedido_veh.cod_baumuster%TYPE;
    vcod_familia_veh vve_pedido_veh.cod_familia_veh%TYPE;
    vcod_marca       vve_pedido_veh.cod_marca%TYPE;
    vcod_config      vve_pedido_veh.cod_config_veh%TYPE;
    vcod_ubica       vve_pedido_veh.cod_ubica_pedido_veh%TYPE;
  BEGIN
    ----
    wc_asunto := 'Alerta de Reposición de Line Up ';
    ----
    wc_verifica := '0';
    ----
    SELECT v.num_vin num_chasis,
           v.sku_sap,
           pkg_venta_select.func_sel_vve_baumuster(v.cod_familia_veh,
                                                   v.cod_marca,
                                                   v.cod_baumuster) modelo,
           pkg_venta_select.func_sel_vve_ubica_pedido(v.cod_ubica_pedido_veh) ubicacion,
           v.cod_ubica_pedido_veh,
           v.cod_baumuster,
           v.cod_familia_veh,
           v.cod_marca,
           v.cod_config_veh
      INTO cnum_chasis,
           nnum_sku,
           vmodelo,
           vubicacion,
           vcod_ubica,
           vcod_baumuster,
           vcod_familia_veh,
           vcod_marca,
           vcod_config
      FROM vve_pedido_veh v
     WHERE v.cod_cia = p_cod_cia --'06'
       AND v.cod_prov = p_cod_prov --'30100005'
       AND v.num_pedido_veh = p_num_pedido_veh; --'15.WKTH064';

    wc_mensaje := 'Estimados, la siguiente unidad ha sido asignada para la venta :' ||
                  '<br><br>';
    wc_mensaje := wc_mensaje || '<Table align="left" baseline: 5  cellspacing="4" style="clear:both; margin:0.5em auto; border:2px solid #FFFFFF;font: 10pt Arial;">
                    <tr>
                      <td><b>Módelo</b></td>
                      <td>' || ':</td><td>' || vmodelo ||
                  '</td>
                    </tr>
                    <tr>
                      <td><b>SKU</b></td>
                      <td>' || ':</td><td><big><b >' ||
                  nnum_sku || '</b></big></td>
                    </tr>
                    <tr>
                      <td><b>Chasis</b></td>
                      <td>' || ':</td><td>' || cnum_chasis ||
                  '</td>
                    </tr>
                    <tr>
                      <td><b>Ubicación</b></td>
                      <td>' || ':</td><td>' || vubicacion ||
                  '</td>
                    </tr>
                  </table>';

    wc_mensaje := wc_mensaje || '<Table align="left" baseline: 5  cellspacing="4" style="clear:both; margin:0.5em auto; border:2px solid #FFFFFF;font: 10pt Arial;">
                    <tr>
                      <td><b>' ||
                  'Unidades Disponibles para reponer: ' ||
                  '</b></td>
                    </tr>
                    </Table>';

    p_proceso_carga_sku_reemplazo(vcod_familia_veh,
                                  vcod_marca,
                                  vcod_baumuster,
                                  vcod_config,
                                  nnum_sku);
    wc_mensaje := wc_mensaje ||
                  '<div style="{font: 8pt Arial}">
         <table baseline: 5  cellspacing="0" cellpadding="15" ' ||
                  wc_style_table || '>
           <tr>
              <td ' || wc_style_cell || '><b>Pedido</b></td>
              <td ' || wc_style_cell || '><b>SKU</b></td>
              <td ' || wc_style_cell || '><b>Modelo</b></td>
              <td ' || wc_style_cell || '><b>Color</b></td>
              <td ' || wc_style_cell || '><b>Ubicación</b></td>
           </tr>';

    FOR c IN c_sku_reemplazo
    LOOP

      wc_mensaje := wc_mensaje || '
          <tr>
            <td> ' || c.num_pedido_veh ||
                    '</td>
            <td> ' || c.sku_reemplazo ||
                    '</td>
            <td> ' || c.des_config_veh ||
                    '</td>
            <td> ' || c.des_color_fabrica ||
                    '</td>
            <td> ' || c.des_ubica_pedido ||
                    '</td>
          </tr>';

      ----
      wc_verifica := '1';
      ----
    END LOOP;

    ----
    IF wc_verifica = '1' THEN
      wc_mensaje := wc_mensaje || '</table>';
      BEGIN
        ----
        wc_mensaje := wc_mensaje ||
                      '</table></div><br><br><font size="1" color="FF0000">NOTA: Este mensaje ha sido autogenerado por el Sistema - PROD.</font><BR>';
        FOR c IN c_lista(vcod_ubica)
        LOOP
          pkg_sweb_five_mant.sp_inse_correo_fv(p_num_ficha_vta_veh ||
                                               p_num_pedido_veh || 'AD', --  P_COD_REF_PROC,
                                               c.di_correo,
                                               'mgeldres@diveimport.com.pe',
                                               wc_asunto,
                                               wc_mensaje,
                                               'codisa-naf@divemotor.com.pe',
                                               p_cod_usua_sid,
                                               p_id_usuario,
                                               p_tipo_ref_proc,
                                               p_ret_esta,
                                               p_ret_mens);
        END LOOP;

        p_ret_esta := 1;
        p_ret_mens := 'Se ha enviado un correo a la(s) persona(s) responsable(s).';
      EXCEPTION
        WHEN OTHERS THEN
          p_ret_esta := -1;
          p_ret_mens := 'Error Line Up, no se pudo enviar el correo ...' ||
                        substr(SQLERRM, 1, 500);
      END;
    END IF;
    ----
  END sp_alerta_correo_line_up;

  /********************************************************************************

  REVISIONES:
      Version    Fecha       Autor            Descripcion
      ---------  ----------  ---------------  ------------------------------------
      1.0        28/08/2018  SOPORTELEGADOS   Se generarón 3 variables, wn_cod_clausula_compra, wn_tipo_soli, wn_clausula_compra.
                        Se modificó la lógica para validar si la proforma tiene clausala de compra = 005.
      2.0        14/01/2020  ASALAS           REQ-89878
  *********************************************************************************/
  PROCEDURE sp_solic_desaduanaje
  (
    p_num_ficha_vta_veh   IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_area_vta        IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_cia             IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov            IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh      IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_clie            IN vve_pedido_veh.cod_clie%TYPE,
    p_cod_propietario_veh IN vve_pedido_veh.cod_propietario_veh%TYPE,
    p_tipo_prof_veh       IN vve_proforma_veh.tip_prof_veh%TYPE,
    p_tipo_ref_proc       IN VARCHAR2,
    p_cod_usua_sid        IN sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario          IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta            OUT NUMBER,
    p_ret_mens            OUT VARCHAR2
  ) IS
    wn_cont_situ22      NUMBER;
    wn_cont_situ12      NUMBER;
    wn_cont_situ06      NUMBER;
    wn_cont_situ14      NUMBER; --<81398>Marco Geldres/30-092015/Se agrego la situación14 Númerado en Aduana.
    wn_cont_situ66      NUMBER; --<84772>Marco Geldres/30-092015/Se agrego la situación66 Stock Contable,para los casos de compañías que no son importer.
    alert_button        NUMBER;
    wc_ind_permiso      CHAR(1) := 'N';
    wc_asunto           VARCHAR2(100);
    wc_mensaje          VARCHAR2(32767);
    wc_mensaje1         VARCHAR2(32767);
    wc_mensaje2         VARCHAR2(32767);
    wc_mensaje3         VARCHAR2(32767);
    wc_dir_correo_from  usuarios.di_correo%TYPE; --<RQ46618> HHUANILO /05-12-2013/ se cambia a %type
    wc_des_usuario_from VARCHAR2(100);
    wn_cantidad         NUMBER(6);
    wc_pagos            VARCHAR2(1);
    wc_sol              VARCHAR2(1);
    wn_total            NUMBER;
    wn_resul            NUMBER;
    wn_conta_reg        NUMBER;
    wc_nom_clie         VARCHAR2(150);
    wc_nom_propietario  VARCHAR2(150);
    wc_cod_baumuster    VARCHAR2(150);
    wc_des_baumuster    VARCHAR2(150);
    wc_num_chasis       VARCHAR2(150);
    wn_val_monto_pos    NUMBER;
    wn_cod_familia_veh  NUMBER;
    wc_cod_marca        VARCHAR2(150);
    ve_error      EXCEPTION;
    ve_error_mens EXCEPTION;
    v_contador         INTEGER;
    l_correos          vve_correo_prof.destinatarios%TYPE;
    v_warrant_mail_cc  VARCHAR2(4000);
    v_dest_desaduanaje vve_correo_prof.destinatarios%TYPE;
    v_cod_fili         VARCHAR2(4000);
    --<REQ-86366>
    wn_cod_clausula_compra vve_clausula_compra.cod_clausula_compra%TYPE;
    wn_tipo_soli           VARCHAR2(60);
    wn_clausula_compra     VARCHAR2(60);
    --<REQ-86366>
    CURSOR c_pagos IS
      SELECT cod_tipo_docu, num_docu, val_monto, fec_docu
        FROM vve_pedido_veh_pagos
       WHERE cod_cia = p_cod_cia
         AND cod_prov = p_cod_prov
         AND num_pedido_veh = p_num_pedido_veh
         AND cod_tipo_docu = 'RE';
    CURSOR c1 IS
      SELECT DISTINCT lower(u.di_correo) di_correo,
                      initcap(u.nombre1 || ' ' || u.paterno) des_usuario
        FROM usuarios_acti_pedido_veh a,
             usuarios                 u,
             usuarios_acti_area_vta   v
       WHERE a.cod_acti_pedido_veh = '0019' --0019 Solicitud de Desaduanaje
         AND a.co_usuario = u.co_usuario
         AND a.co_usuario = v.co_usuario
         AND a.nur_usuario_acti_pedido = v.nur_usuario_acti_pedido
         AND u.estado = '001'
         AND v.cod_area_vta = p_cod_area_vta
         AND a.ind_recibe_email = 'S'
         AND nvl(a.ind_inactivo, 'N') = 'N'
         AND nvl(v.ind_inactivo, 'N') = 'N'
         AND EXISTS
       (SELECT 1
                FROM usuarios_acti_filial f
               WHERE v.co_usuario = f.co_usuario
                 AND v.nur_usuario_acti_pedido = f.nur_usuario_acti_pedido
                 AND v.nur_usua_acti_area_vta = f.nur_usua_acti_area_vta
                 AND f.cod_filial = v_cod_fili
                 AND nvl(f.ind_inactivo, 'N') = 'N')
      UNION
      SELECT DISTINCT lower(u.di_correo) di_correo,
                      initcap(u.nombre1 || ' ' || u.paterno) des_usuario
        FROM usuarios u
       WHERE u.co_usuario IN ('CHURTADO', 'ESANTOS', 'CPRADO', 'KGUIZADO')
         AND u.estado = '001' --<REQ-89878 ASALAS>

      ;
    vtipo_cia       VARCHAR2(2); --<84772>Marco Geldres/06-Nov-2017/Se declara variable para tipo de compañía.
    wc_string       VARCHAR(10);
    url_ficha_venta VARCHAR(150);

  BEGIN
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                        'SP_SOLIC_DESADUANAJE',
                                        p_id_usuario,
                                        'Inicio',
                                        NULL,
                                        p_num_pedido_veh);
    BEGIN
      SELECT a.cod_filial
        INTO v_cod_fili
        FROM vve_ficha_vta_veh a
       WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;
    EXCEPTION
      WHEN OTHERS THEN
        p_ret_mens := 'Error: Ficha venta no existe.';
        RAISE ve_error;
    END;

    v_contador := 1;
    l_correos  := '';

    FOR copia IN (SELECT DISTINCT a.txt_correo correo, txt_apellidos
                    FROM sistemas.sis_mae_usuario a
                   INNER JOIN sistemas.sis_mae_perfil_usuario b
                      ON a.cod_id_usuario = b.cod_id_usuario
                     AND b.ind_inactivo = 'N'
                   INNER JOIN sistemas.sis_mae_perfil_procesos c
                      ON b.cod_id_perfil = c.cod_id_perfil
                     AND c.ind_inactivo = 'N'
                     AND c.ind_recibe_correo = 'S'
                   WHERE c.cod_id_procesos = 94
                     AND txt_correo IS NOT NULL)
    LOOP
      IF copia.correo IS NOT NULL THEN

        IF (v_contador = 1) THEN
          v_warrant_mail_cc := v_warrant_mail_cc ||
                               rtrim(ltrim(copia.correo));
        ELSE
          v_warrant_mail_cc := v_warrant_mail_cc || ', ' ||
                               rtrim(ltrim(copia.correo));
        END IF;
        v_contador := v_contador + 1;

      END IF;
    END LOOP;

    -- Obtener url de ambiente
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                        'SP_SOLIC_DESADUANAJE',
                                        p_id_usuario,
                                        'paso 10',
                                        NULL,
                                        p_num_pedido_veh);

    IF nvl(p_tipo_prof_veh, '1') = '1' THEN
      --<81004>Marco Geldres/02-10-2015/Se agrega el IF de validación de tipo de proforma
      --<I 84772>Marco Geldres/06-Nov-2017/Se captura el tipo de compañía, la cual nos indica que validaciones realizar.
      BEGIN
        SELECT c.tipo_cia
          INTO vtipo_cia
          FROM arfamc c
         WHERE c.no_cia = p_cod_cia;
      EXCEPTION
        WHEN no_data_found THEN
          vtipo_cia := '02';
      END;
      --<F 84772>
      IF vtipo_cia = '01' THEN
        --<84772>Marco Geldres/06-Nov-2017/Se agrega la condicional por tipo de compañía.
        BEGIN
          SELECT COUNT(1)
            INTO wn_cont_situ22
            FROM vve_pedido_veh_situ s
           WHERE s.cod_cia = p_cod_cia
             AND s.cod_prov = p_cod_prov
             AND s.num_pedido_veh = p_num_pedido_veh
             AND
                --<I 83614>Marco Geldres/11-09-2017/Se agrego la nueva situación de 24 solicitud de desaduanaje adelantada
                 nvl(s.ind_anulado, 'N') = 'N'
             AND s.cod_situ_pedido IN ('22', '24');
          --<F 83614>
        EXCEPTION
          WHEN OTHERS THEN
            wn_cont_situ22 := 0;
        END;
        BEGIN
          SELECT COUNT(1)
            INTO wn_cont_situ06
            FROM vve_pedido_veh_situ s
           WHERE s.cod_cia = p_cod_cia
             AND s.cod_prov = p_cod_prov
             AND s.num_pedido_veh = p_num_pedido_veh
             AND nvl(s.ind_anulado, 'N') = 'N'
             AND --<83614>Marco Geldres/Se agrego indicador de anulación, no debe de tomar en cuenta los anulados
                 s.cod_situ_pedido = '06';
        EXCEPTION
          WHEN OTHERS THEN
            wn_cont_situ06 := 0;
        END;
        BEGIN
          SELECT COUNT(1)
            INTO wn_cont_situ12
            FROM vve_pedido_veh_situ s
           WHERE s.cod_cia = p_cod_cia
             AND s.cod_prov = p_cod_prov
             AND s.num_pedido_veh = p_num_pedido_veh
             AND nvl(s.ind_anulado, 'N') = 'N'
             AND --<83614>Marco Geldres/Se agrego indicador de anulación, no debe de tomar en cuenta los anulados
                 s.cod_situ_pedido = '12';
        EXCEPTION
          WHEN OTHERS THEN
            wn_cont_situ12 := 0;
        END;
        --<I 81398>Marco Geldres/30-092015/Se agrego la situación 14 Númerado en Aduana.
        BEGIN
          SELECT COUNT(1)
            INTO wn_cont_situ14
            FROM vve_pedido_veh_situ s
           WHERE s.cod_cia = p_cod_cia
             AND s.cod_prov = p_cod_prov
             AND s.num_pedido_veh = p_num_pedido_veh
             AND nvl(s.ind_anulado, 'N') = 'N'
             AND --<83614>Marco Geldres/Se agrego indicador de anulación, no debe de tomar en cuenta los anulados
                 s.cod_situ_pedido = '14';
        EXCEPTION
          WHEN OTHERS THEN
            wn_cont_situ14 := 0;
        END;

        --<F 81398>
        --<I 84772>Marco Geldres/06-Nov-2017/se agrego condición para casos de compañías no importadora. se obtiene la situación de stock contable.
      ELSE
        BEGIN
          SELECT COUNT(1)
            INTO wn_cont_situ66
            FROM vve_pedido_veh_situ s
           WHERE s.cod_cia = p_cod_cia
             AND s.cod_prov = p_cod_prov
             AND s.num_pedido_veh = p_num_pedido_veh
             AND nvl(s.ind_anulado, 'N') = 'N'
             AND s.cod_situ_pedido = '66';
        EXCEPTION
          WHEN OTHERS THEN
            wn_cont_situ14 := 0;
        END;
      END IF;
      --<F 84772>
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                          'SP_SOLIC_DESADUANAJE',
                                          p_cod_usua_sid,
                                          'Paso 20',
                                          p_ret_mens,
                                          p_num_pedido_veh);

      IF vtipo_cia = '01' THEN
        --<84772>Marco Geldres/06-Nov-2017/Se agrega condicional de Tipo de Compañía
        IF wn_cont_situ12 = 0 THEN
          p_ret_mens := 'El pedido al menos debe estar en Aduana';
          RAISE ve_error;
        END IF;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                            'SP_SOLIC_DESADUANAJE',
                                            p_cod_usua_sid,
                                            'Datos',
                                            wn_cont_situ06 || '-' ||
                                            wn_cont_situ22 || '-' ||
                                            wn_cont_situ14 || '-' ||
                                            wn_cont_situ12,
                                            p_num_ficha_vta_veh);

        IF wn_cont_situ06 = 0 AND wn_cont_situ22 = 0 AND wn_cont_situ14 = 0 AND
           wn_cont_situ12 > 0 THEN

          --<REQ-86366>
          BEGIN
            SELECT DISTINCT pv.cod_clausula_compra
              INTO wn_cod_clausula_compra
              FROM vve_ficha_vta_pedido_veh vpv, vve_proforma_veh pv
             WHERE pv.num_prof_veh = vpv.num_prof_veh
               AND vpv.cod_cia = p_cod_cia
               AND vpv.cod_prov = p_cod_prov
               AND vpv.num_pedido_veh = p_num_pedido_veh
               AND nvl(vpv.ind_inactivo, 'N') = 'N';
            --AND PV.COD_CLAUSULA_COMPRA = '005';
          EXCEPTION
            WHEN no_data_found THEN
              wn_cod_clausula_compra := NULL;
          END;
          --<REQ-86366>

          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_211',
                                              'sp_solic_desaduanaje',
                                              p_cod_usua_sid,
                                              'Error',
                                              p_ret_mens,
                                              p_num_pedido_veh);
          --<81398>Marco Geldres/30-092015/Se agrego la situación 14 Númerado en Aduana.
          BEGIN
            SELECT nvl(ind_permiso, 'N')
              INTO wc_ind_permiso
              FROM venta.vve_control_desadu;
          EXCEPTION
            WHEN OTHERS THEN
              wc_ind_permiso := 'N';
          END;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                              'SP_SOLIC_DESADUANAJE',
                                              p_id_usuario,
                                              'Paso 30',
                                              p_ret_mens,
                                              p_num_pedido_veh);
          IF wc_ind_permiso = 'N' THEN
            p_ret_mens := 'Error: Desaduanaje bloqueado...';
            RAISE ve_error;
          END IF;

          --<REQ-86366>
          SELECT a.des_clausula_compra
            INTO wn_clausula_compra
            FROM vve_clausula_compra a
           WHERE a.cod_clausula_compra = wn_cod_clausula_compra;

          IF wn_cod_clausula_compra = '005' THEN
            wc_asunto    := 'Solicitud de Endoso de Documento FV:' ||
                            p_num_ficha_vta_veh || ' - ' || 'Pedido:' ||
                            p_num_pedido_veh;
            wn_tipo_soli := 'Solicitud de endoso de documento';
            --wn_clausula_compra:= 'Venta en Aduana';
          ELSE

            wc_asunto    := 'Solicitud Desaduanaje FV:' ||
                            p_num_ficha_vta_veh || ' - ' || 'Pedido:' ||
                            p_num_pedido_veh;
            wn_tipo_soli := 'Desaduanaje';
          END IF;
          --<REQ-86366>

          sp_pro_reg_pedido_veh_situ(p_cod_cia,
                                     p_cod_prov,
                                     p_num_pedido_veh,
                                     '22',
                                     SYSDATE,
                                     NULL,
                                     NULL,
                                     ''); --Solicitud de internacion
          BEGIN
            UPDATE vve_pedido_veh
               SET cod_situ_pedido    = '22', -- solicitud de desaduanaje
                   co_usuario_mod_reg = p_cod_usua_sid,
                   fec_modi_reg       = SYSDATE
             WHERE cod_cia = p_cod_cia
               AND cod_prov = p_cod_prov
               AND num_pedido_veh = p_num_pedido_veh;
          EXCEPTION
            WHEN OTHERS THEN
              p_ret_mens := 'Problemas en la actualización';
              RAISE ve_error;
          END;

          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                              'SP_SOLIC_DESADUANAJE',
                                              p_id_usuario,
                                              'Paso 40',
                                              p_ret_mens,
                                              p_num_pedido_veh);
          IF p_cod_clie IS NOT NULL THEN
            BEGIN
              SELECT nom_clie
                INTO wc_nom_clie
                FROM cxc_mae_clie
               WHERE cod_clie = p_cod_clie;
            EXCEPTION
              WHEN OTHERS THEN
                wc_nom_clie := '';
            END;
          END IF;
          IF p_cod_propietario_veh IS NOT NULL THEN
            BEGIN
              SELECT nom_clie
                INTO wc_nom_propietario
                FROM cxc_mae_clie
               WHERE cod_clie = p_cod_propietario_veh;
            EXCEPTION
              WHEN no_data_found THEN
                NULL;
            END;
          END IF;
          --
          BEGIN
            SELECT cod_familia_veh, cod_marca, cod_baumuster, num_vin
              INTO wn_cod_familia_veh,
                   wc_cod_marca,
                   wc_cod_baumuster,
                   wc_num_chasis
              FROM vve_pedido_veh
             WHERE cod_cia = p_cod_cia
               AND cod_prov = p_cod_prov
               AND num_pedido_veh = p_num_pedido_veh;
          EXCEPTION
            WHEN no_data_found THEN
              NULL;
          END;
          IF wc_cod_baumuster IS NOT NULL THEN
            BEGIN
              SELECT des_baumuster
                INTO wc_des_baumuster
                FROM vve_baumuster
               WHERE cod_familia_veh = wn_cod_familia_veh
                 AND cod_marca = wc_cod_marca
                 AND cod_baumuster = wc_cod_baumuster;
            EXCEPTION
              WHEN no_data_found THEN
                NULL;
            END;
          END IF;

          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                              'SP_SOLIC_DESADUANAJE',
                                              p_id_usuario,
                                              'Paso 50',
                                              p_ret_mens,
                                              p_num_pedido_veh);
          wn_total    := 0;
          wc_mensaje  := '
          <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                <tr>
                  <td><b>Pedido</b></td>
                  <td>' || ':</td><td><b>' ||
                         p_num_pedido_veh || '</b></td>
                </tr>
                <tr>
                  <td><b>Modelo</b></td>
                  <td>' || ':</td><td>' ||
                         wc_des_baumuster || '</td>
                </tr>
                <tr>
                  <td><b>Chasis</b></td>
                  <td>' || ':</td><td>' ||
                         wc_num_chasis || '</td>
                </tr>
                <tr>
                  <td><b>Cliente Facturación</b></td>
                  <td>' || ':</td><td>' ||
                         wc_nom_clie || '</td>
                </tr>
                <tr>
                  <td><b>Cliente Propietario</b></td>
                  <td>' || ':</td><td>' ||
                         wc_nom_propietario || '</td>
                </tr>
                <tr>
                  <td><b>Clausla de Compra</b></td>
                  <td>' || ':</td><td>' ||
                         wn_clausula_compra || '</td>
                </tr>
                <tr>
                  <td><b>Observación</b></td>
                  <td>' || ':</td><td>' ||
                         REPLACE('', chr(10), '<br>') ||
                         '</td>
                </tr>
              </table>';
          wc_pagos    := 'N';
          wc_mensaje2 := '';
          FOR c_pago IN c_pagos
          LOOP
            IF c_pago.cod_tipo_docu IS NOT NULL THEN
              IF c_pago.val_monto < 0 THEN
                wn_val_monto_pos := c_pago.val_monto * -1;
              ELSE
                wn_val_monto_pos := c_pago.val_monto;
              END IF;
              wc_pagos    := 'S';
              wc_mensaje2 := wc_mensaje2 ||
                             '<tr><td style="clear:both; border:1px solid #E5D4A1;font: 8pt Arial;">' ||
                             c_pago.cod_tipo_docu || '</td>' ||
                             '<td style="clear:both; border:1px solid #E5D4A1;font: 8pt Arial;">' ||
                             c_pago.num_docu || '</td>' ||
                             '<td style="clear:both; border:1px solid #E5D4A1;font: 8pt Arial;">' ||
                             to_char(wn_val_monto_pos, '99,999,999,990.99') ||
                             '</td>' ||
                             '<td style="clear:both; border:1px solid #E5D4A1;font: 8pt Arial;">' ||
                             to_char(c_pago.fec_docu, 'dd/mm/yyyy') ||
                             '</td></tr>';
              wn_total    := nvl(wn_total, 0) + wn_val_monto_pos;
            END IF;
          END LOOP;
          IF wc_pagos = 'S' THEN
            wc_mensaje := wc_mensaje || '<br><b>Pagos a Cuenta</b><br>
                        <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #eeeeee; border-radius: 0px 0px 5px 5px;">
                        <tr>
                        <td align="center" style="background-color:#FAF5E6;"><b>T. Doc.</b></td>
                        <td align="center" style="background-color:#FAF5E6;"><b>N. Doc.</b></td>
                        <td align="center" style="background-color:#FAF5E6;"><b>Monto Doc.</b></td>
                        <td align="center" style="background-color:#FAF5E6;"><b>Fecha</b></td>
                        </tr>';
            wc_mensaje := wc_mensaje || wc_mensaje2;
            wc_mensaje := wc_mensaje || '</table><br><b>Total Pagos   : ' ||
                          to_char(wn_total, '999,999,999,990.99') ||
                          '</b><br>';
          END IF;

          wc_mensaje3 := wc_mensaje3 ||
                         '<!DOCTYPE html>
          <html lang="es" class="baseFontStyles" style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
              <head>
                <title>Divemotor - Entrega de Vehículo</title>
                <meta charset="utf-8">

                <style>
                  div, p, a, li, td { -webkit-text-size-adjust:none; }

                  @media screen and (max-width: 500px) {
                    .mainTable,.mailBody,.to100{
                      width:100% !important;
                    }

                  }
                </style>
                <style>
                  @media screen and (max-width: 500px) {
                    .mailBody{
                      padding: 20px 18px !important
                    }
                    .col3{
                      width: 100%!important
                    }
                  }
                </style>
              </head>
              <body style="background-color: #eeeeee; margin: 0;">
              <table width="500" class="to100" border="0" align="center" cellpadding="0" cellspacing="0" class="mainTable" style="border-spacing: 0;">
              <tr><td>
                     <table class="to100" height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="border-spacing: 0;">
                        <tr>
                          <td style="padding: 0;">
                            <table height="40" width="100%" cellpadding="14" cellspacing="0" border="0" style="background-color: #222222; border-spacing: 0; padding-left: 25px; padding-right: 30px;">
                              <tr style="background-color: #222222;">
                                <td style="background-color: #222222; padding: 0; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">DIVEMOTOR</td>
                                <td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 800; padding: 0; text-align: right;">Módulo de Ficha de Venta.</td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <table class="to100" width="500" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr>
                          <td class="mailBody" style="background-color: #ffffff; padding: 32px;">
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; ;">Historial de Ficha de Venta</h1>
                            <h1 style="text-align: center;color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 22px; font-weight: bold; margin: 0; padding-bottom: 20px;">Desaduanaje</h1>

                            <p style="margin: 0;"><span style="font-weight: bold;">Hola</span>, se ha generado una notificación dentro del módulo de ficha de ventas:</p>

                            <div style="padding: 10px 0;">

                            </div>

                            <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="border-spacing: 0;padding: 15px 18px;background-color: #e1efff; border-radius: 5px 5px 0px 0px;">
                              <tr>
                                <td>
                                  <div class="to100" style="display:inline-block;width: 265px">
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 18px; line-height: 1.35; margin: 0;"><span style="font-weight: bold;"></span></p>
                                  </div>

                                  <div class="to100" style="display:inline-block;width: 110px">
                                    <p style="font-weight: bold;font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"> Nro de Ficha Venta</p>
                                    <p style="font-family: helvetica, arial, sans-serif; font-size: 15px; line-height: 1.35; margin: 0;"><a href="' ||
                         url_ficha_venta || 'fichas-venta/' ||
                         lpad(p_num_ficha_vta_veh, 12, '0') ||
                         '" style="color:#0076ff">' ||
                         lpad(p_num_ficha_vta_veh, 12, '0') ||
                         '</a></p>
                                  </div>
                                </td>
                              </tr>
                            </table>
                       ' || wc_mensaje || '
                              <p style="margin: 0; padding-top: 25px;" >La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</p>
                            </td>
                              </tr>

                              </table>
                                <div style="-webkit-text-size-adjust: none; padding-bottom: 50px; padding-top: 20px; text-align: left;">
                                  <p style="font-family: helvetica, arial, sans-serif; font-size: 12px; margin: 0; text-align: center;">Este mensaje ha sido generado por el Sistema SID Web - PROD</p>
                                </div>
                         </td></tr> </table>
                         </body></html>';

          wc_mensaje := wc_mensaje ||
                        '<br><br><font size="1" color="FF0000">NOTA: Este mensaje ha sido autogenerado por el Sistema.</font><BR>';
          --
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                              'SP_SOLIC_DESADUANAJE',
                                              p_id_usuario,
                                              'Paso 60',
                                              p_ret_mens,
                                              p_num_pedido_veh);

          SELECT COUNT(1)
            INTO wn_cantidad
            FROM usuarios_acti_pedido_veh
           WHERE co_usuario = p_cod_usua_sid
             AND cod_acti_pedido_veh = '0019'
             AND ind_envia_email = 'S';

          --IF wn_cantidad > 0 THEN
          SELECT lower(di_correo), initcap(nombre1 || ' ' || paterno)
            INTO wc_dir_correo_from, wc_des_usuario_from
            FROM usuarios
           WHERE co_usuario = p_cod_usua_sid
             AND estado = '001';
          IF wc_dir_correo_from IS NULL THEN
            p_ret_mens := 'No tiene correo eléctronico y/o usuario ' ||
                          p_cod_usua_sid || ' esta dado de baja';
            --RAISE ve_error;
            RAISE ve_error_mens;
          END IF;
          /*          ELSE
            p_ret_mens := 'Usuario no está autorizado para el envío de Correo';
            RAISE ve_error_mens;
          END IF;*/
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                              'SP_SOLIC_DESADUANAJE',
                                              p_id_usuario,
                                              'Paso 70',
                                              p_ret_mens || 'correo1:' ||
                                              p_cod_area_vta ||
                                              p_cod_usua_sid,
                                              p_num_pedido_veh);

          --BEGIN
          IF wc_dir_correo_from IS NOT NULL THEN
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                                'SP_SOLIC_DESADUANAJE',
                                                p_id_usuario,
                                                'Paso 80.00',
                                                p_ret_mens || 'correo1:' ||
                                                p_cod_area_vta ||
                                                p_cod_usua_sid,
                                                p_num_pedido_veh);
            FOR envio IN c1
            LOOP
              v_dest_desaduanaje := envio.di_correo || ',' ||
                                    v_dest_desaduanaje;
              /*v_dest_desaduanaje := 'ACRUZ@DIVEMOTOR.COM.PE' || ',' || v_dest_desaduanaje;
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'sp_solic_desaduanaje',
                                              p_id_usuario,
                                              'correo:'||p_cod_area_vta,
                                              '3');*/
            END LOOP;

            v_dest_desaduanaje := rtrim(ltrim(v_dest_desaduanaje, ','),','); --<REQ-89878 ASALAS>

            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                                'SP_SOLIC_DESADUANAJE',
                                                p_id_usuario,
                                                'Paso 80.01',
                                                p_ret_mens || 'correo1:' ||
                                                p_cod_area_vta ||
                                                p_cod_usua_sid,
                                                p_num_pedido_veh);
            pkg_sweb_five_mant.sp_inse_correo_fv(p_num_ficha_vta_veh ||
                                                 p_num_pedido_veh || 'AD', --  P_COD_REF_PROC,
                                                 v_dest_desaduanaje,
                                                 v_warrant_mail_cc,
                                                 wc_asunto,
                                                 '<p style="FONT: 8pt arial">' ||
                                                 wc_mensaje3 || '</p>',
                                                 wc_dir_correo_from,
                                                 p_cod_usua_sid,
                                                 p_id_usuario,
                                                 p_tipo_ref_proc,
                                                 p_ret_esta,
                                                 p_ret_mens);
          END IF;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                              'SP_SOLIC_DESADUANAJE',
                                              p_id_usuario,
                                              'Paso 80',
                                              p_ret_mens || 'correo1:' ||
                                              p_cod_area_vta ||
                                              p_cod_usua_sid,
                                              p_num_pedido_veh);

          /* EXCEPTION
            WHEN OTHERS THEN
            p_ret_mens := 'Error al armar correo:' ||p_ret_mens ||SQLERRM;
            RAISE ve_error;
          END;*/
          --
        ELSE
          p_ret_mens := 'Proceso cancelado';
          RAISE ve_error;
        END IF;
      ELSE
        IF wn_cont_situ66 = 0 THEN
          p_ret_mens := 'El pedido debe tener Stock Contable para que se pueda Asignar porque la compañía no es Importer';
          RAISE ve_error;
        END IF;
      END IF;

    END IF;

    COMMIT;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SP',
                                        'SP_SOLIC_DESADUANAJE',
                                        p_id_usuario,
                                        'Fin',
                                        p_num_pedido_veh);
  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR1',
                                          'sp_solic_desaduanaje',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_num_pedido_veh);

      ROLLBACK;
    WHEN ve_error_mens THEN
      p_ret_esta := 0;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR2',
                                          'sp_solic_desaduanaje',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          p_num_pedido_veh);

    WHEN OTHERS THEN
      p_ret_mens := SQLERRM;
      p_ret_esta := -1;
      wc_mensaje := 'Error al procesar la solicitud de desaduanaje' ||
                    substr(SQLERRM, 1, 500);

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR3',
                                          'sp_solic_desaduanaje',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens || v_dest_desaduanaje,
                                          p_num_pedido_veh);

      ROLLBACK;

  END;

  PROCEDURE sp_list_pedi_asig
  (
    p_num_ficha_vta_veh    IN VARCHAR2,
    p_num_prof_veh         IN VARCHAR2,
    p_num_pedido_veh       IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_num_chasis           IN vve_pedido_veh.num_chasis%TYPE,
    p_cod_ubica_pedido_veh IN vve_pedido_veh.cod_ubica_pedido_veh%TYPE,
    p_cod_situ_pedido      IN vve_pedido_veh.cod_situ_pedido%TYPE,
    p_sku_sap              IN vve_config_veh.sku_sap%TYPE,
    p_num_placa_veh        IN vve_pedido_veh.num_placa_veh%TYPE,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_lim_infe             NUMBER,
    p_lim_supe             NUMBER,
    p_tab                  OUT SYS_REFCURSOR,
    p_tot_regi             OUT NUMBER,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR
  ) AS
    l_cod_area_vta           vve_ficha_vta_veh.cod_area_vta%TYPE;
    l_cod_cia                vve_ficha_vta_veh.cod_cia%TYPE;
    l_sku_sap                vve_config_veh.sku_sap%TYPE;
    l_cod_color_veh          vve_proforma_veh_det.cod_color_veh%TYPE;
    l_cod_filial             vve_proforma_veh.cod_filial%TYPE;
    l_cod_familia_veh        vve_proforma_veh_det.cod_familia_veh%TYPE;
    l_cod_marca              vve_proforma_veh_det.cod_marca%TYPE;
    l_cod_baumuster          vve_proforma_veh_det.cod_baumuster%TYPE;
    l_cod_config_veh         vve_config_veh.cod_config_veh%TYPE;
    l_vendedor               vve_proforma_veh.vendedor%TYPE;
    l_cod_clie               vve_ficha_vta_proforma_veh.cod_perso_dir%TYPE;
    l_txt_cod_clie           cxc_mae_clie.nom_clie%TYPE;
    l_num_pedido_veh         vve_pedido_veh.num_pedido_veh%TYPE;
    l_cod_prov               vve_pedido_veh.cod_prov%TYPE;
    l_tip_prof_veh           vve_proforma_veh.tip_prof_veh%TYPE;
    l_can_veh                vve_proforma_veh_det.can_veh%TYPE;
    l_can_veh_asig           vve_proforma_veh_det.can_veh%TYPE;
    l_can_disp               vve_proforma_veh_det.can_veh%TYPE;
    l_cod_situ_pedido_aduana vve_situ_pedido.cod_situ_pedido%TYPE;
    l_cod_sucursal_ficha     gen_filial.cod_sucursal%TYPE;
    l_nrol                   NUMBER := 0;
    l_wc_ret                 VARCHAR2(1000);
    l_wc_sucursal            gen_filiales.cod_sucursal%TYPE;
    l_paso                   VARCHAR2(3);
    ve_error EXCEPTION;
    l_wc_sql            VARCHAR2(10000);
    l_ind_fifo          VARCHAR2(2);
    sql_stmt_paginacion VARCHAR2(10000);

    v_dato_numerico VARCHAR2(50);
    v_dato_cadena   VARCHAR2(50);
    v_dato_booleano VARCHAR2(50);
    v_cod_rpta      NUMBER;
    v_men           VARCHAR2(5000);
    --<i84905>Color interno
    l_cod_tapiz_veh      vve_proforma_veh_det.cod_tapiz_veh%TYPE;
    v_ind_reser_colorint VARCHAR(1);
    v_query_int          VARCHAR2(1000);
    --<f84905>Color interno
    -- legados
    l_zsku vve_config_veh.zsku%type;
    l_cod_config_veh_2   vve_config_veh.cod_config_veh%type;
  BEGIN
    --Variables Generales
    l_cod_situ_pedido_aduana := '12';
    l_wc_sql                 := '';
    IF nvl(p_num_ficha_vta_veh, 'x') = 'x' THEN
      p_ret_mens := 'El número de ficha de venta es obligatorio';
      RAISE ve_error;
    END IF;

    IF nvl(p_num_prof_veh, 'x') = 'x' THEN
      p_ret_mens := 'El número de proforma es obligatorio';
      RAISE ve_error;
    END IF;
    l_paso := '111';
    ----Variables de Ficha de venta
    SELECT a.cod_area_vta, a.cod_cia, b.cod_sucursal
      INTO l_cod_area_vta, l_cod_cia, l_cod_sucursal_ficha
      FROM vve_ficha_vta_veh a
     INNER JOIN gen_filiales b
        ON a.cod_filial = b.cod_filial
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;
    l_paso := '1.1';
    -- variables de la proforma

    SELECT d.sku_sap,
           b.cod_color_veh,
           a.cod_filial,
           b.cod_familia_veh,
           b.cod_marca,
           b.cod_baumuster,
           a.cod_clie,
           nvl(a.tip_prof_veh, '1') tipo_prof_veh,
           a.vendedor,
           b.can_veh,
           b.cod_config_veh,
           b.cod_tapiz_veh,
           d.zsku
      INTO l_sku_sap,
           l_cod_color_veh,
           l_cod_filial,
           l_cod_familia_veh,
           l_cod_marca,
           l_cod_baumuster,
           l_cod_clie,
           l_tip_prof_veh,
           l_vendedor,
           l_can_veh,
           l_cod_config_veh,
           l_cod_tapiz_veh, --<i84905>Color interno
           l_zsku --<legado>
      FROM vve_proforma_veh a
     INNER JOIN vve_proforma_veh_det b
        ON a.num_prof_veh = b.num_prof_veh
     INNER JOIN vve_ficha_vta_proforma_veh c
        ON a.num_prof_veh = c.num_prof_veh
      LEFT JOIN vve_config_veh d
        ON d.cod_familia_veh = b.cod_familia_veh
       AND b.cod_marca = d.cod_marca
       AND b.cod_baumuster = d.cod_baumuster
       AND b.cod_config_veh = d.cod_config_veh
     WHERE c.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND a.num_prof_veh = p_num_prof_veh;
    l_paso := '2';

    -------------------
    begin
    select a.cod_config_veh into l_cod_config_veh_2 from vve_config_veh a
    where a.sku_sap=l_zsku;
    EXCEPTION
      WHEN no_data_found THEN
        l_cod_config_veh_2 := l_cod_config_veh;
    END;
    --------------------
    ----Cantidad de vehiculos asignados
    SELECT COUNT(a.num_pedido_veh)
      INTO l_can_veh_asig
      FROM vve_ficha_vta_pedido_veh a
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND a.num_prof_veh = p_num_prof_veh
       AND a.ind_inactivo = 'N';
    l_paso := '3';
    -- Cantidad de vehiculos por asignar
    l_can_disp := l_can_veh - l_can_veh_asig;
    BEGIN
      SELECT nom_clie
        INTO l_txt_cod_clie
        FROM cxc.cxc_mae_clie
       WHERE cod_clie = l_cod_clie;
    EXCEPTION
      WHEN no_data_found THEN
        l_txt_cod_clie := 'Cliente no existe';
    END;
    l_paso := '4';
    ---------------------

    l_nrol := 0;
    /* BEGIN
      SELECT COUNT(cod_aut_area_vta)
        INTO l_nrol
        FROM gen_area_vta_aut a
       WHERE cod_aut_area_vta = '05'
            -- Reservas stock FIFO
         AND nvl(ind_inactivo, 'N') = 'N'
         AND cod_area_vta = l_cod_area_vta;
    END;*/
    l_paso := '5';

    pkg_sweb_mant_datos_mae.sp_dato_gen(p_cod_area_vta        => l_cod_area_vta,
                                        p_cod_familia_veh     => l_cod_familia_veh,
                                        p_cod_marca           => NULL,
                                        p_cod_baumuster       => NULL,
                                        p_cod_config_veh      => NULL,
                                        p_cod_tipo_veh        => NULL,
                                        p_cod_clausula_compra => NULL,
                                        p_id_tipo_dato        => 4, --4=reservsa de vehiculos
                                        o_dato_numerico       => v_dato_numerico,
                                        o_dato_cadena         => v_dato_cadena,
                                        o_dato_booleano       => v_dato_booleano,
                                        o_cod_rpta            => v_cod_rpta,
                                        o_mensaje             => v_men);

    IF v_cod_rpta = 1 AND v_dato_cadena = k_val_s THEN
      --IF nvl(l_nrol, 0) > 0 THEN
      l_paso := '6';
      --<I-84905>
      pkg_sweb_mant_datos_mae.sp_dato_gen(l_cod_area_vta,
                                          l_cod_familia_veh,
                                          NULL,
                                          NULL,
                                          NULL,
                                          NULL,
                                          NULL,
                                          12, --12 = RESERVA CON COLOR INTERNO
                                          v_dato_numerico,
                                          v_dato_cadena,
                                          v_ind_reser_colorint,
                                          v_cod_rpta,
                                          v_men);
      IF (v_cod_rpta <> 1) THEN
        v_ind_reser_colorint := 'N';
      END IF;
      IF v_ind_reser_colorint = 'S' THEN
        v_query_int := 'AND nvl(a.cod_tapiz_veh, ''sin color'') = nvl(''' ||
                       l_cod_tapiz_veh ||
                       ''', nvl(a.cod_tapiz_veh, ''sin color'')) ';
      ELSE
        v_query_int := '';
      END IF;
      --<F-84905>
      l_wc_sql := '
    SELECT
     CASE WHEN rownum <= ' || to_char(l_can_disp) ||
                  ' and z.cod_estado_pedido_veh in (''R'',''A'') THEN ''S'' ELSE ''N'' END seleccioando
     ,z.*
    FROM (SELECT y.*
      FROM (SELECT x.*
            FROM (SELECT a.cod_cia,
                       a.cod_prov,
                       a.num_pedido_veh,
                       a.num_chasis,
                       a.ano_fabricacion_veh,
                       a.cod_color_veh,
                       a.cod_ubica_pedido_veh,
                       a.cod_situ_pedido,
                       decode(a.cod_estado_pedido_veh,''R'',''S'',''N'')ind_reserva,
                       a.cod_familia_veh,
                       a.cod_marca,
                       a.cod_baumuster,
                       a.cod_config_veh,
                       a.num_placa_veh,
                       a.cod_filial,
                       a.cod_area_vta,
                       a.cod_estado_pedido_veh,
                       --
                       pkg_sweb_five_mant_pedido.fn_fecha_compromiso(''' ||
                  p_num_prof_veh ||
                  ''') fecha_compromiso,
                       pkg_log_select.func_sel_tapcia(a.cod_cia) cia,
                       pkg_gen_select.func_sel_gen_persona(a.cod_prov) des_prov,
                       (SELECT col.des_color_fabrica_veh
                          FROM vve_color_fabrica_veh col
                         WHERE a.cod_color_veh = col.cod_color_fabrica_veh)||''/''||pkg_sweb_mae_gene.fu_desc_color_tapiz(a.cod_tapiz_veh) des_color_veh,
                       (SELECT des_ubica_pedido
                          FROM vve_ubica_pedido vup
                         WHERE vup.cod_ubica_pedido = a.cod_ubica_pedido_veh
                                       ) des_ubica_pedido,
                       (SELECT s.des_situ_pedido
                          FROM vve_situ_pedido s
                         WHERE s.cod_situ_pedido = a.cod_situ_pedido) des_situ_pedido,
                       (SELECT MAX(ps.fec_situ_pedido)
                          FROM vve_pedido_veh_situ ps
                         WHERE ps.cod_situ_pedido = a.cod_situ_pedido
                           AND a.cod_cia = ps.cod_cia
                           AND a.cod_prov = ps.cod_prov
                           AND a.num_pedido_veh = ps.num_pedido_veh) fec_situ_pedido,
                       pkg_sweb_pedi_veh.fu_sku_pedido(a.cod_cia,
                                                       a.cod_prov,
                                                       a.num_pedido_veh) sku_sap,
                       pkg_sweb_mae_gene.fu_desc_familia(a.cod_familia_veh) des_familia,

                       pkg_sweb_mae_gene.fu_desc_marca(a.cod_marca) des_marca,

                       pkg_sweb_mae_gene.fu_desc_modelo(a.cod_familia_veh,
                                                        a.cod_marca,
                                                        a.cod_baumuster) desc_baumuster,
                       (select sec.nsecreser
                        from Vve_Sec_Reserva  sec
                        where sec.cod_area_vta      = a.cod_area_vta
                          and sec.cod_sucursal_orig =  ''' ||
                  l_cod_sucursal_ficha || '''
                                  and sec.cod_sucursal_rel  = ub.cod_sucursal ) secuencia,
                       pkg_sweb_vve_rese_vehi.fu_obte_fsitu_pdor (a.cod_cia,a.cod_prov, a.num_pedido_veh ) fecha_aduana,
                       decode (i.ind_tip_stock, ''1'', 1, 2) ind_tip_stock,
                       nvl(i.prioridad, 1) prioridad_situ,
                       (select ep.des_estado_pedido from vve_estado_pedido ep where ep.cod_estado_pedido=a.cod_estado_pedido_veh)estado_pedido
                        --,h.orden_reserva ord_prio_esta_pedi --<86227 COMENTADO>
                        ,pkg_sweb_vve_rese_vehi.fun_prio_rese_esta(a.cod_cia , a.cod_prov , a.num_pedido_veh ,a.cod_estado_pedido_veh )ord_prio_esta_pedi--<86227>
                        ,CASE WHEN i.ind_tip_stock = ''1'' THEN NULL ELSE a.fec_sal_fabrica END fec_sal_fabrica
                        ,CASE WHEN i.ind_tip_stock = ''1'' THEN NULL ELSE a.fec_prod_pedido_veh END fec_prod_pedido_veh
                        ,decode(ub.tip_ubic,''2'',2,1) ord_tipo_ubic
                     FROM vve_pedido_veh a
                       INNER JOIN vve_familia_veh d
                          ON d.cod_familia_veh = a.cod_familia_veh
                       INNER JOIN gen_marca e
                          ON e.cod_marca = a.cod_marca
                       INNER JOIN vve_baumuster f
                          ON f.cod_familia_veh = a.cod_familia_veh
                           AND f.cod_marca       = a.cod_marca
                           AND f.cod_baumuster   = a.cod_baumuster
                       LEFT JOIN vve_ubica_pedido ub
                          ON ub.cod_ubica_pedido = a.cod_ubica_pedido_veh
                       LEFT JOIN vve_situ_pedido i
                          ON i.cod_situ_pedido    = a.cod_situ_pedido
                       LEFT JOIN vve_estado_pedido h
                          ON h.cod_estado_pedido  = a.cod_estado_pedido_veh
                       WHERE a.cod_cia = ''' || l_cod_cia || '''
                         AND (a.sku_sap = ' || l_sku_sap || ' or   a.sku_sap = '|| l_zsku ||'   )
                         AND a.cod_area_vta = ''' ||
                  l_cod_area_vta || '''
                         AND nvl(a.cod_color_veh, ''sin color'') = nvl(''' ||
                  l_cod_color_veh || ''', nvl(a.cod_color_veh, ''sin color''))

                         AND a.cod_adquisicion_pedido_veh <> ''0007''
                         AND nvl(a.ind_equipo_esp, ''N'') = ''N''
                         AND a.ind_nuevo_usado = ''N''
                         And Exists (Select 1
                                     From Vve_Estado_Pedido x
                                     Where x.Cod_Estado_Pedido    = a.Cod_Estado_Pedido_Veh
                                       And NVL(x.Ind_Inactivo,''N'')  = ''N''
                                       And NVL(x.Control_Stock,''N'') = ''S'' )
                         And EXISTS (SELECT 1
                                     FROM Vve_Estado_Pedido_Area Epa
                                     WHERE Epa.Cod_Estado_Pedido     = a.Cod_Estado_Pedido_Veh
                                       And Epa.Cod_Area_Vta          = a.cod_area_vta
                                       And Nvl(Asigna_Ficha, ''N'')   = ''S'' )
                        ' || v_query_int || '
                    ) x) y
     ORDER BY ind_tip_stock, prioridad_situ, ord_prio_esta_pedi, ord_tipo_ubic, secuencia ,fecha_aduana,  fec_sal_fabrica, fec_prod_pedido_veh,  Num_Pedido_Veh
     ) z';
      /*l_wc_sql := '
      SELECT
       CASE WHEN rownum <= ' || to_char(l_can_disp) ||' and z.cod_estado_pedido_veh in (''R'',''A'') THEN ''S'' ELSE ''N'' END seleccioando
       ,z.*
      FROM (SELECT y.*
        FROM (SELECT x.*,pkg_sweb_five_mant_pedido.fn_fecha_compromiso(''' || p_num_prof_veh ||''') fecha_compromiso,
               pkg_log_select.func_sel_tapcia(x.cod_cia) cia,
               pkg_gen_select.func_sel_gen_persona(x.cod_prov) des_prov,
               (SELECT col.des_color_fabrica_veh
                  FROM vve_color_fabrica_veh col
                 WHERE x.cod_color_veh = col.cod_color_fabrica_veh) des_color_veh,
               (SELECT des_ubica_pedido
                  FROM vve_ubica_pedido vup
                 WHERE vup.cod_ubica_pedido = x.cod_ubica_pedido_veh
                   AND vup.ind_inactivo = ''N'') des_ubica_pedido,
               (SELECT s.des_situ_pedido
                  FROM vve_situ_pedido s
                 WHERE s.cod_situ_pedido = x.cod_situ_pedido) des_situ_pedido,
               (SELECT MAX(ps.fec_situ_pedido)
                  FROM vve_pedido_veh_situ ps
                 WHERE ps.cod_situ_pedido = x.cod_situ_pedido
                   AND x.cod_cia = ps.cod_cia
                   AND x.cod_prov = ps.cod_prov
                   AND x.num_pedido_veh = ps.num_pedido_veh) fec_situ_pedido,
               pkg_sweb_pedi_veh.fu_sku_pedido(x.cod_cia,
                                               x.cod_prov,
                                               x.num_pedido_veh) sku_sap,
               pkg_sweb_mae_gene.fu_desc_familia(x.cod_familia_veh) des_familia,

               pkg_sweb_mae_gene.fu_desc_marca(x.cod_marca) des_marca,

               pkg_sweb_mae_gene.fu_desc_modelo(x.cod_familia_veh,
                                                x.cod_marca,
                                                x.cod_baumuster) desc_baumuster,
               (SELECT sr.nsecreser
                  FROM vve_sec_reserva sr
                 WHERE sr.cod_sucursal_orig = ''' || l_cod_sucursal_ficha || ''' -- ficha
                   AND sr.cod_area_vta = x.cod_area_vta
                   AND sr.cod_sucursal_rel IN
                       (SELECT gf.cod_sucursal
                          FROM gen_filiales gf
                         WHERE x.cod_filial = gf.cod_filial)) secuencia,
               (SELECT MAX(psa.fec_situ_pedido) fecha_aduana
                  FROM vve_pedido_veh_situ psa
                 WHERE psa.cod_situ_pedido = ''' || l_cod_situ_pedido_aduana || '''
                   AND x.cod_cia = psa.cod_cia
                   AND x.cod_prov = psa.cod_prov
                   AND x.num_pedido_veh = psa.num_pedido_veh) fecha_aduana,
              (SELECT sp.ind_tip_stock
                  FROM vve_situ_pedido sp
                 WHERE x.cod_situ_pedido = sp.cod_situ_pedido) ind_tip_stock,
               (SELECT sp.prioridad
                  FROM vve_situ_pedido sp
                 WHERE x.cod_situ_pedido = sp.cod_situ_pedido) prioridad_situ,
                 (select ep.des_estado_pedido from vve_estado_pedido ep where ep.cod_estado_pedido=x.cod_estado_pedido_veh)estado_pedido
                FROM (SELECT a.cod_cia,
                         a.cod_prov,
                         a.num_pedido_veh,
                         a.num_chasis,
                         a.ano_fabricacion_veh,
                         a.cod_color_veh,
                         a.cod_ubica_pedido_veh,
                         a.cod_situ_pedido,
                         ''S'' ind_reserva,
                         a.cod_familia_veh,
                         a.cod_marca,
                         a.cod_baumuster,
                         a.cod_config_veh,
                         a.num_placa_veh,
                         a.cod_filial,
                         a.cod_area_vta,
                         a.cod_estado_pedido_veh
                       FROM vve_pedido_veh a
                       INNER JOIN vve_sec_reserva b
                          ON a.cod_area_vta = b.cod_area_vta
                       INNER JOIN gen_filiales c
                          ON a.cod_filial = c.cod_filial
                       INNER JOIN vve_familia_veh d
                          ON d.cod_familia_veh = a.cod_familia_veh
                       INNER JOIN gen_marca e
                          ON e.cod_marca = a.cod_marca
                       INNER JOIN vve_baumuster f
                          ON f.cod_baumuster = a.cod_baumuster
                       WHERE b.cod_sucursal_orig = ''' || l_cod_sucursal_ficha || ''' -- ficha
                         AND b.cod_sucursal_rel = c.cod_sucursal
                         AND a.cod_cia = ''' || l_cod_cia || '''
                         AND a.sku_sap = ' || l_sku_sap || '
                         AND a.cod_area_vta = ''' ||  l_cod_area_vta ||  ''' -- ficha
                         AND nvl(a.cod_color_veh, ''sin color'') = nvl(''' || l_cod_color_veh || ''', nvl(a.cod_color_veh, ''sin color''))
                         AND ((''' || l_cod_area_vta || ''' IN (''001'', ''003'') AND a.cod_situ_pedido <> ''01'') OR (''' || l_cod_area_vta ||
                ''' IN (''002'', ''004'') AND a.cod_situ_pedido NOT IN (''01'', ''02'', ''09'', ''11'', ''13''\*, ''03''*\)))
                         AND (a.cod_estado_pedido_veh = ''R'')
                         AND EXISTS
                       (SELECT 1
                          FROM vve_pedido_veh_reserva x
                          WHERE x.cod_cia = a.cod_cia
                            AND x.cod_prov = a.cod_prov
                            AND x.num_pedido_veh = a.num_pedido_veh
                            AND nvl(x.ind_exclusivo,''N'') = ''N'')
                         AND a.cod_adquisicion_pedido_veh <> ''0007''
                         AND nvl(a.ind_equipo_esp, ''N'') = ''N''
                         AND a.ind_nuevo_usado = ''N''
                         AND d.cod_familia_veh = a.cod_familia_veh
                         AND e.cod_marca = a.cod_marca
                         AND f.cod_familia_veh = a.cod_familia_veh
                         AND f.cod_marca = a.cod_marca
                         AND f.cod_baumuster = a.cod_baumuster
                      UNION
                      SELECT a.cod_cia,
                         a.cod_prov,
                         a.num_pedido_veh,
                         a.num_chasis,
                         a.ano_fabricacion_veh,
                         a.cod_color_veh,
                         a.cod_ubica_pedido_veh,
                         a.cod_situ_pedido,
                         ''N'' ind_reserva,
                         a.cod_familia_veh,
                         a.cod_marca,
                         a.cod_baumuster,
                         a.cod_config_veh,
                         a.num_placa_veh,
                         a.cod_filial,
                         a.cod_area_vta,
                         a.cod_estado_pedido_veh
                       FROM v_pedido_veh a
                       WHERE
                       a.num_pedido_veh like ''%' || p_num_pedido_veh || '%'' and
                       a.cod_area_vta = ''' ||   l_cod_area_vta || '''
                         AND a.cod_estado_pedido_veh IN
                             (SELECT epa.cod_estado_pedido
                                FROM vve_estado_pedido_area epa
                               WHERE epa.cod_area_vta = ''' || l_cod_area_vta || '''
                                 AND epa.asigna_ficha = ''S''
                                 AND epa.cod_estado_pedido != ''R'')
                         AND a.cod_adquisicion_pedido_veh <> ''0007''
                         AND a.cod_cia = ''' ||  l_cod_cia || '''
                         AND a.sku_sap = ' ||  to_char(l_sku_sap) || '
                         AND nvl(a.cod_color_veh, ''sin color'') = nvl(''' ||  l_cod_color_veh ||  ''', nvl(a.cod_color_veh, ''sin color''))
                         AND (a.cod_cia, a.cod_prov, a.num_pedido_veh) NOT IN
                             (SELECT pf.cod_cia,
                                     pf.cod_prov,
                                     pf.num_pedido_veh
                                FROM venta.vve_ficha_vta_pedido_veh pf
                               WHERE pf.cod_cia = a.cod_cia
                                 AND pf.cod_prov = a.cod_prov
                                 AND pf.num_pedido_veh = a.num_pedido_veh
                                 AND nvl(pf.ind_inactivo, ''N'') = ''N'')
                         AND EXISTS
                       (SELECT 1
                         FROM vve_sec_reserva b, gen_filiales c
                         WHERE b.cod_sucursal_orig = ''' ||  l_cod_sucursal_ficha || '''
                           AND b.cod_area_vta = a.cod_area_vta
                           AND c.cod_sucursal = b.cod_sucursal_rel
                           AND c.cod_filial = a.cod_filial)

                      ) x) y
       ORDER BY y.ind_reserva       DESC,
                y.secuencia      ASC,
                y.fecha_aduana   ASC,
                y.ind_tip_stock,
                y.prioridad_situ) z';*/
    ELSE
      l_paso := '7';
      IF l_tip_prof_veh = '1' THEN
        l_paso := '8';
        --Proforma de NUEVO

        l_wc_sql := 'SELECT
       CASE
         WHEN rownum <= ' || to_char(l_can_disp) ||
                    '  THEN
          ''N''
         ELSE
          ''N''
       END seleccioando,
       z.*
      FROM ( select y.* from  (select    pkg_sweb_five_mant_pedido.fn_fecha_compromiso(''' ||
                    p_num_prof_veh ||
                    ''') fecha_compromiso, a.cod_cia,
                         a.cod_prov,
                         a.num_pedido_veh,
                         a.num_chasis,
                         a.ano_fabricacion_veh,
                         a.cod_color_veh,
                         a.cod_ubica_pedido_veh,
                         a.cod_situ_pedido,
                         '''' ind_reserva,
                         a.cod_familia_veh,
                         a.cod_marca,
                         a.cod_baumuster,
                         a.cod_config_veh,
                         a.num_placa_veh,
                         a.cod_filial,
                         a.cod_area_vta,
                         a.cod_estado_pedido_veh,
                         a.fec_crea_reg,
                    pkg_log_select.func_sel_tapcia(a.cod_cia) cia,
                       pkg_gen_select.func_sel_gen_persona(a.cod_prov) des_prov,
                       (SELECT col.des_color_fabrica_veh
                          FROM vve_color_fabrica_veh col
                         WHERE a.cod_color_veh = col.cod_color_fabrica_veh) des_color_veh,
                       (SELECT des_ubica_pedido
                          FROM vve_ubica_pedido vup
                         WHERE vup.cod_ubica_pedido = a.cod_ubica_pedido_veh
                                  ) des_ubica_pedido,
                       (SELECT s.des_situ_pedido
                          FROM vve_situ_pedido s
                         WHERE s.cod_situ_pedido = a.cod_situ_pedido) des_situ_pedido,
                       (SELECT MAX(ps.fec_situ_pedido)
                          FROM vve_pedido_veh_situ ps
                         WHERE ps.cod_situ_pedido = a.cod_situ_pedido
                           AND a.cod_cia = ps.cod_cia
                           AND a.cod_prov = ps.cod_prov
                           AND a.num_pedido_veh = ps.num_pedido_veh) fec_situ_pedido,
                       pkg_sweb_pedi_veh.fu_sku_pedido(a.cod_cia,
                                                       a.cod_prov,
                                                       a.num_pedido_veh) sku_sap,
                       pkg_sweb_mae_gene.fu_desc_familia(a.cod_familia_veh) des_familia,

                       pkg_sweb_mae_gene.fu_desc_marca(a.cod_marca) des_marca,

                       pkg_sweb_mae_gene.fu_desc_modelo(a.cod_familia_veh,
                                                        a.cod_marca,
                                                        a.cod_baumuster) desc_baumuster,
                       (SELECT sr.nsecreser
                          FROM vve_sec_reserva sr
                         WHERE sr.cod_sucursal_orig = ''' ||
                    l_cod_sucursal_ficha || '''
                           AND sr.cod_area_vta = a.cod_area_vta
                           AND sr.cod_sucursal_rel IN
                               (SELECT gf.cod_sucursal
                                  FROM gen_filiales gf
                                 WHERE a.cod_filial = gf.cod_filial)) secuencia,
                       (SELECT MAX(psa.fec_situ_pedido) fecha_aduana
                          FROM vve_pedido_veh_situ psa
                         WHERE psa.cod_situ_pedido = ''' ||
                    l_cod_situ_pedido_aduana || '''
                           AND a.cod_cia = psa.cod_cia
                           AND a.cod_prov = psa.cod_prov
                           AND a.num_pedido_veh = psa.num_pedido_veh) fecha_aduana,
                      (SELECT sp.ind_tip_stock
                          FROM vve_situ_pedido sp
                         WHERE a.cod_situ_pedido = sp.cod_situ_pedido) ind_tip_stock,
                       (SELECT sp.prioridad
                          FROM vve_situ_pedido sp
                         WHERE a.cod_situ_pedido = sp.cod_situ_pedido) prioridad_situ,
                         (select ep.des_estado_pedido from vve_estado_pedido ep where ep.cod_estado_pedido=a.cod_estado_pedido_veh)estado_pedido

                    from vve_pedido_veh a
                    where a.num_pedido_veh like ''%' ||
                    p_num_pedido_veh || '%'' and
                    a.cod_marca=''' || l_cod_marca || '''
                    and a.cod_familia_veh=''' ||
                    l_cod_familia_veh || '''
                    and a.cod_baumuster=''' ||
                    l_cod_baumuster || '''
                    and (a.cod_config_veh=''' ||
                    l_cod_config_veh || ''' or a.cod_config_veh=''' ||
                    l_cod_config_veh_2 || ''' )

                   and
                 (a.cod_cia,a.cod_prov,a.num_pedido_veh) not in
                 (select pf.cod_cia,pf.cod_prov,pf.num_pedido_veh
                    from venta.vve_ficha_vta_pedido_veh pf
                   where pf.cod_cia         =  a.cod_cia and
                         pf.cod_prov        =  a.cod_prov   and
                         pf.num_pedido_veh  =  a.num_pedido_veh and
                         nvl(pf.ind_inactivo,''N'')=''N'')  and
                  ( Exists ( Select 1
                               from vve_estado_pedido ep,
                                    vve_estado_pedido_area epa
                              Where ep.cod_estado_pedido      = a.cod_estado_pedido_veh
                                And epa.cod_estado_pedido (+) = ep.cod_estado_pedido
                                And Nvl( Asigna_Ficha,''N'')  = ''S''
                                And ( nvl(epa.Asigna_x_cliente ,''N'') = ''N'' or Exists (Select 1 from VVE_PEDIDO_VEH_RESERVA re
                                                                                    Where re.cod_cia  = a.cod_cia
                                                                                      And re.cod_prov = a.cod_prov
                                                                                      And re.num_pedido_veh = a.num_Pedido_veh
                                                                                      And re.cod_clie = ''' ||
                    l_cod_clie || '''
                                                                                 )
                                  )
                            )
                   or
                  (a.cod_estado_pedido_veh=''D'' and
                   (a.cod_cia,a.cod_prov,a.num_pedido_veh) not in
                   (select pf.cod_cia,pf.cod_prov,pf.num_pedido_veh
                    from venta.vve_ficha_vta_pedido_veh pf
                    where pf.cod_cia  =  a.cod_cia  and
                          pf.cod_prov  =  a.cod_prov  and
                          pf.num_pedido_veh = a.num_pedido_veh and
                          nvl(pf.ind_inactivo,''N'')=''N''))) and
                  a.ind_nuevo_usado=''N''  )y

                  order by
                  y.secuencia      ASC,
                  y.fecha_aduana   ASC,
                  y.ind_tip_stock,
                  y.prioridad_situ,
                  y.fec_crea_reg asc) z

                  ';

        l_paso := '10';

      ELSE
        l_paso   := '9';
        l_wc_sql := 'select pkg_sweb_five_mant_pedido.fn_fecha_compromiso(''' ||
                    p_num_prof_veh ||
                    ''') fecha_compromiso,
                  a.cod_cia,
                               a.cod_prov,
                               a.num_pedido_veh,
                               a.num_chasis,
                               a.ano_fabricacion_veh,
                               a.cod_color_veh,
                               a.cod_ubica_pedido_veh,
                               a.cod_situ_pedido,
                               '''' ind_reserva,
                               a.cod_familia_veh,
                               a.cod_marca,
                               a.cod_baumuster,
                               a.cod_config_veh,
                               a.num_placa_veh,
                               a.cod_filial,
                               a.cod_area_vta,
                               a.cod_estado_pedido_veh,
                    pkg_log_select.func_sel_tapcia(a.cod_cia) cia,
                       pkg_gen_select.func_sel_gen_persona(a.cod_prov) des_prov,
                       (SELECT col.des_color_fabrica_veh
                          FROM vve_color_fabrica_veh col
                         WHERE a.cod_color_veh = col.cod_color_fabrica_veh) des_color_veh,
                       (SELECT des_ubica_pedido
                          FROM vve_ubica_pedido vup
                         WHERE vup.cod_ubica_pedido = a.cod_ubica_pedido_veh
                           AND vup.ind_inactivo = ''N'') des_ubica_pedido,
                       (SELECT s.des_situ_pedido
                          FROM vve_situ_pedido s
                         WHERE s.cod_situ_pedido = a.cod_situ_pedido) des_situ_pedido,
                       (SELECT MAX(ps.fec_situ_pedido)
                          FROM vve_pedido_veh_situ ps
                         WHERE ps.cod_situ_pedido = a.cod_situ_pedido
                           AND a.cod_cia = ps.cod_cia
                           AND a.cod_prov = ps.cod_prov
                           AND a.num_pedido_veh = ps.num_pedido_veh) fec_situ_pedido,
                       pkg_sweb_pedi_veh.fu_sku_pedido(a.cod_cia,
                                                       a.cod_prov,
                                                       a.num_pedido_veh) sku_sap,
                       pkg_sweb_mae_gene.fu_desc_familia(a.cod_familia_veh) des_familia,

                       pkg_sweb_mae_gene.fu_desc_marca(a.cod_marca) des_marca,

                       pkg_sweb_mae_gene.fu_desc_modelo(a.cod_familia_veh,
                                                        a.cod_marca,
                                                        a.cod_baumuster) desc_baumuster,
                       (SELECT sr.nsecreser
                          FROM vve_sec_reserva sr
                         WHERE sr.cod_sucursal_orig = ''' ||
                    l_cod_sucursal_ficha || '''
                           AND sr.cod_area_vta = a.cod_area_vta
                           AND sr.cod_sucursal_rel IN
                               (SELECT gf.cod_sucursal
                                  FROM gen_filiales gf
                                 WHERE a.cod_filial = gf.cod_filial)) secuencia,
                       (SELECT MAX(psa.fec_situ_pedido) fecha_aduana
                          FROM vve_pedido_veh_situ psa
                         WHERE psa.cod_situ_pedido = ''' ||
                    l_cod_situ_pedido_aduana || '''
                           AND a.cod_cia = psa.cod_cia
                           AND a.cod_prov = psa.cod_prov
                           AND a.num_pedido_veh = psa.num_pedido_veh) fecha_aduana,
                      (SELECT sp.ind_tip_stock
                          FROM vve_situ_pedido sp
                         WHERE a.cod_situ_pedido = sp.cod_situ_pedido) ind_tip_stock,
                       (SELECT sp.prioridad
                          FROM vve_situ_pedido sp
                         WHERE a.cod_situ_pedido = sp.cod_situ_pedido) prioridad_situ,
                         (select ep.des_estado_pedido from vve_estado_pedido ep where ep.cod_estado_pedido=a.cod_estado_pedido_veh)estado_pedido

              from
              vve_pedido_veh a where
              a.ind_nuevo_usado = ''U''
              AND EXISTS (SELECT 1
                      FROM vve_estado_pedido e
                     WHERE a.cod_estado_pedido_veh = e.cod_estado_pedido
                       AND e.ind_usado     = ''S''
                       AND e.control_stock = ''S''
                       AND nvl(e.ind_inactivo, ''N'') = ''N'')
              AND EXISTS (
                SELECT * FROM  vve_prof_pedi_adi d
                WHERE d.num_prof_veh =    ''' ||
                    p_num_prof_veh || '''
                  AND d.cod_cia      =    a.cod_cia
                  AND d.cod_prov     =    a.cod_prov
                  AND d.num_pedido_veh =  a.num_pedido_veh
                  AND nvl(d.ind_inactivo,''N'') = ''N''
                  AND NOT EXISTS (
                    SELECT * FROM vve_ficha_vta_pedido_veh f WHERE f.num_prof_veh = ''' ||
                    p_num_prof_veh || '''
                      AND nvl(f.ind_inactivo,''N'') = ''N''
                      AND f.num_pedido_veh = d.num_pedido_veh
                  )
                  )';

      END IF;

    END IF;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_SQL',
                                        'SP_LIST_PEDI_ASIG',
                                        p_cod_usua_sid,
                                        'lista de vehículos para asignacion:',
                                        l_wc_sql,
                                        NULL);
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM (' || l_wc_sql || ')'
      INTO p_tot_regi;

    sql_stmt_paginacion := 'SELECT x.*   FROM ( SELECT ROWNUM fila, a.* FROM ( ' ||
                           l_wc_sql || ' ) a ) x ';

    IF nvl(p_lim_infe, 0) > 0 AND nvl(p_lim_infe, 0) > 0 THEN
      sql_stmt_paginacion := sql_stmt_paginacion || ' WHERE fila BETWEEN ' ||
                             p_lim_infe || ' AND ' || p_lim_supe || '';
    END IF;
    OPEN p_tab FOR sql_stmt_paginacion;

    p_ret_esta := 1;

    p_ret_mens := 'Consulta exitosa: ' || l_cod_cia || '-' || l_cod_filial || '-' ||
                  l_cod_baumuster || '-' || l_vendedor || '-' || l_cod_clie || '-' ||
                  l_cod_area_vta;
  EXCEPTION
    WHEN ve_error THEN
      OPEN p_tab FOR
        SELECT * FROM dual;
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'Paso:' || l_paso || '-' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_PEDI_ASIG',
                                          NULL,
                                          'llego al paso:' || l_paso,
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  --------------
  FUNCTION fun_reserva_vehiculo
  (
    pcia      VARCHAR,
    psku      VARCHAR,
    pusuario  VARCHAR,
    pcolor    VARCHAR,
    pfilial   VARCHAR,
    pfamilia  VARCHAR,
    pmarca    VARCHAR,
    pmodelo   VARCHAR,
    pasesor   VARCHAR,
    pnom_clie VARCHAR,
    pcod_clie VARCHAR,
    popc      VARCHAR,
    sesion    VARCHAR,
    -- <I 82200> NCeron/16-Jun-2016/Corrección
    pc_cod_area_vta gen_area_vta.cod_area_vta%TYPE DEFAULT NULL,
    -- <F 82200>
    p_usuario usuarios.co_usuario%TYPE DEFAULT NULL
  ) RETURN VARCHAR IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    wc_sucursal     gen_sucursales.cod_sucursal%TYPE;
    wc_cod_area_vta gen_area_vta.cod_area_vta%TYPE;
    wc_cod_prov     vve_pedido_veh.cod_prov%TYPE;
    wc_inderror     VARCHAR2(1);
    --
    CURSOR c_ped IS
      SELECT a.rowid rec,
             a.cod_cia,
             a.cod_prov,
             a.num_pedido_veh,
             b.cod_sucursal_orig,
             b.cod_sucursal_rel,
             c.cod_filial,
             des_familia_veh,
             nom_marca,
             des_baumuster,
             color_texto,
             sku_sap
        FROM vve_sec_reserva b,
             gen_filiales    c,
             vve_pedido_veh  a,
             vve_familia_veh d,
             gen_marca       e,
             vve_baumuster   f
       WHERE b.cod_area_vta = wc_cod_area_vta
         AND b.cod_sucursal_orig = wc_sucursal
         AND c.cod_sucursal = b.cod_sucursal_rel
         AND a.cod_cia = pcia
         AND a.sku_sap = psku
         AND a.cod_area_vta = b.cod_area_vta
         AND a.cod_filial = c.cod_filial
         AND nvl(a.cod_color_veh, 'Sin Color') =
             nvl(pcolor, nvl(a.cod_color_veh, 'Sin Color'))
            -- <I 82200> NCeron/16-Jun-2016/Corrección
         AND ((wc_cod_area_vta IN ('001', '003') AND
             a.cod_situ_pedido <> '01') OR
             (wc_cod_area_vta IN ('002', '004') AND
             a.cod_situ_pedido NOT IN
             ('01', '02', '09', '11', '13', '03')))
            -- <F 82200>
         AND ((a.cod_estado_pedido_veh = 'A' OR
             a.cod_estado_pedido_veh = 'R') AND EXISTS
              (SELECT 1
                 FROM vve_pedido_veh_reserva x
                WHERE x.cod_cia = a.cod_cia
                  AND x.cod_prov = a.cod_prov
                  AND x.num_pedido_veh = a.num_pedido_veh
                     -- and trunc(x.FEC_FIN_RESERVA_PEDIDO ) < trunc(sysdate) -- <I 83461>
                  AND nvl(x.ind_exclusivo, 'N') = 'N' --<RQ.25262> HHUANILO se agrega condición
               ))
         AND a.cod_adquisicion_pedido_veh <> '0007'
         AND EXISTS
       (SELECT 1
                FROM venta.vve_estado_pedido x
               WHERE x.cod_estado_pedido = a.cod_estado_pedido_veh
                 AND nvl(ind_inactivo, 'N') = 'N'
                 AND nvl(control_stock, 'N') = 'S')
         AND nvl(a.ind_equipo_esp, 'N') = 'N'
         AND a.ind_nuevo_usado = 'N'
         AND d.cod_familia_veh = a.cod_familia_veh
         AND e.cod_marca = a.cod_marca
         AND f.cod_familia_veh = a.cod_familia_veh
         AND f.cod_marca = a.cod_marca
         AND f.cod_baumuster = a.cod_baumuster
       ORDER BY nsecreser, a.fec_ing_deposito_aduana;
    r_ped c_ped%ROWTYPE;
    -- usuarios envio correo

    CURSOR lista_usuarios IS
      SELECT DISTINCT lower(ltrim(a.di_correo)) di_correo,
                      initcap(a.nombre1 || ' ' || a.paterno) nom_usuario
        FROM usuarios                      a,
             sistemas.usuarios_marca_veh   b,
             usuarios_acti_pedido_veh      c,
             usuarios_acti_area_vta        v,
             sistemas.usuarios_acti_filial d
       WHERE a.co_usuario = b.co_usuario
         AND a.co_usuario = c.co_usuario
         AND b.cod_familia_veh = nvl(pfamilia, cod_familia_veh)
         AND b.cod_marca = nvl(pmarca, cod_marca)
         AND (c.co_usuario = v.co_usuario AND
             c.nur_usuario_acti_pedido = v.nur_usuario_acti_pedido)
         AND (v.co_usuario = d.co_usuario AND
             v.nur_usuario_acti_pedido = d.nur_usuario_acti_pedido AND
             v.nur_usua_acti_area_vta = d.nur_usua_acti_area_vta)
         AND (d.cod_acti_pedido_veh = '0012' AND --Ingreso de Vehiculo
             d.cod_area_vta = wc_cod_area_vta AND d.cod_filial = pfilial)
         AND nvl(a.estado, '000') = '001'
         AND --Estado del usuario 001 = ACTIVO
             nvl(c.ind_recibe_email, 'N') = 'S'
         AND nvl(b.ind_inactivo, 'N') = 'N'
         AND nvl(c.ind_inactivo, 'N') = 'N'
         AND nvl(v.ind_inactivo, 'N') = 'N'
         AND nvl(d.ind_inactivo, 'N') = 'N';
    -- area de venta
    CURSOR c_area
    (
      pcodfam    NUMBER,
      pcod_marca VARCHAR
    ) IS
      SELECT DISTINCT des_area_vta, b.cod_area_vta
        FROM gen_area_vta_filial_fami_veh a, gen_area_vta b
       WHERE a.cod_familia_veh = pcodfam
         AND a.cod_marca = pcod_marca
            -- <I 82200> NCeron/16-Jun-2016/Corrección
         AND nvl(a.ind_inactivo, 'N') = 'N'
            -- <F 82200>
         AND b.cod_area_vta = a.cod_area_vta;

    -- Busca reserva del cliente
    CURSOR c_resercli IS
      SELECT a.num_pedido_veh,
             a.cod_prov,
             b.rowid                recreser,
             a.rowid                recped,
             b.cod_clie,
             fec_reserva_pedido,
             fec_fin_reserva_pedido
        FROM vve_pedido_veh_reserva b, vve_pedido_veh a
       WHERE b.cod_cia = pcia
         AND b.vendedor = pasesor
         AND b.cod_clie = pcod_clie
         AND b.fec_fin_reserva_pedido >= trunc(SYSDATE)
         AND cod_estado_reserva_pedido = '001'
         AND a.cod_cia = b.cod_cia
         AND a.cod_prov = b.cod_prov
         AND a.num_pedido_veh = b.num_pedido_veh
         AND a.sku_sap = psku
         AND a.cod_color_veh = pcolor
         AND nvl(b.ind_exclusivo, 'N') = 'S' --<RQ.25262> HHUANILO se agrega condición
         AND NOT EXISTS
       (SELECT 1
                FROM venta.vve_tmp_reserva x
               WHERE psesion = sesion
                 AND x.cod_prov = a.cod_prov
                 AND x.num_pedido_veh = a.num_pedido_veh);
    wr_resercli c_resercli%ROWTYPE;
    -- Busca reserva el cliente
    CURSOR c_resercli_otros IS
      SELECT a.num_pedido_veh,
             a.cod_cia,
             a.cod_prov,
             c.vendedor,
             c.cod_filial,
             c.rowid                recc,
             a.cod_familia_veh,
             a.cod_marca,
             a.cod_baumuster,
             c.cod_clie,
             c.rowid                recreser,
             a.rowid                recped,
             fec_reserva_pedido,
             fec_fin_reserva_pedido
        FROM vve_sec_reserva b, vve_pedido_veh a, vve_pedido_veh_reserva c
       WHERE b.cod_area_vta = wc_cod_area_vta
         AND b.cod_sucursal_orig = wc_sucursal
         AND a.cod_cia = pcia
         AND a.sku_sap = psku
         AND a.cod_color_veh = pcolor
         AND a.cod_area_vta = b.cod_area_vta
         AND c.cod_cia = a.cod_cia
         AND c.cod_prov = a.cod_prov
         AND c.num_pedido_veh = a.num_pedido_veh
         AND c.fec_fin_reserva_pedido > = trunc(SYSDATE)
         AND c.cod_estado_reserva_pedido = '001'
         AND nvl(c.ind_exclusivo, 'N') = 'N' --<RQ.25262> HHUANILO se agrega condición
       ORDER BY nsecreser, a.fec_ing_deposito_aduana;
    wr_resercliotros c_resercli_otros%ROWTYPE;

    wd_fechai             DATE := SYSDATE;
    wd_fecha              DATE := trunc(SYSDATE);
    wc_horar              VARCHAR2(11);
    wn_dias_no_lab        NUMBER := 0;
    wn_cant               NUMBER := 0;
    wn_nur_reserva_pedido vve_pedido_veh_reserva.nur_reserva_pedido%TYPE;
    wc_num_pedido_veh     vve_pedido_veh.num_pedido_veh%TYPE;
    wc_des_filial         generico.gen_filiales.nom_filial%TYPE;
    wc_des_area_vta       generico.gen_area_vta.des_area_vta%TYPE;
    wc_des_vendedor       arccve.descripcion%TYPE;
    wc_doc_cliente        VARCHAR2(20);
    wc_nom_cliente        generico.gen_persona.nom_perso%TYPE;
    wc_asunto             VARCHAR2(100);
    wc_mensaje            VARCHAR2(4000);
    wc_ret                VARCHAR2(4000);
    --
    wc_des_usuario VARCHAR2(100);
    wc_dir_correo  usuarios.di_correo%TYPE;
    l_user         usuarios.co_usuario%TYPE;
  BEGIN
    -- Datos del Usuario
    BEGIN
      SELECT lower(ltrim(rtrim(di_correo))),
             initcap(nombre1 || ' ' || paterno)
        INTO wc_dir_correo, wc_des_usuario
        FROM usuarios
       WHERE co_usuario = p_usuario;
    EXCEPTION
      WHEN no_data_found THEN
        RETURN 'Error: El Usuario no esta registrado en el sistema.';
    END;
    -- Area vta

    -- <I 82200> NCeron/16-Jun-2016/Corrección
    IF pc_cod_area_vta IS NOT NULL THEN
      wc_cod_area_vta := pc_cod_area_vta;
      SELECT des_area_vta
        INTO wc_des_area_vta
        FROM gen_area_vta
       WHERE cod_area_vta = pc_cod_area_vta;
    ELSE
      OPEN c_area(pfamilia, pmarca);
      FETCH c_area
        INTO wc_des_area_vta, wc_cod_area_vta;
      CLOSE c_area;
    END IF;
    -- <F 82200>

    -- filial
    BEGIN
      SELECT nom_filial, cod_sucursal
        INTO wc_des_filial, wc_sucursal
        FROM generico.gen_filiales
       WHERE cod_filial = pfilial;
    EXCEPTION
      WHEN no_data_found THEN
        NULL;
    END;
    -- vendedor
    BEGIN
      SELECT descripcion
        INTO wc_des_vendedor
        FROM cxc.arccve
       WHERE vendedor = pasesor;
    EXCEPTION
      WHEN no_data_found THEN
        NULL;
    END;
    -- cliente
    BEGIN
      SELECT nvl(num_ruc, num_docu_iden), nom_perso
        INTO wc_doc_cliente, wc_nom_cliente
        FROM generico.gen_persona
       WHERE cod_perso = pcod_clie;
    EXCEPTION
      WHEN no_data_found THEN
        NULL;
    END;
    -- bloque de reserva
    --< I RQ 77488 Gmonar 13/10/2014 --->--
    OPEN c_ped;
    FETCH c_ped
      INTO r_ped;
    IF r_ped.num_pedido_veh IS NOT NULL THEN
      wc_mensaje := r_ped.num_pedido_veh;
    ELSE
      wc_mensaje := NULL;
    END IF;
    CLOSE c_ped;
    RETURN(wc_mensaje);
    --< F RQ 77488 Gmonar 13/10/2014 --->--

    BEGIN
      IF popc IS NULL THEN
        -- reservar
        OPEN c_ped;
        FETCH c_ped
          INTO r_ped;
        IF r_ped.num_pedido_veh IS NOT NULL THEN
          wd_fechai := SYSDATE;
          wc_horar  := to_char(SYSDATE, 'hh24:mi:ss');
          -- Calulamos fecha final de reserva
          LOOP

            BEGIN
              SELECT SUM(cant)
                INTO wn_dias_no_lab
                FROM ((SELECT COUNT(*) cant
                         FROM gen_fec_no_calendario
                        WHERE fec_no_lab = wd_fecha
                          AND nvl(ind_inactivo, 'N') = 'N') UNION
                      (SELECT COUNT(*) cant
                         FROM arlcfr
                        WHERE dia || mes = to_char(wd_fecha, 'ddmm')));
            END;
            --
            IF to_number(to_char(wd_fecha, 'd')) IN (1, 7) OR
               wn_dias_no_lab > 0 THEN
              NULL;
            ELSE
              wn_cant := wn_cant + 1;
            END IF;
            EXIT WHEN wn_cant >= 2;
            wd_fecha := wd_fecha + 1;
          END LOOP;
          --DBMS_OUTPUT.PUT_LINE('fecha fin ');
          -- si la reserva termina a partir de las 6pm ; entonces se finaliza la dia sgte 9 am
          IF wc_horar > '18:00:00' THEN
            wd_fecha := wd_fecha + 1;
            wd_fecha := to_date(to_char(wd_fecha, 'yyyymmdd') ||
                                ' 09:00:00',
                                'yyyymmdd hh24:mi:ss');
            LOOP
              --
              BEGIN
                SELECT SUM(cant)
                  INTO wn_dias_no_lab
                  FROM ((SELECT COUNT(*) cant
                           FROM gen_fec_no_calendario
                          WHERE fec_no_lab = trunc(wd_fecha)
                            AND nvl(ind_inactivo, 'N') = 'N') UNION
                        (SELECT COUNT(*) cant
                           FROM arlcfr
                          WHERE dia || mes = to_char(wd_fecha, 'ddmm')));
              END;

              IF to_number(to_char(wd_fecha, 'd')) IN (1, 7) OR
                 wn_dias_no_lab > 0 THEN
                NULL;
              ELSE
                EXIT;
              END IF;
              wd_fecha := wd_fecha + 1;
            END LOOP;
          ELSE
            wd_fecha := to_date(to_char(wd_fecha, 'yyyymmdd') || wc_horar,
                                'yyyymmdd hh24:mi:ss');
          END IF;
          --DBMS_OUTPUT.PUT_LINE('fecha fin real : '||wd_fecha);
          BEGIN
            -- se crea la reserva
            -- se cambia el estado del pedido a reservado
            UPDATE vve_pedido_veh
               SET cod_estado_pedido_veh = 'R',
                   co_usuario_mod_reg    = p_usuario,
                   fec_modi_reg          = SYSDATE -- reservado
             WHERE ROWID = r_ped.rec
               AND cod_estado_pedido_veh IN ('A', 'R');
            -- Actualizamos a vencido las reservas actuales
            UPDATE vve_pedido_veh_reserva
               SET cod_estado_reserva_pedido = '002'
             WHERE cod_cia = r_ped.cod_cia
               AND cod_prov = r_ped.cod_prov
               AND num_pedido_veh = r_ped.num_pedido_veh;
            -- Insertamos la reserva
            SELECT nvl(MAX(nur_reserva_pedido), 0) + 1
              INTO wn_nur_reserva_pedido
              FROM vve_pedido_veh_reserva
             WHERE cod_cia = r_ped.cod_cia
               AND cod_prov = r_ped.cod_prov
               AND num_pedido_veh = r_ped.num_pedido_veh;
            INSERT INTO vve_pedido_veh_reserva
              (cod_cia,
               cod_prov,
               num_pedido_veh,
               nur_reserva_pedido,
               fec_reserva_pedido,
               fec_fin_reserva_pedido,
               cod_clie,
               cod_filial,
               vendedor,
               obs_reserva_pedido,
               co_usuario_crea_reg,
               fec_crea_reg,
               cod_estado_reserva_pedido)
            VALUES
              (r_ped.cod_cia,
               r_ped.cod_prov,
               r_ped.num_pedido_veh,
               wn_nur_reserva_pedido,
               wd_fechai,
               wd_fecha,
               pcod_clie,
               pfilial,
               pasesor,
               'Reserva Automatica del sistema',
               USER,
               SYSDATE,
               '001');
            --DBMS_OUTPUT.PUT_LINE('creo reserva ');
            -- se creo la reserva
            -- envio de mail
            IF wc_mensaje IS NULL THEN
              wc_asunto  := 'Reserva de Vehiculo ';
              wc_mensaje := '<div style="{font: 12px Arial}">Se ha registrado una reserva de Vehiculo con las sgtes. caracteristicas :  <br><br>' ||
                            '<table style="font: 12px Arial">
                               <tr>
                                <td><b>N? Filial</b></td>
                                <td>' ||
                            ':</td><td>' || wc_des_filial ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>Area de Venta</b></td>
                                <td>' ||
                            ':</td><td>' || wc_des_area_vta ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>Familia </b></td>
                                <td>' ||
                            ':</td><td>' || r_ped.des_familia_veh ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>SKU </b></td>
                                <td>' ||
                            ':</td><td>' || r_ped.sku_sap ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>Marca</b></td>
                                <td>' ||
                            ':</td><td>' || r_ped.nom_marca ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>Modelo</b></td>
                                <td>' ||
                            ':</td><td>' || r_ped.des_baumuster ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>Color</b></td>
                                <td>' ||
                            ':</td><td>' || r_ped.color_texto ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>Asesor</b></td>
                                <td>' ||
                            ':</td><td>' || wc_des_vendedor ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>Fecha Inicio / Hora</b></td>
                                <td>' ||
                            ':</td><td>' ||
                            to_char(wd_fechai, 'dd/mm/yyyy hh24:mi:ss') ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>Fecha Fin / Hora</b></td>
                                <td>' ||
                            ':</td><td>' ||
                            to_char(wd_fecha, 'dd/mm/yyyy hh24:mi:ss') ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>Cliente</b></td>
                                <td>' ||
                            ':</td><td>' || wc_nom_cliente ||
                            '</td>
                            </tr>
                            <tr>
                                <td><b>DNI / RUC </b></td>
                                <td>' ||
                            ':</td><td>' || wc_doc_cliente ||
                            '</td>
                            </tr>
                      </table></div>';
              --DBMS_OUTPUT.PUT_LINE('mail 1 ');

              -- Envia Correos a Personas Responsables
              BEGIN
                sp_pkg_enviar_correo.open(wc_dir_correo);
                sp_pkg_enviar_correo.set_from_address(wc_dir_correo,
                                                      wc_des_usuario);
                FOR c IN lista_usuarios
                LOOP
                  sp_pkg_enviar_correo.set_to_address(c.di_correo,
                                                      c.nom_usuario);
                END LOOP;
                --sp_pkg_enviar_correo.set_bcc_address('csulluchuco@diveimport.com.pe','Christian Sulluchuco');
                sp_pkg_enviar_correo.set_subject(wc_asunto);
                sp_pkg_enviar_correo.set_message(wc_mensaje);
                sp_pkg_enviar_correo.close;
                wc_mensaje := 'Se ha enviado un correo a la(s) persona(s) responsable(s).';
              EXCEPTION
                WHEN OTHERS THEN
                  wc_inderror := '1';
                  wc_mensaje  := 'Error Reserva Veh., no se pudo enviar el correo ...' ||
                                 substr(SQLERRM, 1, 500);
              END;
              --  Commit;
              --DBMS_OUTPUT.PUT_LINE('DESPUES DE COMMIT ');
            ELSE
              ROLLBACK;
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              wc_inderror := '1';
              wc_mensaje  := 'Error al crear reserva ' ||
                             substr(SQLERRM, 1, 200);
          END; -- fin bloque de reserva
        END IF;
        CLOSE c_ped;
      ELSIF popc = '1' THEN
        -- busca reserva para asignacion
        wc_num_pedido_veh := NULL;
        -- se busca reserva del cliente exclusivo
        OPEN c_resercli;
        FETCH c_resercli
          INTO wr_resercli; --wc_num_pedido_veh,wc_cod_prov;
        CLOSE c_resercli;
        IF wr_resercli.num_pedido_veh IS NOT NULL THEN
          wc_num_pedido_veh := wr_resercli.num_pedido_veh;
          wc_mensaje        := wc_num_pedido_veh;
          -- graba lo seleccionado en la sesion
          INSERT INTO venta.vve_tmp_reserva
            (psesion, cod_cia, cod_prov, num_pedido_veh)
          VALUES
            (sesion, pcia, wc_cod_prov, wc_num_pedido_veh);
          --  commit;
          RETURN wc_mensaje;
        END IF;
        -- busca reserva mas antigua
        OPEN c_resercli_otros;
        FETCH c_resercli_otros
          INTO wr_resercliotros;
        CLOSE c_resercli_otros;
        wc_num_pedido_veh := wr_resercliotros.num_pedido_veh;
        IF wc_num_pedido_veh IS NOT NULL THEN
          -- verifica si el cliente de la reserva obtenida es igual al cliente asignado
          IF wr_resercliotros.cod_clie <> wr_resercli.cod_clie THEN
            -- actualiza la reserva obtenida con los datos de la reserva de cliente asignado
            UPDATE vve_pedido_veh_reserva
               SET vendedor               = pasesor,
                   cod_clie               = pcod_clie,
                   cod_filial             = pfilial,
                   fec_reserva_pedido     = wr_resercli.fec_reserva_pedido,
                   fec_fin_reserva_pedido = wr_resercli.fec_fin_reserva_pedido
             WHERE ROWID = wr_resercliotros.recc;
            -- actualiza la reserva del cliente asignado con los datos de la reserva obtenida
            UPDATE vve_pedido_veh_reserva
               SET vendedor               = wr_resercliotros.vendedor,
                   cod_clie               = wr_resercliotros.cod_clie,
                   cod_filial             = wr_resercliotros.cod_filial,
                   fec_reserva_pedido     = wr_resercliotros.fec_reserva_pedido,
                   fec_fin_reserva_pedido = wr_resercliotros.fec_fin_reserva_pedido
             WHERE ROWID = wr_resercli.recreser;
          END IF;
          wc_mensaje := wc_num_pedido_veh;
          -- graba lo seleccionado en la sesion
          INSERT INTO venta.vve_tmp_reserva
            (psesion, cod_cia, cod_prov, num_pedido_veh)
          VALUES
            (sesion, pcia, wc_cod_prov, wc_num_pedido_veh);
          --   commit;
        ELSE
          -- se busca un vehiculos  de las reservas para asignarle al cliente
          OPEN c_resercli_otros;
          FETCH c_resercli_otros
            INTO wr_resercliotros;
          CLOSE c_resercli_otros;
          IF wr_resercliotros.num_pedido_veh IS NOT NULL THEN
            -- se actualiza el registro de reserva asignado al cliente y vendedor
            UPDATE vve_pedido_veh_reserva
               SET vendedor   = pasesor,
                   cod_clie   = pcod_clie,
                   cod_filial = pfilial
             WHERE ROWID = wr_resercliotros.recc;
            --  commit;
            wc_mensaje := wr_resercliotros.num_pedido_veh;
            -- se genera una nueva reserva al vendedor anterior
            wc_ret := fnc_reserva_vehiculo(pcia,
                                           psku,
                                           USER,
                                           pcolor,
                                           wr_resercliotros.cod_filial,
                                           wr_resercliotros.cod_familia_veh,
                                           wr_resercliotros.cod_marca,
                                           wr_resercliotros.cod_baumuster,
                                           wr_resercliotros.vendedor,
                                           NULL,
                                           wr_resercliotros.cod_clie,
                                           NULL,
                                           NULL);
          ELSE
            -- se crea una reserva para el cliente
            wc_ret := fnc_reserva_vehiculo(pcia,
                                           psku,
                                           USER,
                                           pcolor,
                                           pfilial,
                                           pfamilia,
                                           pmarca,
                                           pmodelo,
                                           pasesor,
                                           NULL,
                                           pcod_clie,
                                           NULL,
                                           NULL);
            IF wc_ret NOT LIKE 'Error%' THEN
              wc_mensaje := fnc_reserva_vehiculo(pcia,
                                                 psku,
                                                 USER,
                                                 pcolor,
                                                 pfilial,
                                                 pfamilia,
                                                 pmarca,
                                                 pmodelo,
                                                 pasesor,
                                                 NULL,
                                                 pcod_clie,
                                                 '1',
                                                 sesion);
            END IF;
          END IF;
        END IF;
      END IF;
    END;
    --commit;
    --DBMS_OUTPUT.PUT_LINE('ANTES DE RETURN');
    --rollback;
    RETURN wc_mensaje;
  END;

  PROCEDURE sp_lista_motivo_desasignacion
  (
    p_cod_area_vta VARCHAR2,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR
  ) AS

  BEGIN
    OPEN p_ret_cursor FOR
      SELECT a.cod_motivo, a.des_motivo
        FROM vve_motivo_desasigna a
       WHERE nvl(a.ind_inactivo, 'N') = 'N';
    --AND b.COD_AREA_VTA = P_COD_AREA_VTA;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';
  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LISTA_MOTIVO_DESASIGNACION',
                                          NULL,
                                          'Error al listar los motivos',
                                          p_ret_mens);
  END;

  /*-----------------------------------------------------------------------------
     Nombre : FN_FACT_TRANSITO_FV
     Proposito : Valida si los pedidos de la ficha estan en estado en transito.
     Referencias :
     Parametros :
     Log de Cambios
     Fecha        Autor         Descripcion
     06/02/2018   ARAMOS        Creacion
  ----------------------------------------------------------------------------*/

  FUNCTION fn_fact_transito_fv
  (
    p_cod_cia               vve_ficha_vta_pedido_veh.cod_cia%TYPE,
    p_cod_prov              vve_ficha_vta_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh        vve_ficha_vta_pedido_veh.num_pedido_veh%TYPE,
    p_cod_estado_pedido_veh vve_pedido_veh.cod_estado_pedido_veh%TYPE

  ) RETURN NUMBER IS
    vind_tip_stock vve_situ_pedido.ind_tip_stock%TYPE;
    resultado      NUMBER;
  BEGIN

    vind_tip_stock := pkg_pedido_veh.fun_tipo_stock_sit_pedido(p_cod_cia,
                                                               p_cod_prov,
                                                               p_num_pedido_veh);

    IF (p_cod_estado_pedido_veh = 'P' AND nvl(vind_tip_stock, '0') = '2') THEN
      resultado := 0;
    ELSE
      resultado := 1;
    END IF;

    RETURN resultado;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  /*PROCEDURE sp_list_pedi_fifo
  (
    p_num_ficha_vta_veh    IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh         IN vve_proforma_veh.num_prof_veh%TYPE,
    p_num_pedido_veh       IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_num_chasis           IN vve_pedido_veh.num_chasis%TYPE,
    p_cod_ubica_pedido_veh IN vve_pedido_veh.cod_ubica_pedido_veh%TYPE,
    p_cod_situ_pedido      IN vve_pedido_veh.cod_situ_pedido%TYPE,
    p_sku_sap              IN vve_config_veh.sku_sap%TYPE,
    p_num_placa_veh        IN vve_pedido_veh.num_placa_veh%TYPE,
    p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_lim_infe             NUMBER,
    p_lim_supe             NUMBER,
    p_tab                  OUT SYS_REFCURSOR,
    p_tot_regi             OUT NUMBER,
    p_ret_esta             OUT NUMBER,
    p_ret_mens             OUT VARCHAR
  ) AS
    l_cod_area_vta           vve_ficha_vta_veh.cod_area_vta%TYPE;
    l_cod_cia                vve_ficha_vta_veh.cod_cia%TYPE;
    l_sku_sap                vve_config_veh.sku_sap%TYPE;
    l_cod_color_veh          vve_proforma_veh_det.cod_color_veh%TYPE;
    l_cod_filial             vve_proforma_veh.cod_filial%TYPE;
    l_cod_familia_veh        vve_proforma_veh_det.cod_familia_veh%TYPE;
    l_cod_marca              vve_proforma_veh_det.cod_marca%TYPE;
    l_cod_baumuster          vve_proforma_veh_det.cod_baumuster%TYPE;
    l_vendedor               vve_proforma_veh.vendedor%TYPE;
    l_cod_clie               vve_ficha_vta_proforma_veh.cod_perso_dir%TYPE;
    l_txt_cod_clie           cxc_mae_clie.nom_clie%TYPE;
    l_num_pedido_veh         vve_pedido_veh.num_pedido_veh%TYPE;
    l_cod_prov               vve_pedido_veh.cod_prov%TYPE;
    l_tip_prof_veh           vve_proforma_veh.tip_prof_veh%TYPE;
    l_can_veh                vve_proforma_veh_det.can_veh%TYPE;
    l_can_veh_asig           vve_proforma_veh_det.can_veh%TYPE;
    l_can_disp               vve_proforma_veh_det.can_veh%TYPE;
    l_cod_situ_pedido_aduana vve_situ_pedido.cod_situ_pedido%TYPE;
    l_cod_sucursal_ficha     gen_filial.cod_sucursal%TYPE;
    l_nrol                   NUMBER := 0;
    l_wc_ret                 VARCHAR2(1000);
    l_wc_sucursal            gen_filiales.cod_sucursal%TYPE;
    ve_error EXCEPTION;
    l_wc_sql            VARCHAR2(10000);
    l_ind_fifo          VARCHAR2(2);
    sql_stmt_paginacion VARCHAR2(10000);
  BEGIN
    --Variables Generales
    l_cod_situ_pedido_aduana := '12';
    l_wc_sql                 := '';
    IF nvl(p_num_ficha_vta_veh, 'x') = 'x' THEN
      p_ret_mens := 'El número de ficha de venta es obligatorio';
      RAISE ve_error;
    END IF;

    IF nvl(p_num_prof_veh, 'x') = 'x' THEN
      p_ret_mens := 'El número de proforma es obligatorio';
      RAISE ve_error;
    END IF;

    ----Variables de Ficha de venta
    SELECT a.cod_area_vta, a.cod_cia, b.cod_sucursal
      INTO l_cod_area_vta, l_cod_cia, l_cod_sucursal_ficha
      FROM vve_ficha_vta_veh a
     INNER JOIN gen_filial b
        ON a.cod_filial = b.cod_filial
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh;

    -- variables de la proforma

    SELECT d.sku_sap,
           b.cod_color_veh,
           a.cod_filial,
           b.cod_familia_veh,
           b.cod_marca,
           b.cod_baumuster,
           a.cod_clie,
           nvl(a.tip_prof_veh, '1') tipo_prof_veh,
           a.vendedor,
           b.can_veh
      INTO l_sku_sap,
           l_cod_color_veh,
           l_cod_filial,
           l_cod_familia_veh,
           l_cod_marca,
           l_cod_baumuster,
           l_cod_clie,
           l_tip_prof_veh,
           l_vendedor,
           l_can_veh
      FROM vve_proforma_veh a
     INNER JOIN vve_proforma_veh_det b
        ON a.num_prof_veh = b.num_prof_veh
     INNER JOIN vve_ficha_vta_proforma_veh c
        ON a.num_prof_veh = c.num_prof_veh
      LEFT JOIN vve_config_veh d
        ON d.cod_familia_veh = b.cod_familia_veh
       AND b.cod_marca = d.cod_marca
       AND b.cod_baumuster = d.cod_baumuster
       AND b.cod_config_veh = d.cod_config_veh
     WHERE c.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND a.num_prof_veh = p_num_prof_veh;

    ----Cantidad de vehiculos asignados
    SELECT COUNT(a.num_pedido_veh)
      INTO l_can_veh_asig
      FROM vve_ficha_vta_pedido_veh a
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND a.num_prof_veh = p_num_prof_veh
       AND a.ind_inactivo = 'N';

    -- Cantidad de vehiculos por asignar
    l_can_disp := l_can_veh - l_can_veh_asig;
    BEGIN
      SELECT nom_clie
        INTO l_txt_cod_clie
        FROM cxc.cxc_mae_clie
       WHERE cod_clie = l_cod_clie;
    EXCEPTION
      WHEN no_data_found THEN
        l_txt_cod_clie := 'Cliente no existe';
    END;

    ---------------------

    l_nrol := 0;
    BEGIN
      SELECT COUNT(cod_aut_area_vta)
        INTO l_nrol
        FROM gen_area_vta_aut a
       WHERE cod_aut_area_vta = '05'
            -- Reservas stock FIFO
         AND nvl(ind_inactivo, 'N') = 'N'
         AND cod_area_vta = l_cod_area_vta;
    END;

    IF nvl(l_nrol, 0) > 0 THEN

      l_wc_sql := '

      SELECT
       CASE
         WHEN rownum <= ' || to_char(l_can_disp) ||
                  ' and z.cod_estado_pedido_veh in (''R'',''S'') THEN
          ''S''
         ELSE
          ''N''
       END seleccioando,
       z.*
  FROM (SELECT y.*
          FROM (SELECT x.*,
                       pkg_log_select.func_sel_tapcia(x.cod_cia) cia,
                       pkg_gen_select.func_sel_gen_persona(x.cod_prov) des_prov,
                       (SELECT col.des_color_fabrica_veh
                          FROM vve_color_fabrica_veh col
                         WHERE x.cod_color_veh = col.cod_color_fabrica_veh) des_color_veh,
                       (SELECT des_ubica_pedido
                          FROM vve_ubica_pedido vup
                         WHERE vup.cod_ubica_pedido = x.cod_ubica_pedido_veh
                           AND vup.ind_inactivo = ''N'') des_ubica_pedido,
                       (SELECT s.des_situ_pedido
                          FROM vve_situ_pedido s
                         WHERE s.cod_situ_pedido = x.cod_situ_pedido) des_situ_pedido,
                       (SELECT MAX(ps.fec_situ_pedido)
                          FROM vve_pedido_veh_situ ps
                         WHERE ps.cod_situ_pedido = x.cod_situ_pedido
                           AND x.cod_cia = ps.cod_cia
                           AND x.cod_prov = ps.cod_prov
                           AND x.num_pedido_veh = ps.num_pedido_veh) fec_situ_pedido,
                       pkg_sweb_pedi_veh.fu_sku_pedido(x.cod_cia,
                                                       x.cod_prov,
                                                       x.num_pedido_veh) sku_sap,
                       pkg_sweb_mae_gene.fu_desc_familia(x.cod_familia_veh) des_familia,

                       pkg_sweb_mae_gene.fu_desc_marca(x.cod_marca) des_marca,

                       pkg_sweb_mae_gene.fu_desc_modelo(x.cod_familia_veh,
                                                        x.cod_marca,
                                                        x.cod_baumuster) desc_baumuster,
                       (SELECT sr.nsecreser
                          FROM vve_sec_reserva sr
                         WHERE sr.cod_sucursal_orig = ''' ||
                  l_cod_sucursal_ficha ||
                  ''' -- ficha
                           AND sr.cod_area_vta = x.cod_area_vta
                           AND sr.cod_sucursal_rel IN
                               (SELECT gf.cod_sucursal
                                  FROM gen_filiales gf
                                 WHERE x.cod_filial = gf.cod_filial)) secuencia,
                       (SELECT MAX(psa.fec_situ_pedido) fecha_aduana
                          FROM vve_pedido_veh_situ psa
                         WHERE psa.cod_situ_pedido = ''' ||
                  l_cod_situ_pedido_aduana || '''
                           AND x.cod_cia = psa.cod_cia
                           AND x.cod_prov = psa.cod_prov
                           AND x.num_pedido_veh = psa.num_pedido_veh) fecha_aduana,
                      (SELECT sp.ind_tip_stock
                          FROM vve_situ_pedido sp
                         WHERE x.cod_situ_pedido = sp.cod_situ_pedido) ind_tip_stock,
                       (SELECT sp.prioridad
                          FROM vve_situ_pedido sp
                         WHERE x.cod_situ_pedido = sp.cod_situ_pedido) prioridad_situ,
                         (select ep.des_estado_pedido from vve_estado_pedido ep where ep.cod_estado_pedido=x.cod_estado_pedido_veh)estado_pedido
                  FROM (SELECT a.cod_cia,
                               a.cod_prov,
                               a.num_pedido_veh,
                               a.num_chasis,
                               a.ano_fabricacion_veh,
                               a.cod_color_veh,
                               a.cod_ubica_pedido_veh,
                               a.cod_situ_pedido,
                               ''S'' ind_reserva,
                               a.cod_familia_veh,
                               a.cod_marca,
                               a.cod_baumuster,
                               a.cod_config_veh,
                               a.num_placa_veh,
                               a.cod_filial,
                               a.cod_area_vta,
                               a.cod_estado_pedido_veh

                          FROM vve_pedido_veh a
                         INNER JOIN vve_sec_reserva b
                            ON a.cod_area_vta = b.cod_area_vta
                         INNER JOIN gen_filiales c
                            ON a.cod_filial = c.cod_filial
                         INNER JOIN vve_familia_veh d
                            ON d.cod_familia_veh = a.cod_familia_veh
                         INNER JOIN gen_marca e
                            ON e.cod_marca = a.cod_marca
                         INNER JOIN vve_baumuster f
                            ON f.cod_baumuster = a.cod_baumuster

                         WHERE b.cod_sucursal_orig = ''' ||
                  l_cod_sucursal_ficha ||
                  ''' -- ficha
                             AND b.cod_sucursal_rel = c.cod_sucursal
                          AND a.cod_cia = ''' || l_cod_cia || '''
                           AND a.sku_sap = ' || l_sku_sap || '
                           AND a.cod_area_vta = ''' ||
                  l_cod_area_vta ||
                  ''' -- ficha
                           AND nvl(a.cod_color_veh, ''sin color'') = nvl(''' ||
                  l_cod_color_veh || ''', nvl(a.cod_color_veh, ''sin color''))
                           AND ((''' || l_cod_area_vta ||
                  ''' IN (''001'', ''003'') AND a.cod_situ_pedido <> ''01'') OR
                               (''' || l_cod_area_vta ||
                  ''' IN (''002'', ''004'') AND a.cod_situ_pedido NOT IN (''01'', ''02'', ''09'', ''11'', ''13'', ''03'')))
                           AND (a.cod_estado_pedido_veh = ''R'')
                           AND EXISTS
                         (SELECT 1
                                  FROM vve_pedido_veh_reserva x
                                 WHERE x.cod_cia = a.cod_cia
                                   AND x.cod_prov = a.cod_prov
                                   AND x.num_pedido_veh = a.num_pedido_veh
                                   AND nvl(x.ind_exclusivo,''N'') = ''N'')
                           AND a.cod_adquisicion_pedido_veh <> ''0007''
                           AND nvl(a.ind_equipo_esp, ''N'') = ''N''
                           AND a.ind_nuevo_usado = ''N''
                           AND d.cod_familia_veh = a.cod_familia_veh
                           AND e.cod_marca = a.cod_marca
                           AND f.cod_familia_veh = a.cod_familia_veh
                           AND f.cod_marca = a.cod_marca
                           AND f.cod_baumuster = a.cod_baumuster
                        UNION
                        SELECT a.cod_cia,
                               a.cod_prov,
                               a.num_pedido_veh,
                               a.num_chasis,
                               a.ano_fabricacion_veh,
                               a.cod_color_veh,
                               a.cod_ubica_pedido_veh,
                               a.cod_situ_pedido,
                               ''N'' ind_reserva,
                               a.cod_familia_veh,
                               a.cod_marca,
                               a.cod_baumuster,
                               a.cod_config_veh,
                               a.num_placa_veh,
                               a.cod_filial,
                               a.cod_area_vta,
                               a.cod_estado_pedido_veh
                          FROM v_pedido_veh a
                         WHERE a.cod_area_vta = ''' ||
                  l_cod_area_vta || '''
                           AND a.cod_estado_pedido_veh IN
                               (SELECT epa.cod_estado_pedido
                                  FROM vve_estado_pedido_area epa
                                 WHERE epa.cod_area_vta = ''' ||
                  l_cod_area_vta || '''
                                   AND epa.asigna_ficha = ''S''
                                   AND epa.cod_estado_pedido != ''R'')
                           AND a.cod_adquisicion_pedido_veh <> ''0007''
                           AND a.cod_cia = ''' ||
                  l_cod_cia || '''
                           AND a.sku_sap = ' ||
                  to_char(l_sku_sap) || '
                           AND nvl(a.cod_color_veh, ''sin color'') = nvl(''' ||
                  l_cod_color_veh ||
                  ''', nvl(a.cod_color_veh, ''sin color''))
                           AND (a.cod_cia, a.cod_prov, a.num_pedido_veh) NOT IN
                               (SELECT pf.cod_cia,
                                       pf.cod_prov,
                                       pf.num_pedido_veh
                                  FROM venta.vve_ficha_vta_pedido_veh pf
                                 WHERE pf.cod_cia = a.cod_cia
                                   AND pf.cod_prov = a.cod_prov
                                   AND pf.num_pedido_veh = a.num_pedido_veh
                                   AND nvl(pf.ind_inactivo, ''N'') = ''N'')
                           AND EXISTS
                         (SELECT 1
                                  FROM vve_sec_reserva b, gen_filiales c
                                 WHERE b.cod_sucursal_orig = ''' ||
                  l_cod_sucursal_ficha || '''
                                   AND b.cod_area_vta = a.cod_area_vta
                                   AND c.cod_sucursal = b.cod_sucursal_rel
                                   AND c.cod_filial = a.cod_filial)

                        ) x) y
         ORDER BY y.ind_reserva       DESC,
                  y.secuencia      ASC,
                  y.fecha_aduana   ASC,
                  y.ind_tip_stock,
                  y.prioridad_situ) z';

    END IF;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                        'sp_list_pedi_asig',
                                        p_cod_usua_sid,
                                        'Listar vehiculos:',
                                        l_wc_sql,
                                        NULL);
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM (' || l_wc_sql || ')'
      INTO p_tot_regi;

    sql_stmt_paginacion := 'SELECT x.*   FROM ( SELECT ROWNUM fila, a.*      FROM ( ' ||
                           l_wc_sql || ' ) a ) x ';

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_LOG',
                                        'sp_list_pedi_asig',
                                        p_cod_usua_sid,
                                        'Listar vehiculos:',
                                        sql_stmt_paginacion,
                                        NULL);
    IF nvl(p_lim_infe, 0) > 0 AND nvl(p_lim_infe, 0) > 0 THEN

      sql_stmt_paginacion := sql_stmt_paginacion || ' WHERE fila BETWEEN ' ||
                             p_lim_infe || ' AND ' || p_lim_supe || '';
    END IF;

    OPEN p_tab FOR sql_stmt_paginacion;
    p_ret_esta := 1;

    p_ret_mens := 'Consulta exitosa: ' || l_cod_cia || '-' || l_cod_filial || '-' ||
                  l_cod_baumuster || '-' || l_vendedor || '-' || l_cod_clie || '-' ||
                  l_cod_area_vta;
  EXCEPTION
    WHEN ve_error THEN
      OPEN p_tab FOR
        SELECT * FROM dual;
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_list_pedi_asig',
                                          NULL,
                                          'error al obtener la lista de pedidos',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;*/

  PROCEDURE sp_envia_correo_autorizacion
  (
    p_auto_env          IN VARCHAR2,
    p_auto_apro         IN VARCHAR2,
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_num_prof_veh      IN vve_proforma_veh.num_prof_veh%TYPE,
    p_cod_area_vta      IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_filial        IN vve_pedido_veh.cod_filial%TYPE,
    p_cod_cia           IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov          IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_fec_usuario_aut   IN DATE,
    p_tipo_ref_proc     IN vve_correo_prof.tipo_ref_proc%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
    wc_cod_area_vta      vve_pedido_veh.cod_area_vta%TYPE;
    wc_des_area_vta      gen_area_vta.des_area_vta%TYPE;
    wc_des_filial        gen_filiales.nom_filial%TYPE;
    wc_des_familia_veh   v_pedido_veh.des_familia_veh%TYPE;
    wc_des_aut_ficha_vta VARCHAR2(60);
    wc_mail              usuarios.di_correo%TYPE;
    wc_correo            usuarios.di_correo%TYPE;
    wn_conta_reg         NUMBER := 0;
    wc_asunto            VARCHAR2(100);
    wc_mensaje           VARCHAR2(32500); --<RQ46055> EROZAS /26-11-2013/ Se aumenta la longitud de variable.
    wc_mensaje_aux       VARCHAR2(32500); --<87193 Soporte Legados>
    wn_status_correo     NUMBER;
    wc_co_usuario        VARCHAR2(30);
    wc_nombre            VARCHAR2(100);
    wc_vendedor          VARCHAR2(30);
    wc_jefe              VARCHAR2(30);
    n_num_ped_mail_ficha NUMBER;
    --------
    v_status_correo NUMBER(1);

    --WPALACIOS. REQ 29093. 02/01/2013. Se añade nueva variable.
    --Ini
    vn_val_tot_equipo_local_veh vve_prof_equipo_local_veh.val_tot_equipo_local_veh%TYPE;
    vn_porce                    NUMBER;
    w_contador                  NUMBER;
    w_contador_cont             NUMBER;
    w_flag_pend                 NUMBER;
    w_flag_ped                  NUMBER;
    --Fin

    --<I R30488> Ricardo Cornejo 02/01/2013
    --Equipos Locales
    CURSOR equipo_local(cnum_prof_veh VARCHAR2) IS
      SELECT el.des_equipo_local_veh,
             decode(nvl(pel.ind_cortesia, 'N'),
                    'N',
                    (pel.val_equipo_local_veh * pel.can_equipo_local_veh),
                    0) val_equipo_local_veh,
             decode(nvl(pel.ind_cortesia, 'N'), 'N', pel.porcentaje, 0) porcentaje,
             decode(nvl(pel.ind_cortesia, 'N'), 'N', pel.precio, 0) precio,
             ltrim(rtrim(to_char(decode(nvl(pel.ind_cortesia, 'N'),
                                        'N',
                                        (pel.val_equipo_local_veh *
                                        pel.can_equipo_local_veh),
                                        0),
                                 '999,999,990.99'))) cval_equipo_local_veh,
             ltrim(rtrim(to_char(pel.can_equipo_local_veh, '999,999,990'))) ccan_equipo_local_veh,
             ltrim(rtrim(to_char(decode(nvl(pel.ind_cortesia, 'N'),
                                        'N',
                                        pel.porcentaje,
                                        0),
                                 '999,999,990.99'))) cporcentaje,
             ltrim(rtrim(to_char(decode(nvl(pel.ind_cortesia, 'N'),
                                        'N',
                                        pel.monto_desc,
                                        0),
                                 '999,999,990.99'))) cmonto_desc,
             ltrim(rtrim(to_char(decode(nvl(pel.ind_cortesia, 'N'),
                                        'N',
                                        pel.precio,
                                        0),
                                 '999,999,990.99'))) cprecio
        FROM venta.vve_prof_equipo_local_veh pel,
             venta.vve_equipo_local_veh      el
       WHERE pel.cod_equipo_local_veh = el.cod_equipo_local_veh
         AND pel.num_prof_veh = cnum_prof_veh;
    --Equipos Especiales
    CURSOR equipo_especial(cnum_prof_veh VARCHAR2) IS
      SELECT ee.des_equipo_esp_veh,
             (pee.val_precio_compra * pee.can_equipo_esp_veh) val_precio_compra,
             pee.porcentaje,
             pee.precio,
             ltrim(rtrim(to_char((pee.val_precio_compra *
                                 pee.can_equipo_esp_veh),
                                 '999,999,990.99'))) cval_precio_compra,
             ltrim(rtrim(to_char(pee.can_equipo_esp_veh, '999,999,990'))) ccan_equipo_esp_veh,
             ltrim(rtrim(to_char(pee.porcentaje, '999,999,990.99'))) cporcentaje,
             ltrim(rtrim(to_char(pee.monto_desc, '999,999,990.99'))) cmonto_desc,
             ltrim(rtrim(to_char(pee.precio, '999,999,990.99'))) cprecio
        FROM venta.vve_proforma_equipo_esp_veh pee,
             venta.vve_equipo_esp_veh          ee
       WHERE pee.cod_equipo_esp_veh = ee.cod_equipo_esp_veh
         AND pee.num_prof_veh = cnum_prof_veh;
    --
    npre_veh    vve_proforma_veh_det.val_pre_config_veh%TYPE := 0;
    npor_veh    vve_proforma_veh_det.porcentaje%TYPE := 0;
    ntot_veh    vve_proforma_veh_det.precio%TYPE := 0;
    npre_loc    vve_prof_equipo_local_veh.precio%TYPE := 0;
    nprecio_loc vve_prof_equipo_local_veh.precio%TYPE := 0;
    ntot_loc    vve_prof_equipo_local_veh.precio%TYPE := 0;
    npre_esp    vve_proforma_equipo_esp_veh.precio%TYPE := 0;
    nprecio_esp vve_proforma_equipo_esp_veh.precio%TYPE := 0;
    ntot_esp    vve_proforma_equipo_esp_veh.precio%TYPE := 0;
    nprecio     vve_proforma_veh_det.precio%TYPE := 0;
    --Req.39683.WPALACIOS.19/08/2013.Se modifica la longitud del campo.
    --Ini
    nporcentaje NUMBER := 0; --VE_PROFORMA_VEH_DET.PORCENTAJE%TYPE := 0;
    --Fin
    ntotal vve_proforma_veh_det.precio%TYPE := 0;
    --
    nexiste_local    NUMBER := 0;
    nexiste_especial NUMBER := 0;
    --<F R30488>
    v_cod_clie          gen_persona.cod_perso%TYPE;
    v_nom_clie          gen_persona.nom_perso%TYPE;
    v_obs_ficha_vta_veh vve_ficha_vta_veh.obs_ficha_vta_veh%TYPE;
    v_cod_tipo_pago     vve_ficha_vta_veh.cod_tipo_pago%TYPE;
    url_ficha_venta     VARCHAR(150);
    wc_string           VARCHAR(10);
    --------<I85936>
    n_precio_veh NUMBER;
    n_dcto_veh   NUMBER;
    n_total_veh  NUMBER;

    n_precio_local NUMBER;
    n_dcto_local   NUMBER;
    n_total_local  NUMBER;

    n_precio_especial NUMBER;
    n_dcto_especial   NUMBER;
    n_total_especial  NUMBER;

    n_precio_otros NUMBER;
    n_dcto_otros   NUMBER;
    n_total_otros  NUMBER;

    n_precio_total NUMBER;
    n_dcto_total   NUMBER;
    n_total_total  NUMBER;
    --------<F85936>
  BEGIN
    ---
    n_num_ped_mail_ficha := to_number(pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                                                  '000000064',
                                                                                  'NUM_PED_MAIL_FICHA'));
    -- Nombre de la Filial
    BEGIN
      SELECT nom_filial
        INTO wc_des_filial
        FROM generico.gen_filiales
       WHERE cod_filial = p_cod_filial;
    EXCEPTION
      WHEN no_data_found THEN
        wc_des_filial := NULL;
    END;
    -- Nombre del Area de Venta
    BEGIN
      SELECT des_area_vta
        INTO wc_des_area_vta
        FROM generico.gen_area_vta
       WHERE cod_area_vta = p_cod_area_vta;
    EXCEPTION
      WHEN no_data_found THEN
        wc_des_area_vta := 'Area de venta no existe';
    END;
    BEGIN
      SELECT cod_perso, nom_perso
        INTO v_cod_clie, v_nom_clie
        FROM gen_persona
       WHERE cod_perso =
             (SELECT cod_clie
                FROM vve_ficha_vta_veh
               WHERE num_ficha_vta_veh = p_num_ficha_vta_veh);
    EXCEPTION
      WHEN no_data_found THEN
        v_cod_clie := NULL;
        v_nom_clie := NULL;
    END;
    BEGIN
      SELECT obs_ficha_vta_veh, cod_tipo_pago
        INTO v_obs_ficha_vta_veh, v_cod_tipo_pago
        FROM vve_ficha_vta_veh
       WHERE num_ficha_vta_veh = p_num_ficha_vta_veh;
    EXCEPTION
      WHEN no_data_found THEN
        v_obs_ficha_vta_veh := NULL;
        v_cod_tipo_pago     := NULL;
    END;

    --DESCRIPCION AUTORIZACION APROBADA
    ---< I-30493 31/07/2013 GMonar se lee el nombre de excepción de rol de aprobación de la ficha de la tabla maestra--->
    BEGIN
      SELECT a.des_nombre_exc
        INTO wc_des_aut_ficha_vta
        FROM venta.vve_aut_ficha_vta_exc a
       WHERE a.cod_area_vta = p_cod_area_vta
         AND a.cod_aut_ficha_vta = p_auto_apro
         AND a.ind_inactivo = 'N';
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          SELECT des_aut_ficha_vta
            INTO wc_des_aut_ficha_vta
            FROM venta.vve_aut_ficha_vta
           WHERE cod_aut_ficha_vta = p_auto_apro;
        EXCEPTION
          WHEN OTHERS THEN
            wc_des_aut_ficha_vta := NULL;
        END;
    END;
    ---< F-30493 31/07/2013 GMonar --->
    -- Datos del usuario conectado
    BEGIN
      SELECT lower(di_correo), initcap(nombre1 || ' ' || paterno)
        INTO wc_mail, wc_nombre
        FROM sistemas.usuarios
       WHERE co_usuario = p_cod_usua_sid;
    EXCEPTION
      WHEN no_data_found THEN
        wc_mail   := 'apps@divemotor.com.pe';
        wc_nombre := 'Sistema SID';
    END;
    ----
    -- Obtener url de ambiente
    SELECT upper(instance_name) INTO wc_string FROM v$instance;
    SELECT pkg_gen_parametros.fun_obt_parametro_modulo('0001',
                                                       '000000064',
                                                       'SERV_WEB_LINK_' ||
                                                       wc_string)
      INTO url_ficha_venta
      FROM dual;

    -----
    --'||WC_DES_AUT_FICHA_VTA ||'
    IF p_num_ficha_vta_veh IS NOT NULL THEN
      wc_asunto := 'Autorización ' || wc_des_aut_ficha_vta ||
                   ' a la Ficha de Venta Nro. ' || p_num_ficha_vta_veh;

      wc_mensaje := 'Se ha Autorizado una Ficha de Venta en la Filial ' ||
                    wc_des_filial || ' (' || p_cod_filial || '): <br><br>' ||
                    '<table style="FONT: 9pt Arial">
              <tr>
               <td><b>Nro Ficha</b></td>
               <td>' ||
                    ':</td>
               <td>                   <a href="' ||
                    url_ficha_venta || 'fichas-venta/' ||
                    lpad(p_num_ficha_vta_veh, 12, '0') ||
                    '" style="color:#0076ff">
                                          ' ||
                    lpad(p_num_ficha_vta_veh, 12, '0') || '
                                        </a>
               </td>
              </tr>
              <tr>
               <td> Area de Venta </td>
               <td>' || ':</td><td>' || wc_des_area_vta ||
                    '</td>
              </tr>
              <tr>
               <td> Autorización </td>
               <td>' || ':</td><td>' ||
                    wc_des_aut_ficha_vta || '</td>
              </tr>
              <tr>
               <td> Usuario </td>
               <td>' || ':</td><td>' || wc_nombre ||
                    '</td>
              </tr>
              <tr>
               <td>Fecha </td>
               <td>' || ':</td><td>' ||
                    to_char(p_fec_usuario_aut, 'dd/mm/yyyy hh24:mi:ss') ||
                    '</td>
              </tr>
              <tr>
               <td>Cliente </td>
               <td>' || ':</td><td>' || v_cod_clie ||
                    '   ' || v_nom_clie || '</td>
              </tr>
              <tr>
               <td valign="top">Observaciones </td>
               <td valign="top">' || ':</td><td>' ||
                    REPLACE(v_obs_ficha_vta_veh, chr(10), '<br>') ||
                    '</td>
              </tr>
             </table>';

      w_contador      := 0;
      w_contador_cont := 0;
      w_flag_pend     := 0;
      w_flag_ped      := 0;
      FOR i IN (SELECT pc.num_prof_veh,
                       pc.cod_tipo_importacion,
                       ti.des_tipo_importacion,
                       pd.cod_familia_veh,
                       fv.des_familia_veh,
                       pd.cod_marca,
                       gm.nom_marca,
                       pd.cod_baumuster,
                       bm.des_baumuster,
                       pd.cod_config_veh,
                       --<I-81004>
                       --CV.DES_CONFIG_VEH ,
                       decode(pc.tip_prof_veh,
                              '2',
                              bm.des_baumuster,
                              cv.des_config_veh) des_config_veh,
                       --<F-81004>
                       pd.cod_tipo_veh,
                       vt.des_tipo_veh,
                       pd.can_veh,
                       pd.val_vta_veh,
                       pd.val_pre_veh,
                       pd.can_veh * pd.val_pre_veh total,
                       --<I R30488> Ricardo Cornejo 02/01/2013
                       decode(decode(fvv.cod_tipo_pago,
                                     'C',
                                     fvv.cod_moneda_ficha_vta_veh,
                                     fvv.cod_moneda_cred),
                              'SOL',
                              'S/.',
                              'USD $') ||
                       to_char((nvl(pd.val_pre_oferta_veh,
                                    pd.val_pre_config_veh) +
                               nvl(pd.val_pre_equipo_local_desc, 0) +
                               nvl(pd.val_pre_equipo_esp_desc, 0)),
                               '99,999,999.99') precio,
                       --WPALACIOS REQ. 29093. 02/01/2013. Se modifica para añadir el precio de Lista y % de Descuento.
                       --Ini
                       (nvl(pd.val_pre_oferta_veh, pd.val_pre_config_veh) +
                       nvl(pd.val_pre_equipo_local_desc, 0) +
                       nvl(pd.val_pre_equipo_esp_desc, 0)) preci,
                       decode(decode(fvv.cod_tipo_pago,
                                     'C',
                                     fvv.cod_moneda_ficha_vta_veh,
                                     fvv.cod_moneda_cred),
                              'SOL',
                              'S/.',
                              'USD $') ||
                       to_char((nvl(pd.val_pre_config_veh, 0) +
                               nvl(pd.val_pre_equipo_local_veh, 0) +
                               nvl(pd.val_pre_equipo_esp_veh, 0)),
                               '99,999,999.99') precio_lista,
                       (nvl(pd.val_pre_config_veh, 0) +
                       nvl(pd.val_pre_equipo_local_veh, 0) +
                       nvl(pd.val_pre_equipo_esp_veh, 0)) precio_list
                       --<F R30488>
                       --<I R30488> Ricardo Cornejo 02/01/2013
                      ,
                       fv.des_familia_veh || ' ' || gm.nom_marca || ' ' ||
                       bm.des_baumuster || ' ' || cv.des_config_veh || ' ' ||
                       vt.des_tipo_veh wc_vehiculo,
                       nvl(pd.val_pre_config_veh, 0) npre_veh,
                       pd.porcentaje npor_veh,
                       pd.precio ntot_veh,
                       ltrim(rtrim(to_char((pd.val_pre_config_veh),
                                           '999,999,990.99'))) wc_val_pre_config_veh,
                       ltrim(rtrim(to_char(pd.can_veh, '999,999,990'))) wc_can_veh,
                       ltrim(rtrim(to_char(pd.porcentaje, '999,999,990.99'))) wc_porcentaje,
                       ltrim(rtrim(to_char(pd.monto_desc, '999,999,990.99'))) wc_monto_desc,
                       ltrim(rtrim(to_char(pd.precio, '999,999,990.99'))) wc_precio
                       --<F R30488>
                       --<I 85936>
                      ,
                       decode(decode(fvv.cod_tipo_pago,
                                     'C',
                                     fvv.cod_moneda_ficha_vta_veh,
                                     fvv.cod_moneda_cred),
                              'SOL',
                              'S/.',
                              'USD $') ||
                       to_char(pd.mon_prec_vehi_tran, '999,999,990.99') mon_prec_vehi_tran,
                       decode(decode(fvv.cod_tipo_pago,
                                     'C',
                                     fvv.cod_moneda_ficha_vta_veh,
                                     fvv.cod_moneda_cred),
                              'SOL',
                              'S/.',
                              'USD $') v_moneda
                --<F 85936>
                  FROM venta.vve_proforma_veh           pc,
                       venta.vve_proforma_veh_det       pd,
                       venta.vve_ficha_vta_proforma_veh f,
                       venta.vve_tipo_importacion       ti,
                       venta.vve_familia_veh            fv,
                       generico.gen_marca               gm,
                       venta.vve_baumuster              bm,
                       venta.vve_config_veh             cv,
                       venta.vve_tipo_veh               vt,
                       venta.vve_ficha_vta_veh          fvv
                --
                 WHERE pc.num_prof_veh = pd.num_prof_veh(+)
                   AND pc.num_prof_veh = f.num_prof_veh(+)
                   AND f.num_ficha_vta_veh = p_num_ficha_vta_veh
                   AND fvv.num_ficha_vta_veh = f.num_ficha_vta_veh
                      -- <I 82332> NCeron/02-Ago-2016/
                   AND f.num_prof_veh = nvl(p_num_prof_veh, pc.num_prof_veh)
                      -- <F 82332>

                   AND nvl(f.ind_inactivo, 'N') = 'N'
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
                   AND nvl(ti.ind_inactivo, 'N') = 'N'
                   AND nvl(fv.ind_inactivo, 'N') = 'N'
                   AND nvl(bm.ind_inactivo, 'N') = 'N'
                   AND nvl(cv.ind_inactivo, 'N') = 'N')
      -- AND nvl(vt.ind_inactivo, 'N') = 'N') --<87193 comentado por soporte Legados>-
      LOOP
        IF p_num_pedido_veh IS NULL THEN
          w_contador  := w_contador + 1;
          w_flag_pend := 1;
          w_flag_ped  := 1;
        END IF;

        -------------------------------------
        --------------------------------------
        --<I85936>
        SELECT val_pre_config_veh precio,
               (CASE
                 WHEN nvl(val_pre_config_veh, 0) = 0 THEN
                  0
                 ELSE
                  round(nvl((100 - ((nvl(precio, 0) * 100) /
                            nvl(val_pre_config_veh, 0))),
                            0),
                        3)
               END) descuento,
               precio venta
          INTO n_precio_veh, n_dcto_veh, n_total_veh
          FROM venta.vve_proforma_veh_det
         WHERE num_prof_veh = i.num_prof_veh;

        SELECT precio,
               decode(precio,
                      0,
                      0,
                      round(100 - ((nvl(venta, 0) * 100) / nvl(precio, 0)),
                            3)) descuento,
               venta
          INTO n_precio_local, n_dcto_local, n_total_local
          FROM (SELECT nvl(SUM((de.val_equipo_local_veh *
                               de.can_equipo_local_veh)),
                           0) precio,
                       nvl(SUM((de.precio)), 0) venta
                  FROM vve_prof_equipo_local_veh  de,
                       venta.vve_equipo_local_veh b,
                       vve_tipo_equipo_local_veh  t
                 WHERE de.cod_equipo_local_veh = b.cod_equipo_local_veh
                   AND b.cod_tipo_equipo_local_veh =
                       t.cod_tipo_equipo_local_veh(+)
                   AND nvl(t.sub_tipo, '1') = '1'
                   AND nvl(de.ind_cortesia, 'N') = 'N'
                   AND nvl(de.ind_pag_cliente, 'N') = 'N'
                   AND de.precio > 0
                   AND num_prof_veh = i.num_prof_veh);

        SELECT precio,
               decode(precio,
                      0,
                      0,
                      round(100 - ((nvl(venta, 0) * 100) / nvl(precio, 0)),
                            3)) descuento,
               venta
          INTO n_precio_otros, n_dcto_otros, n_total_otros
          FROM (SELECT nvl(SUM((de.val_equipo_local_veh *
                               de.can_equipo_local_veh)),
                           0) precio,
                       nvl(SUM((de.precio)), 0) venta
                  FROM vve_prof_equipo_local_veh  de,
                       venta.vve_equipo_local_veh b,
                       vve_tipo_equipo_local_veh  t
                 WHERE de.cod_equipo_local_veh = b.cod_equipo_local_veh
                   AND b.cod_tipo_equipo_local_veh =
                       t.cod_tipo_equipo_local_veh(+)
                   AND nvl(t.sub_tipo, '1') = '3'
                   AND nvl(de.ind_cortesia, 'N') = 'N'
                   AND nvl(de.ind_pag_cliente, 'N') = 'N'
                   AND de.precio > 0
                   AND num_prof_veh = i.num_prof_veh);

        SELECT nvl(SUM(val_precio_compra * can_equipo_esp_veh), 0) precio,
               round(CASE
                       WHEN nvl(SUM(val_precio_compra * can_equipo_esp_veh), 0) = 0 THEN
                        0
                       ELSE
                        100 - ((nvl(SUM(precio), 0) * 100) /
                        nvl(SUM(val_precio_compra * can_equipo_esp_veh), 0))
                     END,
                     3) descuento,
               nvl(SUM(precio), 0) venta
          INTO n_precio_especial, n_dcto_especial, n_total_especial
          FROM venta.vve_proforma_equipo_esp_veh
         WHERE num_prof_veh = i.num_prof_veh;

        SELECT pkg_sweb_vta_proforma.fu_precio_lista_proforma(p_num_prof_veh) precio,
               round(pkg_sweb_vta_proforma.fu_descuento_proforma(p_num_prof_veh),
                     3) descuento,
               pkg_sweb_vta_proforma.fu_precio_total_proforma(p_num_prof_veh) venta
          INTO n_precio_total, n_dcto_total, n_total_total
          FROM dual a;

        --<F85936>
        -----------------------------------------
        ------------------------------------------

        --WPALACIOS REQ. 29093. 02/01/2013. Se modifica para añadir el precio de Lista y % de Descuento.
        --Ini
        --Calculamos el porcentaje.
        BEGIN
          SELECT SUM(nvl(val_tot_equipo_local_veh, 0))
            INTO vn_val_tot_equipo_local_veh
            FROM vve_prof_equipo_local_veh
           WHERE num_prof_veh = i.num_prof_veh
             AND nvl(ind_cortesia, 'N') = 'S';
        EXCEPTION
          WHEN OTHERS THEN
            vn_val_tot_equipo_local_veh := 0;
        END;
        vn_porce := round(((nvl(i.precio_list, 0) -
                          (nvl(i.preci, 0) -
                          nvl(vn_val_tot_equipo_local_veh, 0))) /
                          i.precio_list) * 100,
                          2);
        --Fin
        --<I R30488> Ricardo Cornejo 02/01/2013
        npre_veh := i.npre_veh;
        ntot_veh := i.ntot_veh;
        -- <I 82332> NCeron/02-Ago-2016/
        IF p_num_pedido_veh IS NULL THEN
          IF w_contador_cont = 1 THEN
            wc_mensaje := wc_mensaje || '<table style="FONT: 9pt arial">
                   <tr>
                     <td colspan="2"><b>Proforma(s) (...continúa): </b></td>
                     <td></td><td></td>
                   </tr>';
          ELSE
            wc_mensaje := wc_mensaje || '<table style="FONT: 9pt arial">
                   <tr>
                     <td colspan="2"><b>Proforma(s) : </b></td>
                     <td></td><td></td>
                   </tr>';
          END IF;
        ELSE
          wc_mensaje := wc_mensaje || '<table style="FONT: 9pt arial">
                  <tr>
                    <td colspan="2"><b>Proforma(s) :</b></td>
                    <td></td><td></td>
                  </tr>';
        END IF;
        -- <F 82332>
        --<F R30488>
        --<I85936>
        /*
        wc_mensaje := wc_mensaje || '
                 <tr>
                   <td> ; ; ;</td>
                   <td>Proforma </td>
                   <td>' || ':</td><td>' ||
                      i.num_prof_veh || '</td>
                 </tr>
                 <tr>
                   <td> ; ; ;</td>
                   <td>Familia </td>
                   <td>' || ':</td><td>' ||
                      i.des_familia_veh || '</td>
                 </tr>
                 <tr>
                   <td> ; ; ;</td>
                   <td>Marca </td>
                   <td>' || ':</td><td>' ||
                      i.nom_marca || '</td>
                 </tr>
                 <tr>
                   <td> ; ; ;</td>
                   <td>Modelo </td>
                   <td>' || ':</td><td>' ||
                      i.des_config_veh || '</td>
                 </tr>
                 <tr>
                   <td> ; ; ;</td>
                   <td>Nro. Unidades </td>
                   <td>' || ':</td><td>' || i.can_veh ||
                      '</td>
                 </tr>
                 <tr>
                   <td> ; ; ;</td>
                   <td>Precio Unitario </td>
                   <td>' || ':</td><td>' || i.precio ||
                      '</td>
                 </tr>'
                     --WPALACIOS REQ. 29093. 02/01/2013. Se modifica para añadir el precio de Lista y % de Descuento.
                     --Ini
                      || '<tr>
                   <td> ; ; ;</td>
                   <td>Precio Lista </td>
                   <td>' || ':</td><td>' ||
                      i.precio_lista || '</td>
                 </tr>
                 <tr>
                   <td> ; ; ;</td>
                   <td>% Dscto </td>
                   <td>' || ':</td><td>' ||
                      to_char(vn_porce, '99990.99') ||
                      '%</td>
                 </tr>';
                 */
        wc_mensaje := wc_mensaje || '
                 <tr>
                   <td style="width:20px;"></td>
                   <td>Proforma </td>
                   <td>' || ':</td><td>' ||
                      i.num_prof_veh || '</td>
                 </tr>
                 <tr>
                   <td> </td>
                   <td>Familia </td>
                   <td>' || ':</td><td>' ||
                      i.des_familia_veh || '</td>
                 </tr>
                 <tr>
                   <td> </td>
                   <td>Marca </td>
                   <td>' || ':</td><td>' ||
                      i.nom_marca || '</td>
                 </tr>
                 <tr>
                   <td> </td>
                   <td>Modelo </td>
                   <td>' || ':</td><td>' ||
                      i.des_config_veh || '</td>
                 </tr>
                 <tr>
                   <td> </td>
                   <td>Nro. Unidades </td>
                   <td>' || ':</td><td>' || i.can_veh ||
                      '</td>
                 </tr>

                 <tr>
                   <td> </td>
                   <td>Autonomía Máxima</td>
                   <td>' || ':</td><td>' ||
                      i.mon_prec_vehi_tran ||
                      '</td>
                 </tr>
                 <tr>
                    <td> </td>
                    <td colspan="3">
                    <table style="FONT: 9pt arial">
                        <tr style="background-color: #c5c3bc;">
                            <th >Item</th>
                            <th style="width:100px;">Precio</th>
                            <th style="width:100px;">Dcto%</th>
                            <th style="width:100px;">Total</th>
                        </tr>
                        <tr >
                            <td>Precio Venta Chasis/vehículo</td>
                            <td style="text-align: right; ">' ||
                      to_char(n_precio_veh, '999,999,990.99') ||
                      '</td>
                            <td style="text-align: right; ">' ||
                      to_char(n_dcto_veh, '990.99') ||
                      '</td>
                            <td style="text-align: right; ">' ||
                      to_char(n_total_veh, '999,999,990.99') ||
                      '</td>
                        </tr>
                        <tr >
                            <td>Eq. Local</td>
                            <td style="text-align: right;">' ||
                      to_char(n_precio_local, '999,999,990.99') ||
                      '</td>
                            <td style="text-align: right;">' ||
                      to_char(n_dcto_local, '990.99') ||
                      '</td>
                            <td style="text-align: right;">' ||
                      to_char(n_total_local, '999,999,990.99') ||
                      '</td>
                        </tr>
                        <tr>';
        IF (n_precio_especial > 0) THEN
          wc_mensaje := wc_mensaje || '
                            <td>Eq. Especial</td>
                            <td style="text-align: right;">' ||
                        to_char(n_precio_especial, '999,999,990.99') ||
                        '</td>
                            <td style="text-align: right;">' ||
                        to_char(n_dcto_especial, '990.99') ||
                        '</td>
                            <td style="text-align: right;">' ||
                        to_char(n_total_especial, '999,999,990.99') ||
                        '</td>
                        </tr>';
        END IF;
        wc_mensaje := wc_mensaje || '
                        <tr >
                            <td>Otros Adicionales</td>
                            <td style="text-align: right;">' ||
                      to_char(n_precio_otros, '999,999,990.99') ||
                      '</td>
                            <td style="text-align: right;">' ||
                      to_char(n_dcto_otros, '990.99') ||
                      '</td>
                            <td style="text-align: right;">' ||
                      to_char(n_total_otros, '999,999,990.99') ||
                      '</td>
                        </tr>
                        <tr style="background:#cccccc">
                            <td>Total Precio Unidad</td>
                            <td style="text-align: right;">' ||
                      to_char(n_precio_total, '999,999,990.99') ||
                      '</td>
                            <td style="text-align: right;">' ||
                      to_char(n_dcto_total, '990.99') ||
                      '</td>
                            <td style="text-align: right;">' ||
                      to_char(n_total_total, '999,999,990.99') ||
                      '</td>
                        </tr>
                        <tr >
              <th></th>
              <th></th>
                            <th  >Total Operación</th>

                            <th style="text-align: right; background:#cccccc " >' ||
                      i.v_moneda || ' ' ||
                      to_char(i.total, '999,999,990.99') ||
                      '</th>
                        </tr>
                    </table>

                    </td>
                 </tr>

                 ';
        --<I85936>
        --Fin
        --<I R30488> Ricardo Cornejo 02/01/2013
        wc_mensaje := wc_mensaje || '</table>';

        IF p_auto_env = '02' THEN
          --Existe Equipo Local
          BEGIN
            SELECT COUNT(1)
              INTO nexiste_local
              FROM venta.vve_prof_equipo_local_veh pel,
                   venta.vve_equipo_local_veh      el
             WHERE pel.cod_equipo_local_veh = el.cod_equipo_local_veh
               AND pel.num_prof_veh = i.num_prof_veh;
          EXCEPTION
            WHEN no_data_found THEN
              nexiste_local := 0;
          END;
          --Existe Equipo Especial
          BEGIN
            SELECT COUNT(*)
              INTO nexiste_especial
              FROM venta.vve_proforma_equipo_esp_veh pee,
                   venta.vve_equipo_esp_veh          ee
             WHERE pee.cod_equipo_esp_veh = ee.cod_equipo_esp_veh
               AND pee.num_prof_veh = i.num_prof_veh;
          EXCEPTION
            WHEN no_data_found THEN
              nexiste_especial := 0;
          END;
          --
          wc_mensaje := wc_mensaje ||
                        '<table border="0" cellpadding="0" cellspacing="1" bgcolor="#CC9933" style="FONT: 9pt Arial">
                   <tr>
                     <td colspan="2"
                     style="text-align: center; width: 263px; background-color: rgb(204, 204, 204); font-weight: bold;">ITEM</td>
                     <td
                       style="text-align: center; width: 106px; background-color: rgb(204, 204, 204); font-weight: bold;">Cantidad</td>
                       <td
                         style="text-align: center; width: 115px; background-color: rgb(204, 204, 204); font-weight: bold;">Precio Lista
                       (Unidades)</td>
                       <td
                         style="text-align: center; width: 100px; background-color: rgb(204, 204, 204); font-weight: bold;">% Descuento</td>
                       <td
                         style="text-align: center; width: 123px; background-color: rgb(204, 204, 204); font-weight: bold;">Precio Venta
                       </td>
                     </tr>
                     <tr bgcolor="#FFFFFF">
                     <td colspan="2" style="width: 263px;">' ||
                        i.wc_vehiculo ||
                        '</td>
                     <td style="width: 106px; text-align: center;">' || 1 ||
                        '</td>
                     <td style="width: 115px; text-align: right;">' ||
                        i.wc_val_pre_config_veh ||
                        '</td>
                     <td style="width: 100px; text-align: right;">' ||
                        i.wc_porcentaje ||
                        '</td>
                     <td style="width: 123px; text-align: right;">' ||
                        i.wc_precio || '</td>
                   </tr>';
          --Equipos Locales
          wc_mensaje := wc_mensaje || '
                   <tr bgcolor="#FFFFFF" style="font-weight: bold;">
                     <td colspan="6" style="width: 263px;">Equipo
                     Local</td>
                   </tr>';
          IF nexiste_local IS NOT NULL AND nexiste_local <> 0 THEN
            FOR rcur IN equipo_local(i.num_prof_veh)
            LOOP
              wc_mensaje := wc_mensaje || '
                       <tr bgcolor="#FFFFFF">
                         <td colspan="2" style="width: 263px;">' ||
                            rcur.des_equipo_local_veh ||
                            '</td>
                         <td style="width: 106px; text-align: center;">' ||
                            rcur.ccan_equipo_local_veh ||
                            '</td>
                         <td style="width: 115px; text-align: right;">' ||
                            rcur.cval_equipo_local_veh ||
                            '</td>
                         <td style="width: 100px; text-align: right;">' ||
                            rcur.cporcentaje ||
                            '</td>
                         <td style="width: 123px; text-align: right;">' ||
                            rcur.cprecio || '</td>
                       </tr>';
              npre_loc   := npre_loc + rcur.val_equipo_local_veh;
              ntot_loc   := ntot_loc + rcur.precio;
            END LOOP;
            IF nvl(npre_loc, 0) = 0 THEN
              wc_mensaje := wc_mensaje || '
                       <tr>
                         <td colspan="3"
                         style="width: 263px; background-color: rgb(204, 204, 204);"><span
                         style="font-weight: bold;">Total Equipo Local</span></td>
                         <td
                         style="width: 115px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(npre_loc, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                         <td
                         style="width: 100px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                            '</td>
                         <td
                         style="width: 123px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(ntot_loc, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                       </tr>';
            ELSE
              wc_mensaje := wc_mensaje || '
                       <tr>
                         <td colspan="3"
                         style="width: 263px; background-color: rgb(204, 204, 204);"><span
                         style="font-weight: bold;">Total Equipo Local</span></td>
                         <td
                         style="width: 115px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(npre_loc, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                         <td
                         style="width: 100px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(100 - ((ntot_loc * 100) /
                                                    npre_loc),
                                                    0),
                                                '999,999,990.99'))) ||
                            '</td>
                         <td
                         style="width: 123px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                            ltrim(rtrim(to_char(nvl(ntot_loc, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                       </tr>';
            END IF;
          ELSE
            wc_mensaje := wc_mensaje || '
                   <tr bgcolor="#FFFFFF">
                     <td colspan="2" style="width: 263px;">' ||
                          'NO TIENE EQUIPOS LOCALES' ||
                          '</td>
                     <td style="width: 106px; text-align: center;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990'))) ||
                          '</td>
                     <td style="width: 115px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                     <td style="width: 100px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                     <td style="width: 123px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                   </tr>
                   <tr>
                     <td colspan="3"
                     style="width: 263px; background-color: rgb(204, 204, 204);"><span
                     style="font-weight: bold;">Total Equipo Local</span></td>
                     <td
                     style="width: 115px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                     <td
                     style="width: 100px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                     <td
                     style="width: 123px; background-color: rgb(204, 204, 204); text-align: right; font-weight: bold;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                   </tr>';
          END IF;
          --Equipos Especiales
          wc_mensaje := wc_mensaje || '
                 <tr bgcolor="#FFFFFF" style="font-weight: bold;">
                   <td colspan="6" style="width: 263px;">Equipo
                   Especial</td>
                 </tr>';
          IF nexiste_especial IS NOT NULL AND nexiste_especial <> 0 THEN
            FOR rcur IN equipo_especial(i.num_prof_veh)
            LOOP
              wc_mensaje := wc_mensaje || '
                     <tr bgcolor="#FFFFFF">
                       <td colspan="2" style="width: 263px;">' ||
                            rcur.des_equipo_esp_veh ||
                            '</td>
                       <td style="width: 106px; text-align: center;">' ||
                            rcur.ccan_equipo_esp_veh ||
                            '</td>
                       <td style="width: 115px; text-align: right;">' ||
                            rcur.cval_precio_compra ||
                            '</td>
                       <td style="width: 100px; text-align: right;">' ||
                            rcur.cporcentaje ||
                            '</td>
                       <td style="width: 123px; text-align: right;">' ||
                            rcur.cprecio || '</td>
                     </tr>';
              npre_esp   := npre_esp + rcur.val_precio_compra;
              ntot_esp   := ntot_esp + rcur.precio;
            END LOOP;
            IF nvl(npre_esp, 0) = 0 THEN
              wc_mensaje := wc_mensaje || '
                     <tr>
                       <td colspan="3"
                       style="width: 263px; background-color: rgb(204, 204, 204);"><span
                       style="font-weight: bold;">Total Equipo Especial</span></td>
                       <td
                       style="width: 115px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(npre_esp, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                       <td
                       style="width: 100px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                            '</td>
                       <td
                       style="width: 123px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(ntot_esp, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                     </tr>';
            ELSE
              wc_mensaje := wc_mensaje || '
                     <tr>
                       <td colspan="3"
                       style="width: 263px; background-color: rgb(204, 204, 204);"><span
                       style="font-weight: bold;">Total Equipo Especial</span></td>
                       <td
                       style="width: 115px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(npre_esp, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                       <td
                       style="width: 100px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(100 - ((ntot_esp * 100) /
                                                    npre_esp),
                                                    0),
                                                '999,999,990.99'))) ||
                            '</td>
                       <td
                       style="width: 123px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                            ltrim(rtrim(to_char(nvl(ntot_esp, 0),
                                                '999,999,990.99'))) ||
                            '</td>
                     </tr>';
            END IF;
          ELSE
            wc_mensaje := wc_mensaje || '
                   <tr bgcolor="#FFFFFF">
                     <td colspan="2" tyle="width: 263px;">' ||
                          'NO TIENE EQUIPOS ESPECIALES' ||
                          '</td>
                     <td style="width: 106px; text-align: center;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990'))) ||
                          '</td>
                     <td style="width: 115px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                     <td style="width: 100px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                     <td style="width: 123px; text-align: right;">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                   </tr>
                   <tr>
                     <td colspan="3"
                     style="width: 263px; background-color: rgb(204, 204, 204);"><span
                     style="font-weight: bold;">Total Equipo Especial</span></td>
                     <td
                     style="width: 115px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                     <td
                     style="width: 100px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                     <td
                     style="width: 123px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                          ltrim(rtrim(to_char(0, '999,999,990.99'))) ||
                          '</td>
                   </tr>';
          END IF;
          nprecio := nvl((nvl(npre_veh, 0) + nvl(npre_loc, 0) +
                         nvl(npre_esp, 0)),
                         0);
          IF (nvl(npre_veh, 0) + nvl(npre_loc, 0) + nvl(npre_esp, 0)) = 0 THEN
            nporcentaje := 0;
          ELSE
            nporcentaje := nvl((100 -
                               nvl((((nvl(ntot_veh, 0) + nvl(ntot_loc, 0) +
                                    nvl(ntot_esp, 0)) * 100) /
                                    (nvl(npre_veh, 0) + nvl(npre_loc, 0) +
                                    nvl(npre_esp, 0))),
                                    0)),
                               0);
          END IF;
          ntotal      := nvl((nvl(ntot_veh, 0) + nvl(ntot_loc, 0) +
                             nvl(ntot_esp, 0)),
                             0);
          wc_mensaje  := wc_mensaje || '
                 <tr  style="font-weight: bold;">
                   <td colspan="3"
                   style="width: 263px; background-color: rgb(204, 204, 204);"><span
                   style="font-weight: bold;">TOTAL PROFORMA</span></td>
                   <td
                   style="width: 115px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                         ltrim(rtrim(to_char(nprecio, '999,999,990.99'))) ||
                         '</td>
                   <td
                   style="width: 100px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                         ltrim(rtrim(to_char(nporcentaje, '999,999,990.99'))) ||
                         '</td>
                   <td
                   style="width: 123px; text-align: right; font-weight: bold; background-color: rgb(204, 204, 204);">' ||
                         ltrim(rtrim(to_char(ntotal, '999,999,990.99'))) ||
                         '</td>
                 </tr>
                 </table><br>';
          npre_veh    := 0;
          npor_veh    := 0;
          ntot_veh    := 0;
          npre_loc    := 0;
          nprecio_loc := 0;
          ntot_loc    := 0;
          npre_esp    := 0;
          nprecio_esp := 0;
          ntot_esp    := 0;
          nprecio     := 0;
          nporcentaje := 0;
          ntotal      := 0;
        END IF;
        --<F R30488>
        -- <I 82332> NCeron/02-Ago-2016/
        IF p_num_pedido_veh IS NULL THEN
          IF w_contador >= n_num_ped_mail_ficha THEN
            w_contador_cont := 1;
            w_contador      := 0;
            w_flag_pend     := 0;
            -- Envia correo
            sp_envia_correo_vendedor(wc_mail,
                                     wc_nombre,
                                     wc_vendedor,
                                     wc_jefe,
                                     wc_asunto,
                                     wc_mensaje,
                                     p_auto_env,
                                     p_auto_apro,
                                     p_num_ficha_vta_veh,
                                     p_cod_area_vta,
                                     p_cod_filial,
                                     v_cod_tipo_pago,
                                     p_tipo_ref_proc,
                                     p_cod_usua_sid,
                                     p_cod_usua_web,
                                     p_ret_esta,
                                     p_ret_mens,
                                     p_num_pedido_veh);
            -- Fin Enviar Correo
            wc_mensaje := '';
          END IF;
        END IF;
        -- <F 82332>
      END LOOP;

      -- <I 82332> NCeron/02-Ago-2016/
      IF p_num_pedido_veh IS NULL THEN
        IF /*w_flag_ped = 0 or*/
         (w_flag_ped = 1 AND w_flag_pend = 1) THEN
          w_contador_cont := 1;
          w_contador      := 0;
          w_flag_pend     := 0;
          -- Envia correo
          sp_envia_correo_vendedor(wc_mail,
                                   wc_nombre,
                                   wc_vendedor,
                                   wc_jefe,
                                   wc_asunto,
                                   wc_mensaje,
                                   p_auto_env,
                                   p_auto_apro,
                                   p_num_ficha_vta_veh,
                                   p_cod_area_vta,
                                   p_cod_filial,
                                   v_cod_tipo_pago,
                                   p_tipo_ref_proc,
                                   p_cod_usua_sid,
                                   p_cod_usua_web,
                                   p_ret_esta,
                                   p_ret_mens,
                                   p_num_pedido_veh);
          -- Fin Enviar Correo
          wc_mensaje := '';
        END IF;
      END IF;

      w_contador      := 0;
      w_contador_cont := 0;
      w_flag_pend     := 0;
      w_flag_ped      := 0;
      FOR j IN (SELECT g.nom_filial,
                       p.num_pedido_veh,
                       f.num_prof_veh,
                       p.des_marca,
                       p.des_baumuster,
                       p.num_chasis,
                       p.num_motor_veh,
                       p.cod_propietario_veh,
                       p.des_propietario_veh,
                       --<I-87193>
                       p.val_pre_clausula_compra,
                       p.ind_nuevo_usado
                --<F-87193>
                  FROM venta.v_pedido_veh             p,
                       venta.vve_ficha_vta_pedido_veh f,
                       generico.gen_filiales          g
                 WHERE p.cod_cia = f.cod_cia(+)
                   AND p.cod_prov = f.cod_prov(+)
                   AND p.num_pedido_veh = f.num_pedido_veh(+)
                   AND p.cod_filial = g.cod_filial(+)
                   AND nvl(f.ind_inactivo, 'N') = 'N'
                   AND f.num_ficha_vta_veh = p_num_ficha_vta_veh
                   AND p.cod_cia = nvl(p_cod_cia, p.cod_cia)
                   AND p.cod_prov = nvl(p_cod_prov, p.cod_prov)
                   AND p.num_pedido_veh =
                       nvl(p_num_pedido_veh, p.num_pedido_veh))
      LOOP
        w_contador  := w_contador + 1;
        w_flag_pend := 1;
        w_flag_ped  := 1;
        IF w_contador = 1 THEN
          IF w_contador_cont = 1 THEN
            wc_mensaje := wc_mensaje || '<table style="FONT: 9pt arial">
                   <tr>
                     <td colspan="2"><b>Pedido(s) (...continúa): </b></td>
                     <td></td><td></td>
                   </tr>';
          ELSE
            wc_mensaje := wc_mensaje || '<table style="FONT: 9pt arial">
                   <tr>
                     <td colspan="2"><b>Pedido(s) : </b></td>
                     <td></td><td></td>
                   </tr>';
          END IF;
        END IF;
        --<I-87193>
        --Se agrego la fila "Costo"
        IF j.ind_nuevo_usado = 'U' THEN
          wc_mensaje_aux := '<tr>
                   <td></td>
                   <td>Costo </td>
                   <td>' || ':</td><td>' ||
                            j.val_pre_clausula_compra ||
                            '</td>
               </tr>';
        ELSE
          wc_mensaje_aux := '';
        END IF;
        --<F-87193>
        wc_mensaje := wc_mensaje || '
               <tr>
                 <td style="width:20px;"> </td>
                 <td>Filial </td>
                 <td>' || ':</td><td>' || j.nom_filial ||
                      '</td>
               </tr>
               <tr>
                 <td> </td>
                 <td>Pedido</td>
                 <td>' || ':</td><td>' ||
                      j.num_pedido_veh || '</td>
               </tr>
               <tr>
                 <td> </td>
                 <td>Proforma</td>
                 <td>' || ':</td><td>' ||
                      j.num_prof_veh || '</td>
               </tr>
               <tr>
                 <td> </td>
                 <td>Marca </td>
                 <td>' || ':</td><td>' || j.des_marca ||
                      '</td>
               </tr>
                 <tr>
                 <td> </td>
                 <td>Modelo </td>
                 <td>' || ':</td><td>' ||
                      j.des_baumuster || '</td>
               </tr>
               <tr>
                 <td> </td>
                 <td>Chasis </td>
                 <td>' || ':</td><td>' || j.num_chasis ||
                      '</td>
               </tr>
               <tr>
                 <td> </td>
                 <td>Motor </td>
                 <td>' || ':</td><td>' ||
                      j.num_motor_veh || '</td>
               </tr>' || wc_mensaje_aux ||
                      '<tr>
                 <td> </td>
                 <td>Cliente </td>
                 <td>' || ':</td><td>' ||
                      j.cod_propietario_veh || ' - ' ||
                      j.des_propietario_veh || '</td>
               </tr>
                 <tr>
                 <td> </td>
                 <td>      </td>
                 <td>   </td><td> </td>
               </tr>';
        IF w_contador >= n_num_ped_mail_ficha THEN
          w_contador_cont := 1;
          wc_mensaje      := wc_mensaje || '</table>';
          w_contador      := 0;
          w_flag_pend     := 0;
          -- Envia correo
          sp_envia_correo_vendedor(wc_mail,
                                   wc_nombre,
                                   wc_vendedor,
                                   wc_jefe,
                                   wc_asunto,
                                   wc_mensaje,
                                   p_auto_env,
                                   p_auto_apro,
                                   p_num_ficha_vta_veh,
                                   p_cod_area_vta,
                                   p_cod_filial,
                                   v_cod_tipo_pago,
                                   p_tipo_ref_proc,
                                   p_cod_usua_sid,
                                   p_cod_usua_web,
                                   p_ret_esta,
                                   p_ret_mens,
                                   p_num_pedido_veh);
          -- Fin Enviar Correo
          wc_mensaje := '';
        END IF;
      END LOOP;
      IF w_flag_ped = 1 AND w_flag_pend = 1 THEN
        w_contador_cont := 1;
        wc_mensaje      := wc_mensaje || '</table>';
        w_contador      := 0;
        w_flag_pend     := 0;
        -- Envia correo
        sp_envia_correo_vendedor(wc_mail,
                                 wc_nombre,
                                 wc_vendedor,
                                 wc_jefe,
                                 wc_asunto,
                                 wc_mensaje,
                                 p_auto_env,
                                 p_auto_apro,
                                 p_num_ficha_vta_veh,
                                 p_cod_area_vta,
                                 p_cod_filial,
                                 v_cod_tipo_pago,
                                 p_tipo_ref_proc,
                                 p_cod_usua_sid,
                                 p_cod_usua_web,
                                 p_ret_esta,
                                 p_ret_mens,
                                 p_num_pedido_veh);
        -- Fin Enviar Correo
        wc_mensaje := '';
      END IF;
    END IF;

    p_ret_esta := 1;
    p_ret_mens := 'Se ha enviado un correo a la persona(s) responsable(s)';

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ENVIA_CORREO_AUTORIZACION',
                                          NULL,
                                          'error al enviar correo',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  PROCEDURE sp_envia_correo_vendedor
  (
    p_mail              IN usuarios.di_correo%TYPE,
    p_nombre            IN VARCHAR2,
    p_vendedor          IN VARCHAR2,
    p_jefe              IN VARCHAR2,
    p_asunto            IN VARCHAR2,
    p_mensaje           IN VARCHAR2,
    p_auto_env          IN VARCHAR2,
    p_auto_apro         IN VARCHAR2,
    p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_cod_area_vta      IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_filial        IN vve_pedido_veh.cod_filial%TYPE,
    p_cod_tipo_pago     IN vve_ficha_vta_veh.cod_tipo_pago%TYPE,
    p_tipo_ref_proc     IN vve_correo_prof.tipo_ref_proc%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE
  ) AS
    wc_mail           usuarios.di_correo%TYPE;
    wc_nombre         VARCHAR2(100);
    wc_vendedor       VARCHAR2(30);
    wc_jefe           VARCHAR2(30);
    wc_asunto         VARCHAR2(100);
    wc_mensaje        VARCHAR2(32500); --<RQ46055> EROZAS /26-11-2013/ Se aumenta la longitud de variable.
    v_dest_vendedores vve_correo_prof.destinatarios%TYPE;
    --<I-86862 Corregir correo por asignación definitiva>
    l_cod_familia_veh vve_proforma_veh_det.cod_familia_veh%TYPE;
    l_cod_marca       vve_proforma_veh_det.cod_marca%TYPE;
    l_cod_filial      vve_proforma_veh.cod_filial%TYPE;
    --<F-86862 Corregir correo por asignación definitiva>
  BEGIN
    wc_mail     := p_mail;
    wc_nombre   := p_nombre;
    wc_vendedor := p_vendedor;
    wc_jefe     := p_jefe;
    --<I-86862 Corregir correo por asignación definitiva>
    wc_asunto := p_asunto;
    IF p_auto_apro = '06' THEN
      wc_asunto := 'ASIGNACION PEDIDO a la Ficha de Venta Nro. ' ||
                   p_num_ficha_vta_veh || ' Pedido:' || p_num_pedido_veh;
    END IF;

    --<I-86862 Corregir correo por asignación definitiva>
    wc_mensaje := p_mensaje;
    ---------------
    ---------------

    --VENDEDOR
    BEGIN
      SELECT a.co_usuario
        INTO wc_vendedor
        FROM cxc.arccve v, cxc.arccve_acceso a
       WHERE v.vendedor = a.vendedor
         AND v.vendedor = p_vendedor
         AND nvl(v.ind_inactivo, 'N') = 'N'
         AND a.ind_crear = 'S'
         AND nvl(a.ind_inactivo, 'N') = 'N';
    EXCEPTION
      WHEN OTHERS THEN
        wc_vendedor := NULL;
    END;
    --JEFE
    wc_jefe := fn_co_usuario_jefe(p_vendedor, p_cod_area_vta, p_cod_filial);
    --DIFERENCIAR EL CODIGO DE VENDEDOR  SI ES DE LICITACIONES DIFERENTE A UN CODIGO DE OFICINA
    -- 1RO DETERMINAR SI USUARIO ES VENDEDOR
    -- 2DO SI ES VENDEDOR DETERMINAR SI TIENE JEFE
    -- 3RO SI TIENE JEFE FILTRAR SOLO A SU JEFES XXX
    --BUSCAR JEFE VENDEDOR EN CASO SEA BUSES
    --BUSCAR SI VENDEDOR TIENE JEFE EN CADA AREA MAS GENERAL
    wc_mail   := NULL;
    wc_nombre := NULL;
    --<I-86862 Corregir correo por asignación definitiva>
    SELECT a.cod_familia_veh, a.cod_marca
      INTO l_cod_familia_veh, l_cod_marca
      FROM vve_pedido_veh a
     WHERE a.num_pedido_veh = p_num_pedido_veh
       AND rownum = 1;

    SELECT c.cod_filial
      INTO l_cod_filial
      FROM vve_ficha_vta_proforma_veh a
     INNER JOIN vve_proforma_veh c
        ON c.num_prof_veh = a.num_prof_veh
     WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh
       AND rownum = 1;
    --<F-86862 Corregir correo por asignación definitiva>

    IF p_auto_env IS NULL THEN
      --CORREO A PARTIR DE VIGENCIA
      --CORREO PARA USUARIOS CON PERMISO DE REALIZAR
      /*
      FOR i IN (SELECT DISTINCT initcap(u.nombre1 || ' ' || u.paterno) nombre,
                                lower(u.di_correo) di_correo
                  FROM usuarios u, arccve_acceso d
                 WHERE u.estado = '001'
                   AND d.co_usuario = u.co_usuario
                   AND d.ind_crear = 'S'
                   AND EXISTS
                 (SELECT 1
                          FROM venta.vve_ficha_vta_veh f
                         WHERE f.num_ficha_vta_veh = p_num_ficha_vta_veh
                           AND f.vendedor = d.vendedor)
                UNION
                SELECT DISTINCT initcap(u.nombre1 || ' ' || u.paterno) nombre,
                                lower(u.di_correo) di_correo
                  FROM usuarios u,
                       usuarios_aut_area_vta r1,
                       usuarios_aut_area_vta_filial r2,
                       usuarios_aut_marca_veh r,
                       (SELECT d.cod_familia_veh, d.cod_marca
                          FROM vve_proforma_veh_det d
                         WHERE d.num_prof_veh IN
                               (SELECT f.num_prof_veh
                                  FROM vve_ficha_vta_proforma_veh f
                                 WHERE f.num_ficha_vta_veh =
                                       p_num_ficha_vta_veh
                                   AND nvl(f.ind_inactivo, 'N') = 'N')
                         GROUP BY d.cod_familia_veh, d.cod_marca) m
                 WHERE u.co_usuario = r.co_usuario
                   AND u.estado = '001'
                   AND r1.co_usuario = u.co_usuario
                   AND r1.cod_area_vta = p_cod_area_vta
                   AND nvl(r1.ind_inactivo, 'N') = 'N'
                   AND r2.co_usuario = r1.co_usuario
                   AND r2.nur_usuario_aut_ficha_vta =
                       r1.nur_usuario_aut_ficha_vta
                   AND r2.nur_usua_aut_area_vta = r1.nur_usua_aut_area_vta
                   AND r2.cod_filial = p_cod_filial
                   AND nvl(r2.ind_inactivo, 'N') = 'N'
                   AND r.co_usuario = r2.co_usuario
                   AND r.nur_usuario_aut_ficha_vta =
                       r2.nur_usuario_aut_ficha_vta
                   AND r.nur_usua_aut_area_vta = r2.nur_usua_aut_area_vta
                   AND r.nur_usua_aut_filial = r2.nur_usua_aut_filial
                   AND nvl(r.ind_inactivo, 'N') = 'N'
                   AND r.cod_area_vta = p_cod_area_vta
                   AND r.cod_filial = p_cod_filial
                   AND r.cod_familia_veh = m.cod_familia_veh
                   AND r.cod_marca = m.cod_marca
                   AND r.cod_aut_ficha_vta = '02'
                   AND nvl(r.ind_recibe_email, 'N') = 'S' ---RQ74365 GMonar 17/10/2014
                UNION
                SELECT DISTINCT initcap(u.nombre1 || ' ' || u.paterno) nombre,
                                lower(u.di_correo) di_correo
                  FROM usuarios u,
                       usuarios_aut_area_vta r1,
                       usuarios_aut_area_vta_filial r2,
                       usuarios_aut_marca_veh r,
                       (SELECT d.cod_familia_veh, d.cod_marca
                          FROM venta.vve_proforma_veh_det d
                         WHERE d.num_prof_veh IN
                               (SELECT f.num_prof_veh
                                  FROM venta.vve_ficha_vta_proforma_veh f
                                 WHERE f.num_ficha_vta_veh =
                                       p_num_ficha_vta_veh
                                   AND nvl(f.ind_inactivo, 'N') = 'N')
                         GROUP BY d.cod_familia_veh, d.cod_marca) m
                 WHERE u.co_usuario = r.co_usuario
                   AND u.estado = '001'
                   AND r1.co_usuario = u.co_usuario
                   AND r1.cod_area_vta = p_cod_area_vta
                   AND nvl(r1.ind_inactivo, 'N') = 'N'
                   AND r2.co_usuario = r1.co_usuario
                   AND r2.nur_usuario_aut_ficha_vta =
                       r1.nur_usuario_aut_ficha_vta
                   AND r2.nur_usua_aut_area_vta = r1.nur_usua_aut_area_vta
                   AND r2.cod_filial = p_cod_filial
                   AND nvl(r2.ind_inactivo, 'N') = 'N'
                   AND r.co_usuario = r2.co_usuario
                   AND r.nur_usuario_aut_ficha_vta =
                       r2.nur_usuario_aut_ficha_vta
                   AND r.nur_usua_aut_area_vta = r2.nur_usua_aut_area_vta
                   AND r.nur_usua_aut_filial = r2.nur_usua_aut_filial
                   AND nvl(r.ind_inactivo, 'N') = 'N'
                   AND r.cod_area_vta = p_cod_area_vta
                   AND r.cod_filial = p_cod_filial
                   AND r.cod_familia_veh = m.cod_familia_veh
                   AND r.cod_marca = m.cod_marca
                   AND r.cod_aut_ficha_vta = p_auto_apro
                   AND (r.cod_aut_ficha_vta IN
                       (SELECT cod_aut_ficha_vta
                           FROM venta.vve_aut_ficha_vta
                          WHERE nvl(ind_inactivo, 'N') = 'N'
                            AND nvl(ind_aut_ped, 'N') = 'S'))
                   AND nvl(r.ind_inactivo, 'N') = 'N'
                   AND nvl(r.ind_recibe_email, 'N') = 'S'
                   AND (nvl(r.ind_licit, 'N') = 'N' OR
                       (p_vendedor = '07' AND r.ind_licit = 'S'))
                   AND -- Valida el envío a usuarios de licitaciones
                       (nvl(r.ind_cred, 'N') = 'N' OR
                       (p_cod_tipo_pago = 'P' AND
                       nvl(r.ind_cred, 'N') = 'S')) -- valida el envío a usuarios de créditos
                )*/
      --<I-86862 Corregir correo por asignación definitiva>
      FOR i IN (
                --Seleccionamos a los jefes de venta
                SELECT DISTINCT a.txt_correo di_correo
                  FROM sistemas.sis_mae_usuario a
                 INNER JOIN sistemas.sis_mae_perfil_usuario b
                    ON a.cod_id_usuario = b.cod_id_usuario
                   AND b.ind_inactivo = 'N'
                 INNER JOIN sistemas.sis_mae_perfil_procesos c
                    ON b.cod_id_perfil = c.cod_id_perfil
                   AND c.ind_inactivo = 'N'
                 INNER JOIN sistemas.sis_view_usua_marca d
                    ON a.cod_id_usuario = d.cod_id_usuario
                 INNER JOIN sis_view_usua_filial uf
                    ON uf.cod_filial = l_cod_filial
                   AND uf.cod_id_usuario = a.cod_id_usuario
                 WHERE c.cod_id_procesos = 70
                   AND c.ind_recibe_correo = 'S'
                   AND d.cod_area_vta = p_cod_area_vta
                   AND d.cod_familia_veh = l_cod_familia_veh
                   AND d.cod_marca = l_cod_marca
                   AND c.ind_inactivo = 'N'
                   AND txt_correo IS NOT NULL
                UNION
                SELECT DISTINCT u.txt_correo
                  FROM sis_mae_usuario u
                 WHERE u.cod_id_usuario = p_cod_usua_web
                UNION
                SELECT DISTINCT c.txt_correo
                  FROM vve_ficha_vta_proforma_veh a
                 INNER JOIN vve_proforma_veh b
                    ON a.num_prof_veh = b.num_prof_veh
                 INNER JOIN sis_mae_usuario c
                    ON b.co_usuario_crea_reg = c.txt_usuario
                 WHERE a.num_ficha_vta_veh = p_num_ficha_vta_veh)
      --<F-86862 Corregir correo por asignación definitiva>
      LOOP
        IF i.di_correo IS NOT NULL THEN
          v_dest_vendedores := i.di_correo || ',' || v_dest_vendedores;
        END IF;
      END LOOP;
    ELSE
      FOR i IN (SELECT DISTINCT u.co_usuario, u.di_correo
                  FROM usuarios u,
                       usuarios_aut_area_vta r1,
                       usuarios_aut_area_vta_filial r2,
                       usuarios_aut_marca_veh r,
                       (SELECT d.cod_familia_veh, d.cod_marca
                          FROM venta.vve_proforma_veh_det d
                         WHERE d.num_prof_veh IN
                               (SELECT f.num_prof_veh
                                  FROM venta.vve_ficha_vta_proforma_veh f
                                 WHERE f.num_ficha_vta_veh =
                                       p_num_ficha_vta_veh
                                   AND nvl(f.ind_inactivo, 'N') = 'N')
                         GROUP BY d.cod_familia_veh, d.cod_marca) m
                 WHERE u.estado = '001'
                   AND r1.co_usuario = u.co_usuario
                   AND r1.cod_area_vta = p_cod_area_vta
                   AND nvl(r1.ind_inactivo, 'N') = 'N'
                   AND r2.co_usuario = r1.co_usuario
                   AND r2.nur_usuario_aut_ficha_vta =
                       r1.nur_usuario_aut_ficha_vta
                   AND r2.nur_usua_aut_area_vta = r1.nur_usua_aut_area_vta
                   AND r2.cod_filial = p_cod_filial
                   AND nvl(r2.ind_inactivo, 'N') = 'N'
                   AND r.co_usuario = r2.co_usuario
                   AND r.nur_usuario_aut_ficha_vta =
                       r2.nur_usuario_aut_ficha_vta
                   AND r.nur_usua_aut_area_vta = r2.nur_usua_aut_area_vta
                   AND r.nur_usua_aut_filial = r2.nur_usua_aut_filial
                   AND nvl(r.ind_inactivo, 'N') = 'N'
                   AND ((r.cod_aut_ficha_vta != '01' AND
                       u.co_usuario =
                       decode(r.cod_aut_ficha_vta,
                                '02',
                                decode(wc_jefe, NULL, u.co_usuario, wc_jefe),
                                '03',
                                decode(wc_jefe, NULL, u.co_usuario, wc_jefe),
                                u.co_usuario)) OR
                       (r.cod_aut_ficha_vta = '01' AND
                       u.co_usuario IN
                       (SELECT a.co_usuario
                            FROM cxc.arccve v, cxc.arccve_acceso a
                           WHERE v.vendedor = a.vendedor
                             AND v.vendedor = p_vendedor
                             AND nvl(v.ind_inactivo, 'N') = 'N'
                             AND a.ind_crear = 'S'
                             AND nvl(a.ind_inactivo, 'N') = 'N')))
                   AND r.cod_marca = m.cod_marca
                   AND r.cod_familia_veh = m.cod_familia_veh
                   AND r.cod_aut_ficha_vta IN
                       (p_auto_env, '01', p_auto_apro)
                      -- RQ 55364  02/04/2014
                      -- Solo debe validar que el usuario tenga el permiso de recepcion de
                      -- correo NVL(R.IND_RECIBE_EMAIL,'N')='S'
                   AND nvl(r.ind_inactivo, 'N') = 'N'
                   AND nvl(r.ind_recibe_email, 'N') = 'S')
      LOOP
        BEGIN
          SELECT lower(di_correo), initcap(nombre1 || ' ' || paterno)
            INTO wc_mail, wc_nombre
            FROM usuarios
           WHERE co_usuario = i.co_usuario;
        EXCEPTION
          WHEN no_data_found THEN
            NULL;
        END;
        IF wc_mail IS NOT NULL AND wc_nombre IS NOT NULL THEN
          v_dest_vendedores := wc_mail || ',' || v_dest_vendedores;
        END IF;
      END LOOP;
    END IF;
    -- <I 82332> NCeron/02-Ago-2016/
    wc_mensaje := '<table cellpadding=10 width=100% style="clear:both; margin:0.5em auto; border:2px solid #E5D4A1;font: 8pt Arial;"><tr><td>' ||
                  wc_mensaje || '</td></tr></table>';
    wc_mensaje := wc_mensaje ||
                  '<br><br><font style="FONT: 8pt arial" color="FF0000">NOTA: Este mensaje ha sido autogenerado por el Sistema.</font><BR>';

    pkg_sweb_five_mant.sp_inse_correo_fv(p_num_ficha_vta_veh ||
                                         p_num_pedido_veh || 'AD', --  P_COD_REF_PROC,
                                         v_dest_vendedores,
                                         NULL,
                                         wc_asunto,
                                         wc_mensaje,
                                         wc_mail,
                                         p_cod_usua_sid,
                                         p_cod_usua_web,
                                         p_tipo_ref_proc,
                                         p_ret_esta,
                                         p_ret_mens);
    -- <F 82332>

    p_ret_esta := 1;
    p_ret_mens := 'Se ha enviado un correo a la persona(s) responsable(s)';

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ENVIA_CORREO_VENDEDOR',
                                          NULL,
                                          'error al enviar correo',
                                          p_ret_mens,
                                          p_num_ficha_vta_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : sp_mantenimiento_hist
      Proposito : Movimiento de pedidos, numero de documento y ventas,historial del pedido
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      15/03/2018   LAQS         Creacion
      12/02/2020 SOPORTELEGADOS  Req: 86111
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_mantenimiento_hist
  (
    p_num_ficha_vta_veh IN VARCHAR2,
    p_num_pedido_veh    IN VARCHAR2,
    p_cod_cia           IN VARCHAR2,
    p_cod_prov          IN VARCHAR2,
    p_tipodocumento     IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_cursor_mov        OUT SYS_REFCURSOR,
    p_cursor_doc        OUT SYS_REFCURSOR,
    p_cursor_hist       OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS

    v_query VARCHAR2(20000);
    v_where VARCHAR2(20000);

  BEGIN

    -- Movimientos
    v_query := 'SELECT cod_cia,
             COD_TIPO_DOCU,
             Num_DOCU,
             VAL_MONTO,
             FEC_DOCU,
             NUM_REG_PAGO_PEDIDO,
             COD_MONEDA,
             cod_prov,
             num_pedido_veh,
             cod_clie,
             VAL_TIPO_CAMBIO,
             (SELECT SALDO FROM ARCCMD
              WHERE NO_CIA = A.COD_CIA
                    AND TIPO_DOC = A.COD_TIPO_DOCU
                    AND NO_DOCU = A.NUM_DOCU
                    AND NO_CLIENTE = A.COD_CLIE) SALDO
        FROM venta.vve_pedido_veh_pagos a
       WHERE (cod_cia = ''' || p_cod_cia || ''')
         and (cod_prov = ''' || p_cod_prov || ''')
         and (num_pedido_veh = ''' || p_num_pedido_veh ||
               ''')';

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_mantenimiento_hist',
                                        NULL,
                                        'error pedido',
                                        v_query,
                                        'MOVIMIENTOS');

    OPEN p_cursor_mov FOR v_query;

    v_query := 'SELECT
             A.TIPO_DOC,
             A.NO_FACTU,
             A.CENTRO,
             A.BODEGA,
             A.FECHA,
             A.GRUPO,
             A.NO_CLIENTE,
             A.NBR_CLIENTE,
             A.NO_VENDEDOR,
             A.TIPO_PRECIO,
             A.MONEDA,
             A.TIPO_CAMBIO,
             A.NU_PROVE,
             A.NO_ORDEN_DESC,
             A.DESCUENTO,
             A.SUB_TOTAL,
             A.IMPUESTO,
             A.val_pre_docu,
             pkg_sweb_mae_gene.fu_desc_maes(80,A.ESTADO) ESTADO,
             A.RUC,
             A.IND_ANU_DEV,
             A.P_IGV,
             A.P_ISC,
             A.IMP_ISC,
             pkg_sweb_mae_gene.fu_desc_maes(81, A.TI_FACTURA) TI_FACTURA,
             A.ANO,
             A.MES,
             pkg_sweb_mae_gene.fu_desc_maes(82, A.PARCIAL)  PARCIAL,
             A.DOC_DEVOL,
             A.NO_DEVOL,
             A.TIPO_PAGO,
             A.COD_FILIAL,
             --<I-86111>
             T.cod_sunat tipo_sunat,
             C.ruc ruc_emisor
             --<F-86111>
        FROM VENTA.ARFAFE A ,
             VVE_FICHA_VTA_PEDIDO_VEH VFVPH,
             --<I-86111>
             arcctd T,
             arcgmc C
             --<F-86111>
        WHERE
        A.NO_CIA = VFVPH.COD_CIA(+)
        AND A.NU_PROVE  = VFVPH.COD_PROV(+)
        AND A.NO_ORDEN_DESC  = VFVPH.NUM_PEDIDO_VEH(+)
        AND VFVPH.IND_INACTIVO = ''N''
        --<I-86111>
        AND T.tipo   = A.tipo_doc
        AND T.no_cia = A.no_cia
        AND( (T.grupo_doc in (''F'',''B'') ) or (T.grupo_doc=''R'' and A.tipo_nc =''D'') )
        AND C.no_cia = A.no_cia
        --<F-86111>
        ';
    IF p_cod_cia <> '' OR p_cod_cia IS NOT NULL THEN
      v_where := v_where || 'AND A.NO_CIA = ''' || p_cod_cia || '''';
    END IF;

    IF p_cod_prov <> '' OR p_cod_prov IS NOT NULL THEN
      v_where := v_where || 'AND A.NU_PROVE = ''' || p_cod_prov || '''';
    END IF;

    IF p_num_pedido_veh <> '' OR p_num_pedido_veh IS NOT NULL THEN
      v_where := v_where || 'AND A.NO_ORDEN_DESC = ''' || p_num_pedido_veh || '''';
    END IF;

    IF p_num_ficha_vta_veh <> '' OR p_num_ficha_vta_veh IS NOT NULL THEN
      v_where := v_where || 'AND VFVPH.NUM_FICHA_VTA_VEH = ''' ||
                 p_num_ficha_vta_veh || ''' ';
    END IF;

    v_query := v_query || v_where;
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_mantenimiento_hist',
                                        NULL,
                                        'error pedido',
                                        v_query,
                                        'DOCUMENTO');
    -- Documentos de venta
    OPEN p_cursor_doc FOR v_query;

    -- Historial
    OPEN p_cursor_hist FOR
      SELECT cod_cia,
             num_estado_canc,
             cod_prov,
             num_pedido_veh,
             ind_inactivo,
             fec_mod_reg,
             cod_usuario_mod_reg,
             cod_estado_cancelacion_ped,
             cod_usuario_crea_reg,
             observacion,
             fec_crea_reg
        FROM vve_pedido_veh_estado_canc
       WHERE (cod_cia = p_cod_cia)
         AND (cod_prov = p_cod_prov)
         AND (num_pedido_veh = p_num_pedido_veh)
      --and (COD_USUARIO_CREA_REG = p_cod_usua_sid)
       ORDER BY fec_crea_reg DESC;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_cursor_mov;
      CLOSE p_cursor_doc;
      CLOSE p_cursor_hist;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_mantenimiento_hist',
                                          NULL,
                                          'error pedido',
                                          p_ret_mens,
                                          p_num_pedido_veh);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : sp_lista_areaVenta
      Proposito : lista de areas
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      03/03/2018   LAQS         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_lista_areaventa
  (
    p_cod_chek     VARCHAR2,
    p_cod_area_vta VARCHAR2,
    p_ret_cursor   OUT SYS_REFCURSOR,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR
  ) AS

    y_query VARCHAR(10000);
    y_where VARCHAR(100);

  BEGIN

    y_query := '
    SELECT MCA.cod_chek,
             MC.des_chek,
             MCA.cod_area_vta,
             (SELECT des_area_vta
                FROM GENERICO.GEN_AREA_VTA GG
               WHERE GG.COD_AREA_VTA = MCA.cod_area_vta) des_area_vta,
             MCA.fec_crea_reg,
             MCA.ind_inactivo,
             MCA.ind_default
        FROM VVE_MANT_CHEK MC
        LEFT JOIN VVE_MANT_CHEK_AVTA MCA
          ON MC.COD_CHEK = MCA.COD_CHEK
          WHERE 1=1
    ';

    IF p_cod_chek IS NOT NULL THEN
      y_where := ' AND  MCA.cod_chek = ''' || p_cod_chek || '''';
    END IF;

    IF p_cod_area_vta IS NOT NULL THEN
      y_where := y_where || ' AND  MCA.cod_area_vta = ''' || p_cod_area_vta || '''';
    END IF;

    y_query := y_query || y_where;

    OPEN p_ret_cursor FOR y_query;

    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'sp_lista_areaVenta',
                                        NULL,
                                        'error ',
                                        y_query,
                                        p_cod_chek);

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_lista_areaVenta',
                                          NULL,
                                          'error ',
                                          p_ret_mens,
                                          p_cod_chek);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : sp_lista_areas
      Proposito : lista de areas
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      03/03/2018   LAQS         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_lista_areas
  (
    p_cod_chek   VARCHAR2,
    p_ret_cursor OUT SYS_REFCURSOR,
    p_ret_esta   OUT NUMBER,
    p_ret_mens   OUT VARCHAR
  ) AS

  BEGIN

    OPEN p_ret_cursor FOR
      SELECT a.cod_area_vta, a.des_area_vta, b.cod_chek, b.ind_default
        FROM gen_area_vta a
        LEFT JOIN vve_mant_chek_avta b
          ON a.cod_area_vta = b.cod_area_vta
         AND b.cod_chek = p_cod_chek
       WHERE a.negocio_ventas = 'S';

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_lista_areaVenta',
                                          NULL,
                                          'error ',
                                          p_ret_mens,
                                          p_cod_chek);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : sp_lista_areas
      Proposito : lista de areas
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      03/03/2018   LAQS         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_inserupdate_areas
  (
    p_cod_chek     VARCHAR2,
    p_cod_area_vta VARCHAR2,
    p_ind_inactivo VARCHAR2,
    p_ind_default  VARCHAR2,
    p_cod_usua_sid IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta     OUT NUMBER,
    p_ret_mens     OUT VARCHAR
  ) IS
    v_exists NUMBER;

  BEGIN

    SELECT COUNT(*)
      INTO v_exists
      FROM vve_mant_chek_avta t
     WHERE t.cod_chek = p_cod_chek
       AND t.cod_area_vta = p_cod_area_vta;

    IF v_exists = '0' THEN

      INSERT INTO vve_mant_chek_avta
        (cod_chek,
         cod_area_vta,
         ind_inactivo,
         fec_crea_reg,
         cod_usuario_crea,
         ind_default)
      VALUES
        (p_cod_chek,
         p_cod_area_vta,
         p_ind_inactivo,
         SYSDATE,
         p_cod_usua_sid,
         p_ind_default);
    ELSE
      UPDATE vve_mant_chek_avta
         SET cod_chek         = p_cod_chek,
             cod_area_vta     = p_cod_area_vta,
             ind_inactivo     = p_ind_inactivo,
             fec_modi_reg     = SYSDATE,
             cod_usuario_modi = p_cod_usua_sid,
             ind_default      = p_ind_default
       WHERE cod_chek = p_cod_chek
         AND cod_area_vta = p_cod_area_vta;
    END IF;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_inserUpdate_areas',
                                          NULL,
                                          'error ',
                                          p_ret_mens,
                                          p_cod_chek);
  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_HIS_FECHA_COMPROMISO
      Proposito : historial de fecha de compromiso
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      03/03/2018   LAQS         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_his_fecha_compromiso
  (
    p_num_ficha_vta_veh     IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
    p_nur_aut_ficha_vta_veh IN VARCHAR2,
    p_cod_usua_sid          IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web          IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_tipo_uno              IN VARCHAR2,
    p_tipo_dos              IN VARCHAR2,
    p_num_pedido_veh        IN VARCHAR2,
    p_cod_cia               IN VARCHAR2,
    p_cod_prov              IN VARCHAR2,
    p_ret_cursor            OUT SYS_REFCURSOR,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR
  ) AS
    v_nur_aut_ficha_vta_veh NUMBER;
    v_cod_aut_ficha_vta     vve_ficha_vta_veh_aut.cod_aut_ficha_vta%TYPE;
  BEGIN
    pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                        'SP_HIS_FECHA_COMPROMISO',
                                        NULL,
                                        'datos=>' || p_num_pedido_veh || '-' ||
                                        p_cod_prov || ';' || p_tipo_dos || ',' ||
                                        p_tipo_uno,
                                        p_ret_mens,
                                        NULL);

    IF p_tipo_uno = 'FCC' THEN
      v_cod_aut_ficha_vta := '11'; --compromiso comercial
    ELSIF p_tipo_uno = 'FCK' THEN
      v_cod_aut_ficha_vta := '14'; --compromiso karrocero
    ELSIF p_tipo_uno = 'FCL' THEN
      v_cod_aut_ficha_vta := '15'; --compromiso logistico
    END IF;

    BEGIN
      SELECT t.nur_aut_ficha_vta_veh
        INTO v_nur_aut_ficha_vta_veh
        FROM vve_ficha_vta_veh_aut t
       WHERE t.num_ficha_vta_veh = p_num_ficha_vta_veh
         AND t.num_pedido_veh = p_num_pedido_veh
            --AND t.cod_prov       = p_cod_prov
         AND nvl(t.ind_inactivo, 'N') = 'N'
         AND cod_aut_ficha_vta = v_cod_aut_ficha_vta;
    EXCEPTION
      WHEN OTHERS THEN
        v_nur_aut_ficha_vta_veh := NULL;
    END;

    OPEN p_ret_cursor FOR
      SELECT fecha_compromiso,
             cod_motivo,
             des_motivo,
             observacion,
             co_usuario_crea_reg,
             fec_crea_reg,
             co_usuario_autoriza,
             fec_autoriza,
             des_estado,
             des_motivo_rechazo,
             tipo_fec_compromiso
        FROM (SELECT hfc.fecha_compromiso,
                     hfc.cod_motivo,
                     mr.des_nombre AS des_motivo,
                     hfc.observacion,
                     hfc.co_usuario_crea_reg,
                     hfc.fec_crea_reg,
                     hfc.co_usuario_autoriza,
                     hfc.fec_autoriza,
                     pkg_gen_select.func_descri_lval_det('00',
                                                         'ESTADOFR',
                                                         hfc.ind_estado) AS des_estado,
                     hfc.des_motivo_rechazo,
                     hfc.tipo_fec_compromiso,
                     hfc.nur_fec_compromiso
                FROM vve_his_fecha_compromiso hfc,
                     vve_motivo_renegociacion mr
               WHERE hfc.cod_motivo = mr.cod_motivo(+)
                 AND hfc.num_ficha_vta_veh = p_num_ficha_vta_veh
                 AND hfc.ind_estado IN ('A', 'EP')
                 AND tipo_fec_compromiso = p_tipo_dos
                 AND hfc.nur_aut_ficha_vta_veh = v_nur_aut_ficha_vta_veh
              --and (tipo_fec_compromiso = P_TIPO_UNO  or tipo_fec_compromiso = P_TIPO_DOS)
              UNION ALL
              SELECT x.fec_compromiso,
                     NULL cod_motivo,
                     'FECHA INICIAL' des_motivo,
                     NULL observacion,
                     NULL co_usuario_crea_reg,
                     NULL fec_crea_reg,
                     NULL co_usuario_autoriza,
                     NULL fec_autoriza,
                     NULL des_estado,
                     NULL des_motivo_rechazo,
                     p_tipo_uno tipo_fec_compromiso,
                     0 nur_fec_compromiso
                FROM vve_ficha_vta_veh_aut x
               WHERE x.num_ficha_vta_veh = p_num_ficha_vta_veh
                 AND x.nur_aut_ficha_vta_veh = v_nur_aut_ficha_vta_veh
                 AND x.cod_aut_ficha_vta = v_cod_aut_ficha_vta
                 AND nvl(x.ind_inactivo, 'N') = 'N'
               ORDER BY nur_fec_compromiso DESC);

    p_ret_esta := 1;
    p_ret_mens := 'Consulta exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      CLOSE p_ret_cursor;
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ENVIA_CORREO_VENDEDOR',
                                          NULL,
                                          'error al enviar correo',
                                          p_ret_mens,
                                          p_nur_aut_ficha_vta_veh);
  END;

  FUNCTION fn_co_usuario_jefe
  (
    p_vendedor     IN VARCHAR2,
    p_cod_area_vta IN vve_pedido_veh.cod_area_vta%TYPE,
    p_cod_filial   IN vve_pedido_veh.cod_filial%TYPE
  ) RETURN VARCHAR2 IS
    wc_co_usuario_jefe VARCHAR2(30);
  BEGIN
    SELECT co_usuario_jefe
      INTO wc_co_usuario_jefe
      FROM cxc.arccve_area_vta_filial
     WHERE cod_area_vta = p_cod_area_vta
       AND cod_filial = p_cod_filial
       AND co_usuario_jefe IS NOT NULL
       AND vendedor = p_vendedor --'32'
       AND nvl(ind_inactivo, 'N') = 'N';

    RETURN wc_co_usuario_jefe;
  EXCEPTION
    WHEN no_data_found THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION fn_fecha_compromiso(p_proforma IN VARCHAR2) RETURN DATE IS
    v_fec_regi          DATE;
    p_cant_inicial_dias NUMBER := 1;
    p_cant_final_dias   NUMBER;
    wd_fecha            DATE;
    wn_cant             NUMBER;
    wn_dias_no_lab      NUMBER;
  BEGIN
    /*
    SELECT fec_regi
      INTO wd_fecha
      FROM (SELECT fec_regi, num_prof
              FROM vve_prof_hist_proc
             WHERE num_prof = p_proforma
             ORDER BY fec_regi DESC)
     WHERE rownum = 1;*/
    wd_fecha := trunc(SYSDATE);

    SELECT num_dias_est_entrega
      INTO p_cant_final_dias
      FROM vve_proforma_veh vpv
     WHERE vpv.num_prof_veh = p_proforma;
    ---------------------------------------------------------------------
    --DIA INICIAL
    wd_fecha := wd_fecha - 1;
    ---------------------------------------------------------------------
    --VALIDAR DIAS FERIADOS
    WHILE (p_cant_inicial_dias <= p_cant_final_dias)
    LOOP

      wd_fecha := wd_fecha + 1;

      BEGIN
        SELECT SUM(cant)
          INTO wn_dias_no_lab
          FROM ((SELECT COUNT(1) cant
                   FROM gen_fec_no_calendario
                  WHERE to_date(fec_no_lab, 'DD/MM/YY') =
                        to_date(wd_fecha, 'DD/MM/YY')
                    AND nvl(ind_inactivo, 'N') = 'N') UNION
                (SELECT COUNT(*) cant
                   FROM arlcfr
                  WHERE dia || mes = to_char(wd_fecha, 'DDMM')));
      END;
      ---------------------------------------------------------------------
      --CONTADOR DEL BUCLE DE ACUERDO AL TIPO DE DIA
      IF nvl(wn_dias_no_lab, 0) > 0 OR
         to_number(to_char(wd_fecha, 'D')) IN (1, 7) THEN
        NULL;
      ELSE

        p_cant_inicial_dias := p_cant_inicial_dias + 1;
      END IF;

    END LOOP;

    RETURN wd_fecha;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  /*-----------------------------------------------------------------------------
      Nombre : FN_IND_DESADUANAJE
      Proposito : Retorna el indice de envio de correo
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      20/03/2018   ARAMOS         Creacion
    28/08/2018   SOPORTELEGADOS REQ-86366 Se modificó la lógica para una nueva validación y asignación de valor a la variable wn_ind_desaduanaje.
                  Toma el valor 2, cuando la proforma tenga como clausala de compra = 005.
  ----------------------------------------------------------------------------*/

  FUNCTION fn_ind_desaduanaje
  (
    p_cod_cia        IN vve_pedido_veh.cod_cia%TYPE,
    p_cod_prov       IN vve_pedido_veh.cod_prov%TYPE,
    p_num_pedido_veh IN vve_pedido_veh.num_pedido_veh%TYPE
  ) RETURN NUMBER IS
    wn_cont_situ06     NUMBER;
    wn_cont_situ12     NUMBER;
    wn_cont_situ14     NUMBER;
    wn_cont_situ22     NUMBER;
    wn_ind_desaduanaje NUMBER;
    vtipo_cia          VARCHAR2(2);
    --<REQ-86366>
    wn_cod_clausula_compra vve_clausula_compra.cod_clausula_compra%TYPE;
    --<REQ-86366>
  BEGIN
    wn_ind_desaduanaje := 0;

    BEGIN
      SELECT c.tipo_cia
        INTO vtipo_cia
        FROM arfamc c
       WHERE c.no_cia = p_cod_cia;
    EXCEPTION
      WHEN no_data_found THEN
        vtipo_cia := '02';
    END;
    --<F 84772>
    IF vtipo_cia = '01' THEN
      BEGIN
        SELECT COUNT(1)
          INTO wn_cont_situ06
          FROM vve_pedido_veh_situ s
         WHERE s.cod_cia = p_cod_cia
           AND s.cod_prov = p_cod_prov
           AND s.num_pedido_veh = p_num_pedido_veh
           AND nvl(s.ind_anulado, 'N') = 'N'
           AND s.cod_situ_pedido = '06';
      EXCEPTION
        WHEN OTHERS THEN
          wn_cont_situ06 := 0;
      END;

      BEGIN
        SELECT COUNT(1)
          INTO wn_cont_situ12
          FROM vve_pedido_veh_situ s
         WHERE s.cod_cia = p_cod_cia
           AND s.cod_prov = p_cod_prov
           AND s.num_pedido_veh = p_num_pedido_veh
           AND nvl(s.ind_anulado, 'N') = 'N'
           AND s.cod_situ_pedido = '12';
      EXCEPTION
        WHEN OTHERS THEN
          wn_cont_situ12 := 0;
      END;

      BEGIN
        SELECT COUNT(1)
          INTO wn_cont_situ14
          FROM vve_pedido_veh_situ s
         WHERE s.cod_cia = p_cod_cia
           AND s.cod_prov = p_cod_prov
           AND s.num_pedido_veh = p_num_pedido_veh
           AND nvl(s.ind_anulado, 'N') = 'N'
           AND s.cod_situ_pedido = '14';
      EXCEPTION
        WHEN OTHERS THEN
          wn_cont_situ14 := 0;
      END;

      BEGIN
        SELECT COUNT(1)
          INTO wn_cont_situ22
          FROM vve_pedido_veh_situ s
         WHERE s.cod_cia = p_cod_cia
           AND s.cod_prov = p_cod_prov
           AND s.num_pedido_veh = p_num_pedido_veh
           AND nvl(s.ind_anulado, 'N') = 'N'
           AND s.cod_situ_pedido IN ('22', '24');

      EXCEPTION
        WHEN OTHERS THEN
          wn_cont_situ22 := 0;
      END;

      IF wn_cont_situ06 = 0 AND wn_cont_situ22 = 0 AND wn_cont_situ14 = 0 AND
         wn_cont_situ12 > 0 THEN

        wn_ind_desaduanaje := 1;

        --<REQ-86366>
        BEGIN
          SELECT DISTINCT pv.cod_clausula_compra
            INTO wn_cod_clausula_compra
            FROM vve_ficha_vta_pedido_veh vpv, vve_proforma_veh pv
           WHERE pv.num_prof_veh = vpv.num_prof_veh
             AND vpv.cod_cia = p_cod_cia
             AND vpv.cod_prov = p_cod_prov
             AND vpv.num_pedido_veh = p_num_pedido_veh
             AND nvl(vpv.ind_inactivo, 'N') = 'N';
          --AND PV.COD_CLAUSULA_COMPRA = '005';
        EXCEPTION
          WHEN no_data_found THEN
            wn_cod_clausula_compra := NULL;
        END;

        IF wn_cod_clausula_compra = '005' THEN
          wn_ind_desaduanaje := 2;
        END IF;
        --<REQ-86366>

      END IF;
    END IF;

    RETURN wn_ind_desaduanaje;

  END;

  /*-----------------------------------------------------------------------------
      Nombre : SP_GRABAR_VVE_SOLI_FACT_CONT
      Proposito : Graba los contactos de Solicitud de Facturacions
      Referencias :
      Parametros :
      Log de Cambios
      Fecha        Autor         Descripcion
      13/04/2018   ARAMOS         Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_grabar_vve_soli_fact_cont
  (
    p_txt_nombre         IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_txt_correo         IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_cod_soli_fact_vehi IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_cod_usuario_crea   IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR

  ) AS

    v_cod_soli_fact_cont NUMBER;

  BEGIN

    SELECT nvl(MAX(cod_soli_fact_cont), 0) + 1
      INTO v_cod_soli_fact_cont
      FROM vve_soli_fact_cont;

    INSERT INTO vve_soli_fact_cont
    VALUES
      (v_cod_soli_fact_cont,
       p_txt_nombre,
       p_txt_correo,
       p_cod_soli_fact_vehi,
       'N',
       SYSDATE,
       p_cod_usuario_crea,
       NULL,
       NULL);

    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'CONSULTA EXITOSA';
  EXCEPTION
    WHEN OTHERS THEN

      p_ret_esta := -1;
      p_ret_mens := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_GRABAR_VVE_SOLI_FACT_CONT',
                                          p_cod_usuario_crea,
                                          'ERROR AL GRABAR LOS CONTACTOS DE SOLICITUD DE FAC.',
                                          p_ret_mens,
                                          p_cod_soli_fact_vehi);
  END;

  /*--------------------------------------------------------------------------
    Nombre : SP_REG_PEDIDO_VEH_SITU
    Proposito : Registro de situacion del vehiculo
    Referencias :
    Parametros :
    Log de Cambios
      Fecha        Autor         Descripcion
      18/04/2018   PHRAMIREZ     Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_reg_pedido_veh_situ
  (
    p_cod_cia          IN vve_pedido_veh_situ.cod_cia%TYPE,
    p_cod_prov         IN vve_pedido_veh_situ.cod_prov%TYPE,
    p_num_pedido_veh   IN vve_pedido_veh_situ.num_pedido_veh%TYPE,
    p_cod_situ_pedido  IN vve_pedido_veh_situ.cod_situ_pedido%TYPE,
    p_fec_situ_pedido  IN vve_pedido_veh_situ.fec_situ_pedido%TYPE,
    p_cod_tipo_docu    IN vve_pedido_veh_situ.cod_tipo_docu%TYPE,
    p_num_docu         IN vve_pedido_veh_situ.num_docu%TYPE,
    p_obs_situ_pedido  IN vve_pedido_veh_situ.obs_situ_pedido%TYPE,
    p_cod_usuario_crea IN vve_soli_fact_cont.txt_nombre%TYPE,
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR
  ) AS
    wc_num_reg_pedido_situ vve_pedido_veh_situ.num_reg_pedido_situ%TYPE;
  BEGIN
    SELECT ltrim(rtrim(to_char(to_number(nvl(MAX(num_reg_pedido_situ), 0)) + 1,
                               '009')))
      INTO wc_num_reg_pedido_situ
      FROM vve_pedido_veh_situ
     WHERE cod_cia = p_cod_cia
       AND cod_prov = p_cod_prov
       AND num_pedido_veh = p_num_pedido_veh;
    BEGIN
      INSERT INTO vve_pedido_veh_situ
        (cod_cia,
         cod_prov,
         num_pedido_veh,
         num_reg_pedido_situ,
         cod_situ_pedido,
         fec_situ_pedido,
         obs_situ_pedido,
         co_usuario_crea_reg,
         fec_crea_reg,
         cod_tipo_docu,
         num_docu)
      VALUES
        (p_cod_cia,
         p_cod_prov,
         p_num_pedido_veh,
         wc_num_reg_pedido_situ,
         p_cod_situ_pedido,
         p_fec_situ_pedido,
         p_obs_situ_pedido,
         p_cod_usuario_crea,
         SYSDATE,
         p_cod_tipo_docu,
         p_num_docu);

      p_ret_esta := 1;
      p_ret_mens := 'Se registro correctamente';
    EXCEPTION
      WHEN too_many_rows THEN
        p_ret_esta := -1;
        p_ret_mens := SQLERRM;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_REG_PEDIDO_VEH_SITU',
                                            p_cod_usuario_crea,
                                            'Error al insertar en la tabla vve_pedido_veh_situ indica reg. ya existe',
                                            p_ret_mens,
                                            p_num_pedido_veh);
    END;
  END;

  /*-----------------------------------------------------------------------------------------------------
    Nombre : sp_mail_alert_jefeventas
    Proposito : Enviar alertas a los Jefes de Venta
    Referencias :
    Parametros :
    Log de Cambios
    Fecha        Autor              Descripcion
    24/11/2019   SOPORTELEGADOS     Creacion
  -------------------------------------------------------------------------------------------------------*/
  PROCEDURE sp_mail_alert_jefeventas(p_num_ficha_vta_veh IN vve_ficha_vta_veh.num_ficha_vta_veh%TYPE,
                                       p_num_prof_veh      IN vve_proforma_veh.num_prof_veh%TYPE,
                                       p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
                                       p_co_usuario        IN sistemas.usuarios.co_usuario%TYPE,
                                       p_cod_id_usuario    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
                                       p_ret_esta          OUT NUMBER,
                                       p_ret_mens          OUT VARCHAR2) AS
    ve_error               EXCEPTION;
    p_nom_usuario          sistemas.sis_mae_usuario.txt_nombres%TYPE;
    v_cod_area_vta         VARCHAR2(50);
    v_cod_familia_veh      INTEGER;
    v_cod_filial           VARCHAR2(50);
    v_cod_marca            VARCHAR2(50);
    v_destinatarios        vve_correo_prof.destinatarios%TYPE;
    v_nombre_destinatarios VARCHAR2(4000);
    l_txt_corr_usu         VARCHAR2(50);
    wc_asunto              VARCHAR2(100);
    wc_mensaje             VARCHAR2(32767);
    wc_titulo              VARCHAR2(100);

  --Lista de usuarios notificados
      CURSOR lista_usuarios_notificacion IS
        SELECT AM.DI_CORREO,PATERNO || ' ' || MATERNO || ' ' || NOMBRE1 || ' ' || NOMBRE2 AS NOMBRE
          FROM USUARIOS                     AM,
               USUARIOS_ROL_USUARIO         AX,
               USUARIOS_ROL_AREA_VTA        AY,
               USUARIOS_ROL_AREA_VTA_FILIAL AZ,
               USUARIOS_ROL_FAMILIA_VEH     AW,
               USUARIOS_ROL_MARCA_VEH       AV
         WHERE AM.CO_USUARIO = AX.CO_USUARIO
           AND AX.CO_USUARIO = AY.CO_USUARIO
           AND AX.NUR_USUARIO_ROL_USUARIO = AY.NUR_USUARIO_ROL_USUARIO
           AND AY.CO_USUARIO = AZ.CO_USUARIO
           AND AY.NUR_USUARIO_ROL_USUARIO = AZ.NUR_USUARIO_ROL_USUARIO
           AND AY.NUR_USUA_ROL_AREA_VTA = AZ.NUR_USUA_ROL_AREA_VTA
           AND AZ.CO_USUARIO = AW.CO_USUARIO
           AND AZ.NUR_USUARIO_ROL_USUARIO = AW.NUR_USUARIO_ROL_USUARIO
           AND AZ.NUR_USUA_ROL_AREA_VTA = AW.NUR_USUA_ROL_AREA_VTA
           AND AZ.NUR_USUA_ROL_FILIAL = AW.NUR_USUA_ROL_FILIAL
           AND AW.CO_USUARIO = AV.CO_USUARIO
           AND AW.NUR_USUARIO_ROL_USUARIO = AV.NUR_USUARIO_ROL_USUARIO
           AND AW.NUR_USUA_ROL_AREA_VTA = AV.NUR_USUA_ROL_AREA_VTA
           AND AW.NUR_USUA_ROL_FILIAL = AV.NUR_USUA_ROL_FILIAL
           AND AW.NUR_USUA_ROL_FAMILIA_VEH = AV.NUR_USUA_ROL_FAMILIA_VEH
           AND AX.COD_ROL_USUARIO = '002'
           AND AY.COD_AREA_VTA = v_cod_area_vta
           AND AZ.COD_FILIAL = v_cod_filial
           AND AW.COD_FAMILIA_VEH = v_cod_familia_veh
           AND AV.COD_MARCA = v_cod_marca;
    BEGIN
          BEGIN
             select cod_area_vta, cod_filial, cod_familia_veh, cod_marca
             into v_cod_area_vta, v_cod_filial, v_cod_familia_veh, v_cod_marca
             from vve_pedido_veh v
             where v.num_pedido_veh = p_num_pedido_veh;

            FOR c IN lista_usuarios_notificacion LOOP
              v_destinatarios := v_destinatarios || ',' || c.DI_CORREO;
              v_nombre_destinatarios := v_nombre_destinatarios || ',' || c.NOMBRE;
            END LOOP;
            v_destinatarios:=substr(v_destinatarios,2,4000);
            v_nombre_destinatarios:=substr(v_nombre_destinatarios,2,4000);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_cod_area_vta    := NULL;
        v_cod_filial      := NULL;
        v_cod_familia_veh := NULL;
        v_cod_marca       := NULL;
      WHEN OTHERS THEN
        v_cod_area_vta    := NULL;
        v_cod_filial      := NULL;
        v_cod_familia_veh := NULL;
        v_cod_marca       := NULL;
    END;

    BEGIN
      select paterno || ' ' || materno || ' ' || nombre1 || ' ' || nombre2 as nombre, di_correo
        INTO p_nom_usuario, l_txt_corr_usu
        from USUARIOS
        where co_usuario = p_co_usuario;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
          p_nom_usuario := NULL;
         WHEN OTHERS THEN
          p_nom_usuario := NULL;
    END;

  IF v_cod_area_vta IS NOT NULL THEN
      --ASUNTO
      wc_asunto := 'Correo de - Alertas de pre-asignaciÃ³n de Line Up ';
      --TITULO
      wc_titulo := 'DIVEMOTOR - Alerta de pre-asignaciÃ³n de Line Up';
      --
      wc_mensaje := '
        <table class="editorDemoTable" style="width: 572px;">
               <thead></thead>
            <tbody>
          <tr style="height: 61px;" bgcolor="#d">
            <td style="height: 61px; width: 639px;" colspan="4" align="center">
            <h3 style="color: white;">' || wc_titulo ||
                    '</h3>
            </td>
          </tr>
          <tr style="height: 23.8438px;" bgcolor="white">
            <td style="height: 23.8438px; width: 639px;" colspan="4" align="center">
            <h3 style="color: black;">Alertas</h3>
            <p>Hola, se ha creado una alerta porque se realizo la validacion a un pedido en estado PREASIGNADO, el cual tuvo como estado LINE UP.</p>
            </td>
          </tr>
          <tr style="height: 18px;">
            <td style="width: 102px; height: 18px;">Nro Ficha de Venta:</td>
            <td style="width: 251px; height: 18px;">' ||
                    p_num_ficha_vta_veh ||
                    '</td>
            <td style="width: 155px; height: 18px;">Nro de proforma:</td>
            <td style="width: 131px; height: 18px;">' ||
                    p_num_prof_veh ||
                    '</td>
          </tr>
          <tr style="height: 36px;">
            <td style="width: 102px; height: 36px;">Usuario:</td>
            <td style="width: 251px; height: 36px;">' ||
                    p_nom_usuario ||
                    '</td>
            <td style="width: 155px; height: 36px;">Nro de pedido:</td>
            <td style="width: 131px; height: 36px;">' ||
                    p_num_pedido_veh || '</td>
          </tr>
          <tr style="height: 23.8438px;" bgcolor="white">
            <td style="height: 23.8438px; width: 639px;" colspan="4" align="center">
            <p>La informacion contenida en este correo electronico es confidencial. Esta dirigida unicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.;</p>
            </td>
          </tr>
          <tr style="height: 23.8438px;" bgcolor="white">
            <td style="height: 23.8438px; width: 639px;" colspan="4" align="center">Este mensaje ha sido asignado por Sistemas SIDWEB</td>
          </tr>
            </tbody>
           </table>';

--REGISTRO DE CORREOS EN TABLA
          pkg_sweb_graba_prof.sp_inse_mail_aprz
               (p_num_prof_veh,
                v_destinatarios,
                null,
                wc_asunto,
                wc_mensaje,
                l_txt_corr_usu,
                p_cod_id_usuario,
                p_cod_id_usuario,
                null,
                p_ret_esta,
                p_ret_mens);
            IF (p_ret_esta <> 1) THEN
                RAISE ve_error;
            END IF;
            p_ret_esta := 1;
            p_ret_mens := 'SE GRABO CORRECTAMENTE';
--ENVIO DE CORREOS
    Begin
        Sp_Pkg_Enviar_Correo.Open('codisa-naf@divemotor.com.pe');
        Sp_Pkg_Enviar_Correo.Set_From_Address('codisa-naf@divemotor.com.pe','Codisa-Naf');
        Sp_Pkg_Enviar_Correo.Set_To_Address(v_destinatarios,v_nombre_destinatarios);
        Sp_Pkg_Enviar_Correo.set_cc_address('soportelegados@divemotor.com.pe', 'SOPORTE LEGADOS');
        sp_pkg_enviar_correo.set_subject(wc_asunto||' ['||TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI')||']');
        sp_pkg_enviar_correo.set_message(wc_mensaje);
        sp_pkg_enviar_correo.close;
        p_ret_esta := 1;
        p_ret_mens := 'SE ENVIO CORREOS CORRECTAMENTE';
      Exception
        When others then
          wc_mensaje := 'Error, no se pudo enviar el correo ...'||substr(sqlerrm,1,500);
          dbms_output.put_line('Error : '||wc_mensaje);
      End;
     ELSE
       p_ret_esta := 0;
       p_ret_mens := 'NO EXISTEN REGISTROS CON ESOS PARAMETROS';
  END IF;
EXCEPTION
      WHEN ve_error THEN
           p_ret_esta := 0;
           p_ret_mens :='ERROR INTERNO';
      WHEN OTHERS THEN
           p_ret_esta := -1;
           p_ret_mens := 'sp_mail_alert_preasig_lineup: ' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'sp_mail_alert_preasig_lineup',
                                           p_cod_id_usuario,
                                          'ERROR',
                                          p_ret_mens,
                                          p_num_prof_veh);
END sp_mail_alert_jefeventas;
 /*--------------------------------------------------------------------------
    Nombre : sp_correo_facturacion_pedido
    Proposito : Estructura de correo de Facturacion
    Referencias :
    Parametros :
    Log de Cambios
      Fecha        Autor         Descripcion
      31/10/2018   FGRANDEZ     Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_correo_facturacion_pedido
  (
    P_COD_COMPANIA        IN VARCHAR2,
    P_COD_PROVEEDOR       IN VARCHAR2,
    P_PEDIDO              IN VARCHAR2,
    P_DESTINATARIOS       IN VARCHAR2,
    P_COPIA              IN VARCHAR2,
    P_MENSAJE             IN VARCHAR2,
    p_cod_usua_sid       IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web       IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta           OUT NUMBER,
    p_ret_mens           OUT VARCHAR2
  ) AS
      ve_error EXCEPTION;
      v_titulo VARCHAR2(100);
      v_anno VARCHAR2(4);
      v_oficinaRegistral VARCHAR2(300);
      v_documento VARCHAR2(30);
      v_adquiriente VARCHAR2(300);
      v_chasis VARCHAR2(100);
      v_total_documentos number;
      V_CORREOORI VARCHAR2(200);
      wc_entorno       VARCHAR2(400);
      wc_asunto       VARCHAR2(400);
      wc_mensaje      VARCHAR2(4500);
      wc_documentos   VARCHAR2(100);
      v_ambiente VARCHAR2(20);
      wc_documentos_det   VARCHAR2(500);


  BEGIN

   SELECT decode(upper(instance_name),
                  'DESA',
                  'Desarrollo',
                  'QA',
                  'Pruebas',
                  'PROD',
                  'Producción')
      INTO v_ambiente
      FROM v$instance;

  --REQ-86111--
      wc_asunto := 'Envío de Facturación ' || P_PEDIDO;
      wc_mensaje := '<!DOCTYPE html>
        <html lang="es" class="baseFontStyles"
              style="color: #4A4A4A; font-family: helvetica, arial, sans-serif; font-size: 16px; line-height: 1.35;">
        <head>
            <title>Divemotor - #asunto#</title>
            <meta charset="utf-8">
            <style>
                div, p, a, li, td {
                    -webkit-text-size-adjust: none;
                }
                @media screen and (max-width: 750px) {
                    .mainTable, .mailBody, .to100 {
                        width: 100% !important;
                    }
                }
            </style>
            <style>
                @media screen and (max-width: 750px) {
                    .mailBody {
                        padding: 20px 18px !important
                    }

                    .col3 {
                        width: 100% !important
                    }
                }
            </style>
        </head>
        <body style="background-color: #eeeeee; margin: 0;">
        <table width="750" class="to100" border="0" align="center" cellpadding="0" cellspacing="0" class="mainTable"
               style="border-spacing: 0;">
            <tr><td style="padding: 0;"><table class="to100" height="40" width="100%" cellpadding="14" cellspacing="0" border="0"
                           style="border-spacing: 0;"><tr><td style="padding: 0;"><table height="40" width="100%" cellpadding="14" cellspacing="0" border="0"
                                       style="background-color: #222222; border-spacing: 0; padding-left: 25px; padding-right: 30px;"><tr style="background-color: #222222;"><td style="background-color: #222222; padding: 0;color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 750;">
                                            Divemotor
                                        </td><td style="background-color: #222222; color: white; font-family: helvetica, arial, sans-serif; font-size: 15px; font-weight: 750; padding: 0; text-align: right;">
                                           Envío de Facturación '||P_PEDIDO||'</td></tr>
                                </table></td></tr></table>
                    <table class="to100" width="750" cellpadding="12" cellspacing="0" id="content" style="border-spacing: 0;">
                        <tr><td class="mailBody" style="background-color: #ffffff; padding: 30px;"><p style="margin: 0;">Estimados:<br>'||replace(replace(P_MENSAJE,chr(10),'<br>'),chr(13),'<br>')||'</p>
<br>
<div style="margin:0;padding-top:25px;">La información contenida en este correo electrónico es confidencial. Esta dirigida únicamente para el uso individual. Si has recibido este correo por error por favor hacer caso omiso a la solicitud.</div>
                            </td>
                        </tr>
                        '||wc_entorno||'
                    </td></tr></table></td></tr></table></body></html>';
    --REQ-86111--                
    --Obtenemos el correo origen
    BEGIN
      SELECT txt_correo
        INTO V_CORREOORI
      FROM sistemas.sis_mae_usuario
      WHERE cod_id_usuario=P_COD_USUA_WEB;
    EXCEPTION
      WHEN OTHERS THEN
        V_CORREOORI  := 'apps@divemotor.com.pe';
    END;                    

    --REQ-86111--
      pkg_sweb_inmatri_pedido.sp_inse_correo(P_PEDIDO,
                  'EF',
                   P_destinatarios,
                   P_copia,
                   wc_asunto,
                   wc_mensaje,
                   V_CORREOORI,
                   p_cod_usua_sid,
                   p_cod_usua_web,
                   p_ret_esta,
                   p_ret_mens);
    --REQ-86111--


    IF (p_ret_esta <> 1) THEN
      RAISE ve_error;
    END IF;

  EXCEPTION
    WHEN ve_error THEN
      p_ret_esta := 0;
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := SQLERRM;

      --REQ-86111--
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_CORREO_FACTURACION',
                                          p_cod_usua_sid,
                                          'Error',
                                          p_ret_mens,
                                          P_PEDIDO);
      --REQ-86111--
  END;  

END pkg_sweb_five_mant_pedido;
