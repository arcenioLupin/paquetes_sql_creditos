create or replace PACKAGE BODY  VENTA.PKG_SWEB_CRED_SOLI_CART_BANC AS



    PROCEDURE SP_LIST_CRED_SOLI_CB(
        p_cod_cred_soli     IN vve_cred_soli.cod_soli_cred%type,
        p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
      ) AS
      BEGIN
        OPEN p_ret_cursor FOR
              SELECT cod_soli_cred,cod_banco,
                     txt_ofic_banc, num_fax, 
                     --TO_CHAR(fec_aprob_cart_ban, 'DD/MM/YYYY') AS fec_aprob_cart_ban,
                     fec_aprob_cart_ban,
                     cod_mone_cart_banc, val_mone_aprob_banc, txt_nomb_ejec_banc,
                     txt_ruta_cart_banc, num_tele_fijo_ejec, num_celu_ejec 
                FROM vve_cred_soli 
               WHERE cod_soli_cred = p_cod_cred_soli;
         p_ret_esta := 1;
         p_ret_mens := 'La consulta se realizó de manera exitosa';

      EXCEPTION
        WHEN OTHERS THEN
                p_ret_esta := -1;
                p_ret_mens := 'SP_LIST_CRED_SOLI_CB:' || SQLERRM;

        CLOSE p_ret_cursor;
    END SP_LIST_CRED_SOLI_CB;

    PROCEDURE SP_ACTU_CRED_SOLI_CB (
        p_cod_soli_cred         IN                  vve_cred_soli.cod_soli_cred%TYPE,
        p_cod_banco				IN					vve_cred_soli.cod_banco%type,
		p_txt_ofic_banc			IN					vve_cred_soli.txt_ofic_banc%TYPE,
		p_num_fax				IN					vve_cred_soli.num_fax%TYPE,
		p_fec_aprob_cart_ban	IN					vve_cred_soli.fec_aprob_cart_ban%TYPE,
		p_cod_mone_cart_banc	IN					vve_cred_soli.cod_mone_cart_banc%TYPE,
		p_val_mone_aprob_banc	IN					vve_cred_soli.val_mone_aprob_banc%TYPE,
		p_txt_nomb_ejec_banc	IN					vve_cred_soli.txt_nomb_ejec_banc%TYPE,
		p_txt_ruta_cart_banc	IN					vve_cred_soli.txt_ruta_cart_banc%TYPE,
		p_num_tele_fijo_ejec	IN					vve_cred_soli.num_tele_fijo_ejec%TYPE,
		p_num_celu_ejec			IN					vve_cred_soli.num_celu_ejec%TYPE,
		p_cod_usua_sid      	IN 					sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta              OUT                 NUMBER,
        p_ret_mens              OUT                 VARCHAR2
    ) AS
        ve_error EXCEPTION;
        v_txt_usuario VARCHAR2(20);
        v_cod_estado_actu VARCHAR(6);
    BEGIN
    
            UPDATE vve_cred_soli
            SET	cod_banco = p_cod_banco,
				txt_ofic_banc = p_txt_ofic_banc,
                num_fax = p_num_fax,
				fec_aprob_cart_ban = p_fec_aprob_cart_ban,
				cod_mone_cart_banc = p_cod_mone_cart_banc, 
				val_mone_aprob_banc = p_val_mone_aprob_banc, 
				txt_nomb_ejec_banc = p_txt_nomb_ejec_banc,  
				txt_ruta_cart_banc = p_txt_ruta_cart_banc,
				num_tele_fijo_ejec = p_num_tele_fijo_ejec,
				num_celu_ejec = p_num_celu_ejec
            WHERE 
                cod_soli_cred = p_cod_soli_cred;
            COMMIT;
            
        p_ret_esta := 1;
        p_ret_mens := 'Se actualizaron los datos con éxito';
        
    EXCEPTION
        WHEN ve_error THEN
            p_ret_esta := 0;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_UPDATE_CRED_SOLI_CB', p_cod_usua_sid, 'Error al actualizar la solicitud de crédito'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
        WHEN OTHERS THEN
            p_ret_esta := -1;
            p_ret_mens := 'SP_UPDATE_CRED_SOLI:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR', 'SP_UPDATE_CRED_SOLI_CB', p_cod_usua_sid, 'Error al actualizar la solicitud de crédito'
            , p_ret_mens, p_cod_soli_cred);
            ROLLBACK;
    END SP_ACTU_CRED_SOLI_CB;

END PKG_SWEB_CRED_SOLI_CART_BANC; 