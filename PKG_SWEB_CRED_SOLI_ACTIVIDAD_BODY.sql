create or replace PACKAGE BODY VENTA.pkg_sweb_cred_soli_actividad AS

    PROCEDURE sp_list_acti (
        p_cod_soli_cred   IN vve_cred_soli.cod_soli_cred%TYPE,         --<CC E2.1 ID225 LR 11.11.19>
        p_cod_usua_sid    IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_act_actual      OUT vve_cred_maes_activ.des_acti_cred%TYPE,  --<CC E2.1 ID225 LR 11.11.19>
        p_act_siguiente   OUT vve_cred_maes_activ.des_acti_cred%TYPE,  --<CC E2.1 ID225 LR 11.11.19>
        p_ret_cursor      OUT SYS_REFCURSOR,
        p_ret_cantidad    OUT NUMBER,
        p_ret_esta        OUT NUMBER,
        p_ret_mens        OUT VARCHAR2
    ) AS
        v_pendiente       vve_cred_soli_acti.cod_cred_soli_acti%TYPE;
        v_pendiente_gen   NUMBER;
        v_tipo_cred       vve_cred_soli.tip_soli_cred%TYPE;
    BEGIN
        p_ret_cantidad := 0;
        v_pendiente := 1000;
        v_pendiente_gen := 1000;
        BEGIN
            SELECT
                s.tip_soli_cred
            INTO v_tipo_cred
            FROM
                vve_cred_soli s
            WHERE
                s.cod_soli_cred = p_cod_soli_cred;

        EXCEPTION
            WHEN no_data_found THEN
                v_tipo_cred := 'TC01';
        END;

        BEGIN
            SELECT
                MIN(vc1.cod_cred_soli_acti)
            INTO v_pendiente--, p_act_siguiente
            FROM
                vve_cred_soli_acti vc1
            WHERE
                vc1.cod_soli_cred = p_cod_soli_cred
                AND vc1.fec_usua_ejec IS NULL;

        EXCEPTION
            WHEN no_data_found THEN
                v_pendiente := 1000;
        END;

        p_act_actual := '';
        BEGIN
            SELECT
                ma.des_acti_cred
            INTO p_act_actual
            FROM
                vve_cred_soli_acti vc2
                INNER JOIN vve_cred_maes_activ ma --<CC E2.1 ID221 LR 11.11.19>
                 ON ( vc2.cod_acti_cred = ma.cod_acti_cred )
            WHERE
                vc2.cod_soli_cred = p_cod_soli_cred
                AND vc2.cod_cred_soli_acti = (
                    SELECT
                        MAX(vc1.cod_cred_soli_acti)
                    FROM
                        vve_cred_soli_acti vc1
                    WHERE
                        vc1.cod_soli_cred = p_cod_soli_cred
                        AND vc1.fec_usua_ejec IS NOT NULL
                );

        EXCEPTION
            WHEN no_data_found THEN
                p_act_actual := '';
        END;

        p_act_siguiente := '';
        BEGIN
            SELECT
                ma.des_acti_cred
            INTO p_act_siguiente
            FROM
                vve_cred_soli_acti vc2
                INNER JOIN vve_cred_maes_activ ma   --<CC E2.1 ID225 LR 11.11.19>
                 ON ( vc2.cod_acti_cred = ma.cod_acti_cred )
            WHERE
                vc2.cod_soli_cred = p_cod_soli_cred
                AND vc2.cod_cred_soli_acti = (
                    SELECT
                        MIN(vc1.cod_cred_soli_acti)
                    FROM
                        vve_cred_soli_acti vc1
                    WHERE
                        vc1.cod_soli_cred = p_cod_soli_cred
                        AND vc1.fec_usua_ejec IS NULL
                );

        EXCEPTION
            WHEN no_data_found THEN
                p_act_siguiente := '';
        END;

        BEGIN
            SELECT
                MIN(vve.orden)
            INTO v_pendiente_gen
            FROM
                (
                    SELECT
                        ROWNUM orden,
                        vc1.fec_usua_ejec
                    FROM
                        vve_cred_soli_acti vc1 
                        INNER JOIN vve_cred_maes_activ cma    --<CC E2.1 ID225 LR 11.11.19>
                         ON vc1.cod_acti_cred = cma.cod_acti_cred
                    WHERE
                        vc1.cod_soli_cred = p_cod_soli_cred
                        AND cma.cod_etap_cred IS NULL
                ) vve
            WHERE
                vve.fec_usua_ejec IS NULL;

            v_pendiente_gen := v_pendiente_gen - 1;
        EXCEPTION
            WHEN no_data_found THEN
                v_pendiente_gen := 1000;
        END;

        OPEN p_ret_cursor FOR 
      --<I CC E2.1 ID225 LR 11.11.19>     

         SELECT
                                 vc.cod_soli_cred,
                                 vc.cod_cred_soli_acti,
                                 vc.cod_acti_cred,
                                 vc.cod_usua_ejec,
                                 ( CASE
                                     WHEN vm.cod_etap_cred IS NOT NULL THEN vc.fec_usua_ejec
                                     ELSE (
                                         SELECT DISTINCT
                                             MAX(sa.fec_usua_ejec)
                                         FROM
                                             vve_cred_soli_acti sa,
                                             vve_cred_maes_activ vm
                                         WHERE
                                             sa.cod_soli_cred = vc.cod_soli_cred
                                             AND vm.cod_acti_cred = sa.cod_acti_cred
                                             AND vm.cod_etap_cred = vc.cod_acti_cred
                                             AND ( (
                                                 SELECT
                                                     COUNT(sa.fec_usua_ejec)
                                                 FROM
                                                     vve_cred_soli_acti sa,
                                                     vve_cred_maes_activ vm
                                                 WHERE
                                                     sa.cod_soli_cred = vc.cod_soli_cred
                                                     AND vm.cod_acti_cred = sa.cod_acti_cred
                                                     AND vm.cod_etap_cred = vc.cod_acti_cred
                                             ) = (
                                                 SELECT
                                                     COUNT(vm.cod_acti_cred)
                                                 FROM
                                                     vve_cred_acti_tipo_cred a,
                                                     vve_cred_maes_activ vm
                                                 WHERE
                                                     a.cod_tipo_cred = v_tipo_cred
                                                     AND a.ind_inactivo = 'N'
                                                     AND a.ind_oblig = 'S'
                                                     AND vm.cod_etap_cred = vc.cod_acti_cred
                                                     AND a.cod_acti_cred = vm.cod_acti_cred
                                             ) )
                                     )
                                 END ) AS fec_usua_ejec,
                                 vc.cod_usua_crea_reg,
                                 vc.fec_crea_reg,
                                 vc.cod_usua_modi_reg,
                                 vc.fec_modi_reg,
                                 (
                                     SELECT
                                         cm.des_acti_cred
                                     FROM
                                         vve_cred_maes_activ cm
                                     WHERE
                                         cm.cod_acti_cred = vc.cod_acti_cred
                                 ) AS des_acti_cred,
                                 v_pendiente        AS cod_cred_soli_acti_pend,
                                 nvl(to_number(substr(vm.cod_etap_cred,2,length(vm.cod_etap_cred) ) ),to_number(substr(vm.cod_acti_cred
                                ,2,length(vm.cod_acti_cred) ) ) ) AS cod_etap_cred_orden,
                                 vm.cod_etap_cred   AS cod_etap_cred,
                                 v_pendiente_gen    AS pend_gen,
                                 (
                                     SELECT
                                         COUNT(1)
                                     FROM
                                         vve_cred_rol_activ vcr
                                     WHERE
                                         vcr.cod_acti_cred = vc.cod_acti_cred
                                         AND vcr.cod_rol_usuario IN (
                                             SELECT
                                                 r.cod_rol_usuario
                                             FROM
                                                 sistemas.sis_mae_usuario u
                                                 INNER JOIN sistemas.usuarios_rol_usuario r ON ( u.txt_usuario = r.co_usuario )
                                             WHERE
                                                 txt_usuario = p_cod_usua_sid
                                         )
                                 ) AS cant_roles
                             FROM
                                 vve_cred_soli_acti vc,
                                 vve_cred_maes_activ vm,
                                 vve_cred_acti_tipo_cred atc
                             WHERE
                                 atc.cod_tipo_cred = v_tipo_cred
                                 AND atc.ind_inactivo = 'N'
                                 AND atc.cod_acti_cred = vm.cod_acti_cred
                                 AND vm.ind_inactivo = 'N'
                                 AND vc.cod_soli_cred = p_cod_soli_cred
                                 AND vc.cod_acti_cred = vm.cod_acti_cred
                                 AND vc.cod_acti_cred = atc.cod_acti_cred
                                 AND vc.ind_inactivo = 'N'--<Req. 87567 E2.1 ID 150 Usuario 11/08/2020>
                             ORDER BY
                                 vm.num_orden; 
      --<F CC E2.1 ID225 LR 11.11.19>      
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta :=-1;
    END sp_list_acti;

    PROCEDURE sp_actu_acti (
        p_cod_soli_cred   IN vve_cred_soli.cod_soli_cred%TYPE,
        p_etapa           IN VARCHAR2,
        p_acti            IN VARCHAR2,
        p_cod_usua_sid    IN sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta        OUT NUMBER,
        p_ret_mens        OUT VARCHAR2
    ) AS

        v_num_acti        NUMBER := 0;
        v_num_acti_ejec   NUMBER := 0;
        v_tip_soli_cred   VARCHAR2(4);
        v_query1          VARCHAR2(1000);
        v_query2          VARCHAR2(1000);
    BEGIN
        BEGIN
            v_query1 := '';
            v_query2 := '';
            UPDATE vve_cred_soli_acti
            SET
                fec_usua_ejec = to_date(SYSDATE,'DD/MM/YYYY'),--Req. 87567 E1 ID 27 AVILCA 01/07/2020 
                cod_usua_ejec = p_cod_usua_sid,
                cod_usua_modi_reg = p_cod_usua_sid,--Req. 87567 E1 ID 27 AVILCA 01/07/2020 
                fec_modi_reg =  to_date(SYSDATE,'DD/MM/YYYY')--Req. 87567 E1 ID 27 AVILCA 01/07/2020 
            WHERE
                cod_soli_cred = p_cod_soli_cred
                AND cod_acti_cred = p_acti;

            SELECT
                tip_soli_cred
            INTO v_tip_soli_cred
            FROM
                vve_cred_soli
            WHERE
                cod_soli_cred = p_cod_soli_cred;

        --<I CC E2.1 ID225 LR 11.11.19>

            v_query1 := 'SELECT ma.* FROM vve_cred_maes_activ ma, vve_cred_acti_tipo_cred atc 
                     WHERE ma.cod_etap_cred ='''
                        || p_etapa
                        || '''
                      AND ma.cod_acti_cred = atc.cod_acti_cred 
                      AND atc.cod_tipo_cred ='''
                        || v_tip_soli_cred
                        || '''
                      AND atc.ind_oblig IN (''S'') 
                      AND atc.ind_inactivo = ''N'''
                        ;
            v_query2 := 'SELECT * FROM vve_cred_soli_acti WHERE cod_soli_cred = '''
                        || p_cod_soli_cred
                        || '''
                     AND cod_acti_cred in (
                                           SELECT ma.cod_acti_cred 
                                           FROM vve_cred_maes_activ ma, vve_cred_acti_tipo_cred atc 
                                           WHERE ma.cod_etap_cred ='''
                        || p_etapa
                        || '''
                                            AND ma.cod_acti_cred = atc.cod_acti_cred 
                                            AND atc.cod_tipo_cred ='''
                        || v_tip_soli_cred
                        || '''
                                            AND atc.ind_oblig IN (''S'')
                                           ) 
                      AND fec_usua_ejec IS NOT NULL'
                        ;
 
        --<F CC E2.1 ID225 LR 11.11.19>

            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ('
                              || v_query1
                              || ')'
            INTO v_num_acti;
            EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ('
                              || v_query2
                              || ')'
            INTO v_num_acti_ejec;
            IF v_num_acti = v_num_acti_ejec THEN
                UPDATE vve_cred_soli_acti
                SET
                    cod_usua_ejec = p_cod_usua_sid,
                    fec_usua_ejec = SYSDATE,
                    cod_usua_modi_reg = p_cod_usua_sid,--<I Req. 87567 E2.1 ID## avilca 25/02/2021>
                    fec_modi_reg = SYSDATE--<I Req. 87567 E2.1 ID## avilca 25/02/2021>
                    
                WHERE
                    cod_soli_cred = p_cod_soli_cred
                    AND cod_acti_cred = p_etapa;

            END IF;
            

            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_INFO','sp_actu_acti',p_cod_usua_sid,v_query1
                                                                                            || ' '
                                                                                            || v_query2,p_ret_mens,p_cod_soli_cred
                                                                                            );

            p_ret_esta := 1;
            p_ret_mens := 'Se realizó la actualización de la etapa con éxito';
        EXCEPTION
            WHEN OTHERS THEN
                p_ret_esta := 0;
                p_ret_mens := 'sp_actu_acti:' || sqlerrm;
                pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR','sp_actu_acti',p_cod_usua_sid,v_query1
                                                                                                 || ' '
                                                                                                 || v_query2,p_ret_mens,p_cod_soli_cred
                                                                                                 );

        END;
    END sp_actu_acti;
    
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

    PROCEDURE sp_list_actividad_etapa (
        p_cod_acti_cred   IN vve_cred_maes_activ.cod_acti_cred%TYPE,
        p_cod_etap_cred   IN vve_cred_maes_activ.cod_etap_cred%TYPE,
        p_cod_usua_sid    IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web    IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_act_actual      OUT vve_cred_maes_activ.des_acti_cred%TYPE,
        p_act_siguiente   OUT vve_cred_maes_activ.des_acti_cred%TYPE,
        p_ret_cursor      OUT SYS_REFCURSOR,
        p_ret_cantidad    OUT NUMBER,
        p_ret_esta        OUT NUMBER,
        p_ret_mens        OUT VARCHAR2
    ) AS
        v_cod_acti_cred    vve_cred_maes_activ.cod_acti_cred%TYPE;
        v_cod_etap_cred    vve_cred_maes_activ.cod_etap_cred%TYPE;
        v_pendiente       vve_cred_soli_acti.cod_cred_soli_acti%TYPE;
        v_pendiente_gen   NUMBER;
        v_tipo_cred       vve_cred_soli.tip_soli_cred%TYPE;
        v_opcion   NUMBER;
    BEGIN
        p_ret_cantidad := 0;
        v_pendiente := 1000;
        v_pendiente_gen := 1000;
        p_act_actual := '';
        
       v_opcion := CASE WHEN p_cod_acti_cred = 'A' AND p_cod_etap_cred = 'A' THEN 1 
       WHEN p_cod_acti_cred = 'E' AND p_cod_etap_cred = 'E' THEN 2 ELSE 3 END;
       
       
        
            IF (v_opcion = 1) THEN
            BEGIN
                OPEN p_ret_cursor FOR 
                -- SELECT PARA LISTAR ACTIVIDADES MBARDALES REQ. MANT ACT Y ETAPAS
                SELECT cod_acti_cred, des_acti_cred FROM vve_cred_maes_activ WHERE cod_acti_cred like 'A%' AND ind_inactivo = 'N' ORDER BY des_acti_cred;                             
                p_ret_esta := 1;
                p_ret_mens := v_cod_acti_cred ||'++'||p_cod_acti_cred;-- 'La consulta se realizó de manera exitosa opcion I';
             COMMIT;
             END;
            END IF;
           
       IF (v_opcion = 2) THEN
       BEGIN
        OPEN p_ret_cursor FOR 
        -- SELECT PARA LISTAR ACTIVIDADES MBARDALES REQ. MANT ACT Y ETAPAS
        SELECT cod_acti_cred, des_acti_cred FROM vve_cred_maes_activ WHERE cod_acti_cred like 'E%' AND ind_inactivo = 'N' ORDER BY des_acti_cred;
        
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa opcion II';
        COMMIT;
        END;
        END IF;
        
        IF (v_opcion = 3) THEN
        
        IF p_cod_etap_cred = 'N' THEN
          v_cod_etap_cred := NULL;
        ELSE 
          v_cod_etap_cred := p_cod_etap_cred;
        END IF;
        
        BEGIN
        OPEN p_ret_cursor FOR 
            -- SELECT PARA ASIGNAR ACTIVIDAD A TIPO DE CREDITOS 
          SELECT t.cod_tipo AS COD_TIPO, t.descripcion AS DESCRIPCION,
          'N' AS OBLIG,
          'N' AS OPCIONAL,
          'N' AS ASIGNAR
          FROM vve_tabla_maes t 
          WHERE t.cod_grupo = 86 AND t.cod_grupo_rec IS NOT NULL 
          AND t.cod_tipo NOT IN (SELECT tc.cod_tipo_cred 
          FROM vve_cred_acti_tipo_cred tc 
          INNER JOIN vve_cred_maes_activ ma
          ON tc.cod_acti_cred = ma.cod_acti_cred 
          AND ma.ind_inactivo = 'N' 
          AND ma.cod_acti_cred = p_cod_acti_cred  
          AND v_cod_etap_cred IS NULL OR ma.cod_etap_cred = v_cod_etap_cred) 
          UNION
          SELECT t.cod_tipo AS COD_TIPO, t.descripcion AS DESCRIPCION,
          tc.ind_oblig AS OBLIG,
          decode(tc.ind_inactivo,'S','N',decode(tc.ind_oblig,'S','N','S')) AS OPCIONAL, -- decode(tc.ind_oblig,'S','N','S') AS OPCIONAL,
          decode(tc.ind_inactivo,'S','N','S') AS ASIGNAR
          FROM vve_tabla_maes t  
          INNER JOIN vve_cred_acti_tipo_cred tc
          ON t.cod_tipo=tc.cod_tipo_cred 
          AND t.cod_grupo = 86 AND t.cod_grupo_rec IS NOT NULL   
          AND t.cod_tipo = tc.cod_tipo_cred 
          INNER JOIN vve_cred_maes_activ ma
          ON tc.cod_acti_cred = ma.cod_acti_cred 
          AND ma.ind_inactivo = 'N' 
          AND ma.cod_acti_cred = p_cod_acti_cred
          AND v_cod_etap_cred IS NULL OR ma.cod_etap_cred = v_cod_etap_cred;
                                                                           
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa opcion III';                                  
        COMMIT;
        END;
        END IF;
       
       
        EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta :=-1;
            p_ret_mens := 'Se produjo un error en la consulta';
    END sp_list_actividad_etapa;

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
    ) AS
        v_pendiente       vve_cred_soli_acti.cod_cred_soli_acti%TYPE;
        v_pendiente_gen   NUMBER;
        v_tipo_cred       vve_cred_soli.tip_soli_cred%TYPE;
    BEGIN
        p_ret_cantidad := 0;
        v_pendiente := 1000;
        v_pendiente_gen := 1000;
        p_act_actual := '';
        OPEN p_ret_cursor FOR SELECT
                                  cod_acti_cred,
                                  cod_etap_cred,
                                  des_acti_cred,
                                  (select descripcion from vve_tabla_maes where cod_tipo = 
                                  cod_estado_soli and cod_grupo =92 and cod_tipo_rec ='ES') as descripcion,
                                  ind_inactivo,
                                  cod_estado_soli,
                                  num_orden
                              FROM
                                  vve_cred_maes_activ
                                  where ind_inactivo='N' order by num_orden asc;

        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta :=-1;
            p_ret_mens := 'Se produjo un error en la consulta';
    END sp_list_actividad_all;
    
    
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
    ) AS

        ve_error EXCEPTION;
        v_cod_max_acti_cred VARCHAR2(3);
        v_can_dig_acti_cred NUMERIC(2);
        v_pri_dig_acti_cred NUMERIC(1);
        v_seg_dig_acti_cred NUMERIC(1);
        v_cod_acti_cred VARCHAR2(3);

    BEGIN
        dbms_output.put_line('Comenzando...');
        
        IF p_cod_acti_cred = 'A' THEN
          SELECT 'A'||TO_CHAR(MAX(x.sec_acti) +1) INTO v_cod_acti_cred
          FROM 
          (SELECT to_number(substr(a1.cod_acti_cred,2,length(a1.cod_acti_cred))) sec_acti FROM vve_cred_maes_activ a1 WHERE substr(a1.cod_acti_cred,1,1) = 'A' AND a1.ind_inactivo = 'N') x;
        ELSE 
          SELECT 'E'||TO_CHAR(MAX(x.sec_acti) +1) INTO v_cod_acti_cred
          FROM 
          (SELECT to_number(substr(a1.cod_acti_cred,2,length(a1.cod_acti_cred))) sec_acti FROM vve_cred_maes_activ a1 WHERE substr(a1.cod_acti_cred,1,1) = 'E' AND a1.ind_inactivo = 'N') x;
        END IF;
              
        dbms_output.put_line(v_cod_acti_cred);

        INSERT INTO VVE_CRED_MAES_ACTIV (
          cod_acti_cred,
          cod_etap_cred,
          des_acti_cred,
          ind_inactivo,
          cod_estado_soli,
          num_orden,
          fec_crea_regi,
          cod_usua_crea_regi,
          fec_modi_regi,
          cod_usua_modi_regi
        ) VALUES(
          v_cod_acti_cred,
          p_cod_etap_cred,
          p_des_acti_cred,
          'N',
          p_cod_estado_soli,
          p_num_orden,
          SYSDATE,
          p_cod_usua_crea_regi,
          NULL,
          NULL);
                 
         -- ACtualizando fecha de ejecución de registro y verificando cierre de etapa
        --PKG_SWEB_CRED_SOLI_ACTIVIDAD.sp_actu_acti(p_cod_soli_cred,'E2','A8',p_cod_usua_sid,p_ret_esta,p_ret_mens);

        COMMIT;

        p_ret_esta := 1;
        p_ret_mens := 'Se ha registrado corectamente';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_inser_acti_etapa', p_cod_usua_modi_regi, 'Error al insertar la informacion una Actividad o Etapa'
            , p_ret_mens, p_cod_acti_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_inser_acti_etapa:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_inser_acti_etapa', p_cod_usua_modi_regi, 'Error al insertar la informacion una Actividad o Etapa'
            , p_ret_mens, p_cod_acti_cred);
            ROLLBACK;
    END sp_inser_acti_etapa;
    
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
    ) AS

        ve_error EXCEPTION;

    BEGIN
    
        IF p_ind_inactivo = 'N' THEN

          IF substr(p_cod_acti_cred, 1,1) = 'A' THEN
            UPDATE VVE_CRED_MAES_ACTIV SET 
            COD_ETAP_CRED  = p_cod_etap_cred,
            DES_ACTI_CRED  = p_des_acti_cred,
            IND_INACTIVO  = p_ind_inactivo,
            COD_ESTADO_SOLI  = p_cod_estado_soli,
            NUM_ORDEN  = p_num_orden,
            FEC_MODI_REGI  = SYSDATE,
            COD_USUA_MODI_REGI  = p_cod_usua_modi_regi
            WHERE cod_acti_cred = p_cod_acti_cred;
            COMMIT;
          ELSE 
            UPDATE VVE_CRED_MAES_ACTIV SET 
            DES_ACTI_CRED  = p_des_acti_cred,
            IND_INACTIVO  = p_ind_inactivo,
            COD_ESTADO_SOLI  = p_cod_estado_soli,
            NUM_ORDEN  = p_num_orden,
            FEC_MODI_REGI  = SYSDATE,
            COD_USUA_MODI_REGI  = p_cod_usua_modi_regi
            WHERE cod_acti_cred = p_cod_acti_cred;
          END IF;
      
       ELSE 
          UPDATE vve_cred_acti_tipo_cred SET ind_inactivo = p_ind_inactivo WHERE cod_acti_cred = p_cod_acti_cred;
          COMMIT;
          -- SE INACTIVA LA ACTIVIDAD O ETAPA PRINCIPAL
          UPDATE VVE_CRED_MAES_ACTIV SET IND_INACTIVO = p_ind_inactivo WHERE cod_acti_cred = p_cod_acti_cred;
          COMMIT;
          -- SI ES ETAPA INACTIVARA A SUS ACTIVIDADES
          UPDATE VVE_CRED_MAES_ACTIV SET IND_INACTIVO = p_ind_inactivo WHERE cod_etap_cred = p_cod_acti_cred;
          COMMIT;
       END IF;
       
        p_ret_esta := 1;
        p_ret_mens := 'Se ha registrado corectamente';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_inser_acti_etapa', p_cod_usua_modi_regi, 'Error al insertar la informacion una Actividad o Etapa'
            , p_ret_mens, p_cod_acti_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_inser_acti_etapa:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_inser_acti_etapa', p_cod_usua_modi_regi, 'Error al insertar la informacion una Actividad o Etapa'
            , p_ret_mens, p_cod_acti_cred);
            ROLLBACK;
    END sp_actu_activ;
    
    
    PROCEDURE sp_actu_activ_tipo_cred (
        p_cod_acti_cred			IN  vve_cred_acti_tipo_cred.cod_acti_cred%TYPE,
        p_cod_tipo_cred			IN  vve_cred_acti_tipo_cred.cod_tipo_cred%TYPE,
        p_ind_inactivo			IN  vve_cred_acti_tipo_cred.ind_inactivo%TYPE,
        p_ind_oblig				IN  vve_cred_acti_tipo_cred.ind_oblig%TYPE,
        p_cod_usua          	IN  vve_cred_acti_tipo_cred.cod_usua_modi_regi%TYPE,
        p_ret_esta                   OUT     NUMBER,
        p_ret_mens                   OUT     VARCHAR2
    ) AS

        ve_error EXCEPTION;
        v_count INT;

    BEGIN
    
       SELECT COUNT(*) INTO v_count FROM vve_cred_acti_tipo_cred WHERE cod_acti_cred = p_cod_acti_cred AND cod_tipo_cred = p_cod_tipo_cred;
       
       IF v_count > 0 THEN
         UPDATE vve_cred_acti_tipo_cred SET
         cod_acti_cred		= p_cod_acti_cred,
         cod_tipo_cred		= p_cod_tipo_cred,
         ind_inactivo		= DECODE(p_ind_inactivo, 'S','N','S'),
         ind_oblig			= p_ind_oblig,
         fec_modi_regi		= SYSDATE,
         cod_usua_modi_regi	= p_cod_usua
         WHERE cod_acti_cred = p_cod_acti_cred AND cod_tipo_cred = p_cod_tipo_cred;
         COMMIT;

       ELSE 
          IF p_ind_inactivo <> 'N' THEN
            INSERT INTO vve_cred_acti_tipo_cred (COD_ACTI_CRED, COD_TIPO_CRED, IND_INACTIVO, IND_OBLIG, FEC_CREA_REGI, COD_USUA_CREA_REGI)
            VALUES (p_cod_acti_cred, p_cod_tipo_cred, 'N', p_ind_oblig, SYSDATE, p_cod_usua);
            COMMIT;
          END IF;
       END IF;

       p_ret_esta := 1;
       p_ret_mens := 'sp_actu_activ_tipo_cred';

    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_actu_activ_tipo_cred', p_cod_usua, 'Error al modificar Actividad con tipo credito'
            , p_ret_mens, p_cod_acti_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_inser_acti_etapa:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'sp_actu_activ_tipo_cred', p_cod_usua, 'Error al modificar Actividad con tipo credito'
            , p_ret_mens, p_cod_acti_cred);
            ROLLBACK;
    END sp_actu_activ_tipo_cred;
    
    
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
    )AS
      v_cod_acti_cred VARCHAR2(10);
      v_cod_etap_cred VARCHAR2(10);
      v_cod_tipo_cred VARCHAR2(10);
    BEGIN
    
        IF p_cod_acti_cred = 'A' AND p_cod_etap_cred = 'A' AND p_cod_tipo_cred = 'A' THEN 
          OPEN p_ret_cursor FOR
              SELECT distinct a.cod_acti_cred, 
              (SELECT a1.des_acti_cred FROM vve_cred_maes_activ a1 WHERE a1.cod_acti_cred = a.cod_acti_cred AND cod_acti_cred LIKE 'A%') actividad,
              a.cod_etap_cred, 
              (SELECT a2.des_acti_cred FROM vve_cred_maes_activ a2 WHERE a2.cod_acti_cred = a.cod_etap_cred AND cod_acti_cred LIKE 'E%') etapa,
              a.cod_estado_soli, 
              (select descripcion from vve_tabla_maes where cod_tipo = 
              a.cod_estado_soli and cod_grupo =92 and cod_tipo_rec ='ES') as des_estado_soli,
              a.num_orden
              FROM vve_cred_maes_activ a 
              WHERE a.ind_inactivo = 'N'
              AND cod_etap_cred IS NOT NULL
              ORDER BY a.cod_acti_cred, a.num_orden;
        
        ELSE 
        
          IF p_cod_acti_cred = 'N' THEN v_cod_acti_cred := NULL; ELSE v_cod_acti_cred := p_cod_acti_cred; END IF;
          IF p_cod_etap_cred = 'N' THEN v_cod_etap_cred := NULL; ELSE v_cod_etap_cred := p_cod_etap_cred; END IF;
          IF p_cod_tipo_cred = 'N' THEN v_cod_tipo_cred := NULL; ELSE v_cod_tipo_cred := p_cod_tipo_cred; END IF;
          
          OPEN p_ret_cursor FOR
              
              select a1.num_orden,
                     a1.cod_acti_cred,
                     a1.des_acti_cred actividad,
                     a1.cod_etap_cred,
                     nvl((select a2.des_acti_cred from vve_cred_maes_activ a2 where a2.cod_acti_cred = a1.cod_etap_cred),'') etapa,
                     --null tipo_credito,
                     null cod_tipo_cred, 
                     a1.cod_estado_soli, 
                     (select descripcion from vve_tabla_maes where cod_tipo = 
                     a1.cod_estado_soli and cod_grupo =92 and cod_tipo_rec ='ES') as des_estado_soli
              from   vve_cred_maes_activ a1 
              where  a1.ind_inactivo = 'N' and 
                     ((v_cod_acti_cred is null and v_cod_etap_cred is null) or 
                     (v_cod_acti_cred is not null and v_cod_etap_cred is null and a1.cod_acti_cred = v_cod_acti_cred and a1.cod_etap_cred is not null) or
                     (v_cod_acti_cred is not null and v_cod_etap_cred is not null and a1.cod_acti_cred = v_cod_acti_cred and a1.cod_etap_cred = v_cod_etap_cred) or 
                     (v_cod_acti_cred is null and v_cod_etap_cred is not null and (a1.cod_acti_cred = v_cod_etap_cred or a1.cod_etap_cred = v_cod_etap_cred)))
                     and (v_cod_tipo_cred IS NULL) 
              UNION 
              select a1.num_orden,
                     a1.cod_acti_cred,
                     a1.des_acti_cred actividad,
                     a1.cod_etap_cred,
                     nvl((SELECT a2.des_acti_cred FROM vve_cred_maes_activ a2 WHERE a2.cod_acti_cred = a1.cod_etap_cred),'') etapa,
                     --(SELECT m.descripcion FROM vve_tabla_maes m where m.cod_tipo = t.cod_tipo_cred AND m.cod_grupo = '86') tipo_credito,
                     t.cod_tipo_cred, 
                     a1.cod_estado_soli, 
                     (select descripcion from vve_tabla_maes where cod_tipo = 
                     a1.cod_estado_soli and cod_grupo =92 and cod_tipo_rec ='ES') as des_estado_soli
              from   vve_cred_maes_activ a1, vve_cred_acti_tipo_cred t 
              where  a1.ind_inactivo = 'N' and 
                     ((v_cod_acti_cred is null and v_cod_etap_cred is null) or 
                     (v_cod_acti_cred is not null and v_cod_etap_cred is null and a1.cod_acti_cred = v_cod_acti_cred and a1.cod_etap_cred is not null) or
                     (v_cod_acti_cred is not null and v_cod_etap_cred is not null and a1.cod_acti_cred = v_cod_acti_cred and a1.cod_etap_cred = v_cod_etap_cred) or 
                     (v_cod_acti_cred is null and v_cod_etap_cred is not null and (a1.cod_acti_cred = v_cod_etap_cred or a1.cod_etap_cred = v_cod_etap_cred)))
                     and (v_cod_tipo_cred IS NOT NULL and t.cod_tipo_cred = v_cod_tipo_cred and a1.cod_acti_cred = t.cod_acti_cred and t.ind_inactivo = 'N')
              order by 1;
              
          
              
        END IF;
    
        p_ret_esta := 1;
        p_ret_mens := 'Se realizo la consulta correctamente.';  
        p_ret_cantidad := 0;

       
        EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta :=-1;
            p_ret_mens := 'Se produjo un error en la consulta';
            
    END sp_busqueda_act_eta_tip_cred;
    
   END pkg_sweb_cred_soli_actividad;