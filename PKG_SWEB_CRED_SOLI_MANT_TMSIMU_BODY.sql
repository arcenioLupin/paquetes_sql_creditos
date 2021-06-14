create or replace PACKAGE BODY VENTA.PKG_SWEB_CRED_SOLI_MANT_TMSIMU AS

 PROCEDURE SP_ACT_TIPO_MOVI_SIMU
  (
    p_cod_id_soli_tipm IN  vve_cred_soli_movi.cod_id_soli_tipm%TYPE,
    p_cod_soli_cred IN  vve_cred_soli_movi.cod_soli_cred%TYPE,
    p_cod_tipo_movi_pago IN  vve_cred_soli_movi.cod_tipo_movi_pago%TYPE,
    p_fec_movi_pago IN  VARCHAR2,
    p_cod_banco IN  vve_cred_soli_movi.cod_banco%TYPE,
    p_cod_moneda IN  vve_cred_soli_movi.cod_moneda%TYPE,
    p_val_monto_pago IN  vve_cred_soli_movi.val_monto_pago%TYPE,
    p_txt_nro_documento IN  vve_cred_soli_movi.txt_nro_documento%TYPE,
    p_ind_inactivo IN  vve_cred_soli_movi.ind_inactivo%TYPE,
    p_ind_tipo_docu IN  vve_cred_soli_movi.ind_tipo_docu%TYPE,
    p_cod_empresa_cargo IN  vve_cred_soli_movi.cod_empresa_cargo%TYPE,
    p_fec_crea_regi IN  vve_cred_soli_movi.fec_crea_regi%TYPE,
    p_cod_usua_crea_regi IN  vve_cred_soli_movi.cod_usua_crea_regi%TYPE,
    p_fec_modi_regi IN  vve_cred_soli_movi.fec_modi_regi%TYPE,
    p_cod_usua_modi_regi IN  vve_cred_soli_movi.cod_usua_modi_regi%TYPE,
    p_ret_esta          OUT NUMBER,
    p_ret_mens          OUT VARCHAR2
  ) AS
  BEGIN
  
    IF(p_cod_id_soli_tipm <= 0) THEN
       INSERT INTO vve_cred_soli_movi(cod_id_soli_tipm,cod_soli_cred,cod_tipo_movi_pago,fec_movi_pago,cod_banco,cod_moneda,val_monto_pago,txt_nro_documento,ind_inactivo,ind_tipo_docu,cod_empresa_cargo,fec_crea_regi,cod_usua_crea_regi,fec_modi_regi,cod_usua_modi_regi)
        VALUES (SEQ_VVE_CRED_SOLI_MOVI.nextval,p_cod_soli_cred, p_cod_tipo_movi_pago, TO_DATE(p_fec_movi_pago, 'dd/mm/yyyy'), p_cod_banco, p_cod_moneda, p_val_monto_pago, p_txt_nro_documento,'N', p_ind_tipo_docu, p_cod_empresa_cargo, sysdate, p_cod_usua_crea_regi,sysdate, p_cod_usua_modi_regi);
    ELSE    
    
        UPDATE vve_cred_soli_movi
        SET 
        cod_soli_cred =  p_cod_soli_cred,
        cod_tipo_movi_pago =  p_cod_tipo_movi_pago,
        fec_movi_pago =  TO_DATE(p_fec_movi_pago, 'dd/mm/yyyy'),
        cod_banco =  p_cod_banco,
        cod_moneda =  p_cod_moneda,
        val_monto_pago =  p_val_monto_pago,
        txt_nro_documento =  p_txt_nro_documento,
        ind_inactivo =  p_ind_inactivo,
        ind_tipo_docu =  p_ind_tipo_docu,
        cod_empresa_cargo =  p_cod_empresa_cargo,
        cod_usua_crea_regi =  p_cod_usua_crea_regi,
        fec_modi_regi = sysdate,
        cod_usua_modi_regi =  p_cod_usua_modi_regi
        WHERE cod_id_soli_tipm = p_cod_id_soli_tipm;
        
    END IF;
    
    COMMIT;
     

    p_ret_esta := 1;
    p_ret_mens := CONCAT(p_cod_soli_cred, ' actualización éxitosa.');
  EXCEPTION
       WHEN OTHERS THEN
        p_ret_esta := -1;
        p_ret_mens := 'SP_ACT_TIPO_MOVI_EXCEP:' || SQLERRM;
        pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_ACT_TIPO_MOVI',
                                          'SP_ACT_TIPO_MOVI',
                                          'Error al actualizar el tipo de movimiento',
                                          p_ret_mens,
                                          p_cod_id_soli_tipm);
          ROLLBACK;
          
  END SP_ACT_TIPO_MOVI_SIMU;
  
  
  PROCEDURE SP_LISTAR_TIPO_MOVIMIENTO_SIMU
  (
    p_cod_soli_cred IN  vve_cred_soli_movi.cod_soli_cred%TYPE,
    O_CURSOR                     OUT SYS_REFCURSOR,
    O_RET_ESTA                   OUT NUMBER,
    O_RET_MENS                   OUT VARCHAR2
  ) AS
  BEGIN
  IF(p_cod_soli_cred IS NULL) THEN
    O_RET_MENS := 'Inicio';
    O_RET_ESTA := 1;

    OPEN O_CURSOR FOR 
    select cod_id_soli_tipm,cod_soli_cred,cod_tipo_movi_pago,fec_movi_pago,cod_banco,
    cod_moneda,val_monto_pago,txt_nro_documento,ind_inactivo,ind_tipo_docu,
    cod_empresa_cargo,fec_crea_regi,cod_usua_crea_regi,fec_modi_regi,cod_usua_modi_regi
    from vve_cred_soli_movi where  ind_inactivo != 'S';
    O_RET_ESTA := 1;
    O_RET_MENS := 'Consulta exitosa';
    ELSE
    O_RET_MENS := 'Inicio';
    O_RET_ESTA := 1;

    OPEN O_CURSOR FOR 
    select cod_id_soli_tipm,cod_soli_cred,cod_tipo_movi_pago,fec_movi_pago,cod_banco,
    cod_moneda,val_monto_pago,txt_nro_documento,ind_inactivo,ind_tipo_docu,
    cod_empresa_cargo,fec_crea_regi,cod_usua_crea_regi,fec_modi_regi,cod_usua_modi_regi
    from vve_cred_soli_movi where cod_soli_cred=p_cod_soli_cred AND ind_inactivo != 'S';
    O_RET_ESTA := 1;
   -- O_RET_MENS := CONCAT(p_cod_soli_cred,' + Consulta exitosa');
    O_RET_MENS := 'Consulta exitosa';--<Req. 87567 E2.1 ID## avilca 22/01/2021>
    END IF;
    COMMIT;
  EXCEPTION
    WHEN no_data_found THEN
      O_RET_MENS := 'No se encontraron registros';
      O_RET_ESTA := 0;
    WHEN OTHERS THEN
      O_RET_ESTA := -1;
      O_RET_MENS := SQLERRM;
      pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR',
                                          'SP_LISTAR_TIPO_MOVIMIENTO',
                                          'Error al listar los TIPO DE MOVIMIENTO',
                                          O_RET_MENS,
                                          null);
  END SP_LISTAR_TIPO_MOVIMIENTO_SIMU;
  
  
END PKG_SWEB_CRED_SOLI_MANT_TMSIMU;