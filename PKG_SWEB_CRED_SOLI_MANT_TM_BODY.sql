create or replace PACKAGE BODY VENTA.pkg_sweb_cred_soli_mant_tm AS
/*-----------------------------------------------------------------------------
  Nombre : SP_LISTAR_TIPO_MOVIMIENTO
  Proposito : LISTA LAS MOVIMIENTO
  Referencias :
  Parametros :
  Log de Cambios
    Fecha        Autor           Descripcion
    08/01/2020   EBARBOZA       Creacion (REQ-88181)
  ----------------------------------------------------------------------------*/

    PROCEDURE sp_listar_tipo_movimiento (
        p_cod_tm        IN vve_cred_mae_tipo_movi.cod_tipo_mov%TYPE,
        p_cod_desc_tm   IN VARCHAR2, 
        p_ind_natu_tm   IN VARCHAR2,
        o_cursor     OUT SYS_REFCURSOR,
        o_ret_esta   OUT NUMBER,
        o_ret_mens   OUT VARCHAR2
    ) AS
    BEGIN
        o_ret_mens := 'Inicio';
        o_ret_esta := 1;
        
        OPEN o_cursor FOR SELECT
                              cod_tipo_mov,
                              txt_desc_tipo_movi,
                              ind_natu_tipo_movi,
                              ind_inactivo,
                              fec_crea_regi,
                              cod_usua_regi,
                              fec_modi_regi,
                              cod_usua_modi
                          FROM
                              vve_cred_mae_tipo_movi
                          WHERE
                              ((p_cod_tm IS NULL OR p_cod_tm = 0) OR p_cod_tm = cod_tipo_mov) AND
                              (p_cod_desc_tm IS NULL OR upper(translate(txt_desc_tipo_movi, 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU')) LIKE '%'|| upper(p_cod_desc_tm)||'%') AND
                              (p_ind_natu_tm IS NULL OR p_ind_natu_tm = ind_natu_tipo_movi) AND
                              ind_inactivo = 'N';
                              
        o_ret_esta := 1;
        o_ret_mens := p_cod_tm;
    EXCEPTION
        WHEN no_data_found THEN
            o_ret_mens := 'No se encontraron registros';
            o_ret_esta := 0;
        WHEN OTHERS THEN
            o_ret_esta :=-1;
            o_ret_mens := sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR','SP_LISTAR_TIPO_MOVIMIENTO','Error al listar los TIPO DE MOVIMIENTO'
           ,o_ret_mens,NULL);
    END sp_listar_tipo_movimiento;

    PROCEDURE sp_listar_tm_todos (
        o_cursor     OUT SYS_REFCURSOR,
        o_ret_esta   OUT NUMBER,
        o_ret_mens   OUT VARCHAR2
    ) AS
    BEGIN
        o_ret_mens := 'Inicio';
        o_ret_esta := 1;
        OPEN o_cursor FOR SELECT
                              cod_tipo_mov,
                              txt_desc_tipo_movi,
                              ind_natu_tipo_movi,
                              ind_inactivo,
                              fec_crea_regi,
                              cod_usua_regi,
                              fec_modi_regi,
                              cod_usua_modi
                          FROM
                              vve_cred_mae_tipo_movi
                          WHERE ind_inactivo = 'N'
                          ORDER BY cod_tipo_mov;--<Req. 87567 E2.1 ID## AVILCA 09/10/2020>

        o_ret_esta := 1;
        o_ret_mens := 'Consulta exitosa';
    EXCEPTION
        WHEN no_data_found THEN
            o_ret_mens := 'No se encontraron registros';
            o_ret_esta := 0;
        WHEN OTHERS THEN
            o_ret_esta :=-1;
            o_ret_mens := sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR','SP_LISTAR_TIPO_MOVIMIENTO','Error al listar los TIPO DE MOVIMIENTO'
           ,o_ret_mens,NULL);
    END sp_listar_tm_todos;

    PROCEDURE sp_is_tipo_mov_oper (
        p_cod_soli_cred       IN vve_cred_soli.cod_soli_cred%TYPE,
        p_txt_nro_documento   IN vve_cred_soli_movi.txt_nro_documento%TYPE,
        p_cod_tipo_mov        IN vve_cred_mae_tipo_movi.cod_tipo_mov%TYPE,
        o_cursor              OUT SYS_REFCURSOR,
        o_ret_esta            OUT NUMBER,
        o_ret_mens            OUT VARCHAR2
    ) AS
    BEGIN
        OPEN o_cursor FOR SELECT 
                  CASE WHEN nvl(count(a.cod_soli_cred),0) > 0 THEN 1 ELSE 0 END AS IS_TIPO_MOV_OPER
               FROM vve_cred_soli a
                              INNER JOIN vve_cred_soli_movi b ON b.cod_soli_cred = a.cod_soli_cred
                              INNER JOIN vve_cred_mae_tipo_movi c ON c.cod_tipo_mov = b.cod_tipo_movi_pago
                          WHERE  b.txt_nro_documento = p_txt_nro_documento
                              AND c.cod_tipo_mov = p_cod_tipo_mov
                              AND ROWNUM <= 1;

        o_ret_esta := 1;
        o_ret_mens := 'Consulta exitosa';
    EXCEPTION
        WHEN no_data_found THEN
            o_ret_mens := 'No se encontraron registros';
            o_ret_esta := 0;
        WHEN OTHERS THEN
            o_ret_esta :=-1;
            o_ret_mens := sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR','SP_LISTAR_TIPO_MOVIMIENTO','Error al listar los TIPO DE MOVIMIENTO'
           ,o_ret_mens,NULL);
           
    END sp_is_tipo_mov_oper;

    PROCEDURE sp_listar_tabla_maes (
        o_cursor     OUT SYS_REFCURSOR,
        o_ret_esta   OUT NUMBER,
        o_ret_mens   OUT VARCHAR2
    ) AS
    BEGIN
        o_ret_mens := 'Inicio';
        o_ret_esta := 1;
        OPEN o_cursor FOR SELECT
                              cod_tipo,
                              descripcion
                          FROM
                              vve_tabla_maes
                          WHERE
                              cod_grupo = 121;

        o_ret_esta := 1;
        o_ret_mens := 'Consulta exitosa';
    EXCEPTION
        WHEN no_data_found THEN
            o_ret_mens := 'No se encontraron registros';
            o_ret_esta := 0;
        WHEN OTHERS THEN
            o_ret_esta :=-1;
            o_ret_mens := sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR','SP_LISTAR_TIPO_MOVIMIENTO','Error al listar los TIPO DE MOVIMIENTO'
           ,o_ret_mens,NULL);
    END sp_listar_tabla_maes;

    PROCEDURE sp_act_tipo_movi (
        p_cod_tipo_movi        IN vve_cred_mae_tipo_movi.cod_tipo_mov%TYPE,
        p_txt_desc_tipo_movi   IN vve_cred_mae_tipo_movi.txt_desc_tipo_movi%TYPE,
        p_ind_natu_tipo_movi   IN vve_cred_mae_tipo_movi.ind_natu_tipo_movi%TYPE,
        p_ind_inactivo         IN vve_cred_mae_tipo_movi.ind_inactivo%TYPE,
        p_fec_crea_regi        IN vve_cred_mae_tipo_movi.fec_crea_regi%TYPE,
        p_cod_usua_regi        IN vve_cred_mae_tipo_movi.cod_usua_regi%TYPE,
        p_fec_modi_regi        IN vve_cred_mae_tipo_movi.fec_modi_regi%TYPE,
        p_cod_usua_modi        IN vve_cred_mae_tipo_movi.cod_usua_modi%TYPE,
        p_ret_esta             OUT NUMBER,
        p_ret_mens             OUT VARCHAR2
    ) AS
    BEGIN
        IF ( p_cod_tipo_movi <= 0 ) THEN
            INSERT INTO vve_cred_mae_tipo_movi (
                cod_tipo_mov,
                txt_desc_tipo_movi,
                ind_natu_tipo_movi,
                ind_inactivo,
                fec_crea_regi,
                cod_usua_regi,
                fec_modi_regi,
                cod_usua_modi
            ) VALUES (
                seq_vve_cred_mae_tipo_movi.NEXTVAL,
                p_txt_desc_tipo_movi,
                p_ind_natu_tipo_movi,
                p_ind_inactivo,
                SYSDATE,
                p_cod_usua_regi,
                NULL,
                NULL
            );

        ELSE
            UPDATE vve_cred_mae_tipo_movi
            SET
                txt_desc_tipo_movi = p_txt_desc_tipo_movi,
                ind_natu_tipo_movi = p_ind_natu_tipo_movi,
                ind_inactivo = p_ind_inactivo,
                fec_modi_regi = SYSDATE,
                cod_usua_modi = p_cod_usua_modi
            WHERE
                cod_tipo_mov = p_cod_tipo_movi;

        END IF;

        COMMIT;
        p_ret_esta := 1;
        p_ret_mens := 'actualización éxitosa.';
    EXCEPTION
        WHEN OTHERS THEN
            p_ret_esta :=-1;
            p_ret_mens := 'SP_ACT_TIPO_MOVI_EXCEP:' || sqlerrm;
            pkg_sweb_mae_gene.sp_regi_rlog_erro('AUDI_ERROR','SP_ACT_TIPO_MOVI','SP_ACT_TIPO_MOVI','Error al actualizar el tipo de movimiento'
           ,p_ret_mens,p_cod_tipo_movi);
            ROLLBACK;
    END sp_act_tipo_movi;

END pkg_sweb_cred_soli_mant_tm;