create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_GARANTIA AS
PROCEDURE sp_list_garantia
  (
    p_cod_soli_cred     IN vve_cred_soli_gara.cod_soli_cred%TYPE,
    p_ind_tipo_garantia IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    PRAGMA AUTONOMOUS_TRANSACTION; 
    cantidad_registros  NUMBER;
    v_cod_garantia      vve_cred_maes_gara.cod_garantia%TYPE;
    v_ind_adicional     VARCHAR2(1);
    v_estado_inactivo   VARCHAR2(1);
    v_cantidad_veh_ins  NUMBER;
    v_can_veh_fin_aux   NUMBER;
    v_area_vta          vve_proforma_veh.cod_area_vta%type;
    v_no_cia            vve_proforma_veh.cod_cia%type;
    v_familia_veh       vve_proforma_veh_det.cod_familia_veh%type;
    v_tipo_veh          vve_proforma_veh_det.cod_tipo_veh%type;
    v_val_pre_veh       vve_proforma_veh_det.val_pre_veh%type;
    v_val_porc_depr     vve_cred_mae_depr.val_porc_depr%type;
    v_tipo_cred_ok      varchar2(1) := 'N';
    v_cantidad_veh_del  NUMBER;
    v_can_gara_fina_ins vve_cred_soli_prof.can_veh_fin%type;
    i                   NUMBER;
    v_cod_soli_cred VARCHAR2(20);
    v_num_prof_veh VARCHAR2(10);
    v_can_veh_fin  NUMBER;
    v_ano_fab      number;

  CURSOR cproformas IS
   SELECT cod_soli_cred ,num_prof_veh ,can_veh_fin 
   FROM vve_cred_soli_prof
   WHERE cod_soli_cred = p_cod_soli_cred
   AND   ind_inactivo = 'N';

  BEGIN
    v_estado_inactivo:= 'S';
    v_ind_adicional := 'N';

     BEGIN 
      SELECT 'S'
      INTO   v_tipo_cred_ok -- S: Cuando Reconocimiento de Deuda, N: cuando no es reconocimiento de deuda 
      FROM   vve_cred_soli s 
      WHERE  0 < (SELECT INSTR(val_para_car,s.tip_soli_cred) 
                 FROM   vve_cred_soli_para 
                 WHERE cod_cred_soli_para = 'TIPCREDGARFIN') 
      AND s.cod_soli_cred = p_cod_soli_cred;    
   EXCEPTION 
     WHEN NO_DATA_FOUND THEN 
       v_tipo_cred_ok := 'N';
   END;

     SELECT COUNT(*)
     INTO   cantidad_registros
     FROM   vve_cred_soli_gara sg, vve_cred_maes_gara mg
     WHERE  sg.cod_soli_cred = p_cod_soli_cred
     AND    sg.ind_inactivo = 'N'
     AND    sg.cod_gara = mg.cod_garantia 
     AND    sg.ind_gara_adic = 'N' 
     AND    mg.ind_tipo_garantia = 'M'; 
     --and cond <> leasin, mutuo

     SELECT SUM(CAN_VEH_FIN)
     INTO v_can_veh_fin_aux
     FROM vve_cred_soli_prof
     WHERE cod_soli_cred=p_cod_soli_cred
     and ind_inactivo = 'N';

     IF v_tipo_cred_ok = 'S' THEN

        FOR c_lista in cproformas loop

          select cod_area_vta,cod_cia 
          into   v_area_vta,v_no_cia
          from vve_proforma_veh 
          where num_prof_veh = c_lista.num_prof_veh; 

          select cod_familia_veh,val_pre_veh,cod_tipo_veh 
          into   v_familia_veh,v_val_pre_veh,v_tipo_veh
          from vve_proforma_veh_det 
          where num_prof_veh = c_lista.num_prof_veh;

          select val_porc_depr 
          into   v_val_porc_depr
          from vve_cred_mae_depr 
          where val_can_anos = 0 
          and   no_cia = v_no_cia 
          and   cod_area_vta = v_area_vta  
          and   cod_familia_veh = v_familia_veh  
          and   cod_tipo_veh = v_tipo_veh;     

          BEGIN
            SELECT DISTINCT nvl(ano_modelo_veh,ano_fabricacion_veh)
            INTO   v_ano_fab
            FROM   vve_pedido_veh 
            WHERE  num_prof_veh = c_lista.num_prof_veh; 
          EXCEPTION 
            WHEN NO_DATA_FOUND THEN 
              v_ano_fab := to_number(to_char(sysdate,'yyyy'));
          END;

          v_cantidad_veh_ins := 0;
          v_cantidad_veh_del := 0;
          -- Obtener la cantidad de garantias financiadas por proformas que ya existen
          SELECT COUNT(*)
          INTO   v_can_gara_fina_ins 
          FROM   vve_cred_maes_gara mg, vve_cred_soli_gara sg
          WHERE  sg.cod_soli_cred = p_cod_soli_cred  
          AND    sg.cod_gara = mg.cod_garantia
          AND    mg.num_proforma_veh = c_lista.num_prof_veh 
          AND    sg.ind_inactivo = 'N'
          AND    sg.ind_gara_adic = 'N';

          IF c_lista.can_veh_fin > v_can_gara_fina_ins THEN
            -- Si la cantidad de garantias insertadas por proforma es menor o igual al indicado por proforma a financiar
            -- Se obtiene la cantidad de garantias a insertar por proforma
            v_cantidad_veh_ins := c_lista.can_veh_fin - v_can_gara_fina_ins;
          ELSE 
            -- Si la cantidad de garantias insertadas por proforma es mayor que lo indicado por proforma
            -- Se obtiene la cantidad de garantias a eliminar por proforma
            v_cantidad_veh_del := v_can_gara_fina_ins - c_lista.can_veh_fin;
          END IF;

          IF v_cantidad_veh_ins > 0 THEN -- se inserta    
          --for i in 1 .. v_cantidad_veh_ins loop
            i := 0;
            LOOP
            SELECT LPAD(NVL(MAX(TO_NUMBER(cod_garantia)),0)+1,10,'0')
             INTO v_cod_garantia
            FROM vve_cred_maes_gara;

            INSERT INTO vve_cred_maes_gara (cod_garantia,
                                            ind_tipo_garantia,
                                            ind_tipo_bien,--constitucionGM
                                            ind_otor,--otorgante
                                            ind_adicional,--ind_adicional
                                            cod_pers_prop,--codigo persona
                                            cod_cliente,
                                            cod_marca,
                                            txt_modelo,
                                            cod_tipo_veh,
                                            nro_motor,
                                            nro_chasis,
                                            val_nro_rango,
                                            nro_placa,--vpv.NUM_PLACA_VEH
                                            val_const_gar,--pvd.VAL_PRE_VEH?valor constituido
                                            val_realiz_gar,--(pvd.VAL_PRE_VEH*0.8)-20% ?valor realizable
                                            val_ano_fab,
                                            num_pedido_veh,
                                            num_proforma_veh)   
             SELECT  v_cod_garantia  cod_garantia,
                    'M'             ind_tipo_garantia,   
                    'A'             ind_tipo_bien,--'Ajeno/Futuro'
                    'D'             ind_otor,--'Deudor'
                    'N'             ind_adicional,
                    sc.cod_clie cod_pers_prop,
                    sc.cod_clie cod_cliente,  
                    (SELECT pvd.cod_marca FROM vve_proforma_veh_det pvd WHERE pvd.num_prof_veh = c_lista.num_prof_veh )cod_marca,
                    (SELECT b.des_baumuster
                      FROM vve_baumuster b
                      INNER JOIN vve_proforma_veh_det vpv  ON vpv.num_prof_veh = c_lista.num_prof_veh AND vpv.cod_baumuster = b.cod_baumuster AND vpv.cod_marca = b.cod_marca ) txt_modelo,
                    (SELECT pvd.cod_tipo_veh FROM vve_proforma_veh_det pvd WHERE pvd.num_prof_veh = c_lista.num_prof_veh )cod_tipo_veh,
                    NULL AS nro_motor,
                    NULL AS nro_chasis,
                     'RG01'                  val_nro_rango,
                    NULL AS nro_placa,
                    --(SELECT pvd.VAL_PRE_VEH FROM vve_proforma_veh_det pvd WHERE pvd.num_prof_veh = v_num_prof_veh )val_const_gar,
                    --(SELECT (pvd.VAL_PRE_VEH*0.8) FROM vve_proforma_veh_det pvd WHERE pvd.num_prof_veh = c_lista.num_prof_veh )val_realiz_gar,
                    v_val_pre_veh*v_val_porc_depr val_const_gar,
                    v_val_pre_veh*v_val_porc_depr val_realiz_gar,
                    v_ano_fab AS val_ano_fab,
                    NULL AS num_pedido_veh,
                    c_lista.num_prof_veh                           
               FROM vve_cred_soli sc
               INNER JOIN gen_persona gp ON gp.cod_perso = sc.cod_clie
               WHERE sc.cod_soli_cred = c_lista.cod_soli_cred;

            INSERT INTO vve_cred_soli_gara (cod_soli_cred,
                                            cod_gara,
                                            fec_reg_gara,
                                            ind_gara_adic,
                                            cod_rang_gar
                                  ) VALUES (c_lista.cod_soli_cred,
                                            v_cod_garantia,
                                            SYSDATE,
                                            v_ind_adicional,
                                            'RG01'
                                            ); 
             i := i + 1; 
             EXIT WHEN i = v_cantidad_veh_ins;
           END LOOP;           
          END IF;        
          --CLOSE cproformas;      
          IF v_cantidad_veh_del > 0 THEN -- Se eliminan
            delete vve_cred_soli_gara 
            where cod_gara in (select cod_garantia 
                               from vve_cred_maes_gara 
                               where num_proforma_veh = c_lista.num_prof_veh 
                               and ind_adicional = 'N') 
            and cod_soli_cred = p_cod_soli_cred 
            and ind_inactivo  = 'N'
            and rownum <=v_cantidad_veh_del;

            delete vve_cred_maes_gara 
            where cod_garantia not in (select cod_gara 
                                       from vve_cred_soli_gara 
                                       where cod_gara = cod_garantia 
                                       and ind_gara_adic = 'N' 
                                       and cod_soli_cred = p_cod_soli_cred) 
            and num_proforma_veh = c_lista.num_prof_veh  
            and ind_adicional    = 'N';
          END IF;         
        END LOOP;

        FOR c in (SELECT cod_soli_cred ,num_prof_veh ,can_veh_fin 
                   FROM vve_cred_soli_prof
                   WHERE cod_soli_cred = p_cod_soli_cred
                   AND   ind_inactivo = 'S') 
        LOOP 
              delete vve_cred_soli_gara 
              where cod_gara in (select cod_garantia 
                                 from vve_cred_maes_gara 
                                 where num_proforma_veh = c.num_prof_veh
                                 and ind_adicional = 'N') 
              and cod_soli_cred = p_cod_soli_cred;

              delete vve_cred_maes_gara 
              where cod_garantia not in (select cod_gara 
                                         from vve_cred_soli_gara 
                                         where cod_gara = cod_garantia 
                                         and ind_gara_adic = 'N' 
                                         and cod_soli_cred = p_cod_soli_cred) 
              and num_proforma_veh = c.num_prof_veh  
              and ind_adicional    = 'N';
        END LOOP;

    END IF;

    OPEN p_ret_cursor FOR
    SELECT  cod_garantia,
        mg.cod_marca AS MARCA,
        mg.txt_modelo AS MODELO,
        mg.cod_tipo_veh AS TIPO_VEHICULO,
        mg.txt_carroceria AS CARROCERIA,
        mg.val_ano_fab AS ANHO_FABRICACION,
        mg.nro_motor AS MOTOR,
        mg.val_realiz_gar,
        mg.val_const_gar,
        -- (SELECT  PKG_SWEB_CRED_SOLI_GARANTIA.fn_obt_val_const_depr (p_cod_soli_cred,cod_garantia, mg.cod_tipo_veh,'A') FROM DUAL) val_const_gar,
        mg.val_mont_otor_hip,
        mg.nro_placa,
        mg.nro_chasis,
        mg.val_nro_rango,
        mg.cod_tipo_actividad,
        mg.tipo_actividad,
        mg.cod_tipo_veh,
        mg.cod_pers_prop,
        mg.txt_direccion,
        mg.cod_departamento,
        mg.cod_provincia,
        mg.cod_distrito,
        (CASE ind_otor 
           WHEN 'D' THEN 
                (SELECT descripcion FROM vve_tabla_maes t INNER JOIN gen_persona g ON (g.cod_tipo_perso = t.valor_adic_1)
                 WHERE t.cod_grupo = '105' AND g.cod_perso = mg.cod_pers_prop) 
           ELSE 
              (SELECT (CASE cma.ind_tipo_persona 
                WHEN 'J' THEN 'JURIDICA'
                WHEN 'N' THEN 'NATURAL' 
                ELSE '' 
                END)       
                FROM vve_cred_mae_aval cma
                INNER JOIN vve_cred_soli_aval csa ON csa.cod_per_aval = cma.cod_per_aval and csa.cod_per_aval= mg.cod_pers_prop
                WHERE csa.cod_soli_cred=p_cod_soli_cred) 
           END     
        )AS tipo_persona,        
       (CASE ind_otor 
           WHEN 'D' THEN 
            (SELECT descripcion FROM vve_tabla_maes t INNER JOIN gen_persona g ON g.cod_estado_civil = t.valor_adic_1
             WHERE t.cod_grupo = '104' AND g.cod_perso = mg.cod_pers_prop)
           ELSE 
              (SELECT (CASE cma.ind_esta_civil 
                WHEN 'S' THEN 'SOLTERO'
                WHEN 'C' THEN 'CASADO' 
                WHEN 'O' THEN 'CONVIVIENTE' 
                WHEN 'D' THEN 'DIVORCIADO' 
                WHEN 'V' THEN 'VIUDO' 
                ELSE '' 
                END)      
                FROM vve_cred_mae_aval cma
                INNER JOIN vve_cred_soli_aval csa ON csa.cod_per_aval = cma.cod_per_aval and csa.cod_per_aval= mg.cod_pers_prop
                WHERE csa.cod_soli_cred=p_cod_soli_cred) 
         END       
        )AS estado_civil,
        (SELECT nom_marca AS descripcion FROM gen_marca m WHERE m.cod_marca = mg.cod_marca) AS DES_MARCA,
        (SELECT t.descripcion FROM vve_tabla_maes t WHERE t.cod_grupo = '106' AND t.cod_tipo = mg.val_nro_rango) AS DES_RANGO,
        (SELECT descripcion from vve_tabla_maes where cod_grupo = '111' and valor_adic_1 = mg.cod_tipo_actividad) AS DES_ACTIVIDAD,
        --(SELECT ta.des_tipo_actividad AS descripcion FROM vve_credito_tipo_actividad ta WHERE ta.cod_tipo_actividad = mg.cod_tipo_actividad) AS DES_ACTIVIDAD,
        (SELECT des_tipo_veh AS descripcion FROM vve_tipo_veh ve WHERE ve.cod_tipo_veh = mg.cod_tipo_veh) AS DES_TIPO_VEH,
        (CASE WHEN ind_otor='F' 
            THEN (SELECT txt_nomb_pers||' '||txt_apel_pate_pers||' '||txt_apel_mate_pers as nombre_completo 
            FROM vve_cred_mae_aval WHERE cod_per_aval = mg.cod_pers_prop)
        ELSE (SELECT nom_perso FROM gen_persona WHERE cod_perso = mg.cod_pers_prop) END) AS DES_PERS_PROP,
        (SELECT des_nombre AS descripcion FROM gen_mae_departamento WHERE cod_id_departamento = mg.cod_departamento) AS departamento,
        (SELECT des_nombre AS descripcion FROM gen_mae_provincia WHERE cod_id_provincia = mg.cod_provincia) AS provincia,
        (SELECT des_nombre AS descripcion FROM gen_mae_distrito WHERE cod_id_distrito = mg.cod_distrito) AS distrito,
        (SELECT valor_adic_1 FROM vve_tabla_maes WHERE cod_grupo = '102' AND valor_adic_1 = ind_tipo_bien) IND_TIPO_BIEN,
        (SELECT descripcion FROM vve_tabla_maes WHERE cod_grupo = '102' AND valor_adic_1 = ind_tipo_bien) DES_TIPO_BIEN,
        (SELECT valor_adic_1 FROM vve_tabla_maes WHERE cod_grupo = '103' AND valor_adic_1 = ind_otor) AS IND_OTOR,
        (SELECT descripcion FROM vve_tabla_maes WHERE cod_grupo = '103' AND valor_adic_1 = ind_otor) AS DES_OTOR,
        mg.num_pedido_veh,
        mg.cod_of_registral,
        sc.tip_soli_cred,
        (SELECT t.descripcion FROM vve_tabla_maes t WHERE t.cod_grupo = '86' AND t.cod_tipo = sc.tip_soli_cred) AS DES_TIPO_CRED,
        mg.ind_adicional
        --sc.in_gara_adic
       FROM vve_cred_maes_gara mg INNER JOIN vve_cred_soli_gara sg ON sg.cod_gara = mg.cod_garantia
                                  INNER JOIN vve_cred_soli sc ON sg.cod_soli_cred = sc.cod_soli_cred
      WHERE sg.cod_soli_cred = p_cod_soli_cred
        AND mg.ind_tipo_garantia = p_ind_tipo_garantia
        AND (sg.ind_inactivo IS NULL OR sg.ind_inactivo<>v_estado_inactivo)
       -- AND sc.ind_inactivo<>v_estado_inactivo
    ORDER BY cod_garantia;

    COMMIT;

    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';

  EXCEPTION
    WHEN OTHERS THEN
      p_ret_esta := -1;
      p_ret_mens := 'sp_list_garantia:' || SQLERRM;        
      ROLLBACK;

  END sp_list_garantia;

  PROCEDURE sp_ins_gara_soli
  (
     p_cod_soli_cred        vve_cred_soli_even.cod_soli_cred%TYPE,
     p_cod_garantia         VARCHAR2,
     p_ind_tipo_garantia    VARCHAR2,
     p_ind_tipo_bien        VARCHAR2,
     p_ind_otor             VARCHAR2,
     p_cod_pers_prop        VARCHAR2,
     p_cod_marca            VARCHAR2,
     p_txt_marca            VARCHAR2,
     p_txt_modelo           VARCHAR2,
     p_cod_tipo_veh         VARCHAR2,
     p_nro_motor            VARCHAR2,
     p_txt_carroceria       VARCHAR2,
     p_fec_fab_const        VARCHAR2,
     p_nro_chasis           VARCHAR2,
     p_val_nro_rango        VARCHAR2,
     p_nro_placa            VARCHAR2,
     p_tipo_actividad       VARCHAR2,
     p_val_const_gar        NUMBER,
     p_val_realiz_gar       NUMBER,
     p_cod_of_registral     NUMBER,
     p_val_anos_deprec      VARCHAR2,
     p_cod_moneda           VARCHAR2,
     p_des_descripcion      VARCHAR2,
     p_ind_adicional        VARCHAR2,
     p_num_titulo_rpv       VARCHAR2,
     p_nro_tarj_prop_veh    VARCHAR2,
     p_nro_partida          VARCHAR2,
     p_ind_reg_mob_contratos VARCHAR2,
     p_ind_reg_jur_bien     VARCHAR2,
     p_txt_info_mod_gar     VARCHAR2,
     p_ind_ratifica_gar     VARCHAR2,
     p_val_nvo_monto        NUMBER,
     p_val_nvo_val          NUMBER,
     p_val_mont_otor_hip    NUMBER,
     p_txt_direccion        VARCHAR2,
     p_cod_distrito         VARCHAR2,
     p_cod_provincia        VARCHAR2,
     p_cod_departamento     VARCHAR2,
     p_cod_cliente          VARCHAR2,
     p_nuevo                VARCHAR2,
     p_val_ano_fab          VARCHAR2,
     p_num_pedido_veh       VARCHAR2,
     p_cod_usua_sid         IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web         IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_cod_garantia_out     OUT VARCHAR2,
     p_ret_esta             OUT NUMBER,
     p_ret_mens             OUT VARCHAR2
  ) AS
     v_cod_garantia      vve_cred_maes_gara.cod_garantia%TYPE;
     v_ind_adicional     VARCHAR2(1);
  BEGIN
    v_ind_adicional := 'S';
        IF p_nuevo = 'S' THEN
        IF p_cod_garantia IS NULL THEN


            SELECT LPAD(NVL(MAX(cod_garantia),0)+1,10,'0')
              INTO v_cod_garantia
              FROM vve_cred_maes_gara;

            INSERT INTO vve_cred_maes_gara (cod_garantia,
                                            ind_tipo_garantia,
                                            ind_tipo_bien,--constitucionGM
                                            ind_otor,--otorgante
                                            cod_pers_prop,
                                            cod_marca,
                                            txt_marca,
                                            txt_modelo,
                                            cod_tipo_veh,
                                            nro_motor,
                                            txt_carroceria,
                                            fec_fab_const,
                                            nro_chasis,
                                            val_nro_rango,
                                            nro_placa,
                                            tipo_actividad,
                                            val_const_gar,
                                            val_realiz_gar,
                                            cod_of_registral,
                                            val_anos_deprec,
                                            cod_moneda,
                                            des_descripcion,
                                            ind_adicional,
                                            num_titulo_rpv,
                                            nro_tarj_prop_veh,
                                            nro_partida,
                                            ind_reg_mob_contratos,
                                            ind_reg_jur_bien,
                                            txt_info_mod_gar,
                                            ind_ratifica_gar,
                                            val_nvo_monto,
                                            val_nvo_val,
                                            val_mont_otor_hip,
                                            txt_direccion,
                                            cod_distrito,
                                            cod_provincia,
                                            cod_departamento,
                                            cod_cliente,
                                            val_ano_fab,
                                            num_pedido_veh,
                                            cod_usua_crea_regi,
                                            fec_crea_regi)
                                    VALUES  (v_cod_garantia,--p_cod_garantia,
                                             p_ind_tipo_garantia,
                                             p_ind_tipo_bien,
                                             p_ind_otor,
                                             p_cod_pers_prop,
                                             p_cod_marca,
                                             p_txt_marca,
                                             p_txt_modelo,
                                             p_cod_tipo_veh,
                                             p_nro_motor,
                                             p_txt_carroceria,
                                             p_fec_fab_const,
                                             p_nro_chasis,
                                             p_val_nro_rango,
                                             p_nro_placa,
                                             p_tipo_actividad,
                                             p_val_const_gar,
                                             p_val_realiz_gar,
                                             p_cod_of_registral,
                                             p_val_anos_deprec,
                                             p_cod_moneda,
                                             p_des_descripcion,
                                             v_ind_adicional,
                                             p_num_titulo_rpv,
                                             p_nro_tarj_prop_veh,
                                             p_nro_partida,
                                             p_ind_reg_mob_contratos,
                                             p_ind_reg_jur_bien,
                                             p_txt_info_mod_gar,
                                             p_ind_ratifica_gar,
                                             p_val_nvo_monto,
                                             p_val_nvo_val,
                                             p_val_mont_otor_hip,
                                             p_txt_direccion,
                                             p_cod_distrito,
                                             p_cod_provincia,
                                             p_cod_departamento,
                                             p_cod_cliente,
                                             TO_NUMBER(p_val_ano_fab),
                                             p_num_pedido_veh,
                                             p_cod_usua_web,
                                             SYSDATE);

            INSERT INTO vve_cred_soli_gara (cod_soli_cred,
                                            cod_gara,
                                            fec_reg_gara,
                                            ind_gara_adic,
                                            cod_rang_gar,
                                            ind_inactivo,
                                            cod_usua_crea_regi,
                                            fec_crea_regi)
                                    VALUES (p_cod_soli_cred,
                                            v_cod_garantia,
                                            SYSDATE,
                                            v_ind_adicional,
                                            NULL,
                                            'N',
                                            p_cod_usua_web,
                                            SYSDATE);

        ELSE
            UPDATE vve_cred_maes_gara
               SET ind_tipo_garantia = p_ind_tipo_garantia,
                   ind_tipo_bien = p_ind_tipo_bien,
                   ind_otor = p_ind_otor,
                   cod_pers_prop = p_cod_pers_prop,
                   cod_marca = p_cod_marca,
                   txt_marca = p_txt_marca,
                   txt_modelo = p_txt_modelo,
                   cod_tipo_veh = p_cod_tipo_veh,
                   nro_motor = p_nro_motor,
                   txt_carroceria = p_txt_carroceria,
                   fec_fab_const = p_fec_fab_const,
                   nro_chasis = p_nro_chasis,
                   val_nro_rango = p_val_nro_rango,
                   nro_placa = p_nro_placa,
                   tipo_actividad = p_tipo_actividad,
                   val_const_gar = p_val_const_gar,
                   val_realiz_gar = p_val_realiz_gar,
                   cod_of_registral = p_cod_of_registral,
                   val_anos_deprec = p_val_anos_deprec,
                   cod_moneda = p_cod_moneda,
                   des_descripcion = p_des_descripcion,
                   ind_adicional = v_ind_adicional,
                   num_titulo_rpv = p_num_titulo_rpv,
                   nro_tarj_prop_veh = p_nro_tarj_prop_veh,
                   nro_partida = p_nro_partida,
                   ind_reg_mob_contratos = p_ind_reg_mob_contratos,
                   ind_reg_jur_bien = p_ind_reg_jur_bien,
                   txt_info_mod_gar = p_txt_info_mod_gar,
                   ind_ratifica_gar = p_ind_ratifica_gar,
                   val_nvo_monto = p_val_nvo_monto,
                   val_nvo_val = p_val_nvo_val,
                   val_mont_otor_hip = p_val_mont_otor_hip,
                   txt_direccion = p_txt_direccion,
                   cod_distrito = p_cod_distrito,
                   cod_provincia = p_cod_provincia,
                   cod_departamento = p_cod_departamento,
                   cod_cliente = p_cod_cliente,
                   val_ano_fab = TO_NUMBER(p_val_ano_fab),
                   num_pedido_veh = p_num_pedido_veh,
                   cod_usua_modi_regi = p_cod_usua_web,
                   fec_modi_regi = SYSDATE
            WHERE cod_garantia = p_cod_garantia;


        END IF;

      COMMIT;

    END IF;
    IF p_nuevo = 'R' THEN
        INSERT INTO vve_cred_soli_gara (cod_soli_cred,
                                        cod_gara,
                                        fec_reg_gara,
                                        ind_gara_adic,
                                        cod_rang_gar,
                                        ind_inactivo,
                                        cod_usua_crea_regi,
                                        fec_crea_regi)
                                VALUES (p_cod_soli_cred,
                                        p_cod_garantia,
                                        SYSDATE,
                                        NULL,
                                        NULL,
                                        'N',
                                        p_cod_usua_web,
                                        SYSDATE);  

      COMMIT;

    END IF;
    p_cod_garantia_out := v_cod_garantia;
    p_ret_esta := 1;
    p_ret_mens := 'La transaccion se realizó de manera exitosa';

    -- Actualizando fecha de ejecución de registro y verificando cierre de etapa
    PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E2','A12',p_cod_usua_sid,p_ret_esta,p_ret_mens); 

  END sp_ins_gara_soli;

  PROCEDURE sp_list_garantia_histo
  (
    p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
    p_ind_tipo_garantia IN vve_cred_maes_gara.ind_tipo_garantia%TYPE,
    p_cod_cliente       IN vve_cred_maes_gara.cod_cliente%TYPE,
    p_num_pedido_veh    IN vve_pedido_veh.num_pedido_veh%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
    v_rango             vve_cred_maes_gara.val_nro_rango%TYPE;
    v_estado_inactivo   VARCHAR2(10);
  BEGIN
    v_rango := 'RG01';
    v_estado_inactivo:= 'S';
    OPEN p_ret_cursor FOR
     /*SELECT cod_garantia,
            ind_tipo_garantia,
            ind_tipo_bien,
            ind_otor,
            cod_pers_prop,
            cod_marca,
            txt_modelo,
            cod_tipo_veh,
            nro_motor,
            txt_carroceria,
            fec_fab_const,
            nro_chasis,
            val_nro_rango,
            nro_placa,
            cod_tipo_actividad,
            val_const_gar,
            val_realiz_gar,
            cod_of_registral,
            val_anos_deprec,
            cod_moneda,
            des_descripcion,
            ind_adicional,
            num_titulo_rpv,
            nro_tarj_prop_veh,
            nro_partida,
            ind_reg_mob_contratos,
            ind_reg_jur_bien,
            txt_info_mod_gar,
            ind_ratifica_gar,
            val_nvo_monto,
            val_nvo_val,
            val_mont_otor_hip,
            txt_direccion,
            cod_distrito,
            cod_provincia,
            cod_departamento,
            cod_cliente,
            txt_marca,
            s.cod_oper_rel,
            (CASE WHEN ind_tipo_garantia='M' THEN 'Mobiliaria' ELSE 'Hipoticaria' END)  tipo_garantia_desc,
            val_ano_fab,
            (SELECT nom_marca AS descripcion FROM gen_marca m WHERE m.cod_marca=mg.cod_marca) AS des_marca,
            (SELECT t.descripcion FROM vve_tabla_maes t WHERE t.cod_grupo = '106' AND t.cod_tipo = val_nro_rango) AS des_rango,
            (SELECT ta.des_tipo_actividad AS descripcion FROM vve_credito_tipo_actividad ta
              WHERE ta.cod_tipo_actividad = mg.cod_tipo_actividad) des_actividad,
            (SELECT des_tipo_veh AS descripcion FROM vve_tipo_veh ve WHERE ve.cod_tipo_veh = mg.cod_tipo_veh) des_tipo_veh,
            (SELECT nom_perso FROM gen_persona WHERE cod_perso=mg.cod_pers_prop) des_pers_prop,
            (SELECT des_nombre AS descripcion FROM gen_mae_distrito WHERE cod_id_distrito=cod_distrito) AS distrito,
            (SELECT des_nombre AS descripcion FROM gen_mae_provincia WHERE cod_id_provincia=cod_provincia) AS provincia,
            (SELECT des_nombre AS descripcion FROM gen_mae_departamento WHERE cod_id_departamento=cod_departamento) AS departamento,
            --CONSTITUCION GH  OTORGANTE  TIPO PERSONA  EST.CIVIL
            (SELECT descripcion FROM vve_tabla_maes WHERE cod_grupo = '102' AND valor_adic_1 = ind_tipo_bien) tipo_bien,
            (SELECT descripcion FROM vve_tabla_maes WHERE cod_grupo = '103' AND valor_adic_1 = ind_tipo_bien) tipo_otorgante,    
            (SELECT descripcion FROM vve_tabla_maes t INNER JOIN gen_persona g ON (g.cod_tipo_perso = t.valor_adic_1)
             WHERE t.cod_grupo = '105' AND g.cod_perso = mg.cod_pers_prop) AS tipo_persona,
            (SELECT descripcion FROM vve_tabla_maes t INNER JOIN gen_persona g ON (NVL(g.cod_estado_civil,'S') = t.valor_adic_1)
              WHERE t.cod_grupo = '104' AND g.cod_perso = mg.cod_pers_prop) AS estado_civil   
 FROM vve_cred_maes_gara mg
 INNER JOIN vve_cred_soli_gara sg ON (mg.cod_garantia=sg.cod_gara)
 INNER JOIN vve_cred_soli s ON (sg.cod_soli_cred=s.cod_soli_cred)
      WHERE (p_ind_tipo_garantia IS NULL OR (mg.ind_tipo_garantia = p_ind_tipo_garantia))
        AND (s.ind_inactivo IS NULL OR (s.ind_inactivo<>v_estado_inactivo))
        AND ((ind_adicional = 'S') OR (ind_adicional = 'N' AND mg.val_nro_rango IS NULL))--= v_rango))
        AND mg.cod_cliente = p_cod_cliente
        AND sg.cod_soli_cred<>p_cod_soli_cred;*/

        SELECT  g.cod_garantia, 
                g.ind_tipo_garantia,
                g.ind_tipo_bien,
                g.ind_otor,
                g.cod_pers_prop,
                g.cod_marca,
                g.txt_modelo,
                g.cod_tipo_veh,
                g.nro_motor,
                g.txt_carroceria,
                g.fec_fab_const,
                g.nro_chasis,
                g.val_nro_rango,
                g.nro_placa,
                g.cod_tipo_actividad,
                g.val_const_gar,
                --(SELECT  PKG_SWEB_CRED_SOLI_GARANTIA.fn_obt_val_const_depr (p_cod_soli_cred,g.cod_garantia, g.cod_tipo_veh,'F') FROM DUAL) val_const_gar,
                (g.val_realiz_gar - (TO_NUMBER(EXTRACT(YEAR FROM sysdate) - g.val_ano_fab) / 100) * g.val_realiz_gar) as val_realiz_gar,
                g.cod_of_registral,
                g.val_anos_deprec,
                g.cod_moneda,
                g.des_descripcion,
                g.ind_adicional,
                g.num_titulo_rpv,
                g.nro_tarj_prop_veh,
                g.nro_partida,
                g.ind_reg_mob_contratos,
                g.ind_reg_jur_bien,
                g.txt_info_mod_gar,
                g.ind_ratifica_gar,
                g.val_nvo_monto,
                g.val_nvo_val,
                g.val_mont_otor_hip,
                g.txt_direccion,
                g.cod_distrito,
                g.cod_provincia,
                g.cod_departamento,
                g.cod_cliente,
                g.txt_marca,
                s.cod_oper_rel,
                (CASE WHEN g.ind_tipo_garantia='M' THEN 'Mobiliaria' ELSE 'Hipotecaria' END)  tipo_garantia_desc,
                g.val_ano_fab,
                (SELECT nom_marca AS descripcion FROM gen_marca m WHERE m.cod_marca= g.cod_marca) AS des_marca,
                (SELECT t.descripcion FROM vve_tabla_maes t WHERE t.cod_grupo = '106' AND t.cod_tipo = g.val_nro_rango) AS des_rango,
                (SELECT ta.des_tipo_actividad AS descripcion FROM vve_credito_tipo_actividad ta
                  WHERE ta.cod_tipo_actividad = g.cod_tipo_actividad) des_actividad,
                (SELECT des_tipo_veh AS descripcion FROM vve_tipo_veh ve WHERE ve.cod_tipo_veh = g.cod_tipo_veh) des_tipo_veh,
                (SELECT nom_perso FROM gen_persona WHERE cod_perso = g.cod_pers_prop) des_pers_prop,
                (SELECT des_nombre AS descripcion FROM gen_mae_distrito WHERE cod_id_distrito = g.cod_distrito) AS distrito,
                (SELECT des_nombre AS descripcion FROM gen_mae_provincia WHERE cod_id_provincia = g.cod_provincia) AS provincia,
                (SELECT des_nombre AS descripcion FROM gen_mae_departamento WHERE cod_id_departamento = g.cod_departamento) AS departamento,
                (SELECT descripcion FROM vve_tabla_maes WHERE cod_grupo = '102' AND valor_adic_1 = g.ind_tipo_bien) tipo_bien,
                (SELECT descripcion FROM vve_tabla_maes WHERE cod_grupo = '103' AND valor_adic_1 = g.ind_tipo_bien) tipo_otorgante,    
                (SELECT descripcion FROM vve_tabla_maes t INNER JOIN gen_persona g ON (g.cod_tipo_perso = t.valor_adic_1)
                  WHERE t.cod_grupo = '105' AND g.cod_perso = g.cod_pers_prop) AS tipo_persona,
                (SELECT descripcion FROM vve_tabla_maes t INNER JOIN gen_persona g ON (NVL(g.cod_estado_civil,'S') = t.valor_adic_1)
                  WHERE t.cod_grupo = '104' AND g.cod_perso = g.cod_pers_prop) AS estado_civil
        FROM vve_cred_maes_gara g, vve_cred_soli_gara sg, vve_cred_soli s 
        WHERE sg.cod_soli_cred = s.cod_soli_cred
        AND g.cod_pers_prop = p_cod_cliente 
        AND g.cod_garantia = sg.cod_gara 
        AND g.ind_adicional = 'S' 
        AND g.ind_tipo_garantia = p_ind_tipo_garantia
        AND 
        NOT EXISTS (SELECT 1 FROM vve_cred_soli_gara sg2 WHERE sg2.cod_gara = g.cod_garantia AND sg2.cod_soli_cred = p_cod_soli_cred)
        UNION
        SELECT  g.cod_garantia, 
                g.ind_tipo_garantia,
                g.ind_tipo_bien,
                g.ind_otor,
                g.cod_pers_prop,
                g.cod_marca,
                g.txt_modelo,
                g.cod_tipo_veh,
                g.nro_motor,
                g.txt_carroceria,
                g.fec_fab_const,
                g.nro_chasis,
                g.val_nro_rango,
                g.nro_placa,
                g.cod_tipo_actividad,
                g.val_const_gar,
                --(SELECT  PKG_SWEB_CRED_SOLI_GARANTIA.fn_obt_val_const_depr (p_cod_soli_cred,g.cod_garantia, g.cod_tipo_veh,'F') FROM DUAL)val_const_gar,
                (g.val_realiz_gar - (TO_NUMBER(EXTRACT(YEAR FROM sysdate) - g.val_ano_fab) / 100) * g.val_realiz_gar) as val_realiz_gar,
                g.cod_of_registral,
                g.val_anos_deprec,
                g.cod_moneda,
                g.des_descripcion,
                g.ind_adicional,
                g.num_titulo_rpv,
                g.nro_tarj_prop_veh,
                g.nro_partida,
                g.ind_reg_mob_contratos,
                g.ind_reg_jur_bien,
                g.txt_info_mod_gar,
                g.ind_ratifica_gar,
                g.val_nvo_monto,
                g.val_nvo_val,
                g.val_mont_otor_hip,
                g.txt_direccion,
                g.cod_distrito,
                g.cod_provincia,
                g.cod_departamento,
                g.cod_cliente,
                g.txt_marca,
                s.cod_oper_rel,
                (CASE WHEN g.ind_tipo_garantia='M' THEN 'Mobiliaria' ELSE 'Hipoticaria' END)  tipo_garantia_desc,
                g.val_ano_fab,
                (SELECT nom_marca AS descripcion FROM gen_marca m WHERE m.cod_marca= g.cod_marca) AS des_marca,
                (SELECT t.descripcion FROM vve_tabla_maes t WHERE t.cod_grupo = '106' AND t.cod_tipo = g.val_nro_rango) AS des_rango,
                (SELECT ta.des_tipo_actividad AS descripcion FROM vve_credito_tipo_actividad ta
                  WHERE ta.cod_tipo_actividad = g.cod_tipo_actividad) des_actividad,
                (SELECT des_tipo_veh AS descripcion FROM vve_tipo_veh ve WHERE ve.cod_tipo_veh = g.cod_tipo_veh) des_tipo_veh,
                (SELECT nom_perso FROM gen_persona WHERE cod_perso = g.cod_pers_prop) des_pers_prop,
                (SELECT des_nombre AS descripcion FROM gen_mae_distrito WHERE cod_id_distrito = g.cod_distrito) AS distrito,
                (SELECT des_nombre AS descripcion FROM gen_mae_provincia WHERE cod_id_provincia = g.cod_provincia) AS provincia,
                (SELECT des_nombre AS descripcion FROM gen_mae_departamento WHERE cod_id_departamento = g.cod_departamento) AS departamento,
                (SELECT descripcion FROM vve_tabla_maes WHERE cod_grupo = '102' AND valor_adic_1 = g.ind_tipo_bien) tipo_bien,
                (SELECT descripcion FROM vve_tabla_maes WHERE cod_grupo = '103' AND valor_adic_1 = g.ind_tipo_bien) tipo_otorgante,    
                (SELECT descripcion FROM vve_tabla_maes t INNER JOIN gen_persona g ON (g.cod_tipo_perso = t.valor_adic_1)
                  WHERE t.cod_grupo = '105' AND g.cod_perso = g.cod_pers_prop) AS tipo_persona,
                (SELECT descripcion FROM vve_tabla_maes t INNER JOIN gen_persona g ON (NVL(g.cod_estado_civil,'S') = t.valor_adic_1)
                  WHERE t.cod_grupo = '104' AND g.cod_perso = g.cod_pers_prop) AS estado_civil
        FROM vve_cred_maes_gara g, vve_cred_soli_gara sg, vve_cred_soli s  
        where sg.cod_soli_cred = s.cod_soli_cred 
        and s.cod_clie = p_cod_cliente
        and g.cod_garantia = sg.cod_gara 
        and g.ind_adicional = 'N' 
        and g.val_nro_rango IS NULL 
        and g.ind_tipo_garantia = p_ind_tipo_garantia 
        AND NOT EXISTS (SELECT 1 FROM vve_cred_soli_gara sg2 WHERE sg2.cod_gara = g.cod_garantia AND sg2.cod_soli_cred = p_cod_soli_cred);

  p_ret_esta := 1;
  p_ret_mens := 'La consulta se realizó de manera exitosa';
  END sp_list_garantia_histo;

  PROCEDURE sp_eli_gara_soli
  (
     p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
     p_ind_tipo_garantia IN vve_cred_maes_gara.ind_tipo_garantia%TYPE,
     p_list_gara_vig     IN VARCHAR2,
     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_ret_esta          OUT NUMBER,
     p_ret_mens          OUT VARCHAR2
  ) AS
     v_cursor SYS_REFCURSOR;
     v_cod_garantia VARCHAR2(500);
  BEGIN
    IF (p_list_gara_vig IS NULL OR p_list_gara_vig='') THEN
        UPDATE vve_cred_soli_gara s
           SET s.ind_inactivo = 'S'
         WHERE s.cod_soli_cred = p_cod_soli_cred
           AND EXISTS(SELECT 1
                        FROM vve_cred_maes_gara m
                       WHERE m.cod_garantia =s.cod_gara
                         AND m.ind_tipo_garantia = p_ind_tipo_garantia);
    ELSE
        UPDATE vve_cred_soli_gara s
           SET s.ind_inactivo = 'S'
         WHERE s.cod_gara NOT IN (SELECT column_value 
                                   FROM table(fn_varchar_to_table(p_list_gara_vig)))
           AND s.cod_soli_cred = p_cod_soli_cred
           AND EXISTS(SELECT 1
                        FROM vve_cred_maes_gara m
                       WHERE m.cod_garantia =s.cod_gara
                         AND m.ind_tipo_garantia = p_ind_tipo_garantia);
    END IF;



    COMMIT;     
    p_ret_esta := 1;
    p_ret_mens := 'La transaccion se realizó de manera exitosa';
  END sp_eli_gara_soli;


  /*-----------------------------------------------------------------------------
  Nombre : SP_LISTADO_PAIS
  Proposito : Listar los paises
  Referencias : Para el uso en los combos de registro
  Parametros : [p_cod_cia -> codigo de la compañía]
  Log de Cambios
    Fecha        Autor         Descripcion
    10/04/2019   jaltamirano   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_listado_paises(
    p_cod_cia           IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      --select * from generico.gen_mae_pais;
      SELECT pa.cod_id_pais AS cod_pais, pa.des_nombre AS nom_pais FROM gen_mae_pais pa, gen_mae_sociedad so WHERE pa.cod_id_pais = so.cod_id_pais AND so.cod_cia = p_cod_cia;
      --select * from gen_mae_sociedad;
      --SELECT '001' cod_pais,'PERU' nom_pais FROM DUAL;
     p_ret_esta := 1;
     p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_listado_departamentos:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_paises;


  /*-----------------------------------------------------------------------------
  Nombre : SP_LISTADO_DEPARTAMENTOS
  Proposito : Listar los departamentos
  Referencias : Para el uso en los combos de registro
  Parametros : [p_cod_pais -> codigo del pais]
  Log de Cambios
    Fecha        Autor         Descripcion
    10/04/2019   jaltamirano   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_listado_departamentos(
    p_cod_pais          IN VARCHAR2,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT cod_id_departamento,des_nombre FROM gen_mae_departamento WHERE cod_id_pais = p_cod_pais ORDER BY cod_id_departamento ASC;
     p_ret_esta := 1;
     p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_listado_departamentos:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_departamentos;

 /*-----------------------------------------------------------------------------
  Nombre : SP_LISTADO_PROVINCIAS
  Proposito : Listar los provincias
  Referencias : Para el uso en los combos de registro
  Parametros : [p_cod_depa -> codigo del departamento]
  Log de Cambios
    Fecha        Autor         Descripcion
    10/04/2019   jaltamirano   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_listado_provincias
  (
    p_cod_depa          IN gen_mae_departamento.cod_id_departamento%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT cod_id_provincia,des_nombre FROM gen_mae_provincia WHERE cod_id_departamento = p_cod_depa ORDER BY cod_id_provincia;

    p_ret_esta := 1;
    p_ret_mens  := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'sp_listado_provincias:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_provincias;

  /*-----------------------------------------------------------------------------
  Nombre : SP_LISTADO_DISTRITOS
  Proposito : Listar los distritos
  Referencias : Para el uso en los combos de registro
  Parametros : [p_cod_depa -> codigo del departamento]
               [p_cod_prov -> codigo de la provincia]
  Log de Cambios
    Fecha        Autor         Descripcion
    10/04/2019   jaltamirano   Creacion
  ----------------------------------------------------------------------------*/
  PROCEDURE sp_listado_distritos
  (
    p_cod_prov          IN gen_mae_distrito.cod_id_provincia%TYPE,
    p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
    OPEN p_ret_cursor FOR
      SELECT cod_id_distrito,des_nombre FROM gen_mae_distrito WHERE cod_id_provincia = p_cod_prov ORDER BY cod_id_distrito ASC;

    p_ret_esta := 1;
    p_ret_mens  := 'La consulta se realizó de manera exitosa';
  EXCEPTION
       WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'sp_listado_distritos:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_distritos;


  PROCEDURE sp_eli_by_gara
  (
     p_cod_soli_cred     IN vve_cred_soli_even.cod_soli_cred%TYPE,
     p_ind_tipo_garantia IN vve_cred_maes_gara.ind_tipo_garantia%TYPE,
     p_cod_garantia      IN vve_cred_maes_gara.cod_garantia%TYPE,
     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_ret_esta          OUT NUMBER,
     p_ret_mens          OUT VARCHAR2
  ) AS
     v_cursor SYS_REFCURSOR;
     v_cod_garantia VARCHAR2(500);
  BEGIN
    /*IF (p_list_gara_vig IS NULL OR p_list_gara_vig='') THEN
        UPDATE vve_cred_soli_gara s
           SET s.ind_inactivo = 'S'
         WHERE s.cod_soli_cred = p_cod_soli_cred
           AND EXISTS(SELECT 1
                        FROM vve_cred_maes_gara m
                       WHERE m.cod_garantia =s.cod_gara
                         AND m.ind_tipo_garantia = p_ind_tipo_garantia);
    ELSE
        UPDATE vve_cred_soli_gara s
           SET s.ind_inactivo = 'S'
         WHERE s.cod_gara NOT IN (SELECT column_value 
                                   FROM table(fn_varchar_to_table(p_list_gara_vig)))
           AND s.cod_soli_cred = p_cod_soli_cred
           AND EXISTS(SELECT 1
                        FROM vve_cred_maes_gara m
                       WHERE m.cod_garantia =s.cod_gara
                         AND m.ind_tipo_garantia = p_ind_tipo_garantia);
    END IF;*/
    UPDATE vve_cred_soli_gara sg SET 
          sg.ind_inactivo = 'S',  
          cod_usua_modi_regi = p_cod_usua_web, 
          fec_modi_regi = SYSDATE
     WHERE sg.cod_soli_cred = p_cod_soli_cred 
       AND sg.cod_gara IN (SELECT xx.cod_garantia FROM (
           (select g.cod_garantia from vve_cred_maes_gara g 
             where g.cod_garantia = sg.cod_gara 
               and g.cod_garantia = p_cod_garantia 
               and g.ind_tipo_garantia = p_ind_tipo_garantia) xx));

    COMMIT;     
    p_ret_esta := 1;
    p_ret_mens := 'La transaccion se realizó de manera exitosa';
  END sp_eli_by_gara;

   FUNCTION fn_obt_val_const_depr
  (
    p_cod_soli_cred     IN vve_cred_soli_gara.cod_soli_cred%TYPE,
    p_cod_garantia      IN vve_cred_maes_gara.cod_garantia%TYPE,
    p_cod_tipo_veh      IN vve_cred_mae_depr.cod_tipo_veh%TYPE,
    p_tipo_garantia     IN VARCHAR2     
  )  
  return NUMBER 
  AS
    v_cod_area_vta       VARCHAR2(10);
    v_cod_familia_veh    VARCHAR2(10);
    v_val_can_anos1      NUMBER;
    v_val_can_anos2      NUMBER;
    v_val_can_anos3      NUMBER;
    v_val_ano_fab        NUMBER;
    v_val_can_anos_aux1  NUMBER;
    v_val_can_anos_aux2  NUMBER;
    v_val_can_anos_aux3  NUMBER;
    v_val_porc_depr1     NUMBER;
    v_val_porc_depr2     NUMBER;
    v_val_porc_depr3     NUMBER;
    v_fec_modi_regi      DATE;
    v_val_pre_veh        NUMBER;
    v_val_const_gar      NUMBER;
    v_val_const_depr     NUMBER :=0;

  BEGIN
     --Obteniendo el área de venta
      SELECT cod_area_vta  INTO v_cod_area_vta
      FROM vve_cred_soli
      WHERE cod_soli_cred = p_cod_soli_cred;

    -- Obteniendo código de familia del veh.  
     SELECT distinct pvd.cod_familia_veh INTO v_cod_familia_veh
     FROM vve_cred_soli sc
      INNER JOIN vve_cred_soli_prof sp ON sc.cod_soli_cred = sp.cod_soli_cred
      INNER JOIN vve_proforma_veh pv ON pv.num_prof_veh = sp.num_prof_veh
      INNER JOIN vve_proforma_veh_det pvd ON pvd.num_prof_veh = pv.num_prof_veh
     WHERE sc.cod_soli_cred = p_cod_soli_cred;

    -- Obteniendo el valor del veh. 
     SELECT distinct pvd.val_pre_veh
     INTO v_val_pre_veh
     FROM vve_cred_soli sc
      INNER JOIN vve_cred_soli_prof sp ON sc.cod_soli_cred = sp.cod_soli_cred
      INNER JOIN vve_proforma_veh pv ON pv.num_prof_veh = sp.num_prof_veh
      INNER JOIN vve_proforma_veh_det pvd ON pvd.num_prof_veh = pv.num_prof_veh
     WHERE sc.cod_soli_cred = p_cod_soli_cred; 

   -- Obteniendo año de fabricación
     SELECT val_ano_fab INTO v_val_ano_fab
     FROM vve_cred_maes_gara
     where cod_garantia= p_cod_garantia;

   -- Calculando fecha de modificacion en tabla de garantías
     SELECT cmg.fec_modi_regi INTO v_fec_modi_regi
     FROM vve_cred_maes_gara cmg
     WHERE cmg.cod_garantia = p_cod_garantia;

   -- Calculando valor constituid de garantia
      SELECT cmg.val_const_gar INTO v_val_const_gar
      FROM vve_cred_maes_gara cmg
      WHERE cmg.cod_garantia =  p_cod_garantia;

    -- Obteniendo cantidad de años para garantías financiadas
          SELECT EXTRACT(YEAR FROM sysdate)- v_val_ano_fab 
          INTO  v_val_can_anos_aux1
          FROM dual;

    -- Calculando v_val_can_anos para garantías financiadas
          IF v_val_can_anos_aux1 >= 9 THEN  
            v_val_can_anos1 := 9;
          ELSE
            v_val_can_anos1 := v_val_can_anos_aux1;
          END IF;

     -- Obteniendo el valor de la depreciación 1
           SELECT distinct val_porc_depr
            INTO v_val_porc_depr1
           FROM vve_cred_mae_depr
           WHERE cod_area_vta = v_cod_area_vta
            AND  cod_familia_veh = v_cod_familia_veh
            AND  cod_tipo_veh  = p_cod_tipo_veh
            AND  val_can_anos = v_val_can_anos1;

   -- Obteniendo cantidad de años para garantías adicionales con fec_modi_regi null
          SELECT EXTRACT(YEAR FROM cmg.fec_crea_regi)-v_val_ano_fab
           INTO v_val_can_anos_aux2
          FROM vve_cred_maes_gara cmg
          WHERE cmg.cod_garantia = p_cod_garantia;

    -- Calculando v_val_can_anos para garantías financiadas con fec_modi_regi null
          IF v_val_can_anos_aux2 >= 9 THEN  
            v_val_can_anos2 := 9;
          ELSE
            v_val_can_anos2 := v_val_can_anos_aux2;
          END IF;

     -- Obteniendo el valor de la depreciación 2
           SELECT distinct val_porc_depr
            INTO v_val_porc_depr2
           FROM vve_cred_mae_depr
           WHERE cod_area_vta = v_cod_area_vta
            AND  cod_familia_veh = v_cod_familia_veh
            AND  cod_tipo_veh  = p_cod_tipo_veh
            AND  val_can_anos = v_val_can_anos2;   


   -- Obteniendo cantidad de años para garantías adicionales con fec_modi_regi  not null
          SELECT EXTRACT(YEAR FROM cmg.fec_modi_regi)-v_val_ano_fab
           INTO v_val_can_anos_aux3
          FROM vve_cred_maes_gara cmg
          WHERE cmg.cod_garantia = p_cod_garantia;

    -- Calculando v_val_can_anos para garantías financiadas con fec_modi_regi  not null
          IF v_val_can_anos_aux3 >= 9 THEN  
            v_val_can_anos3 := 9;
          ELSE
            v_val_can_anos3 := v_val_can_anos_aux3;
          END IF;

     -- Obteniendo el valor de la depreciación 3
           SELECT distinct val_porc_depr
            INTO v_val_porc_depr3
           FROM vve_cred_mae_depr
           WHERE cod_area_vta = v_cod_area_vta
            AND  cod_familia_veh = v_cod_familia_veh
            AND  cod_tipo_veh  = p_cod_tipo_veh
            AND  val_can_anos = v_val_can_anos3;                  

    IF p_tipo_garantia = 'F' THEN    
       -- Calculando el valor constituido
         v_val_const_depr := v_val_pre_veh*v_val_porc_depr1;                   
    ELSE
      -- Calculando el valor constituido
        IF v_fec_modi_regi IS NULL THEN             
           v_val_const_depr := ((v_val_const_gar*100) / v_val_porc_depr2)*v_val_porc_depr1;
        ELSE
           v_val_const_depr := ((v_val_const_gar*100) / v_val_porc_depr3)*v_val_porc_depr1; 
        END IF;

    END IF;

      return (v_val_const_depr);         

  END fn_obt_val_const_depr;

PROCEDURE sp_list_cobergara_fc
    (      
        p_cod_soli_cred     IN      vve_cred_soli.cod_soli_cred%TYPE,
        p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_cursor        OUT     SYS_REFCURSOR,
        p_ret_esta          OUT     NUMBER,
        p_ret_mens          OUT     VARCHAR2
    ) AS 
        ve_error EXCEPTION;
        val_realiz_gar_total  VARCHAR(200);
-- <-- I JAHERNANDEZ REQ. 89930
        v_no_cia varchar(50);
        v_cod_area_vta varchar(50);
        v_cod_familia_veh varchar(50);
        v_cod_tipo_veh varchar(50);
        v_cant_periodo integer;
 -- <-- F JAHERNANDEZ REQ. 89930
    BEGIN
/*  JAHERNANDEZ REQ--89930    comentado por Jorge Hernandez
         BEGIN
            SELECT SUM(mg.val_realiz_gar) INTO val_realiz_gar_total
            FROM vve_cred_maes_gara mg, vve_cred_soli_gara sg
            WHERE sg.cod_soli_cred = p_cod_soli_cred
            and  mg.cod_garantia = sg.cod_gara
            and sg.ind_inactivo = 'N';
        END;

        OPEN p_ret_cursor FOR
            SELECT round(val_realiz_gar_total/x.monto_letra,2) ratio_cob,x.ano
            from (
                 select max(sl.val_mon_conc) monto_letra, to_char(fec_venc,'yyyy') ano
                 from vve_cred_simu_lede sl, vve_cred_simu s
                 where s.cod_soli_cred = p_cod_soli_cred
                 and s.ind_inactivo = 'N'
                 and sl.cod_simu = s.cod_simu
                 and sl.cod_conc_col = 2 -- 2: Saldo Inicial/ 3:capital / 5:cuota
                 group by to_char(fec_venc,'yyyy')
                )x ORDER BY x.ano;  
*/
-- <-- I JAHERNANDEZ REQ. 89930  
            v_cod_area_vta :='';
            v_cod_familia_veh :='';
            v_cod_tipo_veh :='';
            v_no_cia :='';
            v_cant_periodo:=0;

    select cod_cia,cod_area_vta,cod_familia_veh,cod_tipo_veh
       into v_no_cia,v_cod_area_vta,v_cod_familia_veh,v_cod_tipo_veh
    from (
      select distinct b.cod_cia,b.cod_area_vta,c.cod_familia_veh,c.cod_tipo_veh
      from vve_cred_soli_prof a
      inner join vve_proforma_veh b on a.num_prof_veh=b.num_prof_veh and a.ind_inactivo='N' and b.cod_estado_prof in ('F','A')
      inner join vve_proforma_veh_det c on b.num_prof_veh = c.num_prof_veh
      inner join vve_ficha_vta_proforma_veh d on d.num_prof_veh= a.num_prof_veh and d.ind_inactivo='N'
      where a.cod_soli_cred =p_cod_soli_cred
      );

            select count(1)
              into v_cant_periodo
            from 
            (   
                select min(x.fec_venc) fec_venc,EXTRACT(year FROM x.fec_venc) anio
                from vve_cred_simu_lede x
                inner join vve_cred_simu s on s.cod_simu=x.cod_simu and s.ind_inactivo='N'
                where s.cod_soli_cred=p_cod_soli_cred and x.cod_conc_col=2
                group by EXTRACT(year FROM x.fec_venc)
            ) a
            inner join (
                select x.val_mon_conc,x.fec_venc,EXTRACT(year FROM x.fec_venc)anio,x.cod_det_simu,x.cod_nume_letr,x.cod_simu
                from vve_cred_simu_lede x 
                inner join vve_cred_simu s on s.cod_simu=x.cod_simu and s.ind_inactivo='N'
                where s.cod_soli_cred=p_cod_soli_cred and x.cod_conc_col=2
            ) b on a.anio=b.anio and a.fec_venc=b.fec_venc;


      OPEN p_ret_cursor FOR
                select round(nvl(a.d/n.val_mon_conc,0),2) as ratio_cob,n.anio as anio
                   from (
                   select r.cod_soli_cred,r.val_can_anos, nvl(r.am,0)+nvl(y.ah,0) D
                   from (  
                  select t.cod_soli_cred ,t.val_can_anos, sum(t.aM) as aM
                  from (
                  select  sg.cod_gara,
                  x.val_can_anos,mg.ind_tipo_garantia,mg.ind_tipo_bien,
                  sg.cod_soli_cred,mg.val_realiz_gar,mg.val_nro_rango,
                  x.val_porc_depr, (nvl(mg.val_realiz_gar*x.val_porc_depr,0)) as aM
                  FROM vve_cred_maes_gara mg 
                  INNER JOIN vve_cred_soli_gara sg ON sg.cod_gara = mg.cod_garantia and sg.ind_inactivo='N'
                  --INNER JOIN vve_cred_soli_prof a ON sg.cod_soli_cred = a.cod_soli_cred and a.ind_inactivo='N'
                  INNER JOIN vve_mov_avta_fam_tipoveh y on y.cod_area_vta='014' and y.cod_tipo_veh=mg.cod_tipo_veh and nvl(y.ind_inactivo, 'N') = 'N'

                  inner join vve_cred_mae_depr x on x.no_cia = v_no_cia  and x.cod_area_vta =y.cod_area_vta and
                                            x.cod_familia_veh =y.cod_familia_veh and x.cod_tipo_veh=mg.cod_tipo_veh and x.val_can_anos <v_cant_periodo 
                   WHERE sg.cod_soli_cred = p_cod_soli_cred
                   AND mg.ind_tipo_garantia = 'M' 
                   AND (sg.ind_inactivo IS NULL OR sg.ind_inactivo<>'S')
                    and mg.ind_tipo_bien='P' 
                  UNION
                  select distinct  sg.cod_gara,
                  e.val_can_anos,mg.ind_tipo_garantia, mg.ind_tipo_bien,
                  a.cod_soli_cred,c.val_pre_veh,mg.val_nro_rango,
                  e.val_porc_depr, (nvl(mg.val_realiz_gar*e.val_porc_depr,0))as aM
                  FROM vve_cred_maes_gara mg 
                  INNER JOIN vve_cred_soli_gara sg ON sg.cod_gara = mg.cod_garantia
                  inner join vve_cred_soli_prof a ON sg.cod_soli_cred = a.cod_soli_cred and 
                                                  mg.num_proforma_veh=a.num_prof_veh and a.ind_inactivo='N'
                  inner join vve_proforma_veh b on a.num_prof_veh=b.num_prof_veh and a.ind_inactivo='N' and b.cod_estado_prof in ('F','A')
                  inner join vve_proforma_veh_det c on b.num_prof_veh = c.num_prof_veh
                  inner join vve_ficha_vta_proforma_veh d on d.num_prof_veh= a.num_prof_veh and d.ind_inactivo='N'
                  inner join vve_cred_mae_depr e on e.no_cia = b.cod_cia and  e.cod_familia_veh =c.cod_familia_veh
                                                     and e.cod_area_vta ='014'--b.cod_area_vta 
                                                     and e.cod_tipo_veh= c.cod_tipo_veh and e.val_can_anos <v_cant_periodo  
                   WHERE sg.cod_soli_cred = p_cod_soli_cred
                          AND mg.ind_tipo_garantia = 'M'
                          AND (sg.ind_inactivo IS NULL OR sg.ind_inactivo<>'S')
                          and mg.ind_tipo_bien='A' 
                   )  t
                   group by t.val_can_anos,t.cod_soli_cred
                   ) r
                   left join (
                   select cod_soli_cred,aH from (
                   select sg.cod_soli_cred,sum(nvl(mg.Val_Realiz_Gar,0)) as aH
                  FROM vve_cred_maes_gara mg 
                  INNER JOIN vve_cred_soli_gara sg ON sg.cod_gara = mg.cod_garantia and sg.ind_inactivo='N'
                   WHERE sg.cod_soli_cred = p_cod_soli_cred
                   AND mg.ind_tipo_garantia = 'H' 
                   AND (sg.ind_inactivo IS NULL OR sg.ind_inactivo<>'S')
                    and mg.ind_tipo_bien='P' 
                   group by sg.cod_soli_cred
                   ) z  ) y on r.cod_soli_cred=y.cod_soli_cred
                   ) a
                  inner join (
                  select (ROWNUM-1) as val_can_anos, n.anio,n.val_mon_conc
                  from (
                  select a.anio,b.val_mon_conc
                  from 
                  (   
                  select min(x.fec_venc) fec_venc,EXTRACT(year FROM x.fec_venc) anio
                  from vve_cred_simu_lede x
                  inner join vve_cred_simu s on s.cod_simu=x.cod_simu and s.ind_inactivo='N'
                  where s.cod_soli_cred=p_cod_soli_cred and x.cod_conc_col=2
                  group by EXTRACT(year FROM x.fec_venc)
                  ) a
                  inner join (
                  select x.val_mon_conc,x.fec_venc,EXTRACT(year FROM x.fec_venc)anio,x.cod_det_simu,x.cod_nume_letr,x.cod_simu
                  from vve_cred_simu_lede x 
                  inner join vve_cred_simu s on s.cod_simu=x.cod_simu and s.ind_inactivo='N'
                  where s.cod_soli_cred=p_cod_soli_cred and x.cod_conc_col=2
                  ) b on a.anio=b.anio and a.fec_venc=b.fec_venc
                  order by a.anio asc
                  ) n) n on n.val_can_anos=a.val_can_anos
                  order by  n.val_can_anos;



-- <-- F JAHERNANDEZ REQ. 89930


            p_ret_esta := 1;
            p_ret_mens := 'Se realizó el proceso satisfactoriamente';


    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_cobergara_fc', p_cod_usua_sid, 
            'Error al consultar la cobertura de garantías '||p_cod_soli_cred
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := p_ret_mens||'sp_list_cobergara_fc:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_list_cobergara_fc', p_cod_usua_sid, 
            'Error al consultar la cobertura de garantías'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;

    END sp_list_cobergara_fc;    

END PKG_SWEB_CRED_SOLI_GARANTIA; 
