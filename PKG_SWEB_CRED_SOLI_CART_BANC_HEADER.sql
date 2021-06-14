create or replace PACKAGE VENTA.PKG_SWEB_CRED_SOLI_CART_BANC AS


 /*-----------------------------------------------------------------------------
      Nombre : SP_LIST_CRED_SOLI_CB
      Proposito : Lista informacion de las Solicitudes Credito con CartaBanco ingresada.
      Referencias : 
      Parametros :
      Log de Cambios
        Fecha        Autor          Descripcion
        06/03/2019   jaltamirano    req-87567     Creacion
  ----------------------------------------------------------------------------*/
PROCEDURE SP_LIST_CRED_SOLI_CB(
        p_cod_cred_soli     IN vve_cred_soli.cod_soli_cred%type,
        p_cod_usua_sid      IN sistemas.usuarios.co_usuario%TYPE,
        p_cod_usua_web      IN sistemas.sis_mae_usuario.cod_id_usuario%TYPE,
        p_ret_cursor        OUT SYS_REFCURSOR,
        p_ret_esta          OUT NUMBER,
        p_ret_mens          OUT VARCHAR2
    );
    

/********************************************************************************
    Nombre:     SP_ACTU_CRED_SOLI_CB
    Proposito:  Actualizar carta pago de una solicitud de credito.
    Referencias:
    Parametros: p_cod_soli_cred          ---> Código de la solicitud.
                p_cod_banco              ---> codigo del bnco.
                p_txt_ofic_banc          ---> Nombre Oficina Banco.
                p_num_fax               ---> Numero fax de entidad bancaria.
                p_fec_aprob_cart_ban    ---> Fecha de aprobacion de la carta.
                p_cod_mone_cart_banc    ---> Moneda bancaria del CP.
                p_val_mone_aprob_banc   ---> Monto aprobado por el banco.
                p_txt_nomb_ejec_banc    ---> Nombre del ejecutivo del banco.
                p_txt_ruta_cart_banc    ---> Ruta donde se guardo la CP.
                p_num_tele_fijo_ejec    ---> Telefono fijo del ejecutivo del banco.
                p_num_celu_ejec         ---> Celular del ejecutivo del banco.
                P_COD_USUA_SID           ---> Código del usuario.
                P_RET_ESTA               ---> Id del usuario.
                P_RET_MENS               ---> Código de ficha de venta generado.


    REVISIONES:
    Version    Fecha       Autor            Descripcion
    ---------  ----------  ---------------  ------------------------------------
    1.0        04/03/2019  jaltamirano        Creación del procedure.
  ********************************************************************************/
  
  PROCEDURE SP_ACTU_CRED_SOLI_CB (
        p_cod_soli_cred         IN                  vve_cred_soli.cod_soli_cred%TYPE,
        p_cod_banco				IN					vve_cred_soli.cod_banco%type,
		p_txt_ofic_banc			IN					vve_cred_soli.txt_ofic_banc%TYPE,
		p_num_fax				IN					vve_cred_soli.num_fax%TYPE,
		p_fec_aprob_cart_ban	IN					VARCHAR2, --vve_cred_soli.fec_aprob_cart_ban%TYPE,
		p_cod_mone_cart_banc	IN					vve_cred_soli.cod_mone_cart_banc%TYPE,
		p_val_mone_aprob_banc	IN					vve_cred_soli.val_mone_aprob_banc%TYPE,
		p_txt_nomb_ejec_banc	IN					vve_cred_soli.txt_nomb_ejec_banc%TYPE,
		p_txt_ruta_cart_banc	IN					vve_cred_soli.txt_ruta_cart_banc%TYPE,
		p_num_tele_fijo_ejec	IN					vve_cred_soli.num_tele_fijo_ejec%TYPE,
		p_num_celu_ejec			IN					vve_cred_soli.num_celu_ejec%TYPE,
		p_cod_usua_sid      	IN 					sistemas.usuarios.co_usuario%TYPE,
        p_ret_esta              OUT                 NUMBER,
        p_ret_mens              OUT                 VARCHAR2
    );

END PKG_SWEB_CRED_SOLI_CART_BANC;
