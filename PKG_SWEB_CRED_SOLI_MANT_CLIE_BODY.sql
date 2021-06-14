create or replace PACKAGE BODY   VENTA.PKG_SWEB_CRED_SOLI_MANT_CLIE AS

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
    p_cod_zona              IN vve_mae_zona.cod_zona%type,
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
    v_depa_x            VARCHAR2(2);
    v_prov_x            VARCHAR2(2);
    v_dist_x            VARCHAR2(2);
    v_cod_tipo_docu_iden VARCHAR(3);
BEGIN

    -- PARA FILTRAR POR RUC
    IF p_num_ruc is not null THEN 
      v_cod_tipo_docu_iden := NULL;
    ELSE 
      v_cod_tipo_docu_iden := p_cod_tipo_docu_iden;
    END IF;

  --I Req. 87567 E2.1 ID:304 avilca 24/04/2020> 
    IF p_ind_paginado = 'N' THEN
        SELECT COUNT(1)
            INTO ln_limitsup
        FROM vve_cred_soli;  
    ELSE
        ln_limitinf := p_limitinf - 1;
        ln_limitsup := p_limitsup;
    END IF;
    
    dbms_output.put_line(ln_limitinf);
    dbms_output.put_line(ln_limitsup);
    
    /* Req. obs Consulta Cliente MBardales 19/10/2020 */
    IF p_cod_depa IS NOT NULL THEN
        SELECT substr(des_codigo, 5, 6) into v_depa_x  FROM gen_mae_departamento WHERE cod_id_departamento = p_cod_depa;
        dbms_output.put_line(v_depa_x);
    END IF;
    
    IF p_cod_prov IS NOT NULL THEN
        SELECT substr(des_codigo, 7, 8) into v_prov_x  FROM gen_mae_provincia WHERE cod_id_provincia = p_cod_prov;
        dbms_output.put_line(v_prov_x);
    END IF;
    
    IF p_cod_dist IS NOT NULL THEN
        SELECT substr(des_codigo, 9, 10) into v_dist_x  FROM gen_mae_distrito WHERE cod_id_distrito = p_cod_dist;
        dbms_output.put_line(v_dist_x);
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
                    tb1.cod_zona, --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                    tb1.des_zona,--Req. 87567 E2.1 ID:1 avilca 10/09/2020
                    tb1.cod_cia,
                    tb1.nom_sociedad,
                    tb1.cod_pais,
                    tb1.nom_pais,
                    tb1.cod_dpto,                    
                    (SELECT nom_ubigeo from gen_ubigeo u where u.cod_dpto = tb1.cod_dpto and u.cod_provincia = '00'  and u.cod_distrito = '00')as des_dpto,
                    tb1.cod_provincia,                    
                    (select nom_ubigeo from gen_ubigeo u where u.cod_dpto = tb1.cod_dpto  and u.cod_provincia = tb1.cod_provincia  and u.cod_distrito = '00')as des_provincia,
                    tb1.cod_distrito,
                    (select nom_ubigeo from gen_ubigeo u where u.cod_dpto = tb1.cod_dpto and u.cod_provincia = tb1.cod_provincia   and u.cod_distrito = tb1.cod_distrito)as des_distrito,
                    tb1.nom_ubigeo,
                    tb1.cod_vendedor,
                    tb1.vendedor,  
                    tb1.cod_estado AS COD_ESTADO_SOLI,
                    (select descripcion from vve_tabla_maes where cod_grupo = '92' and orden_pres is not null 
                        and cod_tipo = tb1.cod_estado) AS DES_ESTADO_SOLI,
                    pe.ind_inactivo AS COD_ESTADO_CLIE,
                    0 AS SELECCION,
                    tb1.ind_inactivo,
                    pe.cod_area_telf_movil as cod_call, -- Req. Obs Consulta Cliente MBardales 14/10/2020
                    pe.num_telf_movil as nro_cel -- Req. Obs Consulta Cliente MBardales 14/10/2020
            
            FROM gen_persona pe
            LEFT JOIN cxc_mae_clie mc ON mc.cod_clie = pe.cod_perso  
            LEFT JOIN cxc_clie_pros mp ON mp.cod_clie_pros = pe.cod_perso
            JOIN (
                  SELECT cs.cod_soli_cred 
                        , cs.tip_soli_cred
                        ,cs.cod_clie
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
                        , ub.nom_ubigeo
                        , pv.vendedor as cod_vendedor
                        , ve.descripcion as vendedor   
                        , cs.cod_estado
                        , mz.cod_zona --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                        , mz.des_zona --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                        , cs.ind_inactivo --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                        
                        
                    FROM   vve_cred_soli cs
                     JOIN  vve_cred_soli_prof spf ON cs.cod_soli_cred = spf.cod_soli_cred
                     JOIN  vve_proforma_veh pv ON 	spf.num_prof_veh = pv.num_prof_veh	
                     JOIN  gen_area_vta vta ON 	pv.cod_area_vta = vta.cod_area_vta
                     JOIN gen_mae_sociedad soc	ON cs.cod_empr = soc.cod_cia 
                     JOIN gen_filial fi ON 	cs.cod_empr = fi.cod_cia and soc.cod_cia = fi.cod_cia  and pv.cod_filial = fi.cod_filial
                     JOIN vve_mae_zona_filial mzf ON fi.cod_filial = mzf.cod_filial --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                     JOIN vve_mae_zona mz ON mzf.cod_zona =  mz.cod_zona  --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                     JOIN gen_mae_pais pa ON  soc.cod_id_pais = pa.cod_id_pais 
                     JOIN gen_ubigeo ub ON	fi.cod_dpto = decode(fi.cod_dpto,null,null,ub.cod_dpto) 
					      and fi.cod_provincia = decode(fi.cod_provincia,null,null,ub.cod_provincia)
                          and fi.cod_distrito = decode(fi.cod_distrito,null,null,ub.cod_distrito) 
                     JOIN arccve ve ON pv.vendedor = ve.vendedor
                     JOIN gen_dir_perso gdp ON cs.cod_clie = gdp.cod_perso

                     
               
              UNION    
                    SELECT
                       cs.cod_soli_cred,
                       cs.tip_soli_cred, 
                       cs.cod_clie,
                       cs.cod_empr as cod_cia,
                       soc.nom_sociedad,                                    
                       gav.cod_area_vta,
                       gav.des_area_vta as area_venta,                     
                       null as cod_filial,
                       null as nom_filial,
                       pa.cod_id_pais as cod_pais,
                       pa.des_nombre as nom_pais,                    
                       null as cod_dpto,             
                       null as cod_provincia,               
                       null as cod_distrito,
                       null as nom_ubigeo,
                       null as cod_vendedor,
                       null as vendedor,           
                       cs.cod_estado,
                       null cod_zona, --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                       null des_zona, --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                       cs.ind_inactivo
                    FROM
                       vve_cred_soli cs	
                     JOIN  gen_area_vta gav ON 	cs.cod_area_vta = gav.cod_area_vta
                     JOIN gen_mae_sociedad soc	ON cs.cod_empr = soc.cod_cia 
                     JOIN gen_mae_pais pa ON  soc.cod_id_pais = pa.cod_id_pais    
                     JOIN gen_dir_perso gdp ON cs.cod_clie = gdp.cod_perso
                             
                   WHERE cs.cod_soli_cred not in (
                                                  SELECT cs.cod_soli_cred                        
                                                    FROM    vve_cred_soli cs
                                                     JOIN  vve_cred_soli_prof spf ON cs.cod_soli_cred = spf.cod_soli_cred
                                                     JOIN  vve_proforma_veh pv ON 	spf.num_prof_veh = pv.num_prof_veh	
                                                     JOIN  gen_area_vta vta ON 	pv.cod_area_vta = vta.cod_area_vta
                                                     JOIN gen_mae_sociedad soc	ON cs.cod_empr = soc.cod_cia 
                                                     JOIN gen_filial fi ON 	cs.cod_empr = fi.cod_cia and soc.cod_cia = fi.cod_cia  and pv.cod_filial = fi.cod_filial
                                                     JOIN vve_mae_zona_filial mzf ON fi.cod_filial = mzf.cod_filial --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                                                     JOIN vve_mae_zona mz ON mzf.cod_zona =  mz.cod_zona --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                                                     JOIN gen_mae_pais pa ON  soc.cod_id_pais = pa.cod_id_pais 
                                                     JOIN gen_ubigeo ub ON	fi.cod_dpto = decode(fi.cod_dpto,null,null,ub.cod_dpto) 
                                                          and fi.cod_provincia = decode(fi.cod_provincia,null,null,ub.cod_provincia)
                                                          and fi.cod_distrito = decode(fi.cod_distrito,null,null,ub.cod_distrito) 
                                                     JOIN  arccve ve ON pv.vendedor = ve.vendedor

                                                )
                             
                
        ) tb1 ON tb1.cod_clie = pe.cod_perso
            WHERE 1=1
                AND (p_cod_soli_cred IS NULL OR tb1.cod_soli_cred = p_cod_soli_cred)
                AND (p_tipo_cred IS NULL OR tb1.tip_soli_cred = p_tipo_cred)
                AND (p_cod_clie IS NULL OR pe.cod_perso = p_cod_clie)               
                AND (p_cod_clie_sap IS NULL OR DECODE(SUBSTR(MC.COD_CLIE_SAP,4,7),null,SUBSTR(MP.COD_CLIE_SAP,4,7),SUBSTR(MC.COD_CLIE_SAP,4,7)) = p_cod_clie_sap)                               
                AND (p_nom_perso IS NULL OR pe.nom_perso LIKE  '%'||p_nom_perso||'%')
                AND (p_cod_tipo_perso IS NULL OR pe.cod_tipo_perso = p_cod_tipo_perso)
                AND (v_cod_tipo_docu_iden IS NULL OR pe.cod_tipo_docu_iden = v_cod_tipo_docu_iden)
                AND (p_num_dni IS NULL OR pe.num_docu_iden = p_num_dni)
                AND (p_num_ruc IS NULL OR  pe.num_ruc = p_num_ruc)
                AND (p_cod_area_vta IS NULL OR tb1.cod_area_vta = p_cod_area_vta)
                AND (p_cod_filial IS NULL OR tb1.cod_filial = p_cod_filial) 
                AND (p_cod_zona IS NULL OR tb1.cod_zona = p_cod_zona) --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                AND (p_cod_cia IS NULL OR tb1.cod_cia = p_cod_cia)
                AND (p_cod_pais IS NULL OR tb1.cod_pais = p_cod_pais)
                --I Req. 87567 E2.1 ID:131 avilca 12/02/2020> 
                -- Req. Modificado Consulta Cliente MBardales 19/10/2020
                AND (v_depa_x IS NULL OR tb1.cod_dpto = v_depa_x)
                AND (v_prov_x IS NULL OR tb1.cod_provincia = v_prov_x)
                AND (v_dist_x IS NULL OR tb1.cod_distrito = v_dist_x)
                --F Req. 87567 E2.1 ID:131 avilca 12/02/2020> 
                AND (p_cod_esta_soli IS NULL OR tb1.cod_estado = p_cod_esta_soli)
                AND (p_cod_esta_clie IS NULL OR pe.ind_inactivo = p_cod_esta_clie)
                AND tb1.ind_inactivo = 'N'
                ORDER BY tb1.cod_soli_cred ASC   
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
            JOIN (
                  SELECT cs.cod_soli_cred 
                        , cs.tip_soli_cred
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
                        , ub.nom_ubigeo
                        , pv.vendedor as cod_vendedor
                        , ve.descripcion as vendedor   
                        , cs.cod_estado
                        , mz.cod_zona --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                        , mz.des_zona --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                        , cs.ind_inactivo  --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                        
                        
                    FROM    vve_cred_soli cs
                     JOIN  vve_cred_soli_prof spf ON cs.cod_soli_cred = spf.cod_soli_cred
                     JOIN  vve_proforma_veh pv ON 	spf.num_prof_veh = pv.num_prof_veh	
                     JOIN  gen_area_vta vta ON 	pv.cod_area_vta = vta.cod_area_vta
                     JOIN gen_mae_sociedad soc	ON cs.cod_empr = soc.cod_cia 
                     JOIN gen_filial fi ON 	cs.cod_empr = fi.cod_cia and soc.cod_cia = fi.cod_cia  and pv.cod_filial = fi.cod_filial
                     JOIN vve_mae_zona_filial mzf ON fi.cod_filial = mzf.cod_filial --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                     JOIN vve_mae_zona mz ON mzf.cod_zona =  mz.cod_zona --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                     JOIN gen_mae_pais pa ON  soc.cod_id_pais = pa.cod_id_pais 
                     JOIN gen_ubigeo ub ON	fi.cod_dpto = decode(fi.cod_dpto,null,null,ub.cod_dpto) 
					      and fi.cod_provincia = decode(fi.cod_provincia,null,null,ub.cod_provincia)
                          and fi.cod_distrito = decode(fi.cod_distrito,null,null,ub.cod_distrito) 
                     JOIN  arccve ve ON pv.vendedor = ve.vendedor

                         
                     
               
              UNION    
                    SELECT
                       cs.cod_soli_cred,
                       cs.tip_soli_cred, 
                       cs.cod_clie,
                       cs.cod_empr as cod_cia,
                       soc.nom_sociedad,                                    
                       gav.cod_area_vta,
                       gav.des_area_vta as area_venta,                     
                       null as cod_filial,
                       null as nom_filial,
                       pa.cod_id_pais as cod_pais,
                       pa.des_nombre as nom_pais,                    
                       null as cod_dpto,             
                       null as cod_provincia,               
                       null as cod_distrito,
                       null as nom_ubigeo,
                       null as cod_vendedor,
                       null as vendedor,           
                       cs.cod_estado, 
                       null cod_zona, --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                       null des_zona, --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                       cs.ind_inactivo  --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                    FROM
                       vve_cred_soli cs	
                     JOIN  gen_area_vta gav ON 	cs.cod_area_vta = gav.cod_area_vta
                     JOIN gen_mae_sociedad soc	ON cs.cod_empr = soc.cod_cia 
                     JOIN gen_mae_pais pa ON  soc.cod_id_pais = pa.cod_id_pais                     
                     JOIN gen_dir_perso gdp ON cs.cod_clie = gdp.cod_perso        
                   WHERE cs.cod_soli_cred not in (
                                                  SELECT cs.cod_soli_cred                        
                                                    FROM    vve_cred_soli cs
                                                     JOIN  vve_cred_soli_prof spf ON cs.cod_soli_cred = spf.cod_soli_cred
                                                     JOIN  vve_proforma_veh pv ON 	spf.num_prof_veh = pv.num_prof_veh	
                                                     JOIN  gen_area_vta vta ON 	pv.cod_area_vta = vta.cod_area_vta
                                                     JOIN gen_mae_sociedad soc	ON cs.cod_empr = soc.cod_cia 
                                                     JOIN gen_filial fi ON 	cs.cod_empr = fi.cod_cia and soc.cod_cia = fi.cod_cia  and pv.cod_filial = fi.cod_filial
                                                     JOIN vve_mae_zona_filial mzf ON fi.cod_filial = mzf.cod_filial --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                                                     JOIN vve_mae_zona mz ON mzf.cod_zona =  mz.cod_zona --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                                                     JOIN gen_mae_pais pa ON  soc.cod_id_pais = pa.cod_id_pais 
                                                     JOIN gen_ubigeo ub ON	fi.cod_dpto = decode(fi.cod_dpto,null,null,ub.cod_dpto) 
                                                          and fi.cod_provincia = decode(fi.cod_provincia,null,null,ub.cod_provincia)
                                                          and fi.cod_distrito = decode(fi.cod_distrito,null,null,ub.cod_distrito) 
                                                     JOIN  arccve ve ON pv.vendedor = ve.vendedor

                                                )
                             
                
        ) tb1 ON tb1.cod_clie = pe.cod_perso
            WHERE 1=1
                AND (p_cod_soli_cred IS NULL OR tb1.cod_soli_cred = p_cod_soli_cred)
                AND (p_tipo_cred IS NULL OR tb1.tip_soli_cred = p_tipo_cred)
                AND (p_cod_clie IS NULL OR pe.cod_perso = p_cod_clie)               
                AND (p_cod_clie_sap IS NULL OR DECODE(SUBSTR(MC.COD_CLIE_SAP,4,7),null,SUBSTR(MP.COD_CLIE_SAP,4,7),SUBSTR(MC.COD_CLIE_SAP,4,7)) = p_cod_clie_sap)                               
                AND (p_nom_perso IS NULL OR pe.nom_perso LIKE '%'||p_nom_perso||'%')
                AND (p_cod_tipo_perso IS NULL OR pe.cod_tipo_perso = p_cod_tipo_perso)
                AND (v_cod_tipo_docu_iden IS NULL OR pe.cod_tipo_docu_iden = v_cod_tipo_docu_iden)
                AND (p_num_dni IS NULL OR pe.num_docu_iden = p_num_dni)
                AND (p_num_ruc IS NULL OR  pe.num_ruc = p_num_ruc)
                AND (p_cod_area_vta IS NULL OR tb1.cod_area_vta = p_cod_area_vta)
                AND (p_cod_filial IS NULL OR tb1.cod_filial = p_cod_filial)
                AND (p_cod_zona IS NULL OR tb1.cod_zona = p_cod_zona) --Req. 87567 E2.1 ID:1 avilca 10/09/2020
                AND (p_cod_cia IS NULL OR tb1.cod_cia = p_cod_cia)
                AND (p_cod_pais IS NULL OR tb1.cod_pais = p_cod_pais)
                --I Req. 87567 E2.1 ID:131 avilca 12/02/2020> 
                -- Req. Modificado Consulta Cliente MBardales 19/10/2020
                AND (v_depa_x IS NULL OR tb1.cod_dpto = v_depa_x)
                AND (v_prov_x IS NULL OR tb1.cod_provincia = v_prov_x)
                AND (v_dist_x IS NULL OR tb1.cod_distrito = v_dist_x)
                --F Req. 87567 E2.1 ID:131 avilca 12/02/2020> 
                AND (p_cod_esta_soli IS NULL OR tb1.cod_estado = p_cod_esta_soli)
                AND (p_cod_esta_clie IS NULL OR pe.ind_inactivo = p_cod_esta_clie)
                AND tb1.ind_inactivo = 'N'  --Req. 87567 E2.1 ID:1 avilca 10/09/2020
               
               );

      p_ret_esta := 1;
      p_ret_mens := 'se realizo la consulta correctamente';

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
 --F Req. 87567 E2.1 ID:304 avilca 24/04/2020>        
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
            AND estado = 'A'
           -- <I Req. 87567 E2.1 ID## AVILCA 14/09/2020>
            AND cod_oper  NOT IN(
                                SELECT cod_oper_rel as cod_oper                             
                                FROM vve_cred_soli 
                                WHERE cod_clie = p_cod_clie
                                 AND ind_inactivo = 'N'
                                 AND cod_oper_rel IS NOT NULL
                              )
            -- <F Req. 87567 E2.1 ID## AVILCA 14/09/2020>                  
            ) x
            WHERE 1=1
            AND (p_cod_oper IS NULL OR p_cod_oper = x.cod_oper)
            AND (p_cod_tipo_oper IS NULL OR p_cod_tipo_oper = x.cod_tipo_oper)
            AND (p_cod_mone IS NULL OR p_cod_mone = x.cod_moneda)
            AND (p_estado IS NULL OR p_estado = x.estado); 
 
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
           AND sc.cod_oper_rel IS NOT NULL
           AND sc.ind_inactivo = 'N'
           AND sc.cod_oper_rel = p_cod_oper;
                
        IF(v_cod_solid_cred <> '') THEN
            SELECT distinct(no_cia) INTO v_cod_cia 
            FROM arlcop WHERE no_cliente = p_cod_clie;
        
        ELSE
            SELECT sc.cod_soli_cred, sc.cod_empr, sc.tip_soli_cred
              INTO v_cod_solid_cred, v_cod_cia, v_cod_tipo_operacion
              FROM vve_cred_soli sc
             WHERE sc.cod_clie = p_cod_clie
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
        p_tipo_cred         VARCHAR2,
        p_esta_gara         VARCHAR2,
        p_tipo_gara         IN vve_cred_maes_gara.ind_tipo_garantia%type,
        p_marca_gara        VARCHAR2,
        p_num_soli_cred     VARCHAR2,
        p_anio_fab          VARCHAR2,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    ) AS
    v_estado_inactivo   VARCHAR2(1);
 BEGIN
    v_estado_inactivo:= 'S';
            OPEN p_ret_cursor FOR
            select mg.cod_garantia AS NRO_GARANTIA,
            (select descripcion from vve_tabla_maes 
            where cod_grupo = 129 and valor_adic_1 = mg.ind_tipo_garantia) AS DES_TIPO_GARANTIA,
            ltrim(sg.cod_soli_cred,'0') AS COD_SOLI_CRED, 
            (select descripcion from vve_tabla_maes where cod_grupo = '86' and cod_tipo = s.tip_soli_cred) as DES_TIPO_CREDITO,
            mg.txt_marca AS TXT_MARCA,
            mg.txt_modelo AS TXT_MODELO,
            mg.nro_placa AS NRO_PLACA,
            mg.val_ano_fab AS VAL_ANO_FAB,
            (select descripcion from vve_tabla_maes where cod_grupo = 106 and cod_tipo = mg.val_nro_rango) AS DES_RANG_GAR,
            mg.val_const_gar AS VAL_COMERCIAL,
            mg.val_realiz_gar AS VAL_REALIZ,
            decode(sg.ind_gara_adic,'S','N','S') AS TXT_MISMA_UNIDAD,
            (case  
            WHEN mg.val_nro_rango IS NULL THEN 'CERRADO'
            WHEN mg.val_nro_rango IS NOT NULL THEN 'VIGENTE'
            END) AS TXT_ESTADO_GARA
            from vve_cred_soli s 
            inner join vve_cred_soli_gara sg 
            on s.cod_soli_cred = sg.cod_soli_cred 
            inner join vve_cred_maes_gara mg 
            on sg.cod_gara = mg.cod_garantia 
            where sg.ind_inactivo = 'N' 
            AND (p_cod_clie IS NULL OR s.cod_clie = p_cod_clie) -- cod. cliente
            AND (p_tipo_cred IS NULL OR s.tip_soli_cred = p_tipo_cred)-- <cód. tipo crédito seleccionado>
            AND (p_num_soli_cred IS NULL OR ltrim(sg.cod_soli_cred,'0') = ltrim(p_num_soli_cred,'0'))-- <nro.solicitud ingresado>
            AND (p_tipo_gara IS NULL OR mg.ind_tipo_garantia = p_tipo_gara) -- <tipo garantia seleccionado> 
            AND (p_marca_gara IS NULL OR mg.cod_marca = p_marca_gara) -- <cód. marca seleccionado>
            AND (p_anio_fab IS NULL OR mg.val_ano_fab = p_anio_fab) -- <año ingresado>
            order by 1;

           
            /*SELECT s.cod_soli_cred,
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
           -- AND s.cod_oper_rel = p_cod_oper--<cod_oper>
            --AND sg.ind_inactivo = 'N'
                AND (sg.ind_inactivo IS NULL OR sg.ind_inactivo <> v_estado_inactivo)
            --AND (p_cod_oper IS NULL OR p_cod_oper = s.cod_oper_rel)
           -- AND (p_cod_gara IS NULL OR p_cod_gara = g.cod_garantia)
            AND (p_tipo_gara IS NULL OR p_tipo_gara = g.ind_tipo_garantia)
           -- AND (p_cod_esta_poli IS NULL OR (p_cod_esta_poli = s.cod_esta_poli and sg.ind_gara_adic is null))
            --and s.cod_oper_rel in ( '5621','5783','5785','5890','5892','5990','6166','6418')
            ORDER BY 3;*/
      
 
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
  
 --I Req. 87567 E2.1 ID:131 avilca 11/09/2020> 
  PROCEDURE SP_LIST_TODOS_CLIENTE(
    p_nom_clie              IN cxc_mae_clie.nom_clie%type,    
    p_cod_usua_sid          IN sistemas.usuarios.co_usuario%type,
    p_ret_cursor            OUT SYS_REFCURSOR,
    p_ret_cantidad          OUT NUMBER,
    p_ret_esta              OUT NUMBER,
    p_ret_mens              OUT VARCHAR2
) AS
   ve_error            EXCEPTION;
   
    BEGIN
      
      OPEN p_ret_cursor FOR
         SELECT distinct(gp.cod_perso) as COD_CLIE ,gp.nom_perso as NOM_PERSO
            FROM gen_persona gp
            INNER JOIN vve_cred_soli cs ON gp.cod_perso = cs.cod_clie
            WHERE gp.ind_inactivo = 'N'
            AND cs.ind_inactivo = 'N' order by NOM_PERSO;
         
    SELECT COUNT(1) 
       INTO p_ret_cantidad
        FROM (
         SELECT distinct(gp.cod_perso) as COD_CLIE ,gp.nom_perso as NOM_PERSO
            FROM gen_persona gp
            INNER JOIN vve_cred_soli cs ON gp.cod_perso = cs.cod_clie
            WHERE gp.ind_inactivo = 'N'
            AND cs.ind_inactivo = 'N' order by NOM_PERSO);
         
          p_ret_esta := 1;
          p_ret_mens := 'La consulta se realizó de manera exitosa';
    
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_TODOS_CLIENTE', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_LIST_TODOS_CLIENTE:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_TODOS_CLIENTE', p_cod_usua_sid, 'Error en la consulta', p_ret_mens
            , NULL);
 
    END SP_LIST_TODOS_CLIENTE;
 --F Req. 87567 E2.1 ID:131 avilca 11/09/2020> 
 
    
    /* -- STORE PROCEDURES LISTADO PAIS, DEPARTAMENTO, PROVINCIA, DISTRITO Req. Obs Consulta Cliente MBardales 16/10/2020 */
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
    
     SELECT cod_id_pais as COD_TIPO, nom_pais as DESCRIPCION, '' as VALOR_ADICIONAL FROM gen_pais WHERE cod_id_pais IS NOT NULL;
     
     p_ret_esta := 1;
     p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_listado_departamentos:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_paises;
  
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
  
       SELECT cod_id_departamento as COD_TIPO, des_nombre as DESCRIPCION, '' as VALOR_ADICIONAL FROM gen_mae_departamento 
       WHERE cod_id_pais = p_cod_pais ORDER BY cod_id_departamento;
       
     p_ret_esta := 1;
     p_ret_mens := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'sp_listado_departamentos:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_departamentos;
  
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
       SELECT cod_id_provincia as COD_TIPO, des_nombre as DESCRIPCION, '' as VALOR_ADICIONAL FROM gen_mae_provincia 
       WHERE cod_id_departamento = p_cod_depa ORDER BY cod_id_provincia;

    p_ret_esta := 1;
    p_ret_mens  := 'La consulta se realizó de manera exitosa';
  EXCEPTION
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'sp_listado_provincias:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_provincias;
  
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
     SELECT cod_id_distrito as COD_TIPO, des_nombre as DESCRIPCION, '' as VALOR_ADICIONAL FROM gen_mae_distrito 
     WHERE cod_id_provincia = p_cod_prov ORDER BY cod_id_distrito;
      
    p_ret_esta := 1;
    p_ret_mens  := 'La consulta se realizó de manera exitosa';
  EXCEPTION
       WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'sp_listado_distritos:' || SQLERRM;
    CLOSE p_ret_cursor;
  END sp_listado_distritos;
  
  
  
END PKG_SWEB_CRED_SOLI_MANT_CLIE;