create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_MANT_AGRUP AS

PROCEDURE SP_LIST_AGRUP_TASAS_VEHI (
    p_cod_cia           IN vve_cred_agru_veh_seg.no_cia%TYPE,
    p_cod_usua_web      IN sistemas.usuarios.co_usuario%type,
    p_cod_usua_sid      IN sistemas.sis_mae_usuario.cod_id_usuario%type,
    p_ind_paginado      IN VARCHAR2,
    p_limitinf          IN INTEGER,
    p_limitsup          IN INTEGER,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_cantidad      OUT NUMBER,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
)AS
    
    ve_error            EXCEPTION;
    ln_limitinf         INTEGER := 0;
    ln_limitsup         INTEGER := 0;
    
    BEGIN
        IF p_ind_paginado = 'N' THEN
            SELECT COUNT(1)
                INTO ln_limitsup
            FROM gen_persona;    
        ELSE
            ln_limitinf := p_limitinf - 1;
            IF p_limitsup > 10 THEN
                ln_limitsup := 10;
            ELSE
                ln_limitsup := p_limitsup;
            END IF;
        END IF; 
        
        OPEN p_ret_cursor FOR 
           SELECT xx.cod_agru_veh_seg AS COD_AGRU,
                  xx.des_agru_veh_seg AS DES_AGRU,
                  xx.val_tasa_brut AS TASA_BRUTA,
                  xx.val_gross_up AS VAL_GROSSUP,
                  xx.val_tasa_final AS TASA_FINAL,
                  xx.no_cia AS COD_CIA,
                  (select nom_sociedad from gen_mae_sociedad where cod_cia =  xx.no_cia)AS DES_CIA
             FROM vve_cred_agru_veh_seg xx
            WHERE 1=1
            AND (p_cod_cia IS NULL OR no_cia = p_cod_cia)
            ORDER BY 1
            OFFSET ln_limitinf ROWS FETCH NEXT ln_limitsup ROWS ONLY;
              
            
            SELECT COUNT(1) 
                   INTO p_ret_cantidad
                    FROM (
                        SELECT * 
                         FROM vve_cred_agru_veh_seg
                        WHERE 1=1
                        AND (p_cod_cia IS NULL OR no_cia = p_cod_cia));
            
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
        
EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_AGRUP_TASAS_VEHI', p_cod_usua_web, 'Error en la consulta', p_ret_mens, NULL);
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LIST_AGRUP_TASAS_VEHI:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_AGRUP_TASAS_VEHI', p_cod_usua_web, 'Error en la consulta', p_ret_mens, NULL);       
        
END SP_LIST_AGRUP_TASAS_VEHI;

PROCEDURE SP_LIST_DETAIL_BY_AGRUP (
    p_cod_agru_veh_seg  IN  vve_cred_agru_veh_seg.cod_agru_veh_seg%TYPE,
    p_ret_cursor        OUT SYS_REFCURSOR,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
    ) AS
    
    BEGIN
        OPEN p_ret_cursor FOR 
         SELECT 
                xx.cod_tipo_veh_agru AS COD_DETAIL,
                xx.cod_agru_veh_seg AS COD_AGRU,
                xx.cod_tipo_veh,
                yy.des_tipo_veh,
                xx.cod_tip_uso AS COD_TIPO_USO,
                (SELECT descripcion FROM vve_tabla_maes WHERE cod_grupo = 97 AND cod_tipo = xx.cod_tip_uso AND orden_pres IS NOT NULL) AS des_tipo_uso
                --xx.ind_tipo_clie
            FROM vve_cred_tipo_veh_agru xx, vve_tipo_veh yy
            WHERE xx.cod_tipo_veh = yy.cod_tipo_veh
            AND xx.cod_agru_veh_seg = p_cod_agru_veh_seg
            ORDER BY 1;
            

        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
END SP_LIST_DETAIL_BY_AGRUP;

PROCEDURE SP_ACT_AGRUP
  (
    p_cod_agru_veh_seg  IN vve_cred_agru_veh_seg.cod_agru_veh_seg%TYPE,
    p_des_agru_veh_seg  IN vve_cred_agru_veh_seg.des_agru_veh_seg%TYPE,
    p_val_tasa_brut     IN vve_cred_agru_veh_seg.val_tasa_brut%TYPE,
    p_val_gross_up      IN vve_cred_agru_veh_seg.val_gross_up%TYPE,
    p_val_tasa_final    IN vve_cred_agru_veh_seg.val_tasa_final%TYPE,
    p_no_cia            IN vve_cred_agru_veh_seg.no_cia%TYPE,
    p_cod_usua_web      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_sid      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
  
    IF(p_cod_agru_veh_seg IS NULL) THEN
        INSERT INTO vve_cred_agru_veh_seg(cod_agru_veh_seg,des_agru_veh_seg,val_tasa_brut,val_gross_up,
                                          val_tasa_final,no_cia,cod_usua_crea_reg,fec_crea_reg)
        VALUES (SEQ_CRED_MAE_DOCU.nextval,p_des_agru_veh_seg,p_val_tasa_brut,p_val_gross_up,
                p_val_tasa_final,p_no_cia,p_cod_usua_web,sysdate);
       
    ELSE    
        UPDATE vve_cred_agru_veh_seg 
        SET 
        des_agru_veh_seg = p_des_agru_veh_seg,
        val_tasa_brut = p_val_tasa_brut,
        val_gross_up = p_val_gross_up,
        val_tasa_final = p_val_tasa_final,
        no_cia = p_no_cia,
        cod_usua_modi_reg = p_cod_usua_web,
        fec_modi_reg = sysdate
        WHERE cod_agru_veh_seg = p_cod_agru_veh_seg;
        
    END IF;
    
    COMMIT;
     

    p_ret_esta := 1;
    p_ret_mens := 'El agrupamiento de tasas por vehículo se actualizó con éxito.';
  EXCEPTION
       WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_ACT_AGRUP_EXCEP:' || SQLERRM;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACT_AGRUP',
                                          'SP_ACT_AGRUP',
                                          'Error al actualizar el agrupamiento de tasas por vehículo',
                                          p_ret_mens,
                                          p_cod_agru_veh_seg);
          ROLLBACK;
          
  END SP_ACT_AGRUP;

END PKG_SWEB_CRED_SOLI_MANT_AGRUP; 