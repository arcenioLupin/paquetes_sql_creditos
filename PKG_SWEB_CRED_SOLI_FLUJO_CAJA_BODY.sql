create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_FLUJO_CAJA AS
    
     PROCEDURE sp_inse_param_camiones 
    (      
        p_cod_soli_cred         IN      vve_cred_soli.cod_soli_cred%TYPE,
        p_no_cia                IN      vve_cred_soli.cod_empr%TYPE,
        p_list_ingr_egre        IN      VVE_TYTA_LIST_INGR_EGRE,
        p_indi_tipo_fc          IN      VARCHAR2,
        p_cod_usua_sid          IN      sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta              OUT     NUMBER,
        p_ret_mens              OUT     VARCHAR2
    ) AS
        ve_error EXCEPTION;
        p_ret_cod_cred_soli_pfc vve_cred_soli_para_fc.cod_cred_soli_pfc%TYPE;
        --v_cantidad NUMERIC;
        --v_cant_param NUMERIC;
    
    BEGIN
    
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                  'SP_INSE_PARAM_CAMIONES',
                                  p_cod_usua_sid,
                                  'Entro en sp_inse_param_camiones',
                                  NULL,
                                  NULL);
                                  
                                  
        delete from vve_cred_soli_para_fc where cod_soli_cred = p_cod_soli_cred; 
        delete from vve_cred_soli_fact_fc where cod_soli_cred = p_cod_soli_cred;
        delete from vve_cred_soli_fact_ajust where cod_soli_cred = p_cod_soli_cred;
        commit;
        
       /* BEGIN                   
            SELECT 
                COUNT(*) 
            INTO 
                v_cantidad
            FROM 
                vve_cred_soli_para_fc WHERE cod_soli_cred = p_cod_soli_cred
                AND ind_tipo_fc = p_indi_tipo_fc;
            EXCEPTION
                WHEN OTHERS THEN
                v_cantidad := NULL;
        END;*/
        
        /*IF v_cantidad IS NOT NULL AND v_cantidad > 0 AND p_indi_tipo_fc = 'C' THEN
            p_ret_esta := 1;
            p_ret_mens := 'Se realizó el proceso satisfactoriamente para Camiones';
            RETURN;
        END IF;
        
        IF v_cantidad IS NOT NULL AND v_cantidad > 0 AND p_indi_tipo_fc = 'I' THEN
            p_ret_esta := 1;
            p_ret_mens := 'Se realizó el proceso satisfactoriamente para Interprovincial';
            RETURN;
        END IF;*/
        
        /*IF v_cantidad IS NOT NULL AND v_cantidad > 0 AND p_indi_tipo_fc = 'U' THEN
            p_ret_esta := 1;
            p_ret_mens := 'Se realizó el proceso satisfactoriamente para Urbano';
            RETURN;
        END IF;*/
        
        FOR i IN 1 .. p_list_ingr_egre.COUNT LOOP
        
            /*BEGIN
                SELECT
                    lpad(nvl(MAX(cod_cred_soli_pfc), 0) + 1, 10, '0')
                INTO p_ret_cod_cred_soli_pfc
                FROM
                    vve_cred_soli_para_fc;
                EXCEPTION
                    WHEN OTHERS THEN
                    p_ret_cod_cred_soli_pfc := NULL;
            END;
            */
            /*SELECT  COUNT(*) INTO  v_cant_param
            FROM  vve_cred_soli_para_fc WHERE cod_soli_cred = p_cod_soli_cred AND ind_tipo_fc = p_list_ingr_egre(i).IND_TIPO_FC 
            AND COD_CRED_PARA_FC = p_list_ingr_egre(i).COD_PARA_FC;
            
            IF v_cant_param IS NOT NULL AND v_cant_param > 0 THEN
                UPDATE vve_cred_soli_para_fc set
                NO_CIA = p_no_cia,
                IND_TIPO_FC = p_list_ingr_egre(i).IND_TIPO_FC,
                IND_TIPO = p_list_ingr_egre(i).IND_TIPO,
                VAL_NRO_RUTA = p_list_ingr_egre(i).NRO_RUTA,
                VAL_PARA = p_list_ingr_egre(i).VAL_PARA,
                FEC_USUA_MODI_REGI    = SYSDATE 
                WHERE 
                cod_soli_cred = p_cod_soli_cred AND 
                ind_tipo_fc = p_list_ingr_egre(i).IND_TIPO_FC AND 
                COD_CRED_PARA_FC = p_list_ingr_egre(i).COD_PARA_FC;
                
            ELSE */
                INSERT INTO vve_cred_soli_para_fc (
                    COD_CRED_SOLI_PFC, COD_SOLI_CRED, NO_CIA, COD_CRED_PARA_FC, IND_TIPO_FC,
                    IND_TIPO, VAL_NRO_RUTA, VAL_PARA, COD_USUA_CREA_REGI, FEC_USUA_CREA_REGI , VAL_TXT
                ) VALUES (
                    SEQ_CRED_SOLI_PARA_FC.NEXTVAL, p_cod_soli_cred, p_no_cia, p_list_ingr_egre(i).COD_PARA_FC, 
                    p_list_ingr_egre(i).IND_TIPO_FC, p_list_ingr_egre(i).IND_TIPO, p_list_ingr_egre(i).NRO_RUTA, 
                    p_list_ingr_egre(i).VAL_PARA, p_cod_usua_sid, SYSDATE, p_list_ingr_egre(i).VAL_TXT
                );
            --END IF;
            commit;
           
        END LOOP;
        
        p_ret_esta := 1;
        p_ret_mens := 'Se realizó el proceso satisfactoriamente';
        
        -- Actualizando fecha de ejecución de registro y verificando cierre de etapa
        PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E2','A10',p_cod_usua_sid,p_ret_esta,p_ret_mens); 
    
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_PARAM_CAMIONES', p_cod_usua_sid, 'Error al insertar parametros de camiones '||p_cod_soli_cred
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := p_ret_mens||'SP_INSE_PARAM_CAMIONES:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_PARAM_CAMIONES', p_cod_usua_sid, 'Error al insertar parametros de camiones'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
            
    END sp_inse_param_camiones;
    
    
    PROCEDURE sp_inse_fact_mes 
    (      
         p_cod_soli_cred                IN      vve_cred_soli.cod_soli_cred%TYPE,
         p_no_cia                       IN      vve_cred_soli.cod_empr%TYPE,
         p_fac_cons_ingr                IN      NUMERIC,
         p_ind_fac_fijo_vari_ingr       IN      VARCHAR2,
         p_fac_cons_egre                IN      NUMERIC,
         p_ind_fac_fijo_vari_egre       IN      VARCHAR2,
         p_fec_ini_fact_ingr            IN      VARCHAR2,
         p_fec_fin_fact_ingr            IN      VARCHAR2,
         p_fec_ini_fact_egre            IN      VARCHAR2,
         p_fec_fin_fact_egre            IN      VARCHAR2,
         p_list_fact_mes                IN      VVE_TYTA_LIST_FACT_MES,
         p_indi_tipo_fc                 IN      VARCHAR2,
         p_cant_ruta                    IN      NUMBER,
         p_cod_usua_sid                 IN      sistemas.usuarios.co_usuario%TYPE,
         p_ret_esta                     OUT     NUMBER,
         p_ret_mens                     OUT     VARCHAR2
    ) AS 
        ve_error EXCEPTION;
        p_ret_cod_cred_soli_ffc vve_cred_soli_fact_fc.cod_cred_soli_ffc%TYPE;
        v_cod_simu NUMBER; 
        
        v_cantidad NUMERIC;    
        v_cantidad_simu NUMERIC;
        v_mes_ini_simu VARCHAR(2);
        v_anio_ini_simu VARCHAR(4);
        v_mes_fin_simu VARCHAR(2);
        v_anio_fin_simu VARCHAR(4);
        
        v_fec_ini_fact_ingr_mes VARCHAR(2);
        v_fec_ini_fact_ingr_anio VARCHAR(4);
        v_fec_fin_fact_ingr_mes VARCHAR(2);
        v_fec_fin_fact_ingr_anio VARCHAR(4);
        v_fec_ini_fact_egre_mes VARCHAR(2);
        v_fec_ini_fact_egre_anio VARCHAR(4);
        v_fec_fin_fact_egre_mes VARCHAR(2);
        v_fec_fin_fact_egre_anio VARCHAR(4);
        
        v_mes_ini_ingr VARCHAR(2);
        v_anio_ini_ingr VARCHAR(4);
        v_mes_fin_ingr VARCHAR(2);
        v_anio_fin_ingr VARCHAR(4);
        v_mes_ini_egre VARCHAR(2);
        v_anio_ini_egre VARCHAR(4);
        v_mes_fin_egre VARCHAR(2);
        v_anio_fin_egre VARCHAR(4);
        
        v_validador_ingr VARCHAR2(1);
        v_validador_egre VARCHAR2(1);
        
        v_cant_resu NUMBER;
        v_cant_ruta NUMBER;
        v_cont_auxi NUMBER;
        v_cant_ajust NUMBER;
        
    BEGIN
    
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_INSE_FACT_MES',
                          p_cod_usua_sid,
                          '1 ----------------------------------------- 1',
                          NULL,
                          NULL);
        
        BEGIN
            SELECT cod_simu INTO v_cod_simu 
            FROM vve_cred_simu 
            WHERE cod_soli_cred = p_cod_soli_cred AND ind_inactivo = 'N';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_cod_simu := NULL;
            p_ret_esta := -1;
            p_ret_mens := 'La solicitud no tiene simulador';
            RETURN;
        END;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_INSE_FACT_MES',
                          p_cod_usua_sid,
                          'Simulador de la Solicitud X' || v_cod_simu,
                          NULL,
                          NULL);
                          
         
        
        -- VALIDANDO RANGOS DE FECHAS PARA INSERTAR EN LA TABLA DE FACTOR X MES
        -- CANTIDAD DE LETRAS DEL SIMULADOR LETRA FECHA INI - LETRA FECHA FIN
        SELECT COUNT(*) INTO v_cantidad_simu FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu;
        
        -- MES Y AÑOS DEL SIMULADOR
        SELECT EXTRACT(MONTH FROM fec_venc), EXTRACT(YEAR FROM fec_venc)
        INTO v_mes_ini_simu, v_anio_ini_simu
        FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu AND cod_nume_letr = 1;
        
        SELECT EXTRACT(MONTH FROM fec_venc), EXTRACT(YEAR FROM fec_venc)
        INTO v_mes_fin_simu, v_anio_fin_simu
        FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu AND cod_nume_letr = v_cantidad_simu;
        
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_INSE_FACT_MES',
                          p_cod_usua_sid,
                          'MES Y AÑOS DEL SIMULADOR X ' || v_mes_ini_simu ||
                          ' ' || v_anio_ini_simu || ' ' || v_mes_fin_simu ||
                          ' ' || v_anio_fin_simu,
                          NULL,
                          NULL);
                          
        select extract(month from TO_DATE(p_fec_ini_fact_ingr, 'DD/MM/YYYY')), extract(year from TO_DATE(p_fec_ini_fact_ingr, 'DD/MM/YYYY')) 
        INTO v_fec_ini_fact_ingr_mes, v_fec_ini_fact_ingr_anio
        from dual;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_INSE_FACT_MES',
                          p_cod_usua_sid,
                          'v_fec_ini_fact_ingr_mes X ' || v_fec_ini_fact_ingr_mes || 
                          'v_fec_ini_fact_ingr_anio X ' || v_fec_ini_fact_ingr_anio,
                          NULL,
                          NULL);
        
        select extract(month from TO_DATE(p_fec_fin_fact_ingr, 'DD/MM/YYYY')), extract(year from TO_DATE(p_fec_fin_fact_ingr, 'DD/MM/YYYY')) 
        INTO v_fec_fin_fact_ingr_mes, v_fec_fin_fact_ingr_anio
        from dual;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_INSE_FACT_MES',
                          p_cod_usua_sid,
                          'v_fec_fin_fact_ingr_mes X ' || v_fec_fin_fact_ingr_mes || 
                          'v_fec_fin_fact_ingr_anio X ' || v_fec_fin_fact_ingr_anio,
                          NULL,
                          NULL);
        
        select extract(month from TO_DATE(p_fec_ini_fact_egre, 'DD/MM/YYYY')), extract(year from TO_DATE(p_fec_ini_fact_egre, 'DD/MM/YYYY')) 
        INTO v_fec_ini_fact_egre_mes, v_fec_ini_fact_egre_anio
        from dual;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_INSE_FACT_MES',
                          p_cod_usua_sid,
                          'v_fec_ini_fact_egre_mes X ' || v_fec_ini_fact_egre_mes || 
                          'v_fec_ini_fact_egre_anio X ' || v_fec_ini_fact_egre_anio,
                          NULL,
                          NULL);
        
        select extract(month from TO_DATE(p_fec_fin_fact_egre, 'DD/MM/YYYY')), extract(year from TO_DATE(p_fec_fin_fact_egre, 'DD/MM/YYYY')) 
        INTO v_fec_fin_fact_egre_mes, v_fec_fin_fact_egre_anio
        from dual;
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_INSE_FACT_MES',
                          p_cod_usua_sid,
                          'v_fec_fin_fact_egre_mes X  ' || v_fec_fin_fact_egre_mes || 
                          'v_fec_fin_fact_egre_anio X ' || v_fec_fin_fact_egre_anio,
                          NULL,
                          NULL);
        
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_INSE_FACT_MES',
                          p_cod_usua_sid,
                          'FECHAS INI - FIN INGR Y EGRE X ' || p_fec_ini_fact_ingr ||
                          ' ' || p_fec_fin_fact_ingr || ' ' || p_fec_ini_fact_egre ||
                          ' ' || p_fec_fin_fact_egre,
                          NULL,
                          NULL);          
        
        IF p_ind_fac_fijo_vari_ingr = 'FIF' THEN
            v_validador_ingr := 'S';
        ELSE
            
            IF (v_mes_ini_simu = v_fec_ini_fact_ingr_mes AND v_anio_ini_simu = v_fec_ini_fact_ingr_anio
                AND v_mes_fin_simu = v_fec_fin_fact_ingr_mes AND v_anio_fin_simu = v_fec_fin_fact_ingr_anio) THEN
                v_validador_ingr := 'S';    
            ELSE 
                v_validador_ingr := 'N';
            END IF;
            
        END IF;
        
        IF p_ind_fac_fijo_vari_egre = 'FEF' THEN
            v_validador_egre := 'S';
        ELSE    
        
            IF (v_mes_ini_simu = v_fec_ini_fact_egre_mes AND v_anio_ini_simu = v_fec_ini_fact_egre_anio
                AND v_mes_fin_simu = v_fec_fin_fact_egre_mes AND v_anio_fin_simu = v_fec_fin_fact_egre_anio) THEN
                v_validador_egre := 'S';    
            ELSE 
                v_validador_egre := 'N';
            END IF;
        
        END IF;
        
        IF (v_validador_ingr = 'N' AND v_validador_egre = 'N') THEN
            p_ret_esta := 0;
            p_ret_mens := 'Los rangos de fechas del Factor para Ingresos y para Egresos no concuerdan con el Simulador.';
            RETURN;
        END IF;
        
        IF (v_validador_ingr = 'N' AND v_validador_egre = 'S') THEN
            p_ret_esta := 0;
            p_ret_mens := 'Los rangos de fechas del Factor para Ingresos no concuerdan con el Simulador.';
            RETURN;
        END IF;
        
        IF (v_validador_ingr = 'S' AND v_validador_egre = 'N') THEN
            p_ret_esta := 0;
            p_ret_mens := 'Los rangos de fechas del Factor para Egresos no concuerdan con el Simulador.';
            RETURN;
        END IF;
        
        
        BEGIN
            SELECT 
                COUNT(*) INTO v_cant_resu
            FROM 
                vve_cred_soli_fact_fc 
            WHERE 
                cod_soli_cred = p_cod_soli_cred;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_cant_resu := 0;
        END;
        
        BEGIN
            SELECT 
                COUNT(*) INTO v_cant_ajust
            FROM 
                vve_cred_soli_fact_ajust 
            WHERE 
                cod_soli_cred = p_cod_soli_cred;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_cant_ajust := 0;
        END;
        
        IF (v_cant_ajust > 0) THEN
            p_ret_esta := 1;
            p_ret_mens := 'Se realizó el proceso satisfactoriamente';
            RETURN;
        END IF;
        
        IF (v_cant_resu > 0) THEN
            p_ret_esta := 1;
            p_ret_mens := 'Se realizó el proceso satisfactoriamente';
            RETURN;
        END IF;
        
        IF (v_validador_ingr = 'S' AND v_validador_egre = 'S') THEN
            
            v_cont_auxi := 1;
            IF p_indi_tipo_fc = 'U' THEN
                
                WHILE v_cont_auxi <= p_cant_ruta LOOP
                
                    FOR rs_simu IN (select EXTRACT(MONTH FROM fec_venc) as mes, EXTRACT(YEAR FROM fec_venc) as anio 
                        from vve_cred_simu_letr where cod_simu = v_cod_simu order by to_number(cod_nume_letr)) LOOP
                    
                        FOR rs_ingr IN (select cod_cred_para_fc, ind_ingr_egre, ind_tipo_fc 
                                    from vve_cred_para_fc where ind_ingr_egre = 'IF' and ind_tipo_fc = p_indi_tipo_fc) LOOP
                    
                            BEGIN
                                SELECT
                                    lpad(nvl(MAX(cod_cred_soli_ffc), 0) + 1, 10, '0')
                                INTO p_ret_cod_cred_soli_ffc
                                FROM
                                    vve_cred_soli_fact_fc;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                    p_ret_cod_cred_soli_ffc := NULL;
                            END;
                    
                            INSERT INTO vve_cred_soli_fact_fc (
                                COD_CRED_SOLI_FFC, COD_SOLI_CRED, NO_CIA, VAL_MES, VAL_ANO, COD_CRED_PARA_FACT,
                                IND_TIPO_FC, IND_TIPO, VAL_NRO_RUTA, VAL_PARA, VAL_FACT_AJUST,
                                COD_USUA_CREA_REGI, FEC_USUA_CREA_REGI 
                            ) VALUES (
                                SEQ_CRED_SOLI_FACT_FC.NEXTVAL, p_cod_soli_cred, p_no_cia, rs_simu.mes, rs_simu.anio, 
                                rs_ingr.cod_cred_para_fc, rs_ingr.ind_tipo_fc, rs_ingr.ind_ingr_egre, v_cont_auxi, NULL, NULL,
                                p_cod_usua_sid, SYSDATE
                            );
                            
                        END LOOP;
                        
                        FOR rs_egre IN (select cod_cred_para_fc, ind_ingr_egre, ind_tipo_fc 
                                    from vve_cred_para_fc where ind_ingr_egre = 'EF' and ind_tipo_fc = p_indi_tipo_fc) LOOP
                    
                            BEGIN
                                SELECT
                                    lpad(nvl(MAX(cod_cred_soli_ffc), 0) + 1, 10, '0')
                                INTO p_ret_cod_cred_soli_ffc
                                FROM
                                    vve_cred_soli_fact_fc;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                    p_ret_cod_cred_soli_ffc := NULL;
                            END;
                            
                            INSERT INTO vve_cred_soli_fact_fc (
                                COD_CRED_SOLI_FFC, COD_SOLI_CRED, NO_CIA, VAL_MES, VAL_ANO, COD_CRED_PARA_FACT,
                                IND_TIPO_FC, IND_TIPO, VAL_NRO_RUTA, VAL_PARA, VAL_FACT_AJUST,
                                COD_USUA_CREA_REGI, FEC_USUA_CREA_REGI 
                            ) VALUES (
                                SEQ_CRED_SOLI_FACT_FC.NEXTVAL, p_cod_soli_cred, p_no_cia, rs_simu.mes, rs_simu.anio, 
                                rs_egre.cod_cred_para_fc, rs_egre.ind_tipo_fc, rs_egre.ind_ingr_egre, v_cont_auxi, NULL, NULL,
                                p_cod_usua_sid, SYSDATE
                            );
                        END LOOP;
                        
                        FOR rs_resu IN (select cod_cred_para_fc, ind_ingr_egre, ind_tipo_fc 
                                    from vve_cred_para_fc where ind_ingr_egre = 'R' and ind_tipo_fc = 'G') LOOP
                    
                            BEGIN
                                SELECT
                                    lpad(nvl(MAX(cod_cred_soli_ffc), 0) + 1, 10, '0')
                                INTO p_ret_cod_cred_soli_ffc
                                FROM
                                    vve_cred_soli_fact_fc;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                    p_ret_cod_cred_soli_ffc := NULL;
                            END;
                            
                            INSERT INTO vve_cred_soli_fact_fc (
                                COD_CRED_SOLI_FFC, COD_SOLI_CRED, NO_CIA, VAL_MES, VAL_ANO, COD_CRED_PARA_FACT,
                                IND_TIPO_FC, IND_TIPO, VAL_NRO_RUTA, VAL_PARA, VAL_FACT_AJUST,
                                COD_USUA_CREA_REGI, FEC_USUA_CREA_REGI 
                            ) VALUES (
                                SEQ_CRED_SOLI_FACT_FC.NEXTVAL, p_cod_soli_cred, p_no_cia, rs_simu.mes, rs_simu.anio, 
                                rs_resu.cod_cred_para_fc, rs_resu.ind_tipo_fc, rs_resu.ind_ingr_egre, v_cont_auxi, NULL, NULL,
                                p_cod_usua_sid, SYSDATE
                            );
                        END LOOP;
                        
                    END LOOP;
                    
                    FOR rs_fact IN (SELECT EXTRACT(YEAR FROM fec_venc) as anio 
                        FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu GROUP BY EXTRACT(YEAR FROM fec_venc)) LOOP
                    
                        FOR rs_proy IN (SELECT cod_cred_para_fc, ind_ingr_egre, ind_tipo_fc 
                            FROM vve_cred_para_fc WHERE ind_ingr_egre = 'A' AND ind_tipo_fc = 'G') LOOP
                        
                            INSERT INTO vve_cred_soli_fact_fc (
                                COD_CRED_SOLI_FFC, COD_SOLI_CRED, NO_CIA, VAL_MES, VAL_ANO, COD_CRED_PARA_FACT,
                                IND_TIPO_FC, IND_TIPO, VAL_NRO_RUTA, VAL_PARA, VAL_FACT_AJUST,
                                COD_USUA_CREA_REGI, FEC_USUA_CREA_REGI 
                            ) VALUES (
                                SEQ_CRED_SOLI_FACT_FC.NEXTVAL, p_cod_soli_cred, p_no_cia, 0, rs_fact.anio, 
                                rs_proy.cod_cred_para_fc, rs_proy.ind_tipo_fc, rs_proy.ind_ingr_egre, NULL, NULL, NULL,
                                p_cod_usua_sid, SYSDATE
                            );
                    
                        END LOOP;
                
                    END LOOP;
                    
                    v_cont_auxi := v_cont_auxi + 1;
                
                END LOOP;
            
            ELSE
        
                -- SE REGISTRA LOS PARAMETROS DE FACTOR POR MES
                FOR rs_simu IN (select EXTRACT(MONTH FROM fec_venc) as mes, EXTRACT(YEAR FROM fec_venc) as anio 
                        from vve_cred_simu_letr where cod_simu = v_cod_simu order by to_number(cod_nume_letr)) LOOP
                    
                    FOR rs_ingr IN (select cod_cred_para_fc, ind_ingr_egre, ind_tipo_fc 
                                    from vve_cred_para_fc where ind_ingr_egre = 'IF' and ind_tipo_fc = p_indi_tipo_fc) LOOP
                    
                        BEGIN
                            SELECT
                                lpad(nvl(MAX(cod_cred_soli_ffc), 0) + 1, 10, '0')
                            INTO p_ret_cod_cred_soli_ffc
                            FROM
                                vve_cred_soli_fact_fc;
                            EXCEPTION
                                WHEN OTHERS THEN
                                p_ret_cod_cred_soli_ffc := NULL;
                        END;
                
                        INSERT INTO vve_cred_soli_fact_fc (
                            COD_CRED_SOLI_FFC, COD_SOLI_CRED, NO_CIA, VAL_MES, VAL_ANO, COD_CRED_PARA_FACT,
                            IND_TIPO_FC, IND_TIPO, VAL_NRO_RUTA, VAL_PARA, VAL_FACT_AJUST,
                            COD_USUA_CREA_REGI, FEC_USUA_CREA_REGI 
                        ) VALUES (
                            SEQ_CRED_SOLI_FACT_FC.NEXTVAL, p_cod_soli_cred, p_no_cia, rs_simu.mes, rs_simu.anio, 
                            rs_ingr.cod_cred_para_fc, rs_ingr.ind_tipo_fc, rs_ingr.ind_ingr_egre, NULL, NULL, NULL,
                            p_cod_usua_sid, SYSDATE
                        );
                    END LOOP;
                    
                    FOR rs_egre IN (select cod_cred_para_fc, ind_ingr_egre, ind_tipo_fc 
                                    from vve_cred_para_fc where ind_ingr_egre = 'EF' and ind_tipo_fc = p_indi_tipo_fc) LOOP
                    
                        BEGIN
                            SELECT
                                lpad(nvl(MAX(cod_cred_soli_ffc), 0) + 1, 10, '0')
                            INTO p_ret_cod_cred_soli_ffc
                            FROM
                                vve_cred_soli_fact_fc;
                            EXCEPTION
                                WHEN OTHERS THEN
                                p_ret_cod_cred_soli_ffc := NULL;
                        END;
                        
                        INSERT INTO vve_cred_soli_fact_fc (
                            COD_CRED_SOLI_FFC, COD_SOLI_CRED, NO_CIA, VAL_MES, VAL_ANO, COD_CRED_PARA_FACT,
                            IND_TIPO_FC, IND_TIPO, VAL_NRO_RUTA, VAL_PARA, VAL_FACT_AJUST,
                            COD_USUA_CREA_REGI, FEC_USUA_CREA_REGI 
                        ) VALUES (
                            SEQ_CRED_SOLI_FACT_FC.NEXTVAL, p_cod_soli_cred, p_no_cia, rs_simu.mes, rs_simu.anio, 
                            rs_egre.cod_cred_para_fc, rs_egre.ind_tipo_fc, rs_egre.ind_ingr_egre, NULL, NULL, NULL,
                            p_cod_usua_sid, SYSDATE
                        );
                    END LOOP;
                    
                    IF v_cant_resu <= 0 THEN
                    
                        FOR rs_resu IN (select cod_cred_para_fc, ind_ingr_egre, ind_tipo_fc 
                                        from vve_cred_para_fc where ind_ingr_egre = 'R' and ind_tipo_fc = 'G') LOOP
                        
                            BEGIN
                                SELECT
                                    lpad(nvl(MAX(cod_cred_soli_ffc), 0) + 1, 10, '0')
                                INTO p_ret_cod_cred_soli_ffc
                                FROM
                                    vve_cred_soli_fact_fc;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                    p_ret_cod_cred_soli_ffc := NULL;
                            END;
                            
                            INSERT INTO vve_cred_soli_fact_fc (
                                COD_CRED_SOLI_FFC, COD_SOLI_CRED, NO_CIA, VAL_MES, VAL_ANO, COD_CRED_PARA_FACT,
                                IND_TIPO_FC, IND_TIPO, VAL_NRO_RUTA, VAL_PARA, VAL_FACT_AJUST,
                                COD_USUA_CREA_REGI, FEC_USUA_CREA_REGI 
                            ) VALUES (
                                SEQ_CRED_SOLI_FACT_FC.NEXTVAL, p_cod_soli_cred, p_no_cia, rs_simu.mes, rs_simu.anio, 
                                rs_resu.cod_cred_para_fc, rs_resu.ind_tipo_fc, rs_resu.ind_ingr_egre, NULL, NULL, NULL,
                                p_cod_usua_sid, SYSDATE
                            );
                        END LOOP;
                        
                    END IF;
                    
                END LOOP;
                
                
                FOR rs_fact IN (SELECT EXTRACT(YEAR FROM fec_venc) as anio 
                    FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu GROUP BY EXTRACT(YEAR FROM fec_venc)) LOOP
                    
                    FOR rs_proy IN (SELECT cod_cred_para_fc, ind_ingr_egre, ind_tipo_fc 
                        FROM vve_cred_para_fc WHERE ind_ingr_egre = 'A' AND ind_tipo_fc = 'G') LOOP
                        
                        INSERT INTO vve_cred_soli_fact_fc (
                                COD_CRED_SOLI_FFC, COD_SOLI_CRED, NO_CIA, VAL_MES, VAL_ANO, COD_CRED_PARA_FACT,
                                IND_TIPO_FC, IND_TIPO, VAL_NRO_RUTA, VAL_PARA, VAL_FACT_AJUST,
                                COD_USUA_CREA_REGI, FEC_USUA_CREA_REGI 
                            ) VALUES (
                                SEQ_CRED_SOLI_FACT_FC.NEXTVAL, p_cod_soli_cred, p_no_cia, 0, rs_fact.anio, 
                                rs_proy.cod_cred_para_fc, rs_proy.ind_tipo_fc, rs_proy.ind_ingr_egre, NULL, NULL, NULL,
                                p_cod_usua_sid, SYSDATE
                            );
                    
                    END LOOP;
                
                END LOOP;
                
                
            END IF;
            
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                              'SP_INSE_FACT_MES',
                              p_cod_usua_sid,
                              'Se registro los parametros FACT según el simulador X',
                              NULL,
                              NULL);
                              
            -- SE INSERTA LA CABECERA DE RANGOS 
            FOR f IN 1 .. p_list_fact_mes.COUNT LOOP
            
                IF (p_list_fact_mes(f).IND_INGR_EGRE = 'INGR') THEN
                    
                    INSERT INTO vve_cred_soli_fact_ajust (
                    COD_CRED_SOLI_FACT_AJUST, COD_SOLI_CRED, NO_CIA, IND_TIPO_FC, IND_TIPO, FEC_INI, FEC_FIN, 
                    VAL_FACT_AJUST, NRO_ORDE
                    ) VALUES (
                    SEQ_CRED_SOLI_FACT_AJUST.NEXTVAL, p_cod_soli_cred, p_no_cia, p_indi_tipo_fc, 'IF', TO_DATE(p_list_fact_mes(f).FEC_MES_INI_RANG, 'DD/MM/YYYY'),
                    TO_DATE(p_list_fact_mes(f).FEC_MES_FIN_RANG, 'DD/MM/YYYY'), p_list_fact_mes(f).VAL_FACT, p_list_fact_mes(f).NRO_ORDE 
                    );
                    
                ELSE
                    INSERT INTO vve_cred_soli_fact_ajust (
                    COD_CRED_SOLI_FACT_AJUST, COD_SOLI_CRED, NO_CIA, IND_TIPO_FC, IND_TIPO, FEC_INI, FEC_FIN, 
                    VAL_FACT_AJUST, NRO_ORDE
                    ) VALUES (
                    SEQ_CRED_SOLI_FACT_AJUST.NEXTVAL, p_cod_soli_cred, p_no_cia, p_indi_tipo_fc, 'EF', TO_DATE(p_list_fact_mes(f).FEC_MES_INI_RANG, 'DD/MM/YYYY'),
                    TO_DATE(p_list_fact_mes(f).FEC_MES_FIN_RANG, 'DD/MM/YYYY'), p_list_fact_mes(f).VAL_FACT, p_list_fact_mes(f).NRO_ORDE 
                    );
                END IF;
    
            END LOOP;
            
            -- SE ACTUALIZA LOS VALORES FACT AJUSTABLES
            IF p_ind_fac_fijo_vari_ingr = 'FIF' THEN
            
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                              'SP_INSE_FACT_MES',
                              p_cod_usua_sid,
                              'Ingresos Fijos X = ' || p_ind_fac_fijo_vari_ingr,
                              NULL,
                              NULL);
            
                UPDATE vve_cred_soli_fact_fc SET VAL_FACT_AJUST = p_fac_cons_ingr
                WHERE ind_tipo_fc = p_indi_tipo_fc AND ind_tipo = 'IF'
                AND cod_soli_cred = p_cod_soli_cred;
                   
            ELSE 
            
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                              'SP_INSE_FACT_MES',
                              p_cod_usua_sid,
                              'Ingresos Variables X = ' || p_ind_fac_fijo_vari_ingr,
                              NULL,
                              NULL);
            
                FOR i IN 1 .. p_list_fact_mes.COUNT LOOP
                
                    IF (p_list_fact_mes(i).IND_INGR_EGRE = 'INGR') THEN
                    
                        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_FACT_MES',
                                          p_cod_usua_sid,
                                          TO_DATE(p_list_fact_mes(i).FEC_MES_INI_RANG, 'DD/MM/YYYY') || ' X ' || 
                                          TO_DATE(p_list_fact_mes(i).FEC_MES_FIN_RANG, 'DD/MM/YYYY') || ' X ',
                                          NULL,
                                          NULL);
                    
                       SELECT EXTRACT(MONTH FROM TO_DATE(p_list_fact_mes(i).FEC_MES_INI_RANG, 'DD/MM/YYYY')) 
                       INTO v_mes_ini_ingr FROM dual;
                       
                       SELECT EXTRACT(YEAR FROM TO_DATE(p_list_fact_mes(i).FEC_MES_INI_RANG, 'DD/MM/YYYY')) 
                       INTO v_anio_ini_ingr FROM dual;
                       
                       SELECT EXTRACT(MONTH FROM TO_DATE(p_list_fact_mes(i).FEC_MES_FIN_RANG, 'DD/MM/YYYY')) 
                       INTO v_mes_fin_ingr FROM dual;
                       
                       SELECT EXTRACT(YEAR FROM TO_DATE(p_list_fact_mes(i).FEC_MES_FIN_RANG, 'DD/MM/YYYY')) 
                       INTO v_anio_fin_ingr FROM dual;
                    
                        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_FACT_MES',
                                          p_cod_usua_sid,
                                          v_mes_ini_ingr || ' X ' || v_anio_ini_ingr || ' X ' || v_mes_fin_ingr 
                                          || ' X ' || v_anio_fin_ingr || ' X ' || p_list_fact_mes(i).VAL_FACT,
                                          NULL,
                                          NULL);
                                          
                        UPDATE vve_cred_soli_fact_fc SET VAL_FACT_AJUST = p_list_fact_mes(i).VAL_FACT 
                        WHERE ind_tipo_fc = p_indi_tipo_fc AND ind_tipo = 'IF' 
                        -- AND (val_mes BETWEEN v_mes_ini_ingr AND v_mes_fin_ingr) 
                        -- AND (val_ano BETWEEN v_anio_ini_ingr AND v_anio_fin_ingr
                        AND To_DATE('01' || '/' || val_mes || '/' || val_ano, 'DD/MM/YYYY') 
                        BETWEEN TO_DATE('01' || '/' || v_mes_ini_ingr || '/' || v_anio_ini_ingr, 'DD/MM/YYYY') 
                        AND TO_DATE('01' || '/' || v_mes_fin_ingr || '/' || v_anio_fin_ingr, 'DD/MM/YYYY')  
                        AND cod_soli_cred = p_cod_soli_cred;
                        
                    END IF;
        
                END LOOP;
                
            END IF;
            
            
            IF p_ind_fac_fijo_vari_egre = 'FEF' THEN
            
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                              'SP_INSE_FACT_MES',
                              p_cod_usua_sid,
                              'Egresos Fijos X = ' || p_ind_fac_fijo_vari_egre,
                              NULL,
                              NULL);
            
                UPDATE vve_cred_soli_fact_fc SET VAL_FACT_AJUST = p_fac_cons_egre
                WHERE ind_tipo_fc = p_indi_tipo_fc AND ind_tipo = 'EF'
                AND cod_soli_cred = p_cod_soli_cred;
                   
            ELSE 
                
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                              'SP_INSE_FACT_MES',
                              p_cod_usua_sid,
                              'Egresos Variables X = ' || p_ind_fac_fijo_vari_egre,
                              NULL,
                              NULL);
            
                FOR i IN 1 .. p_list_fact_mes.COUNT LOOP
                
                    IF (p_list_fact_mes(i).IND_INGR_EGRE = 'EGRE') THEN
                    
                       SELECT EXTRACT(MONTH FROM TO_DATE(p_list_fact_mes(i).FEC_MES_INI_RANG, 'DD/MM/YYYY')) 
                       INTO v_mes_ini_egre FROM dual;
                       
                       SELECT EXTRACT(YEAR FROM TO_DATE(p_list_fact_mes(i).FEC_MES_INI_RANG, 'DD/MM/YYYY')) 
                       INTO v_anio_ini_egre FROM dual;
                       
                       SELECT EXTRACT(MONTH FROM TO_DATE(p_list_fact_mes(i).FEC_MES_FIN_RANG, 'DD/MM/YYYY')) 
                       INTO v_mes_fin_egre FROM dual;
                       
                       SELECT EXTRACT(YEAR FROM TO_DATE(p_list_fact_mes(i).FEC_MES_FIN_RANG, 'DD/MM/YYYY')) 
                       INTO v_anio_fin_egre FROM dual;
                    
                        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_INSE_FACT_MES',
                                          p_cod_usua_sid,
                                          v_mes_ini_egre || ' X ' || v_anio_ini_egre || ' X ' || v_mes_fin_egre 
                                          || ' X ' || v_anio_fin_egre || ' X ' || p_list_fact_mes(i).VAL_FACT,
                                          NULL,
                                          NULL);
                                          
                        UPDATE vve_cred_soli_fact_fc SET VAL_FACT_AJUST = p_list_fact_mes(i).VAL_FACT 
                        WHERE ind_tipo_fc = p_indi_tipo_fc AND ind_tipo = 'EF' 
                        --AND (val_mes BETWEEN v_mes_ini_egre AND v_mes_fin_egre) 
                        --AND (val_ano BETWEEN v_anio_ini_egre AND v_anio_fin_egre)
                        AND To_DATE('01' || '/' || val_mes || '/' || val_ano, 'DD/MM/YYYY') 
                        BETWEEN TO_DATE('01' || '/' || v_mes_ini_egre || '/' || v_anio_ini_egre, 'DD/MM/YYYY') 
                        AND TO_DATE('01' || '/' || v_mes_fin_egre || '/' || v_anio_fin_egre, 'DD/MM/YYYY')  
                        AND cod_soli_cred = p_cod_soli_cred;
                        
                    END IF;
        
                END LOOP;
                
            END IF;
        
        END IF;
        
        p_ret_esta := 1;
        p_ret_mens := 'Se realizó el proceso satisfactoriamente';
    
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_FACT_MES', p_cod_usua_sid, 'Error al insertar factor por mes '||p_cod_soli_cred
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := p_ret_mens||'SP_INSE_FACT_MES:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_INSE_FACT_MES', p_cod_usua_sid, 'Error al insertar factor por mes'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
            
    END sp_inse_fact_mes;
    
    
    PROCEDURE sp_calc_proy_cami 
    (      
         p_cod_soli_cred                IN      vve_cred_soli.cod_soli_cred%TYPE,
         p_indi_tipo_fc                 IN      VARCHAR2,
         p_cod_usua_sid                 IN      sistemas.usuarios.co_usuario%TYPE,
         p_ret_cursor                   OUT     SYS_REFCURSOR,
         p_ret_colu_ano                 OUT     SYS_REFCURSOR,
         p_ret_esta                     OUT     NUMBER,
         p_ret_mens                     OUT     VARCHAR2
    ) AS 
    
        -- CAMIONES
         ve_error EXCEPTION;
         v_val_para_viaj_mes NUMERIC(11,2);
         v_val_para_otro_ingr NUMERIC(11,2);
         v_val_para_tota_ingr NUMERIC(11,2);
         
         v_val_para_pago_pers NUMERIC(11,2);
         v_val_para_comb_mes NUMERIC(11,2);
         v_val_para_mant_gral NUMERIC(11,2);
         v_val_para_leas_mutu NUMERIC(11,2);
         v_val_para_otro_gast NUMERIC(11,2);
         
         v_val_para_pago_pers_calc NUMERIC(11,2); 
         v_val_para_comb_mes_calc NUMERIC(11,2);
         v_val_para_mant_gral_calc NUMERIC(11,2);
         v_val_para_leas_mutu_calc NUMERIC(11,2);
         v_val_para_otro_gast_calc NUMERIC(11,2);
         
         v_val_tota_ingr_mes_fact NUMERIC(11,2);
         v_val_tota_egre_mes_fact NUMERIC(11,2);
         
         v_cod_simu NUMBER;
         v_val_caja_disp_mes NUMERIC(11,2);
         v_val_mont_cuot_mes NUMERIC(11,2);
         v_val_caja_libr_mes NUMERIC(11,2);
         
         v_val_caja_disp_mes_calc NUMERIC(11,2);
         v_val_mont_cuot_mes_calc NUMERIC(11,2);
         
         v_val_sum_caja_disp NUMERIC(11,2);
         v_val_sum_cuot_fina NUMERIC(11,2);

         v_cont_arr_cant NUMBER;
         v_contador_sum NUMBER;
         v_list_cobe_fluj_caja VVE_TYTA_LIST_COBE_FLUJ_CAJA;
         
         ln_conc_anos_cabe  VARCHAR2(6000);
         ln_pivot_sql VARCHAR2(4000);
         
         -- INTERPROVINCIAL
         v_val_para_tot_ingr_int NUMERIC(11,2);
         v_val_para_comb_viaj_int NUMERIC(11,2);
         v_val_para_suel_chof_int NUMERIC(11,2);
         v_val_para_suel_terr_int NUMERIC(11,2);
         v_val_para_peaj_viaj_int NUMERIC(11,2);
         v_val_para_otro_gast_int NUMERIC(11,2);
         v_val_para_mant_gral_int NUMERIC(11,2);
         v_val_para_cuot_leas_int NUMERIC(11,2);
         v_val_para_porc_otro_gast_int NUMERIC(11,2);
         
         v_val_tota_ingr_mes_fact_int NUMERIC(11,2);
         v_val_tota_egre_mes_fact_int NUMERIC(11,2);
         v_val_caja_disp_mes_int NUMERIC(11,2);
         v_val_mont_cuot_mes_int NUMERIC(11,2);
         v_val_caja_disp_mes_calc_int NUMERIC(11,2);
         v_val_mont_cuot_mes_calc_int NUMERIC(11,2);
         v_val_caja_libr_mes_int NUMERIC(11,2);
         
         -- URBANO
         v_val_para_tot_ingr_urb NUMERIC(11,2);
         v_val_para_tot_rut_mes_urb NUMERIC(11,2);
         v_val_para_oing_grigo_mes_urb NUMERIC(11,2);
         v_val_para_oing_coti_mes_urb NUMERIC(11,2); 
         v_val_para_oing_adm_mes_urb NUMERIC(11,2); 
         v_val_para_oing_bol_mes_urb NUMERIC(11,2);
         v_val_para_oing_desp_mes_urb NUMERIC(11,2);
         v_val_para_oing_unif_mes_urb NUMERIC(11,2); 
         v_val_para_oing_gps_mes_urb NUMERIC(11,2);
         v_val_para_oing_limp_mes_urb NUMERIC(11,2); 
         v_val_para_oing_relo_mes_urb NUMERIC(11,2);
        
         
         v_val_para_comb_rut_mes_urb NUMERIC(11,2);
         v_val_para_rend_km_gal_mes_urb NUMERIC(11,2);
         v_val_para_kilo_rut_mes_urb NUMERIC(11,2);
         v_val_para_prec_com_mes_urb NUMERIC(11,2);
         v_val_para_cons_gal_mes_urb NUMERIC(11,2);
         v_val_para_mant_prop_mes_urb NUMERIC(11,2);
         v_val_para_km_prop_mes_urb NUMERIC(11,2); 
         v_val_para_mant_km_mes_urb NUMERIC(11,2);
         v_val_para_gast_pers_mes_urb NUMERIC(11,2);
         v_val_para_chof_rut_mes_urb NUMERIC(11,2);
         v_val_para_cob_rut_mes_urb NUMERIC(11,2);
         v_val_para_viat_rut_mes_urb NUMERIC(11,2);
         v_val_para_peaj_rut_mes_urb NUMERIC(11,2);
         v_val_para_cost_reca_mes_urb NUMERIC(11,2);
         v_val_para_gps_rut_mes_urb NUMERIC(11,2);
         v_val_para_soat_rut_mes_urb NUMERIC(11,2); 
         v_val_para_coti_rut_mes_urb NUMERIC(11,2); 
         v_val_para_otro_gas_mes_urb NUMERIC(11,2);
         v_val_para_cuo_leas_mes_urb NUMERIC(11,2);
         v_val_para_igv_comp_mes_urb NUMERIC(11,2);
         
         v_val_tota_ingr_mes_fact_urb NUMERIC(11,2);
         v_val_tota_egre_mes_fact_urb NUMERIC(11,2);
         v_val_caja_disp_mes_urb NUMERIC(11,2);
         v_val_mont_cuot_mes_urb NUMERIC(11,2);
         v_val_caja_disp_mes_calc_urb NUMERIC(11,2);
         v_val_mont_cuot_mes_calc_urb NUMERIC(11,2);
         v_val_caja_libr_mes_urb NUMERIC(11,2);
         
         v_cant_reg_vali NUMBER;
         
         v_tipo_cambio NUMERIC(5,3);
         v_cod_mone_soli VARCHAR2(1);
         
         v_caja_disp_proy NUMERIC(11,2);
         v_cuota_fina_proy NUMERIC(11,2);
         
    BEGIN
    
        BEGIN
            SELECT cod_simu INTO v_cod_simu 
            FROM vve_cred_simu 
            WHERE cod_soli_cred = p_cod_soli_cred AND ind_inactivo = 'N';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            v_cod_simu := NULL;
            p_ret_esta := -1;
            p_ret_mens := 'La solicitud no tiene simulador';
            RETURN;
        END;
        
        SELECT COUNT(*) INTO v_cant_reg_vali FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred;
        SELECT cod_mone_soli INTO v_cod_mone_soli FROM vve_cred_soli WHERE cod_soli_cred = p_cod_soli_cred;
        
        IF v_cod_mone_soli = '2' THEN
            BEGIN
                SELECT tipo_cambio INTO v_tipo_cambio 
                FROM arcgtc 
                WHERE clase_cambio = '02' AND fecha = TRUNC(SYSDATE);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_tipo_cambio := 3.662;
            END;
        ELSE
            v_tipo_cambio := 1;
        END IF;
        
        IF v_cant_reg_vali > 0 THEN
        
            IF p_indi_tipo_fc = 'C' THEN
        
                FOR rs_ingr IN (SELECT cod_cred_para_fact, val_mes, val_ano, val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = p_cod_soli_cred  
                    AND ind_tipo_fc = 'C' AND ind_tipo = 'IF' ORDER BY val_ano, val_mes) LOOP        
                    
                    IF rs_ingr.cod_cred_para_fact = 'VAL_ING_MES_CAM_FACT' THEN                
                        
                        v_val_para_viaj_mes := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PROM_VIAJ_MES', 'C');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_viaj_mes),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_ING_MES_CAM_FACT'
                        AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano;             
                    END IF;
                    
                    IF rs_ingr.cod_cred_para_fact = 'VAL_OTRO_INGR_CAM_MES_FACT' THEN
                        
                        v_val_para_otro_ingr := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OTRO_INGR_CAM', 'C');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_otro_ingr),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OTRO_INGR_CAM_MES_FACT'
                        AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano;
                        
                    END IF;
                    
                    IF rs_ingr.cod_cred_para_fact = 'VAL_TOT_INGR_MES_CAM_FACT' THEN  
                        
                        v_val_para_tota_ingr := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_TOT_INGR_MES_CAM', 'C');
                    
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_tota_ingr),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_TOT_INGR_MES_CAM_FACT'
                        AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano;
                        
                    END IF;
                    
                END LOOP;
                              
                dbms_output.put_line('PASO LOOP INGRESO');
            
                FOR rs_egre IN (SELECT cod_cred_para_fact, val_mes, val_ano, val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = p_cod_soli_cred 
                    AND ind_tipo_fc = 'C' AND ind_tipo = 'EF' ORDER BY to_number(val_ano), to_number(val_mes)) LOOP
                    
                    v_val_para_pago_pers := 0; v_val_para_comb_mes := 0; v_val_para_mant_gral := 0; 
                    v_val_para_leas_mutu := 0; v_val_para_otro_gast := 0;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_PAGO_PERS_MES_FACT' THEN
                        
                        v_val_para_pago_pers := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PAGO_PERS_MES', 'C');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_pago_pers),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_PAGO_PERS_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano
                        AND ind_tipo_fc = 'C';
                        
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_COMB_MES_FACT' THEN
                        
                        v_val_para_comb_mes := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COMB_MES', 'C');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_comb_mes),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_COMB_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano
                        AND ind_tipo_fc = 'C';
                        
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_MANT_GRAL_MES_FACT' THEN
                        
                        v_val_para_mant_gral := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_MANT_GRAL_MES', 'C');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_mant_gral),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_MANT_GRAL_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano
                        AND ind_tipo_fc = 'C';
                        
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_LEASI_MUTUO_MES_FACT' THEN
                        
                        v_val_para_leas_mutu := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_LEASI_MUTUO_MES', 'C');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_leas_mutu),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_LEASI_MUTUO_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano
                        AND ind_tipo_fc = 'C';
                        
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_OTRO_GAST_CAM_MES_FACT' THEN
                        
                        v_val_para_otro_gast := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OTRO_GAST_CAM_MES', 'C');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_otro_gast),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OTRO_GAST_CAM_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano
                        AND ind_tipo_fc = 'C';
                        
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_TOT_EGRE_MES_CAM_FACT' THEN
                        
                        v_val_para_pago_pers_calc := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_PAGO_PERS_MES_FACT', rs_egre.val_mes, 
                        rs_egre.val_ano, 'C');
                        
                        v_val_para_comb_mes_calc := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_COMB_MES_FACT', rs_egre.val_mes, 
                        rs_egre.val_ano, 'C');
                        
                        v_val_para_mant_gral_calc := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_MANT_GRAL_MES_FACT', rs_egre.val_mes, 
                        rs_egre.val_ano, 'C');
                        
                        v_val_para_leas_mutu_calc := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_LEASI_MUTUO_MES_FACT', rs_egre.val_mes, 
                        rs_egre.val_ano, 'C');
                        
                        v_val_para_otro_gast_calc := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_OTRO_GAST_CAM_MES_FACT', rs_egre.val_mes, 
                        rs_egre.val_ano, 'C');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((v_val_para_pago_pers_calc + 
                        v_val_para_comb_mes_calc + v_val_para_mant_gral_calc + v_val_para_leas_mutu_calc + 
                        v_val_para_otro_gast_calc),2) 
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_TOT_EGRE_MES_CAM_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano
                        AND ind_tipo_fc = 'C';
                    END IF;
        
                END LOOP;
                
                dbms_output.put_line('PASO LOOP EGRESO');
                
                FOR rs_resu IN (SELECT cod_cred_para_fact, val_mes, val_ano FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = p_cod_soli_cred  
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'R' ORDER BY val_ano, val_mes) LOOP
                    
                    v_val_tota_ingr_mes_fact := 0; v_val_tota_egre_mes_fact := 0; v_val_caja_disp_mes := 0;
                    v_val_mont_cuot_mes := 0; v_val_caja_disp_mes_calc := 0; v_val_mont_cuot_mes_calc := 0; 
                    v_val_caja_libr_mes := 0;
                    
                    IF rs_resu.cod_cred_para_fact = 'VAL_CAJA_DISP_MES' THEN 
                        
                        v_val_tota_ingr_mes_fact := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_INGR_MES_CAM_FACT', rs_resu.val_mes, 
                        rs_resu.val_ano, 'C');
                        
                        -- dbms_output.put_line('v_val_tota_ingr_mes_fact');
                        -- dbms_output.put_line(v_val_tota_ingr_mes_fact);
                        
                        v_val_tota_egre_mes_fact := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_EGRE_MES_CAM_FACT', rs_resu.val_mes, 
                        rs_resu.val_ano, 'C');
                        
                        -- dbms_output.put_line('v_val_tota_egre_mes_fact');
                        -- dbms_output.put_line(v_val_tota_egre_mes_fact);
                        
                        v_val_caja_disp_mes := (v_val_tota_ingr_mes_fact - v_val_tota_egre_mes_fact);
                        
                        -- dbms_output.put_line('v_val_caja_disp_mes');
                        -- dbms_output.put_line(v_val_caja_disp_mes);
                        
                        UPDATE vve_cred_soli_fact_fc 
                        SET val_para = v_val_caja_disp_mes
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CAJA_DISP_MES'
                        AND val_mes = rs_resu.val_mes AND  val_ano = rs_resu.val_ano
                        AND ind_tipo_fc = 'G';
                        
                    END IF;
                    
                    IF rs_resu.cod_cred_para_fact = 'VAL_CUOT_FINA_MES' THEN
                        
                        BEGIN
                            SELECT NVL(val_mont_cuo, 0) INTO v_val_mont_cuot_mes
                            FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu 
                            AND EXTRACT(MONTH FROM fec_venc) = rs_resu.val_mes 
                            AND EXTRACT(YEAR FROM fec_venc) = rs_resu.val_ano;
                        EXCEPTION
                            WHEN OTHERS THEN
                            v_val_mont_cuot_mes := 0;
                            p_ret_esta := 0;
                            p_ret_mens := 'No se pudo generar la Proyeccion, hay errores en el Cronograma.';
                            RETURN;
                        END;
                        
                        -- dbms_output.put_line('v_val_mont_cuot_mes');
                        -- dbms_output.put_line(v_val_mont_cuot_mes);
                        
                        UPDATE vve_cred_soli_fact_fc 
                        SET val_para = (v_val_mont_cuot_mes * v_tipo_cambio)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CUOT_FINA_MES'
                        AND val_mes = rs_resu.val_mes AND  val_ano = rs_resu.val_ano
                        AND ind_tipo_fc = 'G';
                    
                    END IF;
                    
                    IF rs_resu.cod_cred_para_fact = 'VAL_CAJA_LIBR_MES' THEN
                    
                        v_val_tota_ingr_mes_fact := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_INGR_MES_CAM_FACT', rs_resu.val_mes, 
                        rs_resu.val_ano, 'C');
                        
                        v_val_tota_egre_mes_fact := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_EGRE_MES_CAM_FACT', rs_resu.val_mes, 
                        rs_resu.val_ano, 'C');
                        
                        v_val_caja_disp_mes_calc := (v_val_tota_ingr_mes_fact - v_val_tota_egre_mes_fact);
                        
                        SELECT NVL(val_mont_cuo, 0) INTO v_val_mont_cuot_mes_calc
                        FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu 
                        AND EXTRACT(MONTH FROM fec_venc) = rs_resu.val_mes 
                        AND EXTRACT(YEAR FROM fec_venc) = rs_resu.val_ano;
                        
                        -- dbms_output.put_line('v_val_caja_disp_mes_calc');
                        -- dbms_output.put_line(v_val_caja_disp_mes_calc);
                        
                        -- dbms_output.put_line('v_val_mont_cuot_mes_calc');
                        -- dbms_output.put_line(v_val_mont_cuot_mes_calc);
                        
                        v_val_caja_libr_mes := v_val_caja_disp_mes_calc - (v_val_mont_cuot_mes_calc * v_tipo_cambio);
                        
                        -- dbms_output.put_line('v_val_caja_libr_mes');
                        -- dbms_output.put_line(v_val_caja_libr_mes);
                        
                        UPDATE vve_cred_soli_fact_fc 
                        SET val_para = v_val_caja_libr_mes
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CAJA_LIBR_MES'
                        AND val_mes = rs_resu.val_mes AND  val_ano = rs_resu.val_ano
                        AND ind_tipo_fc = 'G';
                    
                    END IF;
                 
                END LOOP;
                
                dbms_output.put_line('PASO LOOP RESUMEN');
                
                -- PROYECTADO
                FOR rs_proy IN (SELECT val_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'A') LOOP
                    
                    v_caja_disp_proy := 0; v_cuota_fina_proy := 0;
                    
                    select sum(val_para) INTO v_caja_disp_proy from vve_cred_soli_fact_fc where cod_soli_cred = p_cod_soli_cred
                    and cod_cred_para_fact = 'VAL_CAJA_DISP_MES' and val_ano = rs_proy.val_ano;
                    
                    select sum(val_para) INTO v_cuota_fina_proy from vve_cred_soli_fact_fc where cod_soli_cred = p_cod_soli_cred
                    and cod_cred_para_fact = 'VAL_CUOT_FINA_MES' and val_ano = rs_proy.val_ano;
                    
                    UPDATE vve_cred_soli_fact_fc 
                    SET val_para = (v_caja_disp_proy / v_cuota_fina_proy)
                    WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_COBE_FCJA_ANUAL'
                    AND val_ano = rs_proy.val_ano
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'A';
                    
                END LOOP;
                
                v_cont_arr_cant := 0;
                ln_conc_anos_cabe := '';
                
                FOR rs_cobe IN (SELECT val_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'R' GROUP BY val_ano ORDER BY val_ano) LOOP
                    
                    v_cont_arr_cant := v_cont_arr_cant + 1;    
                    
                    IF (v_cont_arr_cant = 1) THEN
                        dbms_output.put_line('No tiene datos');
                        ln_conc_anos_cabe := rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant;
                        dbms_output.put_line('Primera concatenacion ' || ln_conc_anos_cabe);
                    ELSE
                        ln_conc_anos_cabe := ln_conc_anos_cabe || ',' || rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant;
                        dbms_output.put_line('Siguiente concatenacion ' || ln_conc_anos_cabe);
                    END IF;
                    
                END LOOP;
                
                dbms_output.put_line(ln_conc_anos_cabe);
                
                OPEN p_ret_colu_ano FOR
                    SELECT val_ano AS num_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                        AND ind_tipo_fc = 'G' AND ind_tipo = 'R' GROUP BY val_ano ORDER BY val_ano;
            
                ln_pivot_sql := 'SELECT * FROM
                    (
                        SELECT TO_NUMBER(TO_CHAR(SUM(x.val_sum_caja_disp) / SUM(x.val_sum_cuot_fina),''999999999999D99'')) num_ano, x.val_ano
                        FROM (
                           SELECT NVL(SUM(val_para), 0) val_sum_caja_disp, 0 val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                           GROUP BY val_ano
                           UNION ALL
                           SELECT 0 val_sum_caja_disp, NVL(SUM(val_para), 0) val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CUOT_FINA_MES''
                           GROUP BY val_ano
                        ) x
                        GROUP BY x.val_ano
                    )
                    PIVOT
                    (
                    MAX(num_ano)
                    FOR val_ano IN (' || ln_conc_anos_cabe || ')
                    )';
                
                
                OPEN p_ret_cursor FOR ln_pivot_sql;
                  
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_CALC_PROY_CAMI',
                                          p_cod_usua_sid,
                                          ln_pivot_sql,
                                          NULL,
                                          NULL);
                
            END IF;
            
            IF p_indi_tipo_fc = 'I' THEN
            
                dbms_output.put_line('Entro en Interprovincial');
                
                FOR rs_ingr IN (SELECT cod_cred_para_fact, val_mes, val_ano, val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = p_cod_soli_cred  
                    AND ind_tipo_fc = 'I' AND ind_tipo = 'IF' ORDER BY val_ano, val_mes) LOOP 
                    
                    v_val_para_tot_ingr_int := 0;
                    
                    IF rs_ingr.cod_cred_para_fact = 'VAL_TOT_INGR_MES_INT_FACT' THEN                
                        
                        v_val_para_tot_ingr_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_TOT_INGR_MES_INT', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_tot_ingr_int),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_TOT_INGR_MES_INT_FACT'
                        AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano;             
                    END IF;
                    
                END LOOP;
                
                
                FOR rs_egre IN (SELECT cod_cred_para_fact, val_mes, val_ano, val_fact_ajust FROM vve_cred_soli_fact_fc 
                                WHERE cod_soli_cred = p_cod_soli_cred 
                                AND ind_tipo_fc = 'I' AND ind_tipo = 'EF' ORDER BY val_ano, val_mes) LOOP
                                
                    v_val_para_comb_viaj_int := 0; v_val_para_suel_chof_int := 0; v_val_para_suel_terr_int := 0;
                    v_val_para_peaj_viaj_int := 0; v_val_para_otro_gast_int := 0; v_val_para_mant_gral_int := 0;
                    v_val_para_cuot_leas_int := 0; v_val_para_porc_otro_gast_int := 0;
                            
                            
                    IF rs_egre.cod_cred_para_fact = 'VAL_TOT_EGRE_MES_INT_FACT' THEN      
                        
                        v_val_para_comb_viaj_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COMB_VIAJ_MES', 'I');
                        v_val_para_suel_chof_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_SUEL_CHOF_VIAJ_MES', 'I');
                        v_val_para_suel_terr_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_SUEL_TERR_VIAJ_MES', 'I');
                        v_val_para_peaj_viaj_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PEAJE_VIAJ_MES', 'I');
                        v_val_para_otro_gast_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OTROS_GAST_VIAJ_MES', 'I');
                        v_val_para_mant_gral_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_MANT_GRAL_MES', 'I');
                        v_val_para_cuot_leas_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_CUOT_LEAS', 'I');
                        v_val_para_porc_otro_gast_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PORC_OTRO_GAST_INT', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = 
                        round(((v_val_para_comb_viaj_int + v_val_para_suel_chof_int + v_val_para_suel_terr_int + v_val_para_peaj_viaj_int + 
                        v_val_para_otro_gast_int + v_val_para_mant_gral_int + v_val_para_cuot_leas_int + v_val_para_porc_otro_gast_int)
                        * rs_egre.val_fact_ajust),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_TOT_EGRE_MES_INT_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano;             
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_COMB_VIAJ_MES_FACT' THEN                
                        
                        v_val_para_comb_viaj_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COMB_VIAJ_MES', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_comb_viaj_int),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_COMB_VIAJ_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano;             
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_SUEL_CHOF_VIAJ_MES_FACT' THEN                
                        
                        v_val_para_suel_chof_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_SUEL_CHOF_VIAJ_MES', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_suel_chof_int),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_SUEL_CHOF_VIAJ_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano;             
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_SUEL_TERR_VIAJ_MES_FACT' THEN                
                        
                        v_val_para_suel_terr_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_SUEL_TERR_VIAJ_MES', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_suel_terr_int),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_SUEL_TERR_VIAJ_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano;             
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_PEAJE_VIAJ_MES_FACT' THEN                
                        
                        v_val_para_peaj_viaj_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PEAJE_VIAJ_MES', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_peaj_viaj_int),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_PEAJE_VIAJ_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano;             
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_OTROS_GAST_VIAJ_MES_FACT' THEN                
                        
                        v_val_para_otro_gast_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OTROS_GAST_VIAJ_MES', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_otro_gast_int),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OTROS_GAST_VIAJ_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano;             
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_MANT_GRAL_VEH_MES_FACT' THEN                
                        
                        v_val_para_mant_gral_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_MANT_GRAL_MES', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_mant_gral_int),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_MANT_GRAL_VEH_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano;             
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_CUOT_LEAS_MES_FACT' THEN                
                        
                        v_val_para_cuot_leas_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_CUOT_LEAS', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_cuot_leas_int),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CUOT_LEAS_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano;             
                    END IF;
                    
                    IF rs_egre.cod_cred_para_fact = 'VAL_OTRO_GAST_INT_MES_FACT' THEN                
                        
                        v_val_para_porc_otro_gast_int := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PORC_OTRO_GAST_INT', 'I');
                        
                        UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_porc_otro_gast_int),2)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OTRO_GAST_INT_MES_FACT'
                        AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano;             
                    END IF;
                    
                
                END LOOP;
                
                
                FOR rs_resu IN (SELECT cod_cred_para_fact, val_mes, val_ano FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = p_cod_soli_cred  
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'R' ORDER BY val_ano, val_mes) LOOP
                    
                    v_val_tota_ingr_mes_fact_int := 0; v_val_tota_egre_mes_fact_int := 0; v_val_caja_disp_mes_int := 0;
                    v_val_mont_cuot_mes_int := 0; v_val_caja_disp_mes_calc_int := 0; v_val_mont_cuot_mes_calc_int := 0; 
                    v_val_caja_libr_mes_int := 0;
                    
                    IF rs_resu.cod_cred_para_fact = 'VAL_CAJA_DISP_MES' THEN 
    
                        v_val_tota_ingr_mes_fact_int := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_INGR_MES_INT_FACT', rs_resu.val_mes, 
                        rs_resu.val_ano, 'I');
                        
                        v_val_tota_egre_mes_fact_int := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_EGRE_MES_INT_FACT', rs_resu.val_mes, 
                        rs_resu.val_ano, 'I');
                        
                        v_val_caja_disp_mes_int := (v_val_tota_ingr_mes_fact_int - v_val_tota_egre_mes_fact_int);
                        
                        UPDATE vve_cred_soli_fact_fc 
                        SET val_para = v_val_caja_disp_mes_int
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CAJA_DISP_MES'
                        AND val_mes = rs_resu.val_mes AND  val_ano = rs_resu.val_ano
                        AND ind_tipo_fc = 'G';
                        
                    END IF;
                    
                    IF rs_resu.cod_cred_para_fact = 'VAL_CUOT_FINA_MES' THEN
                        
                        BEGIN
                            SELECT NVL(val_mont_cuo, 0) INTO v_val_mont_cuot_mes_int
                            FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu 
                            AND EXTRACT(MONTH FROM fec_venc) = rs_resu.val_mes 
                            AND EXTRACT(YEAR FROM fec_venc) = rs_resu.val_ano;
                        EXCEPTION
                            WHEN OTHERS THEN
                            v_val_mont_cuot_mes_int := 0;
                            p_ret_esta := 0;
                            p_ret_mens := 'No se pudo generar la Proyeccion, hay errores en el Cronograma.';
                            RETURN;
                        END;
                        
                        UPDATE vve_cred_soli_fact_fc 
                        SET val_para = (v_val_mont_cuot_mes_int * v_tipo_cambio)
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CUOT_FINA_MES'
                        AND val_mes = rs_resu.val_mes AND  val_ano = rs_resu.val_ano
                        AND ind_tipo_fc = 'G';
                    
                    END IF;
                    
                    IF rs_resu.cod_cred_para_fact = 'VAL_CAJA_LIBR_MES' THEN
                    
                        v_val_tota_ingr_mes_fact_int := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_INGR_MES_INT_FACT', rs_resu.val_mes, 
                        rs_resu.val_ano, 'I');
                        
                        v_val_tota_egre_mes_fact_int := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_EGRE_MES_INT_FACT', rs_resu.val_mes, 
                        rs_resu.val_ano, 'I');
                        
                        v_val_caja_disp_mes_calc_int := (v_val_tota_ingr_mes_fact_int - v_val_tota_egre_mes_fact_int);
                        
                        SELECT NVL(val_mont_cuo, 0) INTO v_val_mont_cuot_mes_calc_int
                        FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu 
                        AND EXTRACT(MONTH FROM fec_venc) = rs_resu.val_mes 
                        AND EXTRACT(YEAR FROM fec_venc) = rs_resu.val_ano;
                        
                        v_val_caja_libr_mes_int := v_val_caja_disp_mes_calc_int - (v_val_mont_cuot_mes_calc_int * v_tipo_cambio);
                        
                        UPDATE vve_cred_soli_fact_fc 
                        SET val_para = v_val_caja_libr_mes_int
                        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CAJA_LIBR_MES'
                        AND val_mes = rs_resu.val_mes AND  val_ano = rs_resu.val_ano
                        AND ind_tipo_fc = 'G';
                    
                    END IF;
                 
                END LOOP;
                
                -- PROYECTADO
                FOR rs_proy IN (SELECT val_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'A') LOOP
                    
                    v_caja_disp_proy := 0; v_cuota_fina_proy := 0;
                    
                    select sum(val_para) INTO v_caja_disp_proy from vve_cred_soli_fact_fc where cod_soli_cred = p_cod_soli_cred
                    and cod_cred_para_fact = 'VAL_CAJA_DISP_MES' and val_ano = rs_proy.val_ano;
                    
                    select sum(val_para) INTO v_cuota_fina_proy from vve_cred_soli_fact_fc where cod_soli_cred = p_cod_soli_cred
                    and cod_cred_para_fact = 'VAL_CUOT_FINA_MES' and val_ano = rs_proy.val_ano;
                    
                    UPDATE vve_cred_soli_fact_fc 
                    SET val_para = (v_caja_disp_proy / v_cuota_fina_proy)
                    WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_COBE_FCJA_ANUAL'
                    AND val_ano = rs_proy.val_ano
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'A';
                    
                END LOOP;
                
                v_cont_arr_cant := 0;
                ln_conc_anos_cabe := '';
                
                FOR rs_cobe IN (SELECT val_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'R' GROUP BY val_ano ORDER BY val_ano) LOOP
                    
                    v_cont_arr_cant := v_cont_arr_cant + 1;    
                    
                    IF (v_cont_arr_cant = 1) THEN
                        dbms_output.put_line('No tiene datos');
                        ln_conc_anos_cabe := rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant;
                        dbms_output.put_line('Primera concatenacion ' || ln_conc_anos_cabe);
                    ELSE
                        ln_conc_anos_cabe := ln_conc_anos_cabe || ',' || rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant;
                        dbms_output.put_line('Siguiente concatenacion ' || ln_conc_anos_cabe);
                    END IF;
                    
                END LOOP;
                
                dbms_output.put_line(ln_conc_anos_cabe);
                
                OPEN p_ret_colu_ano FOR
                    SELECT val_ano AS num_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                        AND ind_tipo_fc = 'G' AND ind_tipo = 'R' GROUP BY val_ano ORDER BY val_ano;
            
                ln_pivot_sql := 'SELECT * FROM
                    (
                        SELECT TO_NUMBER(TO_CHAR(SUM(x.val_sum_caja_disp) / SUM(x.val_sum_cuot_fina),''999999999999D99'')) num_ano, x.val_ano
                        FROM (
                           SELECT NVL(SUM(val_para), 0) val_sum_caja_disp, 0 val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                           GROUP BY val_ano
                           UNION ALL
                           SELECT 0 val_sum_caja_disp, NVL(SUM(val_para), 0) val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CUOT_FINA_MES''
                           GROUP BY val_ano
                        ) x
                        GROUP BY x.val_ano
                    )
                    PIVOT
                    (
                    MAX(num_ano)
                    FOR val_ano IN (' || ln_conc_anos_cabe || ')
                    )';
                
                
                OPEN p_ret_cursor FOR ln_pivot_sql;
                  
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_CALC_PROY_CAMI',
                                          p_cod_usua_sid,
                                          ln_pivot_sql,
                                          NULL,
                                          NULL);
            END IF;
            
            IF p_indi_tipo_fc = 'U' THEN
            
                dbms_output.put_line('Entro en Urbano');
                
                FOR rs IN (select val_nro_ruta from vve_cred_soli_para_fc where cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fc = 'COD_RUTA') LOOP
                    
                    -- INGRESOS
                    FOR rs_ingr IN (SELECT cod_cred_para_fact, val_mes, val_ano, val_fact_ajust FROM vve_cred_soli_fact_fc 
                        WHERE cod_soli_cred = p_cod_soli_cred AND val_nro_ruta = rs.val_nro_ruta
                        AND ind_tipo_fc = 'U' AND ind_tipo = 'IF' ORDER BY val_ano, val_mes) LOOP 
                    
                        v_val_para_tot_ingr_urb := 0; v_val_para_tot_rut_mes_urb := 0; v_val_para_oing_grigo_mes_urb := 0;
                        v_val_para_oing_coti_mes_urb := 0; v_val_para_oing_adm_mes_urb := 0; v_val_para_oing_bol_mes_urb := 0;
                        v_val_para_oing_desp_mes_urb := 0; v_val_para_oing_unif_mes_urb := 0; v_val_para_oing_gps_mes_urb := 0;
                        v_val_para_oing_limp_mes_urb := 0; v_val_para_oing_relo_mes_urb := 0;
                        
                        IF rs_ingr.cod_cred_para_fact = 'VAL_TOT_ING_MES_FACT' THEN              
                            
                            v_val_para_tot_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_TOT_RUT_MES', 'U');
                            v_val_para_oing_grigo_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_GRIFO', 'U');
                            v_val_para_oing_coti_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_COTIZ', 'U');
                            v_val_para_oing_adm_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_ADM', 'U');
                            v_val_para_oing_bol_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_BOL', 'U');
                            v_val_para_oing_desp_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_DESP', 'U');
                            v_val_para_oing_unif_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_UNIF', 'U');
                            v_val_para_oing_gps_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_GPS', 'U');
                            v_val_para_oing_limp_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_LIMP', 'U');
                            v_val_para_oing_relo_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_RELO', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round(((
                            v_val_para_tot_rut_mes_urb + v_val_para_oing_grigo_mes_urb + v_val_para_oing_coti_mes_urb + v_val_para_oing_adm_mes_urb + 
                            v_val_para_oing_bol_mes_urb + v_val_para_oing_desp_mes_urb + v_val_para_oing_unif_mes_urb + v_val_para_oing_gps_mes_urb + 
                            v_val_para_oing_limp_mes_urb + v_val_para_oing_relo_mes_urb) * rs_ingr.val_fact_ajust),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_TOT_ING_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
    
                        IF rs_ingr.cod_cred_para_fact = 'VAL_TOT_RUT_MES_FACT' THEN                
                            
                            v_val_para_tot_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_TOT_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_tot_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_TOT_RUT_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_ingr.cod_cred_para_fact = 'VAL_OING_GRIFO_MES_FACT' THEN                
                            
                            v_val_para_oing_grigo_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_GRIFO', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_oing_grigo_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OING_GRIFO_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_ingr.cod_cred_para_fact = 'VAL_OING_COTIZ_MES_FACT' THEN                
                            
                            v_val_para_oing_coti_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_COTIZ', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_oing_coti_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OING_COTIZ_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                    
                        IF rs_ingr.cod_cred_para_fact = 'VAL_OING_ADM_MES_FACT' THEN                
                            
                            v_val_para_oing_adm_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_ADM', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_oing_adm_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OING_ADM_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                    
                        IF rs_ingr.cod_cred_para_fact = 'VAL_OING_BOL_MES_FACT' THEN                
                            
                            v_val_para_oing_bol_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_BOL', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_oing_bol_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OING_BOL_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                    
                        IF rs_ingr.cod_cred_para_fact = 'VAL_OING_DESP_MES_FACT' THEN                
                            
                            v_val_para_oing_desp_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_DESP', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_oing_desp_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OING_DESP_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                    
                        IF rs_ingr.cod_cred_para_fact = 'VAL_OING_UNIF_MES_FACT' THEN                
                            
                            v_val_para_oing_unif_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_UNIF', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_oing_unif_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OING_UNIF_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                    
                        IF rs_ingr.cod_cred_para_fact = 'VAL_OING_GPS_MES_FACT' THEN                
                            
                            v_val_para_oing_gps_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_GPS', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_oing_gps_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OING_GPS_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                    
                        IF rs_ingr.cod_cred_para_fact = 'VAL_OING_LIMP_MES_FACT' THEN                
                            
                            v_val_para_oing_limp_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_LIMP', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_oing_limp_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OING_LIMP_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                    
                        IF rs_ingr.cod_cred_para_fact = 'VAL_OING_RELO_MES_FACT' THEN                
                            
                            v_val_para_oing_relo_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OING_RELO', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_ingr.val_fact_ajust * v_val_para_oing_relo_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OING_RELO_MES_FACT'
                            AND val_mes = rs_ingr.val_mes AND val_ano = rs_ingr.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                
                    END LOOP;
                    
                    -- EGRESOS
                    FOR rs_egre IN (SELECT cod_cred_para_fact, val_mes, val_ano, val_fact_ajust FROM vve_cred_soli_fact_fc 
                        WHERE cod_soli_cred = p_cod_soli_cred AND val_nro_ruta = rs.val_nro_ruta
                        AND ind_tipo_fc = 'U' AND ind_tipo = 'EF' ORDER BY val_ano, val_mes) LOOP
                        
                        v_val_para_comb_rut_mes_urb := 0; v_val_para_rend_km_gal_mes_urb := 0; v_val_para_kilo_rut_mes_urb := 0;
                        v_val_para_prec_com_mes_urb := 0; v_val_para_cons_gal_mes_urb := 0; v_val_para_mant_prop_mes_urb := 0;
                        v_val_para_km_prop_mes_urb := 0; v_val_para_mant_km_mes_urb := 0; v_val_para_gast_pers_mes_urb := 0;
                        v_val_para_chof_rut_mes_urb := 0; v_val_para_cob_rut_mes_urb := 0; v_val_para_viat_rut_mes_urb := 0;
                        v_val_para_peaj_rut_mes_urb := 0; v_val_para_cost_reca_mes_urb := 0; v_val_para_gps_rut_mes_urb := 0;
                        v_val_para_soat_rut_mes_urb := 0; v_val_para_coti_rut_mes_urb := 0; v_val_para_otro_gas_mes_urb := 0;
                        v_val_para_cuo_leas_mes_urb := 0; v_val_para_igv_comp_mes_urb := 0;
                                
                        IF rs_egre.cod_cred_para_fact = 'VAL_TOT_EGRE_URB_MES_FACT' THEN                
                        
                            v_val_para_comb_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COMB_RUT_MES', 'U');
                            v_val_para_rend_km_gal_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_REND_KM_GALON_RUT_MES', 'U');
                            v_val_para_kilo_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_KM_RUT_MES', 'U');
                            v_val_para_prec_com_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PREC_COMB_RUT_MES', 'U');
                            v_val_para_cons_gal_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_CONS_GAL_RUT_MES', 'U');
                            v_val_para_mant_prop_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_MANT_PROP_RUT_MES', 'U');
                            v_val_para_km_prop_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_KM_PROP_RUT_MES', 'U');
                            v_val_para_mant_km_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_MANT_KM_PROP_RUT_MES', 'U');
                            v_val_para_gast_pers_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_GAST_PERS_RUT_MES', 'U');
                            v_val_para_chof_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_CHOF_RUT_MES', 'U');
                            v_val_para_cob_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COB_RUT_MES', 'U');
                            v_val_para_viat_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_VIAT_RUT_MES', 'U');
                            v_val_para_peaj_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PEAJ_RUT_MES', 'U');
                            v_val_para_cost_reca_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COST_RECA_FLOT_MES', 'U');
                            v_val_para_gps_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_GPS_RUT_MES', 'U');
                            v_val_para_soat_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_SOAT_RUT_MES', 'U');
                            v_val_para_coti_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COTI_RUT_MES', 'U');
                            v_val_para_otro_gas_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OGAST_RUT_MES', 'U');
                            v_val_para_cuo_leas_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_CUO_LEAS_RUT_MES', 'U');
                            v_val_para_igv_comp_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_IGV_COMP_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((((
                            v_val_para_comb_rut_mes_urb + v_val_para_rend_km_gal_mes_urb + v_val_para_kilo_rut_mes_urb +
                            v_val_para_prec_com_mes_urb + v_val_para_cons_gal_mes_urb + v_val_para_mant_prop_mes_urb +
                            v_val_para_km_prop_mes_urb + v_val_para_mant_km_mes_urb + v_val_para_gast_pers_mes_urb +
                            v_val_para_chof_rut_mes_urb + v_val_para_cob_rut_mes_urb + v_val_para_viat_rut_mes_urb +
                            v_val_para_peaj_rut_mes_urb + v_val_para_cost_reca_mes_urb + v_val_para_gps_rut_mes_urb +
                            v_val_para_soat_rut_mes_urb + v_val_para_coti_rut_mes_urb + v_val_para_otro_gas_mes_urb +
                            v_val_para_igv_comp_mes_urb) * rs_egre.val_fact_ajust) + v_val_para_cuo_leas_mes_urb) ,2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_TOT_EGRE_URB_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF; 
    
    
                        IF rs_egre.cod_cred_para_fact = 'VAL_COMB_RUT_MES_FACT' THEN                
                        
                            v_val_para_comb_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COMB_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_comb_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_COMB_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_REND_KM_GALON_RUT_MES_FACT' THEN                
                        
                            v_val_para_rend_km_gal_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_REND_KM_GALON_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_rend_km_gal_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_REND_KM_GALON_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_KM_RUT_MES_FACT' THEN                
                        
                            v_val_para_kilo_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_KM_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_kilo_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_KM_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_PREC_COMB_RUT_MES_FACT' THEN                
                        
                            v_val_para_prec_com_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PREC_COMB_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_prec_com_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_PREC_COMB_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_CONS_GAL_RUT_MES_FACT' THEN                
                        
                            v_val_para_cons_gal_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_CONS_GAL_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_cons_gal_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CONS_GAL_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_MANT_PROP_RUT_MES_FACT' THEN                
                        
                            v_val_para_mant_prop_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_MANT_PROP_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_mant_prop_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_MANT_PROP_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_KM_PROP_RUT_MES_FACT' THEN                
                        
                            v_val_para_km_prop_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_KM_PROP_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_km_prop_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_KM_PROP_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_MANT_KM_PROP_RUT_MES_FACT' THEN                
                        
                            v_val_para_mant_km_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_MANT_KM_PROP_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_mant_km_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_MANT_KM_PROP_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_GAST_PERS_RUT_MES_FACT' THEN                
                        
                            v_val_para_gast_pers_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_GAST_PERS_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_gast_pers_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_GAST_PERS_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_CHOF_RUT_MES_FACT' THEN                
                        
                            v_val_para_chof_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_CHOF_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_chof_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CHOF_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_COB_RUT_MES_FACT' THEN                
                        
                            v_val_para_cob_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COB_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_cob_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_COB_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_VIAT_RUT_MES_FACT' THEN                
                        
                            v_val_para_viat_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_VIAT_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_viat_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_VIAT_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_PEAJ_RUT_MES_FACT' THEN                
                        
                            v_val_para_peaj_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_PEAJ_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_peaj_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_PEAJ_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_COST_RECA_FLOT_MES_FACT' THEN                
                        
                            v_val_para_cost_reca_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COST_RECA_FLOT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_cost_reca_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_COST_RECA_FLOT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_GPS_RUT_MES_FACT' THEN                
                        
                            v_val_para_gps_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_GPS_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_gps_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_GPS_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_SOAT_RUT_MES_FACT' THEN                
                        
                            v_val_para_soat_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_SOAT_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_soat_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_SOAT_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_COTI_RUT_MES_FACT' THEN                
                        
                            v_val_para_coti_rut_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_COTI_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_coti_rut_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_COTI_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_OGAST_RUT_MES_FACT' THEN                
                        
                            v_val_para_otro_gas_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_OGAST_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_otro_gas_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_OGAST_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_CUO_LEAS_RUT_MES_FACT' THEN                
                        
                            v_val_para_cuo_leas_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_CUO_LEAS_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round(v_val_para_cuo_leas_mes_urb ,2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CUO_LEAS_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                        
                        IF rs_egre.cod_cred_para_fact = 'VAL_IGV_COMP_RUT_MES_FACT' THEN                
                        
                            v_val_para_igv_comp_mes_urb := fn_ret_val_cred_soli_para_fc(p_cod_soli_cred, 'VAL_IGV_COMP_RUT_MES', 'U');
                            
                            UPDATE vve_cred_soli_fact_fc SET VAL_PARA = round((rs_egre.val_fact_ajust * v_val_para_igv_comp_mes_urb),2)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_IGV_COMP_RUT_MES_FACT'
                            AND val_mes = rs_egre.val_mes AND val_ano = rs_egre.val_ano AND val_nro_ruta = rs.val_nro_ruta;             
                        END IF;
                    
                    END LOOP;
                    
                    -- RESUMEN
                    
                    FOR rs_resu IN (SELECT cod_cred_para_fact, val_mes, val_ano FROM vve_cred_soli_fact_fc 
                        WHERE cod_soli_cred = p_cod_soli_cred AND val_nro_ruta = rs.val_nro_ruta
                        AND ind_tipo_fc = 'G' AND ind_tipo = 'R' ORDER BY val_ano, val_mes) LOOP
                    
                        v_val_tota_ingr_mes_fact_urb := 0; v_val_tota_egre_mes_fact_urb := 0; v_val_caja_disp_mes_urb := 0;
                        v_val_mont_cuot_mes_urb := 0; v_val_caja_disp_mes_calc_urb := 0; v_val_mont_cuot_mes_calc_urb := 0; 
                        v_val_caja_libr_mes_urb := 0;
                        
                        IF rs_resu.cod_cred_para_fact = 'VAL_CAJA_DISP_MES' THEN    
        
                            v_val_tota_ingr_mes_fact_urb := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_ING_MES_FACT', rs_resu.val_mes, 
                            rs_resu.val_ano, 'U');
                            
                            v_val_tota_egre_mes_fact_urb := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_EGRE_URB_MES_FACT', rs_resu.val_mes, 
                            rs_resu.val_ano, 'U');
                            
                            v_val_caja_disp_mes_urb := (v_val_tota_ingr_mes_fact_urb - v_val_tota_egre_mes_fact_urb);
                            
                            UPDATE vve_cred_soli_fact_fc 
                            SET val_para = v_val_caja_disp_mes_urb
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CAJA_DISP_MES'
                            AND val_mes = rs_resu.val_mes AND val_ano = rs_resu.val_ano AND val_nro_ruta = rs.val_nro_ruta
                            AND ind_tipo_fc = 'G';
                            
                        END IF;
                        
                        IF rs_resu.cod_cred_para_fact = 'VAL_CUOT_FINA_MES' THEN
                            
                            BEGIN
                                SELECT NVL(val_mont_cuo, 0) INTO v_val_mont_cuot_mes_urb
                                FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu 
                                AND EXTRACT(MONTH FROM fec_venc) = rs_resu.val_mes 
                                AND EXTRACT(YEAR FROM fec_venc) = rs_resu.val_ano;
                            EXCEPTION
                                WHEN OTHERS THEN
                                v_val_mont_cuot_mes_urb := 0;
                                p_ret_esta := 0;
                                p_ret_mens := 'No se pudo generar la Proyeccion, hay errores en el Cronograma.';
                                RETURN;
                            END;
                            
                            UPDATE vve_cred_soli_fact_fc 
                            SET val_para = (v_val_mont_cuot_mes_urb * v_tipo_cambio)
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CUOT_FINA_MES'
                            AND val_mes = rs_resu.val_mes AND  val_ano = rs_resu.val_ano AND val_nro_ruta = rs.val_nro_ruta
                            AND ind_tipo_fc = 'G';
                        
                        END IF;
                        
                        IF rs_resu.cod_cred_para_fact = 'VAL_CAJA_LIBR_MES' THEN
                        
                            v_val_tota_ingr_mes_fact_urb := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_ING_MES_FACT', rs_resu.val_mes, 
                            rs_resu.val_ano, 'U');
                            
                            v_val_tota_egre_mes_fact_urb := fn_ret_val_cred_soli_fact_fc(p_cod_soli_cred, 'VAL_TOT_EGRE_URB_MES_FACT', rs_resu.val_mes, 
                            rs_resu.val_ano, 'U');
                            
                            v_val_caja_disp_mes_calc_urb := (v_val_tota_ingr_mes_fact_urb - v_val_tota_egre_mes_fact_urb);
                            
                            SELECT NVL(val_mont_cuo, 0) INTO v_val_mont_cuot_mes_calc_urb
                            FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu 
                            AND EXTRACT(MONTH FROM fec_venc) = rs_resu.val_mes 
                            AND EXTRACT(YEAR FROM fec_venc) = rs_resu.val_ano;
                            
                            v_val_caja_libr_mes_urb := v_val_caja_disp_mes_calc_urb - (v_val_mont_cuot_mes_calc_urb * v_tipo_cambio);
                            
                            UPDATE vve_cred_soli_fact_fc 
                            SET val_para = v_val_caja_libr_mes_urb
                            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CAJA_LIBR_MES'
                            AND val_mes = rs_resu.val_mes AND  val_ano = rs_resu.val_ano AND val_nro_ruta = rs.val_nro_ruta
                            AND ind_tipo_fc = 'G';
                        
                        END IF;
                     
                    END LOOP;
                    
                END LOOP;
                
                -- PROYECTADO
                FOR rs_proy IN (SELECT val_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'A') LOOP
                    
                    v_caja_disp_proy := 0; v_cuota_fina_proy := 0;
                    
                    select sum(val_para) INTO v_caja_disp_proy from vve_cred_soli_fact_fc where cod_soli_cred = p_cod_soli_cred
                    and cod_cred_para_fact = 'VAL_CAJA_DISP_MES' and val_ano = rs_proy.val_ano;
                    
                    select sum(val_para) INTO v_cuota_fina_proy from vve_cred_soli_fact_fc where cod_soli_cred = p_cod_soli_cred
                    and cod_cred_para_fact = 'VAL_CUOT_FINA_MES' and val_ano = rs_proy.val_ano;
                    
                    UPDATE vve_cred_soli_fact_fc 
                    SET val_para = (v_caja_disp_proy / v_cuota_fina_proy)
                    WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_COBE_FCJA_ANUAL'
                    AND val_ano = rs_proy.val_ano
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'A';
                    
                END LOOP;
                
                v_cont_arr_cant := 0;
                ln_conc_anos_cabe := '';
                
                FOR rs_cobe IN (SELECT val_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                    AND ind_tipo_fc = 'G' AND ind_tipo = 'A' ORDER BY val_ano) LOOP
                    
                    v_cont_arr_cant := v_cont_arr_cant + 1;    
                    
                    IF (v_cont_arr_cant = 1) THEN
                        dbms_output.put_line('No tiene datos');
                        ln_conc_anos_cabe := rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant;
                        dbms_output.put_line('Primera concatenacion ' || ln_conc_anos_cabe);
                    ELSE
                        ln_conc_anos_cabe := ln_conc_anos_cabe || ',' || rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant;
                        dbms_output.put_line('Siguiente concatenacion ' || ln_conc_anos_cabe);
                    END IF;
                    
                END LOOP;
                
                dbms_output.put_line(ln_conc_anos_cabe);
                
                OPEN p_ret_colu_ano FOR
                    SELECT val_ano AS num_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                        AND ind_tipo_fc = 'G' AND ind_tipo = 'R' GROUP BY val_ano ORDER BY val_ano;
            
                ln_pivot_sql := 'SELECT * FROM
                    (
                        SELECT TO_NUMBER(TO_CHAR(SUM(x.val_sum_caja_disp) / SUM(x.val_sum_cuot_fina),''999999999999D99'')) num_ano, x.val_ano
                        FROM (
                           SELECT NVL(SUM(val_para), 0) val_sum_caja_disp, 0 val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                           GROUP BY val_ano
                           UNION ALL
                           SELECT 0 val_sum_caja_disp, NVL(SUM(val_para), 0) val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CUOT_FINA_MES''
                           GROUP BY val_ano
                        ) x
                        GROUP BY x.val_ano
                    )
                    PIVOT
                    (
                    MAX(num_ano)
                    FOR val_ano IN (' || ln_conc_anos_cabe || ')
                    )';
                
                
                OPEN p_ret_cursor FOR ln_pivot_sql;
                  
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_CALC_PROY_CAMI',
                                          p_cod_usua_sid,
                                          ln_pivot_sql,
                                          NULL,
                                          NULL);
                
                
            END IF;
            
            p_ret_esta := 1;
            p_ret_mens := 'Se realizó el proceso satisfactoriamente.';
            
        ELSE 
        
            p_ret_esta := 0;
            p_ret_mens := 'Falta ingresar parámetros para realizar la proyección.';
        
        END IF;
    
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_CALC_PROY_CAMI', p_cod_usua_sid, 'Error al calcular la Proyección '||p_cod_soli_cred
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := p_ret_mens||'SP_CALC_PROY_CAMI:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_CALC_PROY_CAMI', p_cod_usua_sid, 'Error al calcular la Proyección'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
         
    END sp_calc_proy_cami;
    
    
    FUNCTION fn_ret_text
    (
      p_val_ano IN  NUMBER
    ) RETURN VARCHAR2 AS

    BEGIN
    
        RETURN TO_CHAR(p_val_ano);
    
    END fn_ret_text;
    
    
    FUNCTION fn_ret_val_cred_soli_fact_fc
    (
        p_cod_soli_cred                   IN      vve_cred_soli_fact_fc.cod_soli_cred%TYPE,
        p_cod_cred_para_fact              IN      vve_cred_soli_fact_fc.cod_cred_para_fact%TYPE,
        p_val_mes                         IN      vve_cred_soli_fact_fc.val_mes%TYPE, 
        p_val_ano                         IN      vve_cred_soli_fact_fc.val_ano%TYPE,
        p_ind_tipo_fc                     IN      vve_cred_soli_fact_fc.ind_tipo_fc%TYPE   
    ) RETURN NUMBER AS
        v_val_para NUMBER;
        
    BEGIN
        
        SELECT NVL(SUM(val_para), 0) INTO v_val_para
        FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred
        AND cod_cred_para_fact = p_cod_cred_para_fact
        AND val_mes = p_val_mes AND val_ano = p_val_ano
        AND ind_tipo_fc = p_ind_tipo_fc;
    
        RETURN v_val_para;
    
    END fn_ret_val_cred_soli_fact_fc;
    
    
    FUNCTION fn_ret_val_cred_soli_para_fc
    (
        p_cod_soli_cred                 IN      vve_cred_soli_para_fc.cod_soli_cred%TYPE,
        p_cod_cred_para_fc              IN      vve_cred_soli_para_fc.cod_cred_para_fc%TYPE,
        p_ind_tipo_fc                   IN      vve_cred_soli_para_fc.ind_tipo_fc%TYPE   
    ) RETURN NUMBER AS
        v_val_para NUMBER;
    
    BEGIN
    
        SELECT NVL(SUM(val_para), 0) INTO v_val_para FROM vve_cred_soli_para_fc 
        WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fc = p_cod_cred_para_fc
        AND ind_tipo_fc = p_ind_tipo_fc;
        
        RETURN v_val_para;
    
    END fn_ret_val_cred_soli_para_fc;
    
    
    PROCEDURE sp_list_para_fc
    (      
     p_cod_soli_cred                IN      vve_cred_soli.cod_soli_cred%TYPE,
     p_ind_tipo_fc                  IN      vve_cred_soli_para_fc.ind_tipo_fc%TYPE,
     p_cod_usua_sid                 IN      sistemas.usuarios.co_usuario%TYPE,
     p_ret_cursor                   OUT     SYS_REFCURSOR,
     p_ret_cabe_urba                OUT     SYS_REFCURSOR, 
     p_ret_fact_cons_if             OUT     SYS_REFCURSOR, 
     p_ret_fact_cons_ef             OUT     SYS_REFCURSOR,
     p_ret_fact_ajus_if             OUT     SYS_REFCURSOR, 
     p_ret_fact_ajus_ef             OUT     SYS_REFCURSOR, 
     p_ret_colu_ano                 OUT     SYS_REFCURSOR, 
     p_ret_fc_proy                  OUT     SYS_REFCURSOR, 
     p_ret_esta                     OUT     NUMBER,
     p_ret_mens                     OUT     VARCHAR2
    ) AS 
        ve_error EXCEPTION;
        v_fec_fluj_caja DATE;
        v_fec_simu DATE;
        v_val_mes NUMBER;
        v_val_ano NUMBER;
        v_cod_simu NUMBER;
        v_cant_fluj_caja NUMBER;
        v_cant_letr_simu NUMBER;
        
        v_cont_arr_cant NUMBER;
        ln_conc_anos_cabe  VARCHAR2(6000);
        ln_pivot_sql VARCHAR2(4000);
        
        v_sum_caja NUMERIC(11,2);
        v_sum_cuot NUMERIC(11,2);
        
        v_exito NUMBER;
        
    BEGIN
    
        BEGIN
            SELECT min(TO_DATE('01/'||LPAD(TO_CHAR(val_mes),2,'0')||'/'||TO_CHAR(val_ano), 'DD/MM/YYYY'))
            INTO v_fec_fluj_caja
            FROM vve_cred_soli_fact_fc 
            WHERE cod_soli_cred = p_cod_soli_cred
            and cod_cred_para_fact not in ('VAL_COBE_FCJA_ANUAL');
        EXCEPTION
            WHEN OTHERS THEN
            v_fec_fluj_caja := NULL;
        END;
        
        BEGIN
            SELECT TO_DATE('01/'||to_char(fec_venc_1ra_let,'MM/YYYY'),'DD/MM/YYYY') INTO v_fec_simu
            FROM vve_cred_simu WHERE cod_soli_cred= p_cod_soli_cred AND ind_inactivo = 'N';
        EXCEPTION
            WHEN OTHERS THEN
            v_fec_simu := NULL;
        END;
        
        IF v_fec_fluj_caja = v_fec_simu THEN
            
            SELECT COUNT(*) INTO v_cant_fluj_caja 
            FROM 
            (SELECT DISTINCT val_mes, val_ano
            FROM vve_cred_soli_fact_fc 
            WHERE cod_soli_cred = p_cod_soli_cred 
            and cod_cred_para_fact NOT IN ('VAL_COBE_FCJA_ANUAL') ORDER BY val_ano, val_mes) x;
            
            SELECT cod_simu INTO v_cod_simu
            FROM vve_cred_simu 
            WHERE cod_soli_cred = p_cod_soli_cred AND ind_inactivo = 'N';
            
            SELECT COUNT(*) INTO v_cant_letr_simu
            FROM vve_cred_simu_letr WHERE cod_simu = v_cod_simu;
            
            IF v_cant_fluj_caja = v_cant_letr_simu THEN
                v_exito := 1;
            ELSE
                v_exito := 0;
            END IF;
    
        ELSE
            v_exito := 0;
        END IF;
        
        IF v_exito = 0 THEN
            DELETE FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred; 
            DELETE FROM vve_cred_soli_fact_ajust WHERE cod_soli_cred = p_cod_soli_cred;
            COMMIT;
        END IF;
        
        OPEN p_ret_cursor FOR
            SELECT cod_cred_para_fc, NVL(val_para, 0) AS val_para, val_nro_ruta , val_txt
            FROM vve_cred_soli_para_fc 
            WHERE cod_soli_cred = p_cod_soli_cred AND ind_tipo_fc = p_ind_tipo_fc
            union all
            SELECT cod_cred_para_fc, NVL(val_para, 0) AS val_para, val_nro_ruta  , val_txt
            FROM vve_cred_soli_para_fc 
            WHERE cod_soli_cred = p_cod_soli_cred AND ind_tipo_fc = 'G' and ind_tipo = 'G';
            
            
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_LIST_PARA_FC',
                          p_cod_usua_sid,
                          'PASO 1',
                          NULL,
                          NULL);
            
        OPEN p_ret_cabe_urba FOR
            SELECT COD_RUTA, VAL_DIAS_TRAB_RUTA, VAL_NRO_VEH_RUTA, VAL_TOT_INGR_URB_MES, VAL_TOT_EGRE_URB_MES FROM
            (
                SELECT cod_cred_para_fc, val_nro_ruta, val_para FROM vve_cred_soli_para_fc 
                WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fc 
                in ('COD_RUTA','VAL_DIAS_TRAB_RUTA','VAL_NRO_VEH_RUTA','VAL_TOT_INGR_URB_MES','VAL_TOT_EGRE_URB_MES')
            
            )
            PIVOT
            (
                MAX(val_para)
                FOR cod_cred_para_fc IN ('COD_RUTA' AS COD_RUTA,'VAL_DIAS_TRAB_RUTA' AS VAL_DIAS_TRAB_RUTA,'VAL_NRO_VEH_RUTA' AS VAL_NRO_VEH_RUTA,
                'VAL_TOT_INGR_URB_MES' AS VAL_TOT_INGR_URB_MES,'VAL_TOT_EGRE_URB_MES' AS VAL_TOT_EGRE_URB_MES)
            );
            
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_LIST_PARA_FC',
                          p_cod_usua_sid,
                          'PASO 2',
                          NULL,
                          NULL);
              --<I Obs. 266 - Se agrego listado de factores constantes>                           
        OPEN p_ret_fact_cons_if FOR
            SELECT val_mes,
                val_ano,
                cod_cred_para_fact,
                val_para,
                val_fact_ajust
            FROM vve_cred_soli_fact_fc 
            WHERE cod_soli_cred = p_cod_soli_cred 
                AND ind_tipo_fc = p_ind_tipo_fc 
                AND ind_tipo = 'IF'
                AND NOT EXISTS (
                    SELECT 'X'
                    FROM vve_cred_soli_fact_ajust 
                    WHERE cod_soli_cred = p_cod_soli_cred 
                        AND ind_tipo_fc = p_ind_tipo_fc 
                        AND ind_tipo = 'IF'
                );

        OPEN p_ret_fact_cons_ef FOR
            SELECT val_mes,
                val_ano,
                cod_cred_para_fact,
                val_para,
                val_fact_ajust
            FROM vve_cred_soli_fact_fc 
            WHERE cod_soli_cred = p_cod_soli_cred 
                AND ind_tipo_fc = p_ind_tipo_fc 
                AND ind_tipo = 'EF'
                AND NOT EXISTS (
                    SELECT 'X'
                    FROM vve_cred_soli_fact_ajust 
                    WHERE cod_soli_cred = p_cod_soli_cred 
                        AND ind_tipo_fc = p_ind_tipo_fc 
                        AND ind_tipo = 'EF'
                );
        --<F Obs. 266 - Se agrego listado de factores constantes>        
            
        OPEN p_ret_fact_ajus_if FOR     
            -- SELECT TO_CHAR(fec_ini, 'DD/MM/YYYY') AS fec_ini, TO_CHAR(fec_fin, 'DD/MM/YYYY') AS fec_fin, val_fact_ajust,
            SELECT fec_ini AS fec_ini, fec_fin AS fec_fin, val_fact_ajust,
            'INGR' AS ind_ingr_egre
            from vve_cred_soli_fact_ajust where 
            cod_soli_cred = p_cod_soli_cred and ind_tipo_fc = p_ind_tipo_fc and ind_tipo = 'IF' ORDER BY nro_orde;
            
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_LIST_PARA_FC',
                          p_cod_usua_sid,
                          'PASO 3',
                          NULL,
                          NULL);
            
        OPEN p_ret_fact_ajus_ef FOR       
            -- SELECT TO_CHAR(fec_ini, 'DD/MM/YYYY') AS fec_ini, TO_CHAR(fec_fin, 'DD/MM/YYYY') AS fec_fin, val_fact_ajust,
            SELECT fec_ini AS fec_ini, fec_fin AS fec_fin, val_fact_ajust,
            'EGRE' AS ind_ingr_egre
            from vve_cred_soli_fact_ajust where 
            cod_soli_cred = p_cod_soli_cred and ind_tipo_fc = p_ind_tipo_fc and ind_tipo = 'EF' ORDER BY nro_orde;
            
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                          'SP_LIST_PARA_FC',
                          p_cod_usua_sid,
                          'PASO 4',
                          NULL,
                          NULL);
                          
        SELECT NVL(sum(val_para), 0) INTO v_sum_caja
        FROM vve_cred_soli_fact_fc 
        WHERE cod_soli_cred = p_cod_soli_cred 
        and cod_cred_para_fact = 'VAL_CAJA_DISP_MES';
        
        SELECT NVL(sum(val_para), 0) INTO v_sum_cuot
        FROM vve_cred_soli_fact_fc 
        WHERE cod_soli_cred = p_cod_soli_cred
        and cod_cred_para_fact = 'VAL_CUOT_FINA_MES';
        
        
        IF v_sum_caja > 0 AND v_sum_cuot > 0 THEN
        
            -- PARA FLUJO DE CAJA PROYECTADO
            v_cont_arr_cant := 0;
            ln_conc_anos_cabe := '';
    
            FOR rs_cobe IN (SELECT val_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                AND ind_tipo_fc = 'G' AND ind_tipo = 'A' GROUP BY val_ano ORDER BY val_ano) LOOP
                
                v_cont_arr_cant := v_cont_arr_cant + 1;    
                
                IF (v_cont_arr_cant = 1) THEN
                    dbms_output.put_line('No tiene datos');
                    ln_conc_anos_cabe := rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant;
                    dbms_output.put_line('Primera concatenacion ' || ln_conc_anos_cabe);
                ELSE
                    ln_conc_anos_cabe := ln_conc_anos_cabe || ',' || rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant;
                    dbms_output.put_line('Siguiente concatenacion ' || ln_conc_anos_cabe);
                END IF;
                
            END LOOP;
                    
            --dbms_output.put_line(ln_conc_anos_cabe); 
            
            IF ln_conc_anos_cabe IS NOT NULL THEN
            
                dbms_output.put_line('Entro ln_conc_anos_cabe != '); 
            
                OPEN p_ret_colu_ano FOR
                    SELECT val_ano AS num_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                        AND ind_tipo_fc = 'G' AND ind_tipo = 'A' GROUP BY val_ano ORDER BY val_ano;
            
                ln_pivot_sql := 'SELECT * FROM
                    (
                        SELECT TO_NUMBER(TO_CHAR(SUM(x.val_sum_caja_disp) / SUM(x.val_sum_cuot_fina),''999999999999D99'')) num_ano, x.val_ano
                        FROM (
                           SELECT NVL(SUM(val_para), 0) val_sum_caja_disp, 0 val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                           GROUP BY val_ano
                           UNION ALL
                           SELECT 0 val_sum_caja_disp, NVL(SUM(val_para), 0) val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CUOT_FINA_MES''
                           GROUP BY val_ano
                        ) x
                        GROUP BY x.val_ano
                    )
                    PIVOT
                    (
                    MAX(num_ano)
                    FOR val_ano IN (' || ln_conc_anos_cabe || ')
                    )';
            
            
                OPEN p_ret_fc_proy FOR ln_pivot_sql;
            
            END IF;
        
        END IF;
        
        IF v_exito = 1 THEN
            p_ret_esta := 1;
            p_ret_mens := 'Se realizó el proceso satisfactoriamente';
            
        ELSE 
            p_ret_esta := 1;
            p_ret_mens := 'Se realizó el proceso satisfactoriamente. Ingrese los Factores de Ingreso y Egreso';
        END IF;
    
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_PARA_FC', p_cod_usua_sid, 
            'Error al consultar los parametros de Flujo de Caja '||p_cod_soli_cred
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := p_ret_mens||'SP_LIST_PARA_FC:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_PARA_FC', p_cod_usua_sid, 
            'Error al consultar los parametros de Flujo de Caja'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
         
    END sp_list_para_fc;
    
    
    PROCEDURE sp_repo_fluj_caja
    (      
         p_cod_soli_cred                IN      vve_cred_soli.cod_soli_cred%TYPE,
         p_indi_tipo_fc                 IN      VARCHAR2,
         p_cod_usua_sid                 IN      sistemas.usuarios.co_usuario%TYPE,
         p_ret_fact_ingr                OUT     SYS_REFCURSOR,
         p_ret_fact_egre                OUT     SYS_REFCURSOR,
         p_ret_fact_caja                OUT     SYS_REFCURSOR,
         p_ret_fc_proy                  OUT     SYS_REFCURSOR,
         p_txtComentario                OUT     VARCHAR2,
         p_ret_esta                     OUT     NUMBER,
         p_ret_mens                     OUT     VARCHAR2
    ) AS 
        ve_error EXCEPTION;
        ln_conc_anos_cabe  VARCHAR2(12000);
        v_cont_arr_cant NUMBER;
        v_cont_ano NUMBER;
        v_val_ano NUMBER;
        
        ln_pivot_ingr_sql VARCHAR2(30000);
        ln_pivot_egre_sql VARCHAR2(30000);
        ln_pivot_caja_sql VARCHAR2(30000);
        ln_separador VARCHAR2(1);
        
        v_sum_caja NUMERIC(11,2);
        v_sum_cuot NUMERIC(11,2);
        v_txt_comentario VARCHAR2(2000);
        
        v_cont_arr_cant_proy NUMBER;
        ln_conc_anos_cabe_proy VARCHAR2(6000);
        ln_pivot_sql_proy VARCHAR2(4000);
        
    BEGIN
        
        BEGIN
            select val_txt into v_txt_comentario from vve_cred_soli_para_fc where cod_soli_cred = p_cod_soli_cred and ind_tipo_fc = 'G' and 
            ind_tipo= 'G' and rownum = 1;
            p_txtComentario := v_txt_comentario;
        EXCEPTION
            WHEN OTHERS THEN
            p_txtComentario := '';
        END;
        
        ln_separador := '/';
    
        v_cont_arr_cant := 0;
        FOR rs IN (SELECT val_ano, val_mes, val_para FROM vve_cred_soli_fact_fc 
            WHERE cod_soli_cred = p_cod_soli_cred AND cod_cred_para_fact = 'VAL_CAJA_LIBR_MES'
            ORDER BY val_ano, val_mes) LOOP
            
            v_cont_arr_cant := v_cont_arr_cant + 1;  
            
            IF (v_cont_ano IS NULL) THEN
                v_cont_ano := 1;
                v_val_ano := rs.val_ano;
            ELSE 
                IF v_val_ano != rs.val_ano THEN
                    v_cont_ano := v_cont_ano + 1;
                    v_val_ano := rs.val_ano;
                END IF;
            END IF;
            
            IF (v_cont_arr_cant = 1) THEN
                dbms_output.put_line('No tiene datos');
                ln_conc_anos_cabe := '('||rs.val_ano||','||rs.val_mes|| ')'||' AS ANIO_'||v_cont_ano||'_MES_'||rs.val_mes;
            ELSE
                ln_conc_anos_cabe := ln_conc_anos_cabe || ',' || '('||rs.val_ano||','||rs.val_mes|| ')'||' AS ANIO_'||v_cont_ano||'_MES_'||rs.val_mes;
            END IF;
                
        END LOOP;
        
        dbms_output.put_line(ln_conc_anos_cabe);
        
        IF p_indi_tipo_fc = 'C' THEN
        
            dbms_output.put_line('entro en Cami');
        
            -- PARA INGRESOS
            ln_pivot_ingr_sql := '
                SELECT * FROM
                (
                    SELECT ''AÑO/MES'' AS rubro, val_ano, val_mes, concat(val_ano, concat(''/'', val_mes)) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_ING_MES_CAM_FACT''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Factor Ajuste'' AS rubro, val_ano, val_mes, TO_CHAR(val_fact_ajust) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_ING_MES_CAM_FACT''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Ingresos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_INGR_MES_CAM_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Ingresos Mensuales'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_ING_MES_CAM_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Otros Ingresos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para  FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OTRO_INGR_CAM_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))';
                
            dbms_output.put_line(ln_pivot_ingr_sql);
                 
            OPEN p_ret_fact_ingr FOR ln_pivot_ingr_sql;
            
            
            -- EGRESOS
            ln_pivot_egre_sql := '
                SELECT * FROM
                (
                    SELECT ''AÑO/MES'' AS rubro, val_ano, val_mes, concat(val_ano, concat(''/'', val_mes)) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_EGRE_MES_CAM_FACT''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Factor Ajuste'' AS rubro, val_ano, val_mes, TO_CHAR(val_fact_ajust) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_EGRE_MES_CAM_FACT''
                ) 
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Egresos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_EGRE_MES_CAM_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Pago Personal'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_PAGO_PERS_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Combustible'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_COMB_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Mantenimiento Gral.'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_MANT_GRAL_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Cuota Leasing'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_LEASI_MUTUO_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Otros Gastos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OTRO_GAST_CAM_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )';
            
            OPEN p_ret_fact_egre FOR ln_pivot_egre_sql;
            
            -- FLUJO DE CAJA
            ln_pivot_caja_sql := '
                SELECT * FROM
                (
                    SELECT ''AÑO/MES'' AS rubro, val_ano, val_mes, concat(val_ano, concat(''/'', val_mes)) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Caja Disponible'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Cuota Financiamiento'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CUOT_FINA_MES''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Caja Libre'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CAJA_LIBR_MES''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )';
            
            OPEN p_ret_fact_caja FOR ln_pivot_caja_sql;
            
        END IF;
        
        IF p_indi_tipo_fc = 'I' THEN
        
            dbms_output.put_line('entro en Inter');
        
            -- PARA INGRESOS
            ln_pivot_ingr_sql := '
                SELECT * FROM
                (
                    SELECT ''AÑO/MES'' AS rubro, val_ano, val_mes, concat(val_ano, concat(''/'', val_mes)) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_INGR_MES_INT_FACT''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Factor Ajuste'' AS rubro, val_ano, val_mes, TO_CHAR(val_fact_ajust) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_INGR_MES_INT_FACT''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Ingresos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_INGR_MES_INT_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                ';
                
            dbms_output.put_line(ln_pivot_ingr_sql);
                 
            OPEN p_ret_fact_ingr FOR ln_pivot_ingr_sql;
            
            
            -- EGRESOS
            ln_pivot_egre_sql := '
                SELECT * FROM
                (
                    SELECT ''AÑO/MES'' AS rubro, val_ano, val_mes, concat(val_ano, concat(''/'', val_mes)) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_EGRE_MES_INT_FACT''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Factor Ajuste'' AS rubro, val_ano, val_mes, TO_CHAR(val_fact_ajust) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_EGRE_MES_INT_FACT''
                ) 
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Egresos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_EGRE_MES_INT_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Combustible x Viaje'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_COMB_VIAJ_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Sueldo Chofer'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_SUEL_CHOF_VIAJ_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Sueldo Terramoza'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_SUEL_TERR_VIAJ_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Peaje x Viaje'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_PEAJE_VIAJ_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Otros'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OTROS_GAST_VIAJ_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Mantenimiento Gral.'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_MANT_GRAL_VEH_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Cuota Leasing'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CUOT_LEAS_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Otros Gastos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OTRO_GAST_INT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))';
            
            OPEN p_ret_fact_egre FOR ln_pivot_egre_sql;
            
            -- FLUJO DE CAJA
            ln_pivot_caja_sql := '
                SELECT * FROM
                (
                    SELECT ''AÑO/MES'' AS rubro, val_ano, val_mes, concat(val_ano, concat(''/'', val_mes)) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Caja Disponible'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Cuota Financiamiento'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CUOT_FINA_MES''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Caja Libre'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CAJA_LIBR_MES''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )';
            
            OPEN p_ret_fact_caja FOR ln_pivot_caja_sql;
            
        END IF;
        
        IF p_indi_tipo_fc = 'U' THEN
            
            dbms_output.put_line('entro en Urbano');
        
            -- PARA INGRESOS
            ln_pivot_ingr_sql := '
                SELECT * FROM
                (
                    SELECT ''AÑO/MES'' AS rubro, val_ano, val_mes, concat(val_ano, concat(''/'', val_mes)) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_ING_MES_FACT''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Factor Ajuste'' AS rubro, val_ano, val_mes, TO_CHAR(val_fact_ajust) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_ING_MES_FACT''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Ingresos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_ING_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Ruta'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_RUT_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Grifo'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OING_GRIFO_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Cotización'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OING_COTIZ_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Administración'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OING_ADM_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Boletaje'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OING_BOL_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Despacho'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OING_DESP_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Uniforme'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OING_UNIF_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''GPS'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OING_GPS_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Limpieza'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OING_LIMP_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                
                UNION ALL
                SELECT * FROM
                (
                SELECT  ''Reloj'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OING_RELO_MES_FACT''
                )
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                ';
                
            dbms_output.put_line(ln_pivot_ingr_sql);
                 
            OPEN p_ret_fact_ingr FOR ln_pivot_ingr_sql;
            
            dbms_output.put_line('Paso Ingresos');
            
            -- EGRESOS
            ln_pivot_egre_sql := '
                SELECT * FROM
                (
                    SELECT ''AÑO/MES'' AS rubro, val_ano, val_mes, concat(val_ano, concat(''/'', val_mes)) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_EGRE_URB_MES_FACT''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Factor Ajuste'' AS rubro, val_ano, val_mes, TO_CHAR(val_fact_ajust) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_EGRE_URB_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Egresos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_TOT_EGRE_URB_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Pago Personal'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_COMB_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Combustible'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_REND_KM_GALON_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Mantenimiento Gral'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_KM_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Precio Combustible'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_PREC_COMB_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Consumo Gasolina'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CONS_GAL_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Mantenimiento Unidad'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_MANT_PROP_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Kilometros Recorridos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_KM_PROP_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Costo Mantenimiento por Km'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_MANT_KM_PROP_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Gasto Personal'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_GAST_PERS_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Chofer'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CHOF_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Cobrador'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_COB_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Viáticos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_VIAT_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Peaje por Ruta'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_PEAJ_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Costo de Sistema'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_COST_RECA_FLOT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''GPS'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_GPS_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Soat'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_SOAT_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Cotización Diaria'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_COTI_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Otros Gastos'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_OGAST_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Cuota Leasing'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CUO_LEAS_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''IGV'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_IGV_COMP_RUT_MES_FACT''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))';
            
            OPEN p_ret_fact_egre FOR ln_pivot_egre_sql;
            
            -- FLUJO DE CAJA
            ln_pivot_caja_sql := '
                SELECT * FROM
                (
                    SELECT ''AÑO/MES'' AS rubro, val_ano, val_mes, concat(val_ano, concat(''/'', val_mes)) AS val_fact_ajust FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                )
                PIVOT
                (
                MAX(val_fact_ajust)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||'))
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Caja Disponible'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Cuota Financiamiento'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CUOT_FINA_MES''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )
                UNION ALL
                SELECT * FROM
                (
                    SELECT ''Caja Libre'' AS rubro, val_ano, val_mes, TO_CHAR(val_para) AS val_para FROM vve_cred_soli_fact_fc 
                    WHERE cod_soli_cred = ' || p_cod_soli_cred || ' AND cod_cred_para_fact = ''VAL_CAJA_LIBR_MES''
                ) 
                PIVOT
                (
                MAX(val_para)
                FOR (val_ano, val_mes) IN ('|| ln_conc_anos_cabe ||')
                )';
                
            dbms_output.put_line(ln_pivot_caja_sql);
            
            OPEN p_ret_fact_caja FOR ln_pivot_caja_sql;
        
        END IF;
        
        SELECT NVL(sum(val_para), 0) INTO v_sum_caja
        FROM vve_cred_soli_fact_fc 
        WHERE cod_soli_cred = p_cod_soli_cred 
        and cod_cred_para_fact = 'VAL_CAJA_DISP_MES';
        
        SELECT NVL(sum(val_para), 0) INTO v_sum_cuot
        FROM vve_cred_soli_fact_fc 
        WHERE cod_soli_cred = p_cod_soli_cred
        and cod_cred_para_fact = 'VAL_CUOT_FINA_MES';
        
        
        IF v_sum_caja > 0 AND v_sum_cuot > 0 THEN
        
            -- PARA FLUJO DE CAJA PROYECTADO
            v_cont_arr_cant_proy := 0;
            ln_conc_anos_cabe_proy := '';
    
            FOR rs_cobe IN (SELECT val_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                AND ind_tipo_fc = 'G' AND ind_tipo = 'A' ORDER BY val_ano) LOOP
                
                v_cont_arr_cant_proy := v_cont_arr_cant_proy + 1;    
                
                IF (v_cont_arr_cant_proy = 1) THEN
                    dbms_output.put_line('No tiene datos');
                    ln_conc_anos_cabe_proy := rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant_proy;
                    dbms_output.put_line('Primera concatenacion ' || ln_conc_anos_cabe_proy);
                ELSE
                    ln_conc_anos_cabe_proy := ln_conc_anos_cabe_proy || ',' || rs_cobe.val_ano || ' AS ANIO_' || v_cont_arr_cant_proy;
                    dbms_output.put_line('Siguiente concatenacion ' || ln_conc_anos_cabe_proy);
                END IF;
                
            END LOOP;
                    
            dbms_output.put_line(ln_conc_anos_cabe_proy); 
            
            IF ln_conc_anos_cabe_proy IS NOT NULL THEN
            
                dbms_output.put_line('Entro ln_conc_anos_cabe_proy != '); 
                
                /*
                OPEN p_ret_colu_ano FOR
                    SELECT val_ano AS num_ano FROM vve_cred_soli_fact_fc WHERE cod_soli_cred = p_cod_soli_cred 
                        AND ind_tipo_fc = 'G' AND ind_tipo = 'A' ORDER BY val_ano;
                */
                
                ln_pivot_sql_proy := 'SELECT * FROM
                    (
                        SELECT TO_NUMBER(TO_CHAR(SUM(x.val_sum_caja_disp) / SUM(x.val_sum_cuot_fina),''999999999999D99'')) num_ano, x.val_ano
                        FROM (
                           SELECT NVL(SUM(val_para), 0) val_sum_caja_disp, 0 val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CAJA_DISP_MES''
                           GROUP BY val_ano
                           UNION ALL
                           SELECT 0 val_sum_caja_disp, NVL(SUM(val_para), 0) val_sum_cuot_fina, val_ano
                           FROM vve_cred_soli_fact_fc
                           WHERE cod_soli_cred = ' || p_cod_soli_cred || '
                           AND cod_cred_para_fact = ''VAL_CUOT_FINA_MES''
                           GROUP BY val_ano
                        ) x
                        GROUP BY x.val_ano
                    )
                    PIVOT
                    (
                    MAX(num_ano)
                    FOR val_ano IN (' || ln_conc_anos_cabe_proy || ')
                    )';
            
            
                OPEN p_ret_fc_proy FOR ln_pivot_sql_proy;
            
            END IF;
        
        END IF;

        
        p_ret_esta := 1;
        p_ret_mens := 'Se realizó el proceso satisfactoriamente';
    
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_REPO_FLUJ_CAJA', p_cod_usua_sid, 
            'Error al consultar los parametros de Flujo de Caja '||p_cod_soli_cred
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := p_ret_mens||'SP_REPO_FLUJ_CAJA:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_REPO_FLUJ_CAJA', p_cod_usua_sid, 
            'Error al consultar los parametros de Flujo de Caja'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
         
    END sp_repo_fluj_caja;

  --<I Obs. 266 - Se agrego listado de datos del flujo de caja>  
  PROCEDURE sp_obte_info_fc
  (
     p_cod_soli_cred IN  vve_cred_soli.cod_soli_cred%TYPE,
     p_cod_usua_sid  IN  sistemas.usuarios.co_usuario%TYPE,
     p_ret_cursor    OUT SYS_REFCURSOR, 
     p_ret_esta      OUT NUMBER,
     p_ret_mens      OUT VARCHAR2    
  ) AS
  BEGIN

    OPEN p_ret_cursor FOR
        SELECT ind_tipo_fc 
        FROM vve_cred_soli_fact_fc
        WHERE cod_soli_cred = p_cod_soli_cred
            AND ROWNUM = 1;

    p_ret_esta := 1;
    p_ret_mens := 'Se realizó la consulta satisfactoriamente';

  EXCEPTION
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := p_ret_mens||'SP_OBTE_CRED_SOLI_FC:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 
            'SP_OBTE_CRED_SOLI_FC', 
            p_cod_usua_sid, 
            'Error al consultar los parametros de Flujo de Caja', 
            p_ret_mens, 
            p_cod_soli_cred);
  END sp_obte_info_fc;
  --<F Obs. 266 - Se agrego listado de datos del flujo de caja>         
    
END PKG_SWEB_CRED_SOLI_FLUJO_CAJA; 