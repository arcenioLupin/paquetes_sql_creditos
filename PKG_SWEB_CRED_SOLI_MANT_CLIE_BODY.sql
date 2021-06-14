create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_MANT_CLIE AS

PROCEDURE SP_LIST_CLIENTES(
    p_tipo_cred             IN vve_cred_soli.tip_soli_cred%type,
    p_cod_soli_cred         IN vve_cred_soli.cod_soli_cred%type,
    p_cod_clie              IN gen_persona.cod_perso%type,
    p_cod_clie_sap          IN VARCHAR2,
    p_nom_perso             IN gen_persona.nom_perso%type,
    p_cod_tipo_perso        IN gen_persona.cod_tipo_perso%type,
    p_cod_tipo_docu_iden    IN gen_persona.cod_tipo_docu_iden%type,
    p_num_dni               IN gen_persona.num_docu_iden%type,
    p_num_ruc               IN gen_persona.num_ruc%type,
    p_cod_area_vta          IN gen_area_vta.cod_area_vta%type,
    p_cod_filial            IN gen_filial.cod_filial%type,
    p_cod_cia               IN gen_mae_sociedad.cod_cia%type,
    p_cod_pais              IN gen_mae_pais.cod_id_pais%type,
    p_cod_depa              IN gen_filial.cod_dpto%type,
    p_cod_prov              IN gen_filial.cod_provincia%type,
    p_cod_dist              IN gen_filial.cod_distrito%type,
    p_cod_esta_soli         IN vve_cred_soli.cod_estado%type,
    p_cod_esta_clie         IN gen_persona.ind_inactivo%type,           
    
    p_cod_usua_sid          IN sistemas.usuarios.co_usuario%type,
    p_cod_usua_web          IN sistemas.sis_mae_usuario.cod_id_usuario%type,
    p_ind_paginado          IN VARCHAR2,
    p_limitinf              IN INTEGER,
    p_limitsup              IN INTEGER,
    p_ret_cursor            OUT SYS_REFCURSOR,
    p_ret_cantidad          OUT NUMBER,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR2
) AS
    ve_error            EXCEPTION;
    ln_limitinf         INTEGER := 0;
    ln_limitsup         INTEGER := 0;

BEGIN
    IF p_ind_paginado = 'N' THEN
        SELECT COUNT(1)
            INTO ln_limitsup
        FROM gen_persona;    
    ELSE
        ln_limitinf := 1;
        IF p_limitsup > 10 THEN
            ln_limitsup := 10;
        ELSE
            ln_limitsup := 10;
        END IF;
    END IF; 
    
    OPEN p_ret_cursor FOR
            SELECT  
                    tb1.cod_soli_cred,
                    tb1.tip_soli_cred AS TIPO_CREDITO,
                    (select descripcion from vve_tabla_maes where cod_grupo = '86' and orden_pres is not null 
                        and cod_tipo = tb1.tip_soli_cred) AS DES_TIPO_CREDITO,
                    tb1.cod_clie,
                    DECODE(SUBSTR(MC.COD_CLIE_SAP,4,7),null,SUBSTR(MP.COD_CLIE_SAP,4,7),SUBSTR(MC.COD_CLIE_SAP,4,7)) AS COD_CLIE_SAP,
                    pe.NOM_PERSO, 
                    pe.COD_TIPO_PERSO, 
                    decode(pe.cod_tipo_perso,'N','Natural','J','Juridica') AS DES_TIPO_PERSO,
                    pe.cod_tipo_docu_iden AS COD_TIPO_DOCU,
                    pe.num_docu_iden AS DNI,
                    pe.num_ruc AS RUC,
                    tb1.cod_area_vta,
                    tb1.area_venta,
                    tb1.cod_filial,
                    tb1.nom_filial,
                    tb1.cod_cia,
                    tb1.nom_sociedad,
                    tb1.cod_pais,
                    tb1.nom_pais,
                    tb1.cod_dpto,
                    tb1.cod_provincia,
                    tb1.cod_distrito,
                    --tb1.nom_ubigeo,
                    tb1.cod_vendedor,
                    tb1.vendedor,  
                    tb1.cod_estado AS COD_ESTADO_SOLI,
                    (select descripcion from vve_tabla_maes where cod_grupo = '92' and orden_pres is not null 
                        and cod_tipo = tb1.cod_estado) AS DES_ESTADO_SOLI,
                    pe.ind_inactivo AS COD_ESTADO_CLIE,
                    0 AS SELECCION 
            
            FROM gen_persona pe
            LEFT JOIN cxc_mae_clie mc ON mc.cod_clie = pe.cod_perso  
            LEFT JOIN cxc_clie_pros mp ON mp.cod_clie_pros = pe.cod_perso
            LEFT JOIN (
                  SELECT cs.cod_soli_cred 
                        , cs.tip_soli_cred
                        , (select descripcion from vve_tabla_maes where cod_grupo = '86' and orden_pres is not null 
                            and cod_tipo = cs.tip_soli_cred) as tipo_credito
                        , cs.cod_clie
                        , cs.cod_empr as cod_cia
                        , soc.nom_sociedad
                        , vta.cod_area_vta
                        , vta.des_area_vta as area_venta
                        , fi.cod_filial
                        , fi.nom_filial
                        , pa.cod_id_pais as cod_pais
                        , pa.des_nombre as nom_pais
                        , fi.cod_dpto
                        , fi.cod_provincia
                        , fi.cod_distrito
                        --, ub.nom_ubigeo
                        , pv.vendedor as cod_vendedor
                        , ve.descripcion as vendedor   
                        , cs.ind_inactivo
                        , cs.cod_estado
                        ,(select descripcion from vve_tabla_maes where cod_grupo = '92' and orden_pres is not null 
                            and cod_tipo = cs.cod_estado) as estado_soli
                    FROM vve_cred_soli cs
                    ,vve_cred_soli_prof spf
                    ,vve_proforma_veh pv
                    ,gen_area_vta vta
                    ,gen_mae_sociedad soc
                    ,gen_filial fi
                    ,arccve ve
                    ,gen_mae_pais pa
                    --,gen_ubigeo ub
                    WHERE cs.cod_soli_cred = spf.cod_soli_cred
                    and spf.num_prof_veh = pv.num_prof_veh
                    and cs.tip_soli_cred <> 'TC05'
                    and pv.cod_area_vta = vta.cod_area_vta
                    and cs.cod_empr = soc.cod_cia
                    and cs.cod_empr = fi.cod_cia
                    --and cs.cod_oper_rel is not null
                    and soc.cod_cia = fi.cod_cia
                    and soc.cod_id_pais = pa.cod_id_pais 
                    and pv.cod_filial = fi.cod_filial
                    --and fi.cod_dpto = decode(fi.cod_dpto,null,null,ub.cod_dpto)
                    --and fi.cod_provincia = decode(fi.cod_provincia,null,null,ub.cod_provincia)
                    --and fi.cod_distrito = decode(fi.cod_distrito,null,null,ub.cod_distrito)
                    and pv.vendedor = ve.vendedor
                    --El cliente debe tener nroDocumento
                    and cs.cod_clie IN (
                    select x.cod_perso from gen_persona x where x.ind_inactivo  = 'N' 
                    and (x.cod_tipo_perso = 'N' and x.num_docu_iden is not null) OR (x.cod_tipo_perso = 'J' and x.num_ruc is not null)
                    and x.cod_perso = cs.cod_clie
                    )
                    --order by 1
                
        ) tb1 ON tb1.cod_clie = pe.cod_perso 
            WHERE 1=1
                AND (p_cod_soli_cred IS NULL OR tb1.cod_soli_cred = p_cod_soli_cred)
                AND (p_tipo_cred IS NULL OR tb1.tip_soli_cred = p_tipo_cred)
                AND (p_cod_clie IS NULL OR pe.cod_perso = p_cod_clie)
                AND (p_nom_perso IS NULL OR pe.nom_perso LIKE p_nom_perso||'%')
                AND (p_cod_tipo_perso IS NULL OR pe.cod_tipo_perso = p_cod_tipo_perso)
                AND (p_cod_tipo_docu_iden IS NULL OR pe.cod_tipo_docu_iden = p_cod_tipo_docu_iden)
                AND (p_num_dni IS NULL OR pe.num_docu_iden = p_num_dni)
                AND (p_num_ruc IS NULL OR  pe.num_ruc = p_num_ruc)
                AND (p_cod_area_vta IS NULL OR tb1.cod_area_vta = p_cod_area_vta)
                AND (p_cod_filial IS NULL OR tb1.cod_filial = p_cod_filial)
                AND (p_cod_cia IS NULL OR tb1.cod_cia = p_cod_cia)
                AND (p_cod_pais IS NULL OR tb1.cod_pais = p_cod_pais)
                                --AND (p_cod_depa IS NULL OR tb1.cod_dpto = p_cod_depa)
                                --AND (p_cod_prov IS NULL OR tb1.cod_provincia = p_cod_prov)
                                --AND (p_cod_dist IS NULL OR tb1.cod_distrito = p_cod_dist)
                AND (p_cod_esta_soli IS NULL OR tb1.cod_estado = p_cod_esta_soli)
                AND (p_cod_esta_clie IS NULL OR pe.ind_inactivo = p_cod_esta_clie)
            OFFSET ln_limitinf ROWS FETCH NEXT ln_limitsup ROWS ONLY;
            

    /**
    SENTENCIA PARA EL CONTADOR DE REGISTROS(PAGINADOR)  
    **/
            
      SELECT COUNT(1) 
       INTO p_ret_cantidad
        FROM (
                SELECT *
                FROM gen_persona pe
                LEFT JOIN cxc_mae_clie mc ON mc.cod_clie = pe.cod_perso  
                LEFT JOIN cxc_clie_pros mp ON mp.cod_clie_pros = pe.cod_perso
                LEFT JOIN (
                      SELECT cs.cod_soli_cred 
                            , cs.tip_soli_cred
                            , (select descripcion from vve_tabla_maes where cod_grupo = '86' and orden_pres is not null 
                                and cod_tipo = cs.tip_soli_cred) as tipo_credito
                            , cs.cod_clie
                            , cs.cod_empr as cod_cia
                            , soc.nom_sociedad
                            , vta.cod_area_vta
                            , vta.des_area_vta as area_venta
                            , fi.cod_filial
                            , fi.nom_filial
                            , pa.cod_id_pais as cod_pais
                            , pa.des_nombre as nom_pais
                            , fi.cod_dpto
                            , fi.cod_provincia
                            , fi.cod_distrito
                            --, ub.nom_ubigeo
                            , pv.vendedor as cod_vendedor
                            , ve.descripcion as vendedor   
                            , cs.ind_inactivo
                            , cs.cod_estado
                            ,(select descripcion from vve_tabla_maes where cod_grupo = '92' and orden_pres is not null 
                                and cod_tipo = cs.cod_estado) as estado_soli
                        FROM vve_cred_soli cs
                        ,vve_cred_soli_prof spf
                        ,vve_proforma_veh pv
                        ,gen_area_vta vta
                        ,gen_mae_sociedad soc
                        ,gen_filial fi
                        ,arccve ve
                        ,gen_mae_pais pa
                        --,gen_ubigeo ub
                        WHERE cs.cod_soli_cred = spf.cod_soli_cred
                        and spf.num_prof_veh = pv.num_prof_veh
                        and cs.tip_soli_cred <> 'TC05'
                        and pv.cod_area_vta = vta.cod_area_vta
                        and cs.cod_empr = soc.cod_cia
                        and cs.cod_empr = fi.cod_cia
                        --and cs.cod_oper_rel is not null
                        and soc.cod_cia = fi.cod_cia
                        and soc.cod_id_pais = pa.cod_id_pais 
                        and pv.cod_filial = fi.cod_filial
                        --and fi.cod_dpto = decode(fi.cod_dpto,null,null,ub.cod_dpto)
                        --and fi.cod_provincia = decode(fi.cod_provincia,null,null,ub.cod_provincia)
                        --and fi.cod_distrito = decode(fi.cod_distrito,null,null,ub.cod_distrito)
                        and pv.vendedor = ve.vendedor
                        --El cliente debe tener nroDocumento
                        and cs.cod_clie IN (
                        select x.cod_perso from gen_persona x where x.ind_inactivo  = 'N' 
                        and (x.cod_tipo_perso = 'N' and x.num_docu_iden is not null) OR (x.cod_tipo_perso = 'J' and x.num_ruc is not null)
                        and x.cod_perso = cs.cod_clie
                        )
                        --order by 1
                    
            ) tb1 ON tb1.cod_clie = pe.cod_perso 
                WHERE 1=1
                    AND (p_cod_soli_cred IS NULL OR tb1.cod_soli_cred = p_cod_soli_cred)
                    AND (p_tipo_cred IS NULL OR tb1.tip_soli_cred = p_tipo_cred)
                    AND (p_cod_clie IS NULL OR pe.cod_perso = p_cod_clie)
                    AND (p_nom_perso IS NULL OR pe.nom_perso LIKE p_nom_perso||'%')
                    AND (p_cod_tipo_perso IS NULL OR pe.cod_tipo_perso = p_cod_tipo_perso)
                    AND (p_cod_tipo_docu_iden IS NULL OR pe.cod_tipo_docu_iden = p_cod_tipo_docu_iden)
                    AND (p_num_dni IS NULL OR pe.num_docu_iden = p_num_dni)
                    AND (p_num_ruc IS NULL OR  pe.num_ruc = p_num_ruc)
                    AND (p_cod_area_vta IS NULL OR tb1.cod_area_vta = p_cod_area_vta)
                    AND (p_cod_filial IS NULL OR tb1.cod_filial = p_cod_filial)
                    AND (p_cod_cia IS NULL OR tb1.cod_cia = p_cod_cia)
                    AND (p_cod_pais IS NULL OR tb1.cod_pais = p_cod_pais)
                    --AND (p_cod_depa IS NULL OR tb1.cod_dpto = p_cod_depa)
                    --AND (p_cod_prov IS NULL OR tb1.cod_provincia = p_cod_prov)
                    --AND (p_cod_dist IS NULL OR tb1.cod_distrito = p_cod_dist)
                    AND (p_cod_esta_soli IS NULL OR tb1.cod_estado = p_cod_esta_soli)
                    AND (p_cod_esta_clie IS NULL OR pe.ind_inactivo = p_cod_esta_clie)
               
               );

      p_ret_esta := 1;
      p_ret_mens := 'La consulta se realizó de manera exitosa';

EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_CLIENTES', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
        , NULL);
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LIST_FICHA_VENTA_web:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_CLIENTES', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
        , NULL);
END SP_LIST_CLIENTES;

PROCEDURE SP_LIST_COD_OPERS(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        p_cod_oper          IN VARCHAR2,
        p_cod_tipo_oper     IN VARCHAR2,
        p_cod_mone          IN VARCHAR2,
        p_estado            IN VARCHAR2,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    ) AS
  
    BEGIN
     --Lista de Operaciones por cliente
        OPEN p_ret_cursor FOR
             SELECT * from (SELECT cod_oper_rel as cod_oper,
               tip_soli_cred as cod_tipo_oper,
               cod_mone_soli as cod_moneda,
               decode(ind_inactivo,'N','Vigente','Cerrado') as estado
              FROM vve_cred_soli 
              WHERE cod_clie = p_cod_clie
              AND ind_inactivo = 'N'
            UNION
            SELECT cod_oper as cod_oper,
                     decode(modal_cred,'F','TC01','M','TC03','P','TC05','R','TC07') as cod_tipo_oper,
                     moneda as cod_moneda,
                     decode(estado,'A','Vigente','Cerrado') as estado
            FROM arlcop  
            WHERE no_cliente = p_cod_clie
            AND estado = 'A') x
            WHERE 1=1
            AND (p_cod_oper IS NULL OR p_cod_oper = x.cod_oper)
            AND (p_cod_tipo_oper IS NULL OR p_cod_tipo_oper = x.cod_tipo_oper)
            AND (p_cod_mone IS NULL OR p_cod_mone = x.cod_moneda)
            AND (p_estado IS NULL OR p_estado = x.estado)
           
            ; 
 
      p_ret_esta := 1;
      p_ret_mens := 'La consulta se realizó de manera exitosa';

END SP_LIST_COD_OPERS;


PROCEDURE SP_LIST_OPERS(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        p_cod_oper          IN vve_cred_soli.cod_oper_rel%type,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    ) AS
    v_cod_solid_cred        VARCHAR2(20);
    v_cod_cia               vve_cred_soli.cod_empr%type;
    v_nro_operacion         vve_cred_soli.cod_oper_rel%type;
    v_cod_tipo_operacion    VARCHAR2(20);
    v_tipo_operacion        VARCHAR2(20);
    v_fecha_otorgamiento    VARCHAR2(20);
    v_fecha_vencimiento     VARCHAR2(20);
    v_plazo_dias            VARCHAR2(20);
    v_tea_porc              VARCHAR2(20);
    v_val_porc_tea_sigv     vve_cred_soli.val_porc_tea_sigv%type;
    v_tea                   arlcop.tea%type;
    v_txt_ruta_cart_banc    vve_cred_soli.txt_ruta_cart_banc%type;
    
    /*v_opers_refcur    SYS_REFCURSOR;*/
    
 BEGIN
        v_cod_solid_cred := '';
        v_cod_cia := '';
        v_cod_tipo_operacion := '';
        v_tipo_operacion := '';
        v_fecha_otorgamiento := '';
        v_tea_porc := '';
        
        --00000000000000000001	50547094	5534
     
        --Obtener codSoliCred , codCia, nroOperacion
        SELECT sc.cod_soli_cred, sc.cod_empr, sc.tip_soli_cred, sc.cod_oper_rel
          INTO v_cod_solid_cred, v_cod_cia, v_cod_tipo_operacion, v_nro_operacion
          FROM vve_cred_soli sc
         WHERE sc.cod_clie = p_cod_clie
           AND sc.cod_oper_rel IS NOT NULL; 
                
        IF(v_cod_solid_cred <> '') THEN
            SELECT distinct(no_cia) INTO v_cod_cia 
            FROM arlcop WHERE no_cliente = p_cod_clie;
        
        ELSE
            SELECT sc.cod_soli_cred, sc.cod_empr, sc.tip_soli_cred
              INTO v_cod_solid_cred, v_cod_cia, v_cod_tipo_operacion
              FROM vve_cred_soli sc
             WHERE sc.cod_clie = '50547094'--p_cod_clie
               AND (sc.ind_inactivo IS NULL OR sc.ind_inactivo <> 'S')
               AND sc.cod_estado = 'ES02'; --VIGENTE
        END IF;
        
        
        --NRO_OPERACION
        --v_nro_operacion := p_cod_oper;
        
        --TIPO_OPERACION
        IF(v_cod_solid_cred <> '' AND v_cod_tipo_operacion <> '') THEN
            SELECT m.cod_tipo,m.descripcion INTO v_cod_tipo_operacion, v_tipo_operacion
              FROM vve_tabla_maes m, vve_cred_soli cs
             WHERE cs.cod_clie = p_cod_clie--<cod_cliente> 
               AND cs.cod_oper_rel IN (p_cod_oper)--<nro_operacion> 
               AND m.cod_grupo = 86
               AND m.cod_tipo = cs.tip_soli_cred;
           
        ELSE 
            SELECT m.cod_tipo,m.descripcion INTO v_cod_tipo_operacion, v_tipo_operacion
              FROM vve_tabla_maes m 
             WHERE m.cod_grupo = 86
               AND m.cod_tipo IN (SELECT decode(o.modal_cred,'F','TC01','M','TC03','P','TC05','R','TC07') 
                                    FROM arlcop o
                                   WHERE o.no_cliente = p_cod_clie--<cod_cliente>
                                     AND cod_oper IN (p_cod_oper)--<nro_operacion> 
                                );
           
        END IF;
        
           
        --FECHA_OTORGAMIENTO
        IF(v_cod_solid_cred IS NOT NULL AND v_fecha_otorgamiento <> '') THEN
             SELECT DECODE(fec_apro_inte,NULL,NULL,TO_CHAR(fec_apro_inte,'DD/MM/YYYY HH24:MI:SS')) INTO v_fecha_otorgamiento
               FROM vve_cred_soli WHERE cod_clie = p_cod_clie
                AND cod_oper_rel = p_cod_oper;
        ELSE
            SELECT DECODE(fecha_aut_ope,NULL,NULL,TO_CHAR(fecha_aut_ope,'DD/MM/YYYY HH24:MI:SS')) INTO v_fecha_otorgamiento
              FROM arlcop 
             WHERE no_cliente = p_cod_clie
               AND cod_oper = p_cod_oper;
        END IF;
        
        --FECHA_VENCIMIENTO
        SELECT MAX(to_char(f_vence,'DD/MM/YYYY HH24:MI:SS')) fec_vencimiento INTO v_fecha_vencimiento
               FROM arlcml  
              WHERE cod_oper = p_cod_oper --<nro_operacion>
                AND no_cliente = p_cod_clie --<cod_cliente>
                AND (v_cod_cia = '' OR v_cod_cia = no_cia) --<cod_empresa de la op o solicitud>
           GROUP BY cod_oper;
        
        --PLAZO DIAS
        SELECT q.plazo_dias_op||' días' INTO v_plazo_dias from (SELECT (CASE nvl(ind_per_gra,'N')  
               WHEN 'S' THEN (no_cuotas+1)*fre_pago_dias 
               WHEN 'N' THEN no_cuotas*fre_pago_dias 
               END) plazo_dias_op 
        FROM arlcop 
        WHERE cod_oper = p_cod_oper--<nro_operacion> 
        AND NOT EXISTS (SELECT 1 FROM vve_cred_soli WHERE cod_clie = p_cod_clie AND cod_oper_rel = cod_oper) 
        UNION
        SELECT no_cuotas*fre_pago_dias AS plazo_dias_op 
        FROM arlcop
        WHERE cod_oper = p_cod_oper--<nro_operacion>  
        AND EXISTS (SELECT 1 FROM vve_cred_soli WHERE cod_clie = p_cod_clie AND cod_oper_rel = cod_oper)) q ;
  
      
       --TEA
       SELECT sc.val_porc_tea_sigv, o.tea INTO  v_val_porc_tea_sigv, v_tea
             FROM vve_cred_soli sc, arlcop o
            WHERE sc.cod_oper_rel = o.cod_oper 
              AND sc.cod_clie = o.no_cliente
              AND sc.cod_oper_rel = p_cod_oper
              AND sc.cod_clie = p_cod_clie;
       
       IF(v_val_porc_tea_sigv IS NOT NULL AND v_tea IS NOT NULL) THEN
           SELECT round((v_val_porc_tea_sigv / v_tea),2) INTO  v_tea_porc
             FROM vve_cred_soli sc, arlcop o
            WHERE sc.cod_oper_rel = o.cod_oper 
              AND sc.cod_clie = o.no_cliente
              AND sc.cod_oper_rel = p_cod_oper
              AND sc.cod_clie = p_cod_clie; 
        
        ELSE
          v_tea_porc := '0.00';
        END IF;
        
        --
        SELECT sc.txt_ruta_cart_banc INTO  v_txt_ruta_cart_banc
             FROM vve_cred_soli sc/*, arlcop o
            WHERE sc.cod_oper_rel = o.cod_oper 
              AND sc.cod_clie = o.no_cliente*/
              WHERE sc.cod_oper_rel = p_cod_oper
              AND sc.cod_clie = p_cod_clie; 
        
        --dbms_output.put_line(v_cod_cia||','||v_nro_operacion||','||v_cod_tipo_operacion||','||v_tipo_operacion||','||v_fecha_otorgamiento||','||v_fecha_vencimiento||','||v_plazo_dias||','||v_tea_porc);
    
   
        OPEN p_ret_cursor FOR
        SELECT v_cod_cia AS NRO_CIA,
               p_cod_oper AS NRO_OPERACION,
               v_cod_tipo_operacion AS COD_TIPO_OPERACION,
               v_tipo_operacion AS TIPO_OPERACION,
               v_fecha_otorgamiento AS FEC_OTORGAMIENTO,
               v_fecha_vencimiento AS FEC_VENCIMIENTO,
               v_plazo_dias AS PLAZO_DIAS,
               v_tea_porc AS TEA,
               v_txt_ruta_cart_banc AS CARTA_BANCO
               
               FROM DUAL;     
 
      p_ret_esta := 1;
      p_ret_mens := 'La consulta se realizó de manera exitosa';
      
  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_CRED_SOLI_VC_OPERS:' || SQLERRM;
  END SP_LIST_OPERS;


PROCEDURE SP_LIST_GARAN(
        p_cod_clie          IN vve_cred_soli.cod_clie%type,
        p_cod_oper          IN vve_cred_soli.cod_oper_rel%type,
        p_cod_gara          IN vve_cred_maes_gara.cod_garantia%type,
        p_tipo_gara         IN vve_cred_maes_gara.ind_tipo_garantia%type,
        p_cod_esta_poli     IN vve_cred_soli.cod_esta_poli%type,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    ) AS
    v_estado_inactivo   VARCHAR2(1);
 BEGIN
    v_estado_inactivo:= 'S';
            OPEN p_ret_cursor FOR
           
            SELECT s.cod_soli_cred,
                   s.cod_oper_rel AS NRO_OPERACION,
                   g.cod_garantia AS NRO_GARANTIA,
                   g.ind_tipo_garantia as ind_tipo_garantia,
                   decode(g.ind_tipo_garantia,'M','Mobiliaria','H','Hipotecaria') AS DES_TIPO_GARANTIA,
                   s.tip_soli_cred as cod_tipo_credito,
                   (select descripcion from vve_tabla_maes where cod_grupo = '86' and cod_tipo = s.tip_soli_cred) as des_tipo_credito,
                   sg.ind_gara_adic as gara_adic,
                   (CASE nvl(sg.ind_gara_adic,'N') WHEN 'N' THEN s.nro_poli_seg WHEN 'S' THEN NULL  END) AS NRO_POLIZA, 
                   (CASE nvl(sg.ind_gara_adic,'N') WHEN 'N' THEN s.cod_esta_poli WHEN 'S' THEN NULL END) AS COD_EST_POLIZA,
                    decode(nvl(sg.ind_gara_adic,'N'),'N',
                          (SELECT descripcion 
                             FROM vve_tabla_maes m 
                            WHERE m.cod_grupo = 109 
                              AND cod_tipo = s.cod_esta_poli),null, null) AS EST_POLIZA,
                   'USD' AS DIVISA,
                   g.val_const_gar*0.8 AS VAL_COMERCIAL,
                   g.val_realiz_gar AS VAL_REALIZ,
                   g.fec_fab_const AS FEC_CONST,
                   g.cod_marca,
                   g.txt_marca,
                   g.txt_modelo,
                   g.cod_tipo_veh,
                   g.nro_placa,
                   g.val_ano_fab,
                   sg.cod_rang_gar,
                   (select descripcion from vve_tabla_maes where cod_grupo = '106' and cod_tipo = sg.cod_rang_gar) as des_rang_gar,
                   sg.ind_inactivo
                   FROM vve_cred_maes_gara g, vve_cred_soli_gara sg, vve_cred_soli s
            WHERE  s.cod_clie = p_cod_clie--<cod_cliente>
            AND s.cod_soli_cred = sg.cod_soli_cred 
            AND sg.cod_gara = g.cod_garantia 
            AND s.cod_oper_rel = p_cod_oper--<cod_oper>
            --AND sg.ind_inactivo = 'N'
                AND (sg.ind_inactivo IS NULL OR sg.ind_inactivo <> v_estado_inactivo)
            AND (p_cod_oper IS NULL OR p_cod_oper = s.cod_oper_rel)
            AND (p_cod_gara IS NULL OR p_cod_gara = g.cod_garantia)
            AND (p_tipo_gara IS NULL OR p_tipo_gara = g.ind_tipo_garantia)
            AND (p_cod_esta_poli IS NULL OR (p_cod_esta_poli = s.cod_esta_poli and sg.ind_gara_adic is null))
            --and s.cod_oper_rel in ( '5621','5783','5785','5890','5892','5990','6166','6418')
            ORDER BY 3;
      
 
      p_ret_esta := 1;
      p_ret_mens := 'La consulta se realizó de manera exitosa';
      
  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_CRED_SOLI_VC_GARAN:' || SQLERRM; 
  END SP_LIST_GARAN;
  
   PROCEDURE SP_ACT_GARANTIA
  (
     p_cod_soli_cred     IN vve_cred_soli_aval.cod_soli_cred%TYPE,
     p_cod_gara          IN vve_cred_maes_gara.cod_garantia%TYPE,
     p_cod_clie          IN vve_cred_maes_gara.cod_cliente%TYPE,
     p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
     p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
     p_ret_esta          OUT NUMBER,
     p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN

    UPDATE vve_cred_soli_gara sg 
       SET cod_rang_gar = null, cod_usua_modi_regi = p_cod_usua_web, fec_modi_regi = sysdate
     WHERE cod_gara = p_cod_gara
       AND cod_soli_cred = p_cod_soli_cred;
    COMMIT;  
    
    UPDATE vve_cred_maes_gara 
       SET val_nro_rango = null, cod_usua_modi_regi = p_cod_usua_web, fec_modi_regi = sysdate
     WHERE cod_garantia = p_cod_gara
       AND cod_cliente = p_cod_clie;
    COMMIT;    
    
    p_ret_esta := 1;
    p_ret_mens := 'La garantía se actualizó con éxito.';
  EXCEPTION
       WHEN OTHERS THEN
        p_ret_esta := -1;
          p_ret_mens := 'SP_ACT_GARANTIA_EXCEP:' || SQLERRM;
          pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                              'SP_ACT_GARANTIA',
                                              'SP_ACT_GARANTIA',
                                              'Error al actualizar la garantía',
                                              p_ret_mens,
                                              p_cod_soli_cred);
          ROLLBACK;
          
  END SP_ACT_GARANTIA;
   

END PKG_SWEB_CRED_SOLI_MANT_CLIE; 