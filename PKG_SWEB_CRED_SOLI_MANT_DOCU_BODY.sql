create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_MANT_DOCU AS

PROCEDURE SP_LIST_DOCU (
    p_des_docu_eval   IN    vve_cred_mae_docu.des_docu_eval%TYPE,
    p_ind_tipo_docu   IN    vve_cred_mae_docu.ind_tipo_docu%TYPE,
    p_ind_oblig_gral  IN    vve_cred_mae_docu.ind_oblig_gral%TYPE,
    p_ind_inactivo    IN    vve_cred_mae_docu.ind_inactivo%TYPE,
    
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
            ln_limitinf := p_limitinf - 1;
            IF p_limitsup > 10 THEN
                ln_limitsup := 10;
            ELSE
                ln_limitsup := p_limitsup;
            END IF;
        END IF; 
        
        OPEN p_ret_cursor FOR 
           SELECT 
                cod_docu_eval AS CODIGO,
                des_docu_eval AS DOCUMENTO,
                ind_tipo_docu AS COD_TIPO_DOCU,
                (select descripcion from vve_tabla_maes mae where mae.cod_grupo = 120 
                    and mae.cod_tipo = ind_tipo_docu and mae.orden_pres is not null) AS DES_TIPO_DOCU,
                val_dias_vig AS VIGENCIA,
                ind_oblig_gral AS OBLIGATORIO,  
                cod_docleg AS DOCUMENTO_LEGAL,
                ind_inactivo AS ESTADO
             FROM vve_cred_mae_docu
            WHERE 1=1
            AND (p_des_docu_eval IS NULL OR UPPER(des_docu_eval) LIKE  '%'||p_des_docu_eval||'%')
            AND (p_ind_tipo_docu IS NULL OR ind_tipo_docu = p_ind_tipo_docu)
            AND (p_ind_oblig_gral IS NULL OR ind_oblig_gral = p_ind_oblig_gral)
            AND (p_ind_inactivo IS NULL OR ind_inactivo = p_ind_inactivo)
            ORDER BY 1
            OFFSET ln_limitinf ROWS FETCH NEXT ln_limitsup ROWS ONLY;
              
            
            SELECT COUNT(1) 
                   INTO p_ret_cantidad
                    FROM (
                        SELECT * FROM vve_cred_mae_docu
                        WHERE 1=1
                        AND (p_des_docu_eval IS NULL OR UPPER(des_docu_eval) LIKE  '%'||p_des_docu_eval||'%')
                        AND (p_ind_tipo_docu IS NULL OR ind_tipo_docu = p_ind_tipo_docu)
                        AND (p_ind_oblig_gral IS NULL OR ind_oblig_gral = p_ind_oblig_gral)
                        AND (p_ind_inactivo IS NULL OR ind_inactivo = p_ind_inactivo)
                        );
            
        p_ret_esta := 1;
        p_ret_mens := 'La consulta se realizó de manera exitosa';
        
EXCEPTION
    WHEN ve_error THEN
        p_ret_esta := 0;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_DOCU', p_cod_usua_sid, 'Error en la consulta', p_ret_mens, NULL);
    WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_LIST_DOCU:' || sqlerrm;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_LIST_DOCU', p_cod_usua_sid, 'Error en la consulta', p_ret_mens, NULL);       
        
END SP_LIST_DOCU;


PROCEDURE SP_ACT_DOCU
  (
    p_cod_docu_eval     IN vve_cred_mae_docu.cod_docu_eval%TYPE,
    p_des_docu_eval     IN vve_cred_mae_docu.des_docu_eval%TYPE,
    p_ind_tipo_docu     IN vve_cred_mae_docu.ind_tipo_docu%TYPE,
    p_ind_oblig_gral    IN vve_cred_mae_docu.ind_oblig_gral%TYPE,
    p_ind_inactivo      IN vve_cred_mae_docu.ind_inactivo%TYPE,
    p_cod_docu_legal    IN vve_cred_mae_docu.cod_docleg%TYPE,
    p_cod_usua_web      IN sistemas.usuarios.co_usuario%TYPE,
    p_cod_usua_sid      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
  
    IF(p_cod_docu_eval IS NULL) THEN
        INSERT INTO vve_cred_mae_docu(COD_DOCU_EVAL,DES_DOCU_EVAL,IND_INACTIVO,VAL_DIAS_VIG,IND_TIPO_DOCU,IND_OBLIG_GRAL,
                                      COD_USUA_CREA_REG,FEC_CREA_REG,COD_USUA_MODI_REG,FEC_MODI_REG,COD_DOCLEG)
        VALUES (SEQ_CRED_MAE_DOCU.nextval,p_des_docu_eval,p_ind_inactivo,10,p_ind_tipo_docu,p_ind_oblig_gral,
                p_cod_usua_web,sysdate,null,null,p_cod_docu_legal);
       
    ELSE    
    
        UPDATE vve_cred_mae_docu 
        SET 
        des_docu_eval = p_des_docu_eval,
        ind_tipo_docu = p_ind_tipo_docu,
        ind_oblig_gral = p_ind_oblig_gral,
        ind_inactivo = p_ind_inactivo,
        cod_docleg = p_cod_docu_legal,
        cod_usua_modi_reg = p_cod_usua_web,
        fec_modi_reg = sysdate
        WHERE cod_docu_eval = p_cod_docu_eval;
        
    END IF;
    
    COMMIT;
     

    p_ret_esta := 1;
    p_ret_mens := 'El documento legal se actualizó con éxito.';
  EXCEPTION
       WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_ACT_DOCU_EXCEP:' || SQLERRM;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACT_DOCU',
                                          'SP_ACT_DOCU',
                                          'Error al actualizar el documento legal',
                                          p_ret_mens,
                                          p_cod_docu_eval);
          ROLLBACK;
          
  END SP_ACT_DOCU;
    
    
END PKG_SWEB_CRED_SOLI_MANT_DOCU; 