create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_LXC AS

  PROCEDURE sp_list_docu_rela (
    p_no_cliente          IN                arccmd.no_cliente%TYPE,
    p_cod_soli_cred       IN                vve_cred_soli_pedi_veh.cod_soli_cred%TYPE,
    p_no_cia              IN                arccmd.no_cia%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_cursor_total    OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2 
    ) AS
    ve_error EXCEPTION;
    v_tipo_cred VARCHAR2(5);
    v_sum_docu_arcc NUMERIC(11,2);
    v_sum_arfa NUMERIC(11,2);
    v_cod_oper vve_cred_soli.cod_oper_rel%type := null;
	
    BEGIN
    
    SELECT TIP_SOLI_CRED, COD_OPER_REL 
    INTO   v_tipo_cred, v_cod_oper 
    FROM   VVE_CRED_SOLI 
    WHERE  COD_SOLI_CRED = p_cod_soli_cred
    AND    COD_EMPR = p_no_cia;
       
    IF (v_tipo_cred = 'TC01') THEN
    
        OPEN p_ret_cursor FOR
            SELECT  tipo_doc, no_docu, moneda, saldo, 
                    TO_CHAR(fecha_vence, 'DD/MM/YYYY') AS fecha_vence, 
                    no_cliente, grupo, cod_oper 
            FROM    arccmd a
            WHERE   a.no_cia = p_no_cia 
            AND     a.grupo = '01'  -- codigo del grupo del cliente
            AND     a.no_soli in 
                    (select num_pedido_veh from vve_cred_soli_pedi_veh where cod_soli_cred = p_cod_soli_cred AND cod_cia = p_no_cia)
            AND     a.no_cliente = p_no_cliente 
            AND     a.estado != 'P' AND (nvl(a.saldo,0) != 0 ) 
            AND    ((v_cod_oper IS NULL) 
                     OR 
                     (v_cod_oper IS NOT NULL and NOT EXISTS (SELECT 1 FROM arlcrd d 
                                                           where d.tipo_docu = a.tipo_doc 
                                                           and d.no_docu = a.no_docu 
                                                           and d.no_cliente = a.no_cliente 
                                                           and d.no_cia = a.no_cia
                                                           and d.grupo = a.grupo
                                                           and d.cod_oper = v_cod_oper)
                    ))
            UNION 
            SELECT tipo_docu tipo_doc,no_docu,moneda,monto saldo,TO_CHAR(fecha, 'DD/MM/YYYY') fecha_vence,no_cliente, grupo,cod_oper
            FROM arlcrd 
            WHERE (cod_oper = v_cod_oper AND v_cod_oper IS NOT NULL)
            order by tipo_doc, no_docu;
             
                /*SELECT tipo_doc, no_docu, moneda, saldo, 
                    TO_CHAR(fecha_vence, 'DD/MM/YYYY') AS fecha_vence, 
                    no_cliente, grupo, cod_oper 
                    FROM arccmd a
                    WHERE a.no_cia = p_no_cia
                    AND a.grupo = '01'  -- codigo del grupo del cliente
                    AND a.no_soli in 
                    (select num_pedido_veh from vve_cred_soli_pedi_veh where cod_soli_cred = p_cod_soli_cred AND cod_cia = p_no_cia)
                    AND a.no_cliente = p_no_cliente
                    AND a.estado != 'P' AND (nvl(a.saldo,0) != 0 ) 
                UNION ALL
                SELECT TIPO_DOC, NO_FACTU AS NO_DOCU, MONEDA, VAL_PRE_DOCU AS SALDO, TO_CHAR(FECHA, 'DD/MM/YYYY') AS fecha_vence,
                    NO_CLIENTE, GRUPO, NULL AS COD_OPER
                    FROM ARFAFE WHERE NO_ORDEN_DESC 
                    IN (SELECT NUM_PEDIDO_VEH FROM VVE_CRED_SOLI_PEDI_VEH WHERE cod_soli_cred = p_cod_soli_cred)
                 order by tipo_doc, no_docu;
                
            SELECT NVL(SUM(saldo), 0) INTO v_sum_docu_arcc
                FROM arccmd a
                WHERE a.no_cia = p_no_cia
                AND a.grupo = '01'  -- codigo del grupo del cliente
                AND a.no_soli in 
                (select num_pedido_veh from vve_cred_soli_pedi_veh where cod_soli_cred = p_cod_soli_cred AND cod_cia = p_no_cia)
                AND a.no_cliente = p_no_cliente
                AND a.estado != 'P' AND (nvl(a.saldo,0) != 0 ) order by a.tipo_doc, a.no_docu;
                
            SELECT NVL(SUM(VAL_PRE_DOCU), 0) INTO v_sum_arfa
                    FROM ARFAFE WHERE NO_ORDEN_DESC 
                    IN (SELECT NUM_PEDIDO_VEH FROM VVE_CRED_SOLI_PEDI_VEH WHERE cod_soli_cred = p_cod_soli_cred);
            */        
            OPEN p_ret_cursor_total FOR
              --  SELECT (v_sum_docu_arcc + v_sum_arfa) AS TOTAL FROM DUAL;
            SELECT SUM(X.SALDO) as TOTAL FROM 
               (SELECT  tipo_doc, no_docu, moneda, saldo, 
                        TO_CHAR(fecha_vence, 'DD/MM/YYYY') AS fecha_vence, 
                        no_cliente, grupo, cod_oper 
                FROM    arccmd a
                WHERE   a.no_cia = p_no_cia 
                AND     a.grupo = '01'  -- codigo del grupo del cliente
                AND     a.no_soli in 
                        (select num_pedido_veh from vve_cred_soli_pedi_veh where cod_soli_cred = p_cod_soli_cred AND cod_cia = p_no_cia)
                AND     a.no_cliente = p_no_cliente 
                AND     a.estado != 'P' AND (nvl(a.saldo,0) != 0 ) 
                AND    ((v_cod_oper IS NULL) 
                         OR 
                         (v_cod_oper IS NOT NULL and NOT EXISTS (SELECT 1 FROM arlcrd d 
                                                               where d.tipo_docu = a.tipo_doc 
                                                               and d.no_docu = a.no_docu 
                                                               and d.no_cliente = a.no_cliente 
                                                               and d.no_cia = a.no_cia
                                                               and d.grupo = a.grupo
                                                               and d.cod_oper = v_cod_oper)
                        ))
                UNION 
                SELECT tipo_docu tipo_doc,no_docu,moneda,monto saldo,TO_CHAR(fecha, 'DD/MM/YYYY') fecha_vence,no_cliente, grupo,cod_oper
                FROM arlcrd 
                WHERE (cod_oper = v_cod_oper AND v_cod_oper IS NOT NULL)) x;
            
                
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
            
    ELSE
    
        OPEN p_ret_cursor FOR
        --SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL FROM DUAL;
        SELECT  tipo_doc, no_docu, moneda, saldo, 
                TO_CHAR(fecha_vence, 'DD/MM/YYYY') AS fecha_vence, 
                no_cliente, grupo, cod_oper 
        FROM arccmd a
        WHERE a.no_cia = p_no_cia
        AND a.grupo = '01'  -- codigo del grupo del cliente
        AND a.no_soli in 
        (select num_pedido_veh from vve_cred_soli_pedi_veh where cod_soli_cred = 0 AND cod_cia = p_no_cia)
        AND a.no_cliente = p_no_cliente
        AND a.estado != 'P' AND (nvl(a.saldo,0) != 0 ) 
        UNION 
        SELECT tipo_docu tipo_doc,no_docu,moneda,monto saldo,TO_CHAR(fecha, 'DD/MM/YYYY') fecha_vence,no_cliente, grupo,cod_oper
        FROM arlcrd 
        WHERE (cod_oper = v_cod_oper AND v_cod_oper IS NOT NULL)
        order by tipo_doc, no_docu;
         
         OPEN p_ret_cursor_total FOR
                SELECT 0 AS TOTAL FROM DUAL;
    
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    
    END IF;
            
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_DOCU_RELA', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_DOCU_RELA:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_DOCU_RELA', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
    END sp_list_docu_rela;


  PROCEDURE sp_list_tipo_docu (
    p_no_cia              IN                arcctd.no_cia%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2 
    ) AS
    ve_error EXCEPTION;
	
    BEGIN
    
    OPEN p_ret_cursor FOR
            SELECT 
                tipo, descripcion 
            FROM 
                arcctd 
            where 
                arcctd.no_cia = p_no_cia order by tipo;
            
            p_ret_esta := 1;
            p_ret_mens := 'La consulta se realizó de manera exitosa';
            
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_TIPO_DOCU', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_TIPO_DOCU:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_TIPO_DOCU', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
  END sp_list_tipo_docu;
    
  
  PROCEDURE sp_list_tipo_gasto (
    p_no_cia              IN                arcctd.no_cia%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2 
    ) AS
    ve_error EXCEPTION;
	
    BEGIN
    
    OPEN p_ret_cursor FOR
            SELECT 
                no_cia, tipo cod_gasto, descripcion 
            FROM 
                arcctd a
            WHERE 
                no_cia = p_no_cia and tipo_mov = 'D' and 
                (clase_docu = 'D' or tipo in 
                (SELECT 
                    d.cod_valdet 
                FROM 
                    gen_lval_det d
                WHERE  
                    d.no_cia = a.no_cia AND d.cod_val = 'OPGTO' 
                    AND d.cod_valdet = a.tipo AND NVL(d.ind_inactivo,'N') = 'N'
                ));
            
            p_ret_esta := 1;
            p_ret_mens := 'La consulta se realizó de manera exitosa';
            
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_TIPO_GASTO', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_TIPO_GASTO:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_TIPO_GASTO', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
  END sp_list_tipo_gasto;
    
    
  PROCEDURE sp_list_gastos (
    p_cod_soli_cred       IN                vve_cred_simu.cod_soli_cred%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_cursor_total    OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2 
    ) AS
    ve_error EXCEPTION;
    v_cod_simu VARCHAR2(12);
	
    BEGIN
    
        BEGIN
            SELECT 
                cod_simu INTO v_cod_simu
            FROM 
                vve_cred_simu 
            WHERE 
                cod_soli_cred = p_cod_soli_cred and ind_inactivo = 'N';
            EXCEPTION
                WHEN OTHERS THEN
                v_cod_simu := '0';
        END;
    
    OPEN p_ret_cursor FOR
        SELECT 
            --'XX' as cod_gast,
            'FO' as cod_gast,
            UPPER(des_conc), 
            CASE 
            WHEN cod_moneda = '1' THEN 'SOL' 
            ELSE 'DOL' END AS moneda,
            val_mon_total 
        FROM 
            vve_cred_simu_gast sg INNER JOIN vve_cred_maes_conc_letr ml
            ON (sg.cod_conc_col = ml.cod_conc_col)
        WHERE  
            cod_simu = v_cod_simu AND ind_fin = 'N';
                
    OPEN p_ret_cursor_total FOR
        SELECT 
            SUM(val_mon_total) as total
        FROM 
            vve_cred_simu_gast sg INNER JOIN vve_cred_maes_conc_letr ml
            ON (sg.cod_conc_col = ml.cod_conc_col)
        WHERE  
            cod_simu = v_cod_simu AND ind_fin = 'N'; 
            
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
            
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_GASTOS', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_GASTOS:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_GASTOS', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
  END sp_list_gastos;
  
  PROCEDURE sp_list_repre_legal (
    p_cod_cliente         IN                gen_persona.cod_perso%TYPE,
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2 
    ) AS
    ve_error EXCEPTION;
	
    BEGIN
    
    OPEN p_ret_cursor FOR
        SELECT 
            nom_perso, 
            (select upper(d.dir_domicilio||' - '||di.nom_ubigeo) 
            from gen_dir_perso d,gen_ubigeo di 
            where d.cod_perso = g.cod_perso and d.ind_dir_ctrato = 'S'
            and di.cod_distrito = d.cod_distrito
            and di.cod_provincia = d.cod_provincia
            and di.cod_dpto = d.cod_dpto) AS direccion,
            num_telf_movil,
            CASE WHEN cod_tipo_perso = 'N' then num_docu_iden ELSE num_ruc END AS nro_docu,
            '' AS avalar
        FROM 
            gen_persona g
        where 
            g.cod_perso in 
            (SELECT r.cod_perso_rela  FROM gen_rela_perso r
            WHERE r.cod_perso = p_cod_cliente AND r.ind_impr_docu = 'S' AND r.ind_repre = 'S');
            
    p_ret_esta := 1;
    p_ret_mens := 'La consulta se realizó de manera exitosa';
            
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_REPRE_LEGAL', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_REPRE_LEGAL:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_REPRE_LEGAL', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
  END sp_list_repre_legal;
  
  PROCEDURE sp_list_repro_oper (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_no_cia              IN                arlcop.no_cia%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ind_paginado        IN                VARCHAR2,
    p_limitinf            IN                INTEGER,
    p_limitsup            IN                INTEGER,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_cantidad            OUT               NUMBER,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2  
    ) AS
    ve_error EXCEPTION;
    v_cod_oper VARCHAR2(12);
    ln_limitinf NUMBER := 0;
    ln_limitsup NUMBER := 0;
	
    BEGIN 
    
        dbms_output.put_line('Entra a sp_list_repro_oper');
    
        BEGIN
            SELECT 
                CASE WHEN cod_oper_orig != NULL THEN cod_oper_orig ELSE cod_oper_rel END cod_oper 
            INTO
                v_cod_oper
            FROM 
                vve_cred_soli 
            WHERE 
                cod_soli_cred = p_cod_soli_cred;
        EXCEPTION
            WHEN OTHERS THEN
                v_cod_oper := NULL;
        END;
        
        dbms_output.put_line('v_cod_oper');
        dbms_output.put_line(v_cod_oper);
        
        IF v_cod_oper IS NOT NULL THEN
            
            IF p_ind_paginado = 'N' THEN
                SELECT COUNT(1)
                    INTO ln_limitsup
                FROM 
                    arlcop
                WHERE 
                    cod_oper like '%'||v_cod_oper||'%' AND no_cia = p_no_cia;
            ELSE
                ln_limitinf := p_limitinf - 1;
                ln_limitsup := p_limitsup;
            END IF;
            
            dbms_output.put_line(ln_limitinf);
            dbms_output.put_line(ln_limitsup);
            
            OPEN p_ret_cursor FOR
                SELECT 
                    a.cod_oper,a.MONEDA,a.monto_fina,
                    (SELECT COUNT(*) FROM arlcml l WHERE a.cod_oper = l.cod_oper AND a.no_cia = l.no_cia) nro_cuotas,
                    a.tea, 
                    TO_CHAR(a.vcto_1ra_let, 'DD/MM/YYYY') AS vcto_1ra_let,
                    decode(a.estado,'P', 'PENDIENTE','U','ANULADO','I','IMPRESO','A','ACTUALIZADO') as estado
                FROM 
                    arlcop a 
                WHERE 
                    cod_oper like '%'||v_cod_oper||'%' AND no_cia = p_no_cia
                    ORDER BY 1
                OFFSET ln_limitinf rows FETCH NEXT ln_limitsup ROWS ONLY;
                
            SELECT 
                COUNT(1) 
            INTO 
                p_cantidad
            FROM 
                arlcop a 
            WHERE 
                cod_oper like '%'||v_cod_oper||'%' AND no_cia = p_no_cia;
                
                dbms_output.put_line(p_cantidad);
                
        ELSE 
            p_cantidad := 0;
        END IF;
                
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
            
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_REPRO_OPER', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_REPRO_OPER:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_REPRO_OPER', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
  END sp_list_repro_oper;
  
  
  PROCEDURE sp_list_oper_regi
    (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE,
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_docu            OUT               SYS_REFCURSOR,
    p_ret_docu_total      OUT               SYS_REFCURSOR,
    p_ret_gasto           OUT               SYS_REFCURSOR,
    p_ret_gasto_total     OUT               SYS_REFCURSOR,
    p_ret_aval            OUT               SYS_REFCURSOR,
    p_ret_oper_regi       OUT               SYS_REFCURSOR,
    p_ret_tipo_credito_lxc    OUT               vve_cred_soli_para.val_para_car%TYPE,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2 
    ) AS
    ve_error EXCEPTION;
    v_cod_oper VARCHAR2(12);
    v_cod_simu VARCHAR2(12);
    
    BEGIN
    
    select val_para_car into p_ret_tipo_credito_lxc from vve_cred_soli_para where cod_cred_soli_para = 'TIPCREDOCLXC';--06sep2019
    
        BEGIN
            SELECT 
                CASE WHEN cod_oper_orig != NULL THEN cod_oper_orig ELSE cod_oper_rel END cod_oper 
            INTO
                v_cod_oper
            FROM 
                vve_cred_soli 
            WHERE 
                cod_soli_cred = p_cod_soli_cred;
        EXCEPTION
            WHEN OTHERS THEN
                v_cod_oper := NULL;
        END;  
        
        
        BEGIN
            SELECT 
                cod_simu INTO v_cod_simu
            FROM 
                vve_cred_simu 
            WHERE 
                cod_soli_cred = p_cod_soli_cred and ind_inactivo = 'N';
        EXCEPTION
            WHEN OTHERS THEN
            v_cod_simu := '0';
        END;
        
        
        -- GENERANDO LAS LISTAS
        OPEN p_ret_oper_regi FOR
            SELECT 
                (select fec_firm_cont from vve_cred_soli  WHERE cod_soli_cred = p_cod_soli_cred) AS fecha_contrato,
                fecha_ini as fecha_entrega,
                tipodocgen AS tipo_docu
            FROM 
                ARLCOP 
            WHERE 
                cod_oper = v_cod_oper;
        
        OPEN p_ret_docu FOR
            SELECT 
                tipo_docu as tipo_doc, 
                no_docu, 
                TO_CHAR(fecha, 'DD/MM/YYYY') AS FECHA_VENCE, 
                moneda, 
                monto AS SALDO 
            FROM 
                ARLCRD 
            WHERE 
                cod_oper = v_cod_oper;
                
        
        OPEN p_ret_docu_total FOR
            SELECT 
                SUM(monto) AS TOTAL 
            FROM 
                ARLCRD 
            WHERE 
                cod_oper = v_cod_oper; 
                
        
        OPEN p_ret_gasto FOR
            SELECT 
                cod_gasto as cod_gast, 
                (SELECT 
                UPPER(des_conc)
                FROM 
                vve_cred_simu_gast sg INNER JOIN vve_cred_maes_conc_letr ml
                ON (sg.cod_conc_col = ml.cod_conc_col)
                WHERE  
                cod_simu = v_cod_simu AND ind_fin = 'N' AND ROWNUM = 1) 
                AS des_conc,
                moneda, monto as val_mon_total
            FROM 
                ARLCGO 
            WHERE 
                cod_oper = v_cod_oper;
                
                
        OPEN p_ret_gasto_total FOR
            SELECT 
                SUM(monto) as TOTAL
            FROM 
                ARLCGO 
            WHERE 
                cod_oper = v_cod_oper;
        
        
        OPEN p_ret_aval FOR        
            SELECT 
                sec_aval, 
                nom_aval, 
                direc_aval, 
                telf_aval, 
                le, 
                des_aval 
            FROM 
                ARLCAV 
            WHERE 
                cod_oper = v_cod_oper;
        
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
   
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_OPER_REGI', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_REPRO_OPER:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_OPER_REGI', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
            
  END sp_list_oper_regi; 
  
  
  PROCEDURE sp_list_crono_lxc
    (
    p_cod_soli_cred       IN                vve_cred_soli.cod_soli_cred%TYPE, 
    p_cod_usua_sid        IN                sistemas.usuarios.co_usuario%TYPE,
    p_ret_cursor          OUT               SYS_REFCURSOR,
    p_ret_totales         OUT               SYS_REFCURSOR,
    p_ret_datos_gen       OUT               SYS_REFCURSOR,
    p_ret_esta            OUT               NUMBER,
    p_ret_mens            OUT               VARCHAR2   
    ) AS
    
    ve_error EXCEPTION;
    v_cop_oper VARCHAR2(12);
    v_cod_empr VARCHAR2(2);
    v_cod_clie VARCHAR2(8);
    
    BEGIN
    
        BEGIN 
            SELECT 
                CASE WHEN cod_oper_rel IS NOT NULL THEN 
                cod_oper_rel 
                ELSE cod_oper_orig END AS cod_oper,
                cod_empr,
                cod_clie
            INTO
                v_cop_oper, 
                v_cod_empr,
                v_cod_clie
            FROM 
                vve_cred_soli 
            WHERE 
                cod_soli_cred = p_cod_soli_cred;
        EXCEPTION
            WHEN OTHERS THEN
            v_cop_oper := NULL;
        END;
        
        dbms_output.put_line(v_cop_oper);
        dbms_output.put_line(v_cod_empr);
        dbms_output.put_line(v_cod_clie);
    
        IF v_cop_oper IS NOT NULL THEN
    
            /*OPEN p_ret_cursor FOR
                SELECT 
                    monto_inicial AS saldo_inicial, 
                    amortizacion, 
                    intereses, 
                    nvl(val_seguro_veh + igv_seguro, 0) AS seguro, 
                    cuota, 
                    nvl(monto_inicial - amortizacion, 0) AS saldo_final,
                    f_vence AS fecha_venc
                FROM 
                    ARLCML 
                WHERE 
                    cod_oper = v_cop_oper;*/
                    
            OPEN p_ret_cursor FOR      
                SELECT   
                    b.no_letra, b.nro_sec, b.ind_cuota_ext, 
                    b.monto_inicial AS saldo_inicial, 
                    case when nvl(IND_PERIODO_GRACIA,'N') = 'N' then b.amortizacion else 0 end amortizacion,
                    case when nvl(IND_PERIODO_GRACIA,'N') = 'N' then b.intereses else 0 end intereses,
                    case when nvl(IND_PERIODO_GRACIA,'N') = 'N' then b.igv else 0 end igv,
                    case when nvl(IND_PERIODO_GRACIA,'N') = 'N' then b.isc else 0 end isc,  
                    nvl((b.val_seguro_veh + b.igv_seguro), 0) seguro,
                    b.cuota AS cuota,
                    nvl(monto_inicial - amortizacion, 0) AS saldo_final,
                    TO_CHAR(b.f_vence,'DD/MM/YYYY') AS fecha_vence
                FROM 
                      arlcml b, arlcop a
                WHERE 
                    a.no_cia       = v_cod_empr	and
                    a.cod_oper   = nvl(v_cop_oper, a.cod_oper) and
                    a.no_cliente  = nvl(v_cod_clie, a.no_cliente) and
                    a.no_cia        = b.no_cia(+) and
                    a.cod_oper    = b.cod_oper(+)
               ORDER BY
                    b.nro_sec;
                    
                    
            /*OPEN p_ret_totales FOR       
                SELECT 
                    COUNT(*) AS total_cuotas,
                    SUM(monto_inicial) AS total_financiar, 
                    SUM(amortizacion) AS total_amortizacion, 
                    SUM(intereses) AS total_interes, 
                    SUM(nvl(val_seguro_veh + igv_seguro, 0)) as total_seguro, 
                    SUM(cuota) AS total_cuota
                FROM 
                    ARLCML 
                WHERE 
                    cod_oper = v_cop_oper;  */
                    
            OPEN p_ret_totales FOR 
                Select  
                    COUNT(*) AS total_cuotas,
                    SUM(CASE WHEN nvl(IND_PERIODO_GRACIA,'N') = 'N' THEN b.monto_inicial ELSE 0 END) AS total_financiar, 
                    SUM(CASE WHEN nvl(IND_PERIODO_GRACIA,'N') = 'N' THEN b.amortizacion ELSE 0 END) total_amortizacion,
                    SUM(CASE WHEN nvl(IND_PERIODO_GRACIA,'N') = 'N' THEN b.intereses ELSE 0 END) total_interes,  
                    SUM(CASE WHEN nvl(IND_PERIODO_GRACIA,'N') = 'N' THEN b.igv ELSE 0 END) total_igv,
                    SUM(CASE WHEN nvl(IND_PERIODO_GRACIA,'N') = 'N' THEN b.isc ELSE 0 END) total_isc,  
                    SUM(nvl(b.val_seguro_veh + b.igv_seguro,0)) total_seguro,
                    SUM(b.cuota) total_cuota
                FROM 
                    arlcml b, arlcop a
                WHERE 
                    a.no_cia       = v_cod_empr	and
                    a.cod_oper   = nvl(v_cop_oper, a.cod_oper)	and
                    a.no_cliente  = nvl(v_cod_clie, a.no_cliente)	and
                    a.no_cia        = b.no_cia(+)	and
                    a.cod_oper    = b.cod_oper(+)
                GROUP BY b.cod_oper;
                
            
            OPEN p_ret_datos_gen FOR
                SELECT 
                    a.no_cia, a.grupo, a.cod_oper, a.tea,
                    decode(a.estado,'P', 'PENDIENTE','U','ANULADO','I','IMPRESO','A','ACTUALIZADO') estado, 
                    TO_CHAR(a.fecha_ini, 'DD/MM/YYYY') AS fecha_cronograma, 
                    a.moneda, 
                    a.tipo_cambio, 
                    a.no_cliente,
                    a.total_financiar, 
                    a.no_cuotas, 
                    TO_CHAR(sysdate, 'DD/MM/YYYY') AS fecha_actual,
                    (select nom_perso from gen_persona where cod_perso = v_cod_clie) AS nom_cliente
                FROM 
                    arlcop a
                WHERE 
                    a.no_cia = v_cod_empr AND
                    a.cod_oper = nvl(v_cop_oper, a.cod_oper) AND
                    a.no_cliente = nvl(v_cod_clie, a.no_cliente);
                    
        END IF;
            
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
    
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_CRONO_LXC', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_CRONO_LXC:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_CRONO_LXC', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
            
  END sp_list_crono_lxc;
    
    
    
END PKG_SWEB_CRED_SOLI_LXC; 