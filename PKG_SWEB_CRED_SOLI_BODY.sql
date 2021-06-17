create or replace PACKAGE BODY         VENTA.pkg_sweb_cred_soli AS
       --<Req. 87567 ES01 ID## EBARBOZA 23/03/2020>
       --< SE AGREGAN LAS VARIABLES p_num_tele_fijo_ejec,p_cod_sucursal,p_cod_area_venta
       -- p_cod_vendedor, p_cod_zona, p_dir_correo>
    PROCEDURE sp_inse_cred_soli (
        p_cod_clie            IN                    vve_cred_soli.cod_clie%TYPE,
        p_tip_soli_cred       IN                    vve_cred_soli.tip_soli_cred%TYPE,
        p_cod_mone_soli       IN                    vve_cred_soli.cod_mone_soli%TYPE,
        p_cod_banco           IN                    vve_cred_soli.cod_banco%TYPE,
        p_cod_estado          IN                    vve_cred_soli.cod_estado%TYPE,
        p_val_mon_fin         IN                    vve_cred_soli.val_mon_fin%TYPE,
        p_can_plaz_mes        IN                    vve_cred_soli.can_plaz_mes%TYPE,
        p_txt_obse_crea       IN                    vve_cred_soli.txt_obse_crea%TYPE,
        p_cod_res_fina        IN                    VARCHAR2,
        p_num_telf_movil      IN                    VARCHAR2,
        p_num_tele_fijo_ejec  IN                    vve_cred_soli.num_tele_fijo_ejec%TYPE,
        p_cod_sucursal        IN                    vve_cred_soli.cod_sucursal%TYPE,
        p_cod_filial          IN                    vve_cred_soli.cod_filial%TYPE,
        p_cod_area_venta      IN                    vve_cred_soli.cod_area_vta%TYPE,
        p_cod_vendedor        IN                    vve_cred_soli.vendedor%TYPE,
        p_cod_zona            IN                    vve_cred_soli.cod_zona%TYPE,
        p_dir_correo          IN                    VARCHAR2,
        p_num_prof_veh        IN                    VARCHAR2,
        p_val_vta_tot_fin     IN                    vve_cred_soli_prof.val_vta_tot_fin%TYPE,
        p_flag_registro       IN                    VARCHAR2,
        p_cod_empr            IN                    vve_cred_soli.cod_empr%TYPE,
        p_can_dias_fact_cred  IN                    VARCHAR2, /** Req. 87567 E2.1 ID: 309 - avilca 25/03/2020 **/
        p_cod_usua_sid        IN                    sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web        IN                    sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_cod_soli_cred   OUT                   vve_cred_soli.cod_soli_cred%TYPE,
        p_ret_esta            OUT                   NUMBER,
        p_ret_mens            OUT                   VARCHAR2
    ) AS

        ve_error EXCEPTION;
        v_sql_base             VARCHAR2(4000);
        c_actividades          SYS_REFCURSOR;
        -- v_cod_acti_cred        vve_cred_maes_acti.cod_acti_cred%TYPE; <CC E2.1 ID224 LR 11.11.19>
        v_cod_acti_cred        vve_cred_maes_activ.cod_acti_cred%TYPE; --<CC E2.1 ID224 LR 11.11.19>
        v_ind_inactivo         VARCHAR2(1);
        v_cod_cred_soli_acti   VARCHAR2(20);
        v_txt_usuario          VARCHAR2(20);
        v_cod_empr             VARCHAR2(2);
        v_cod_area_vta         VARCHAR2(3);
        v_txt_msj              VARCHAR2(200);
        e_up_gen_perso         EXCEPTION;
        v_val_can_veh          vve_proforma_veh_det.can_veh%TYPE;
        v_val_venta_pedido     vve_pedido_veh.val_vta_pedido_veh%TYPE;
        v_can_veh              vve_proforma_veh_det.can_veh%TYPE;
        v_num_prof_veh         vve_cred_soli_prof.num_prof_veh%TYPE;


    BEGIN

        BEGIN
            SELECT
                lpad(nvl(MAX(cod_soli_cred), 0) + 1, 20, '0')
            INTO p_ret_cod_soli_cred
            FROM
                vve_cred_soli;
            EXCEPTION
                WHEN OTHERS THEN
                p_ret_cod_soli_cred := '0000000000000000001';
        END;

        BEGIN
            UPDATE gen_persona
            SET
                dir_correo = p_dir_correo,
                num_telf_movil = p_num_telf_movil
            WHERE
                cod_perso = p_cod_clie;
        v_txt_msj := 'Se actualizó en GEN_PERSONA ';
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, v_txt_msj
        , p_ret_mens, p_ret_cod_soli_cred);
        IF SQL%NOTFOUND THEN
            RAISE e_up_gen_perso;
        END IF;
        ROLLBACK;
        EXCEPTION
           WHEN e_up_gen_perso THEN
           v_txt_msj := 'ERROR AL ACTUALIZAR GEN_PERSONA';
            p_ret_esta := -1;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, v_txt_msj
            , p_ret_mens, p_ret_cod_soli_cred);
        END;
        COMMIT;

        -- <I Req. 87567 E2.1 ID:12 avilca 14/05/2020>
            UPDATE gen_dir_perso
            SET
                num_telf_movil = p_num_telf_movil,
                num_telf1 = p_num_tele_fijo_ejec
            WHERE
                cod_perso = p_cod_clie;

            COMMIT;
        -- <F Req. 87567 E2.1 ID:12 avilca 14/05/2020>

        v_txt_usuario := p_cod_res_fina;

        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, 'Tiene usuario', p_ret_mens, p_ret_cod_soli_cred);

        IF p_tip_soli_cred = 'TC05' OR p_tip_soli_cred = 'TC07' THEN
            v_cod_empr := p_cod_empr;

            BEGIN
              SELECT COD_AREA_VTA INTO v_cod_area_vta FROM gen_perso_vendedor WHERE COD_PERSO = p_cod_clie AND IND_INACTIVO = 'N';
              p_ret_esta := 0;
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, p_tip_soli_cred||'- con area vta: '||v_cod_area_vta
                , p_ret_mens, p_ret_cod_soli_cred);
            EXCEPTION
              WHEN TOO_MANY_ROWS THEN
                v_txt_msj := 'Código de area post-venta devuelve más de un registro';
                --v_cod_area_vta := '001';
                p_ret_esta := -1;
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, v_txt_msj
                , p_ret_mens, p_ret_cod_soli_cred);
              WHEN NO_DATA_FOUND THEN
                p_ret_esta := -1;
                p_ret_mens := 'El cliente no tiene asignado a un vendedor';
                RETURN;
            END;
        ELSE
            SELECT cod_cia, cod_area_vta INTO v_cod_empr, v_cod_area_vta
            FROM vve_proforma_veh WHERE num_prof_veh = p_num_prof_veh;
        END IF;

        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, 'Paso validacion de empresa y area vta', p_ret_mens, p_ret_cod_soli_cred);


        BEGIN
         --<Inicio Req. 87567 ES01 ID## EBARBOZA 23/03/2020>
         --<SE INSERTA NUEVOS CAMPO PARA NUEVAS COLUMNAS
         --p_num_tele_fijo_ejec,p_cod_sucursal,p_cod_area_venta
       -- p_cod_vendedor, p_cod_zona, p_dir_correo>
        INSERT INTO vve_cred_soli (
            cod_soli_cred,
            cod_clie,
            cod_empr,
            cod_resp_fina,
            cod_area_vta,
            tip_soli_cred,
            fec_soli_cred,
            cod_pers_soli,
            cod_banco,
            num_tele_fijo_ejec,
            num_celu_ejec,
            cod_estado,
            val_mon_fin,
            can_plaz_mes,
            txt_obse_crea,
            cod_usua_crea_reg,
            fec_crea_regi,
            cod_mone_soli,
            val_ci,
            val_mont_sol_gest_banc,
            val_porc_ci,
            cod_mone_cart_banc,
            cod_zona,
            cod_filial,
            vendedor,
            cod_sucursal,
            can_dias_fact_cred,/** Req. 87567 E2.1 ID: 309 - avilca 25/03/2020 **/
            ind_inactivo/** Req. 87567 E2.1 ID:62 - avilca 20/08/2020 **/
        ) VALUES (
            p_ret_cod_soli_cred,
            p_cod_clie,
            v_cod_empr,
            v_txt_usuario,
            CASE
            WHEN p_cod_area_venta is not null  THEN p_cod_area_venta ELSE v_cod_area_vta
            END,
            p_tip_soli_cred,
            to_date(to_char(sysdate,'DD/MM/YYYY'),'DD/MM/YYYY'),/** Req. 87567 E2.1 ID:62 - avilca 20/08/2020 **/
            p_cod_usua_sid,
            p_cod_banco,
            NULL,
            NULL,
            p_cod_estado,
            CASE
            WHEN p_tip_soli_cred = 'TC06'  THEN 0 ELSE p_val_mon_fin
            END,
            p_can_plaz_mes,
            p_txt_obse_crea,
            p_cod_usua_sid,
            to_date(to_char(sysdate,'DD/MM/YYYY'),'DD/MM/YYYY'),/** Req. 87567 E2.1 ID:62 - avilca 20/08/2020 **/
            DECODE(p_cod_mone_soli, 'SOL', '1', '2'),
            --<I Req. 87567 E2.1 ID:19 AVILCA 14/05/2020>
            CASE
            WHEN (p_tip_soli_cred = 'TC04' OR p_tip_soli_cred = 'TC05' OR p_tip_soli_cred = 'TC06')  THEN 0 ELSE p_val_mon_fin
            END,
            CASE
            WHEN (p_tip_soli_cred = 'TC06')  THEN p_val_mon_fin ELSE NULL
            END,
            CASE
            WHEN (p_tip_soli_cred = 'TC04' OR p_tip_soli_cred = 'TC05' OR p_tip_soli_cred = 'TC06')  THEN 0 ELSE 100
            END,
            NULL,
           --<F Req. 87567 E2.1 ID:19 AVILCA 14/05/2020>
            p_cod_zona,--<p_cod_zona Req. 87567 ES01 ID## EBARBOZA 23/03/2020>
            p_cod_filial,--<p_cod_filial Req. 87567 ES01 ID## EBARBOZA 23/03/2020>
            p_cod_vendedor,--<p_cod_vendedor Req. 87567 ES01 ID## EBARBOZA 23/03/2020>
            p_cod_sucursal,--<p_cod_sucursal Req. 87567 ES01 ID## EBARBOZA 23/03/2020>
            p_can_dias_fact_cred,/** Req. 87567 E2.1 ID: 309 - avilca 25/03/2020 **/
            'N'/** Req. 87567 E2.1 ID:62 - avilca 20/08/2020 **/
            );
            --<Fin Req. 87567 ES01 ID## EBARBOZA 23/03/2020>
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            v_txt_msj := 'la solicitud a insertar ya existe';
            p_ret_esta := -1;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, v_txt_msj
            , p_ret_mens, p_ret_cod_soli_cred);
            ROLLBACK;
        END;
        COMMIT;

        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, 'Insertó solicitud', p_ret_mens, p_ret_cod_soli_cred);

        BEGIN
            SELECT NVL(d.can_veh,0), d.val_pre_veh
            INTO   v_val_can_veh, v_val_venta_pedido
            FROM   vve_proforma_veh p, vve_proforma_veh_det d
            WHERE  p.num_prof_veh = p_num_prof_veh
            AND    p.num_prof_veh = d.num_prof_veh
            AND    p.cod_cia = v_cod_empr; --p_cod_empr;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_val_can_veh := 0;
              v_val_venta_pedido := 0;
              v_txt_msj := 'No se encuentra la proforma';
              p_ret_esta := -1;
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, v_txt_msj
              , p_ret_mens, p_ret_cod_soli_cred);
            WHEN TOO_MANY_ROWS THEN
              v_val_can_veh := 0;
              v_val_venta_pedido := 0;
              v_txt_msj := 'Existe mas de un registro para la proforma';
              p_ret_esta := -1;
              pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, v_txt_msj
              , p_ret_mens, p_ret_cod_soli_cred);
        END;

        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, 'Validando datos 2', p_ret_mens, p_ret_cod_soli_cred);

        IF p_flag_registro = 'PROF' THEN
        -- <I Req. 87567 E2.1 ID: Proforma -ficha AVILCA 29/10/2020>
        BEGIN
           SELECT num_prof_veh INTO v_num_prof_veh
            FROM vve_cred_soli_prof
            where cod_soli_cred = p_ret_cod_soli_cred;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_num_prof_veh := 0;
        END;

        BEGIN
           SELECT can_veh INTO v_can_veh
            FROM vve_proforma_veh_det
            where num_prof_veh = v_num_prof_veh;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_can_veh := 0;
        END;
      -- <F Req. 87567 E2.1 ID: Proforma -ficha AVILCA 29/10/2020>

            INSERT INTO vve_cred_soli_prof (
                cod_soli_cred,
                num_prof_veh,
                can_veh_fin,
                val_vta_tot_fin,
                can_veh_prof,
                cod_usua_crea_reg,
                fec_crea_reg,
                cod_usua_modi_reg,
                fec_modi_reg,
                ind_inactivo
            ) VALUES (
                p_ret_cod_soli_cred,
                p_num_prof_veh,
                v_val_can_veh,
                p_val_vta_tot_fin,
                v_val_can_veh,/** Req. 87567 E2.1 ID:62 - avilca 26/01/2021 **/
                p_cod_usua_sid,
                to_date(to_char(sysdate,'DD/MM/YYYY'),'DD/MM/YYYY'),/** Req. 87567 E2.1 ID:62 - avilca 20/08/2020 **/
                null,
                null,
                'N'
            );

            COMMIT;
        END IF;

        --<I CC E2.1 ID224 LR 11.11.19>
        v_sql_base := 'SELECT ma.COD_ACTI_CRED, atc.IND_OBLIG
                       FROM  vve_cred_maes_activ ma, vve_cred_acti_tipo_cred atc
                       WHERE ma.cod_acti_cred = atc.cod_acti_cred
                       AND atc.cod_tipo_cred ='''||p_tip_soli_cred||'''
                       AND ma.ind_inactivo = ''N''
                       AND atc.ind_inactivo = ''N''
                       ORDER BY ma.num_orden';

        /*
        v_sql_base := 'SELECT COD_ACTI_CRED, IND_' || p_tip_soli_cred || ' FROM vve_cred_maes_acti WHERE IND_'
                      || p_tip_soli_cred
                      || ' IN (''S'', ''X'') ORDER BY num_orden';
        */
        --<F CC E2.1 ID224 LR 11.11.19>
        OPEN c_actividades FOR v_sql_base;
        LOOP
            FETCH c_actividades INTO v_cod_acti_cred, v_ind_inactivo;
            EXIT WHEN c_actividades%notfound;
            BEGIN
                SELECT
                    lpad(nvl(MAX(cod_cred_soli_acti), 0) + 1, 20, '0')
                INTO v_cod_cred_soli_acti
                FROM
                    vve_cred_soli_acti;

            EXCEPTION
                WHEN OTHERS THEN
                    v_cod_cred_soli_acti := '1';
            END;

            INSERT INTO vve_cred_soli_acti (
                cod_cred_soli_acti,
                cod_acti_cred,
                cod_soli_cred,
                cod_usua_crea_reg,
                fec_crea_reg,
                ind_inactivo
            ) VALUES (
                v_cod_cred_soli_acti,
                v_cod_acti_cred,
                p_ret_cod_soli_cred,
                p_cod_usua_sid,
                to_date(to_char(sysdate,'DD/MM/YYYY'),'DD/MM/YYYY'),/** Req. 87567 E2.1 ID:62 - avilca 20/08/2020 **/
                DECODE(v_ind_inactivo,'S','N','S')
            );
            COMMIT;

        END LOOP;

        CLOSE c_actividades;
        -- ACtualizando fecha de ejecución de registro y verificando cierre de etapa
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_ret_cod_soli_cred,'E1','A1',p_cod_usua_sid,p_ret_esta,p_ret_mens);

        p_ret_esta := 1;
        p_ret_mens := 'Se registro correctamente la solicitud N° ' || p_ret_cod_soli_cred;

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, 'Error al insertar la solicitud de crédito - tipo credito: '||p_tip_soli_cred
            , p_ret_mens, p_ret_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := p_ret_mens||'SP_INSE_CRED_SOLI:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI', p_cod_usua_sid, 'Error al insertar la solicitud de crédito'
            , p_ret_mens, p_ret_cod_soli_cred);
            ROLLBACK;
    END sp_inse_cred_soli;

    PROCEDURE sp_actu_gest_banc (
        p_cod_soli_cred             IN          vve_cred_soli.cod_soli_cred%TYPE,
        p_cod_banco                 IN          vve_cred_soli.cod_banco%TYPE,
        p_val_mont_fin              IN          vve_cred_soli.val_mon_fin%TYPE,
        p_cod_mone_soli             IN          vve_cred_soli.cod_mone_soli%TYPE,
        p_val_mont_sol_gest_banc    IN          vve_cred_soli.val_mont_sol_gest_banc%TYPE,
        p_val_porc_gest_banc        IN          vve_cred_soli.val_porc_gest_banc%TYPE,
        p_fec_ingr_gest_banc        IN          VARCHAR2,
        p_fec_ingr_ries_gest_banc   IN          VARCHAR2,
        p_fec_aprob_cart_ban        IN          VARCHAR2,
        p_fec_resu_gest_banc        IN          VARCHAR2,
        p_cod_esta_gest_banc        IN          vve_cred_soli.cod_esta_gest_banc%TYPE,
        p_txt_obse_gest_banc        IN          vve_cred_soli.txt_obse_gest_banc%TYPE,
        p_cod_usua_sid              IN          sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta                  OUT         NUMBER,
        p_ret_mens                  OUT         VARCHAR2
    ) AS
        ve_error EXCEPTION;
        v_val_pago_cont_ci NUMERIC(10,2);
        v_val_mon_fin_rechazo NUMERIC(10,2);
        v_val_porc_ci_rechazo NUMERIC(5,2);
        v_val_porc_conv NUMERIC(5,2);
        v_val_mont_sol_gest_banc_aux NUMERIC(11,2);
        v_val_mont_cart_banc_calc NUMERIC(11,2);
        v_val_ci_calc NUMERIC(11,2);
        v_val_porc_ci NUMERIC(5,2);
        v_val_mon_fin NUMERIC(10,2);

    BEGIN

        -- DATOS GENERALES
        SELECT nvl(val_pago_cont_ci, 0), val_mon_fin INTO v_val_pago_cont_ci, v_val_mon_fin
        FROM
            vve_cred_soli
        WHERE
            cod_soli_cred = p_cod_soli_cred;

        --------------------------------------------------------

        IF p_cod_esta_gest_banc IN ('EGB03', 'EGB04') THEN --   ACEPTADO TOTAL Y PARCIAL

            v_val_porc_conv := p_val_porc_gest_banc / 100;

            IF p_val_mont_sol_gest_banc IS NULL OR p_val_mont_sol_gest_banc = '' THEN
                SELECT val_mont_sol_gest_banc INTO v_val_mont_sol_gest_banc_aux
                FROM vve_cred_soli
                WHERE
                    cod_soli_cred = p_cod_soli_cred;
            ELSE
                v_val_mont_sol_gest_banc_aux := p_val_mont_sol_gest_banc;
            END IF;

            -- v_val_mont_cart_banc_calc := v_val_mont_sol_gest_banc_aux * v_val_porc_conv;

            IF p_cod_esta_gest_banc = 'EGB03' THEN -- ACEPTADO TOTAL
                v_val_ci_calc := v_val_mont_sol_gest_banc_aux - v_val_pago_cont_ci;
                v_val_porc_ci := (v_val_ci_calc / p_val_mont_fin) * 100;
            ELSE                                   -- ACEPTADO PARCIAL
                v_val_ci_calc := (p_val_mont_fin * (1 - v_val_porc_conv)) - v_val_pago_cont_ci;
                --v_val_porc_ci := (v_val_ci_calc / p_val_mont_fin) * 100; --<Req. 87567 E2.1 ID 146 AVILCA 08/09/2020>
                v_val_porc_ci := (1 - v_val_porc_conv) * 100;

            END IF;

            UPDATE vve_cred_soli
            SET
                val_porc_gest_banc = p_val_porc_gest_banc,
                val_mont_cart_banc = p_val_mont_sol_gest_banc,
                cod_banco = p_cod_banco,-- Req. 87567 E2.19 ID 4 avilca 01/02/2021
                val_ci = v_val_ci_calc,
                val_mon_fin = v_val_ci_calc,
                val_porc_ci = v_val_porc_ci,
                txt_obse_gest_banc = p_txt_obse_gest_banc,
                fec_aprob_cart_ban = to_date(p_fec_aprob_cart_ban,'DD/MM/YYYY'),
                fec_resu_gest_banc = to_date(p_fec_resu_gest_banc,'DD/MM/YYYY'),
                cod_esta_gest_banc = p_cod_esta_gest_banc,
                val_mone_aprob_banc = p_val_mont_sol_gest_banc,--Req. 87567 E2.1 ID 10 AVILCA 20/05/2020
                val_mont_sol_gest_banc = p_val_mont_fin, --Req. 87567 E2.1 ID 10 AVILCA 01/02/2021
                cod_usua_modi  = p_cod_usua_sid,
                fec_modi_regi = to_date(SYSDATE,'DD/MM/YYYY')-- Req. 87567 E2.19 ID 4 avilca 25/06/2020
            WHERE
                cod_soli_cred = p_cod_soli_cred;
            COMMIT;

        END IF;

        IF p_cod_esta_gest_banc = 'EGB05' THEN -- RECHAZADO

            v_val_mon_fin_rechazo := p_val_mont_fin - v_val_pago_cont_ci;

            SELECT (val_ci/p_val_mont_fin) INTO v_val_porc_ci_rechazo
            FROM
                vve_cred_soli
            WHERE
                cod_soli_cred = p_cod_soli_cred;

            UPDATE vve_cred_soli
            SET
                tip_soli_cred = 'TC01',
                val_porc_gest_banc = p_val_porc_gest_banc,
                val_mont_cart_banc = 0,
                val_mon_fin = v_val_mon_fin_rechazo,
                val_ci = v_val_pago_cont_ci,
                val_porc_ci = v_val_porc_ci_rechazo,
                cod_esta_gest_banc = p_cod_esta_gest_banc,
                txt_obse_gest_banc = p_txt_obse_gest_banc,
                cod_usua_modi  = p_cod_usua_sid,
                fec_modi_regi = to_date(SYSDATE,'DD/MM/YYYY')-- Req. 87567 E2.19 ID 4 avilca 25/06/2020
            WHERE
                cod_soli_cred = p_cod_soli_cred;
            COMMIT;
        END IF;
         --<INICIO. 87567 ES01 ID## EBARBOZA 23/03/2020>
        IF p_cod_esta_gest_banc = 'EGB01' THEN -- INGRESADO
            UPDATE vve_cred_soli
            SET
                val_mont_sol_gest_banc = p_val_mont_fin,
                val_ci = p_val_mont_sol_gest_banc,
                cod_banco = p_cod_banco, --<p_cod_banco. 87567 ES01 ID## EBARBOZA 11/03/2020>
                cod_mone_cart_banc = DECODE(p_cod_mone_soli, 'SOL', '1', '2'),
                cod_esta_gest_banc = p_cod_esta_gest_banc,
                fec_ingr_gest_banc = to_date(p_fec_ingr_gest_banc,'DD/MM/YYYY'),
                txt_obse_gest_banc = p_txt_obse_gest_banc,
                cod_usua_modi  = p_cod_usua_sid,
                fec_modi_regi = to_date(SYSDATE,'DD/MM/YYYY')-- Req. 87567 E2.19 ID 4 avilca 25/06/2020
            WHERE
                cod_soli_cred = p_cod_soli_cred;
            COMMIT;
        END IF;
         --<FIN. 87567 E2.1 ID## EBARBOZA 23/03/2020>
        IF p_cod_esta_gest_banc = 'EGB02' THEN -- RIESGOS
            UPDATE vve_cred_soli
            SET
                val_mont_sol_gest_banc = p_val_mont_fin,
                val_ci = p_val_mont_sol_gest_banc,
                cod_mone_cart_banc = DECODE(p_cod_mone_soli, 'SOL', '1', '2'),
                cod_esta_gest_banc = p_cod_esta_gest_banc,
                fec_ingr_ries_gest_banc = to_date(p_fec_ingr_ries_gest_banc,'DD/MM/YYYY'),
                txt_obse_gest_banc = p_txt_obse_gest_banc,
                cod_banco = p_cod_banco,-- Req. 87567 E2.19 ID 4 avilca 01/02/2021
                cod_usua_modi  = p_cod_usua_sid,
                fec_modi_regi = to_date(SYSDATE,'DD/MM/YYYY')-- Req. 87567 E2.19 ID 4 avilca 25/06/2020
            WHERE
                cod_soli_cred = p_cod_soli_cred;
            COMMIT;
        END IF;

        p_ret_esta := 1;
        p_ret_mens := 'Se actualizaron los datos con éxito';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_ACTU_GEST_BANC', p_cod_usua_sid, 'Error al actualizar la solicitud de crédito'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_ACTU_GEST_BANC:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_ACTU_GEST_BANC', p_cod_usua_sid, 'Error al actualizar la solicitud de crédito'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;

    END sp_actu_gest_banc;

    PROCEDURE sp_update_cred_soli (
        p_cod_zona              IN                  vve_cred_soli.cod_zona%TYPE,
        p_cod_area_vta          IN                  vve_cred_soli.cod_area_vta%TYPE,
        p_vendedor              IN                  vve_cred_soli.vendedor%TYPE,
        p_cod_filial            IN                  vve_cred_soli.cod_filial%TYPE,
        p_cod_sucursal          IN                  vve_cred_soli.cod_sucursal%TYPE,
        p_cod_soli_cred         IN                  vve_cred_soli.cod_soli_cred%TYPE,
        p_cod_estado            IN                  vve_cred_soli.cod_estado%TYPE,
        p_cod_perso             IN                  VARCHAR2,
        p_num_prof_veh          IN                  VARCHAR2,
        p_num_telf_movil        IN                  VARCHAR2,
        p_dir_correo            IN                  VARCHAR2,
        p_obse_crea             IN                  VARCHAR2,
        p_tip_soli_cred         IN                  VARCHAR2,
        p_cod_resp_fina         IN                  VARCHAR2,
        p_can_plaz_mes          IN                  vve_cred_soli.can_plaz_mes%TYPE,
        p_cod_moneda_prof       IN                  VARCHAR2,
        p_val_vta_tot_fin       IN                  vve_cred_soli_prof.val_vta_tot_fin%TYPE,
        p_txt_obse_gest_banc    IN                  vve_cred_soli.txt_obse_gest_banc%TYPE,
        p_cod_esta_gest_banc    IN                  vve_cred_soli.cod_esta_gest_banc%TYPE,
        p_flag_actualiza        IN                  VARCHAR2,
        p_ven_factura           IN                  VARCHAR2, --Req. 87567 E1 ID 27 AVILCA 01/07/2020
        p_cod_banco             IN                  VARCHAR2, --Req. 87567 E1 ID 27 AVILCA 01/07/2020
        p_telf_fijo             IN                  VARCHAR2,
        p_cod_usua_sid          IN                  sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta              OUT                 NUMBER,
        p_ret_mens              OUT                 VARCHAR2
    ) AS
        ve_error EXCEPTION;
        v_txt_usuario VARCHAR2(20);
        v_cod_estado_actu VARCHAR(6);
        v_acti_conca VARCHAR2(5000):=NULL;
        v_sql_base_maes_acti   VARCHAR2(4000);
        c_actividades          SYS_REFCURSOR;
        v_ind_inactivo         VARCHAR2(1);
        v_cod_cred_soli_acti   VARCHAR2(20);
        --v_cod_acti_cred        vve_cred_maes_activ.cod_acti_cred%TYPE; <CC E2.1 ID224 LR 11.11.19>
        v_cod_acti_cred        vve_cred_maes_activ.cod_acti_cred%TYPE; --<CC E2.1 ID224 LR 11.11.19>
        v_ind_esta_aprob_jv    VARCHAR2(2);
        v_tipo_soli_cred       VARCHAR2(4);
        v_flag_jv              NUMBER(1); -- REQ 87567 MBARDALES 12/03/2021

    BEGIN

        IF p_flag_actualiza = 'GEST_BANC' THEN

            IF p_cod_esta_gest_banc = 'EEJV01' THEN
                v_cod_estado_actu:= 'ES02';
                v_ind_esta_aprob_jv:='A';
            ELSE
                v_cod_estado_actu:= 'ES06';
                v_ind_esta_aprob_jv:='R';
            END IF;

            UPDATE vve_cred_soli
            SET
               --//I Req. 87567 E2.1 ID:17 avilca 09/03/2021
                txt_obse_jv = p_txt_obse_gest_banc,
                cod_jefe_vtas_apro = p_cod_usua_sid,
                fec_jefe_vtas_apro = SYSDATE,
                ind_esta_aprob_jv = v_ind_esta_aprob_jv,
                fec_modi_regi = sysdate,
                cod_usua_modi = p_cod_usua_sid,
              --//F Req. 87567 E2.1 ID:17 avilca 09/03/2021
                cod_estado = v_cod_estado_actu
            WHERE
                cod_soli_cred = p_cod_soli_cred;
            COMMIT;

        ELSE

            --OBTENIENDO TIPO DE CRÉDITO ACTUAL DE LA SOLICITUD (ANTES DE CAMBIAR EL TIPO DE CRED)
            SELECT tip_soli_cred INTO v_tipo_soli_cred
            FROM vve_cred_soli
            WHERE cod_soli_cred = p_cod_soli_cred;

            v_txt_usuario := p_cod_resp_fina;

            UPDATE gen_persona
            SET
                dir_correo = p_dir_correo,
                num_telf_movil = p_num_telf_movil
            WHERE
                cod_perso = p_cod_perso;

            COMMIT;

            UPDATE gen_dir_perso
            SET
                num_telf_movil = p_num_telf_movil,
                num_telf1 = p_telf_fijo --Req. 87567 E1 ID 27 AVILCA 01/07/2020
            WHERE
                cod_perso = p_cod_perso;

            COMMIT;

            UPDATE vve_cred_soli
            SET
                -- ACTUALIZA MONTO
                val_mon_fin = p_val_vta_tot_fin,
                can_dias_fact_cred = p_ven_factura,
                txt_obse_crea = p_obse_crea,
                tip_soli_cred = p_tip_soli_cred,
                cod_resp_fina = v_txt_usuario,
                cod_anal_cred = v_txt_usuario, --Req. 87567 E2.2 MBARDALES 12/03/2021
                can_plaz_mes = p_can_plaz_mes,
                cod_estado = p_cod_estado,
                cod_banco = p_cod_banco,--Req. 87567 E1 ID 27 AVILCA 01/07/2020
                val_mont_sol_gest_banc = p_val_vta_tot_fin, --Req. 87567 E1 ID 27 AVILCA 29/01/2021
                cod_usua_modi = p_cod_usua_sid,
                fec_modi_regi = to_date(SYSDATE,'DD/MM/YYYY')--Req. 87567 E1 ID 27 AVILCA 01/07/2020
            WHERE
                cod_soli_cred = p_cod_soli_cred;
            COMMIT;

            --<I Req. 87567 E2.2 ID## MBARDALES 12/03/2021>
            IF p_tip_soli_cred = 'TC05' THEN
              UPDATE vve_cred_soli
              SET
                  cod_area_vta = p_cod_area_vta,
                  cod_zona = p_cod_zona,
                  cod_filial = p_cod_filial,
                  vendedor = p_vendedor,
                  cod_sucursal = p_cod_sucursal,
                  cod_usua_modi = p_cod_usua_sid,
                  fec_modi_regi = to_date(SYSDATE,'DD/MM/YYYY')--Req. 87567 E1 ID 27 AVILCA 01/07/2020
              WHERE
                  cod_soli_cred = p_cod_soli_cred;
              COMMIT;
            END IF;
            --<F Req. 87567 E2.2 ID## MBARDALES 12/03/2021>

            UPDATE vve_proforma_veh
            SET
                cod_moneda_prof = p_cod_moneda_prof
            WHERE
                num_prof_veh = p_num_prof_veh;
            COMMIT;

            UPDATE vve_cred_soli_prof
            SET
                val_vta_tot_fin = p_val_vta_tot_fin,
                cod_usua_modi_reg = p_cod_usua_sid,
                fec_modi_reg =  to_date(SYSDATE,'DD/MM/YYYY')--Req. 87567 E1 ID 27 AVILCA 01/07/2020
            WHERE
                cod_soli_cred = p_cod_soli_cred;
            COMMIT;

            IF p_tip_soli_cred IS NOT NULL THEN

             --<I Req. 87567 E2.1 ID 33 AVILCA 06/08/2020>

            --EJECUTA CAMBIOS EN ACTIVIDADES SÓLO SI SE CAMBIA EL TIPO DE CRÉDITO
              IF v_tipo_soli_cred <> p_tip_soli_cred THEN

                -- ELIMINAR ACTIVIDADES CON fec_usua_ejec NULL
                DELETE FROM vve_cred_soli_acti WHERE cod_soli_cred = p_cod_soli_cred AND fec_usua_ejec IS NULL AND cod_usua_ejec IS NULL;
                COMMIT;

                -- CONCATENAR ACTIVIDADES RESTANTES
                FOR rs IN (SELECT cod_acti_cred FROM vve_cred_soli_acti
                                WHERE cod_soli_cred = p_cod_soli_cred AND fec_usua_ejec IS NOT NULL AND cod_usua_ejec IS NOT NULL) LOOP

                    IF v_acti_conca IS NULL THEN
                        v_acti_conca := rs.cod_acti_cred;
                    ELSE
                        v_acti_conca := v_acti_conca || ',' || rs.cod_acti_cred;
                    END IF;

                END LOOP;

                dbms_output.put_line(v_acti_conca);

                --<I CC E2.1 ID224 LR 11.11.19>
                v_sql_base_maes_acti := 'SELECT ma.COD_ACTI_CRED, atc.IND_OBLIG
                                         FROM  vve_cred_maes_activ ma, vve_cred_acti_tipo_cred atc
                                         WHERE ma.cod_acti_cred = atc.cod_acti_cred
                                         AND atc.cod_tipo_cred ='''||p_tip_soli_cred||'''
                                         AND ma.ind_inactivo = ''N''
                                         AND atc.ind_inactivo = ''N''
                                         AND ma.COD_ACTI_CRED NOT IN
                                              (SELECT column_value FROM TABLE (fn_varchar_to_table(''' || trim(v_acti_conca) || ''')))
                                         ORDER BY ma.num_orden';



                --<F CC E2.1 ID224 LR 11.11.19>
                dbms_output.put_line(v_sql_base_maes_acti);

                OPEN c_actividades FOR v_sql_base_maes_acti;
                LOOP
                    FETCH c_actividades INTO v_cod_acti_cred, v_ind_inactivo;
                    EXIT WHEN c_actividades%notfound;
                    BEGIN
                        SELECT
                            lpad(nvl(MAX(cod_cred_soli_acti), 0) + 1, 20, '0')
                        INTO v_cod_cred_soli_acti
                        FROM
                            vve_cred_soli_acti;

                    EXCEPTION
                        WHEN OTHERS THEN
                            v_cod_cred_soli_acti := '1';
                    END;

                    INSERT INTO vve_cred_soli_acti (
                        cod_cred_soli_acti,
                        cod_acti_cred,
                        cod_soli_cred,
                        cod_usua_crea_reg,
                        cod_usua_ejec,
                        fec_crea_reg,
                        ind_inactivo
                    ) VALUES (
                        v_cod_cred_soli_acti,
                        v_cod_acti_cred,
                        p_cod_soli_cred,
                        p_cod_usua_sid, -- REQ. 87567 E.2.2 12/03/2021 MBARDALES SE CAMBIO EL ORDEN DEL SETEO DEL cod_usua_crea_reg, cod_usua_ejec (EL cod_usua_ejec DEBE SER NULL)
                        NULL, --< Req. 87567 E2.1 ID 33 AVILCA 06/08/2020>
                        SYSDATE,
                        DECODE(v_ind_inactivo,'S','N','S')
                    );
                    COMMIT;

                END LOOP;

                CLOSE c_actividades;
               END IF;
               --<F Req. 87567 E2.1 ID 33 AVILCA 06/08/2020>
            END IF;


        END IF;

        p_ret_esta := 1;
        -- p_ret_mens := 'Se actualizaron los datos con éxito';
        p_ret_mens := p_val_vta_tot_fin;

        --<I Req. 87567 E2.2 ID## MBARDALES 12/03/2021>
        BEGIN
          SELECT count(*) INTO v_flag_jv FROM sis_mae_perfil_usuario where cod_id_perfil IN (select val_para_num from vve_cred_soli_para where cod_cred_soli_para = 'BJV') and ind_inactivo = 'N'
          and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid);
        EXCEPTION WHEN NO_DATA_FOUND THEN
        v_flag_jv := 0;
        END;

        IF v_flag_jv = 1 THEN
          -- ACtualizando fecha de ejecución de registro y verificando cierre de etapa
          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E1','A2',p_cod_usua_sid,p_ret_esta,p_ret_mens);
          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E1','A3',p_cod_usua_sid,p_ret_esta,p_ret_mens);
        END IF;
        --<F Req. 87567 E2.2 ID## MBARDALES 12/03/2021>

        --<I Req. 87567 E2.1 ID## avilca 01/12/2020>
        --PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E1','A4',p_cod_usua_sid,p_ret_esta,p_ret_mens);
        --<F Req. 87567 E2.1 ID## avilca 01/12/2020>

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_UPDATE_CRED_SOLI', p_cod_usua_sid, 'Error al actualizar la solicitud de crédito'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_UPDATE_CRED_SOLI:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_UPDATE_CRED_SOLI', p_cod_usua_sid, 'Error al actualizar la solicitud de crédito'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
    END sp_update_cred_soli;


/*Inicio requerimiento 90690 ebarboza 13 08 2020*/
PROCEDURE SP_IS_SOLI_APRO (

p_cod_soli_cred        IN                VARCHAR2,
    p_num_prof              IN         VARCHAR2,
    p_cod_usuario          IN                sistemas.usuarios.co_usuario%TYPE,
    p_id_usuario          IN         VARCHAR2,
    p_ret_cursor           OUT               SYS_REFCURSOR,
    p_ret_esta             OUT               NUMBER,
    p_ret_mens             OUT               VARCHAR2
) AS
    ve_error EXCEPTION;

BEGIN

OPEN p_ret_cursor FOR
  SELECT pro.num_prof_veh,
        pro.cod_moneda_prof,
        fic.num_ficha_vta_veh,
        fic.ind_inactivo, --ncoqchi 01sep2019
        gp.nom_perso,
        gp.cod_estado_civil,
        gp.cod_tipo_perso,
        CASE
            WHEN gp.cod_tipo_perso = 'J' THEN 'Jurídica' ELSE 'Natural'
        END AS tipo_perso,
        gp.ind_mancomunado,
        gp.num_docu_iden,
        gp.num_ruc,
        gp.dir_correo,
        gp.num_telf_movil,
        UPPER((SELECT descripcion FROM arccve WHERE vendedor = pro.vendedor)) AS vendedor,
        (select round((val_pre_veh * can_veh), 2) from vve_proforma_veh_det where num_prof_veh = pro.num_prof_veh) as val_vta_prof,
        (select cod_soli_cred from vve_cred_soli_prof where num_prof_veh like '%p_num_prof%' and rownum = 1) as cod_soli_cred
        FROM vve_proforma_veh pro
        INNER JOIN vve_ficha_vta_proforma_veh fic ON pro.num_prof_veh = fic.num_prof_veh
        INNER JOIN gen_persona gp ON gp.cod_perso = pro.cod_clie
        WHERE  pro.num_prof_veh like '%p_num_prof%';

        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';

EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_PROFORMA', p_id_usuario, 'Error en la consulta', p_ret_mens
        , NULL);
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LIST_PROFORMA:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_PROFORMA', p_id_usuario, 'Error en la consulta', p_ret_mens
        , NULL);
END SP_IS_SOLI_APRO;

/*Fin requerimiento 90690 ebarboza 13 058 2020*/

PROCEDURE sp_list_proforma (

p_cod_clie        IN                VARCHAR2,
p_num_prof_veh     IN         VARCHAR2,
p_cod_usua_sid    IN                sistemas.usuarios.co_usuario%TYPE,
p_ret_cursor      OUT               SYS_REFCURSOR,
p_ret_esta        OUT               NUMBER,
p_ret_mens        OUT               VARCHAR2
) AS
    ve_error EXCEPTION;

BEGIN

OPEN p_ret_cursor FOR
  SELECT pro.num_prof_veh,
        pro.cod_moneda_prof,
        fic.num_ficha_vta_veh,
        fic.ind_inactivo, --ncoqchi 01sep2019
        gp.nom_perso,
        gp.cod_estado_civil,
        gp.cod_tipo_perso,
        CASE
            WHEN gp.cod_tipo_perso = 'J' THEN 'Jurídica' ELSE 'Natural'
        END AS tipo_perso,
        gp.ind_mancomunado,
        gp.num_docu_iden,
        gp.num_ruc,
        gp.dir_correo,
        gp.num_telf_movil,
        UPPER((SELECT descripcion FROM arccve WHERE vendedor = pro.vendedor)) AS vendedor,
        (select round((val_pre_veh * can_veh), 2) from vve_proforma_veh_det where num_prof_veh = pro.num_prof_veh) as val_vta_prof,
        (select cod_soli_cred from vve_cred_soli_prof where num_prof_veh = p_num_prof_veh and rownum = 1) as cod_soli_cred
        FROM vve_proforma_veh pro
        INNER JOIN vve_ficha_vta_proforma_veh fic ON pro.num_prof_veh = fic.num_prof_veh
        INNER JOIN gen_persona gp ON gp.cod_perso = pro.cod_clie
        WHERE pro.cod_clie = p_cod_clie AND pro.num_prof_veh = p_num_prof_veh;

        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';

EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_PROFORMA', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
        , NULL);
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LIST_PROFORMA:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_PROFORMA', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
        , NULL);
END sp_list_proforma;


PROCEDURE sp_list_cred_soli (
    p_cod_soli_cred IN vve_cred_soli.cod_soli_cred%TYPE,
    p_num_prof_veh  IN vve_cred_soli_prof.num_prof_veh%TYPE,
    p_fec_ini       IN VARCHAR2,
    p_fec_fin       IN VARCHAR2,
    p_cod_area_vta  IN VARCHAR2,
    p_tip_soli_cred IN VARCHAR2,
    p_cod_clie      IN vve_cred_soli.cod_clie%TYPE,
    p_cod_pers_soli IN vve_cred_soli.cod_pers_soli%TYPE,
    p_cod_resp_fina IN vve_cred_soli.cod_resp_fina%TYPE,
    p_cod_estado    IN vve_cred_soli.cod_estado%TYPE,
    p_cod_empr      IN VARCHAR2,
    p_cod_zona      IN VARCHAR2,
    p_ruc_cliente   IN VARCHAR2,
    p_cod_usua_sid  IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web  IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ind_paginado  IN VARCHAR2,
    p_limitinf      IN INTEGER,
    p_limitsup      IN INTEGER,
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_cantidad      OUT NUMBER,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR2
) AS
    ve_error            EXCEPTION;
    ln_limitinf         NUMBER := 0;
    ln_limitsup         NUMBER := 0;
    p_cod_pers_soli_aux VARCHAR2(20);
    p_cod_resp_fina_aux VARCHAR2(20);
    v_cod_soli_cred     VARCHAR2(20);
    v_cod_soli_cred2     VARCHAR2(20);
    v_num_prof_veh      VARCHAR2(10);
    v_perf_asesor       vve_cred_soli_para.val_para_car%type;
    v_perf_jv           vve_cred_soli_para.val_para_car%type;
    v_perf_ges_fin      vve_cred_soli_para.val_para_car%type;
    v_perf_consulta     vve_cred_soli_para.val_para_car%type;

BEGIN
    IF p_ind_paginado = 'N' THEN
        SELECT COUNT(1)
            INTO ln_limitsup
        FROM vve_cred_soli;
    ELSE
        ln_limitinf := p_limitinf - 1;
        ln_limitsup := p_limitsup;
    END IF;

    IF p_cod_pers_soli IS NOT NULL THEN
        SELECT txt_usuario
            INTO p_cod_pers_soli_aux
        FROM sis_mae_usuario
        WHERE cod_id_usuario = p_cod_pers_soli;
    ELSE
        --p_cod_pers_soli_aux := p_cod_usua_sid;--<I Req. 87567 E2.1 ID## avilca 27/01/2021>
        p_cod_pers_soli_aux := NULL;--<I Req. 87567 E2.1 ID## avilca 27/01/2021>
    END IF;

    IF p_cod_resp_fina IS NOT NULL THEN
        SELECT txt_usuario
            INTO p_cod_resp_fina_aux
        FROM sis_mae_usuario
        WHERE cod_id_usuario = p_cod_resp_fina;
    ELSE
        p_cod_resp_fina_aux := NULL;
    END IF;

    SELECT val_para_car
      INTO v_perf_asesor
      FROM vve_cred_soli_para
     WHERE cod_cred_soli_para = 'ROLPERFASE';

    SELECT val_para_car
      INTO v_perf_jv
      FROM vve_cred_soli_para
     WHERE cod_cred_soli_para = 'ROLPERJV';

     SELECT val_para_car
      INTO v_perf_ges_fin
      FROM vve_cred_soli_para
     WHERE cod_cred_soli_para = 'ROLGESCRED';

     SELECT val_para_car
      INTO v_perf_consulta
      FROM vve_cred_soli_para
     WHERE cod_cred_soli_para = 'ROLCONSOTR';

    OPEN p_ret_cursor FOR
        SELECT *
        FROM
        (
            SELECT
               sc.cod_soli_cred,
               sc.txt_obse_crea,
               sc.can_plaz_mes,
               gav.cod_area_vta,
               gav.des_area_vta,
               TO_CHAR(sc.fec_soli_cred, 'DD/MM/YYYY') AS fec_soli_cred,
               (select des_zona from vve_mae_zona_filial f inner join vve_mae_zona z on (f.cod_zona = z.cod_zona)
               where cod_filial = (
                    SELECT pv.cod_filial
                    FROM vve_cred_soli_prof sp
                    INNER JOIN vve_proforma_veh pv
                        ON pv.num_prof_veh = sp.num_prof_veh
                    INNER JOIN vve_proforma_veh_det pd
                        ON sp.num_prof_veh = pd.num_prof_veh
                    WHERE cod_soli_cred = sc.cod_soli_cred
                        AND rownum = 1)
               ) as region,
              --I Req. 87567 E2.1 ID 25 AVILCA 22/05/2020
               CASE
                   WHEN sc.tip_soli_cred <> 'TC05' AND sc.tip_soli_cred <> 'TC07' THEN
                      ( SELECT mz.des_zona
                        FROM vve_cred_soli_prof sp
                            INNER JOIN vve_proforma_veh pv
                                ON pv.num_prof_veh = sp.num_prof_veh
                            INNER JOIN vve_proforma_veh_det pd
                                ON sp.num_prof_veh = pd.num_prof_veh
                            INNER JOIN vve_mae_zona_filial mzf
                                ON mzf.cod_filial = pv.cod_filial
                            INNER JOIN vve_mae_zona mz
                                ON mz.cod_zona = mzf.cod_zona
                        WHERE sp.cod_soli_cred = p_cod_soli_cred
                        AND rownum = 1)
                   ELSE null
                END as nombre_zona,
               CASE
                   WHEN sc.tip_soli_cred <> 'TC05' AND sc.tip_soli_cred <> 'TC07' THEN
                      ( SELECT mz.cod_zona
                        FROM vve_cred_soli_prof sp
                            INNER JOIN vve_proforma_veh pv
                                ON pv.num_prof_veh = sp.num_prof_veh
                            INNER JOIN vve_proforma_veh_det pd
                                ON sp.num_prof_veh = pd.num_prof_veh
                            INNER JOIN vve_mae_zona_filial mzf
                                ON mzf.cod_filial = pv.cod_filial
                            INNER JOIN vve_mae_zona mz
                                ON mz.cod_zona = mzf.cod_zona
                        WHERE sp.cod_soli_cred = p_cod_soli_cred
                        AND rownum = 1)
                   ELSE null
                END as cod_zona,
                CASE
                   WHEN sc.tip_soli_cred <> 'TC05' AND sc.tip_soli_cred <> 'TC07' THEN
                      (SELECT gs.nom_sucursal
                        FROM vve_cred_soli_prof sp
                           INNER JOIN vve_proforma_veh pv
                            ON pv.num_prof_veh = sp.num_prof_veh
                           INNER JOIN vve_proforma_veh_det pd
                            ON sp.num_prof_veh = pd.num_prof_veh
                           INNER JOIN  gen_sucursales gs
                            ON gs.cod_sucursal = pv.cod_sucursal
                        WHERE sp.cod_soli_cred = p_cod_soli_cred
                        AND rownum = 1 )
                   ELSE null
                END as nombre_sucursal,
               CASE
                   WHEN sc.tip_soli_cred <> 'TC05' AND sc.tip_soli_cred <> 'TC07' THEN
                      (SELECT pv.cod_sucursal
                        FROM vve_cred_soli_prof sp
                         INNER JOIN vve_proforma_veh pv
                          ON pv.num_prof_veh = sp.num_prof_veh
                         INNER JOIN vve_proforma_veh_det pd
                          ON sp.num_prof_veh = pd.num_prof_veh
                       WHERE cod_soli_cred = p_cod_soli_cred
                        AND rownum = 1)
                   ELSE null
                END as cod_sucursal,
                CASE
                   WHEN sc.tip_soli_cred <> 'TC05' AND sc.tip_soli_cred <> 'TC07' THEN
                      ( SELECT v.descripcion
                        FROM vve_cred_soli_prof sp
                            INNER JOIN vve_proforma_veh pv
                                ON pv.num_prof_veh = sp.num_prof_veh
                            INNER JOIN vve_proforma_veh_det pd
                                ON sp.num_prof_veh = pd.num_prof_veh
                            INNER JOIN  arccve v
                                ON v.vendedor = pv.vendedor
                        WHERE sp.cod_soli_cred = p_cod_soli_cred
                        AND rownum = 1     )
                   ELSE null
                END as nombre_vendedor,
             CASE
                   WHEN sc.tip_soli_cred <> 'TC05' AND sc.tip_soli_cred <> 'TC07' THEN
                      (SELECT pv.vendedor
                       FROM vve_cred_soli_prof sp
                            INNER JOIN vve_proforma_veh pv
                                ON pv.num_prof_veh = sp.num_prof_veh
                            INNER JOIN vve_proforma_veh_det pd
                                ON sp.num_prof_veh = pd.num_prof_veh
                       WHERE sp.cod_soli_cred = p_cod_soli_cred
                        AND rownum = 1)
                   ELSE null
                END as cod_vendedor,
                CASE
                   WHEN sc.tip_soli_cred <> 'TC05' AND sc.tip_soli_cred <> 'TC07' THEN
                      ( SELECT gf.nom_filial
                        FROM vve_cred_soli_prof sp
                            INNER JOIN vve_proforma_veh pv
                                ON pv.num_prof_veh = sp.num_prof_veh
                            INNER JOIN vve_proforma_veh_det pd
                                ON sp.num_prof_veh = pd.num_prof_veh
                            INNER JOIN  gen_filiales gf
                                ON gf.cod_filial = pv.cod_filial
                        WHERE sp.cod_soli_cred = p_cod_soli_cred
                        AND rownum = 1 )
                   ELSE null
                END as nombre_filial,
               CASE
                   WHEN sc.tip_soli_cred <> 'TC05' AND sc.tip_soli_cred <> 'TC07' THEN
                      ( SELECT pv.cod_filial
                         FROM vve_cred_soli_prof sp
                            INNER JOIN vve_proforma_veh pv
                                ON pv.num_prof_veh = sp.num_prof_veh
                            INNER JOIN vve_proforma_veh_det pd
                                ON sp.num_prof_veh = pd.num_prof_veh
                        WHERE sp.cod_soli_cred = p_cod_soli_cred
                        AND rownum = 1)
                   ELSE null
                END as cod_filial,
          --F Req. 87567 E2.1 ID 25 AVILCA 22/05/2020
               sc.cod_clie,
               gp.nom_perso,
               gp.cod_estado_civil,
               gp.cod_tipo_perso,
               CASE
                   WHEN gp.cod_tipo_perso = 'J' THEN 'Jurídica'
                   ELSE 'Natural'
               END AS tipo_perso,
               gp.ind_mancomunado,
               gp.num_docu_iden,
               gp.num_ruc,
               gp.dir_correo,
               gp.num_telf_movil,
               gdp.num_telf1,
               sc.tip_soli_cred,
               tc.descripcion   AS des_tipo_soli_cred,
               sc.cod_estado,
               tc.descripcion,
               UPPER(sce.descripcion) AS des_estado,
               TO_CHAR(sc.fec_apro_clie, 'DD/MM/YYYY') AS fec_apro_clie,
               --(SELECT ma.des_acti_cred FROM vve_cred_soli_acti vc2 INNER JOIN vve_cred_maes_acti ma <CC E2.1 ID224 LR 11.11.19>
               (SELECT ma.des_acti_cred FROM vve_cred_soli_acti vc2 INNER JOIN vve_cred_maes_activ ma --<CC E2.1 ID224 LR 11.11.19>
               ON (vc2.cod_acti_cred=ma.cod_acti_cred) WHERE vc2.cod_soli_cred=sc.cod_soli_cred
               AND vc2.cod_cred_soli_acti = (SELECT MAX(vc1.cod_cred_soli_acti) FROM vve_cred_soli_acti vc1
               WHERE vc1.cod_soli_cred=sc.cod_soli_cred AND vc1.fec_usua_ejec IS NOT NULL)) AS act_actual,
               (select cod_id_usuario from sis_mae_usuario where txt_usuario = sc.cod_pers_soli) AS cod_pers_soli,
               (select UPPER(paterno || ' ' || materno || ' ' || nombre1) from usuarios where co_usuario = sc.cod_pers_soli) AS des_pers_soli,
               sc.cod_resp_fina,
               (select UPPER(paterno || ' ' || materno || ' ' || nombre1) from usuarios where co_usuario = sc.cod_resp_fina) AS des_resp_fina,
               sc.cod_empr,
               em.nombre AS des_nom_empr,
               (
                    SELECT sp.num_prof_veh
                    FROM vve_cred_soli_prof sp
                    INNER JOIN vve_proforma_veh pv
                        ON pv.num_prof_veh = sp.num_prof_veh
                    INNER JOIN vve_proforma_veh_det pd
                        ON sp.num_prof_veh = pd.num_prof_veh
                    WHERE cod_soli_cred = sc.cod_soli_cred
                        AND rownum = 1
               ) num_prof_veh,
               (
                   --<I Req. 87567 E2.1 ID 160 avilca 08/08/2020>

                 SELECT SUM(sp.val_vta_tot_fin)
                    FROM vve_cred_soli_prof sp
                    INNER JOIN vve_proforma_veh pv
                        ON pv.num_prof_veh = sp.num_prof_veh
                    INNER JOIN vve_proforma_veh_det pd
                        ON sp.num_prof_veh = pd.num_prof_veh
                    WHERE sp.cod_soli_cred = sc.cod_soli_cred
                    and sp.ind_inactivo = 'N'
              --<F Req. 87567 E2.1 ID 160 avilca 08/08/2020>
               )
               val_vta_tot_fin,
               (
                    SELECT pv.cod_moneda_prof
                    FROM vve_cred_soli_prof sp
                    INNER JOIN vve_proforma_veh pv
                        ON pv.num_prof_veh = sp.num_prof_veh
                    INNER JOIN vve_proforma_veh_det pd
                        ON sp.num_prof_veh = pd.num_prof_veh
                    WHERE cod_soli_cred = sc.cod_soli_cred
                        AND rownum = 1
               )
               cod_moneda_prof,
               (
                   SELECT
                       descripcion
                   FROM
                       arccve
                   WHERE
                       vendedor = (SELECT pv.vendedor
                                   FROM vve_cred_soli_prof sp
                                   INNER JOIN vve_proforma_veh pv
                                        ON pv.num_prof_veh = sp.num_prof_veh
                                   INNER JOIN vve_proforma_veh_det pd
                                        ON sp.num_prof_veh = pd.num_prof_veh
                                   WHERE cod_soli_cred = sc.cod_soli_cred
                                        AND rownum = 1)
               ) AS vendedor,
               (
                    SELECT vpv.num_ficha_vta_veh
                    FROM vve_cred_soli_prof sp
                    INNER JOIN vve_ficha_vta_proforma_veh vpv
                        ON vpv.num_prof_veh = sp.num_prof_veh
                            AND vpv.ind_inactivo = 'N'
                    WHERE cod_soli_cred = sc.cod_soli_cred
                        AND rownum = 1
               )
               num_ficha_vta_veh,
               sc.cod_banco,
               sc.val_mon_fin as monto_sol_cred,
               sc.val_mont_sol_gest_banc,
               sc.val_porc_gest_banc,
               sc.fec_ingr_gest_banc,
               sc.fec_ingr_ries_gest_banc,
               sc.fec_aprob_cart_ban,
               sc.fec_resu_gest_banc,
               sc.cod_esta_gest_banc,
               sc.txt_obse_gest_banc,
               DECODE(sc.tip_soli_cred,'TC03','S',DECODE(sc.tip_soli_cred,'TC02','S',DECODE(sc.tip_soli_cred,'TC06','S','N'))) AS ind_pago_contado,
               DECODE(sc.cod_estado,'ES03','S',decode(sc.cod_estado,'ES07','S','N')) AS ind_cred_aprobado,
               DECODE(sc.tip_soli_cred,'TC04','S','N') AS ind_bloqueo_pestanias,
               DECODE(sc.tip_soli_cred,'TC04','S',decode(sc.cod_estado,'TC05','S','N')) AS ind_cred_vehi,
               DECODE(sc.tip_soli_cred,'TC06','S','N') AS ind_gest_banc,
               CASE
                    WHEN sc.cod_esta_gest_banc = 'EGB02' THEN 'RI' --Riesgo
                    WHEN sc.cod_esta_gest_banc = 'EGB03' THEN 'AT' --Aprobado Total
                    WHEN sc.cod_esta_gest_banc = 'EGB04' THEN 'AP' --Aprobado Parcial
                    WHEN sc.cod_esta_gest_banc = 'EGB05' THEN 'RE' --Rechazado
                    ELSE 'IN' --Si es nulo o Ingresado
               END AS esta_gest_banc,
               (
                    SELECT SUM(can_veh_fin)
                    FROM vve_cred_soli_prof
                    WHERE cod_soli_cred = sc.cod_soli_cred
                    AND ind_inactivo = 'N'-- //< Req. 87567 E2.1 ID 112 AVILCA 27/07/2020>
               )
               can_veh_fin,
               (
                    SELECT pd.val_pre_veh
                    FROM vve_cred_soli_prof sp
                    INNER JOIN vve_proforma_veh pv
                        ON pv.num_prof_veh = sp.num_prof_veh
                    INNER JOIN vve_proforma_veh_det pd
                        ON sp.num_prof_veh = pd.num_prof_veh
                    WHERE cod_soli_cred = sc.cod_soli_cred
                        AND rownum = 1
               )
               val_pre_veh,
               (select porcentaje from arcgiv where clave = '01' and no_cia = sc.cod_empr) as igv,
               (select porcentaje from arcgiv where clave = '03' and no_cia = sc.cod_empr) as ir,
               (select val_para_num from vve_cred_soli_para where cod_cred_soli_para = 'ADEPVEH') as val_para_num,
               sc.cod_oper_rel,
               sc.cod_oper_orig,
               sc.val_porc_ci,
               sc.val_ci,
               sc.val_pago_cont_ci,
               TO_CHAR(sc.fec_venc_1ra_let, 'DD/MM/YYYY') as fecVenc1raLet,
               sc.can_dias_venc_1ra_letr,
               sc.cod_peri_cred_soli,
               sc.can_tota_letr,
               sc.ind_tipo_peri_grac,
               sc.val_dias_peri_grac,
               sc.can_letr_peri_grac,
               sc.val_int_per_gra,
               sc.val_porc_tea_sigv,
               sc.val_porc_tep_sigv,
               sc.ind_gps,
               sc.val_porc_cuot_ball,
               sc.val_cuot_ball,
               sc.ind_tipo_segu,
               sc.cod_cia_seg,
               sc.cod_tip_uso_veh,
               sc.val_tasa_segu,
               sc.val_prim_seg,
               sc.cod_tipo_unid,
               sc.val_porc_gast_admi,
               sc.val_gasto_admi,
               (select substr(cod_clie_sap, 4, 8) from gen_dir_perso where cod_perso = sc.cod_clie and ind_inactivo = 'N' and ind_dir_defecto = 'S') as cod_clie_sap,
               (select tipo_cambio from arcgtc where clase_cambio = '02' and fecha = trunc(sysdate)) as tipo_cambio,
               DECODE(sc.cod_estado,'ES06','S','N') AS ind_cred_recha,
               (SELECT TO_CHAR(MAX(l.fec_venc), 'DD/MM/YYYY')
                FROM vve_cred_simu s
                INNER JOIN vve_cred_simu_letr l
                    ON s.cod_simu = l.cod_simu
                WHERE s.cod_soli_cred = sc.cod_soli_cred
                    AND s.ind_inactivo = 'N') as fec_ulti_venc,
               (SELECT s.txt_otr_cond
                FROM vve_cred_simu s
                WHERE s.cod_soli_cred = sc.cod_soli_cred
                    AND s.ind_inactivo = 'N') as txt_otr_cond,
               sc.can_dias_fact_cred,
               sc.txt_obse_jv,
               sc.val_tc, --//<I Req. 87567 E2.1 ID 98 AVILCA 20/07/2020>
               --//<I Req. 87567 E2.1 ID 112 AVILCA 27/07/2020>
              (
                SELECT count(*)
                FROM vve_cred_soli_gara
                WHERE cod_soli_cred = sc.cod_soli_cred
                AND ind_inactivo = 'N'--Req. 87567 E2.1  avilca 25/09/2020
               )
               can_gara_soli
             -- //<F Req. 87567 E2.1 ID 112 AVILCA 27/07/2020>
            FROM
               vve_cred_soli sc
               INNER JOIN arcgmc em ON em.no_cia = sc.cod_empr
               INNER JOIN gen_persona gp ON gp.cod_perso = sc.cod_clie
               INNER JOIN gen_dir_perso gdp ON gdp.cod_perso = sc.cod_clie
               INNER JOIN gen_area_vta gav ON gav.cod_area_vta = sc.cod_area_vta
               LEFT JOIN vve_tabla_maes tc ON sc.tip_soli_cred = tc.cod_tipo
                                              AND tc.cod_grupo_rec = '86'
                                              AND tc.cod_tipo_rec = 'TC'
               LEFT JOIN vve_tabla_maes sce ON sc.cod_estado = sce.cod_tipo
                                               AND sce.cod_grupo_rec = '92'
                                               AND sce.cod_tipo_rec = 'ES'
            WHERE
               (p_cod_soli_cred IS NULL OR sc.cod_soli_cred like '%'||p_cod_soli_cred||'%')
               AND (p_num_prof_veh IS NULL OR EXISTS(
                SELECT 'X'
                FROM vve_cred_soli_prof sp
                WHERE sp.cod_soli_cred = sc.cod_soli_cred
                    AND sp.num_prof_veh like '%'||p_num_prof_veh||'%'
                )
               )
               AND ( ( p_fec_ini IS NULL
                       AND p_fec_fin IS NULL )
                     OR trunc(sc.fec_soli_cred) BETWEEN TO_DATE(p_fec_ini, 'DD/MM/YYYY') AND TO_DATE(p_fec_fin
                     , 'DD/MM/YYYY') )
               AND ( p_cod_area_vta IS NULL
                     OR sc.cod_area_vta IN (
                   SELECT column_value
                   FROM TABLE(fn_varchar_to_table(p_cod_area_vta))
               ) )
               AND ( p_tip_soli_cred IS NULL
                     OR sc.tip_soli_cred IN (
                   SELECT column_value
                   FROM TABLE(fn_varchar_to_table(p_tip_soli_cred))
               ) )
               AND ( p_cod_clie IS NULL
                     OR sc.cod_clie = p_cod_clie )
               AND ((
                     exists (select 1 from sis_mae_perfil_usuario
                                      where 0< (select instr(val_para_car,cod_id_perfil)
                                                from vve_cred_soli_para
                                                where cod_cred_soli_para = 'ROLCONSOTR')
                                        and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid)
                            )
                      AND (p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado )
                    )--falso
                    OR
                    (( (  p_cod_pers_soli_aux IS NULL
                         OR p_cod_pers_soli_aux = p_cod_usua_sid
                       )  AND (sc.cod_pers_soli = p_cod_usua_sid)
                      AND exists (select 1 from sis_mae_perfil_usuario where cod_id_perfil = v_perf_asesor and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))

                      --AND v_perf_asesor IN (select cod_id_perfil from sis_mae_perfil_usuario where cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
    --***                  AND (p_cod_estado IS NULL  OR p_cod_estado IN ('ES01','ES02'))
                      AND (p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado )
                     )
                     OR ((p_cod_pers_soli_aux IS NULL OR sc.cod_pers_soli = p_cod_pers_soli_aux)
                          AND ( sc.cod_soli_cred in (select cod_soli_cred
                                                      from   vve_cred_soli_prof sp, vve_proforma_veh p, vve_mae_zona_filial zf
                                                      where  p.num_prof_veh = sp.num_prof_veh
                                                      and    p.cod_area_vta = sc.cod_area_vta
                                                      and    p.cod_filial = zf.cod_filial
                                                      and   (p.cod_filial,p.cod_area_vta,zf.cod_zona) in ( select cod_filial,cod_area_vta,cod_zona
                                                                                                           from   vve_cred_org_cred_vtas
                                                                                                           where  co_usuario = p_cod_usua_sid
                                                                                                           and    cod_rol_usuario = v_perf_jv)
                                                    )
               --            AND (p_cod_estado IS NULL OR sc.cod_estado IN ('ES01'))
                          AND (p_cod_estado IS NULL OR sc.cod_estado = p_cod_estado)
                          )
                        )
                    )
               OR (
                    ( (p_cod_resp_fina_aux IS NULL  OR p_cod_resp_fina_aux = p_cod_usua_sid)
                       AND sc.cod_resp_fina = p_cod_usua_sid
                       AND exists (select 1 from sis_mae_perfil_usuario where cod_id_perfil = v_perf_ges_fin and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                       AND sc.cod_estado NOT IN ('ES01','ES08')
                       AND (--(p_cod_estado IS NULL AND sc.cod_estado = 'ES03') OR
                            ( p_cod_estado IS NULL OR sc.cod_estado = p_cod_estado ))
                       )
                     OR ((p_cod_resp_fina_aux IS NULL OR sc.cod_resp_fina = p_cod_pers_soli_aux)
                          AND sc.cod_estado NOT IN ('ES01','ES08')
                          AND (--(p_cod_estado IS NULL AND sc.cod_estado = 'ES03') OR
                               ( p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado ))
                          AND ( sc.cod_soli_cred in (  select cod_soli_cred
                                                        from   vve_cred_soli_prof sp, vve_proforma_veh p, vve_mae_zona_filial zf
                                                        where  p.num_prof_veh = sp.num_prof_veh
                                                        and    p.cod_filial = zf.cod_filial
                                                        and   (p.cod_filial,p.cod_area_vta,zf.cod_zona) in ( select cod_filial,cod_area_vta,cod_zona
                                                                                                             from   vve_cred_org_cred_vtas
                                                                                                             where  co_usuario = p_cod_usua_sid
                                                                                                             and    0< (select instr(val_para_car,cod_rol_usuario)
                                                                                                                                          from vve_cred_soli_para
                                                                                                                                         where cod_cred_soli_para = 'ROLJEFES'))
                                                        )
                          )
                        )
                    )
                )
             -- AND ( p_cod_estado IS NULL
             --       OR sc.cod_estado = p_cod_estado )
               AND ( p_cod_empr IS NULL
                     OR sc.cod_empr IN (
                   SELECT column_value
                   FROM TABLE(fn_varchar_to_table(p_cod_empr))
               ))
               AND (p_cod_zona IS NULL OR EXISTS(
                    SELECT 'X'
                    FROM vve_mae_zona_filial f
                    INNER JOIN vve_mae_zona z
                        ON f.cod_zona = z.cod_zona
                    WHERE cod_filial = (
                        SELECT pv.cod_filial
                        FROM vve_cred_soli_prof sp
                        INNER JOIN vve_proforma_veh pv
                            ON pv.num_prof_veh = sp.num_prof_veh
                        INNER JOIN vve_proforma_veh_det pd
                            ON sp.num_prof_veh = pd.num_prof_veh
                        WHERE sp.cod_soli_cred = sc.cod_soli_cred
                            AND rownum = 1)
                    AND z.cod_zona IN (
                        SELECT column_value
                        FROM TABLE(fn_varchar_to_table(p_cod_zona))
               )))
                   AND sc.tip_soli_cred NOT IN ('TC05') -- <Eudo etiquetar, esta linea estaba comentada tb generaba duplicado>
               AND ( p_ruc_cliente IS NULL OR gp.num_ruc = p_ruc_cliente )
               AND (sc.ind_inactivo = 'N' OR sc.ind_inactivo IS NULL ) --Req. 87567 E2.1  avilca 07/01/2021
            UNION  -- <I Eudo comente el all xq si hay duplicado los muestra todos> ALL
               ---- <Eudo etiquetar reemplace todo el bloque hasta final del query>
               --<Req. 87567 E2.1 ID## EBARBOZA 11/03/2020>
                SELECT sc.cod_soli_cred, sc.txt_obse_crea, sc.can_plaz_mes, sc.cod_area_vta as cod_area_vta,
                    gav.des_area_vta as des_area_vta, TO_CHAR(sc.fec_soli_cred, 'DD/MM/YYYY') AS fec_soli_cred,
                    (select des_zona from gen_perso_vendedor gv
                                     inner join arccve v on (gv.vendedor = sc.vendedor)
                                     inner join vve_mae_zona_filial f on (v.cod_filial = sc.cod_filial)
                                     inner join vve_mae_zona z on (f.cod_zona = sc.cod_zona)
                    where gv.cod_perso = sc.cod_clie AND gv.IND_INACTIVO = 'N' and rownum = 1) AS region,
                   (select z.des_zona from vve_cred_soli s inner join vve_mae_zona z on z.cod_zona = s.cod_zona where s.cod_soli_cred = p_cod_soli_cred) as nombre_zona,
                   (select z.cod_zona from vve_cred_soli s inner join vve_mae_zona z on z.cod_zona = s.cod_zona  where s.cod_soli_cred = p_cod_soli_cred) as cod_zona,
                   (select gs.nom_sucursal from vve_cred_soli s inner join gen_sucursales gs on gs.cod_sucursal = s.cod_sucursal where s.cod_soli_cred = p_cod_soli_cred) as nombre_sucursal,
                   (select gs.cod_sucursal from vve_cred_soli s inner join gen_sucursales gs on gs.cod_sucursal = s.cod_sucursal where s.cod_soli_cred = p_cod_soli_cred) as cod_sucursal,
                   (select v.descripcion from vve_cred_soli s inner join arccve v on v.vendedor = s.vendedor where s.cod_soli_cred = p_cod_soli_cred) as nombre_vendedor,
                   (select v.vendedor from vve_cred_soli s inner join arccve v on v.vendedor = s.vendedor where s.cod_soli_cred = p_cod_soli_cred) as cod_vendedor,
                   (select f.nom_filial from vve_cred_soli s inner join gen_filiales f on f.cod_filial = s.cod_filial where s.cod_soli_cred = p_cod_soli_cred) as nombre_filial,
                   (select f.cod_filial from vve_cred_soli s inner join gen_filiales f on f.cod_filial = s.cod_filial where s.cod_soli_cred = p_cod_soli_cred) as cod_filial,
                    sc.cod_clie, gp.nom_perso, gp.cod_estado_civil, gp.cod_tipo_perso,
                    CASE WHEN gp.cod_tipo_perso = 'J' THEN 'Jurídica' ELSE 'Natural' END AS tipo_perso,
                    gp.ind_mancomunado, gp.num_docu_iden, gp.num_ruc, gp.dir_correo, gp.num_telf_movil,gdp.num_telf1,
                    sc.tip_soli_cred, tc.descripcion AS des_tipo_soli_cred, sc.cod_estado, tc.descripcion,
                    upper(sce.descripcion) AS des_estado, TO_CHAR(sc.fec_apro_clie, 'DD/MM/YYYY') AS fec_apro_clie,
                    --(SELECT ma.des_acti_cred FROM vve_cred_soli_acti vc2 INNER JOIN vve_cred_maes_acti ma <CC E2.1 ID224 LR 11.11.19>
                    (SELECT ma.des_acti_cred FROM vve_cred_soli_acti vc2 INNER JOIN vve_cred_maes_activ ma --<CC E2.1 ID224 LR 11.11.19>
                    ON (vc2.cod_acti_cred=ma.cod_acti_cred) WHERE vc2.cod_soli_cred=sc.cod_soli_cred
                    AND vc2.cod_cred_soli_acti = (SELECT MAX(vc1.cod_cred_soli_acti) FROM vve_cred_soli_acti vc1
                    WHERE vc1.cod_soli_cred=sc.cod_soli_cred AND vc1.fec_usua_ejec IS NOT NULL)) AS act_actual,
                    (select cod_id_usuario from sis_mae_usuario where txt_usuario = sc.cod_pers_soli) AS cod_pers_soli,
                    (select UPPER(paterno || ' ' || materno || ' ' || nombre1) from usuarios where co_usuario = sc.cod_pers_soli) AS des_pers_soli,
                    sc.cod_resp_fina,
                    (select UPPER(paterno || ' ' || materno || ' ' || nombre1) from usuarios where co_usuario = sc.cod_resp_fina) AS des_resp_fina,
                    sc.cod_empr, em.nombre AS des_nom_empr, null as num_prof_veh, sc.val_mon_fin as val_vta_tot_fin, sc.cod_mone_soli as cod_moneda_prof,
                    sc.vendedor AS vendedor,
                    null as num_ficha_vta_veh,
                    null as cod_banco,
                    sc.val_mon_fin as monto_sol_cred,
                    sc.val_mont_sol_gest_banc,
                    sc.val_porc_gest_banc,
                    sc.fec_ingr_gest_banc,
                    sc.fec_ingr_ries_gest_banc,
                    sc.fec_aprob_cart_ban,
                    sc.fec_resu_gest_banc,
                    sc.cod_esta_gest_banc,
                    sc.txt_obse_gest_banc,
                    'N' AS ind_pago_contado,
                    decode(sc.cod_estado,'ES03','S',decode(sc.cod_estado,'ES07','S','N')) AS ind_cred_aprobado,
                    'N' AS ind_bloqueo_pestanias,
                    'S' AS ind_cred_vehi,
                    'N' AS ind_gest_banc,
                    'IN' AS esta_gest_banc,
                    null as can_veh_fin,
                    null as val_pre_veh,
                    (select porcentaje from arcgiv where clave = '01' and no_cia = sc.cod_empr) as igv,
                    (select porcentaje from arcgiv where clave = '03' and no_cia = sc.cod_empr) as ir,
                    (select val_para_num from vve_cred_soli_para where cod_cred_soli_para = 'ADEPVEH') as val_para_num,
                    sc.cod_oper_rel,
                    sc.cod_oper_orig,
                    sc.val_porc_ci,
                    sc.val_ci,
                    sc.val_pago_cont_ci,
                    TO_CHAR(sc.fec_venc_1ra_let, 'DD/MM/YYYY') as fecVenc1raLet,
                    sc.can_dias_venc_1ra_letr,
                    sc.cod_peri_cred_soli,
                    sc.can_tota_letr,
                    sc.ind_tipo_peri_grac,
                    sc.val_dias_peri_grac,
                    sc.can_letr_peri_grac,
                    sc.val_int_per_gra,
                    sc.val_porc_tea_sigv,
                    sc.val_porc_tep_sigv,
                    sc.ind_gps,
                    sc.val_porc_cuot_ball,
                    sc.val_cuot_ball,
                    sc.ind_tipo_segu,
                    sc.cod_cia_seg,
                    sc.cod_tip_uso_veh,
                    sc.val_tasa_segu,
                    sc.val_prim_seg,
                    sc.cod_tipo_unid,
                    sc.val_porc_gast_admi,
                    sc.val_gasto_admi,
                    (select ltrim(cod_clie_sap,'0') from gen_dir_perso where cod_perso = sc.cod_clie and ind_inactivo = 'N' and ind_dir_defecto = 'S') as cod_clie_sap,
                    (select tipo_cambio from arcgtc where clase_cambio = '02' and fecha = trunc(sysdate)) as tipo_cambio,
                    DECODE(sc.cod_estado,'ES06','S','N') AS ind_cred_recha,
                   (SELECT TO_CHAR(MAX(l.fec_venc), 'DD/MM/YYYY')
                    FROM vve_cred_simu s
                    INNER JOIN vve_cred_simu_letr l
                        ON s.cod_simu = l.cod_simu
                    WHERE s.cod_soli_cred = sc.cod_soli_cred
                        AND s.ind_inactivo = 'N') as fec_ulti_venc,
                   (SELECT s.txt_otr_cond
                    FROM vve_cred_simu s
                    WHERE s.cod_soli_cred = sc.cod_soli_cred
                        AND s.ind_inactivo = 'N') as txt_otr_cond,
                    sc.can_dias_fact_cred,
                    sc.txt_obse_jv,
                    sc.val_tc ,--//<I Req. 87567 E2.1 ID 98 AVILCA 20/07/2020>
                    null can_gara_soli--//<I Req. 87567 E2.1 ID 112 AVILCA 27/07/2020>
                FROM vve_cred_soli sc
                    INNER JOIN arcgmc em ON em.no_cia = sc.cod_empr
                    INNER JOIN gen_persona gp ON gp.cod_perso = sc.cod_clie
                    INNER JOIN gen_dir_perso gdp ON gdp.cod_perso = sc.cod_clie
                    INNER JOIN gen_area_vta gav ON gav.cod_area_vta = sc.cod_area_vta
                    LEFT JOIN vve_tabla_maes tc ON sc.tip_soli_cred = tc.cod_tipo
                    AND tc.cod_grupo_rec = '86'
                    AND tc.cod_tipo_rec = 'TC'
                    LEFT JOIN vve_tabla_maes sce ON sc.cod_estado = sce.cod_tipo
                    AND sce.cod_grupo_rec = '92'
                    AND sce.cod_tipo_rec = 'ES'
                WHERE --sc.cod_soli_cred like '%'||DECODE(p_cod_soli_cred, null, p_num_prof_veh, p_cod_soli_cred)||'%'
                    (p_cod_soli_cred IS NULL OR sc.cod_soli_cred like '%'||p_cod_soli_cred||'%')
                    AND ((p_fec_ini IS NULL AND p_fec_fin IS NULL ) OR trunc(sc.fec_soli_cred) BETWEEN TO_DATE(p_fec_ini, 'DD/MM/YYYY') AND TO_DATE(p_fec_fin, 'DD/MM/YYYY') )
                    AND (p_cod_area_vta IS NULL OR sc.cod_area_vta IN (SELECT column_value FROM TABLE (fn_varchar_to_table(p_cod_area_vta))))
                    AND (p_tip_soli_cred IS NULL OR sc.tip_soli_cred IN (SELECT column_value FROM TABLE (fn_varchar_to_table(p_tip_soli_cred))))
                    AND ( p_cod_clie IS NULL OR sc.cod_clie = p_cod_clie )

                    AND (
                    (exists (select 1 from sis_mae_perfil_usuario
                                      where 0< (select instr(val_para_car,cod_id_perfil)
                                                from vve_cred_soli_para
                                                where cod_cred_soli_para = 'ROLCONSOTR')
                                        and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid)
                            )
                      AND (p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado )
                    )
                    OR
                    (
                    ( (  p_cod_pers_soli_aux IS NULL
                         OR p_cod_pers_soli_aux = p_cod_usua_sid
                       )
                      AND (sc.cod_pers_soli = p_cod_usua_sid)
                      AND exists (select 1 from sis_mae_perfil_usuario where cod_id_perfil = v_perf_asesor and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                      --AND v_perf_asesor IN (select cod_id_perfil from sis_mae_perfil_usuario where cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                     -- AND (p_cod_estado IS NULL OR p_cod_estado IN ('ES01','ES02'))
                      AND (p_cod_estado IS NULL OR sc.cod_estado = p_cod_estado )
                     )
                     OR ((p_cod_pers_soli_aux IS NULL OR sc.cod_pers_soli = p_cod_pers_soli_aux)
                          AND (  (sc.cod_filial,sc.cod_area_vta,sc.cod_zona) in ( select cod_filial,cod_area_vta,cod_zona
                                                                                 from   vve_cred_org_cred_vtas
                                                                                 where  co_usuario = p_cod_usua_sid
                                                                                 and    cod_rol_usuario = v_perf_jv)

                            AND (p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado)
                          )
                        )
                    )
                    OR (
                    ( (p_cod_resp_fina_aux IS NULL  OR p_cod_resp_fina_aux = p_cod_usua_sid)
                       AND sc.cod_resp_fina = p_cod_usua_sid
                       AND exists (select 1 from sis_mae_perfil_usuario where cod_id_perfil = v_perf_ges_fin and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                       AND sc.cod_estado NOT IN ('ES01','ES08')
                       AND (--(p_cod_estado IS NULL AND sc.cod_estado = 'ES03') OR
                            ( p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado ))
                       )
                     OR ((p_cod_resp_fina_aux IS NULL OR sc.cod_resp_fina = p_cod_pers_soli_aux)
                          AND sc.cod_estado NOT IN ('ES01','ES08')
                          AND (( p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado ))
                          AND (
                                  exists (select 1 from sis_mae_perfil_usuario
                                      where 0< (select instr(val_para_car,cod_id_perfil)
                                                from vve_cred_soli_para
                                                where cod_cred_soli_para = 'ROLGESCRED')
                                        and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid)
                            )
                                                       -- )
                              )
                            )
                        )
                    )

                    AND ( p_cod_empr IS NULL OR sc.cod_empr IN ( SELECT column_value FROM TABLE ( fn_varchar_to_table(p_cod_empr))))
                    AND (p_cod_zona IS NULL OR p_cod_zona = sc.cod_zona

                    )
                    AND sc.tip_soli_cred = 'TC05'
                 AND ( p_ruc_cliente IS NULL OR gp.num_ruc = p_ruc_cliente )
                 AND  (sc.ind_inactivo = 'N' OR sc.ind_inactivo IS NULL)--Req. 87567 E2.1  avilca 07/01/2021

        ) s
        ORDER BY TO_DATE(s.fec_soli_cred, 'DD/MM/YYYY') DESC
        OFFSET ln_limitinf ROWS FETCH NEXT ln_limitsup ROWS ONLY;
        --<Fin Req. 87567 E2.1 ID## EBARBOZA 11/03/2020>
       SELECT COUNT(1)
       INTO p_cantidad
       FROM (
               SELECT sc.cod_soli_cred
               FROM
                   vve_cred_soli sc
                   INNER JOIN arcgmc em ON em.no_cia = sc.cod_empr
                   INNER JOIN gen_persona gp ON gp.cod_perso = sc.cod_clie
                   INNER JOIN gen_area_vta gav ON gav.cod_area_vta = sc.cod_area_vta
                   LEFT JOIN vve_tabla_maes tc ON sc.tip_soli_cred = tc.cod_tipo
                                                  AND tc.cod_grupo_rec = '86'
                                                  AND tc.cod_tipo_rec = 'TC'
                   LEFT JOIN vve_tabla_maes sce ON sc.cod_estado = sce.cod_tipo
                                                   AND sce.cod_grupo_rec = '92'
                                                   AND sce.cod_tipo_rec = 'ES'
               WHERE
                   ( p_cod_soli_cred IS NULL
                     OR sc.cod_soli_cred like '%'||p_cod_soli_cred||'%')
                   AND (p_num_prof_veh IS NULL OR EXISTS(
                    SELECT 'X'
                    FROM vve_cred_soli_prof sp
                    WHERE sp.cod_soli_cred = sc.cod_soli_cred
                        AND sp.num_prof_veh like '%'||p_num_prof_veh||'%'
                    )
                   )
                   AND ( ( p_fec_ini IS NULL
                           AND p_fec_fin IS NULL )
                         OR trunc(sc.fec_soli_cred) BETWEEN TO_DATE(p_fec_ini, 'DD/MM/YYYY') AND TO_DATE(p_fec_fin
                         , 'DD/MM/YYYY') )
                   AND ( p_cod_area_vta IS NULL
                         OR sc.cod_area_vta IN (
                       SELECT
                           column_value
                       FROM
                           TABLE ( fn_varchar_to_table(p_cod_area_vta) )
                   ) )
                   AND ( p_tip_soli_cred IS NULL
                         OR sc.tip_soli_cred IN (
                       SELECT
                           column_value
                       FROM
                           TABLE ( fn_varchar_to_table(p_tip_soli_cred) )
                   ) )
                   AND ( p_cod_clie IS NULL
                         OR sc.cod_clie = p_cod_clie )
                    /* AND ( p_cod_pers_soli_aux IS NULL
                       OR sc.cod_pers_soli = p_cod_pers_soli_aux )
                       AND ( p_cod_resp_fina_aux IS NULL
                       OR sc.cod_resp_fina = p_cod_resp_fina_aux )
                    */
                    AND (
                    (exists (select 1 from sis_mae_perfil_usuario
                                      where 0< (select instr(val_para_car,cod_id_perfil)
                                                from vve_cred_soli_para
                                                where cod_cred_soli_para = 'ROLCONSOTR')
                                        and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid)
                            )
                      AND (p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado )
                    )
                    OR
                    (
                    ( (  p_cod_pers_soli_aux IS NULL
                         OR p_cod_pers_soli_aux = p_cod_usua_sid
                       )
                      AND (sc.cod_pers_soli = p_cod_usua_sid)
                      AND exists (select 1 from sis_mae_perfil_usuario where cod_id_perfil = v_perf_asesor and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                      --AND v_perf_asesor IN (select cod_id_perfil from sis_mae_perfil_usuario where cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                     -- AND (p_cod_estado IS NULL OR p_cod_estado IN ('ES01','ES02'))
                      AND (p_cod_estado IS NULL OR sc.cod_estado = p_cod_estado )
                     )
                     OR ((p_cod_pers_soli_aux IS NULL OR sc.cod_pers_soli = p_cod_pers_soli_aux)
                          AND ( sc.cod_soli_cred in (select cod_soli_cred
                                                      from   vve_cred_soli_prof sp, vve_proforma_veh p, vve_mae_zona_filial zf
                                                      where  p.num_prof_veh = sp.num_prof_veh
                                                      and    p.cod_area_vta = sc.cod_area_vta
                                                      and    p.cod_filial = zf.cod_filial
                                                      and   (p.cod_filial,p.cod_area_vta,zf.cod_zona) in ( select cod_filial,cod_area_vta,cod_zona
                                                                                                           from   vve_cred_org_cred_vtas
                                                                                                           where  co_usuario = p_cod_usua_sid
                                                                                                           and    cod_rol_usuario = v_perf_jv)
                                                    )
                         --   AND (p_cod_estado IS NULL OR sc.cod_estado IN ('ES01'))
                            AND (p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado)
                          )
                        )
                    )
                    OR (
                    ( (p_cod_resp_fina_aux IS NULL  OR p_cod_resp_fina_aux = p_cod_usua_sid)
                       AND sc.cod_resp_fina = p_cod_usua_sid
                       AND exists (select 1 from sis_mae_perfil_usuario where cod_id_perfil = v_perf_ges_fin and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                       AND sc.cod_estado NOT IN ('ES01','ES08')
                       AND (--(p_cod_estado IS NULL AND sc.cod_estado = 'ES03') OR
                            ( p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado ))
                       )
                     OR ((p_cod_resp_fina_aux IS NULL OR sc.cod_resp_fina = p_cod_pers_soli_aux)
                          AND sc.cod_estado NOT IN ('ES01','ES08')
                          AND (--(p_cod_estado IS NULL AND sc.cod_estado = 'ES03') OR
                               ( p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado ))
                          AND ( sc.cod_soli_cred in (  select cod_soli_cred
                                                        from   vve_cred_soli_prof sp, vve_proforma_veh p, vve_mae_zona_filial zf
                                                        where  p.num_prof_veh = sp.num_prof_veh
                                                        and    p.cod_filial = zf.cod_filial
                                                        and   (p.cod_filial,p.cod_area_vta,zf.cod_zona) in ( select cod_filial,cod_area_vta,cod_zona
                                                                                                             from   vve_cred_org_cred_vtas
                                                                                                             where  co_usuario = p_cod_usua_sid
                                                                                                             and    0< (select instr(val_para_car,cod_rol_usuario)
                                                                                                                                          from vve_cred_soli_para
                                                                                                                                         where cod_cred_soli_para = 'ROLJEFES'))
                                                        )
                              )
                            )
                        )
                    )
                    -- AND ( p_cod_estado IS NULL
                    --       OR sc.cod_estado = p_cod_estado )
                   AND ( p_cod_empr IS NULL
                         OR sc.cod_empr IN (
                       SELECT
                           column_value
                       FROM
                           TABLE ( fn_varchar_to_table(p_cod_empr) )
                   ) )
                   AND (p_cod_zona IS NULL OR EXISTS(
                        SELECT 'X'
                        FROM vve_mae_zona_filial f
                        INNER JOIN vve_mae_zona z
                            ON f.cod_zona = z.cod_zona
                        WHERE cod_filial = (
                            SELECT pv.cod_filial
                            FROM vve_cred_soli_prof sp
                            INNER JOIN vve_proforma_veh pv
                                ON pv.num_prof_veh = sp.num_prof_veh
                            INNER JOIN vve_proforma_veh_det pd
                                ON sp.num_prof_veh = pd.num_prof_veh
                            WHERE sp.cod_soli_cred = sc.cod_soli_cred
                                AND rownum = 1)
                        AND z.cod_zona IN (
                            SELECT column_value
                            FROM TABLE(fn_varchar_to_table(p_cod_zona))
                   )))
                   AND sc.tip_soli_cred NOT IN ('TC05') -- <Eudo etiquetar, esta línea estaba comentado>
                   AND ( p_ruc_cliente IS NULL OR gp.num_ruc = p_ruc_cliente )
                   AND (sc.ind_inactivo = 'N' OR sc.ind_inactivo IS NULL ) --Req. 87567 E2.1  avilca 07/01/2021
                   UNION -- <Eudo etiquetar reemplace todo el bloque hasta final del query>
                    select sc.cod_soli_cred
                    from vve_cred_soli sc
                    INNER JOIN arcgmc em ON em.no_cia = sc.cod_empr
                    INNER JOIN gen_persona gp ON gp.cod_perso = sc.cod_clie
                    INNER JOIN gen_area_vta gav ON gav.cod_area_vta = sc.cod_area_vta
                    LEFT JOIN vve_tabla_maes tc ON sc.tip_soli_cred = tc.cod_tipo
                    AND tc.cod_grupo_rec = '86'
                    AND tc.cod_tipo_rec = 'TC'
                    LEFT JOIN vve_tabla_maes sce ON sc.cod_estado = sce.cod_tipo
                    AND sce.cod_grupo_rec = '92'
                    AND sce.cod_tipo_rec = 'ES'
                    WHERE
                    --sc.cod_soli_cred like '%'||DECODE(p_cod_soli_cred, null, p_num_prof_veh, p_cod_soli_cred)||'%'
                    (p_cod_soli_cred IS NULL OR sc.cod_soli_cred like '%'||p_cod_soli_cred||'%')
                    AND ((p_fec_ini IS NULL AND p_fec_fin IS NULL ) OR trunc(sc.fec_soli_cred) BETWEEN TO_DATE(p_fec_ini, 'DD/MM/YYYY') AND TO_DATE(p_fec_fin, 'DD/MM/YYYY') )
                    AND (p_cod_area_vta IS NULL OR sc.cod_area_vta IN (SELECT column_value FROM TABLE (fn_varchar_to_table(p_cod_area_vta))))
                    AND (p_tip_soli_cred IS NULL OR sc.tip_soli_cred IN (SELECT column_value FROM TABLE (fn_varchar_to_table(p_tip_soli_cred))))
                    AND ( p_cod_clie IS NULL OR sc.cod_clie = p_cod_clie )
                    /* AND ( p_cod_pers_soli_aux IS NULL
                       OR sc.cod_pers_soli = p_cod_pers_soli_aux )
                       AND ( p_cod_resp_fina_aux IS NULL
                       OR sc.cod_resp_fina = p_cod_resp_fina_aux )
                    */
                    AND (
                    (exists (select 1 from sis_mae_perfil_usuario
                                      where 0< (select instr(val_para_car,cod_id_perfil)
                                                from vve_cred_soli_para
                                                where cod_cred_soli_para = 'ROLCONSOTR')
                                        and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid)
                            )
                      AND (p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado )
                    )
                    OR
                    (
                    ( (  p_cod_pers_soli_aux IS NULL
                         OR p_cod_pers_soli_aux = p_cod_usua_sid
                       )
                      AND (sc.cod_pers_soli = p_cod_usua_sid)
                      AND exists (select 1 from sis_mae_perfil_usuario where cod_id_perfil = v_perf_asesor and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                      --AND v_perf_asesor IN (select cod_id_perfil from sis_mae_perfil_usuario where cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                     -- AND (p_cod_estado IS NULL OR p_cod_estado IN ('ES01','ES02'))
                      AND (p_cod_estado IS NULL OR sc.cod_estado = p_cod_estado )
                     )
                     OR ((p_cod_pers_soli_aux IS NULL OR sc.cod_pers_soli = p_cod_pers_soli_aux)
                          AND ( /*sc.cod_soli_cred in (select cod_soli_cred
                                                      from   vve_cred_soli_prof sp, vve_proforma_veh p, vve_mae_zona_filial zf
                                                      where  p.num_prof_veh = sp.num_prof_veh
                                                      and    p.cod_area_vta = sc.cod_area_vta
                                                      and    p.cod_filial = zf.cod_filial
                                                      and   (p.cod_filial,p.cod_area_vta,zf.cod_zona)*/
                                  (sc.cod_filial,sc.cod_area_vta,sc.cod_zona) in ( select cod_filial,cod_area_vta,cod_zona
                                                                                 from   vve_cred_org_cred_vtas
                                                                                 where  co_usuario = p_cod_usua_sid
                                                                                 and    cod_rol_usuario = v_perf_jv)
                                                   -- )
                         --   AND (p_cod_estado IS NULL OR sc.cod_estado IN ('ES01'))
                            AND (p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado)
                          )
                        )
                    )
                    OR (
                    ( (p_cod_resp_fina_aux IS NULL  OR p_cod_resp_fina_aux = p_cod_usua_sid)
                       AND sc.cod_resp_fina = p_cod_usua_sid
                       AND exists (select 1 from sis_mae_perfil_usuario where cod_id_perfil = v_perf_ges_fin and cod_id_usuario IN (select cod_id_usuario from sis_mae_usuario where txt_usuario = p_cod_usua_sid))
                       AND sc.cod_estado NOT IN ('ES01','ES08')
                       AND (--(p_cod_estado IS NULL AND sc.cod_estado = 'ES03') OR
                            ( p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado ))
                       )
                     OR ((p_cod_resp_fina_aux IS NULL OR sc.cod_resp_fina = p_cod_pers_soli_aux)
                          AND sc.cod_estado NOT IN ('ES01','ES08')
                          AND (--(p_cod_estado IS NULL AND sc.cod_estado = 'ES03') OR
                               ( p_cod_estado IS NULL  OR sc.cod_estado = p_cod_estado ))
                          AND ( /*sc.cod_soli_cred in (  select cod_soli_cred
                                                        from   vve_cred_soli_prof sp, vve_proforma_veh p, vve_mae_zona_filial zf
                                                        where  p.num_prof_veh = sp.num_prof_veh
                                                        and    p.cod_filial = zf.cod_filial
                                                        and   (p.cod_filial,p.cod_area_vta,zf.cod_zona)*/
                                  (sc.cod_filial,sc.cod_area_vta,sc.cod_zona) in ( select cod_filial,cod_area_vta,cod_zona
                                                                                                             from   vve_cred_org_cred_vtas
                                                                                                             where  co_usuario = p_cod_usua_sid
                                                                                                             and    0< (select instr(val_para_car,cod_rol_usuario)
                                                                                                                                          from vve_cred_soli_para
                                                                                                                                         where cod_cred_soli_para = 'ROLJEFES'))
                                                     --   )
                              )
                            )
                        )
                    )
                    -- AND ( p_cod_estado IS NULL
                    --       OR sc.cod_estado = p_cod_estado )
                    AND ( p_cod_empr IS NULL OR sc.cod_empr IN ( SELECT column_value FROM TABLE ( fn_varchar_to_table(p_cod_empr))))
                    AND (p_cod_zona IS NULL OR p_cod_zona = sc.cod_zona
                    /*EXISTS(
                            SELECT 'X'
                            FROM gen_perso_vendedor gv
                            INNER JOIN arccve v
                                ON gv.vendedor = sc.vendedor
                            INNER JOIN vve_mae_zona_filial f
                                ON v.cod_filial = sc.cod_filial
                            INNER JOIN vve_mae_zona z
                                ON f.cod_zona = sc.cod_zona
                            WHERE gv.cod_perso = sc.cod_clie
                                AND gv.ind_inactivo = 'N'*/
                               /* AND z.cod_zona IN (
                                    SELECT column_value
                                    FROM TABLE(fn_varchar_to_table(p_cod_zona))) */
                              --  AND rownum = 1
                    --)
                    )
                    AND sc.tip_soli_cred = 'TC05'
                    AND ( p_ruc_cliente IS NULL OR gp.num_ruc = p_ruc_cliente )
                    AND (sc.ind_inactivo = 'N' OR sc.ind_inactivo IS NULL ) --Req. 87567 E2.1  avilca 07/01/2021
                );

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_LIST_CRED_SOLI',
                                            p_cod_usua_sid,
                                            'Error en la consulta',
                                            p_ret_mens,
                                            NULL);
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LIST_FICHA_VENTA_web:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_LIST_CRED_SOLI',
                                            p_cod_usua_sid,
                                            'Error en la consulta',
                                            p_ret_mens,
                                            NULL);
END sp_list_cred_soli;


    PROCEDURE sp_list_vehiculos (
        p_cod_soli_cred   IN                vve_cred_soli.cod_soli_cred%TYPE,
        p_ind_consulta    IN                VARCHAR2,
        p_cod_usua_sid    IN                sistemas.usuarios.co_usuario%TYPE,
        p_ret_cursor      OUT               SYS_REFCURSOR,
        p_ret_esta        OUT               NUMBER,
        p_ret_mens        OUT               VARCHAR2
    ) AS
        ve_error EXCEPTION;
        v_lc_uso VARCHAR2(30);
        cantidad NUMBER;
    BEGIN

    cantidad := 0;

    BEGIN
        SELECT
            descripcion INTO v_lc_uso
        FROM
            vve_tabla_maes
        WHERE
            cod_grupo = '97'
            AND cod_tipo IN (SELECT cod_tip_uso_veh FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred);
    EXCEPTION
        WHEN OTHERS THEN
            v_lc_uso := '-';
    END;

    dbms_output.put_line(v_lc_uso);

    IF p_ind_consulta = 'AGREGA' THEN

        BEGIN
            SELECT
                COUNT(1) INTO cantidad
            FROM
                vve_cred_soli_pedi_veh
            WHERE
                cod_soli_cred = p_cod_soli_cred
                AND ind_inactivo = 'N'; -- MBARDALES 31/03/2021 E. 2.3
        EXCEPTION
            WHEN OTHERS THEN
                cantidad := '0';
        END;

        dbms_output.put_line(cantidad);
       /*
        IF cantidad > 0 THEN
            OPEN p_ret_cursor FOR
                SELECT
                    p.cod_cia, p.cod_prov, p.num_pedido_veh, p.num_chasis, p.num_placa_veh, p.num_motor_veh, b.des_baumuster,
                    p.ano_fabricacion_veh, v_lc_uso as tipo_vehiculo, null as asientos, null as ruta
                FROM
                    vve_pedido_veh p, vve_baumuster b, vve_cred_maes_gara m, vve_cred_soli_gara g, vve_cred_soli_pedi_veh s
                WHERE
                    p.num_prof_veh IN (SELECT num_prof_veh FROM vve_cred_soli_prof WHERE cod_soli_cred = p_cod_soli_cred)
                    AND s.num_pedido_veh = p.num_pedido_veh
                    AND p.cod_baumuster = b.cod_baumuster
                    AND p.cod_marca = b.cod_marca
                    AND m.cod_garantia = g.cod_gara
                    AND m.num_pedido_veh = p.num_pedido_veh
                    AND g.ind_inactivo = 'S'
                    ORDER BY p.num_pedido_veh;
        ELSE
      */
            OPEN p_ret_cursor FOR
                SELECT
                    p.cod_cia, p.cod_prov, p.num_pedido_veh, p.num_chasis, p.num_placa_veh, p.num_motor_veh, b.des_baumuster,
                    p.ano_fabricacion_veh, v_lc_uso as tipo_vehiculo,
                    NULL as asientos,
                    NULL as ruta
                    --(select can_nro_asie from vve_cred_maes_gara where num_pedido_veh = p.num_pedido_veh) as asientos,
                    --(select txt_ruta_veh from vve_cred_maes_gara where num_pedido_veh = p.num_pedido_veh) as ruta
                FROM vve_pedido_veh p, vve_baumuster b
                WHERE
                    p.num_prof_veh IN (SELECT num_prof_veh FROM vve_cred_soli_prof WHERE cod_soli_cred = p_cod_soli_cred AND ind_inactivo = 'N') -- MBARDALES 31/03/2021 E. 2.3
                    AND p.num_pedido_veh NOT IN (SELECT num_pedido_veh FROM vve_cred_soli_pedi_veh
                                                 -- I Req. 87567 E2.1  avilca 24/06/2020
                                                 WHERE cod_soli_cred = p_cod_soli_cred AND IND_INACTIVO='N')
                                                 -- F Req. 87567 E2.1  avilca 24/06/2020
                    AND p.cod_baumuster = b.cod_baumuster
                    AND p.cod_marca = b.cod_marca
                    AND b.ind_inactivo = 'N' ORDER BY p.num_pedido_veh;
        --END IF;

    ELSIF   p_ind_consulta = 'REGIS' THEN

        OPEN p_ret_cursor FOR
            SELECT
                p.cod_cia, p.cod_prov, p.num_pedido_veh, p.num_chasis, p.num_placa_veh, p.num_motor_veh, b.des_baumuster,
                p.ano_fabricacion_veh, v_lc_uso as tipo_vehiculo, m.can_nro_asie as asientos, m.txt_ruta_veh as ruta
            FROM
                vve_pedido_veh p, vve_baumuster b, vve_cred_maes_gara m, vve_cred_soli_gara g, vve_cred_soli_pedi_veh s, vve_cred_soli cs
            WHERE
                cs.cod_soli_cred = p_cod_soli_cred
                AND s.cod_soli_cred = cs.cod_soli_cred
                AND cs.tip_soli_cred = 'TC01'
                AND p.num_prof_veh IN (SELECT num_prof_veh FROM vve_cred_soli_prof WHERE cod_soli_cred = p_cod_soli_cred AND ind_inactivo = 'N')
                AND s.num_pedido_veh = p.num_pedido_veh
                AND p.cod_baumuster = b.cod_baumuster
                AND p.cod_marca = b.cod_marca
                AND m.cod_garantia = g.cod_gara
                AND m.num_pedido_veh = p.num_pedido_veh
               -- AND (g.ind_inactivo = 'N' OR g.ind_inactivo is null)
                AND s.ind_inactivo = 'N'
                AND g.ind_inactivo = 'N'
                AND (cs.ind_inactivo = 'N' OR cs.ind_inactivo IS NULL)
                -- ORDER BY p.num_pedido_veh; [I] MBARDALES 31/03/2021 E. 2.3
                UNION
                SELECT
                  p.cod_cia, p.cod_prov, p.num_pedido_veh, p.num_chasis, p.num_placa_veh, p.num_motor_veh, b.des_baumuster,
                  p.ano_fabricacion_veh, v_lc_uso as tipo_vehiculo, s.can_asientos as asientos, s.txt_ruta_veh as ruta
                FROM
                vve_pedido_veh p, vve_baumuster b, vve_cred_soli_pedi_veh s, vve_cred_soli cs
                WHERE
                  cs.cod_soli_cred = p_cod_soli_cred
                  AND s.cod_soli_cred = cs.cod_soli_cred
                  AND cs.tip_soli_cred IN ('TC02','TC03','TC06')
                  AND p.num_prof_veh IN (SELECT num_prof_veh FROM vve_cred_soli_prof WHERE cod_soli_cred = p_cod_soli_cred AND ind_inactivo = 'N')
                  AND s.num_pedido_veh = p.num_pedido_veh
                  AND p.cod_baumuster = b.cod_baumuster
                  AND p.cod_marca = b.cod_marca
                  --AND m.cod_garantia = g.cod_gara
                  --AND m.num_pedido_veh = p.num_pedido_veh
                 -- AND (g.ind_inactivo = 'N' OR g.ind_inactivo is null)
                  AND s.ind_inactivo = 'N'
                  AND (cs.ind_inactivo = 'N' OR cs.ind_inactivo IS NULL);
                  -- [F] MBARDALES 31/03/2021
   ELSE
   /**I Req. 87567 E2.1 ID:309 Usuario 26.03.2020**/
          OPEN p_ret_cursor FOR
            SELECT
                p.cod_cia, p.cod_prov, p.num_pedido_veh, p.num_chasis, p.num_placa_veh, p.num_motor_veh, b.des_baumuster,
                p.ano_fabricacion_veh
                --v_lc_uso as tipo_vehiculo,
                --m.can_nro_asie as asientos, m.txt_ruta_veh as ruta
            FROM
                 vve_cred_soli_prof sp
                 INNER JOIN vve_ficha_vta_proforma_veh fp ON sp.num_prof_veh = fp.num_prof_veh
                 INNER JOIN vve_ficha_vta_pedido_veh fvp ON fp.num_ficha_vta_veh = fvp.num_ficha_vta_veh
                 INNER JOIN vve_pedido_veh p ON fvp.num_pedido_veh = p.num_pedido_veh
                 INNER JOIN vve_baumuster b ON (p.cod_baumuster = b.cod_baumuster AND p.cod_marca = b.cod_marca)

            WHERE
                  sp.cod_soli_cred = p_cod_soli_cred
                  AND sp.ind_inactivo = 'N' -- MBARDALES 31/03/2021 E. 2.3
									AND NVL(fvp.ind_inactivo, 'N') = 'N'--ASALASM 22/04/2021
                  ORDER BY p.num_pedido_veh;
    END IF;
   /**F Req. 87567 E2.1 ID:309 Usuario 26.03.2020**/
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_VEHICULOS', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_VEHICULOS:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_VEHICULOS', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_vehiculos;


    PROCEDURE sp_inse_soli_veh (
        p_cod_soli_cred      IN     vve_cred_soli_pedi_veh.cod_soli_cred%TYPE,
        p_cod_cia            IN     vve_cred_soli_pedi_veh.cod_cia%TYPE,
        p_cod_prov           IN     vve_cred_soli_pedi_veh.cod_prov%TYPE,
        p_num_pedido_veh     IN     vve_cred_soli_pedi_veh.num_pedido_veh%TYPE,
        p_txt_ruta_veh       IN     vve_cred_soli_pedi_veh.txt_ruta_veh%TYPE,
        p_can_asientos       IN     vve_cred_soli_pedi_veh.can_asientos%TYPE,
        p_cod_usua_sid       IN     sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta           OUT    NUMBER,
        p_ret_mens           OUT    VARCHAR2
    ) AS

        ve_error            EXCEPTION;
        cantidad            NUMBER;
        v_cantidad_gara     NUMBER;
        v_cod_gara          VARCHAR2(10);
        v_num_pedido_veh    VARCHAR2(12);
        v_num_prof_veh      vve_pedido_veh.num_prof_veh%type;
        v_num_chasis        vve_pedido_veh.num_chasis%type;
        v_num_placa_veh     vve_pedido_veh.num_placa_veh%type;
        v_num_motor_veh     vve_pedido_veh.num_motor_veh%type;
        v_baumuster         vve_pedido_veh.cod_baumuster%type;
        v_cod_marca        vve_pedido_veh.cod_marca%type;
        v_familia_veh       vve_pedido_veh.cod_familia_veh%type;
        v_ano_fab_veh       vve_pedido_veh.ano_fabricacion_veh%type;
        v_des_baumuster     vve_baumuster.des_baumuster%type;
    BEGIN

        v_num_pedido_veh := REPLACE(p_num_pedido_veh, ',', '.');


        SELECT
            COUNT(1) INTO cantidad
        FROM
            vve_cred_soli_pedi_veh
        WHERE
            num_pedido_veh = v_num_pedido_veh and cod_soli_cred = p_cod_soli_cred;

        BEGIN
            SELECT num_prof_veh INTO v_num_prof_veh FROM vve_pedido_veh WHERE cod_cia = p_cod_cia AND num_pedido_veh = v_num_pedido_veh;
        END;

        IF cantidad > 0 AND v_num_prof_veh IS NOT NULL THEN
           UPDATE
              vve_cred_soli_pedi_veh
           SET
             CAN_ASIENTOS = p_can_asientos,
             TXT_RUTA_VEH = p_txt_ruta_veh,
             IND_INACTIVO = 'N',--Req. 87567 E2.1 ID## AVILCA 24/06/2020
             COD_USUA_MODI_REGI =  p_cod_usua_sid,--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
             FEC_MODI_REGI = SYSDATE--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
           WHERE
             NUM_PEDIDO_VEH = v_num_pedido_veh;
           COMMIT;

           BEGIN
            SELECT COUNT(1) INTO v_cantidad_gara
            FROM
                vve_cred_maes_gara m inner join vve_cred_soli_gara s on (m.cod_garantia = s.cod_gara and s.cod_soli_cred = p_cod_soli_cred AND s.ind_inactivo = 'N' ) -- MBARDALES
            WHERE
                m.num_proforma_veh = v_num_prof_veh
                AND m.num_pedido_veh = v_num_pedido_veh;
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
              v_cantidad_gara := 0;
            END;

            /*
            SELECT
                COUNT(1) INTO v_cantidad_gara
            FROM
                vve_cred_maes_gara m inner join vve_cred_soli_gara s on (m.cod_garantia = s.cod_gara)
            WHERE
                num_pedido_veh = v_num_pedido_veh and ind_inactivo = 'S';


            IF v_cantidad_gara > 0 THEN

                SELECT
                    cod_gara INTO v_cod_gara
                FROM
                    vve_cred_maes_gara m inner join vve_cred_soli_gara s on (m.cod_garantia = s.cod_gara)
                WHERE
                    num_pedido_veh = v_num_pedido_veh and ind_inactivo = 'S';


                IF v_cod_gara IS NOT NULL THEN

                    UPDATE
                        vve_cred_soli_gara
                    SET
                        ind_inactivo = 'N'
                    WHERE
                        cod_gara = v_cod_gara;
                END IF;
            END IF;
           */

           SELECT
                p.num_chasis, p.num_placa_veh, p.num_motor_veh, p.cod_baumuster, p.cod_marca, p.cod_familia_veh, p.ano_fabricacion_veh, b.des_baumuster
            INTO
                v_num_chasis, v_num_placa_veh, v_num_motor_veh, v_baumuster,v_cod_marca,v_familia_veh, v_ano_fab_veh, v_des_baumuster
            FROM
                vve_pedido_veh p, vve_baumuster b
            WHERE
               p.num_pedido_veh = v_num_pedido_veh
               AND p.cod_baumuster = b.cod_baumuster
               AND p.cod_marca = b.cod_marca
               AND p.cod_familia_veh = b.cod_familia_veh
               AND p.cod_cia = p_cod_cia;

           IF v_cantidad_gara > 0 THEN
             SELECT cod_garantia INTO v_cod_gara
             FROM
                vve_cred_maes_gara m inner join vve_cred_soli_gara s on (m.cod_garantia = s.cod_gara and s.cod_soli_cred = p_cod_soli_cred)
             WHERE
                m.num_proforma_veh = v_num_prof_veh
                AND m.num_pedido_veh = v_num_pedido_veh
                -- MBARDALES
                AND s.ind_inactivo = 'N';

             UPDATE
                vve_cred_maes_gara
             SET
                CAN_NRO_ASIE = p_can_asientos, TXT_RUTA_VEH = p_txt_ruta_veh,
                NRO_CHASIS = v_num_chasis, NRO_MOTOR = v_num_motor_veh, NRO_PLACA = v_num_placa_veh, TXT_MODELO = v_des_baumuster,
                VAL_ANO_FAB = v_ano_fab_veh,
                COD_USUA_MODI_REGI = p_cod_usua_sid,--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
                FEC_MODI_REGI = sysdate--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
             WHERE
                COD_GARANTIA = v_cod_gara AND
                NUM_PEDIDO_VEH = v_num_pedido_veh;
             COMMIT;

             UPDATE
                vve_cred_soli_gara
             SET
               -- IND_INACTIVO = 'N', MBARDALES
               COD_USUA_MODI_REGI = p_cod_usua_sid,--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
               FEC_MODI_REGI = sysdate--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
             WHERE
                COD_GARA = v_cod_gara AND
                COD_SOLI_CRED = p_cod_soli_cred;
            COMMIT;

           ELSE
             SELECT cod_garantia INTO v_cod_gara
             FROM
                vve_cred_maes_gara m inner join vve_cred_soli_gara s on (m.cod_garantia = s.cod_gara and s.cod_soli_cred = p_cod_soli_cred)
             WHERE
                m.num_proforma_veh = v_num_prof_veh
                AND m.num_pedido_veh IS NULL
                -- MBARDALES
                AND s.ind_inactivo = 'N'
                AND ROWNUM = 1;

             UPDATE
                vve_cred_maes_gara
             SET
                CAN_NRO_ASIE = p_can_asientos, TXT_RUTA_VEH = p_txt_ruta_veh, NUM_PEDIDO_VEH = v_num_pedido_veh,
                NRO_CHASIS = v_num_chasis, NRO_MOTOR = v_num_motor_veh, NRO_PLACA = v_num_placa_veh, TXT_MODELO = v_des_baumuster,
                VAL_ANO_FAB = v_ano_fab_veh,
                COD_USUA_MODI_REGI = p_cod_usua_sid,--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
                FEC_MODI_REGI = sysdate--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
             WHERE
                COD_GARANTIA = v_cod_gara;
             COMMIT;
           END IF;

           --END IF;
        ELSE

            INSERT INTO vve_cred_soli_pedi_veh (
                cod_soli_cred,
                cod_cia,
                cod_prov,
                num_pedido_veh,
                txt_ruta_veh,
                can_asientos,
                ind_inactivo, --Req. 87567 E2.1 ID## AVILCA 24/06/2020
                cod_usua_crea_regi,--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
                fec_crea_regi--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
            ) VALUES (
                p_cod_soli_cred,
                p_cod_cia,
                p_cod_prov,
                p_num_pedido_veh,
                p_txt_ruta_veh,
                p_can_asientos,
                'N',         --Req. 87567 E2.1 ID## AVILCA 24/06/2020
                p_cod_usua_sid,--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
                sysdate--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
            );
            COMMIT;

            SELECT cod_garantia INTO v_cod_gara
             FROM
                vve_cred_maes_gara m inner join vve_cred_soli_gara s on (m.cod_garantia = s.cod_gara and s.cod_soli_cred = p_cod_soli_cred)
             WHERE
                m.num_proforma_veh = v_num_prof_veh
                AND m.num_pedido_veh IS NULL
                -- MBARDALES
                AND s.ind_inactivo = 'N'
                AND ROWNUM = 1;

             UPDATE
                vve_cred_maes_gara
             SET
                CAN_NRO_ASIE = p_can_asientos, TXT_RUTA_VEH = p_txt_ruta_veh, NUM_PEDIDO_VEH = v_num_pedido_veh,
                NRO_CHASIS = v_num_chasis, NRO_MOTOR = v_num_motor_veh, NRO_PLACA = v_num_placa_veh, TXT_MODELO = v_des_baumuster,
                VAL_ANO_FAB = v_ano_fab_veh,
                COD_USUA_MODI_REGI = p_cod_usua_sid,--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
                FEC_MODI_REGI = sysdate--Req. 87567 E2.1 ID 176 AVILCA 10/08/2020
             WHERE
                COD_GARANTIA = v_cod_gara;
             COMMIT;
            /*UPDATE
                vve_cred_maes_gara
            SET CAN_NRO_ASIE = p_can_asientos, TXT_RUTA_VEH = p_txt_ruta_veh, num_pedido_veh = v_num_pedido_veh
            WHERE
                NUM_PEDIDO_VEH = v_num_pedido_veh;
            COMMIT;*/

        END IF;
        -- Actualizando actividades
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E6','A35',p_cod_usua_sid,p_ret_esta,p_ret_mens);
        p_ret_esta := 1;
        p_ret_mens := 'Se registró con éxito la operación';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_SOLI_VEH', p_cod_usua_sid, 'Error al insertar la solicitud de crédito VEHICULOS'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_INSE_CRED_SOLI:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_SOLI_VEH', p_cod_usua_sid, 'Error al insertar la solicitud de crédito VEHICULOS'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
    END sp_inse_soli_veh;


    PROCEDURE sp_actu_indi_vehiculo (
        p_num_pedido_veh     IN     vve_cred_soli_pedi_veh.num_pedido_veh%TYPE,
        p_indicativo         IN     VARCHAR2,
        p_cod_usua_sid       IN     sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta           OUT    NUMBER,
        p_ret_mens           OUT    VARCHAR2
    ) AS
        ve_error EXCEPTION;
        v_cod_garantia VARCHAR2(10);
        v_num_pedido_veh VARCHAR2(12);
        v_tip_soli_cred vve_cred_soli.tip_soli_cred%TYPE; -- MBARDALES 31/03/2021 E. 2.3
        v_cod_soli_cred vve_cred_soli.cod_soli_cred%TYPE; -- MBARDALES 31/03/2021 E. 2.3

    BEGIN

        v_num_pedido_veh := REPLACE(p_num_pedido_veh, ',', '.');

        -- [I] MBARDALES 31/03/2021 E. 2.3
        select s.tip_soli_cred, s.cod_soli_cred INTO v_tip_soli_cred, v_cod_soli_cred from vve_cred_soli_pedi_veh pv
        inner join vve_cred_soli s
        on (pv.cod_soli_cred = s.cod_soli_cred)
        where pv.num_pedido_veh = v_num_pedido_veh
        AND pv.ind_inactivo = 'N' AND (s.ind_inactivo = 'N' or s.ind_inactivo IS NULL);

        IF (v_tip_soli_cred = 'TC01') THEN -- [F] MBARDALES 31/03/2021 E. 2.3

          SELECT
              cod_garantia INTO v_cod_garantia
          FROM
              vve_cred_maes_gara
          WHERE
              num_pedido_veh = v_num_pedido_veh;

          dbms_output.put_line(v_cod_garantia);
          /*
          UPDATE
              vve_cred_soli_gara
          SET
              ind_inactivo = p_indicativo,
              cod_usua_modi_regi = p_cod_usua_sid, --Req. 87567 E2.1 ID 178-180 AVILCA 10/08/2020
              fec_modi_regi = sysdate --Req. 87567 E2.1 ID 178-180 AVILCA 10/08/2020
          WHERE
              cod_gara = v_cod_garantia;
          COMMIT;
          */
          --Req. 87567 E2.1 ID 178-180 AVILCA 10/08/2020
          UPDATE
              vve_cred_maes_gara
          SET
              num_pedido_veh = null,
              txt_ruta_veh = null,
              can_nro_asie = null,
              cod_usua_modi_regi = p_cod_usua_sid,
              fec_modi_regi = sysdate
          WHERE
              cod_garantia = v_cod_garantia;
          COMMIT;

        END IF; -- MBARDALES 31/03/2021 E. 2.3

        --Req. 87567 E2.1 ID 178-180 AVILCA 10/08/2020
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO', 'SP_ACTU_INDI_VEHICULO', p_cod_usua_sid, 'Antes de actualizar vve_cred_soli_pedi_veh ', p_ret_mens, p_num_pedido_veh);
        -- I Req. 87567 E2.1 ID## AVILCA 24/06/2020
        UPDATE
            vve_cred_soli_pedi_veh
        SET
            ind_inactivo = 'S',
            cod_usua_modi_regi = p_cod_usua_sid, --Req. 87567 E2.1 ID 178-180 AVILCA 10/08/2020
            fec_modi_regi = sysdate --Req. 87567 E2.1 ID 178-180 AVILCA 10/08/2020
        WHERE
           NUM_PEDIDO_VEH = v_num_pedido_veh
           -- [I] MBARDALES 31/03/2021 E. 2.3
           AND cod_soli_cred = v_cod_soli_cred
           AND ind_inactivo = 'N';
           -- [F] MBARDALES 31/03/2021 E. 2.3
        COMMIT;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO', 'SP_ACTU_INDI_VEHICULO', p_cod_usua_sid, 'Después de actualizar vve_cred_soli_pedi_veh ', p_ret_mens, p_num_pedido_veh);
      -- F Req. 87567 E2.1 ID## AVILCA 24/06/2020
        p_ret_esta := 1;
        p_ret_mens := 'Se actualizaron los datos con éxito';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_ACTU_INDI_VEHICULO', p_cod_usua_sid, 'Error al actualizar el IND_INACTIVO de la garantia'
            , p_ret_mens, p_num_pedido_veh);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_ACTU_INDI_VEHICULO:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_ACTU_INDI_VEHICULO', p_cod_usua_sid, 'Error al actualizar el IND_INACTIVO de la garantia'
            , p_ret_mens, p_num_pedido_veh);
            ROLLBACK;

    END sp_actu_indi_vehiculo;

    PROCEDURE sp_inse_info_sbs (
        p_cod_clasif_sbs_clie             IN      vve_cred_soli_isbs.cod_clasif_sbs_clie%TYPE,
        p_cod_clasif_sbs_repr             IN      vve_cred_soli_isbs.cod_clasif_sbs_repr%TYPE,
        p_cod_persona_clie                IN      vve_cred_soli_isbs.cod_persona_clie%TYPE,
        p_cod_persona_repr                IN      vve_cred_soli_isbs.cod_persona_repr%TYPE,
        p_cod_ries_dive_clie              IN      vve_cred_soli_isbs.cod_ries_dive_clie%TYPE,
        p_cod_ries_dive_repr              IN      vve_cred_soli_isbs.cod_ries_dive_repr%TYPE,
        p_cod_soli_cred                   IN      vve_cred_soli_isbs.cod_soli_cred%TYPE,
        p_ind_cond_ruc_clie               IN      vve_cred_soli_isbs.ind_cond_ruc_clie%TYPE,
        p_ind_cond_ruc_repr               IN      vve_cred_soli_isbs.ind_cond_ruc_repr%TYPE,
        p_txt_link_sbs_clie               IN      vve_cred_soli_isbs.txt_link_sbs_clie%TYPE,
        p_txt_link_sbs_repr               IN      vve_cred_soli_isbs.txt_link_sbs_repr%TYPE,
        p_val_deud_actu_clie              IN      vve_cred_soli_isbs.val_deud_actu_clie%TYPE,
        p_val_deud_actu_repr              IN      vve_cred_soli_isbs.val_deud_actu_repr%TYPE,
        p_val_deud_cier_ano_actu_clie     IN      vve_cred_soli_isbs.val_deud_cier_ano_actu_clie%TYPE,
        p_val_deud_cier_ano_actu_repr     IN      vve_cred_soli_isbs.val_deud_cier_ano_actu_repr%TYPE,
        p_val_deud_cier_ano_ante_clie     IN      vve_cred_soli_isbs.val_deud_cier_ano_ante_clie%TYPE,
        p_val_deud_cier_ano_ante_repr     IN      vve_cred_soli_isbs.val_deud_cier_ano_ante_repr%TYPE,
        p_val_deud_venci_clie             IN      vve_cred_soli_isbs.val_deud_venci_clie%TYPE,
        p_val_deud_venci_repr             IN      vve_cred_soli_isbs.val_deud_venci_repr%TYPE,
        p_val_impa_clie                   IN      vve_cred_soli_isbs.val_impa_clie%TYPE,
        p_val_impa_repr                   IN      vve_cred_soli_isbs.val_impa_repr%TYPE,
        p_val_prot_sin_regu_clie          IN      vve_cred_soli_isbs.val_prot_sin_regu_clie%TYPE,
        p_val_prot_sin_regu_repr          IN      vve_cred_soli_isbs.val_prot_sin_regu_repr%TYPE,
        p_val_prot_regu_clie              IN      vve_cred_soli_isbs.val_prot_regu_clie%TYPE,
        p_val_prot_regu_repr              IN      vve_cred_soli_isbs.val_prot_regu_repr%TYPE,
        p_cod_usua_sid                    IN      sistemas.usuarios.co_usuario%TYPE,
        p_cod_cred_soli_sbs               OUT     vve_cred_soli_isbs.cod_cred_soli_sbs%TYPE,
        p_ret_esta                        OUT     NUMBER,
        p_ret_mens                        OUT     VARCHAR2
    ) AS

        ve_error EXCEPTION;

    BEGIN

        delete from vve_cred_soli_isbs where cod_soli_cred = p_cod_soli_cred;
        commit;
        BEGIN
            SELECT
                lpad(nvl(MAX(cod_cred_soli_sbs), 0) + 1, 10, '0')
            INTO p_cod_cred_soli_sbs
            FROM
                vve_cred_soli_isbs;
            EXCEPTION
                WHEN OTHERS THEN
                p_cod_cred_soli_sbs := '0000000000000000001';
        END;

        INSERT INTO vve_cred_soli_isbs (
            cod_clasif_sbs_clie,
            cod_clasif_sbs_repr,
            cod_cred_soli_sbs,
            cod_persona_clie,
            cod_persona_repr,
            cod_ries_dive_clie,
            cod_ries_dive_repr,
            cod_soli_cred,
            ind_cond_ruc_clie,
            ind_cond_ruc_repr,
            txt_link_sbs_clie,
            txt_link_sbs_repr,
            val_deud_actu_clie,
            val_deud_actu_repr,
            val_deud_cier_ano_actu_clie,
            val_deud_cier_ano_actu_repr,
            val_deud_cier_ano_ante_clie,
            val_deud_cier_ano_ante_repr,
            val_deud_venci_clie,
            val_deud_venci_repr,
            val_impa_clie,
            val_impa_repr,
            val_prot_sin_regu_clie,
            val_prot_sin_regu_repr,
            val_prot_regu_clie,
            val_prot_regu_repr,
            cod_usua_crea_reg,
            fec_crea_reg--//<Req. 87567 E2.1 ID## avilca 03/12/2020>
        ) VALUES (
            p_cod_clasif_sbs_clie,
            p_cod_clasif_sbs_repr,
            p_cod_cred_soli_sbs,
            p_cod_persona_clie,
            p_cod_persona_repr,
            p_cod_ries_dive_clie,
            p_cod_ries_dive_repr,
            p_cod_soli_cred,
            p_ind_cond_ruc_clie,
            p_ind_cond_ruc_repr,
            p_txt_link_sbs_clie,
            p_txt_link_sbs_repr,
            p_val_deud_actu_clie,
            p_val_deud_actu_repr,
            p_val_deud_cier_ano_actu_clie,
            p_val_deud_cier_ano_actu_repr,
            p_val_deud_cier_ano_ante_clie,
            p_val_deud_cier_ano_ante_repr,
            p_val_deud_venci_clie,
            p_val_deud_venci_repr,
            p_val_impa_clie,
            p_val_impa_repr,
            p_val_prot_sin_regu_clie,
            p_val_prot_sin_regu_repr,
            p_val_prot_regu_clie,
            p_val_prot_regu_repr,
            p_cod_usua_sid,
            sysdate --
        );

         -- ACtualizando fecha de ejecución de registro y verificando cierre de etapa
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E2','A8',p_cod_usua_sid,p_ret_esta,p_ret_mens);

        COMMIT;

        p_ret_esta := 1;
        p_ret_mens := 'Se guardó correctamente la información SBS';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_INFO_SBS', p_cod_usua_sid, 'Error al insertar la informacion SBS'
            , p_ret_mens, p_cod_cred_soli_sbs);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_INSE_INFO_SBS:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_INFO_SBS', p_cod_usua_sid, 'Error al insertar la informacion SBS'
            , p_ret_mens, p_cod_cred_soli_sbs);
            ROLLBACK;
    END sp_inse_info_sbs;


    PROCEDURE sp_list_info_sbs (
        p_cod_soli_cred   IN                vve_cred_soli_isbs.cod_soli_cred%TYPE,
        p_cod_usua_sid    IN                sistemas.usuarios.co_usuario%TYPE,
        p_ret_cursor      OUT               SYS_REFCURSOR,
        p_ret_esta        OUT               NUMBER,
        p_ret_mens        OUT               VARCHAR2
    ) AS
        ve_error EXCEPTION;

    BEGIN

    OPEN p_ret_cursor FOR
        SELECT
            cod_clasif_sbs_clie,
            cod_clasif_sbs_repr,
            cod_persona_clie,
            cod_persona_repr,
            cod_ries_dive_clie,
            cod_ries_dive_repr,
            cod_soli_cred,
            ind_cond_ruc_clie,
            ind_cond_ruc_repr,
            txt_link_sbs_clie,
            txt_link_sbs_repr,
            val_deud_actu_clie,
            val_deud_actu_repr,
            val_deud_cier_ano_actu_clie,
            val_deud_cier_ano_actu_repr,
            val_deud_cier_ano_ante_clie,
            val_deud_cier_ano_ante_repr,
            val_deud_venci_clie,
            val_deud_venci_repr,
            val_impa_clie,
            val_impa_repr,
            val_prot_sin_regu_clie,
            val_prot_sin_regu_repr,
            val_prot_regu_clie,
            val_prot_regu_repr
        FROM
            vve_cred_soli_isbs
        WHERE
            cod_soli_cred = p_cod_soli_cred;


        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_INFO_SBS', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_INFO_SBS:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_INFO_SBS', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_info_sbs;


    PROCEDURE sp_datos_hist_oper
    (
        p_cod_oper        IN                VARCHAR2,
        p_cod_clie        IN                vve_cred_soli.cod_clie%TYPE,
        p_no_cia          IN                VARCHAR2,
        p_cod_usua_sid    IN           sistemas.usuarios.co_usuario%TYPE,
        p_ret_cursor      OUT               SYS_REFCURSOR,
        p_ret_esta        OUT               NUMBER,
        p_ret_mens        OUT               VARCHAR2
    ) AS
        ve_error EXCEPTION;
        v_cod_soli_cred VARCHAR2(20) := '';
        v_sum_valo_gara NUMBER := 0.00;
    BEGIN

        dbms_output.put_line('Entro en el SP');

        BEGIN
            SELECT cod_soli_cred INTO v_cod_soli_cred
            FROM vve_cred_soli WHERE cod_oper_rel = p_cod_oper;
            EXCEPTION
                WHEN OTHERS THEN
                v_cod_soli_cred := 'S';
        END;

        dbms_output.put_line(v_cod_soli_cred);

        --IF v_cod_soli_cred = 'S' THEN

        IF p_no_cia <> 'NN' THEN

             dbms_output.put_line('No tiene solicitud');
             OPEN p_ret_cursor FOR
                Select
                    decode(v_cod_soli_cred,'S','',(SELECT  SUM(val_realiz_gar) FROM vve_cred_maes_gara
                                      WHERE cod_garantia IN (SELECT cod_gara FROM vve_cred_soli_gara
                                                             WHERE cod_soli_cred = v_cod_soli_cred))
                           ) as valo_gara_tot,
                    decode(v_cod_soli_cred,'S',decode(ind_per_gra,'S',no_cuotas+1,no_cuotas),
                                  (select can_tota_letr+nvl(can_letr_peri_grac,0)
                                   from vve_cred_soli where cod_soli_cred = v_cod_soli_cred)
                           ) as can_tota_letr,
                    tea as val_porc_tea_sigv,
                    decode(v_cod_soli_cred,'S','',(select val_porc_ci from vve_cred_soli where cod_soli_cred = v_cod_soli_cred)
                          ) as val_porc_ci,
                    monto_fina as val_mon_fin,
                    (SELECT m.descripcion
                        from vve_tabla_maes m
                    WHERE m.cod_grupo = 86
                    AND m.cod_tipo IN (SELECT decode(o.modal_cred,'F','TC01','M','TC03','P','TC05','R','TC07')
                    FROM arlcop o
                    WHERE o.no_cliente = p_cod_clie
                    AND cod_oper = p_cod_oper
                    )) as descripcion,
                    (SELECT cod_tipo
                    from vve_tabla_maes m
                    WHERE m.cod_grupo = 86
                    AND m.cod_tipo IN (SELECT decode(o.modal_cred,'F','TC01','M','TC03','P','TC05','R','TC07')
                    FROM arlcop o
                    WHERE o.no_cliente = p_cod_clie
                    AND cod_oper = p_cod_oper)) as cod_tipo,
                    TO_CHAR((select f_generada from arlcml where cod_oper = p_cod_oper AND no_cia = p_no_cia and rownum = 1), 'DD/MM/YYYY') as fec_emi,--<Req. 87567 E2.1 ID## AVILCA 05/02/2021>
                    (select txt_ruta_cart_banc from vve_cred_soli where cod_oper_rel = p_cod_oper) AS TXT_CARTA_BANCO,
                    (select txt_ruta_docs_firm from vve_cred_soli where cod_oper_rel = p_cod_oper) AS TXT_CONTRATO
                FROM
                    arlcop
                WHERE
                    cod_oper = p_cod_oper AND
                    no_cia = p_no_cia;

            p_ret_esta := 1;
            p_ret_mens := 'La consulta se realizó de manera exitosa';

        ELSE

            OPEN p_ret_cursor FOR
            select
            DECODE(a.no_cia,'06','3000','3001') as compania,
            a.cod_oper as cod_oper,
            DECODE(a.moneda, 'DOL','USD','SOL') as moneda,
            monto_fina as saldo,
            TO_CHAR((select f_vence from arlcml where cod_oper = a.cod_oper
            AND NRO_SEC = (select max(NRO_SEC) from arlcml where cod_oper = a.cod_oper )), 'DD/MM/YYYY') as fec_ult_venc,
            DECODE(monto_fina,0,'CERRADO', 'VIGENTE') as estado,
            '---' AS dias_vencidos,
            '---' AS max_dias_vencidos,
            '---' AS ratio_gara,
            (SELECT SUM(val_realiz_gar) FROM vve_cred_maes_gara
            WHERE cod_garantia
            IN (SELECT cod_gara FROM vve_cred_soli_gara g inner join vve_cred_soli s ON g.cod_soli_cred = s.cod_soli_cred WHERE s.cod_oper_rel = a.cod_oper)) as valo_gara_tot,
            (select max(NRO_SEC) from arlcml where cod_oper = a.cod_oper) as can_tota_letr,
            tea as val_porc_tea_sigv,
            (select val_porc_ci from vve_cred_soli where cod_oper_rel = a.cod_oper) as val_porc_ci,
            monto_fina as val_mon_fin,
            (SELECT m.descripcion
            from vve_tabla_maes m
            WHERE m.cod_grupo = 86
            AND m.cod_tipo IN (SELECT decode(o.modal_cred,'F','TC01','M','TC03','P','TC05','R','TC07')
            FROM arlcop o
            WHERE o.no_cliente = p_cod_clie
            AND cod_oper = a.cod_oper
            )) as descripcion,
            (SELECT cod_tipo
            from vve_tabla_maes m
            WHERE m.cod_grupo = 86
            AND m.cod_tipo IN (SELECT decode(o.modal_cred,'F','TC01','M','TC03','P','TC05','R','TC07')
            FROM arlcop o
            WHERE o.no_cliente = p_cod_clie
            AND cod_oper = a.cod_oper)) as cod_tipo,
            TO_CHAR((select f_generada from arlcml where cod_oper = a.cod_oper AND no_cia = a.no_cia and rownum = 1), 'DD/MM/YYYY') as fec_emi,
            (select txt_ruta_cart_banc from vve_cred_soli where cod_oper_rel = a.cod_oper and cod_clie = p_cod_clie) AS TXT_CARTA_BANCO,
            (select txt_ruta_docs_firm from vve_cred_soli where cod_oper_rel = a.cod_oper and cod_clie = p_cod_clie) AS TXT_CONTRATO
            from arlcop a INNER JOIN  vve_cred_soli s ON a.cod_oper = s.cod_oper_rel
            where cod_clie = p_cod_clie
            and a.cod_oper NOT IN (SELECT column_value FROM TABLE(fn_varchar_to_table(p_cod_oper)));


            p_ret_esta := 1;
            p_ret_mens := p_cod_oper;
        END IF;



    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_DATOS_HIST_OPER', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_DATOS_HIST_OPER:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_DATOS_HIST_OPER', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_datos_hist_oper;

  PROCEDURE sp_list_cred_soli_reso_cred
  (
    p_cod_soli_cred    IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_fec_venc_1ra_let IN  VARCHAR2,
    p_fec_apro_clie    IN  VARCHAR2,
    p_txt_info_adic    IN  vve_cred_soli.txt_info_adic%TYPE,
    p_txt_info_oper    IN  vve_cred_soli.txt_info_oper%TYPE,
    p_cod_usua_sid     IN  sistemas.usuarios.co_usuario%TYPE,
    p_fec_contrato     IN  VARCHAR2,
    p_plazo_fact_cred  IN  VARCHAR2,/**Req. 87567 E2.1 ID: 309 - avilca 24/03/2020 **/
    p_monto_financiar  IN  vve_cred_soli.val_mon_fin%TYPE,/**Req. 87567 E2.1 ID: 309 - avilca 14/04/2021 **/
    p_ret_cursor       OUT SYS_REFCURSOR,
    p_ret_esta         OUT NUMBER,
    p_ret_mens         OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_simu NUMBER;
    v_val_mon_conc NUMBER;
    v_valor_peri NUMBER;
    v_fec_venc_prim_letr VARCHAR2(10);

    v_fec_venc_ult_letr VARCHAR2(10);
    v_fec_ini_vp VARCHAR2(10);
    v_fec_fin_vp VARCHAR2(10);

   -- v_valida_EEA01 char(1):= '1';
    v_cont_rech    NUMBER :=0;
    v_cont_apro    NUMBER :=0;
    v_ind_niveles  NUMBER :=0;
  BEGIN
    -- OBTENIENDO EL COD_SIMULADOR
    BEGIN
        SELECT cod_simu
        INTO v_cod_simu
        FROM
            vve_cred_simu
        WHERE cod_soli_cred = p_cod_soli_cred
            AND ind_inactivo = 'N';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
           v_cod_simu := NULL;
    END;


    IF v_cod_simu IS NOT NULL  THEN

        IF p_fec_venc_1ra_let IS NOT NULL THEN

            -- ACTUALIZANDO LA PRIMERA FECHA DE LETRA
            UPDATE vve_cred_soli
            SET fec_venc_1ra_let = TO_DATE(p_fec_venc_1ra_let, 'DD/MM/YYYY')
            WHERE cod_soli_cred = p_cod_soli_cred;


            -- OBTENIENDO LA PERIOCIDAD PARA EL CALCULO
            BEGIN             -- Req. 87567 E2.1 ID: 309 - avilca 04/06/2020
                SELECT valor_adic_2
                INTO v_valor_peri
                FROM vve_cred_soli s
                INNER JOIN vve_tabla_maes m
                    ON (m.cod_tipo = s.cod_peri_cred_soli)
                WHERE cod_grupo = 88
                    AND cod_soli_cred = p_cod_soli_cred;
            EXCEPTION  -- I Req. 87567 E2.1 ID: 309 - avilca 04/06/2020
                    WHEN NO_DATA_FOUND THEN
                       v_valor_peri := 0;
                END;   -- F Req. 87567 E2.1 ID: 309 - avilca 04/06/2020


            -- SETEANDO LA PRIMERA FECHA DE VENCIMIENTO DE LETRA EN VARIABLE GENERAL
            v_fec_venc_prim_letr := p_fec_venc_1ra_let;

            -- ACTUALIZANDO FECHA INICIAL
            UPDATE vve_cred_simu_lede
            SET fec_venc = TO_DATE(v_fec_venc_prim_letr, 'DD/MM/YYYY')
            WHERE cod_simu = v_cod_simu and cod_nume_letr = 1;


            UPDATE vve_cred_simu_letr
            SET fec_venc = TO_DATE(v_fec_venc_prim_letr, 'DD/MM/YYYY')
            WHERE cod_simu = v_cod_simu and cod_nume_letr = 1;

            UPDATE vve_cred_simu
            SET fec_venc_1ra_let = TO_DATE(v_fec_venc_prim_letr, 'DD/MM/YYYY')
            WHERE cod_simu = v_cod_simu and ind_inactivo = 'N';


            -- RECORRIENDO LA CONSULTA
            FOR c IN (SELECT to_number(cod_nume_letr) AS cod_nume_letr
                      FROM vve_cred_simu_lede
                      WHERE cod_simu = v_cod_simu
                      GROUP BY cod_nume_letr
                      ORDER BY to_number(cod_nume_letr))
                LOOP
                    -- OBTENIENDO LAS FECHAS PARA LAS SIGUIENTES CUOTAS
                    IF c.cod_nume_letr != 1 THEN
                        SELECT TO_CHAR(add_months(TO_DATE(v_fec_venc_prim_letr, 'DD/MM/YYYY'), v_valor_peri / 30), 'DD/MM/YYYY')
                        INTO v_fec_venc_prim_letr
                        FROM dual;

                        -- ACTUALIZANDO FECHAS
                        UPDATE vve_cred_simu_lede
                        SET fec_venc = TO_DATE(v_fec_venc_prim_letr, 'DD/MM/YYYY')
                        WHERE cod_simu = v_cod_simu
                        AND cod_nume_letr = c.cod_nume_letr;

                        UPDATE vve_cred_simu_letr
                        SET fec_venc    = TO_DATE(v_fec_venc_prim_letr, 'DD/MM/YYYY')
                        WHERE cod_simu  = v_cod_simu
                        AND cod_nume_letr = c.cod_nume_letr;
                    END IF;
                END LOOP;

            -- Actualizando fecha de ejecución de registro de la actividad
            PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E4','A20',p_cod_usua_sid,p_ret_esta,p_ret_mens);

        END IF;

        --<I Req. 87567 E2.1 ID## avilca  18/02/2020>
        -- ACTUALIZANDO LA PRIMERA Y ULTIMA FECHA DE POLIZA
            SELECT max(fec_venc) INTO v_fec_venc_ult_letr
            FROM vve_cred_simu_lede WHERE cod_simu = v_cod_simu;

            BEGIN
                SELECT fec_inic_vige_poli,fec_fin_vige_poli
                INTO  v_fec_ini_vp, v_fec_fin_vp
                FROM vve_cred_soli
                WHERE cod_soli_cred = p_cod_soli_cred;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_fec_ini_vp:= NULL;
                v_fec_fin_vp:= NULL;
            END;

            IF v_fec_ini_vp IS NOT NULL AND v_fec_fin_vp IS NOT NULL THEN
                UPDATE vve_cred_soli
                SET
                    fec_inic_vige_poli = TO_DATE(p_fec_venc_1ra_let, 'DD/MM/YYYY'),
                    fec_fin_vige_poli = TO_DATE(v_fec_venc_ult_letr, 'DD/MM/YYYY')
                WHERE cod_soli_cred = p_cod_soli_cred;
            END IF;
       --<F Req. 87567 E2.1 ID## avilca  18/02/2020>

        IF p_fec_apro_clie IS NOT NULL THEN
            -- ACTUALIZANDO LA FECHA DE APROB. DE CLIENTE
            UPDATE vve_cred_soli
            SET fec_apro_clie = TO_DATE(p_fec_apro_clie, 'DD/MM/YYYY')
            WHERE cod_soli_cred = p_cod_soli_cred;

            -- Cuenta cuantos aprobadores aprobaron la solicitud
            BEGIN
              SELECT COUNT(*)
              INTO   v_cont_apro
              FROM   vve_cred_soli_apro
              WHERE  cod_soli_cred = p_cod_soli_cred
              AND    est_apro = 'EEA01';
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_cont_apro := 0;
            END;

            -- Cuenta el nro de niveles de aprobación que se generó para la solicitud
            BEGIN
              SELECT COUNT(*)
              INTO   v_ind_niveles
              FROM   vve_cred_soli_apro
              WHERE  cod_soli_cred = p_cod_soli_cred;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_ind_niveles := 0;
            END;

            IF v_cont_apro = v_ind_niveles AND v_ind_niveles > 0 THEN
              UPDATE vve_cred_soli SET cod_estado = 'ES04' where cod_soli_cred = p_cod_soli_cred;
            END IF;


            BEGIN
              SELECT COUNT(*)
              INTO   v_cont_rech
              FROM   vve_cred_soli_apro
              WHERE  cod_soli_cred = p_cod_soli_cred
              AND    est_apro = 'EEA03';
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_cont_rech := 0;
            END;

            IF v_cont_rech >0 THEN
               UPDATE vve_cred_soli SET cod_estado = 'ES06' where cod_soli_cred = p_cod_soli_cred;
            END IF;

            PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E4','A22',p_cod_usua_sid,p_ret_esta,p_ret_mens);
            PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E4','A23',p_cod_usua_sid,p_ret_esta,p_ret_mens);
        END IF;

        IF p_fec_contrato IS NOT NULL THEN
            -- ACTUALIZANDO LA FECHA DE CONTRATO
            UPDATE vve_cred_soli
            SET fec_firm_cont = TO_DATE(p_fec_contrato, 'DD/MM/YYYY')
            WHERE cod_soli_cred = p_cod_soli_cred;
        END IF;

        IF p_txt_info_adic IS NOT NULL THEN
            UPDATE vve_cred_soli
            SET txt_info_adic = p_txt_info_adic
            WHERE cod_soli_cred = p_cod_soli_cred;
        END IF;

        IF p_txt_info_oper IS NOT NULL THEN
            UPDATE vve_cred_soli
            SET txt_info_oper = p_txt_info_oper
            WHERE cod_soli_cred = p_cod_soli_cred;
        END IF;

        -- OBTENIENDO EL VALOR DEL MONTO LETRA
        SELECT SUM(val_mon_conc)
        INTO v_val_mon_conc
        FROM vve_cred_simu_lede
        WHERE cod_simu = v_cod_simu
            AND cod_conc_col = 5
            AND cod_nume_letr > (
                SELECT can_letr_peri_grac
                FROM vve_cred_soli
                WHERE cod_soli_cred = p_cod_soli_cred
            );


    END IF;

  /** I Req. 87567 E2.1 ID: 309 - avilca 24/03/2020 **/
   -- IF  p_plazo_fact_cred IS NOT NULL THEN EBARBOZA REVERTIR

        IF p_fec_apro_clie IS NOT NULL THEN
            -- ACTUALIZANDO LA FECHA DE APROB. DE CLIENTE
            UPDATE vve_cred_soli
            SET fec_apro_clie = TO_DATE(p_fec_apro_clie, 'DD/MM/YYYY')
            WHERE cod_soli_cred = p_cod_soli_cred;

            -- Cuenta cuantos aprobadores aprobaron la solicitud
            BEGIN
              SELECT COUNT(*)
              INTO   v_cont_apro
              FROM   vve_cred_soli_apro
              WHERE  cod_soli_cred = p_cod_soli_cred
              AND    est_apro = 'EEA01';
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_cont_apro := 0;
            END;

            -- Cuenta el nro de niveles de aprobación que se generó para la solicitud
            BEGIN
              SELECT COUNT(*)
              INTO   v_ind_niveles
              FROM   vve_cred_soli_apro
              WHERE  cod_soli_cred = p_cod_soli_cred;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_ind_niveles := 0;
            END;

            IF v_cont_apro = v_ind_niveles AND v_ind_niveles > 0 THEN
              UPDATE vve_cred_soli SET cod_estado = 'ES04' where cod_soli_cred = p_cod_soli_cred;
            END IF;

            BEGIN
              SELECT COUNT(*)
              INTO   v_cont_rech
              FROM   vve_cred_soli_apro
              WHERE  cod_soli_cred = p_cod_soli_cred
              AND    est_apro = 'EEA03';
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_cont_rech := 0;
            END;

            IF v_cont_rech >0 THEN
               UPDATE vve_cred_soli SET cod_estado = 'ES06' where cod_soli_cred = p_cod_soli_cred;
            END IF;

            PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E4','A22',p_cod_usua_sid,p_ret_esta,p_ret_mens);
            PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E4','A23',p_cod_usua_sid,p_ret_esta,p_ret_mens);
        END IF;



        IF p_plazo_fact_cred IS NOT NULL THEN
            UPDATE vve_cred_soli
            SET can_dias_fact_cred = p_plazo_fact_cred
            WHERE cod_soli_cred = p_cod_soli_cred;
        END IF;



       IF p_txt_info_adic IS NOT NULL THEN
            UPDATE vve_cred_soli
            SET txt_info_adic = p_txt_info_adic
            WHERE cod_soli_cred = p_cod_soli_cred;
        END IF;

        IF p_txt_info_oper IS NOT NULL THEN
            UPDATE vve_cred_soli
            SET txt_info_oper = p_txt_info_oper
            WHERE cod_soli_cred = p_cod_soli_cred;
        END IF;

   /** I Req. 87567 E2.1 ID: 309 - avilca 14/04/2021 **/
     IF p_monto_financiar IS NOT NULL THEN
           UPDATE vve_cred_soli
           SET val_mon_fin = p_monto_financiar
           WHERE cod_soli_cred = p_cod_soli_cred;
     END IF;
   /** F Req. 87567 E2.1 ID: 309 - avilca 14/04/2021 **/

   -- END IF; EBARBOZA REVERTIR
 /** F Req. 87567 E2.1 ID: 309 - avilca 24/03/2020 **/
     -- OBTENIENDO LA LISTA
        OPEN p_ret_cursor FOR
            SELECT
                val_mon_fin,
                (
                    SELECT descripcion
                    FROM vve_tabla_maes
                    WHERE cod_grupo = 88
                        AND cod_tipo = cod_peri_cred_soli
                ) AS cod_peri_cred_soli,
                val_prim_seg,
                (
                    SELECT descripcion
                    FROM vve_tabla_maes
                    WHERE cod_grupo = 89
                        AND cod_tipo = ind_tipo_peri_grac
                ) AS ind_tipo_peri_grac,
                can_letr_peri_grac,
                fec_venc_1ra_let AS fec_venc_prim_let,
                can_tota_letr,
                can_tota_letr - can_letr_peri_grac AS letras_camort,
                v_val_mon_conc AS val_mon_conc,
                can_dias_fact_cred,
                fec_apro_clie,
                txt_info_adic,
                txt_info_oper,
                fec_firm_cont,
                can_dias_fact_cred /**Req. 87567 E2.1 ID: 309 - avilca 24/03/2020 **/
            FROM vve_cred_soli
            WHERE cod_soli_cred = p_cod_soli_cred;



    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'Se actualizaron los datos de manera exitosa';

  EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_LIST_CRED_SOLI_RESO_CRED',
                                            p_cod_usua_sid,
                                            'Error en la actualización',
                                            p_ret_mens,
                                            NULL);
        ROLLBACK;
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LIST_CRED_SOLI_RESO_CRED:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                            'SP_LIST_CRED_SOLI_RESO_CRED',
                                            p_cod_usua_sid,
                                            'Error en la actualización',
                                            p_ret_mens,
                                            NULL);
        ROLLBACK;
    END sp_list_cred_soli_reso_cred;

    PROCEDURE sp_list_resu_reso_cred
    (
        p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
        p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
        p_ret_cursor          OUT               SYS_REFCURSOR,
        p_ret_esta            OUT               NUMBER,
        p_ret_mens            OUT               VARCHAR2
    ) AS
        ve_error EXCEPTION;
        v_val_ano_fab NUMBER;
        v_cod_clasif_sbs_clie VARCHAR2(200);
        v_val_deud_actu_clie NUMBER;
        v_tip_soli_cred VARCHAR2(5);

        BEGIN

            -- Año
            BEGIN
                SELECT
                    distinct mg.val_ano_fab
                    INTO v_val_ano_fab
                FROM
                    vve_cred_soli s
                    INNER JOIN vve_cred_soli_gara sg ON (sg.cod_soli_cred = s.cod_soli_cred)
                    INNER JOIN vve_cred_maes_gara mg ON (sg.cod_gara = mg.cod_garantia)
                WHERE
                    s.cod_soli_cred = p_cod_soli_cred AND mg.ind_adicional = 'N'; -- AND ind_adicional = 'N';
                EXCEPTION
                    WHEN OTHERS THEN
                    v_val_ano_fab := 0;
            END;

            BEGIN
                SELECT
                    cod_clasif_sbs_clie, val_deud_actu_clie INTO v_cod_clasif_sbs_clie, v_val_deud_actu_clie
                FROM
                    vve_cred_soli_isbs
                WHERE
                    cod_soli_cred = p_cod_soli_cred;
                EXCEPTION
                    WHEN OTHERS THEN
                    v_cod_clasif_sbs_clie := '-';
                    v_val_deud_actu_clie := 0;
            END;
            /** I Req. 87567 E2.1 ID: 309 - avilca 24/03/2020 **/
            BEGIN
                SELECT s.tip_soli_cred INTO v_tip_soli_cred
                 FROM vve_cred_soli s
                WHERE s.cod_soli_cred = p_cod_soli_cred;
              EXCEPTION
                    WHEN OTHERS THEN
                     v_tip_soli_cred := 0;
            END;

            IF v_tip_soli_cred = 'TC04' THEN

             OPEN p_ret_cursor FOR
                SELECT
                s.val_porc_ci, -- Cuota inicial: vve_cred_soli.val_porc_ci, vve_cred_soli.val_ci
                s.val_ci, -- Cuota inicial: vve_cred_soli.val_porc_ci, vve_cred_soli.val_ci
                s.val_mon_fin as mont_cred, -- Monto crédito: vve_cred_soli.val_mon_fin + vve_cred_soli.val_prim_seg
                s.can_plaz_mes, -- Plazo (meses): vve_cred_soli.can_plaz_mes
                s.val_porc_tea_sigv, -- TEA(s/igv): vve_cred_soli.val_porc_tea_sigv
                s.can_dias_venc_1ra_letr as can_dias_venc_prim_letr, -- Venc. 1ra letra: del vve_cred_soli.can_dias_venc_1ra_let
                (
                    SELECT SUM(can_veh_fin)
                    FROM vve_cred_soli_prof
                    WHERE cod_soli_cred = s.cod_soli_cred
                ) as can_veh_fin, -- Nro. Unidades: vve_cred_soli_prof.can_veh
                gav.des_area_vta, -- Unidad de negocio: vve_proforma_veh. cod_area_vta
                gm.nom_marca, -- Marca: vve_proforma_veh.cod_marca
                (pd.val_pre_veh *
                (
                    SELECT SUM(can_veh_fin)
                    FROM vve_cred_soli_prof
                    WHERE cod_soli_cred = s.cod_soli_cred
                )
                ) as prec_total, -- Precio Total: vve_proforma_veh.val_pre_veh*nro unidades
                UPPER(tc.descripcion) as descripcion, -- Tipo de crédito
                --si.can_let_per_gra + si.can_tot_let as nro_letras, -- Nro letras: tomar las del simulador y las letras de periodo de gracia
                cod_sociedad, UPPER(nom_sociedad) as nom_sociedad, -- Seguro dive: Si es dive => Si, Divemotor /No , seguro endosado
                v_val_ano_fab AS val_ano_fab,
                decode(s.ind_gps, 'S', 'SI', 'NO') AS gps,
                decode(s.ind_tipo_segu, 'TS01', 'DIVEMOTOR', '-') AS gps_deta,
                decode(s.ind_tipo_segu, 'TS01', 'SI','NO') AS seguro,
                decode(s.ind_tipo_segu, 'TS01', 'DIVEMOTOR','ENDOSADO') AS seguro_deta,
                g.nom_perso,
                v_cod_clasif_sbs_clie as cod_clasif_sbs_clie,
                v_val_deud_actu_clie as val_deuda_actu_clie,
                decode(v_val_deud_actu_clie, 0, 'NO', 'SI') as val_deuda_deta,
                s.txt_info_adic,
                s.txt_info_oper,
                (SELECT NVL(sum(val_saldo), 0) as saldo_directo from vve_cred_hist_ope
                where cod_soli_cred = p_cod_soli_cred and cod_tip_cred IN ('TC02','TC03')) as saldo_mutuo,
                (SELECT NVL(SUM(val_saldo), 0) from vve_cred_hist_ope
                where cod_soli_cred = p_cod_soli_cred and cod_tip_cred = 'TC01') as saldo_directo,
                (SELECT NVL(sum(val_saldo), 0) as saldo_directo from vve_cred_hist_ope
                where cod_soli_cred = p_cod_soli_cred and cod_tip_cred IN ('TC01','TC02','TC03')) as saldo_mut_dire,
                s.val_gasto_admi as val_gast_admi,
                s.can_dias_fact_cred --Req. 87567 E2.1 ID:45 - avilca 15/06/2020
                from vve_cred_soli s
                INNER JOIN gen_persona g on (g.cod_perso = s.cod_clie)
                INNER JOIN vve_cred_soli_prof p on (s.cod_soli_cred = p.cod_soli_cred)
                INNER JOIN vve_proforma_veh pv on (p.num_prof_veh = pv.num_prof_veh)
                INNER JOIN vve_proforma_veh_det pd on (pv.num_prof_veh = pd.num_prof_veh)
                INNER JOIN gen_marca gm on (pd.cod_marca = gm.cod_marca)
                LEFT JOIN vve_tabla_maes tc ON (s.tip_soli_cred = tc.cod_tipo AND tc.cod_grupo_rec = '86' AND tc.cod_tipo_rec = 'TC')                
                INNER JOIN gen_mae_sociedad ms ON (s.cod_empr = ms.cod_cia)
                INNER JOIN gen_area_vta gav ON gav.cod_area_vta = s.cod_area_vta
                where s.cod_soli_cred = p_cod_soli_cred;

            ELSE
            /** F Req. 87567 E2.1 ID: 309 - avilca 24/03/2020 **/
            IF  v_tip_soli_cred = 'TC05' THEN

            OPEN p_ret_cursor FOR
                SELECT
                s.val_porc_ci, -- Cuota inicial: vve_cred_soli.val_porc_ci, vve_cred_soli.val_ci
                s.val_ci, -- Cuota inicial: vve_cred_soli.val_porc_ci, vve_cred_soli.val_ci
                s.val_mon_fin as mont_cred, -- Monto crédito: vve_cred_soli.val_mon_fin + vve_cred_soli.val_prim_seg
                s.can_plaz_mes, -- Plazo (meses): vve_cred_soli.can_plaz_mes
                s.val_porc_tea_sigv, -- TEA(s/igv): vve_cred_soli.val_porc_tea_sigv
                s.can_dias_venc_1ra_letr as can_dias_venc_prim_letr, -- Venc. 1ra letra: del vve_cred_soli.can_dias_venc_1ra_let
                (
                    SELECT SUM(can_veh_fin)
                    FROM vve_cred_soli_prof
                    WHERE cod_soli_cred = s.cod_soli_cred
                ) as can_veh_fin, -- Nro. Unidades: vve_cred_soli_prof.can_veh
                gav.des_area_vta, -- Unidad de negocio: vve_proforma_veh. cod_area_vta
                null nom_marca, -- Marca: vve_proforma_veh.cod_marca
                0 as prec_total, -- Precio Total: vve_proforma_veh.val_pre_veh*nro unidades
                UPPER(tc.descripcion) as descripcion, -- Tipo de crédito
                si.can_let_per_gra + si.can_tot_let as nro_letras, -- Nro letras: tomar las del simulador y las letras de periodo de gracia
                cod_sociedad, UPPER(nom_sociedad) as nom_sociedad, -- Seguro dive: Si es dive => Si, Divemotor /No , seguro endosado
                v_val_ano_fab AS val_ano_fab,
                decode(s.ind_gps, 'S', 'SI', 'NO') AS gps,
                decode(s.ind_tipo_segu, 'TS01', 'DIVEMOTOR', '-') AS gps_deta,
                decode(s.ind_tipo_segu, 'TS01', 'SI','NO') AS seguro,
                decode(s.ind_tipo_segu, 'TS01', 'DIVEMOTOR','ENDOSADO') AS seguro_deta,
                g.nom_perso,
                v_cod_clasif_sbs_clie as cod_clasif_sbs_clie,
                v_val_deud_actu_clie as val_deuda_actu_clie,
                decode(v_val_deud_actu_clie, 0, 'NO', 'SI') as val_deuda_deta,
                s.txt_info_adic,
                s.txt_info_oper,
                (SELECT NVL(sum(val_saldo), 0) as saldo_directo from vve_cred_hist_ope
                where cod_soli_cred = p_cod_soli_cred and cod_tip_cred IN ('TC02','TC03')) as saldo_mutuo,
                (SELECT NVL(SUM(val_saldo), 0) from vve_cred_hist_ope
                where cod_soli_cred = p_cod_soli_cred and cod_tip_cred = 'TC01') as saldo_directo,
                (SELECT NVL(sum(val_saldo), 0) as saldo_directo from vve_cred_hist_ope
                where cod_soli_cred = p_cod_soli_cred and cod_tip_cred IN ('TC01','TC02','TC03')) as saldo_mut_dire,
                s.val_gasto_admi as val_gast_admi
                from vve_cred_soli s
                INNER JOIN gen_persona g on (g.cod_perso = s.cod_clie)
                LEFT JOIN vve_tabla_maes tc ON (s.tip_soli_cred = tc.cod_tipo AND tc.cod_grupo_rec = '86' AND tc.cod_tipo_rec = 'TC')
                INNER JOIN vve_cred_simu si ON (s.cod_soli_cred = si.cod_soli_cred AND si.ind_inactivo = 'N')
                INNER JOIN gen_mae_sociedad ms ON (s.cod_empr = ms.cod_cia)
                INNER JOIN gen_area_vta gav ON gav.cod_area_vta = s.cod_area_vta
                where s.cod_soli_cred = p_cod_soli_cred;


            ELSE

             OPEN p_ret_cursor FOR
                SELECT
                s.val_porc_ci, -- Cuota inicial: vve_cred_soli.val_porc_ci, vve_cred_soli.val_ci
                s.val_ci, -- Cuota inicial: vve_cred_soli.val_porc_ci, vve_cred_soli.val_ci
                s.val_mon_fin as mont_cred, -- Monto crédito: vve_cred_soli.val_mon_fin + vve_cred_soli.val_prim_seg
                s.can_plaz_mes, -- Plazo (meses): vve_cred_soli.can_plaz_mes
                s.val_porc_tea_sigv, -- TEA(s/igv): vve_cred_soli.val_porc_tea_sigv
                s.can_dias_venc_1ra_letr as can_dias_venc_prim_letr, -- Venc. 1ra letra: del vve_cred_soli.can_dias_venc_1ra_let
                (
                    SELECT SUM(can_veh_fin)
                    FROM vve_cred_soli_prof
                    WHERE cod_soli_cred = s.cod_soli_cred
                ) as can_veh_fin, -- Nro. Unidades: vve_cred_soli_prof.can_veh
                gav.des_area_vta, -- Unidad de negocio: vve_proforma_veh. cod_area_vta
                gm.nom_marca, -- Marca: vve_proforma_veh.cod_marca
                (pd.val_pre_veh *
                (
                    SELECT SUM(can_veh_fin)
                    FROM vve_cred_soli_prof
                    WHERE cod_soli_cred = s.cod_soli_cred
                )
                ) as prec_total, -- Precio Total: vve_proforma_veh.val_pre_veh*nro unidades
                UPPER(tc.descripcion) as descripcion, -- Tipo de crédito
                si.can_let_per_gra + si.can_tot_let as nro_letras, -- Nro letras: tomar las del simulador y las letras de periodo de gracia
                cod_sociedad, UPPER(nom_sociedad) as nom_sociedad, -- Seguro dive: Si es dive => Si, Divemotor /No , seguro endosado
                v_val_ano_fab AS val_ano_fab,
                decode(s.ind_gps, 'S', 'SI', 'NO') AS gps,
                decode(s.ind_tipo_segu, 'TS01', 'DIVEMOTOR', '-') AS gps_deta,
                decode(s.ind_tipo_segu, 'TS01', 'SI','NO') AS seguro,
                decode(s.ind_tipo_segu, 'TS01', 'DIVEMOTOR','ENDOSADO') AS seguro_deta,
                g.nom_perso,
                v_cod_clasif_sbs_clie as cod_clasif_sbs_clie,
                v_val_deud_actu_clie as val_deuda_actu_clie,
                decode(v_val_deud_actu_clie, 0, 'NO', 'SI') as val_deuda_deta,
                s.txt_info_adic,
                s.txt_info_oper,
                (SELECT NVL(sum(val_saldo), 0) as saldo_directo from vve_cred_hist_ope
                where cod_soli_cred = p_cod_soli_cred and cod_tip_cred IN ('TC02','TC03')) as saldo_mutuo,
                (SELECT NVL(SUM(val_saldo), 0) from vve_cred_hist_ope
                where cod_soli_cred = p_cod_soli_cred and cod_tip_cred = 'TC01') as saldo_directo,
                (SELECT NVL(sum(val_saldo), 0) as saldo_directo from vve_cred_hist_ope
                where cod_soli_cred = p_cod_soli_cred and cod_tip_cred IN ('TC01','TC02','TC03')) as saldo_mut_dire,
                s.val_gasto_admi as val_gast_admi
                from vve_cred_soli s
                INNER JOIN gen_persona g on (g.cod_perso = s.cod_clie)
                INNER JOIN vve_cred_soli_prof p on (s.cod_soli_cred = p.cod_soli_cred)
                INNER JOIN vve_proforma_veh pv on (p.num_prof_veh = pv.num_prof_veh)
                INNER JOIN vve_proforma_veh_det pd on (pv.num_prof_veh = pd.num_prof_veh)
                INNER JOIN gen_marca gm on (pd.cod_marca = gm.cod_marca)
                LEFT JOIN vve_tabla_maes tc ON (s.tip_soli_cred = tc.cod_tipo AND tc.cod_grupo_rec = '86' AND tc.cod_tipo_rec = 'TC')
                INNER JOIN vve_cred_simu si ON (s.cod_soli_cred = si.cod_soli_cred AND si.ind_inactivo = 'N')
                INNER JOIN gen_mae_sociedad ms ON (s.cod_empr = ms.cod_cia)
                INNER JOIN gen_area_vta gav ON gav.cod_area_vta = s.cod_area_vta
                where s.cod_soli_cred = p_cod_soli_cred;

               END IF;

            END IF;


                p_ret_esta := 1;
                p_ret_mens := 'La consulta se realizó de manera exitosa';

        EXCEPTION
            WHEN ve_error THEN
                p_ret_esta := 0;
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_RESU_RESO_CRED', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
                , NULL);
            WHEN OTHERS THEN
                p_ret_esta := -1;
                p_ret_mens := 'SP_LIST_RESU_RESO_CRED:' || sqlerrm;
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_RESU_RESO_CRED', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
                , NULL);

        END sp_list_resu_reso_cred;


PROCEDURE sp_inse_cred_soli_aprob
    (
        p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
        p_num_prof_veh        IN                vve_cred_soli_prof.num_prof_veh%TYPE,
        p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta            OUT               NUMBER,
        p_ret_mens            OUT               VARCHAR2
    ) AS
        ve_error            EXCEPTION;
        v_cod_simu          NUMBER;
        v_cod_area_vta      vve_proforma_veh.cod_area_vta%TYPE;
        v_cod_filial        vve_proforma_veh.cod_filial%TYPE;
        v_cod_zona          vve_mae_zona_filial.cod_zona%TYPE;
        v_cod_id_usuario    NUMBER;
        v_contador          NUMBER;
        v_flag_valida       NUMBER;
        v_tip_soli_cred VARCHAR2(5);
        v_rol_gescre_gaf VARCHAR2(10); /** Req. 87567 E2.1 ID: 309 - avilca 08/03/2021 **/

    BEGIN

        v_flag_valida := 0;


        BEGIN
            SELECT count(*) INTO v_contador
            FROM vve_cred_soli_apro WHERE cod_soli_cred = p_cod_soli_cred
            AND ind_inactivo = 'N'; /** Req. 87567 E2.1 ID: 309 - avilca 08/03/2021 **/
        EXCEPTION
            WHEN OTHERS THEN
            v_contador := 0;
        END;

       /** I Req. 87567 E2.1 ID: 309 - avilca 25/03/2020 **/
            BEGIN
                SELECT s.tip_soli_cred INTO v_tip_soli_cred
                 FROM vve_cred_soli s
                WHERE s.cod_soli_cred = p_cod_soli_cred;
              EXCEPTION
                    WHEN OTHERS THEN
                     v_tip_soli_cred := 0;
            END;
             /** I Req. 87567 E2.1 ID: 309 - avilca 08/03/2021 **/
            BEGIN
             SELECT cod_id_perfil INTO v_rol_gescre_gaf
             FROM sis_mae_perfil
             where txt_cod_perfil= 'ROL_GESCRE_GAF';
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
                v_rol_gescre_gaf:= '0';
            END;
          /** F Req. 87567 E2.1 ID: 309 - avilca 08/03/2021 **/
        IF v_contador > 0 THEN

            p_ret_esta := 1;
            p_ret_mens := 'La solicitud ya cuenta con Registro de Solicitud de Aprobación';

        ELSE
          IF v_tip_soli_cred = 'TC04' THEN

                        SELECT cod_area_vta, cod_filial
                        INTO   v_cod_area_vta, v_cod_filial
                        FROM   vve_proforma_veh p, vve_cred_soli_prof sp
                        WHERE  sp.cod_soli_cred = p_cod_soli_cred
                        AND    p.num_prof_veh = sp.num_prof_veh
                        AND    rownum = 1;

                        SELECT cod_zona INTO v_cod_zona FROM vve_mae_zona_filial z where cod_filial = v_cod_filial;

                        SELECT cod_id_usuario INTO v_cod_id_usuario
                        FROM  sis_mae_usuario
                        WHERE txt_usuario IN (SELECT co_usuario FROM VVE_CRED_ORG_CRED_VTAS
                                              WHERE  cod_zona = v_cod_zona
                                              AND    cod_filial = v_cod_filial
                                              AND    cod_area_vta = v_cod_area_vta
                                              AND    cod_rol_usuario = v_rol_gescre_gaf);

           INSERT INTO VVE_CRED_SOLI_APRO
                    (
                        COD_CRIT_APRO,
                        COD_SOLI_CRED,
                        COD_ID_USUA,
                        EST_APRO,
                        COD_SIMU_APRO,
                        COD_PERFIL_USUA,
                        IND_INACTIVO,
                        IND_NIVEL,
                        COD_USUA_CREA_REGI,
                        FEC_CREA_REGI
                    )
                    VALUES
                    (
                        '1',
                        p_cod_soli_cred,
                        v_cod_id_usuario,
                        'EEA04',
                        NULL,
                        '1674691',
                        'N',
                        1,
                        p_cod_usua_sid,
                        SYSDATE
                    );

            -- seteando las actividades como obligatorios de los niveles generados para aprobación

                update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A29' AND cod_soli_cred = p_cod_soli_cred;

        /** F Req. 87567 E2.1 ID: 309 - avilca 25/03/2020 **/
      ELSE
       FOR rs IN (SELECT xc.cod_crit_apro,xc.cod_tip_ries_dive, xc.cod_perfil_usuario, xc.ind_nivel, xc.ind_usado, xc.tip_soli_cred
                  FROM vve_cred_crit_aprob xc
                  WHERE
                   xc.COD_TIP_RIES_DIVE IN (select cod_ries_dive_clie from vve_cred_soli_isbs where cod_soli_cred = p_cod_soli_cred)
                  AND xc.ind_nivel <= (
                  select min(c.ind_nivel)
                  FROM vve_cred_crit_aprob c, vve_cred_soli s
                  WHERE s.cod_soli_cred = p_cod_soli_cred
                  AND   c.COD_TIP_RIES_DIVE IN (select cod_ries_dive_clie from vve_cred_soli_isbs where cod_soli_cred = p_cod_soli_cred)
                  AND   0<(SELECT INSTR(c.txt_tip_area_vta,s.cod_area_vta) from dual)
                  AND   s.val_mon_fin <= c.val_lim_may_aprob
                  AND   c.val_rat_min_cob_gar <= nvl((select nvl(x.suma_garantias/(s.val_mon_fin),0) ratiocob--<Req. 87567 E2.1 ID## avilca 20/11/2020>
                                                  from (
                                                  select sum(g.val_realiz_gar) suma_garantias,sg.cod_soli_cred
                                                  from vve_cred_maes_gara g, vve_cred_soli_gara sg
                                                  where sg.cod_soli_cred = p_cod_soli_cred --s.cod_soli_cred --'00000000000000000023'
                                                  and g.cod_garantia = sg.cod_gara
                                                  and sg.ind_inactivo = 'N'
                                                  group by sg.cod_soli_cred) x, vve_cred_soli s
                                                  where s.cod_soli_cred = x.cod_soli_cred),0)--<Req. 87567 E2.1 ID## avilca 20/11/2020>
                  and decode(s.cod_area_vta,'014','U','N') = c.ind_usado
                  and nvl(c.val_porc_min_ci,0) <= (select val_porc_ci/100 from vve_cred_soli where cod_soli_cred = p_cod_soli_cred )
                  )
                  AND xc.ind_usado in (select decode(cod_area_vta,'014','U','N') from vve_cred_soli where cod_soli_cred = p_cod_soli_cred)
             )LOOP
               -- dbms_output.put_line('Paso 1');

                IF rs.ind_usado = 'U' THEN

                    IF rs.tip_soli_cred IS NULL OR rs.tip_soli_cred = 'TC01' THEN

                        SELECT cod_simu INTO v_cod_simu FROM vve_cred_simu WHERE cod_soli_cred = p_cod_soli_cred AND ind_inactivo = 'N';

                        SELECT cod_area_vta, cod_filial
                        INTO   v_cod_area_vta, v_cod_filial
                        FROM   vve_proforma_veh p, vve_cred_soli_prof sp
                        WHERE  sp.cod_soli_cred = p_cod_soli_cred
                        AND    p.num_prof_veh = sp.num_prof_veh
                        AND    rownum = 1;

                        SELECT cod_zona INTO v_cod_zona FROM vve_mae_zona_filial z where cod_filial = v_cod_filial;

                        SELECT cod_id_usuario INTO v_cod_id_usuario
                        FROM  sis_mae_usuario
                        WHERE txt_usuario IN (SELECT co_usuario FROM VVE_CRED_ORG_CRED_VTAS
                                              WHERE  cod_zona = v_cod_zona
                                              AND    cod_filial = v_cod_filial
                                              AND    cod_area_vta = v_cod_area_vta
                                              AND    cod_rol_usuario = rs.cod_perfil_usuario);

                        --SELECT cod_id_usuario INTO v_cod_id_usuario FROM sis_mae_perfil_usuario WHERE cod_id_perfil = rs.cod_perfil_usuario AND ROWNUM <= 1;

                        INSERT INTO VVE_CRED_SOLI_APRO
                        (
                            COD_CRIT_APRO,
                            COD_SOLI_CRED,
                            COD_ID_USUA,
                            EST_APRO,
                            COD_SIMU_APRO,
                            COD_PERFIL_USUA,
                            IND_INACTIVO,
                            IND_NIVEL,
                            COD_USUA_CREA_REGI,
                            FEC_CREA_REGI
                        )
                        VALUES
                        (
                            rs.cod_crit_apro,
                            p_cod_soli_cred,
                            v_cod_id_usuario,
                            --'EEA01',
                            'EEA04', -- Nacen como pendientes de aprobacion
                            v_cod_simu,
                            rs.cod_perfil_usuario,
                            'N',
                            rs.ind_nivel,
                            p_cod_usua_sid,
                            SYSDATE
                        );

                    END IF;

                    -- seteando las actividades como obligatorios de los niveles generados para aprobación
                    if rs.ind_nivel = 1 then -- JEFE DE FINANZAS
                      update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A26' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel = 2 then -- JEFE DE CREDITOS
                      update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A27' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel =  3 then -- GAF
                      update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A29' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel =  4 then -- GERENTE GRAL
                      update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A30' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel =  5 then -- DIRECTOR CORPORATIVO
                       update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A31' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel =  6 then -- PRESIDENTE
                       update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A32' AND cod_soli_cred = p_cod_soli_cred;
                    end if;



                ELSE

                    SELECT cod_simu INTO v_cod_simu FROM vve_cred_simu WHERE cod_soli_cred = p_cod_soli_cred AND ind_inactivo = 'N';

                        IF v_tip_soli_cred = 'TC05' OR v_tip_soli_cred = 'TC07' THEN
                            SELECT cod_area_vta,cod_filial
                            INTO   v_cod_area_vta, v_cod_filial
                            FROM vve_cred_soli
                            WHERE cod_soli_cred = p_cod_soli_cred;
                        ELSE
                            SELECT cod_area_vta, cod_filial
                            INTO   v_cod_area_vta, v_cod_filial
                            FROM   vve_proforma_veh p, vve_cred_soli_prof sp
                            WHERE  sp.cod_soli_cred = p_cod_soli_cred
                            AND    p.num_prof_veh = sp.num_prof_veh
                            AND    rownum = 1;
                        END IF;

                        SELECT cod_zona INTO v_cod_zona FROM vve_mae_zona_filial z where cod_filial = v_cod_filial;

                        SELECT cod_id_usuario INTO v_cod_id_usuario
                        FROM  sis_mae_usuario
                        WHERE txt_usuario IN (SELECT co_usuario FROM VVE_CRED_ORG_CRED_VTAS
                                              WHERE  cod_zona = v_cod_zona
                                              AND    cod_filial = v_cod_filial
                                              AND    cod_area_vta = v_cod_area_vta
                                              AND    cod_rol_usuario = rs.cod_perfil_usuario);

                        --SELECT cod_id_usuario INTO v_cod_id_usuario FROM sis_mae_perfil_usuario WHERE cod_id_perfil = rs.cod_perfil_usuario AND ROWNUM <= 1;

                    INSERT INTO VVE_CRED_SOLI_APRO
                    (
                        COD_CRIT_APRO,
                        COD_SOLI_CRED,
                        COD_ID_USUA,
                        EST_APRO,
                        COD_SIMU_APRO,
                        COD_PERFIL_USUA,
                        IND_INACTIVO,
                        IND_NIVEL,
                        COD_USUA_CREA_REGI,
                        FEC_CREA_REGI
                    )
                    VALUES
                    (
                        rs.cod_crit_apro,
                        p_cod_soli_cred,
                        v_cod_id_usuario,
                        'EEA04',
                        v_cod_simu,
                        rs.cod_perfil_usuario,
                        'N',
                        rs.ind_nivel,
                        p_cod_usua_sid,
                        SYSDATE
                    );

                    -- seteando las actividades como obligatorios de los niveles generados para aprobación
                    if rs.ind_nivel = 1 then -- JEFE DE FINANZAS
                      update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A26' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel = 2 then -- JEFE DE CREDITOS
                      update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A27' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel =  3 then -- GAF
                      update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A29' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel =  4 then -- GERENTE GRAL
                      update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A30' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel =  5 then -- DIRECTOR CORPORATIVO
                       update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A31' AND cod_soli_cred = p_cod_soli_cred;
                    elsif  rs.ind_nivel =  6 then -- PRESIDENTE
                       update vve_cred_soli_acti set ind_inactivo = 'N' where cod_acti_cred = 'A32' AND cod_soli_cred = p_cod_soli_cred;
                    end if;

                END IF;

            END LOOP;
         END IF;
            PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E4','A24',p_cod_usua_sid,p_ret_esta,p_ret_mens);
            PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E4','A25',p_cod_usua_sid,p_ret_esta,p_ret_mens);

            p_ret_esta := 1;
            p_ret_mens := 'Se registró correctamente la Solicitud de Aprobación';

        END IF;

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI_APROB', p_cod_usua_sid, 'Error en la inserción', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_INSE_CRED_SOLI_APROB:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI_APROB', p_cod_usua_sid, 'Error en la inserción', p_ret_mens
            , NULL);
    END sp_inse_cred_soli_aprob;


    PROCEDURE sp_actu_cred_soli_aprob
    (
        p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
        p_valor_estado        IN                VARCHAR2,
        p_txt_coment          IN                VARCHAR2,
        p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web        IN                sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_esta            OUT               NUMBER,
        p_ret_mens            OUT               VARCHAR2
    ) AS
        ve_error EXCEPTION;
        v_cod_id_usuario NUMBER;
        v_ind_nivel NUMBER;
        p_ret_correo NUMBER;
        p_ret_esta_correo NUMBER;
        p_ret_mens_correo VARCHAR2(1000);
        c_perfil_usuario  SYS_REFCURSOR;
        v_cod_id_perfil VARCHAR2(100);
        v_sql_base       VARCHAR2(4000);
        v_cont_aprobadores    NUMBER:=0;
        v_fec_apro_clie_ok    VARCHAR2(1);
        v_cont_rech           number;
        v_aprobados           NUMBER:=0;
        v_tip_soli_cred       varchar2(5);--I Req. 87567 E2.1 ID25 avilca 28.05.2020
    BEGIN

        BEGIN
            SELECT
                cod_id_usuario INTO v_cod_id_usuario
            FROM
                sis_mae_usuario
            WHERE
                txt_usuario = p_cod_usua_sid and IND_INACTIVO = 'N';
        EXCEPTION
            WHEN OTHERS THEN
            v_cod_id_usuario := 0;
        END;

        IF v_cod_id_usuario = 0 THEN

            p_ret_esta := 1;
            p_ret_mens := 'Hubo un error en la actualización de la Solicitud de Aprobación.';

        ELSE
          BEGIN
            SELECT COUNT(*)
            INTO   v_cont_aprobadores
            FROM   vve_cred_soli_apro
            WHERE  cod_soli_cred = p_cod_soli_cred
             AND ind_inactivo = 'N';--I Req. 87567 E2.1 ID25 avilca 08.03.2021
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
               v_cont_aprobadores := 0;
          END;

          BEGIN
            SELECT 'S'
            INTO   v_fec_apro_clie_ok
            FROM   vve_cred_soli
            WHERE  cod_soli_cred = p_cod_soli_cred
            AND    FEC_APRO_CLIE IS NOT NULL;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_fec_apro_clie_ok := 'N';
          END;

        BEGIN
            SELECT
                   tip_soli_cred
            INTO   v_tip_soli_cred
            FROM   vve_cred_soli
            WHERE  cod_soli_cred = p_cod_soli_cred;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tip_soli_cred := '';
          END;

          IF v_cont_aprobadores > 0 THEN
            SELECT MIN(ind_nivel) INTO v_ind_nivel FROM vve_cred_soli_apro
            WHERE cod_soli_cred = p_cod_soli_cred AND cod_id_usua = v_cod_id_usuario
            AND est_apro = 'EEA04';
            /*AND ROWNUM = 1
            ORDER BY ind_nivel;*/

            IF p_valor_estado = 'APRO' THEN

                dbms_output.put_line('Paso 1');
                dbms_output.put_line(p_txt_coment);
                dbms_output.put_line(p_cod_usua_web);

                UPDATE
                    vve_cred_soli_apro
                SET
                    txt_come_apro = p_txt_coment,
                    fec_esta_apro = SYSDATE,
                    est_apro = 'EEA01'
                WHERE
                    cod_id_usua = v_cod_id_usuario
                    AND ind_nivel = v_ind_nivel
                    AND cod_soli_cred = p_cod_soli_cred;

                SELECT COUNT(*)
                INTO   v_aprobados
                FROM   vve_cred_soli_apro
                WHERE  cod_soli_cred = p_cod_soli_cred
                AND    est_apro = 'EEA01';

                IF v_aprobados = v_cont_aprobadores AND (v_fec_apro_clie_ok = 'S' OR v_tip_soli_cred = 'TC04') THEN --I Req. 87567 E2.1 ID25 avilca 28.05.2020
                  update vve_cred_soli
                  set    cod_estado = 'ES04',
                         fec_apro_inte = to_date(sysdate,'dd/mm/yyyy')--I Req. 87567 E2.1 ID25 avilca 25.09.2020
                  WHERE  cod_soli_cred = p_cod_soli_cred;
                END IF;

                COMMIT;

                p_ret_esta := 1;
                p_ret_mens := 'Se aprobó correctamente la Solicitud.';

            ELSE

                dbms_output.put_line('Paso 2');

                dbms_output.put_line(p_txt_coment);
                dbms_output.put_line(p_cod_usua_sid);

                UPDATE
                    vve_cred_soli_apro
                SET
                    txt_come_rech = p_txt_coment,
                    fec_esta_rech = SYSDATE,
                    est_apro = 'EEA03'
                WHERE
                    cod_id_usua = v_cod_id_usuario
                    AND ind_nivel = v_ind_nivel
                    AND cod_soli_cred = p_cod_soli_cred;

                BEGIN
                  SELECT COUNT(*)
                  INTO   v_cont_rech
                  FROM   vve_cred_soli_apro
                  WHERE  cod_soli_cred = p_cod_soli_cred
                  AND    est_apro = 'EEA03';
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    v_cont_rech := 0;
                END;
                IF v_cont_rech >0 THEN
                   UPDATE vve_cred_soli SET cod_estado = 'ES06' where cod_soli_cred = p_cod_soli_cred;
                END IF;

                COMMIT;

                p_ret_esta := 1;
                p_ret_mens := 'Se rechazó correctamente la Solicitud.';

            END IF;
            v_sql_base := 'SELECT smp.TXT_COD_PERFIL FROM SIS_MAE_PERFIL_USUARIO smu
                           INNER JOIN SIS_MAE_PERFIL smp on smu.cod_id_perfil = smp.cod_id_perfil
                           WHERE smu.COD_ID_USUARIO ='||v_cod_id_usuario;

           OPEN c_perfil_usuario FOR v_sql_base;
                    LOOP
                    FETCH c_perfil_usuario INTO v_cod_id_perfil;
                    EXIT WHEN c_perfil_usuario%notfound;
                    BEGIN
                        IF v_cod_id_perfil = 'ROL_GESCRE_JEFE_FINANZAS' AND v_ind_nivel = 1 THEN
                          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E5','A26',p_cod_usua_sid,p_ret_esta,p_ret_mens);
                        END IF;

                       IF v_cod_id_perfil = 'ROL_GESCRE_JEFE_CREDITO' AND v_ind_nivel = 2 THEN
                          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E5','A27',p_cod_usua_sid,p_ret_esta,p_ret_mens);
                        END IF;

                        /*
                        IF v_cod_id_perfil = 'ROL_GERENTE_FINANZAS' THEN
                          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E5','A28',p_cod_usua_sid,p_ret_esta,p_ret_mens);
                        END IF;*/

                        IF (v_cod_id_perfil = 'ROL_GESCRE_GAF' AND v_ind_nivel = 3) OR
                          --<I Req. 87567 E2.1 ID38 AVILCA 16/06/2020>
                            (v_cod_id_perfil = 'ROL_GESCRE_GAF' AND v_ind_nivel = 1 AND v_tip_soli_cred = 'TC04') THEN
                         --<F Req. 87567 E2.1 ID38 AVILCA 16/06/2020>
                          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E5','A29',p_cod_usua_sid,p_ret_esta,p_ret_mens);
                        END IF;


                        IF v_cod_id_perfil = 'ROL_GESCRE_GTE_GRAL' AND v_ind_nivel = 4 THEN
                          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E5','A30',p_cod_usua_sid,p_ret_esta,p_ret_mens);
                        END IF;

                        IF v_cod_id_perfil = 'ROL_GESCRE_DIR_CORP' AND v_ind_nivel = 5 THEN
                          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E5','A31',p_cod_usua_sid,p_ret_esta,p_ret_mens);
                        END IF;

                        IF v_cod_id_perfil = 'ROL_GESCRE_PRESIDENTE' AND v_ind_nivel = 6 THEN
                          PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E5','A32',p_cod_usua_sid,p_ret_esta,p_ret_mens);
                        END IF;

                    END;
              END LOOP;
           END IF;
           CLOSE c_perfil_usuario;

        END IF;

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_ACTU_CRED_SOLI_APROB', p_cod_usua_sid, 'Error en la actualización', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_ACTU_CRED_SOLI_APROB:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_ACTU_CRED_SOLI_APROB', p_cod_usua_sid, 'Error en la actualización', p_ret_mens
            , NULL);
    END sp_actu_cred_soli_aprob;


  PROCEDURE sp_list_formato_recon_deuda
  (
    p_cod_soli_cred             IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid              IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor_cabe           OUT               SYS_REFCURSOR,
    p_ret_cursor_aval           OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi          OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_ghipo_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_garantias      OUT               SYS_REFCURSOR,
    p_ret_cursor_info_refinan   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_garante   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_ref_lea   OUT               SYS_REFCURSOR,
    p_ret_esta                  OUT               NUMBER,
    p_ret_mens                  OUT               VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_simu NUMBER;
    v_can_plaz_meses NUMBER;
    v_cod_empr VARCHAR(2);
    v_cod_ope_rel VARCHAR(6);
    v_cod_clie VARCHAR(8);
    c_facturas SYS_REFCURSOR;
    v_info_det_mutu VARCHAR(4000);
    v_sql_cadena VARCHAR(4000);
    v_no_docu arlcrd.no_docu%TYPE;
    v_fecha arlcrd.fecha%TYPE;
    v_cod_banco vve_cred_soli.cod_banco%TYPE;
    v_tip_soli_cred vve_cred_soli.tip_soli_cred%TYPE;

    BEGIN

        SELECT cod_empr, cod_banco INTO v_cod_empr, v_cod_banco FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;

        SELECT cod_oper_rel, cod_clie, tip_soli_cred INTO v_cod_ope_rel, v_cod_clie, v_tip_soli_cred FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;

        v_sql_cadena := 'SELECT no_docu, fecha FROM arlcrd WHERE cod_oper = ''' || v_cod_ope_rel ||  ''' ';

        OPEN c_facturas FOR v_sql_cadena;
        LOOP
        FETCH c_facturas INTO v_no_docu, v_fecha;
            EXIT WHEN c_facturas%notfound;
            dbms_output.put_line(v_no_docu);
            dbms_output.put_line(v_fecha);
            IF v_info_det_mutu is null THEN
              v_info_det_mutu := '- ' || v_no_docu || ' con Fecha ' || v_fecha || chr(13);
            ELSE
              v_info_det_mutu := v_info_det_mutu || '- ' || v_no_docu || ' con Fecha ' || v_fecha || chr(13);
            END IF;
        END LOOP;
        CLOSE c_facturas;

        OPEN p_ret_cursor_cabe FOR
            select
            -- SE MODIFICA CAMPOS PARA CHECK LIST MBARDALES 23/11/2020
            -- MODIFICACION PARA TITULO INICIAL DEL REPORTE
            (SELECT 'Créditos y Gestión Bancaria - '||z.des_zona
            from vve_mae_zona z, vve_cred_soli_prof sp, vve_proforma_veh p, vve_mae_zona_filial zf
            where sp.cod_soli_cred = p_cod_soli_cred
            and sp.num_prof_veh = p.num_prof_veh and p.cod_cia = v_cod_empr and p.cod_filial = zf.cod_filial and zf.cod_zona = z.cod_zona) as titulo,
            -- MODIFICACION PARA TITULO 2 DE INFORMACION
            (SELECT 'Información para la Elaboración de Contratos - '||t.descripcion FROM vve_tabla_maes t, vve_cred_soli s
            WHERE t.cod_grupo = 86 and s.cod_soli_cred = p_cod_soli_cred and s.tip_soli_cred = t.cod_tipo) as ind_info,
            -- MODIFICACION PARA INDICADOR DE NUEVO O USADO
            (SELECT UPPER(decode(nvl(ind_nu,'X'),'N', 'Nuevo','U','Usado','A','Nuevo/Usado','O','Ninguno'))
            FROM arlcop WHERE cod_oper = v_cod_ope_rel) as ind_nuevo_usado,
            -- MODIFICACION PARA NRO OPE / 2019
            (select cod_oper_rel||'/2019' from vve_cred_soli where cod_soli_cred = p_cod_soli_cred and cod_empr = v_cod_empr) as ind_nro_ope,
            --
            (select 'Persona ' || decode(cod_tipo_perso,'J','Jurídica','N','Natural') from gen_persona where cod_perso = s.cod_clie) as tipo_perso,
            DECODE(a.descrip,NULL,'-',a.descrip) as nom_empr,
            DECODE(s.cod_clie,NULL,'-',s.cod_clie) as cod_clie,
            DECODE(gp.nom_perso,NULL,'-',gp.nom_perso) as nom_perso,
            decode(gp.cod_tipo_perso, 'J', gp.num_ruc, gp.num_docu_iden) as num_docu,
            DECODE(dp.dir_domicilio,NULL,'-',dp.dir_domicilio) as dir_domicilio,
            DECODE(dis.des_nombre,NULL,'-',dis.des_nombre) as distrito,
            DECODE(pro.des_nombre,NULL,'-',pro.des_nombre) as provincia,
            DECODE(dep.des_nombre,NULL,'-',dep.des_nombre) as departamento,
            (SELECT nom_perso FROM gen_persona p, cxp_prov_giros g WHERE p.cod_perso = g.cod_prov AND g.cod_giro_perso = '012'
            AND cod_perso = s.cod_banco) as nom_banco,
            -- MODIFICACION PARA MARCA
            (select (select upper(nom_marca) from gen_marca where cod_marca = pd.cod_marca)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh ) as txt_marca,
            -- MODIFICACION PARA TIPO DE VEH
            (select lpad(to_char(pd.can_veh),2,'0')||' '|| (select upper(des_familia_veh) from vve_familia_veh where cod_familia_veh = pd.cod_familia_veh)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh ) as tipo_veh,
            -- MODIFICACION PARA AÑO DE FAB
            (select (select to_char(ano_fabricacion_veh,'9999') from vve_pedido_veh where cod_cia = s.cod_empr and num_prof_veh = sp.num_prof_veh and  rownum <= 1)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh) as val_ano_fab,
            -- MODIFICACION PARA MODELO
            (select (select upper(des_baumuster) from vve_baumuster where cod_baumuster = pd.cod_baumuster and cod_marca = pd.cod_marca)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh) as txt_modelo,
            -- MODIFICACION PARA CHASIS
            (select pe.num_chasis from vve_pedido_veh pe,vve_cred_soli_prof sp, vve_cred_soli s where s.cod_soli_cred = p_cod_soli_cred
            and s.cod_empr = v_cod_empr and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pe.num_prof_veh and  rownum <= 1 ) as nro_chasis,
            -- MODIFICACION PARA NRO DE MOTOR
            (select pe.num_motor_veh from vve_pedido_veh pe,vve_cred_soli_prof sp, vve_cred_soli s where s.cod_soli_cred = p_cod_soli_cred
            and s.cod_empr = v_cod_empr and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pe.num_prof_veh and  rownum <= 1) as nro_motor,
            --
            DECODE(mg.nro_placa,NULL,'-',mg.nro_placa) as nro_placa,
            s.val_porc_tea_sigv,
            -- MODIFICACION PARA PERIODO DE GRACIA
            (select decode((case ind_tip_per_gra when null then 'S' else  'N' end),'S','SI','N','NO')
            from vve_cred_simu where ind_inactivo = 'N' and cod_soli_cred = p_cod_soli_cred) as peri_gracia,
            -- MODIFICACION PARA PERIODO DE GRACIA SIN INT
            (select decode(nvl(ind_pgra_sint,'N'),'S','SI','N','NO')
            from vve_cred_simu where ind_inactivo = 'N' and cod_soli_cred = p_cod_soli_cred) as peri_grac_sin_int,
            -- MODIFICACION PARA DIAS PERIODO DE GRACIA
            (select val_dias_per_gra from vve_cred_simu where ind_inactivo = 'N' and cod_soli_cred = p_cod_soli_cred) as dias_peri_grac,
            s.val_int_per_gra,
            decode(s.ind_tipo_segu,'TS01','DIVEMOTOR','ENDOSADO') as tipo_segur,
            s.can_plaz_mes,
            upper(txt_nombres || ' ' || txt_apellidos) as nom_resp_fina,
            sbs.cod_clasif_sbs_clie,
            -- MODIFICACION PARA FIRM CONT
            to_char(s.fec_firm_cont, 'dd/MM/yyyy') as fec_firma_cont,
            -- MODIFICACION PARA ENTREGA LEGAL
            to_char(sysdate, 'dd/MM/yyyy') as fec_entre_leg,
            -- MODIFICACION PARA INFO DET MUTUO
            (select v_info_det_mutu from dual) as info_det_mutuo,
            -- MODIFICACION PARA NOMBRE DE BANCO MUTUO
            (SELECT nom_perso FROM gen_persona WHERE cod_perso = v_cod_banco) as nom_banco_mutuo
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia) -- maestro de garantias
            inner join vve_pedido_veh p on (p.num_pedido_veh = mg.num_pedido_veh) -- pedidos
            left join vve_tabla_maes tc ON (s.tip_soli_cred = tc.cod_tipo AND tc.cod_grupo_rec = '86' AND tc.cod_tipo_rec = 'TC')
            left join arccct a on (s.cod_empr = a.no_cia) -- nombre de compañias
            left join gen_persona gp on (gp.cod_perso = s.cod_clie) -- personas
            left join gen_dir_perso dp on (dp.cod_perso = s.cod_clie) -- direcciones
            inner join gen_mae_distrito dis on (dp.cod_distrito = dis.cod_id_distrito) -- distrito
            inner join gen_mae_provincia pro on (dp.cod_provincia = pro.cod_id_provincia) -- provincia
            inner join gen_mae_departamento dep on (dp.cod_dpto = dep.cod_id_departamento) -- departamento
            inner join sis_mae_usuario mu on (s.cod_resp_fina = mu.txt_usuario)
            left join vve_cred_soli_isbs sbs on (s.cod_soli_cred = sbs.cod_soli_cred)
            where s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N';

        OPEN p_ret_cursor_aval FOR
            -- SE AGREGAN CAMPOS PARA LISTA DE AVALES
            select
            (SELECT case when cod_estado_civil is not null and cod_estado_civil = 'C' THEN 'Sociedad Conyugal'
            when cod_tipo_perso = 'J' then 'Persona Jurídica'
            when cod_tipo_perso = 'N' then 'Persona Natural' END
            FROM gen_persona WHERE cod_perso = v_cod_clie) as tipo_pers_aval,
            DECODE(txt_nomb_pers || ' ' || txt_apel_pate_pers || ' ' || txt_apel_mate_pers,NULL,'-',txt_nomb_pers || ' ' || txt_apel_pate_pers || ' ' || txt_apel_mate_pers)  as nom_pers_aval,
            DECODE(txt_doi,NULL,'-', txt_doi) AS txt_doi,
            DECODE(txt_direccion,NULL,'-',txt_direccion) AS txt_direccion,
            DECODE(dis.des_nombre,NULL,'-',dis.des_nombre) as distrito,
            DECODE(pro.des_nombre,NULL,'-',pro.des_nombre) as provincia,
            DECODE(dep.des_nombre,NULL,'-',dep.des_nombre) as departamento,
            DECODE(ma.val_monto_fianza,NULL,0,ma.val_monto_fianza) as val_monto_fianza
            from vve_cred_mae_aval ma
            inner join gen_mae_distrito dis on (ma.cod_distrito = dis.cod_id_distrito) -- distrito
            inner join gen_mae_provincia pro on (ma.cod_provincia = pro.cod_id_provincia) -- provincia
            inner join gen_mae_departamento dep on (ma.cod_departamento = dep.cod_id_departamento) -- departamento
            where cod_rela_aval = 'RAVAL01';

        OPEN p_ret_cursor_gmobi FOR
            select
            decode(ind_tipo_bien,'P','SI','NO') as gar_propio,
            decode(ind_tipo_bien,'A','SI','NO') as gar_ajeno,
            decode(ind_otor,'D','DEUDOR','FIADOR') as otorgante,
            DECODE(nro_placa,NULL,'-',nro_placa) AS nro_placa
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N' and ind_tipo_garantia = 'M' and ind_adicional = 'N';

        OPEN p_ret_cursor_gmobi_adi FOR
            select
            decode(ind_tipo_bien,'P','SI','NO') as gar_propio,
            decode(ind_tipo_bien,'A','SI','NO') as gar_ajeno,
            decode(ind_otor,'D','DEUDOR','FIADOR') as otorgante,
            DECODE(nro_placa,NULL,'-',nro_placa) AS nro_placa
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N' and ind_tipo_garantia = 'M' and ind_adicional = 'S';

        OPEN p_ret_cursor_ghipo_adi FOR
            SELECT
            decode(mg.ind_otor,'D','DEUDOR','FIADOR') as otorgante,
            DECODE(mg.txt_direccion,NULL,'-', mg.txt_direccion) AS txt_direccion,
            DECODE(dis.des_nombre,NULL,'-', dis.des_nombre) as distrito,
            DECODE(pro.des_nombre,NULL,'-', pro.des_nombre) as provincia,
            DECODE(dep.des_nombre,NULL,'-', dep.des_nombre) as departamento,
            DECODE(mg.val_mont_otor_hip,NULL,0, mg.val_mont_otor_hip) AS val_mont_otor_hip,
            DECODE(mg.val_realiz_gar,NULL,0, mg.val_realiz_gar) AS val_realiz_gar,
            DECODE(sg.cod_rang_gar,NULL,'-', sg.cod_rang_gar) AS cod_rang_gar,
            DECODE(ac.des_tipo_actividad,NULL,'-', ac.des_tipo_actividad) AS des_tipo_actividad
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            inner join gen_mae_distrito dis on (mg.cod_distrito = dis.cod_id_distrito) -- distrito
            inner join gen_mae_provincia pro on (mg.cod_provincia = pro.cod_id_provincia) -- provincia
            inner join gen_mae_departamento dep on (mg.cod_departamento = dep.cod_id_departamento) -- departamento
            left join vve_credito_tipo_actividad ac on (mg.cod_tipo_actividad = ac.cod_tipo_actividad)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N' and ind_tipo_garantia = 'H' and ind_adicional = 'S';

        OPEN p_ret_cursor_garantias FOR
            select
            DECODE(ind_otor,NULL,'-',ind_otor) as otorgante,
            DECODE(nro_placa,NULL,'-',nro_placa) as nro_placa,
            DECODE(num_titulo_rpv,NULL,'-',num_titulo_rpv) as num_titulo_rpv,
            DECODE(nro_partida,NULL,'-',nro_partida) as nro_partida,
            DECODE(ind_reg_mob_contratos,NULL,'-',ind_reg_mob_contratos) as ind_reg_mob,
            DECODE(ind_reg_jur_bien,NULL,'-',ind_reg_jur_bien) as ind_reg_jur,
            DECODE(txt_info_mod_gar,NULL,'-',txt_info_mod_gar) as txt_info_mod_gar,
            DECODE(ind_ratifica_gar,NULL,'-',ind_ratifica_gar) as ind_ratifica,
            DECODE(val_nvo_monto,NULL,0,val_nvo_monto) as val_nvo_monto,
            DECODE(val_nvo_val,NULL,'-',val_nvo_val) as val_nvo_val
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N';


        OPEN p_ret_cursor_info_refinan FOR
            SELECT s.val_porc_tea_sigv, s.val_prima_seg, s.can_plaz_meses,
            decode(s.ind_tip_per_gra,'PG01','PARCIAL','TOTAL') as ind_tip_per_gra,
            s.can_let_per_gra,
            s.can_plaz_meses - 1 as can_plaz_meses_restante,
            (SELECT val_mont_letr FROM vve_cred_simu_lede d where d.cod_simu = s.cod_simu and cod_nume_letr = 1
            and cod_conc_col = 5) as val_letra_inicial, -- valor de la letra inicial
            (SELECT val_mont_letr -- valor de la letra final
            FROM vve_cred_simu_lede d where d.cod_simu = s.cod_simu and cod_nume_letr = 2
            and cod_conc_col = 5) as val_letra_final, --  valor de la letra final,
            (SELECT sum(val_mon_conc) -- suma de letras
            FROM vve_cred_simu_lede d where d.cod_simu = s.cod_simu
            and cod_conc_col = 5) as val_total_letr, -- valor total  de letras
            DECODE(TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = 1
            and cod_conc_col = 5),'DD/MM/YYYY'),'','-', TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = 1
            and cod_conc_col = 5),'DD/MM/YYYY')) as fec_venc_inicial, -- valor fecha venc inicial
            DECODE(TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = s.can_plaz_meses
            and cod_conc_col = 5),'DD/MM/YYYY'),'','-', TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = s.can_plaz_meses
            and cod_conc_col = 5),'DD/MM/YYYY')) as fec_venc_final -- valor fecha venc inicial
            FROM vve_cred_simu s WHERE cod_soli_cred = p_cod_soli_cred
            AND ind_inactivo = 'N';


        OPEN p_ret_cursor_info_garante FOR
            select distinct (case ind_tipo_persona
            when 'N' then (select txt_nomb_pers||' '||txt_apel_pate_pers||' '||txt_apel_mate_pers from vve_cred_mae_aval where cod_per_aval = ma.cod_per_aval)
            when 'J' then (select txt_nomb_pers from vve_cred_mae_aval where cod_per_aval = ma.cod_per_aval)
            end) AS nom_garante,
            txt_doi AS doi_garante,
            (case when ma.ind_esta_civil is not null and ma.ind_esta_civil = 'C' THEN 'Sociedad Conyugal'
            when ma.ind_esta_civil = 'J' then 'Persona Jurídica'
            when ma.ind_esta_civil = 'N' then 'Persona Natural' END) AS tipo_pers_garante,
            (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='104' AND valor_adic_1=ma.ind_esta_civil) AS des_estado_civil_garante,
            ma.txt_direccion AS direc_garante,
            (select des_nombre FROM gen_mae_departamento WHERE cod_id_pais = ma.cod_pais and cod_id_departamento = ma.cod_departamento) AS dpto_garante,
            (select des_nombre FROM gen_mae_provincia WHERE cod_id_departamento = ma.cod_departamento and cod_id_provincia = ma.cod_provincia) AS prov_garante,
            (select des_nombre FROM gen_mae_distrito WHERE cod_id_provincia = ma.cod_provincia and cod_id_distrito = ma.cod_distrito) AS dist_garante
            from vve_cred_soli s,vve_cred_soli_gara sg, vve_cred_maes_gara g,vve_cred_mae_aval ma
            where s.cod_soli_cred = p_cod_soli_cred
            and s.cod_empr = v_cod_empr
            and sg.cod_soli_cred = s.cod_soli_cred
            and sg.cod_gara = g.cod_garantia
            and g.cod_pers_prop = ma.cod_per_aval
            and ma.cod_per_rel_aval is null
            and ma.cod_tipo_otor in ('OG03', 'OG02','OG01') AND ROWNUM <= 1;


        OPEN p_ret_cursor_info_ref_lea FOR
            select
            (case when s.tip_soli_cred = 'TC02' THEN 'Cuota inicial derivada de Leasing (Banco abona 100% y carga inicial'
            else 'Banco abona saldo de monto facturado menos inicial' end) as ori_info_refi,
            no_docu as no_docu_info_refi,
            fecha as fecha_info_refi,
            (SELECT nom_perso FROM gen_persona WHERE cod_perso = v_cod_banco) as nom_banco_info_refi,
            (select upper(nom_marca) from gen_marca where cod_marca = g.cod_marca) as marca_veh_info_refi,
            to_char(fec_fab_const, '9999') anio_fab_info_refi,
            txt_modelo as modelo_info_refi,
            nro_chasis as chasis_info_refi,
            nro_motor as motor_info_refi,
            (select upper(des_familia_veh) from vve_familia_veh where cod_familia_veh = g.cod_familia_veh) as tipo_veh_info_refi,
            nro_placa as placa_info_refi
            from
            vve_cred_soli_gara sg inner join vve_cred_maes_gara g on sg.cod_gara = g.cod_garantia
            inner join vve_cred_soli s on sg.cod_soli_cred = s.cod_soli_cred
            inner join arlcrd a on s.cod_oper_rel = a.cod_oper
            where s.cod_soli_cred = p_cod_soli_cred;


        p_ret_esta := 1;
        p_ret_mens := 'Se realizó correctamente la consulta.';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_FORMATO_RECON_DEUDA', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_FORMATO_RECON_DEUDA:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_FORMATO_RECON_DEUDA', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_formato_recon_deuda;


   PROCEDURE sp_list_formato_mutuo
  (
    p_cod_soli_cred             IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid              IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor_cabe           OUT               SYS_REFCURSOR,
    p_ret_cursor_aval           OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi          OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_ghipo_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_garantias      OUT               SYS_REFCURSOR,
    p_ret_cursor_info_refinan   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_garante   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_ref_lea   OUT               SYS_REFCURSOR,
    p_ret_esta                  OUT               NUMBER,
    p_ret_mens                  OUT               VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_simu NUMBER;
    v_can_plaz_meses NUMBER;
    v_cod_empr VARCHAR(2);
    v_cod_ope_rel VARCHAR(6);
    v_cod_clie VARCHAR(8);
    c_facturas SYS_REFCURSOR;
    v_info_det_mutu VARCHAR(4000);
    v_sql_cadena VARCHAR(4000);
    v_no_docu arlcrd.no_docu%TYPE;
    v_fecha arlcrd.fecha%TYPE;
    v_cod_banco vve_cred_soli.cod_banco%TYPE;
    v_tip_soli_cred vve_cred_soli.tip_soli_cred%TYPE;

    BEGIN

        SELECT cod_empr, cod_banco INTO v_cod_empr, v_cod_banco FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;

        SELECT cod_oper_rel, cod_clie, tip_soli_cred INTO v_cod_ope_rel, v_cod_clie, v_tip_soli_cred FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;

        v_sql_cadena := 'SELECT no_docu, fecha FROM arlcrd WHERE cod_oper = ''' || v_cod_ope_rel ||  ''' ';

        OPEN c_facturas FOR v_sql_cadena;
        LOOP
        FETCH c_facturas INTO v_no_docu, v_fecha;
            EXIT WHEN c_facturas%notfound;
            dbms_output.put_line(v_no_docu);
            dbms_output.put_line(v_fecha);
            IF v_info_det_mutu is null THEN
              v_info_det_mutu := '- ' || v_no_docu || ' con Fecha ' || v_fecha || chr(13);
            ELSE
              v_info_det_mutu := v_info_det_mutu || '- ' || v_no_docu || ' con Fecha ' || v_fecha || chr(13);
            END IF;
        END LOOP;
        CLOSE c_facturas;

        OPEN p_ret_cursor_cabe FOR
            select
            -- SE MODIFICA CAMPOS PARA CHECK LIST MBARDALES 23/11/2020
            -- MODIFICACION PARA TITULO INICIAL DEL REPORTE
            (SELECT 'Créditos y Gestión Bancaria - '||z.des_zona
            from vve_mae_zona z, vve_cred_soli_prof sp, vve_proforma_veh p, vve_mae_zona_filial zf
            where sp.cod_soli_cred = p_cod_soli_cred
            and sp.num_prof_veh = p.num_prof_veh and p.cod_cia = v_cod_empr and p.cod_filial = zf.cod_filial and zf.cod_zona = z.cod_zona) as titulo,
            -- MODIFICACION PARA TITULO 2 DE INFORMACION
            (SELECT 'Información para la Elaboración de Contratos - '||t.descripcion FROM vve_tabla_maes t, vve_cred_soli s
            WHERE t.cod_grupo = 86 and s.cod_soli_cred = p_cod_soli_cred and s.tip_soli_cred = t.cod_tipo) as ind_info,
            -- MODIFICACION PARA INDICADOR DE NUEVO O USADO
            (SELECT UPPER(decode(nvl(ind_nu,'X'),'N', 'Nuevo','U','Usado','A','Nuevo/Usado','O','Ninguno'))
            FROM arlcop WHERE cod_oper = v_cod_ope_rel) as ind_nuevo_usado,
            -- MODIFICACION PARA NRO OPE / 2019
            (select cod_oper_rel||'/2019' from vve_cred_soli where cod_soli_cred = p_cod_soli_cred and cod_empr = v_cod_empr) as ind_nro_ope,
            --
            (select 'Persona ' || decode(cod_tipo_perso,'J','Jurídica','N','Natural') from gen_persona where cod_perso = s.cod_clie) as tipo_perso,
            DECODE(a.descrip,NULL,'-',a.descrip) as nom_empr,
            DECODE(s.cod_clie,NULL,'-',s.cod_clie) as cod_clie,
            DECODE(gp.nom_perso,NULL,'-',gp.nom_perso) as nom_perso,
            decode(gp.cod_tipo_perso, 'J', gp.num_ruc, gp.num_docu_iden) as num_docu,
            DECODE(dp.dir_domicilio,NULL,'-',dp.dir_domicilio) as dir_domicilio,
            DECODE(dis.des_nombre,NULL,'-',dis.des_nombre) as distrito,
            DECODE(pro.des_nombre,NULL,'-',pro.des_nombre) as provincia,
            DECODE(dep.des_nombre,NULL,'-',dep.des_nombre) as departamento,
            (SELECT nom_perso FROM gen_persona p, cxp_prov_giros g WHERE p.cod_perso = g.cod_prov AND g.cod_giro_perso = '012'
            AND cod_perso = s.cod_banco) as nom_banco,
            -- MODIFICACION PARA MARCA
            (select (select upper(nom_marca) from gen_marca where cod_marca = pd.cod_marca)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh and  rownum <= 1 ) as txt_marca,
            -- MODIFICACION PARA TIPO DE VEH
            (select lpad(to_char(pd.can_veh),2,'0')||' '|| (select upper(des_familia_veh) from vve_familia_veh where cod_familia_veh = pd.cod_familia_veh)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh and  rownum <= 1 ) as tipo_veh,
            -- MODIFICACION PARA AÑO DE FAB
            (select (select to_char(ano_fabricacion_veh,'9999') from vve_pedido_veh where cod_cia = s.cod_empr and num_prof_veh = sp.num_prof_veh and  rownum <= 1)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh and rownum <= 1) as val_ano_fab,
            -- MODIFICACION PARA MODELO
            (select (select upper(des_baumuster) from vve_baumuster where cod_baumuster = pd.cod_baumuster and cod_marca = pd.cod_marca)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh and rownum <= 1) as txt_modelo,
            -- MODIFICACION PARA CHASIS
            (select pe.num_chasis from vve_pedido_veh pe,vve_cred_soli_prof sp, vve_cred_soli s where s.cod_soli_cred = p_cod_soli_cred
            and s.cod_empr = v_cod_empr and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pe.num_prof_veh and  rownum <= 1 ) as nro_chasis,
            -- MODIFICACION PARA NRO DE MOTOR
            (select pe.num_motor_veh from vve_pedido_veh pe,vve_cred_soli_prof sp, vve_cred_soli s where s.cod_soli_cred = p_cod_soli_cred
            and s.cod_empr = v_cod_empr and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pe.num_prof_veh and  rownum <= 1) as nro_motor,
            --
            DECODE(mg.nro_placa,NULL,'-',mg.nro_placa) as nro_placa,
            s.val_porc_tea_sigv,
            -- MODIFICACION PARA PERIODO DE GRACIA
            (select decode((case ind_tip_per_gra when null then 'S' else  'N' end),'S','SI','N','NO')
            from vve_cred_simu where ind_inactivo = 'N' and cod_soli_cred = p_cod_soli_cred) as peri_gracia,
            -- MODIFICACION PARA PERIODO DE GRACIA SIN INT
            (select decode(nvl(ind_pgra_sint,'N'),'S','SI','N','NO')
            from vve_cred_simu where ind_inactivo = 'N' and cod_soli_cred = p_cod_soli_cred) as peri_grac_sin_int,
            -- MODIFICACION PARA DIAS PERIODO DE GRACIA
            (select val_dias_per_gra from vve_cred_simu where ind_inactivo = 'N' and cod_soli_cred = p_cod_soli_cred) as dias_peri_grac,
            s.val_int_per_gra,
            decode(s.ind_tipo_segu,'TS01','DIVEMOTOR','ENDOSADO') as tipo_segur,
            s.can_plaz_mes,
            upper(txt_nombres || ' ' || txt_apellidos) as nom_resp_fina,
            sbs.cod_clasif_sbs_clie,
            -- MODIFICACION PARA FIRM CONT
            to_char(s.fec_firm_cont, 'dd/MM/yyyy') as fec_firma_cont,
            -- MODIFICACION PARA ENTREGA LEGAL
            to_char(sysdate, 'dd/MM/yyyy') as fec_entre_leg,
            -- MODIFICACION PARA INFO DET MUTUO
            (select v_info_det_mutu from dual) as info_det_mutuo,
            -- MODIFICACION PARA NOMBRE DE BANCO MUTUO
            (SELECT nom_perso FROM gen_persona WHERE cod_perso = v_cod_banco) as nom_banco_mutuo
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia) -- maestro de garantias
            left join vve_tabla_maes tc ON (s.tip_soli_cred = tc.cod_tipo AND tc.cod_grupo_rec = '86' AND tc.cod_tipo_rec = 'TC')
            left join arccct a on (s.cod_empr = a.no_cia) -- nombre de compañias
            left join gen_persona gp on (gp.cod_perso = s.cod_clie) -- personas
            left join gen_dir_perso dp on (dp.cod_perso = s.cod_clie) -- direcciones
            inner join gen_mae_distrito dis on (dp.cod_distrito = dis.cod_id_distrito) -- distrito
            inner join gen_mae_provincia pro on (dp.cod_provincia = pro.cod_id_provincia) -- provincia
            inner join gen_mae_departamento dep on (dp.cod_dpto = dep.cod_id_departamento) -- departamento
            inner join sis_mae_usuario mu on (s.cod_resp_fina = mu.txt_usuario)
            left join vve_cred_soli_isbs sbs on (s.cod_soli_cred = sbs.cod_soli_cred)
            where s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N';

        OPEN p_ret_cursor_aval FOR
            -- SE AGREGAN CAMPOS PARA LISTA DE AVALES
            select
            (SELECT case when cod_estado_civil is not null and cod_estado_civil = 'C' THEN 'Sociedad Conyugal'
            when cod_tipo_perso = 'J' then 'Persona Jurídica'
            when cod_tipo_perso = 'N' then 'Persona Natural' END
            FROM gen_persona WHERE cod_perso = v_cod_clie) as tipo_pers_aval,
            DECODE(txt_nomb_pers || ' ' || txt_apel_pate_pers || ' ' || txt_apel_mate_pers,NULL,'-',txt_nomb_pers || ' ' || txt_apel_pate_pers || ' ' || txt_apel_mate_pers)  as nom_pers_aval,
            DECODE(txt_doi,NULL,'-', txt_doi) AS txt_doi,
            DECODE(txt_direccion,NULL,'-',txt_direccion) AS txt_direccion,
            DECODE(dis.des_nombre,NULL,'-',dis.des_nombre) as distrito,
            DECODE(pro.des_nombre,NULL,'-',pro.des_nombre) as provincia,
            DECODE(dep.des_nombre,NULL,'-',dep.des_nombre) as departamento,
            DECODE(ma.val_monto_fianza,NULL,0,ma.val_monto_fianza) as val_monto_fianza
            from vve_cred_mae_aval ma
            inner join gen_mae_distrito dis on (ma.cod_distrito = dis.cod_id_distrito) -- distrito
            inner join gen_mae_provincia pro on (ma.cod_provincia = pro.cod_id_provincia) -- provincia
            inner join gen_mae_departamento dep on (ma.cod_departamento = dep.cod_id_departamento) -- departamento
            where cod_rela_aval = 'RAVAL01';

        OPEN p_ret_cursor_gmobi FOR
            select
            decode(ind_tipo_bien,'P','SI','NO') as gar_propio,
            decode(ind_tipo_bien,'A','SI','NO') as gar_ajeno,
            decode(ind_otor,'D','DEUDOR','FIADOR') as otorgante,
            DECODE(nro_placa,NULL,'-',nro_placa) AS nro_placa
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N' and ind_tipo_garantia = 'M' and ind_adicional = 'N';

        OPEN p_ret_cursor_gmobi_adi FOR
            select
            decode(ind_tipo_bien,'P','SI','NO') as gar_propio,
            decode(ind_tipo_bien,'A','SI','NO') as gar_ajeno,
            decode(ind_otor,'D','DEUDOR','FIADOR') as otorgante,
            DECODE(nro_placa,NULL,'-',nro_placa) AS nro_placa
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N' and ind_tipo_garantia = 'M' and ind_adicional = 'S';

        OPEN p_ret_cursor_ghipo_adi FOR
            SELECT
            decode(mg.ind_otor,'D','DEUDOR','FIADOR') as otorgante,
            DECODE(mg.txt_direccion,NULL,'-', mg.txt_direccion) AS txt_direccion,
            DECODE(dis.des_nombre,NULL,'-', dis.des_nombre) as distrito,
            DECODE(pro.des_nombre,NULL,'-', pro.des_nombre) as provincia,
            DECODE(dep.des_nombre,NULL,'-', dep.des_nombre) as departamento,
            DECODE(mg.val_mont_otor_hip,NULL,0, mg.val_mont_otor_hip) AS val_mont_otor_hip,
            DECODE(mg.val_realiz_gar,NULL,0, mg.val_realiz_gar) AS val_realiz_gar,
            DECODE(sg.cod_rang_gar,NULL,'-', sg.cod_rang_gar) AS cod_rang_gar,
            DECODE(ac.des_tipo_actividad,NULL,'-', ac.des_tipo_actividad) AS des_tipo_actividad
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            inner join gen_mae_distrito dis on (mg.cod_distrito = dis.cod_id_distrito) -- distrito
            inner join gen_mae_provincia pro on (mg.cod_provincia = pro.cod_id_provincia) -- provincia
            inner join gen_mae_departamento dep on (mg.cod_departamento = dep.cod_id_departamento) -- departamento
            left join vve_credito_tipo_actividad ac on (mg.cod_tipo_actividad = ac.cod_tipo_actividad)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N' and ind_tipo_garantia = 'H' and ind_adicional = 'S';

        OPEN p_ret_cursor_garantias FOR
            select
            DECODE(ind_otor,NULL,'-',ind_otor) as otorgante,
            DECODE(nro_placa,NULL,'-',nro_placa) as nro_placa,
            DECODE(num_titulo_rpv,NULL,'-',num_titulo_rpv) as num_titulo_rpv,
            DECODE(nro_partida,NULL,'-',nro_partida) as nro_partida,
            DECODE(ind_reg_mob_contratos,NULL,'-',ind_reg_mob_contratos) as ind_reg_mob,
            DECODE(ind_reg_jur_bien,NULL,'-',ind_reg_jur_bien) as ind_reg_jur,
            DECODE(txt_info_mod_gar,NULL,'-',txt_info_mod_gar) as txt_info_mod_gar,
            DECODE(ind_ratifica_gar,NULL,'-',ind_ratifica_gar) as ind_ratifica,
            DECODE(val_nvo_monto,NULL,0,val_nvo_monto) as val_nvo_monto,
            DECODE(val_nvo_val,NULL,'-',val_nvo_val) as val_nvo_val
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N';


        OPEN p_ret_cursor_info_refinan FOR
            SELECT s.val_porc_tea_sigv, s.val_prima_seg, s.can_plaz_meses,
            decode(s.ind_tip_per_gra,'PG01','PARCIAL','TOTAL') as ind_tip_per_gra,
            s.can_let_per_gra,
            s.can_plaz_meses - 1 as can_plaz_meses_restante,
            (SELECT val_mont_letr FROM vve_cred_simu_lede d where d.cod_simu = s.cod_simu and cod_nume_letr = 1
            and cod_conc_col = 5) as val_letra_inicial, -- valor de la letra inicial
            (SELECT val_mont_letr -- valor de la letra final
            FROM vve_cred_simu_lede d where d.cod_simu = s.cod_simu and cod_nume_letr = 2
            and cod_conc_col = 5) as val_letra_final, --  valor de la letra final,
            (SELECT sum(val_mon_conc) -- suma de letras
            FROM vve_cred_simu_lede d where d.cod_simu = s.cod_simu
            and cod_conc_col = 5) as val_total_letr, -- valor total  de letras
            DECODE(TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = 1
            and cod_conc_col = 5),'DD/MM/YYYY'),'','-', TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = 1
            and cod_conc_col = 5),'DD/MM/YYYY')) as fec_venc_inicial, -- valor fecha venc inicial
            DECODE(TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = s.can_plaz_meses
            and cod_conc_col = 5),'DD/MM/YYYY'),'','-', TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = s.can_plaz_meses
            and cod_conc_col = 5),'DD/MM/YYYY')) as fec_venc_final -- valor fecha venc inicial
            FROM vve_cred_simu s WHERE cod_soli_cred = p_cod_soli_cred
            AND ind_inactivo = 'N';


        OPEN p_ret_cursor_info_garante FOR
            select distinct (case ind_tipo_persona
            when 'N' then (select txt_nomb_pers||' '||txt_apel_pate_pers||' '||txt_apel_mate_pers from vve_cred_mae_aval where cod_per_aval = ma.cod_per_aval)
            when 'J' then (select txt_nomb_pers from vve_cred_mae_aval where cod_per_aval = ma.cod_per_aval)
            end) AS nom_garante,
            txt_doi AS doi_garante,
            (case when ma.ind_esta_civil is not null and ma.ind_esta_civil = 'C' THEN 'Sociedad Conyugal'
            when ma.ind_esta_civil = 'J' then 'Persona Jurídica'
            when ma.ind_esta_civil = 'N' then 'Persona Natural' END) AS tipo_pers_garante,
            (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='104' AND valor_adic_1=ma.ind_esta_civil) AS des_estado_civil_garante,
            ma.txt_direccion AS direc_garante,
            (select des_nombre FROM gen_mae_departamento WHERE cod_id_pais = ma.cod_pais and cod_id_departamento = ma.cod_departamento) AS dpto_garante,
            (select des_nombre FROM gen_mae_provincia WHERE cod_id_departamento = ma.cod_departamento and cod_id_provincia = ma.cod_provincia) AS prov_garante,
            (select des_nombre FROM gen_mae_distrito WHERE cod_id_provincia = ma.cod_provincia and cod_id_distrito = ma.cod_distrito) AS dist_garante
            from vve_cred_soli s,vve_cred_soli_gara sg, vve_cred_maes_gara g,vve_cred_mae_aval ma
            where s.cod_soli_cred = p_cod_soli_cred
            and s.cod_empr = v_cod_empr
            and sg.cod_soli_cred = s.cod_soli_cred
            and sg.cod_gara = g.cod_garantia
            and g.cod_pers_prop = ma.cod_per_aval
            and ma.cod_per_rel_aval is null
            and ma.cod_tipo_otor in ('OG03', 'OG02','OG01') AND ROWNUM <= 1;


        OPEN p_ret_cursor_info_ref_lea FOR
            select
            (case when s.tip_soli_cred = 'TC02' THEN 'Cuota inicial derivada de Leasing (Banco abona 100% y carga inicial'
            else 'Banco abona saldo de monto facturado menos inicial' end) as ori_info_refi,
            no_docu as no_docu_info_refi,
            fecha as fecha_info_refi,
            (SELECT nom_perso FROM gen_persona WHERE cod_perso = v_cod_banco) as nom_banco_info_refi,
            (select upper(nom_marca) from gen_marca where cod_marca = g.cod_marca) as marca_veh_info_refi,
            to_char(fec_fab_const, '9999') anio_fab_info_refi,
            txt_modelo as modelo_info_refi,
            nro_chasis as chasis_info_refi,
            nro_motor as motor_info_refi,
            (select upper(des_familia_veh) from vve_familia_veh where cod_familia_veh = g.cod_familia_veh) as tipo_veh_info_refi,
            nro_placa as placa_info_refi
            from
            vve_cred_soli_gara sg inner join vve_cred_maes_gara g on sg.cod_gara = g.cod_garantia
            inner join vve_cred_soli s on sg.cod_soli_cred = s.cod_soli_cred
            inner join arlcrd a on s.cod_oper_rel = a.cod_oper
            where s.cod_soli_cred = p_cod_soli_cred;


        p_ret_esta := 1;
        p_ret_mens := 'Se realizó correctamente la consulta.';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_formato_mutuo', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_list_formato_mutuo:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_formato_mutuo', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_formato_mutuo;

 PROCEDURE sp_list_formato_leasing
  (
    p_cod_soli_cred             IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid              IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor_cabe           OUT               SYS_REFCURSOR,
    p_ret_cursor_aval           OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi          OUT               SYS_REFCURSOR,
    p_ret_cursor_gmobi_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_ghipo_adi      OUT               SYS_REFCURSOR,
    p_ret_cursor_garantias      OUT               SYS_REFCURSOR,
    p_ret_cursor_info_refinan   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_garante   OUT               SYS_REFCURSOR,
    p_ret_cursor_info_ref_lea   OUT               SYS_REFCURSOR,
    p_ret_esta                  OUT               NUMBER,
    p_ret_mens                  OUT               VARCHAR2
  ) AS
    ve_error EXCEPTION;
    v_cod_simu NUMBER;
    v_can_plaz_meses NUMBER;
    v_cod_empr VARCHAR(2);
    v_cod_ope_rel VARCHAR(6);
    v_cod_clie VARCHAR(8);
    c_facturas SYS_REFCURSOR;
    v_info_det_mutu VARCHAR(4000);
    v_sql_cadena VARCHAR(4000);
    v_no_docu arlcrd.no_docu%TYPE;
    v_fecha arlcrd.fecha%TYPE;
    v_cod_banco vve_cred_soli.cod_banco%TYPE;
    v_tip_soli_cred vve_cred_soli.tip_soli_cred%TYPE;

    BEGIN

        SELECT cod_empr, cod_banco INTO v_cod_empr, v_cod_banco FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;

        SELECT cod_oper_rel, cod_clie, tip_soli_cred INTO v_cod_ope_rel, v_cod_clie, v_tip_soli_cred FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;

        v_sql_cadena := 'SELECT no_docu, fecha FROM arlcrd WHERE cod_oper = ''' || v_cod_ope_rel ||  ''' ';

        OPEN c_facturas FOR v_sql_cadena;
        LOOP
        FETCH c_facturas INTO v_no_docu, v_fecha;
            EXIT WHEN c_facturas%notfound;
            dbms_output.put_line(v_no_docu);
            dbms_output.put_line(v_fecha);
            IF v_info_det_mutu is null THEN
              v_info_det_mutu := '- ' || v_no_docu || ' con Fecha ' || v_fecha || chr(13);
            ELSE
              v_info_det_mutu := v_info_det_mutu || '- ' || v_no_docu || ' con Fecha ' || v_fecha || chr(13);
            END IF;
        END LOOP;
        CLOSE c_facturas;

        OPEN p_ret_cursor_cabe FOR
            select
            -- SE MODIFICA CAMPOS PARA CHECK LIST MBARDALES 23/11/2020
            -- MODIFICACION PARA TITULO INICIAL DEL REPORTE
            (SELECT 'Créditos y Gestión Bancaria - '||z.des_zona
            from vve_mae_zona z, vve_cred_soli_prof sp, vve_proforma_veh p, vve_mae_zona_filial zf
            where sp.cod_soli_cred = p_cod_soli_cred
            and sp.num_prof_veh = p.num_prof_veh and p.cod_cia = v_cod_empr and p.cod_filial = zf.cod_filial and zf.cod_zona = z.cod_zona) as titulo,
            -- MODIFICACION PARA TITULO 2 DE INFORMACION
            (SELECT 'Información para la Elaboración de Contratos - '||t.descripcion FROM vve_tabla_maes t, vve_cred_soli s
            WHERE t.cod_grupo = 86 and s.cod_soli_cred = p_cod_soli_cred and s.tip_soli_cred = t.cod_tipo) as ind_info,
            -- MODIFICACION PARA INDICADOR DE NUEVO O USADO
            (SELECT UPPER(decode(nvl(ind_nu,'X'),'N', 'Nuevo','U','Usado','A','Nuevo/Usado','O','Ninguno'))
            FROM arlcop WHERE cod_oper = v_cod_ope_rel) as ind_nuevo_usado,
            -- MODIFICACION PARA NRO OPE / 2019
            (select cod_oper_rel||'/2019' from vve_cred_soli where cod_soli_cred = p_cod_soli_cred and cod_empr = v_cod_empr) as ind_nro_ope,
            --
            (select 'Persona ' || decode(cod_tipo_perso,'J','Jurídica','N','Natural') from gen_persona where cod_perso = s.cod_clie) as tipo_perso,
            DECODE(a.descrip,NULL,'-',a.descrip) as nom_empr,
            DECODE(s.cod_clie,NULL,'-',s.cod_clie) as cod_clie,
            DECODE(gp.nom_perso,NULL,'-',gp.nom_perso) as nom_perso,
            decode(gp.cod_tipo_perso, 'J', gp.num_ruc, gp.num_docu_iden) as num_docu,
            DECODE(dp.dir_domicilio,NULL,'-',dp.dir_domicilio) as dir_domicilio,
            DECODE(dis.des_nombre,NULL,'-',dis.des_nombre) as distrito,
            DECODE(pro.des_nombre,NULL,'-',pro.des_nombre) as provincia,
            DECODE(dep.des_nombre,NULL,'-',dep.des_nombre) as departamento,
            (SELECT nom_perso FROM gen_persona p, cxp_prov_giros g WHERE p.cod_perso = g.cod_prov AND g.cod_giro_perso = '012'
            AND cod_perso = s.cod_banco) as nom_banco,
             -- MODIFICACION PARA MARCA
            (select (select upper(nom_marca) from gen_marca where cod_marca = pd.cod_marca)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh and  rownum <= 1 ) as txt_marca,
            -- MODIFICACION PARA TIPO DE VEH
            (select lpad(to_char(pd.can_veh),2,'0')||' '|| (select upper(des_familia_veh) from vve_familia_veh where cod_familia_veh = pd.cod_familia_veh)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh and  rownum <= 1 ) as tipo_veh,
            -- MODIFICACION PARA AÑO DE FAB
            (select (select to_char(ano_fabricacion_veh,'9999') from vve_pedido_veh where cod_cia = s.cod_empr and num_prof_veh = sp.num_prof_veh and  rownum <= 1)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh and rownum <= 1) as val_ano_fab,
            -- MODIFICACION PARA MODELO
            (select (select upper(des_baumuster) from vve_baumuster where cod_baumuster = pd.cod_baumuster and cod_marca = pd.cod_marca)
            from vve_proforma_veh_det pd, vve_cred_soli_prof sp, vve_cred_soli s
            where s.cod_soli_cred = p_cod_soli_cred and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pd.num_prof_veh and rownum <= 1) as txt_modelo,
            -- MODIFICACION PARA CHASIS
            (select pe.num_chasis from vve_pedido_veh pe,vve_cred_soli_prof sp, vve_cred_soli s where s.cod_soli_cred = p_cod_soli_cred
            and s.cod_empr = v_cod_empr and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pe.num_prof_veh and  rownum <= 1 ) as nro_chasis,
            -- MODIFICACION PARA NRO DE MOTOR
            (select pe.num_motor_veh from vve_pedido_veh pe,vve_cred_soli_prof sp, vve_cred_soli s where s.cod_soli_cred = p_cod_soli_cred
            and s.cod_empr = v_cod_empr and sp.cod_soli_cred = s.cod_soli_cred and sp.num_prof_veh = pe.num_prof_veh and  rownum <= 1) as nro_motor,
            --
            DECODE(mg.nro_placa,NULL,'-',mg.nro_placa) as nro_placa,
            s.val_porc_tea_sigv,
            -- MODIFICACION PARA PERIODO DE GRACIA
            (select decode((case ind_tip_per_gra when null then 'S' else  'N' end),'S','SI','N','NO')
            from vve_cred_simu where ind_inactivo = 'N' and cod_soli_cred = p_cod_soli_cred) as peri_gracia,
            -- MODIFICACION PARA PERIODO DE GRACIA SIN INT
            (select decode(nvl(ind_pgra_sint,'N'),'S','SI','N','NO')
            from vve_cred_simu where ind_inactivo = 'N' and cod_soli_cred = p_cod_soli_cred) as peri_grac_sin_int,
            -- MODIFICACION PARA DIAS PERIODO DE GRACIA
            (select val_dias_per_gra from vve_cred_simu where ind_inactivo = 'N' and cod_soli_cred = p_cod_soli_cred) as dias_peri_grac,
            s.val_int_per_gra,
            decode(s.ind_tipo_segu,'TS01','DIVEMOTOR','ENDOSADO') as tipo_segur,
            s.can_plaz_mes,
            upper(txt_nombres || ' ' || txt_apellidos) as nom_resp_fina,
            sbs.cod_clasif_sbs_clie,
            -- MODIFICACION PARA FIRM CONT
            to_char(s.fec_firm_cont, 'dd/MM/yyyy') as fec_firma_cont,
            -- MODIFICACION PARA ENTREGA LEGAL
            to_char(sysdate, 'dd/MM/yyyy') as fec_entre_leg,
            -- MODIFICACION PARA INFO DET MUTUO
            (select v_info_det_mutu from dual) as info_det_mutuo,
            -- MODIFICACION PARA NOMBRE DE BANCO MUTUO
            (SELECT nom_perso FROM gen_persona WHERE cod_perso = v_cod_banco) as nom_banco_mutuo
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia) -- maestro de garantias
            left join vve_tabla_maes tc ON (s.tip_soli_cred = tc.cod_tipo AND tc.cod_grupo_rec = '86' AND tc.cod_tipo_rec = 'TC')
            left join arccct a on (s.cod_empr = a.no_cia) -- nombre de compañias
            left join gen_persona gp on (gp.cod_perso = s.cod_clie) -- personas
            left join gen_dir_perso dp on (dp.cod_perso = s.cod_clie) -- direcciones
            inner join gen_mae_distrito dis on (dp.cod_distrito = dis.cod_id_distrito) -- distrito
            inner join gen_mae_provincia pro on (dp.cod_provincia = pro.cod_id_provincia) -- provincia
            inner join gen_mae_departamento dep on (dp.cod_dpto = dep.cod_id_departamento) -- departamento
            inner join sis_mae_usuario mu on (s.cod_resp_fina = mu.txt_usuario)
            left join vve_cred_soli_isbs sbs on (s.cod_soli_cred = sbs.cod_soli_cred)
            where s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N';

        OPEN p_ret_cursor_aval FOR
            -- SE AGREGAN CAMPOS PARA LISTA DE AVALES
            select
            (SELECT case when cod_estado_civil is not null and cod_estado_civil = 'C' THEN 'Sociedad Conyugal'
            when cod_tipo_perso = 'J' then 'Persona Jurídica'
            when cod_tipo_perso = 'N' then 'Persona Natural' END
            FROM gen_persona WHERE cod_perso = v_cod_clie) as tipo_pers_aval,
            DECODE(txt_nomb_pers || ' ' || txt_apel_pate_pers || ' ' || txt_apel_mate_pers,NULL,'-',txt_nomb_pers || ' ' || txt_apel_pate_pers || ' ' || txt_apel_mate_pers)  as nom_pers_aval,
            DECODE(txt_doi,NULL,'-', txt_doi) AS txt_doi,
            DECODE(txt_direccion,NULL,'-',txt_direccion) AS txt_direccion,
            DECODE(dis.des_nombre,NULL,'-',dis.des_nombre) as distrito,
            DECODE(pro.des_nombre,NULL,'-',pro.des_nombre) as provincia,
            DECODE(dep.des_nombre,NULL,'-',dep.des_nombre) as departamento,
            DECODE(ma.val_monto_fianza,NULL,0,ma.val_monto_fianza) as val_monto_fianza
            from vve_cred_mae_aval ma
            inner join gen_mae_distrito dis on (ma.cod_distrito = dis.cod_id_distrito) -- distrito
            inner join gen_mae_provincia pro on (ma.cod_provincia = pro.cod_id_provincia) -- provincia
            inner join gen_mae_departamento dep on (ma.cod_departamento = dep.cod_id_departamento) -- departamento
            where cod_rela_aval = 'RAVAL01';

        OPEN p_ret_cursor_gmobi FOR
            select
            decode(ind_tipo_bien,'P','SI','NO') as gar_propio,
            decode(ind_tipo_bien,'A','SI','NO') as gar_ajeno,
            decode(ind_otor,'D','DEUDOR','FIADOR') as otorgante,
            DECODE(nro_placa,NULL,'-',nro_placa) AS nro_placa
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N' and ind_tipo_garantia = 'M' and ind_adicional = 'N';

        OPEN p_ret_cursor_gmobi_adi FOR
            select
            decode(ind_tipo_bien,'P','SI','NO') as gar_propio,
            decode(ind_tipo_bien,'A','SI','NO') as gar_ajeno,
            decode(ind_otor,'D','DEUDOR','FIADOR') as otorgante,
            DECODE(nro_placa,NULL,'-',nro_placa) AS nro_placa
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N' and ind_tipo_garantia = 'M' and ind_adicional = 'S';

        OPEN p_ret_cursor_ghipo_adi FOR
            SELECT
            decode(mg.ind_otor,'D','DEUDOR','FIADOR') as otorgante,
            DECODE(mg.txt_direccion,NULL,'-', mg.txt_direccion) AS txt_direccion,
            DECODE(dis.des_nombre,NULL,'-', dis.des_nombre) as distrito,
            DECODE(pro.des_nombre,NULL,'-', pro.des_nombre) as provincia,
            DECODE(dep.des_nombre,NULL,'-', dep.des_nombre) as departamento,
            DECODE(mg.val_mont_otor_hip,NULL,0, mg.val_mont_otor_hip) AS val_mont_otor_hip,
            DECODE(mg.val_realiz_gar,NULL,0, mg.val_realiz_gar) AS val_realiz_gar,
            DECODE(sg.cod_rang_gar,NULL,'-', sg.cod_rang_gar) AS cod_rang_gar,
            DECODE(ac.des_tipo_actividad,NULL,'-', ac.des_tipo_actividad) AS des_tipo_actividad
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            inner join gen_mae_distrito dis on (mg.cod_distrito = dis.cod_id_distrito) -- distrito
            inner join gen_mae_provincia pro on (mg.cod_provincia = pro.cod_id_provincia) -- provincia
            inner join gen_mae_departamento dep on (mg.cod_departamento = dep.cod_id_departamento) -- departamento
            left join vve_credito_tipo_actividad ac on (mg.cod_tipo_actividad = ac.cod_tipo_actividad)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N' and ind_tipo_garantia = 'H' and ind_adicional = 'S';

        OPEN p_ret_cursor_garantias FOR
            select
            DECODE(ind_otor,NULL,'-',ind_otor) as otorgante,
            DECODE(nro_placa,NULL,'-',nro_placa) as nro_placa,
            DECODE(num_titulo_rpv,NULL,'-',num_titulo_rpv) as num_titulo_rpv,
            DECODE(nro_partida,NULL,'-',nro_partida) as nro_partida,
            DECODE(ind_reg_mob_contratos,NULL,'-',ind_reg_mob_contratos) as ind_reg_mob,
            DECODE(ind_reg_jur_bien,NULL,'-',ind_reg_jur_bien) as ind_reg_jur,
            DECODE(txt_info_mod_gar,NULL,'-',txt_info_mod_gar) as txt_info_mod_gar,
            DECODE(ind_ratifica_gar,NULL,'-',ind_ratifica_gar) as ind_ratifica,
            DECODE(val_nvo_monto,NULL,0,val_nvo_monto) as val_nvo_monto,
            DECODE(val_nvo_val,NULL,'-',val_nvo_val) as val_nvo_val
            from
            vve_cred_soli s
            inner join vve_cred_soli_gara sg on (s.cod_soli_cred = sg.cod_soli_cred) -- garantia desde solicitud
            inner join vve_cred_maes_gara mg on (sg.cod_gara = mg.cod_garantia)
            where
            s.cod_soli_cred = p_cod_soli_cred and sg.ind_inactivo = 'N';


        OPEN p_ret_cursor_info_refinan FOR
            SELECT s.val_porc_tea_sigv, s.val_prima_seg, s.can_plaz_meses,
            decode(s.ind_tip_per_gra,'PG01','PARCIAL','TOTAL') as ind_tip_per_gra,
            s.can_let_per_gra,
            s.can_plaz_meses - 1 as can_plaz_meses_restante,
            (SELECT val_mont_letr FROM vve_cred_simu_lede d where d.cod_simu = s.cod_simu and cod_nume_letr = 1
            and cod_conc_col = 5) as val_letra_inicial, -- valor de la letra inicial
            (SELECT val_mont_letr -- valor de la letra final
            FROM vve_cred_simu_lede d where d.cod_simu = s.cod_simu and cod_nume_letr = 2
            and cod_conc_col = 5) as val_letra_final, --  valor de la letra final,
            (SELECT sum(val_mon_conc) -- suma de letras
            FROM vve_cred_simu_lede d where d.cod_simu = s.cod_simu
            and cod_conc_col = 5) as val_total_letr, -- valor total  de letras
            DECODE(TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = 1
            and cod_conc_col = 5),'DD/MM/YYYY'),'','-', TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = 1
            and cod_conc_col = 5),'DD/MM/YYYY')) as fec_venc_inicial, -- valor fecha venc inicial
            DECODE(TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = s.can_plaz_meses
            and cod_conc_col = 5),'DD/MM/YYYY'),'','-', TO_CHAR((SELECT fec_venc
            FROM vve_cred_simu_lede where cod_simu = s.cod_simu and cod_nume_letr = s.can_plaz_meses
            and cod_conc_col = 5),'DD/MM/YYYY')) as fec_venc_final -- valor fecha venc inicial
            FROM vve_cred_simu s WHERE cod_soli_cred = p_cod_soli_cred
            AND ind_inactivo = 'N';


        OPEN p_ret_cursor_info_garante FOR
            select distinct (case ind_tipo_persona
            when 'N' then (select txt_nomb_pers||' '||txt_apel_pate_pers||' '||txt_apel_mate_pers from vve_cred_mae_aval where cod_per_aval = ma.cod_per_aval)
            when 'J' then (select txt_nomb_pers from vve_cred_mae_aval where cod_per_aval = ma.cod_per_aval)
            end) AS nom_garante,
            txt_doi AS doi_garante,
            (case when ma.ind_esta_civil is not null and ma.ind_esta_civil = 'C' THEN 'Sociedad Conyugal'
            when ma.ind_esta_civil = 'J' then 'Persona Jurídica'
            when ma.ind_esta_civil = 'N' then 'Persona Natural' END) AS tipo_pers_garante,
            (SELECT descripcion FROM vve_tabla_maes WHERE COD_GRUPO='104' AND valor_adic_1=ma.ind_esta_civil) AS des_estado_civil_garante,
            ma.txt_direccion AS direc_garante,
            (select des_nombre FROM gen_mae_departamento WHERE cod_id_pais = ma.cod_pais and cod_id_departamento = ma.cod_departamento) AS dpto_garante,
            (select des_nombre FROM gen_mae_provincia WHERE cod_id_departamento = ma.cod_departamento and cod_id_provincia = ma.cod_provincia) AS prov_garante,
            (select des_nombre FROM gen_mae_distrito WHERE cod_id_provincia = ma.cod_provincia and cod_id_distrito = ma.cod_distrito) AS dist_garante
            from vve_cred_soli s,vve_cred_soli_gara sg, vve_cred_maes_gara g,vve_cred_mae_aval ma
            where s.cod_soli_cred = p_cod_soli_cred
            and s.cod_empr = v_cod_empr
            and sg.cod_soli_cred = s.cod_soli_cred
            and sg.cod_gara = g.cod_garantia
            and g.cod_pers_prop = ma.cod_per_aval
            and ma.cod_per_rel_aval is null
            and ma.cod_tipo_otor in ('OG03', 'OG02','OG01') AND ROWNUM <= 1;


        OPEN p_ret_cursor_info_ref_lea FOR
            select
            (case when s.tip_soli_cred = 'TC02' THEN 'Cuota inicial derivada de Leasing (Banco abona 100% y carga inicial'
            else 'Banco abona saldo de monto facturado menos inicial' end) as ori_info_refi,
            no_docu as no_docu_info_refi,
            fecha as fecha_info_refi,
            (SELECT nom_perso FROM gen_persona WHERE cod_perso = v_cod_banco) as nom_banco_info_refi,
            (select upper(nom_marca) from gen_marca where cod_marca = g.cod_marca) as marca_veh_info_refi,
            to_char(fec_fab_const, '9999') anio_fab_info_refi,
            txt_modelo as modelo_info_refi,
            nro_chasis as chasis_info_refi,
            nro_motor as motor_info_refi,
            (select upper(des_familia_veh) from vve_familia_veh where cod_familia_veh = g.cod_familia_veh) as tipo_veh_info_refi,
            nro_placa as placa_info_refi
            from
            vve_cred_soli_gara sg inner join vve_cred_maes_gara g on sg.cod_gara = g.cod_garantia
            inner join vve_cred_soli s on sg.cod_soli_cred = s.cod_soli_cred
            inner join arlcrd a on s.cod_oper_rel = a.cod_oper
            where s.cod_soli_cred = p_cod_soli_cred;


        p_ret_esta := 1;
        p_ret_mens := 'Se realizó correctamente la consulta.';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_formato_leasing', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_list_formato_leasing:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_formato_leasing', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_formato_leasing;

  PROCEDURE sp_list_perm_usua_solcre
  (
    p_cod_soli_cred IN vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid  IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web  IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor    OUT SYS_REFCURSOR,
    p_ret_esta      OUT NUMBER,
    p_ret_mens      OUT VARCHAR
  ) AS

    lv_ind_editar_estado_solicitud VARCHAR2(1);
    lv_men_editar_estado_solicitud VARCHAR2(100);
    lv_ind_editar_estado_aprob VARCHAR2(1);
    lv_men_editar_estado_aprob VARCHAR2(100);
    lv_ind_habilitar_tab_doc VARCHAR2(1);
    lv_men_habilitar_tab_doc VARCHAR2(100);
    lv_ind_crear_soli_prof VARCHAR2(1);
    lv_men_crear_soli_prof VARCHAR2(100);
    lv_ind_crear_soli_post_venta VARCHAR2(1);
    lv_men_crear_soli_post_venta VARCHAR2(100);
    lv_ind_editar_soli VARCHAR2(1);
    lv_men_editar_soli VARCHAR2(100);
    lv_ind_habilitar_tab_gest_banc VARCHAR2(1);
    lv_men_habilitar_tab_gest_banc VARCHAR2(100);
    lv_ind_editar_tab_doc VARCHAR2(1);
    lv_men_editar_tab_doc VARCHAR2(100);
    lv_ind_habilitar_tab_simu VARCHAR2(1);
    lv_men_habilitar_tab_simu VARCHAR2(100);
    lv_ind_editar_tab_simu VARCHAR2(1);
    lv_men_editar_tab_simu VARCHAR2(100);
    lv_ind_habilitar_tab_eval VARCHAR2(1);
    lv_men_habilitar_tab_eval VARCHAR2(100);
    lv_ind_editar_tab_eval VARCHAR2(1);
    lv_men_editar_tab_eval VARCHAR2(100);
    lv_ind_soli_aprob_tab_eval VARCHAR2(1);
    lv_men_soli_aprob_tab_eval VARCHAR2(100);
    lv_ind_aprob_tab_eval VARCHAR2(1);
    lv_men_aprob_tab_eval VARCHAR2(100);
    lv_ind_habilitar_tab_vehi VARCHAR2(1);
    lv_men_habilitar_tab_vehi VARCHAR2(100);
    lv_ind_editar_tab_vehi VARCHAR2(1);
    lv_men_editar_tab_vehi VARCHAR2(100);
    lv_ind_habilitar_tab_lxc VARCHAR2(1);
    lv_men_habilitar_tab_lxc VARCHAR2(100);
    lv_ind_editar_tab_lxc VARCHAR2(1);
    lv_men_editar_tab_lxc VARCHAR2(100);
    lv_ind_habilitar_tab_even VARCHAR2(1);
    lv_men_habilitar_tab_even VARCHAR2(100);
    lv_ind_habilitar_tab_nota VARCHAR2(1);
    lv_men_habilitar_tab_nota VARCHAR2(100);
    lv_ind_editar_tab_nota VARCHAR2(1);
    lv_men_editar_tab_nota VARCHAR2(100);
    lv_ind_habilitar_tab_reso VARCHAR2(1);
    lv_men_habilitar_tab_reso VARCHAR2(100);
    lv_ind_editar_tab_reso VARCHAR2(1);
    lv_men_editar_tab_reso VARCHAR2(100);
    --<I Req. 87567 E2.1 ID## avilca 04/01/2021>
    lv_ind_habilitar_ar_seg VARCHAR2(1);
    lv_men_habilitar_ar_seg VARCHAR2(100);
    --<F Req. 87567 E2.1 ID## avilca 04/01/2021>
    lv_ind_habilitar_tab_segu VARCHAR2(1);
    lv_men_habilitar_tab_segu  VARCHAR2(100);

  BEGIN
    --L: lectura
    --E: escritura
    --O: oculto
    --V: visible
    --B: Bloqueado
    --Variables Generales

    -------------------Editar estado de solicitud de crédito-------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   103,
                                                   lv_ind_editar_estado_solicitud,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_editar_estado_solicitud = 'N') THEN
      lv_ind_editar_estado_solicitud := 'B';
      lv_men_editar_estado_solicitud := 'Usted no cuenta con permisos para editar el estado de la solicitud de crédito';
    ELSE
      lv_ind_editar_estado_solicitud := 'V';
    END IF;
    -------------------Editar estado de solicitud de crédito-------------------

    -------------------Editar estado de aprobación-----------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   104,
                                                   lv_ind_editar_estado_aprob,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_editar_estado_aprob = 'N') THEN
      lv_ind_editar_estado_aprob := 'B';
      lv_men_editar_estado_aprob := 'Usted no cuenta con permisos para editar el estado de la aprobación';
    ELSE
      lv_ind_editar_estado_aprob := 'V';
    END IF;
    -------------------Editar estado de aprobación-----------------------------

    -------------------Habilitar pestaña de documentos------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   105,
                                                   lv_ind_habilitar_tab_doc,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_doc = 'N') THEN
      lv_ind_habilitar_tab_doc := 'B';
      lv_men_habilitar_tab_doc := 'Usted no cuenta con permisos para adjuntar documentos';
    ELSE
      lv_ind_habilitar_tab_doc := 'V';
    END IF;
    -------------------Habilitar pestaña de documentos-------------------------

    -------------------Crear solicitud desde proforma--------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   106,
                                                   lv_ind_crear_soli_prof,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_crear_soli_prof = 'N') THEN
      lv_ind_crear_soli_prof := 'B';
      lv_men_crear_soli_prof := 'Usted no cuenta con permisos para crear solicitud';
    ELSE
      lv_ind_crear_soli_prof := 'V';
    END IF;
    -------------------Crear solicitud desde proforma--------------------------

    -------------------Crear solicitud de post-venta----------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   107,
                                                   lv_ind_crear_soli_post_venta,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_crear_soli_post_venta = 'N') THEN
      lv_ind_crear_soli_post_venta := 'B';
      lv_men_crear_soli_post_venta := 'Usted no cuenta con permisos para crear solicitud';
    ELSE
      lv_ind_crear_soli_post_venta := 'V';
    END IF;
    -------------------Crear solicitud de post-venta----------------------------

    -------------------Editar solicitud de crédito------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   108,
                                                   lv_ind_editar_soli,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_editar_soli = 'N') THEN
      lv_ind_editar_soli := 'V';
    ELSE
      lv_ind_editar_soli := 'B';
      lv_men_editar_soli := 'Usted no cuenta con permisos para editar solicitud ';
    END IF;
    -------------------Editar solicitud de crédito------------------------------

    -------------------Habilitar pestaña de gestión bancaria--------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   109,
                                                   lv_ind_habilitar_tab_gest_banc,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_gest_banc = 'N') THEN
      lv_ind_habilitar_tab_gest_banc := 'B';
      lv_men_habilitar_tab_gest_banc := 'Usted no cuenta con permisos para ingresar a Gestión Bancaria';
    ELSE
      lv_ind_habilitar_tab_gest_banc := 'V';
    END IF;
    -------------------Habilitar pestaña de gestión bancaria--------------------

    -------------------Ver contenido de pestaña de Documentos-------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   110,
                                                   lv_ind_editar_tab_doc,
                                                   p_ret_esta,
                                                   p_ret_mens);
     IF (lv_ind_editar_tab_doc = 'N') THEN
      lv_ind_editar_tab_doc := 'V';
    ELSE
      lv_ind_editar_tab_doc := 'B';
      lv_men_editar_tab_doc := 'Usted cuenta con permisos de solo lectura en Documentos';
    END IF;
    -------------------Ver contenido de pestaña de Documentos-------------------

    -------------------Habilitar pestaña de Simulador---------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   111,
                                                   lv_ind_habilitar_tab_simu,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_simu = 'N') THEN
      lv_ind_habilitar_tab_simu := 'B';
      lv_men_habilitar_tab_simu := 'Usted no cuenta con permisos para ingresar a Simulador';
    ELSE
      lv_ind_habilitar_tab_simu := 'V';
    END IF;
    -------------------Habilitar pestaña de Simulador---------------------------

    -------------------Ver contenido de pestaña de Simulador--------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   112,
                                                   lv_ind_editar_tab_simu,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_editar_tab_simu = 'N') THEN
      lv_ind_editar_tab_simu := 'V';
    ELSE
      lv_ind_editar_tab_simu := 'B';
      lv_men_editar_tab_simu := 'Usted cuenta con permisos de solo lectura en Simulador';
    END IF;
    -------------------Ver contenido de pestaña de Simulador--------------------

    -------------------Habilitar pestaña de Evaluación---------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   113,
                                                   lv_ind_habilitar_tab_eval,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_eval = 'N') THEN
      lv_ind_habilitar_tab_eval := 'B';
      lv_men_habilitar_tab_eval := 'Usted no cuenta con permisos para ingresar a Evaluación';
    ELSE
      lv_ind_habilitar_tab_eval := 'V';
    END IF;
    -------------------Habilitar pestaña de Evaluación---------------------------

    -------------------Ver contenido de pestaña de Evaluación--------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   114,
                                                   lv_ind_editar_tab_eval,
                                                   p_ret_esta,
                                                   p_ret_mens);
   IF (lv_ind_editar_tab_eval = 'N') THEN
      lv_ind_editar_tab_eval := 'V';
    ELSE
      lv_ind_editar_tab_eval := 'B';
      lv_men_editar_tab_eval := 'Usted cuenta con permisos de solo lectura en Evaluación';
    END IF;
    -------------------Ver contenido de pestaña de Evaluación--------------------

    -------------------Solicitar aprobación en Resolución------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   115,
                                                   lv_ind_soli_aprob_tab_eval,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_soli_aprob_tab_eval = 'N') THEN
      lv_ind_soli_aprob_tab_eval := 'B';
      lv_men_soli_aprob_tab_eval := 'Usted no cuenta con permisos para solicitar aprobación';
    ELSE
      lv_ind_soli_aprob_tab_eval := 'V';
    END IF;
    -------------------Solicitar aprobación en Resolución------------------------

    -------------------Aprobación en Resolución----------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   116,
                                                   lv_ind_aprob_tab_eval,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_aprob_tab_eval = 'N') THEN
      lv_ind_aprob_tab_eval := 'B';
      lv_men_aprob_tab_eval := 'Usted no cuenta con permisos para aprobar';
    ELSE
      lv_ind_aprob_tab_eval := 'V';
    END IF;
    -------------------Aprobación en Resolución----------------------------------

    -------------------Habilitar pestaña de Vehiculos----------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   117,
                                                   lv_ind_habilitar_tab_vehi,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_vehi = 'N') THEN
      lv_ind_habilitar_tab_vehi := 'B';
      lv_men_habilitar_tab_vehi := 'Usted no cuenta con permisos para ingresar a Vehiculos';
    ELSE
      lv_ind_habilitar_tab_vehi := 'V';
    END IF;
    -------------------Habilitar pestaña de Vehiculos----------------------------

    -------------------Ver contenido de pestaña de Vehiculos---------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   118,
                                                   lv_ind_editar_tab_vehi,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_editar_tab_vehi = 'N') THEN
      lv_ind_editar_tab_vehi := 'V';
    ELSE
      lv_ind_editar_tab_vehi := 'B';
      lv_men_editar_tab_vehi := 'Usted cuenta con permisos de solo lectura en Vehiculos';
    END IF;
    -------------------Ver contenido de pestaña de Vehiculos---------------------

    -------------------Habilitar pestaña de LxC----------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   119,
                                                   lv_ind_habilitar_tab_lxc,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_lxc = 'N') THEN
      lv_ind_habilitar_tab_lxc := 'B';
      lv_men_habilitar_tab_lxc := 'Usted no cuenta con permisos para ingresar a Operación LxC';
    ELSE
      lv_ind_habilitar_tab_lxc := 'V';
    END IF;
    -------------------Habilitar pestaña de LxC----------------------------------

    -------------------Ver contenido de pestaña de LxC---------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   120,
                                                   lv_ind_editar_tab_lxc,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_editar_tab_lxc = 'N') THEN
      lv_ind_editar_tab_lxc := 'V';
    ELSE
      lv_ind_editar_tab_lxc := 'B';
      lv_men_editar_tab_lxc := 'Usted cuenta con permisos de solo lectura en Operación LxC';
    END IF;

    -------------------Ver contenido de pestaña de LxC---------------------------

    -------------------Habilitar pestaña de Eventos----------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   121,
                                                   lv_ind_habilitar_tab_even,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_even = 'N') THEN
      lv_ind_habilitar_tab_even := 'B';
      lv_men_habilitar_tab_even := 'Usted no cuenta con permisos para ingresar a Eventos';
    ELSE
      lv_ind_habilitar_tab_even := 'V';
    END IF;
    -------------------Habilitar pestaña de Eventos----------------------------------

    -------------------Habilitar pestaña de Notaria----------------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   122,
                                                   lv_ind_habilitar_tab_nota,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_nota = 'N') THEN
      lv_ind_habilitar_tab_nota := 'B';
      lv_men_habilitar_tab_nota := 'Usted no cuenta con permisos para ingresar a Notaria';
    ELSE
      lv_ind_habilitar_tab_nota := 'V';
    END IF;
    -------------------Habilitar pestaña de Notaria----------------------------------

    -------------------Ver contenido de pestaña de Notaria---------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   123,
                                                   lv_ind_editar_tab_nota,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_editar_tab_nota = 'N') THEN
      lv_ind_editar_tab_nota := 'V';
    ELSE
      lv_ind_editar_tab_nota := 'B';
      lv_men_editar_tab_nota := 'Usted cuenta con permisos de solo lectura en Notaria';
    END IF;

    -------------------Ver contenido de pestaña de Notaria---------------------------

    -------------------Habilitar pestaña de Resolución de Créditos-------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   125,
                                                   lv_ind_habilitar_tab_reso,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_reso = 'N') THEN
      lv_ind_habilitar_tab_reso := 'B';
      lv_men_habilitar_tab_reso := 'Usted no cuenta con permisos para ingresar a Resolución de Créditos';
    ELSE
      lv_ind_habilitar_tab_reso := 'V';
    END IF;
    -------------------Habilitar pestaña de Resolución de Créditos-------------------
   -------------------Ver contenido de pestaña de Resolución de créditos---------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   126,
                                                   lv_ind_editar_tab_reso,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_editar_tab_reso = 'N') THEN
      lv_ind_editar_tab_reso := 'V';
    ELSE
      lv_ind_editar_tab_reso := 'B';
      lv_men_editar_tab_reso := 'Usted cuenta con permisos de solo lectura en resolución de créditos';
    END IF;
    -------------------Ver contenido de pestaña de Resolución de créditos---------------------------
    --<I Req. 87567 E2.1 ID## avilca 04/01/2021>
    -------------------Habilitar aprobación o rechazo en gestioón de seguros------------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   160,
                                                   lv_ind_habilitar_ar_seg,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_ar_seg = 'N') THEN
      lv_ind_habilitar_ar_seg := 'B';
      lv_men_habilitar_ar_seg := 'Usted no cuenta con permisos para aprobar o rechazar en gestión de seguros';
    ELSE
      lv_ind_habilitar_ar_seg := 'V';
    END IF;
    -------------------Habilitar aprobación o rechazo en gestioón de seguros--------------------
    -------------------Habilitar pestaña gestión de seguros-------------------
    sistemas.pkg_sweb_sis_usuario.sp_veri_proc_usu(p_cod_usua_web,
                                                   156,
                                                   lv_ind_habilitar_tab_segu,
                                                   p_ret_esta,
                                                   p_ret_mens);
    IF (lv_ind_habilitar_tab_segu = 'N') THEN
      lv_ind_habilitar_tab_segu := 'B';
      lv_men_habilitar_tab_segu := 'Usted no cuenta con permisos para la pestaña gestión de seguros';
    ELSE
      lv_ind_editar_estado_solicitud := 'V';
    END IF;
    ------------------Habilitar pestaña gestión de seguros-------------------

   --<F Req. 87567 E2.1 ID## avilca 04/01/2021>

    OPEN p_ret_cursor FOR
        SELECT 'ind_editar_estado_solicitud' permiso,
            lv_ind_editar_estado_solicitud valor,
            lv_men_editar_estado_solicitud mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_editar_estado_aprob' permiso,
            lv_ind_editar_estado_aprob valor,
            lv_men_editar_estado_aprob mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_habilitar_tab_doc' permiso,
            lv_ind_habilitar_tab_doc valor,
            lv_men_habilitar_tab_doc mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_crear_soli_prof' permiso,
            lv_ind_crear_soli_prof valor,
            lv_men_crear_soli_prof mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_crear_soli_post_venta' permiso,
            lv_ind_crear_soli_post_venta valor,
            lv_men_crear_soli_post_venta mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_editar_soli' permiso,
            lv_ind_editar_soli valor,
            lv_men_editar_soli mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_habilitar_tab_gest_banc' permiso,
            lv_ind_habilitar_tab_gest_banc valor,
            lv_men_habilitar_tab_gest_banc mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_editar_tab_doc' permiso,
            lv_ind_editar_tab_doc valor,
            lv_men_editar_tab_doc mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_habilitar_tab_simu' permiso,
            lv_ind_habilitar_tab_simu valor,
            lv_men_habilitar_tab_simu mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_editar_tab_simu' permiso,
            lv_ind_editar_tab_simu valor,
            lv_men_editar_tab_simu mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_habilitar_tab_eval' permiso,
            lv_ind_habilitar_tab_eval valor,
            lv_men_habilitar_tab_eval mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_editar_tab_eval' permiso,
            lv_ind_editar_tab_eval valor,
            lv_men_editar_tab_eval mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_soli_aprob_tab_eval' permiso,
            lv_ind_soli_aprob_tab_eval valor,
            lv_men_soli_aprob_tab_eval mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_aprob_tab_eval' permiso,
            lv_ind_aprob_tab_eval valor,
            lv_men_aprob_tab_eval mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_habilitar_tab_vehi' permiso,
            lv_ind_habilitar_tab_vehi valor,
            lv_men_habilitar_tab_vehi mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_editar_tab_vehi' permiso,
            lv_ind_editar_tab_vehi valor,
            lv_men_editar_tab_vehi mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_habilitar_tab_lxc' permiso,
            lv_ind_habilitar_tab_lxc valor,
            lv_men_habilitar_tab_lxc mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_editar_tab_lxc' permiso,
            lv_ind_editar_tab_lxc valor,
            lv_men_editar_tab_lxc mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_habilitar_tab_even' permiso,
            lv_ind_habilitar_tab_even valor,
            lv_men_habilitar_tab_even mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_habilitar_tab_nota' permiso,
            lv_ind_habilitar_tab_nota valor,
            lv_men_habilitar_tab_nota mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_editar_tab_nota' permiso,
            lv_ind_editar_tab_nota valor,
            lv_men_editar_tab_nota mensaje
        FROM dual
        UNION ALL
        SELECT 'ind_habilitar_tab_reso' permiso,
            lv_ind_habilitar_tab_reso valor,
            lv_men_habilitar_tab_reso mensaje
        FROM dual
    UNION ALL
        SELECT 'ind_editar_tab_reso' permiso,
            lv_ind_editar_tab_reso valor,
            lv_men_editar_tab_reso mensaje
        FROM dual
    UNION ALL --<I Req. 87567 E2.1 ID## avilca 04/01/2021>
        SELECT 'ind_habilitar_aprob_rech_seg' permiso,
            lv_ind_habilitar_ar_seg valor,
            lv_men_habilitar_ar_seg mensaje
        FROM dual--<F Req. 87567 E2.1 ID## avilca 04/01/2021>
    UNION ALL --<I Req. 87567 E2.1 ID## avilca 04/01/2021>
        SELECT 'lv_ind_habilitar_tab_segu' permiso,
            lv_ind_habilitar_tab_segu valor,
            lv_men_habilitar_tab_segu mensaje
        FROM dual;

    p_ret_esta := 1;
    p_ret_mens := 'Consulta ejecutada de forma exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'SP_PERM_USUA_SOLCRE:' || SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_PERM_USUA_SOLCRE',
                                          p_cod_usua_sid,
                                          'Error en la consulta',
                                          p_ret_mens,
                                          NULL);
  END;


  PROCEDURE sp_list_roles
  (
    p_cod_rol           IN  VARCHAR2,
    p_cod_rol_jef_fi    IN  VARCHAR2,
    p_num_prof_veh      IN  VARCHAR2,
    p_cod_clie          IN  VARCHAR2,
    p_cod_zona          IN  VARCHAR2,
    p_cod_filial        IN  VARCHAR2,
    p_cod_area_vta      IN  VARCHAR2,
    p_flag_busq         IN  VARCHAR2,
    p_flag_edit         IN  VARCHAR2,
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
    ve_error EXCEPTION;
    v_cod_para_rol VARCHAR2(20);
    v_cod_area_vta VARCHAR2(20);
    v_cod_filial VARCHAR2(20);
    v_cod_zona NUMBER;
    v_rol_res_cred VARCHAR2(20);
    v_rol_jef_fina VARCHAR2(20);
    v_cant_perf NUMBER;

  BEGIN



    IF p_flag_edit = 'EDIT' THEN

        SELECT val_para_num INTO v_rol_res_cred FROM vve_cred_soli_para WHERE cod_cred_soli_para = 'ROLRESCRED';
        SELECT val_para_car INTO v_rol_jef_fina FROM vve_cred_soli_para WHERE cod_cred_soli_para = 'ROLJEFFINCRE';

        SELECT COUNT(*) INTO v_cant_perf FROM sis_mae_perfil_usuario WHERE 0<(select instr(val_para_car,cod_id_perfil)
                                                                              from   vve_cred_soli_para
                                                                              where cod_cred_soli_para = 'ROLJEFFINCRE')
        AND cod_id_usuario = p_cod_usua_web AND ind_inactivo = 'N';


        IF p_num_prof_veh IS NOT NULL THEN

            SELECT cod_zona INTO v_cod_zona
            FROM vve_proforma_veh p INNER JOIN vve_mae_zona_filial f ON (p.cod_filial = f.cod_filial)
            WHERE num_prof_veh = p_num_prof_veh;

        ELSE

            select z.cod_zona INTO v_cod_zona
            from gen_perso_vendedor gv inner join arccve v on (gv.vendedor = v.vendedor)
            inner join vve_mae_zona_filial f on (v.cod_filial = f.cod_filial) inner join vve_mae_zona z on (f.cod_zona = z.cod_zona)
            where gv.cod_perso = p_cod_clie AND gv.IND_INACTIVO = 'N' and ROWNUM = 1;

        END IF;


        IF (v_cant_perf > 0) THEN


            OPEN p_ret_cursor FOR
                select distinct co_usuario as idUsuario, UPPER(u.TXT_APELLIDOS) as apellidos, UPPER(u.TXT_NOMBRES) as nombre
                from VVE_CRED_ORG_CRED_VTAS v inner join sis_mae_usuario u
                on (v.co_usuario = u.txt_usuario)
                where (cod_rol_usuario = v_rol_res_cred)
                      AND
                      (COD_ZONA IN (select DISTINCT COD_ZONA from vve_cred_org_cred_vtas WHERE  co_usuario = p_cod_usua_sid));

        END IF;
    ELSE

        SELECT val_para_num INTO v_cod_para_rol FROM vve_cred_soli_para WHERE cod_cred_soli_para = p_cod_rol;

        IF p_flag_busq = 'PROF' THEN

            -- CON PROFORMA
            SELECT cod_area_vta, p.cod_filial, cod_zona INTO v_cod_area_vta, v_cod_filial, v_cod_zona
            FROM vve_proforma_veh p INNER JOIN vve_mae_zona_filial f ON (p.cod_filial = f.cod_filial)
            WHERE num_prof_veh = p_num_prof_veh;

        ELSE

            -- POST VENTA
            v_cod_area_vta := p_cod_area_vta;
            v_cod_filial := p_cod_filial;
            v_cod_zona := p_cod_zona;

        END IF;

            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO', 'SP_LIST_ROLES', p_cod_usua_sid, 'datos cod_zona: '||v_cod_zona||
            ' cod_filial: '||v_cod_filial||'cod_area_vta: '||v_cod_area_vta||' v_cod_para_rol: '||v_cod_para_rol
            , p_ret_mens
            , NULL);

        OPEN p_ret_cursor FOR
            SELECT U.TXT_USUARIO as idUsuario, U.TXT_APELLIDOS  as apellidos, U.TXT_NOMBRES as nombre
            FROM SIS_MAE_USUARIO U, sis_mae_perfil_usuario P, vve_cred_org_cred_vtas v
            WHERE P.COD_ID_PERFIL = v_cod_para_rol
            and P.COD_ID_PERFIL = v.cod_rol_usuario
            AND U.COD_ID_USUARIO = P.COD_ID_USUARIO
            and u.txt_usuario = v.co_usuario
            and v.cod_zona = v_cod_zona
            and v.cod_filial = v_cod_filial
            and v.cod_area_vta = v_cod_area_vta;
    END IF;

    p_ret_esta := 1;
    p_ret_mens := 'Se realizo correctamente la consulta';

  EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_ROLES', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_ROLES:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_ROLES', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_roles;

  FUNCTION fn_list_proforma
  (
    p_cod_soli_cred IN vve_cred_soli.cod_soli_cred%TYPE,
    p_ind_todos     IN CHAR
  ) RETURN SYS_REFCURSOR AS
    lc_cursor SYS_REFCURSOR;
  BEGIN
    OPEN lc_cursor FOR
        SELECT pv.vendedor,
            pv.cod_filial,
            sp.num_prof_veh,
            sp.val_vta_tot_fin,
            pv.cod_moneda_prof,
            sp.can_veh_fin,
            pd.val_pre_veh
        FROM vve_cred_soli_prof sp
        INNER JOIN vve_proforma_veh pv
            ON pv.num_prof_veh = sp.num_prof_veh
        INNER JOIN vve_proforma_veh_det pd
            ON sp.num_prof_veh = pd.num_prof_veh
        WHERE cod_soli_cred = p_cod_soli_cred
            AND (p_ind_todos = 'S' OR rownum = 1);
    RETURN lc_cursor;
  END fn_list_proforma;


  PROCEDURE sp_inse_cred_soli_hist (
    p_cod_soli_cred     IN  vve_cred_soli_hist.cod_soli_cred%TYPE,
    p_val_lc_actu       IN  vve_cred_soli_hist.val_lc_actual%TYPE,
    p_fec_plaz          IN  VARCHAR2,
    p_val_lc_util       IN  vve_cred_soli_hist.val_lc_util%TYPE,
    p_val_dven_dc       IN  vve_cred_soli_hist.VAL_MONT_DVEN_DC%TYPE,
    p_val_dven_di       IN  vve_cred_soli_hist.VAL_MONT_DVEN_DI%TYPE,
    p_val_porc_dc       IN  vve_cred_soli_hist.VAL_PORC_DVEN_DC%TYPE,
    p_val_porc_di       IN  vve_cred_soli_hist.VAL_PORC_DVEN_DI%TYPE,
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cod           OUT VARCHAR2,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    p_ret_cod_hist vve_cred_soli_hist.cod_cred_soli_hist%TYPE;
    v_cant_regi NUMBER;

  BEGIN

    BEGIN
        SELECT DISTINCT cod_cred_soli_hist INTO p_ret_cod_hist
        FROM vve_cred_soli_hist WHERE cod_soli_cred = p_cod_soli_cred;
    EXCEPTION
        WHEN OTHERS THEN
        p_ret_cod_hist := NULL;
    END;

    IF (p_ret_cod_hist IS NOT NULL) THEN
         UPDATE vve_cred_soli_hist
         SET
                VAL_LC_ACTUAL = p_val_lc_actu,
                FEC_PLAZO = TO_DATE(p_fec_plaz, 'DD/MM/YYYY'),
                VAL_LC_UTIL = p_val_lc_util ,
                VAL_MONT_DVEN_DC = p_val_dven_dc,
                VAL_MONT_DVEN_DI = p_val_dven_di,
                VAL_PORC_DVEN_DC = p_val_porc_dc ,
                VAL_PORC_DVEN_DI = p_val_porc_di,
                FEC_MODI_REGI = SYSDATE,
                COD_USUA_MODI_REGI = p_cod_usua_sid
         WHERE
               cod_soli_cred = p_cod_soli_cred;

            p_ret_esta := 1;
            p_ret_mens := 'Se registró correctamente.';
            p_ret_cod := TO_CHAR(p_ret_cod_hist);
        -- <F Req. 87567 E2.1 ID## AVILCA 10/02/2021>
    ELSE

        BEGIN
            SELECT
                lpad(nvl(MAX(cod_cred_soli_hist), 0) + 1, 10, '0')
            INTO p_ret_cod_hist
            FROM
                vve_cred_soli_hist;
            EXCEPTION
                WHEN OTHERS THEN
                p_ret_cod_hist := NULL;
        END;

        IF (p_ret_cod_hist IS NOT NULL) THEN

            INSERT INTO vve_cred_soli_hist (
                COD_CRED_SOLI_HIST,
                COD_SOLI_CRED,
                VAL_LC_ACTUAL,
                FEC_PLAZO,
                VAL_LC_UTIL,
                VAL_MONT_DVEN_DC,
                VAL_MONT_DVEN_DI,
                VAL_PORC_DVEN_DC,
                VAL_PORC_DVEN_DI,
                FEC_CREA_REGI,
                COD_USUA_CREA_REGI
            ) VALUES (
                p_ret_cod_hist,
                p_cod_soli_cred,
                p_val_lc_actu,
                TO_DATE(p_fec_plaz, 'YYYY/MM/DD'),
                p_val_lc_util,
                p_val_dven_dc,
                p_val_dven_di,
                p_val_porc_dc,
                p_val_porc_di,
                SYSDATE,
                p_cod_usua_sid
            );

            p_ret_esta := 1;
            p_ret_mens := 'Se registró correctamente.';
            p_ret_cod := TO_CHAR(p_ret_cod_hist);

        ELSE

            p_ret_esta := 0;
            p_ret_mens := 'Error al registrar.';
            p_ret_cod := '';

        END IF;

    END IF;
       --<I Req. 87567 E2.1 ID## AVILCA 04/12/2020>
     -- ACtualizando fecha de ejecución de registro y verificando cierre de etapa
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E2','A9',p_cod_usua_sid,p_ret_esta,p_ret_mens);
        --<F Req. 87567 E2.1 ID## AVILCA 04/12/2020>

  EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI_HIST', p_cod_usua_sid, 'Error al insertar datos en el historico de operaciones cabecera'
        , p_ret_mens, p_ret_cod_hist);
        ROLLBACK;
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := p_ret_mens||'SP_INSE_CRED_SOLI_HIST:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_SOLI_HIST', p_cod_usua_sid, 'Error al insertar datos en el historico de operaciones cabecera'
        , p_ret_mens, p_ret_cod_hist);
        ROLLBACK;
  END sp_inse_cred_soli_hist;


  PROCEDURE sp_inse_cred_hist_ope
  (
    p_cod_cred_soli_hist    IN  vve_cred_hist_ope.cod_cred_soli_hist%TYPE,
    p_cod_soli_cred         IN  vve_cred_hist_ope.cod_soli_cred%TYPE,
    p_cod_cia               IN  vve_cred_hist_ope.cod_cia%TYPE,
    p_cod_tip_cred          IN  vve_cred_hist_ope.cod_tip_cred%TYPE,
    p_cod_oper              IN  vve_cred_hist_ope.cod_oper%TYPE,
    p_cod_moneda            IN  vve_cred_hist_ope.cod_moneda%TYPE,
    p_val_monto_cred        IN  vve_cred_hist_ope.val_monto_cred%TYPE,
    p_can_letras            IN  vve_cred_hist_ope.can_letras%TYPE,
    p_val_tea               IN  vve_cred_hist_ope.val_tea%TYPE,
    p_val_saldo             IN  vve_cred_hist_ope.val_saldo%TYPE,
    p_fec_ult_venc          IN  VARCHAR2,
    p_cod_estado_op         IN  vve_cred_hist_ope.cod_estado_op%TYPE,
    p_fec_emi_op            IN  VARCHAR2,
    p_val_porc_ci           IN  vve_cred_hist_ope.val_porc_ci%TYPE,
    p_val_val_gar           IN  vve_cred_hist_ope.val_val_gar%TYPE,
    p_val_porc_rat_gar      IN  vve_cred_hist_ope.val_porc_rat_gar%TYPE,
    p_cod_clie              IN  vve_cred_hist_ope.cod_clie%TYPE,
    p_dias_max_venc         IN  vve_cred_hist_ope.DIAS_MAX_VENC%TYPE, --<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
    p_dias_venc_prom        IN  vve_cred_hist_ope.DIAS_VENC_PROM%TYPE, --<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
    p_cod_usua_sid          IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web          IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cod               OUT VARCHAR2,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR2
  ) AS
    ve_error EXCEPTION;
    --p_ret_cod_ope vve_cred_hist_ope.cod_hist_ope%TYPE;
    v_cant_reg_det NUMBER;

  BEGIN

    select count(*) into v_cant_reg_det
    from  vve_cred_hist_ope
    where cod_soli_cred = p_cod_soli_cred and
    cod_cred_soli_hist = p_cod_cred_soli_hist and
    COD_OPER = p_cod_oper;

    IF v_cant_reg_det > 0 THEN
        --EXISTE UN REGISTRO
        UPDATE vve_cred_hist_ope SET
        COD_CIA = p_cod_cia,
        COD_TIP_CRED = p_cod_tip_cred,
        COD_MONEDA = p_cod_moneda,
        VAL_MONTO_CRED = p_val_monto_cred,
        CAN_LETRAS = p_can_letras,
        VAL_TEA = p_val_tea,
        VAL_SALDO = p_val_saldo,
        FEC_ULT_VENC = DECODE(p_fec_ult_venc,NULL,NULL,TO_DATE(p_fec_ult_venc, 'DD/MM/YYYY')),
        COD_ESTADO_OP =p_cod_estado_op,
        FEC_EMI_OP = DECODE(p_fec_emi_op,NULL,NULL,TO_DATE(p_fec_emi_op, 'DD/MM/YYYY')),
        VAL_PORC_CI = p_val_porc_ci,
        VAL_VAL_GAR = p_val_val_gar,
        VAL_PORC_RAT_GAR = p_val_porc_rat_gar,
        COD_CLIE = p_cod_clie,
        DIAS_MAX_VENC = p_dias_max_venc , --<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
        DIAS_VENC_PROM= p_dias_venc_prom, --<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
        FEC_MODI_REGI = SYSDATE,
        COD_USUA_MODI_REGI = p_cod_usua_sid
        WHERE cod_soli_cred = p_cod_soli_cred AND
        cod_cred_soli_hist = p_cod_cred_soli_hist AND
        COD_OPER = p_cod_oper;

    ELSE
        --NUEVO REGISTRO
        INSERT INTO vve_cred_hist_ope (
                COD_CRED_SOLI_HIST,
                COD_HIST_OPE,
                COD_SOLI_CRED,
                COD_CIA,
                COD_TIP_CRED,
                COD_OPER,
                COD_MONEDA,
                VAL_MONTO_CRED,
                CAN_LETRAS,
                VAL_TEA,
                VAL_SALDO,
                FEC_ULT_VENC,
                COD_ESTADO_OP,
                FEC_EMI_OP,
                VAL_PORC_CI,
                VAL_VAL_GAR,
                VAL_PORC_RAT_GAR,
                COD_CLIE,
                DIAS_MAX_VENC,--<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
                DIAS_VENC_PROM,--<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
                FEC_CREA_REGI,
                COD_USUA_CREA_REGI
            ) VALUES (
                p_cod_cred_soli_hist,
                p_cod_oper,--p_ret_cod_ope, se cambia al codigo del valor de la operación
                p_cod_soli_cred,
                p_cod_cia,
                p_cod_tip_cred,
                p_cod_oper,
                p_cod_moneda,
                p_val_monto_cred,
                p_can_letras,
                p_val_tea,
                p_val_saldo,
                DECODE(p_fec_ult_venc,NULL,NULL,TO_DATE(p_fec_ult_venc, 'DD/MM/YYYY')),
                p_cod_estado_op,
                DECODE(p_fec_emi_op,NULL,NULL,TO_DATE(p_fec_emi_op, 'DD/MM/YYYY')),
                p_val_porc_ci,
                p_val_val_gar,
                p_val_porc_rat_gar,
                p_cod_clie,
                p_dias_max_venc,--<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
                p_dias_venc_prom,--<I Req. 87567 E2.1 ID## AVILCA 10/02/2020>
                SYSDATE,
                p_cod_usua_sid
            );
        commit;
    END IF;
    p_ret_esta := 1;
    p_ret_mens := 'Se registró correctamente.';

  EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_HIST_OPE', p_cod_usua_sid, 'Error al insertar datos en el historico de operaciones detalle'
        , p_ret_mens, p_cod_oper);
        ROLLBACK;
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := p_ret_mens||'SP_INSE_CRED_HIST_OPE:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_CRED_HIST_OPE', p_cod_usua_sid, 'Error al insertar datos en el historico de operaciones detalle'
        , p_ret_mens, p_cod_oper);
        ROLLBACK;
  END sp_inse_cred_hist_ope;

  --ECUBAS <I>89642
  PROCEDURE sp_list_motivos_aprobacion (

  p_cod_soli_cred   IN                vve_cred_hist_ope.cod_soli_cred%TYPE,
  p_cod_usua_sid    IN                sistemas.usuarios.co_usuario%TYPE,
  p_ret_cursor      OUT               SYS_REFCURSOR,
  p_ret_esta        OUT               NUMBER,
  p_ret_mens        OUT               VARCHAR2
  ) AS
    ve_error EXCEPTION;

  BEGIN

  OPEN p_ret_cursor FOR
  SELECT V.FEC_ESTA_APRO,
         U.TXT_NOMBRES ||' '||U.TXT_APELLIDOS AS TXT_NOMBRES ,
         V.TXT_COME_APRO
        FROM VVE_CRED_SOLI_APRO V,SIS_MAE_USUARIO U
        WHERE U.COD_ID_USUARIO = V.COD_ID_USUA
          AND V.COD_SOLI_CRED= p_cod_soli_cred
          AND V.EST_APRO='EEA01' --TRAE A LOS QUE SOLO FUERON APROBADOS
          AND V.TXT_COME_APRO <> ' ';

        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';

  EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_motivos_aprobacion', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
        , NULL);
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LIST_PROFORMA:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_motivos_aprobacion', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
        , NULL);
  END sp_list_motivos_aprobacion;
  --ECUBAS <F>89642

  --<I Req. 87567 E2.1 ID:9 AVILCA 12/05/2020>
   PROCEDURE sp_list_param_solcre
  (
    p_cod_param         IN  VARCHAR2,
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN  sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
    ve_error EXCEPTION;

  BEGIN

        OPEN p_ret_cursor FOR
        SELECT cod_cred_soli_para,des_cred_soli_para,val_para_num,val_para_car
        FROM vve_cred_soli_para WHERE cod_cred_soli_para = p_cod_param;


    p_ret_esta := 1;
    p_ret_mens := 'Se realizo correctamente la consulta';

  EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_param_solcre', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_list_param_solcre:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_param_solcre', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_param_solcre;
  --<F Req. 87567 E2.1 ID:9 AVILCA 12/05/2020>
 
 --<I Req. 87567 E2.1 ID:9 AVILCA 10/02/2021>
   PROCEDURE sp_list_clie_creditos
  (
    p_cod_soli_cred     IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
    ve_error EXCEPTION;

  BEGIN

        OPEN p_ret_cursor FOR
        SELECT cod_cred_soli_hist,
               cod_soli_cred,
               val_lc_actual,
               TO_CHAR(fec_plazo,'dd/MM/yyyy') fec_plazo,
               val_lc_util,
               val_mont_dven_dc,
               val_mont_dven_di,
               val_porc_dven_dc,
               val_porc_dven_di

         FROM  vve_cred_soli_hist
        WHERE cod_soli_cred = p_cod_soli_cred;


    p_ret_esta := 1;
    p_ret_mens := 'Se realizo correctamente la consulta';

  EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_clie_creditos', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_list_param_solcre:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_clie_creditos', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_clie_creditos;

  PROCEDURE sp_list_clie_movimientos
  (
    p_cod_soli_cred     IN  vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid      IN  sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR
  ) AS
    ve_error EXCEPTION;

  BEGIN

        OPEN p_ret_cursor FOR
        SELECT cod_cred_soli_hist,
               cod_hist_ope,
               cod_soli_cred,
               cod_cia,
               cod_tip_cred,
               (SELECT m.descripcion from vve_tabla_maes m
                    WHERE m.cod_grupo = 86
                    AND m.cod_tipo = cod_tip_cred) descripcion,
               cod_oper,
               cod_moneda,
               val_monto_cred,
               can_letras,
               val_tea,
               val_saldo,
               to_char(fec_ult_venc,'DD/MM/YYYY') fec_ult_venc,
               cod_estado_op,
               to_char(fec_emi_op,'DD/MM/YYYY') fec_emi_op,
               val_porc_ci,
               val_val_gar,
               val_porc_rat_gar,
               cod_clie,
               dias_max_venc,
               dias_venc_prom

         FROM  vve_cred_hist_ope
        WHERE cod_soli_cred = p_cod_soli_cred;


    p_ret_esta := 1;
    p_ret_mens := 'Se realizo correctamente la consulta';

  EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_clie_movimientos', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_list_param_solcre:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_clie_movimientos', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_clie_movimientos;
  --<F Req. 87567 E2.1 ID:9 AVILCA 10/01/2021>
END pkg_sweb_cred_soli;
/
