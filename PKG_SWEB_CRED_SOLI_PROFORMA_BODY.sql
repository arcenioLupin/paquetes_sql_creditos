create or replace PACKAGE BODY VENTA.PKG_SWEB_CRED_SOLI_PROFORMA AS

  PROCEDURE sp_list_cred_soli_proforma
  (
    p_cod_soli_cred  IN vve_cred_soli.cod_soli_cred%TYPE,   
    p_cod_usua_sid   IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web   IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ind_paginado   IN VARCHAR2,
    p_limitinf       IN INTEGER,
    p_limitsup       IN INTEGER,    
    p_ret_cursor     OUT SYS_REFCURSOR,
    p_cantidad       OUT NUMBER,
    p_ret_esta       OUT NUMBER,
    p_ret_mens       OUT VARCHAR2
  ) AS
  
  v_cod_tipo_veh VARCHAR2(10);--<I Req. 87567 E2.1 ID 63 avilca 21/08/2020>
  BEGIN
  
  --<I Req. 87567 E2.1 ID 63 Usuario 21/08/2020>
  -- Obteniendo el código de tipo de vehículo de la proforma con que se creó la solicitud

   BEGIN
   SELECT cod_tipo_veh INTO v_cod_tipo_veh
   FROM vve_proforma_veh_det
   WHERE NUM_PROF_VEH =
            (SELECT num_prof_veh FROM vve_cred_soli_prof
              WHERE fec_crea_reg =
                                   (SELECT MIN(fec_crea_reg) FROM
                                        (SELECT pvd.cod_tipo_veh,csp.num_prof_veh,csp.fec_crea_reg FROM vve_cred_soli_prof csp
                                            INNER JOIN vve_proforma_veh_det pvd on csp.num_prof_veh = pvd.num_prof_veh
                                            where csp.cod_soli_cred = p_cod_soli_cred)
                                    )
             AND cod_soli_cred = p_cod_soli_cred                    
            );
    EXCEPTION
     WHEN NO_DATA_FOUND THEN  
         v_cod_tipo_veh:= NULL;
    END; 
   --<I Req. 87567 E2.1 ID 63 avilca 21/08/2020>
    OPEN p_ret_cursor FOR
         SELECT DISTINCT 
            (Select nvl(fp.ind_inactivo,'N') 
             from vve_ficha_vta_proforma_veh fp 
             where fp.num_ficha_vta_veh = fvR.num_ficha_vta_veh 
             and   fp.num_prof_veh = fvR.num_prof_veh 
             ) IND_PROF_FV_INAC,
            fvr.num_prof_veh,
            fvr.num_ficha_vta_veh,
            pvd.cod_familia_veh,
            fv.des_familia_veh,
            pvd.cod_tipo_veh,
            tv.des_tipo_veh,
            pvd.cod_marca,
            gm.nom_marca,
            pvd.cod_baumuster,
            pkg_sweb_mae_gene.fu_desc_modelo(pvd.cod_familia_veh,
                                             pvd.cod_marca,
                                             pvd.cod_baumuster) baumuster,
            pkg_sweb_mae_vehi.fu_cara_anio_fabr(pvd.cod_familia_veh,
                                                pvd.cod_marca,
                                                pvd.cod_baumuster,
                                                pvd.cod_config_veh) anio_fabricacion,
            pv.cod_moneda_prof,
            DECODE(pv.cod_moneda_prof, 'SOL', 'S/.', 'US$') des_moneda_prof,
            pvd.can_veh can_veh_prof, 
            NVL(
            (SELECT cv.can_veh_fin 
             FROM vve_cred_soli_prof cv 
             WHERE cv.cod_soli_cred = p_cod_soli_cred 
                AND cv.num_prof_veh = fvr.num_prof_veh),
            pvd.can_veh) can_veh,
            pvd.val_pre_veh precio_unitario,
            (NVL(
            (SELECT vt.can_veh_fin 
             FROM vve_cred_soli_prof vt 
             WHERE vt.cod_soli_cred = p_cod_soli_cred  
                AND vt.num_prof_veh = fvr.num_prof_veh),
            pvd.can_veh) * pvd.val_pre_veh)  venta_total,
            (SELECT DECODE(sp.ind_inactivo, 'N', 'S', 'N')
             FROM vve_cred_soli_prof sp 
             WHERE sp.num_prof_veh = fvr.num_prof_veh 
                AND sp.cod_soli_cred = p_cod_soli_cred ) ind_soli_prof
        FROM vve_ficha_vta_proforma_veh fvp
        INNER JOIN vve_ficha_vta_proforma_veh fvr
            ON fvp.num_ficha_vta_veh = (select distinct v.num_ficha_vta_veh 
                                        from vve_ficha_vta_proforma_veh v
                                        where v.num_prof_veh in (select s.num_prof_veh 
                                                                 from   vve_cred_soli_prof s 
                                                                 where  s.cod_soli_cred = p_cod_soli_cred 
                                                                 and    s.ind_inactivo = 'N'))
            and fvr.num_ficha_vta_veh = fvp.num_ficha_vta_veh 
        INNER JOIN vve_proforma_veh pv
            ON pv.num_prof_veh = fvr.num_prof_veh    
        INNER JOIN vve_proforma_veh_det pvd
            ON pvd.num_prof_veh = pv.num_prof_veh
               AND pvd.cod_tipo_veh = v_cod_tipo_veh  --<I Req. 87567 E2.1 ID 63 avilca 21/08/2020>
        INNER JOIN vve_familia_veh fv
            ON fv.cod_familia_veh = pvd.cod_familia_veh
        INNER JOIN vve_tipo_veh tv
            ON tv.cod_tipo_veh = pvd.cod_tipo_veh
        INNER JOIN gen_marca gm
            ON gm.cod_marca = pvd.cod_marca
        WHERE fvp.num_prof_veh IN 
            (SELECT num_prof_veh sp
            FROM vve_cred_soli_prof sp
            WHERE sp.cod_soli_cred = p_cod_soli_cred 
            and ind_inactivo = 'N'
           )
      and (
           fvr.ind_inactivo='N'      
      or EXISTS (select 1 
         from vve_cred_soli_prof sp 
         where sp.num_prof_veh =fvr.num_prof_veh 
          and not(fvr.ind_inactivo='S' and sp.ind_inactivo='S') 
        ));
        

/*        SELECT DISTINCT 
            (SELECT 'S' 
             FROM VVE_CRED_SOLI_PROF SP
             WHERE SP.COD_SOLI_CRED LIKE '%92' 
             AND   SP.NUM_PROF_VEH = FVR.NUM_PROF_VEH  
             AND   (SP.IND_INACTIVO ='N'
             AND   FVR.IND_INACTIVO = 'S')) IND_PROF_FV_INAC,
            fvr.num_prof_veh,
            fvr.num_ficha_vta_veh,
            pvd.cod_familia_veh,
            fv.des_familia_veh,
            pvd.cod_tipo_veh,
            tv.des_tipo_veh,
            pvd.cod_marca,
            gm.nom_marca,
            pvd.cod_baumuster,
            pkg_sweb_mae_gene.fu_desc_modelo(pvd.cod_familia_veh,
                                             pvd.cod_marca,
                                             pvd.cod_baumuster) baumuster,
            pkg_sweb_mae_vehi.fu_cara_anio_fabr(pvd.cod_familia_veh,
                                                pvd.cod_marca,
                                                pvd.cod_baumuster,
                                                pvd.cod_config_veh) anio_fabricacion,
            pv.cod_moneda_prof,
            DECODE(pv.cod_moneda_prof, 'SOL', 'S/.', 'US$') des_moneda_prof,
            NVL(
            (SELECT cv.can_veh_fin 
             FROM vve_cred_soli_prof cv 
             WHERE cv.cod_soli_cred = p_cod_soli_cred 
                AND cv.num_prof_veh = fvr.num_prof_veh),
            pvd.can_veh) can_veh,
            pvd.can_veh can_veh_prof,
            pvd.val_pre_veh precio_unitario,
            NVL(
            (SELECT vt.can_veh_fin 
             FROM vve_cred_soli_prof vt 
             WHERE vt.cod_soli_cred = p_cod_soli_cred 
                AND vt.num_prof_veh = fvr.num_prof_veh),
            pvd.can_veh) * pvd.val_pre_veh venta_total,
            (SELECT DECODE(sp.ind_inactivo, 'N', 'S', 'N')
             FROM vve_cred_soli_prof sp 
             WHERE sp.num_prof_veh = fvr.num_prof_veh 
                AND sp.cod_soli_cred = p_cod_soli_cred) ind_soli_prof
        FROM vve_ficha_vta_proforma_veh fvp
        INNER JOIN vve_ficha_vta_proforma_veh fvr
            ON fvr.num_ficha_vta_veh = fvp.num_ficha_vta_veh 
--                AND fvr.ind_inactivo = 'N'
                AND EXISTS (select 1 
                           from vve_cred_soli_prof sp 
                           where sp.num_prof_veh =fvr.num_prof_veh 
                            and not(fvr.ind_inactivo='S' and sp.ind_inactivo='S') 
                           and sp.cod_soli_cred = p_cod_soli_cred)
        INNER JOIN vve_proforma_veh pv
            ON pv.num_prof_veh = fvr.num_prof_veh    
        INNER JOIN vve_proforma_veh_det pvd
            ON pvd.num_prof_veh = pv.num_prof_veh
        INNER JOIN vve_familia_veh fv
            ON fv.cod_familia_veh = pvd.cod_familia_veh
        INNER JOIN vve_tipo_veh tv
            ON tv.cod_tipo_veh = pvd.cod_tipo_veh
        INNER JOIN gen_marca gm
            ON gm.cod_marca = pvd.cod_marca
        WHERE fvp.num_prof_veh IN 
            (SELECT num_prof_veh 
            FROM vve_cred_soli_prof 
            WHERE cod_soli_cred = p_cod_soli_cred);
*/             
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
    p_cantidad := 1;
    
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_cantidad := 0;
      p_ret_mens := 'SP_LIST_CRED_SOLI_PROFORMA:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LIST_CRED_SOLI_PROFORMA',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          p_cod_soli_cred);   
  END sp_list_cred_soli_proforma;

END PKG_SWEB_CRED_SOLI_PROFORMA;