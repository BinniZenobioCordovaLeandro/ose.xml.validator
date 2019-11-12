<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	xmlns:regexp="http://exslt.org/regular-expressions" 
	xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions" 
	xmlns:func="http://exslt.org/functions" 
	xmlns="urn:oasis:names:specification:ubl:schema:xsd:DebitNote-2" 
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#" 
	xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" 
	xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
	xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" 
	xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" 
	xmlns:dp="http://www.datapower.com/extensions" 
	extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">

    <!--xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" / -->
	<!-- <xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" /> -->
	<xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" />


    <!-- key de Datos del documento que se modifica  -->
    <xsl:key name="by-Billingreference" match="cac:BillingReference/cac:InvoiceDocumentReference" use="concat(cbc:DocumentTypeCode, cbc:ID)"/>
	
	<!-- key Tipo y número de la guía de remisión relacionada -->
    <xsl:key name="by-document-despatch-reference" match="*[local-name()='DebitNote']/cac:DespatchDocumentReference" use="concat(cbc:DocumentTypeCode, ' ', cbc:ID)"/>
	
	<!-- key Tipo y número de otro documento relacionado -->
	<xsl:key name="by-document-additional-reference" match="*[local-name()='DebitNote']/cac:AdditionalDocumentReference" use="concat(cbc:DocumentTypeCode, ' ', cbc:ID)"/>
	
	<!-- key Código de tributo - cabecera -->
	<xsl:key name="by-codigo-tributo-cabecera-reference" match="*[local-name()='DebitNote']/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-')"/>
	
	<!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-debitNoteLine-id" match="*[local-name()='DebitNote']/cac:DebitNoteLine" use="number(cbc:ID)"/>
	
	<!-- key tributos duplicados por linea -->
    <xsl:key name="by-tributos-in-line" match="cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../cbc:ID)"/>
	
    
	<xsl:template match="/*">
    
        <!-- 
        ===========================================================================================================================================
        Ini Variables  
        ===========================================================================================================================================
        -->
        
		<!-- INI SOLO_PRUEBAS -->
		<!-- <xsl:variable name="fileName" select="'20480072872-08-FG99-2075.xml'"/>
		<xsl:variable name="numeroRuc" select="substring($fileName, 1, 11)"/>
		<xsl:variable name="numeroSerie" select="substring($fileName, 16, 4)"/>
		<xsl:variable name="numeroComprobante" select="substring($fileName, 21, string-length($fileName) - 24)"/> -->
		
		<xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
        
        <xsl:variable name="numeroSerie" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)"/>
		
		<xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/>
		
		<!-- FIN SOLO_PRUEBAS -->
        
        <xsl:variable name="tipoComprobante">
            <xsl:choose>
                <xsl:when test="substring($numeroSerie, 1, 1) = 'F' ">
                    <xsl:value-of select="'01'"/>
                </xsl:when>
                <xsl:when test="substring($numeroSerie, 1, 1) = 'S' ">
                    <xsl:value-of select="'14'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'03'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

		<xsl:variable name="monedaComprobante" select="cbc:DocumentCurrencyCode/text()"/>
		
		<!-- 
		<xsl:variable name="sumatoriaIGV">
            <xsl:choose>
				<xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="sumatoriaIVAP">
            <xsl:choose>
                <xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="sumatoriaISC">
            <xsl:choose>
                <xsl:when test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

		<xsl:variable name="sumMontoTotalImpuestos" select="number($sumatoriaIGV) + number($sumatoriaIVAP) + number($sumatoriaISC)"/>
		-->
		<!-- 
        ===========================================================================================================================================
        Fin Variables  
        ===========================================================================================================================================
        -->
		
        
		<!-- 
        ===========================================================================================================================================
        Ini Datos de la Nota de credito  
        ===========================================================================================================================================
        -->
        
        <!-- Numero de RUC del nombre del archivo no coincide con el consignado en el contenido del archivo XML -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1034'" />
            <xsl:with-param name="node" select="cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroRuc != cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
        </xsl:call-template>
        
        <!-- Numero de Serie del nombre del archivo no coincide con el consignado en el contenido del archivo XML -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1035'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroSerie != substring(cbc:ID, 1, 4)" />
        </xsl:call-template>
        
        <!-- Numero de documento en el nombre del archivo no coincide con el consignado en el contenido del XML -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1036'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroComprobante != substring(cbc:ID, 6)" />
        </xsl:call-template>
    

        <!-- /DebitNote/cbc:UBLVersionID No existe el Tag UBL o es vacío
        ERROR 2075 -->
        
        <!-- /DebitNote/cbc:UBLVersionID El valor del Tag UBL es diferente de "2.1"
        ERROR 2074 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="errorCodeValidate" select="'2074'"/>
            <xsl:with-param name="node" select="cbc:UBLVersionID"/>
            <xsl:with-param name="regexp" select="'^(2.1)$'"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cbc:CustomizationID No existe el Tag UBL o es vacío
        ERROR 2073 -->
        
        <!-- /DebitNote/cbc:CustomizationID El valor del Tag UBL es diferente de "2.0"
        ERROR 2072 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2073'"/>
            <xsl:with-param name="errorCodeValidate" select="'2072'"/>
            <xsl:with-param name="node" select="cbc:CustomizationID"/>
            <xsl:with-param name="regexp" select="'^(2.0)$'"/>
        </xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4250'"/>
			<xsl:with-param name="node" select="cbc:CustomizationID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <!-- Numeracion, conformada por serie y numero correlativo -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'1001'"/>
			<xsl:with-param name="node" select="cbc:ID"/>
			<xsl:with-param name="regexp" select="'^[FBS][A-Z0-9]{3}-[0-9]{1,8}?$'"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:DiscrepancyResponse Existe más de un Tag UBL en el /DebitNote
        ERROR 2415 -->
        <!-- TODO para confirmar
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2415'" />
            <xsl:with-param name="node" select="cac:DiscrepancyResponse" />
            <xsl:with-param name="expresion" select="count(cac:DiscrepancyResponse)>1" />
        </xsl:call-template>
		-->
        
        <!-- /DebitNote/cac:DiscrepancyResponse/cbc:ResponseCode No existe el Tag UBL o es vacío
        ERROR 2128 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2128'"/>
            <xsl:with-param name="errorCodeValidate" select="'2128'"/>
            <xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode"/>
            <xsl:with-param name="regexp" select="'^((?!\s*$)[^\s].*)$'"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:DiscrepancyResponse/cbc:ResponseCode El Tag UBL no existe en el listado
        ERROR 2172 -->
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'10'"/>
            <xsl:with-param name="idCatalogo" select="cac:DiscrepancyResponse/cbc:ResponseCode"/>
            <xsl:with-param name="errorCodeValidate" select="'2172'"/>
        </xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3203'" />
            <xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode" />
            <xsl:with-param name="expresion" select="count(cac:DiscrepancyResponse/cbc:ResponseCode) &gt; 1" />
        </xsl:call-template>
        
		<!-- cac:DiscrepancyResponse/cbc:ResponseCode/@listAgencyName Si existe el atributo, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- cac:DiscrepancyResponse/cbc:ResponseCode/@listName Si existe el atributo, el valor ingresado es diferente a 'Tipo de nota de credito'-->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de nota de débito)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- cac:DiscrepancyResponse/cbc:ResponseCode/@listURI Si existe el atributo, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo09' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:ResponseCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo10)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
        <!-- /DebitNote/cac:DiscrepancyResponse/cbc:Description No existe el Tag UBL o es vacío
        ERROR 2136 -->
        
        <!-- /DebitNote/cac:DiscrepancyResponse/cbc:Description El formato del Tag UBL es diferente a alfanumérico de 1 hasta 500 caracteres (se considera cualquier carácter excepto salto de línea.)
        ERROR 2135 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2136'"/>
            <xsl:with-param name="errorCodeValidate" select="'2135'"/>
            <xsl:with-param name="node" select="cac:DiscrepancyResponse/cbc:Description"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,499}$'"/>
        </xsl:call-template>
        
		<!-- /DebitNote/cbc:DocumentCurrencyCode No existe el Tag UBL o es vacío
        ERROR 2070 -->
        
        <!-- /DebitNote/cbc:DocumentCurrencyCode Si el Tag UBL existe, el valor del Tag UBL no existe en el listado
        ERROR 2922 -->
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2070'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode"/>
		</xsl:call-template>
	
		<!-- /CreditNote/cbc:DocumentCurrencyCode Si el Tag UBL existe, el valor del Tag UBL no existe en el listado
        ERROR 3088 -->
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'3088'"/>
			<xsl:with-param name="idCatalogo" select="cbc:DocumentCurrencyCode"/>
			<xsl:with-param name="catalogo" select="'02'"/>
		</xsl:call-template>
        
        <!-- /DebitNote/cbc:DocumentCurrencyCode La moneda de los totales de línea y totales de comprobantes es diferente al valor del Tag UBL
        ERROR 2071 -->
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2071'" />
            <xsl:with-param name="node" select="descendant::*[@currencyID != $monedaComprobante]/@currencyID" />
            <xsl:with-param name="expresion" select="descendant::*[@currencyID != $monedaComprobante]" />
        </xsl:call-template>
        
		<!-- 
        ===========================================================================================================================================
        Fin Datos de la Nota de credito  
        ===========================================================================================================================================
        -->
		
        
		
		<!-- Ini Datos del Emisor -->
        
        <xsl:apply-templates select="cac:AccountingSupplierParty"/>
        
        <!-- Fin Datos del Emisor --> 
        

		<!-- Ini Datos del ciente o receptor -->
        
        <xsl:apply-templates select="cac:AccountingCustomerParty"/>
        
        <!-- Fin Datos del ciente o receptor --> 
		
		
		<!-- Ini Datos del documento que se modifica  -->

        <xsl:apply-templates select="cac:BillingReference">
			<xsl:with-param name="root" select="."/>
		</xsl:apply-templates>
        
        <!-- Fin Datos del documento que se modifica  --> 
		
		
		<!-- Ini Datos del Tipo y número de la guía de remisión relacionada  -->

        <xsl:apply-templates select="cac:DespatchDocumentReference">
			<xsl:with-param name="root" select="."/>
		</xsl:apply-templates>
        
        <!-- Fin Datos del Tipo y número de la guía de remisión relacionada  --> 
	   
		
		<!-- Ini Datos del Tipo y número de otro documento relacionado  -->

        <xsl:apply-templates select="cac:AdditionalDocumentReference">
			<xsl:with-param name="root" select="."/>
		</xsl:apply-templates>
        
        <!-- Fin Datos del Tipo y número de otro documento relacionado  --> 
	   
	   
		<!-- Ini Totales de la Nota de Debito -->

        <xsl:apply-templates select="cac:TaxTotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
			<!-- <xsl:with-param name="sumMontoTotalImpuestos" select="$sumMontoTotalImpuestos"/>-->
        </xsl:apply-templates>
		
		<!-- Fin Totales de la Nota de Debito -->
		
		 
		
		
		
		<!-- Ini Totales/subTotales de la Nota de Debito -->

        <xsl:apply-templates select="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
			<!--<xsl:with-param name="sumMontosTotales" select="$sumMontosTotales"/>-->
        </xsl:apply-templates>
		
		<!-- Fin Totales/subTotales de la Nota de Debito -->
		
		<xsl:variable name="descuentosGlobalesNOAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '03']]/cbc:Amount)"/>
        <xsl:variable name="descuentosxLineaNOAfectaBI" select="sum(cac:debitNoteLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '01']]/cbc:Amount)"/>
       	<xsl:variable name="totalDescuentos" select="sum(cac:RequestedMonetaryTotal/cbc:AllowanceTotalAmount)"/>
       	<xsl:variable name="totalDescuentosCalculado" select="$descuentosGlobalesNOAfectaBI + $descuentosxLineaNOAfectaBI"/>
        <xsl:variable name="cargosxLineaNOAfectaBI" select="sum(cac:debitNoteLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '48']]/cbc:Amount)"/>
        <xsl:variable name="cargosGlobalesNOAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '45' or text() = '46' or text() = '50' or text() = '51' or text() = '52' or text() = '53']]/cbc:Amount)"/>
       	<xsl:variable name="totalCargos" select="sum(cac:RequestedMonetaryTotal/cbc:ChargeTotalAmount)"/>
       	<xsl:variable name="totalCargosCalculado" select="$cargosGlobalesNOAfectaBI + $cargosxLineaNOAfectaBI"/>
        <!-- <xsl:variable name="totalPrecioVenta" select="sum(cac:RequestedMonetaryTotal/cbc:PayableAmount)"/> -->
        <xsl:variable name="totalPrecioVenta" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9997' or text() = '9998']]/cbc:TaxableAmount)"/>
        <xsl:variable name="totalAnticipo" select="sum(cac:RequestedMonetaryTotal/cbc:PrepaidAmount)"/>
        <xsl:variable name="totalImporte" select="sum(cac:RequestedMonetaryTotal/cbc:PayableAmount)"/>
        <xsl:variable name="totalRedondeo" select="sum(cac:RequestedMonetaryTotal/cbc:PayableRoundingAmount)"/>
        <xsl:variable name="totalImporteCalculado" select="$totalPrecioVenta + $totalCargos - $totalDescuentos - $totalAnticipo + $totalRedondeo"/>
        <xsl:variable name="totalValorVenta" select="sum(cac:RequestedMonetaryTotal/cbc:LineExtensionAmount)"/>
        <xsl:variable name="SumatoriaIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
        <xsl:variable name="SumatoriaIVAP" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxAmount)" />
        <xsl:variable name="SumatoriaISC" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
        <xsl:variable name="SumatoriaOtrosTributos" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)" />
        <xsl:variable name="MontoBaseIGV" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount"/>
        <xsl:variable name="MontoBaseIVAP" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount"/>
        <xsl:variable name="MontoBaseIGVLinea" select="sum(cac:debitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
        <xsl:variable name="MontoBaseIVAPLinea" select="sum(cac:debitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)"/>
        <xsl:variable name="MontoDescuentoAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)"/>
        <xsl:variable name="MontoDescuentoAfectoBIAnticipo" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '04']]/cbc:Amount)"/>
        <xsl:variable name="MontoCargosAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)"/>
        <!--<xsl:variable name="totalValorVentaxLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '1000' or text() = '1016' or text() = '9995' or text() = '9997' or text() = '9998']]/cbc:TaxableAmount)"/>-->
        <xsl:variable name="totalValorVentaxLinea" select="sum(cac:debitNoteLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '1000' or text() = '1016' or text() = '9995' or text() = '9997' or text() = '9998']]//cbc:LineExtensionAmount)"/>
        <xsl:variable name="DescuentoGlobalesAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)"/>
        <xsl:variable name="cargosGlobalesAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)"/>
       	<xsl:variable name="totalValorVentaCalculado" select="$totalValorVentaxLinea - $DescuentoGlobalesAfectaBI + $cargosGlobalesAfectaBI"/>
       	<xsl:variable name="totalPrecioVentaCalculadoIGV" select="$totalValorVenta + $SumatoriaISC + $SumatoriaOtrosTributos + ($MontoBaseIGVLinea - $MontoDescuentoAfectoBI + $MontoCargosAfectoBI) * 0.18"/>
       	<xsl:variable name="totalPrecioVentaCalculadoIVAP" select="$totalValorVenta + $SumatoriaOtrosTributos + ($MontoBaseIVAPLinea - $MontoDescuentoAfectoBI + $MontoCargosAfectoBI) * 0.04"/>
       	<xsl:variable name="SumatoriaIGVCalculado" select="($MontoBaseIGVLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo + $MontoCargosAfectoBI) * 0.18"/>
       	<xsl:variable name="SumatoriaIVAPCalculado" select="($MontoBaseIVAPLinea - $MontoDescuentoAfectoBI - $MontoDescuentoAfectoBIAnticipo + $MontoCargosAfectoBI) * 0.04"/>
     
		<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4290'" />
	            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="($SumatoriaIGV + 1 ) &lt; $SumatoriaIGVCalculado or ($SumatoriaIGV - 1) &gt; $SumatoriaIGVCalculado" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
     
       	<xsl:if test="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]">
			   <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4302'" />
	            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="($SumatoriaIVAP + 1 ) &lt; $SumatoriaIVAPCalculado or ($SumatoriaIVAP - 1) &gt; $SumatoriaIVAPCalculado" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4312'" />
            <xsl:with-param name="node" select="cac:RequestedMonetaryTotal/cbc:PayableAmount" />
            <xsl:with-param name="expresion" select="cac:RequestedMonetaryTotal/cbc:PayableAmount and (($totalImporte + 1 ) &lt; $totalImporteCalculado or ($totalImporte - 1) &gt; $totalImporteCalculado)" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
		
		<!-- /DebitNote/cac:RequestedMonetaryTotal/cbc:ChargeTotalAmount  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
        ERROR   2065
        -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeNotExist" select="'2065'"/>
            <xsl:with-param name="errorCodeValidate" select="'2065'"/>
            <xsl:with-param name="node" select="cac:RequestedMonetaryTotal/cbc:ChargeTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:RequestedMonetaryTotal/cbc:AllowanceTotalAmount  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales
        ERROR   2064
        -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeNotExist" select="'2064'"/>
            <xsl:with-param name="errorCodeValidate" select="'2064'"/>
            <xsl:with-param name="node" select="cac:RequestedMonetaryTotal/cbc:AllowanceTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:RequestedMonetaryTotal/cbc:PayableAmount El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR   2062
         -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2062'"/>
            <xsl:with-param name="errorCodeValidate" select="'2062'"/>
            <xsl:with-param name="node" select="cac:RequestedMonetaryTotal/cbc:PayableAmount"/>
            <xsl:with-param name="isGreaterCero" select="true()"/>
        </xsl:call-template>
        
		<xsl:apply-templates select="cbc:Note"/>
		<!-- Ini Datos del detalle o Ítem de la Nota de Debito  -->
		
		<xsl:apply-templates select="cac:DebitNoteLine">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
		
		<!-- Fin Datos del detalle o Ítem de la Nota de Debito  -->
		
		<!--  Debe existir en el cac:DebitNoteLine un bloque TaxTotal ERROR 3195 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2956'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
            <xsl:with-param name="expresion" select="not(cac:TaxTotal)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
 
 
        <!-- Retornamos el comprobante al flujo necesario para lotes -->
        <xsl:copy-of select="."/>
        
    </xsl:template>
    
        
		
	<!-- 
    ===========================================================================================================================================
    *******************************************************************************************************************************************
                                                       TEMPLATES
    *******************************************************************************************************************************************
    ===========================================================================================================================================
    -->
	
	 <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cbc:Note =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cbc:Note">
		
		<xsl:if test="@languageLocaleID">    
            <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3027'"/>
				<xsl:with-param name="idCatalogo" select="@languageLocaleID"/>
				<xsl:with-param name="catalogo" select="'52'"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="existAndRegexpValidateElement">
        	<xsl:with-param name="errorCodeNotExist" select="'3006'"/>
			<xsl:with-param name="errorCodeValidate" select="'3006'"/>
			<xsl:with-param name="node" select="text()"/>
			<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,199}$'"/>
			<xsl:with-param name="descripcion" select="concat('Leyenda : ', @languageLocaleID)"/>
		</xsl:call-template>
       
	</xsl:template>
    
	
	
    
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:AccountingSupplierParty
	===========================================================================================================================================
	--> 
	
    <xsl:template match="cac:AccountingSupplierParty">
    
        <!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID No existe el Tag UBL o es vacío
        ERROR 2676 -->
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2676'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeID No existe el Tag UBL o es vacío
        ERROR 3029 -->
		<!-- DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeID El Tag UBL es diferente a "6"
        ERROR 2511 -->
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'3029'"/>
            <xsl:with-param name="errorCodeValidate" select="'2511'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeName Si existe el tag, el valor ingresado es diferente a 'Documento de Identidad' 
		OBSERVACION 4255 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeAgencyName Si existe el tag, el valor ingresado es diferente a 'PE:SUNAT'
		OBSERVACION 4256 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID@schemeURI Si existe el tag, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06' 
		OBSERVACION 4251 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyName/cbc:Name El valor del tag es mayor al formato establecido 
		OBSERVACION 4092 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4092'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name"/>
			<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,999}$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName No existe el Tag UBL o es vacío
        ERROR 1037 -->
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName El formato del Tag UBL es diferente a alfanumérico de 3 hasta 1000 caracteres  (se considera cualquier carácter excepto salto de línea)
        ERROR 1038 -->
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1037'"/>
            <xsl:with-param name="errorCodeValidate" select="'1038'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,999}$'"/>
        </xsl:call-template>
		
		
        <!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line El formato del Tag UBL es diferente a alfanumérico de 3 a 200 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea) 
		OBSERVACION 4094 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4094'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName El formato del Tag UBL es diferente a alfanumérico de 1 a 25 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea)
		OBSERVACION 4095 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4095'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,24}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName El formato del Tag UBL es diferente a alfanumérico de 1 a 30 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea)
		OBSERVACION 4096 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4096'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID Si el Tag UBL existe, el valor del Tag UBL debe estar en el listado 
		OBSERVACION 4093 -->
        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'4093'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID"/>
			<xsl:with-param name="catalogo" select="'13'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeAgencyName Si existe el atributo, el valor ingresado es diferente a 'PE:INEI' 
		OBSERVACION 4256 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeName Si existe el atributo, el valor ingresado es diferente a 'Ubigeos' 
		OBSERVACION 4255 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity El formato del Tag UBL es diferente a alfanumérico de 1 a 30 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea)
		OBSERVACION 4097 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4097'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> 
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:Distric El formato del Tag UBL es diferente a alfanumérico de 1 a 30 caracteres  (se considera cualquier carácter incluido espacio, sin salto de línea)
		OBSERVACION 4098 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4098'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode Si el Tag UBL existe, el valor del Tag UBL es diferente a PE
		OBSERVACION 4041 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4041'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode"/>
            <xsl:with-param name="regexp" select="'^(PE)$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listID Si existe el tag, el valor ingresado es diferente a 'ISO 3166-1'
		OBSERVACION 4254 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 3166-1)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		        
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listAgencyName Si existe el tag, el valor ingresado es diferente a 'United Nations Economic Commission for Europe'
		OBSERVACION 4251 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listName Si existe el tag, el valor ingresado es diferente a 'Country'
		OBSERVACION 4252 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Country)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'3030'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
			<!-- PAS115 Se cambio a observación por solicitud de Michael Ruiz -->
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4242'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
            <xsl:with-param name="regexp" select="'^[0-9]{4}$'"/> <!-- de 4 dígitoso -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Establecimientos anexos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

    </xsl:template>
    
    <!-- 
	===========================================================================================================================================
	Fin Template cac:AccountingSupplierParty
	===========================================================================================================================================
	--> 
    
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:AccountingCustomerParty
	===========================================================================================================================================
	--> 
   
	<xsl:template match="cac:AccountingCustomerParty">
        
        <!-- numero de documento -->
        <!--<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3090'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>-->
        
        <!-- /DebitNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID No existe el Tag UBL o es vacío
        ERROR 2679 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2679'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID Si "Tipo de documento de identidad del adquiriente" es RUC (6), el formato del Tag UBL es diferente a numérico de 11 dígitos
        ERROR 2017 -->
        <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6'">
            <xsl:call-template name="regexpValidateElementIfExist">
             <xsl:with-param name="errorCodeValidate" select="'2017'"/>
             <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
             <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
         </xsl:call-template>
        </xsl:if>
		
		<!-- /DebitNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID No existe el Tag UBL o es vacío
        ERROR 2679 -->
        <!-- /DebitNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeID El Tag UBL es diferente al listado
        ERROR 2922 -->
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2679'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
		</xsl:call-template>
	
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'2016'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
			<xsl:with-param name="catalogo" select="'06'"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeName
		OBSERVACION 4255 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName
		OBSERVACION 4256 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI
		OBSERVACION 4257 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <!-- /DebitNote/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName No existe el Tag UBL o es vacío
        ERROR 2021 -->
        <!-- /DebitNote/cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName El formato del Tag UBL es diferente a alfanumérico de 3 hasta 1000 caracteres (se considera cualquier carácter excepto salto de línea)
        ERROR 2022 --> 
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2021'"/>
            <xsl:with-param name="errorCodeValidate" select="'2022'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,999}$'"/>
        </xsl:call-template>
        
    </xsl:template>

	<!-- 
	===========================================================================================================================================
	Fin Template cac:AccountingCustomerParty
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:BillingReference
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:BillingReference">
		<xsl:param name="root" select = "'-'" />
		
		<!-- /DebitNote/cac:DiscrepancyResponse/cbc:ResponseCode Si tipo de nota de credito es 10 Ajustes de operaciones de exportación, y existe mas de un tag /DebitNote/cac:BillingReference/
        ERROR 3194 -->
        <xsl:if test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11'">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3194'" />
				<xsl:with-param name="node" select="$root/cac:BillingReference" />
				<xsl:with-param name="expresion" select="count($root/cac:BillingReference)>1" />
			</xsl:call-template>
        </xsl:if>
		
        
        <xsl:choose>
		
			<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de dédito" es "03" (Penalidades/ otros conceptos) el formato del tag UBL puede ser, vacío ó:
			- [F][A-Z0-9]{3}-[0-9]{1,8}
			- (E001)-[0-9]{1,8}
			- [0-9]{1,4}-[0-9]{1,8}
			- [B][A-Z0-9]{3}-[0-9]{1,8}
			- (EB01)-[0-9]{1,8}
			- [S][A-Z0-9]{3}-[0-9]{1,8}
			- [a-zA-Z0-9-]{1,20}-[0-9]{1,10}
			ERROR 2205 -->
			<xsl:when test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '03'">
			
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'2205'"/>
					<xsl:with-param name="errorCodeValidate" select="'2205'"/>
					<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
					<xsl:with-param name="regexp" select="'^(([F][A-Z0-9]{3}-[0-9]{1,8})|((E001)-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8})|([B][A-Z0-9]{3}-[0-9]{1,8})|((EB01)-[0-9]{1,8})|([S][A-Z0-9]{3}-[0-9]{1,8})|([a-zA-Z0-9-]{1,20}-[0-9]{1,10}))$'"/>
				</xsl:call-template>
				
				<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de Debito" es igual a"10" (Otros conceptos),  el valor del tag UBL puede ser vacío ó los valores del catálogo 01.
				ERROR 2922 -->
				<xsl:if test="string(cac:InvoiceDocumentReference/cbc:DocumentTypeCode)">
					<xsl:call-template name="findElementInCatalog">
						<xsl:with-param name="catalogo" select="'01'"/>
						<xsl:with-param name="idCatalogo" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode"/>
						<xsl:with-param name="errorCodeValidate" select="'2922'"/>
					</xsl:call-template>
				</xsl:if>
			
			</xsl:when>
			<xsl:otherwise>
			
				<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de Debito" es diferente de "10" (Otros conceptos) y la nota Debito modifica a una factura, el formato del Tag UBL es diferente a:
				- [F][A-Z0-9]{3}-[0-9]{1,8}
				- (E001)-[0-9]{1,8}
				- [0-9]{1,4}-[0-9]{1,8}
				ERROR 2205 -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '01'">
					<xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2205'"/>
						<xsl:with-param name="errorCodeValidate" select="'2205'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^(([F][A-Z0-9]{3}-[0-9]{1,8})|((E001)-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8}))$'"/>
					</xsl:call-template>
				</xsl:if>
				
				<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de Debito" es diferente de "10" (Otros conceptos) y la NC modifica a una boleta de venta (tipo de comprobante =03), y el formato del Tag UBL es diferente a:
				- [B][A-Z0-9]{3}-[0-9]{1,8}
				- (EB01)-[0-9]{1,8}
				- [0-9]{1,4}-[0-9]{1,8}
				ERROR 2205 -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '03'">
					<xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2205'"/>
						<xsl:with-param name="errorCodeValidate" select="'2205'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^(([B][A-Z0-9]{3}-[0-9]{1,8})|((EB01)-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8}))$'"/>
					</xsl:call-template>
				</xsl:if>
				
				<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de cédito" es diferente de "10" (Otros conceptos) y la NC modifica a un DAE (tipo de comprobante =14), y el formato del Tag UBL es diferente a:
				- [S][A-Z0-9]{3}-[0-9]{1,8}
				- [0-9]{1,4}-[0-9]{1,8}
				- [0-9]{1,8} (Para caso de DAE sin serie)
				ERROR 2205 -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '14'">
                
					<xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2205'"/>
						<xsl:with-param name="errorCodeValidate" select="'2205'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^(([S][A-Z0-9]{3}-[0-9]{1,8})|([0-9]{1,4}-[0-9]{1,8})|([0-9]{1,8}))$'"/>
					</xsl:call-template>
				</xsl:if>
				
				<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de cédito" es diferente de "10" (Otros conceptos) y  "Tipo del documento del documento que modifica" es "12", el formato del Tag UBL es diferente a:
				- [a-zA-Z0-9-]{1,20}-[0-9]{1,10}
				ERROR 2205 -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '12'">
				   <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2205'"/>
						<xsl:with-param name="errorCodeValidate" select="'2205'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^([a-zA-Z0-9-]{1,20}-[0-9]{1,10})$'"/>
					</xsl:call-template>
				</xsl:if>
				
				<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si "Código de tipo de nota de Debito" es diferente de "10" (Otros conceptos) y Si "Tipo del documento del documento que modifica" es "56", el valor del Tag UBL es diferente a alfanumérico (incluido el guión)
				ERROR 2205 -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode = '56'">
				   <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2205'"/>
						<xsl:with-param name="errorCodeValidate" select="'2205'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^[\w\d\- ]+$'"/>
					</xsl:call-template>
				</xsl:if>
				
				<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID Si la nota de Debito modifica un Documento autorizado (tipo de comprobante "06","13","16", "37", "43","45","24","15"), la serie de la nota de credito debe iniciar con F y el formato del Tag UBL es diferente a:
				- [0-9]{1,4}-[0-9]{1,8}
				- [A-Z0-9]{1,9}-[A-Z0-9]{1,20}
				ERROR 2205 -->
				<xsl:if test="cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text()='06' or text()='13' or text()='16' or text()='37' or text()='43' or text()='45' or text()='24' or text()='15']">
				   <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2205'"/>
						<xsl:with-param name="errorCodeValidate" select="'2205'"/>
						<xsl:with-param name="node" select="$root/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^(([F][A-Z0-9]{3}-[0-9]{1,8}))$'"/>
				   </xsl:call-template>
				   <xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'2205'"/>
						<xsl:with-param name="errorCodeValidate" select="'2205'"/>
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID"/>
						<xsl:with-param name="regexp" select="'^(([0-9]{1,4}-[0-9]{1,8})|([A-Z0-9]{1,9}-[A-Z0-9]{1,20}))$'"/>
					</xsl:call-template>
				</xsl:if>
				
				<!-- /DebitNote/cac:BillingReference/InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de Debito" es diferente de "10" (Otros conceptos) y la Serie del comprobante empieza con "B", el Tag UBL es diferente de "03"
				ERROR 2399 -->
				<xsl:if test="substring($root/cbc:ID, 1, 1) = 'B'">
					<xsl:call-template name="isTrueExpresion">
						<xsl:with-param name="errorCodeValidate" select="'2400'" />
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
						<xsl:with-param name="expresion" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode != '03'" />
					</xsl:call-template>
				</xsl:if>
				
				<!-- /DebitNote/cac:BillingReference/InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de Debito" es diferente de "10" (Otros conceptos) y  la Serie del comprobante empieza con "F", el Tag UBL es diferente de "01", "12", "56"
				ERROR 2116 -->
				<xsl:if test="substring($root/cbc:ID, 1, 1) = 'F'">
					<xsl:call-template name="isTrueExpresion">
						<xsl:with-param name="errorCodeValidate" select="'2204'" />
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
						<xsl:with-param name="expresion" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode[text() !='01' and text() !='12' and text() !='56']" />
					</xsl:call-template>
				</xsl:if>
				
				<!-- /DebitNote/cac:BillingReference/InvoiceDocumentReference/cbc:DocumentTypeCode Si "Código de tipo de nota de Debito" es diferente de "10" (Otros conceptos) y la Serie del comprobante empieza con "S", el Tag UBL es diferente de "14"
				ERROR 2930 -->
				<xsl:if test="substring($root/cbc:ID, 1, 1) = 'S'">
					<xsl:call-template name="isTrueExpresion">
						<xsl:with-param name="errorCodeValidate" select="'2930'" />
						<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode" />
						<xsl:with-param name="expresion" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode != '14'" />
					</xsl:call-template>
                </xsl:if>
				
            </xsl:otherwise>

        </xsl:choose>
        
		
        <!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID El "Tipo de documento del documento que modifica" concatenado con el valor del Tag UBL no debe repetirse en el /DebitNote
        ERROR 2365 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2365'" />
            <xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-Billingreference', concat(cac:InvoiceDocumentReference/cbc:DocumentTypeCode, cac:InvoiceDocumentReference/cbc:ID))) > 1" />
        </xsl:call-template>
		
		<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listAgencyName Si existe el atributo, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listName Si existe el atributo, el valor ingresado es diferente a 'Tipo de nota de credito'-->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:BillingReference/cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listURI Si existe el atributo, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo09' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:InvoiceDocumentReference/cbc:DocumentTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:BillingReference
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:DespatchDocumentReference
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:DespatchDocumentReference">
    
        <!-- /DebitNote/cac:DespatchDocumentReference/cbc:ID Si el Tag UBL existe, el formato del Tag UBL es diferente a: 
		- [T][0-9]{3}-[0-9]{1,8}
		- [0-9]{4}-[0-9]{1,8}
		- [EG][0-9]{2}-[0-9]{1,8}
		- [G][0-9]{3}-[0-9]{1,8}
        OBSERV 4006 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4006'"/>
            <xsl:with-param name="errorCodeValidate" select="'4006'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(([T][0-9]{3}-[0-9]{1,8})|([0-9]{4}-[0-9]{1,8})|([E][G][0-9]{2}-[0-9]{1,8})|([G][0-9]{3}-[0-9]{1,8}))$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:DespatchDocumentReference/cbc:ID El "Tipo de la guía de remisión relacionada" concatenado con el valor del Tag UBL no debe repetirse en el /DebitNote
        ERROR 2364 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2364'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-despatch-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) > 1" />
        </xsl:call-template>
		
        <!-- /DebitNote/cac:DespatchDocumentReference/cbc:DocumentTypeCode Si existe el Tag UBL, el formato del Tag UBL es diferente de "09" o "31"
        OBSERV 4005 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4005'"/>
            <xsl:with-param name="errorCodeValidate" select="'4005'"/>
            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
            <xsl:with-param name="regexp" select="'^(31)|(09)$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:DespatchDocumentReference/cbc:DocumentTypeCode/@listAgencyName Si existe el atributo, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:DespatchDocumentReference/cbc:DocumentTypeCode/@listName Si existe el atributo, el valor ingresado es diferente a 'Tipo de nota de credito'-->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:DespatchDocumentReference/cbc:DocumentTypeCode/@listURI Si existe el atributo, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo09' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
    
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:DespatchDocumentReference
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:AdditionalDocumentReference
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:AdditionalDocumentReference">
        <xsl:param name="root" select = "'-'" />
    
        <!-- /DebitNote/cac:AdditionalDocumentReference/cbc:ID El formato del Tag UBL es diferente a alfanumérico de entre 6 y 30 caracteres  (se considera cualquier carácter no permite "whitespace character": espacio, salto de línea, fin de línea, tab, etc.)
        OBSERV 4010 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4010'"/>
            <xsl:with-param name="errorCodeValidate" select="'4010'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{6,30}$'"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:AdditionalDocumentReference/cbc:ID El "Tipo de otro documento relacionado" concatenado con el valor del Tag UBL, no debe repetirse en el /DebitNote
        ERROR 2426 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2426'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-additional-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) > 1" />
        </xsl:call-template>

        <!-- /DebitNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode El formato del Tag UBL es diferente de "04" o "05" o "99" o "01"
        ERROR 4009 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4009'"/>
            <xsl:with-param name="errorCodeValidate" select="'4009'"/>
            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
            <xsl:with-param name="regexp" select="'^(0[145]|99)$'"/>
            <xsl:with-param name="isError" select ="true()"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode/@schemeName Si existe el tag, el valor ingresado es diferente a 'Documentos Relacionados' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documentos Relacionados)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode/@schemeAgencyName Si existe el tag, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:AdditionalDocumentReference/cbc:DocumentTypeCode/@schemeURI Si existe el tag, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:AdditionalDocumentReference
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:TaxTotal mode=cabecera
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:TaxTotal" mode="cabecera">
		<xsl:param name="root" select = "'-'" />
		<!-- <xsl:param name="sumMontoTotalImpuestos" select = "'0'" />-->
        
		<!-- /DebitNote/cac:TaxTotal/cbc:TaxAmount Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR 3020 -->
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeNotExist" select="'3020'"/>
            <xsl:with-param name="errorCodeValidate" select="'3020'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:TaxTotal/cbc:TaxAmount Si el Tag UBL existe, el monto total de impuestos es diferente a la sumatoria de impuestos (Códigos 1000+1016+2000)
        ERROR 2519 -->
        <xsl:variable name="totalImpuestos" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestos" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000'or text() = '1016' or text() = '9999' or text() = '2000']]/cbc:TaxAmount)"/>
        <!-- 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2519'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalImpuestos + 1 ) &lt; $SumatoriaImpuestos or ($totalImpuestos - 1) &gt; $SumatoriaImpuestos" />            
        </xsl:call-template>-->
		<!--InvoiceLine -> DebitNoteLine-->
		<xsl:if test="$root/cac:DebitNoteLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode ='02'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2641'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '9996']/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0" />
            </xsl:call-template>
        </xsl:if>
		
		<!-- /DebitNote/cac:TaxTotal El tag cac:TaxTotal no debe repetirse en el comprobante
        ERROR 3024 -->        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3024'" />
            <xsl:with-param name="node" select="$root/cac:TaxTotal" />
            <xsl:with-param name="expresion" select="count($root/cac:TaxTotal) &gt; 1" />
        </xsl:call-template>
		
		<xsl:variable name="totalBaseISC" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseISCxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4303'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseISC + 1 ) &lt; $totalBaseISCxLinea or ($totalBaseISC - 1) &gt; $totalBaseISCxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!-- Validacion de sumatorias -->        
        <xsl:variable name="totalBaseExportacion" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseExportacionxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4295'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9995']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseExportacion + 1 ) &lt; $totalBaseExportacionxLinea or ($totalBaseExportacion - 1) &gt; $totalBaseExportacionxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:variable name="totalBaseExoneradas" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseExoneradasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4297'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseExoneradas + 1 ) &lt; $totalBaseExoneradasxLinea or ($totalBaseExoneradas - 1) &gt; $totalBaseExoneradasxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:variable name="totalBaseInafectas" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseInafectasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4296'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9998']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseInafectas + 1 ) &lt; $totalBaseInafectasxLinea or ($totalBaseInafectas - 1) &gt; $totalBaseInafectasxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:variable name="totalBaseGratuitas" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseGratuitasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4298'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseGratuitas + 1 ) &lt; $totalBaseGratuitasxLinea or ($totalBaseGratuitas - 1) &gt; $totalBaseGratuitasxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>		
		
		<xsl:variable name="totalBaseIGV" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
        <xsl:variable name="totalBaseIVAP" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)"/>
        <xsl:variable name="totalBaseIGVxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalBaseIVAPxLinea" select="sum($root/cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount &gt; 0]/cbc:LineExtensionAmount)"/>
        <xsl:variable name="totalDescuentosGlobales" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '02' or text() = '04']]/cbc:Amount)"/>
        <xsl:variable name="totalCargosGobales" select="sum($root/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode [text() = '49']]/cbc:Amount)"/>
        <xsl:variable name="totalBaseIGVCalculado" select="$totalBaseIGVxLinea - $totalDescuentosGlobales + $totalCargosGobales"/>
        <xsl:variable name="totalBaseIVAPCalculado" select="$totalBaseIVAPxLinea - $totalDescuentosGlobales + $totalCargosGobales"/>
		
		
		<xsl:if test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount &gt; 0">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4299'" />
	            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount" />
	            <xsl:with-param name="expresion" select="($totalBaseIGV + 1 ) &lt; $totalBaseIGVCalculado or ($totalBaseIGV - 1) &gt; $totalBaseIGVCalculado" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
		
		<xsl:if test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount &gt; 0">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4300'" />
	            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount" />
	            <xsl:with-param name="expresion" select="($totalBaseIVAP + 1 ) &lt; $totalBaseIVAPCalculado or ($totalBaseIVAP - 1) &gt; $totalBaseIVAPCalculado" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
						
		<xsl:variable name="totalGratuitas" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount"/>
        <xsl:variable name="totalGratuitasxLinea" select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4311'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalGratuitas + 1 ) &lt; $totalGratuitasxLinea or ($totalGratuitas - 1) &gt; $totalGratuitasxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3196'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalImpuestos + 1 ) &lt; $SumatoriaImpuestos or ($totalImpuestos - 1) &gt; $SumatoriaImpuestos" />
            <xsl:with-param name="isError" select ="true()"/>
        </xsl:call-template>
		
		<xsl:variable name="totalOtros" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount"/>
        <xsl:variable name="totalOtrosxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4306'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalOtros + 1 ) &lt; $totalOtrosxLinea or ($totalOtros - 1) &gt; $totalOtrosxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4020'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:Taxmount" />
            <xsl:with-param name="expresion" select="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount &gt; 0 and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount = 0" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>		
		

    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:TaxTotal mode=cabecera
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:TaxTotal/cac:TaxSubtotal mode=cabecera
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera">
		<xsl:param name="root" select = "'-'" />
		<!--<xsl:param name="sumMontosTotales" select = "'0'" />-->
		
		<xsl:variable name="totValorVentaIGVLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaIVAPLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaISCLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaEXPLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9995']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9995']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaGRALinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9996']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9996']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaEXOLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9997']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9997']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaINALinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9998']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9998']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totValorVentaOTRLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxableAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxableAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totSumatoriaIGVLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1000']/cbc:TaxAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totSumatoriaIVAPLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='1016']/cbc:TaxAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totSumatoriaISCLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		<xsl:variable name="totSumatoriaOTRLinea">
            <xsl:choose>
				<xsl:when test="$root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxAmount">
                    <xsl:value-of select="sum($root/cac:DebitNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID='9999']/cbc:TaxAmount)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
		
		
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()!='9996']">
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount No existe el Tag UBL o es vacío
			ERROR 3003 -->
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3003'"/>
				<xsl:with-param name="node" select="cbc:TaxableAmount"/>
			</xsl:call-template>
		</xsl:if>
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR 2999 -->
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeNotExist" select="'2999'"/>
            <xsl:with-param name="errorCodeValidate" select="'2999'"/>
            <xsl:with-param name="node" select="cbc:TaxableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount si codigo de tributo es = '1000' y  el Tag UBL existe, el valor del Tag UBL es diferente a la sumatoria del total valor de venta - operaciones gravadas de IGV en cada ítem (con una tolerancia + - 1)
        ERROR 3039    
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3039'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaIGVLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaIGVLinea)-1)" />
			</xsl:call-template>
		</xsl:if>
		-->
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount si codigo de tributo es = '1016' y  el Tag UBL existe, el valor del Tag UBL es diferente a la sumatoria del total valor de venta - operaciones gravadas de IGV en cada ítem (con una tolerancia + - 1)
        ERROR 3046  
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1016']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3046'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaIVAPLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaIVAPLinea)-1)" />
			</xsl:call-template>
		</xsl:if>-->  
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si codigo de tributo = '2000', Si el Tag UBL existe y el valor del Tag UBL es diferente a la sumatoria del total valor de venta  - ISC de cada ítem (con una tolerancia + - 1)
        ERROR 3045 
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3045'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaISCLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaISCLinea)-1)" />
			</xsl:call-template>
		</xsl:if>-->   
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si codigo de tributo = '9999', Si el Tag UBL existe, el valor del Tag UBL es diferente a la sumatoria del total valor de venta  - Otros tributos '9999' de cada ítem  (con una tolerancia + - 1)
        ERROR 3008 -->   
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9999']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3008'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaOTRLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaOTRLinea)-1)" />
			</xsl:call-template>
		</xsl:if>
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si  codigo tributo es '1000', el valor del Tag Ubl es diferente de la sumatoria de los importes de IGV de cada ítem
        ERROR 3038 
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3038'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxAmount) &gt; (number($totSumatoriaIGVLinea)+1) or number(cbc:TaxAmount) &lt; (number($totSumatoriaIGVLinea)-1)" />
			</xsl:call-template>
		</xsl:if>-->   
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si  codigo tributo es '1016', el valor del Tag Ubl es diferente de la sumatoria de los importes de IVAP de cada ítem
        ERROR 3049
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1016']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3049'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxAmount) &gt; (number($totSumatoriaIVAPLinea)+1) or number(cbc:TaxAmount) &lt; (number($totSumatoriaIVAPLinea)-1)" />
			</xsl:call-template>
		</xsl:if>
		 -->   
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si  codigo tributo es '2000', el valor del Tag Ubl es diferente de la sumatoria de los importes de ISC de cada ítem (con una tolerancia + - 1)
        ERROR 3048  
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3048'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxAmount) &gt; (number($totSumatoriaISCLinea)+1) or number(cbc:TaxAmount) &lt; (number($totSumatoriaISCLinea)-1)" />
			</xsl:call-template>
		</xsl:if>-->  
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si  codigo tributo es '9999', el valor del Tag Ubl es diferente de la sumatoria de los importes de otros tributos (9999) de cada ítem (con una tolerancia + - 1)
        ERROR 3009   
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9999']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3009'" />
				<xsl:with-param name="node" select="cbc:TaxAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxAmount) &gt; (number($totSumatoriaOTRLinea)+1) or number(cbc:TaxAmount) &lt; (number($totSumatoriaOTRLinea)-1)" />
			</xsl:call-template>
		</xsl:if>--> 
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si el codigo de tributo es = '9995', el valor del Tag UBL es diferente a la sumatoria del total valor de venta - Exportaciones de cada ítem
        ERROR 3040   
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9995']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3040'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaEXPLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaEXPLinea)-1)" />
			</xsl:call-template>
		</xsl:if>--> 
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si el codigo de tributo es = '9996', el valor del Tag UBL es diferente a la sumatoria del total valor de venta - Exportaciones de cada ítem
        ERROR 3057 
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9996']">
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3057'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaGRALinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaGRALinea)-1)" />
			</xsl:call-template>
		</xsl:if>
		-->   
		
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9997']">
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si el codigo de tributo es = '9997', el valor del Tag UBL es diferente a la sumatoria del total valor de venta - operaciones exoneradas de cada ítem  (con una tolerancia + - 1)
			ERROR 3042 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3042'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaEXOLinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaEXOLinea)-1)" />
			</xsl:call-template>--> 
			
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada)  y existe alguna línea con "codigo de tributo por linea" igual a "9997" (Exonerada),  el Tag UBL es igual a 0 (cero)
			OBSERVACION 4018 -->  
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4018'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="count($root/cac:DebitNote/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9997']]) > 0 and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada)  y "Código de leyenda" es 2001, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4022 -->  
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4022'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2001' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada) y "Código de leyenda" es 2002, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4023 -->  
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4023'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2002' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada) y "Código de leyenda" es 2003, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4024 -->  
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4024'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2003' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada) y "Código de leyenda" es 2007, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4243 -->  
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4243'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2007' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9997" (Exonerada) y "Código de leyenda" es 2008, el valor del Tab UBL es igual a 0 (cero)
			OBSERVACION 4244 -->  
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4244'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="$root/cbc:Note/@languageLocaleID='2008' and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			
		</xsl:if>
		
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9998']">
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si el codigo de tributo es = '9998', el valor del Tag UBL es diferente a la sumatoria del total valor de venta - operaciones inafectos de cada ítem  (con una tolerancia + - 1)
			ERROR 3041
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3041'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="number(cbc:TaxableAmount) &gt; (number($totValorVentaINALinea)+1) or number(cbc:TaxableAmount) &lt; (number($totValorVentaINALinea)-1)" />
			</xsl:call-template> --> 
			
			<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxableAmount Si "codigo de tributo" igual a "9998" (inafectas) y  existe alguna línea con "codigo de tributo por linea" igual a "9998" (inafectas), el Tag UBL es igual a 0 (cero)
			OBSERVACION 4017 -->  
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'4017'" />
				<xsl:with-param name="node" select="cbc:TaxableAmount" />
				<xsl:with-param name="expresion" select="count($root/cac:CreditNoteLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9998']]) > 0 and number(cbc:TaxableAmount) = 0" />
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
        ERROR 2048 -->
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeNotExist" select="'2048'"/>
            <xsl:with-param name="errorCodeValidate" select="'2048'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount Si el Tag UBL existe, el valor del Tag Ubl es diferente de 0 (cero), cuando el código de tributo es 9995, 9997 y 9998. 
		ERROR 3000 -->
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3000'" />
			<xsl:with-param name="node" select="cbc:TaxAmount" />
			<xsl:with-param name="expresion" select="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9995' or text()='9997' or text()='9998'] and number(cbc:TaxAmount) != 0" />
		</xsl:call-template>

        <!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID No existe el Tag UBL o es vacío
        ERROR 3059 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3059'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL es diferente al código del tributo del listado
        ERROR 3007 -->
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'3007'"/>
        </xsl:call-template>
        
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el comprobante
        ERROR 3068 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3068'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-codigo-tributo-cabecera-reference', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-'))) > 1" />
        </xsl:call-template>
		
        <!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID Si "código de tipo de nota de credito" es 12 (IVAP)  y existe un Id '9995' o '9997' o '9998' a nivel global
        ERROR 3221 -->
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9995' or text()='9997' or text()='9998']">
		
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3221'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '12' and (cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9995' or text()='9997' or text()='9998'] and cbc:TaxableAmount &gt; 0)" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>
		
		</xsl:if>
		
		<!-- /CreditNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID Si tipo de nota de debito es 11 (Exportacion) y existe un Id '9997' o '9998' a nivel global
		ERROR 3221 -->
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'3221'" />
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
			<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11' and (cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='9997' or text()='9998'])" />
			<xsl:with-param name="isError" select ="true()"/>
		</xsl:call-template>  
		
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000' or text()='1016']">
		
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID Si "código de tipo de nota de credito" es 11 (IVAP) y existe un Id '1000'
			ERROR 3107 --> 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3107'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '12' and (cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000'] and cbc:TaxableAmount &gt; 0)" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>
			
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID si "código de tipo de nota de credito" es 10 (Exportación) y existe un ID '1000' o '1016' o  a nivel global
			ERROR 3107 --> 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3107'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11' and cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1000' or text()='1016']" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>
		
		</xsl:if>
		
		<xsl:if test="cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000' or text()='9999']">
		
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID Si "código de tipo de nota de credito" es 11 (IVAP)  y existe un Id '2000'
			ERROR 3107 --> 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3107'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11' and cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000' or text()='9999']" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>
			
			<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID si "código de tipo de nota de credito" es 10 (Exportación) y existe un ID '2000' o '9999' a nivel global
			ERROR 3107 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3107'" />
				<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
				<xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '10' and cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='2000' or text()='9999']" />
				<xsl:with-param name="isError" select ="true()"/>
			</xsl:call-template>--> 
		
		</xsl:if>

		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID si "código de tipo de nota de credito" es 11 (Exportación) y  '9997' o '9998' en cualquier invoice line
        OBSERV 3107 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3107'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11' and (cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID ='9997' or cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID ='9998')" />
            <xsl:with-param name="isError" select ="true()"/>
        </xsl:call-template>
		-->
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName Si existe el tag, el valor ingresado es diferente a 'Codigo de tributos' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName Si existe el tag, el valor ingresado es diferente a 'PE:SUNAT' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI Si existe el tag, el valor ingresado es diferente a 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05' -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>

        <!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name No existe el Tag UBL o es vacío
        ERROR 2054 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2054'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:Name Si el tag es diferente al nombre del tributo del listado según el codigo del tributo. (catalogo 5)
        ERROR 2964 -->
		<xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'name'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
			<xsl:with-param name="errorCodeValidate" select="'2964'"/>       
      <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode No existe el Tag UBL o es vacío
        ERROR 2052 -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2052'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode Si el tag es diferente al codigo internacional del tributo del listado según el codigo del tributo. (catalogo 5)
        ERROR 2961 -->
		<xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
			<xsl:with-param name="errorCodeValidate" select="'2961'"/>
		</xsl:call-template>

    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:TaxTotal/cac:TaxSubtotal mode=cabecera
	===========================================================================================================================================
	--> 
	
	
	<!-- 
	===========================================================================================================================================
	Ini Template cac:DebitNoteLine
	===========================================================================================================================================
	--> 
	
	<xsl:template match="cac:DebitNoteLine">
    
        <xsl:param name="root"/>
        <xsl:variable name="nroLinea" select="cbc:ID"/>
        <!--<xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>-->
		<xsl:variable name="codigoProducto" select="$root/cac:PaymentTerms/cbc:PaymentMeansID"/>
        <xsl:variable name="codigoPrecio" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode"/>
        
		
        <!-- /DebitNote/cac:DebitNoteLine/cbc:ID El formato del Tag UBL es diferente de numérico de hasta 3 dígitos; o, es igual cero.
		ERROR 2137 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2137'"/>
            <xsl:with-param name="errorCodeValidate" select="'2137'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(?!0*$)\d{1,3}$'"/> <!-- de tres numeros como maximo, no cero -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:DebitNoteLine/cbc:ID El valor del Tag UBL no debe repetirse en el /DebitNote
		ERROR 2752 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-debitNoteLine-id', number(cbc:ID))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:DebitNoteLine/cbc:DebitedQuantity@unitCode NSi el Tag UBL existe, no existe el atributo del Tag UBL
		ERROR 2138 -->
        <xsl:if test="cbc:DebitedQuantity">
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2188'"/>
                <xsl:with-param name="node" select="cbc:DebitedQuantity/@unitCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
        </xsl:if>
        
		<!-- /DebitNote/cac:DebitNoteLine/cbc:DebitedQuantity@unitCodeListID Si existe el tag, el valor ingresado es diferente a 'UN/ECE rec 20'
		ERROR 4258 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4258'"/>
			<xsl:with-param name="node" select="cbc:DebitedQuantity/@unitCodeListID"/>
			<xsl:with-param name="regexp" select="'^(UN/ECE rec 20)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:DebitNoteLine/cbc:DebitedQuantity@unitCodeListAgencyName Si existe el tag, el valor ingresado es diferente a 'United Nations Economic Commission for Europe'
		ERROR 4259 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4259'"/>
			<xsl:with-param name="node" select="cbc:DebitedQuantity/@unitCodeListAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>

        <!-- /DebitNote/cac:DebitNoteLine/cbc:DebitedQuantity No existe el Tag UBL
		ERROR 2580 -->
		<!-- /DebitNote/cac:DebitNoteLine/cbc:DebitedQuantity Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 10 decimales
		ERROR 2139 -->
        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2580'"/>
            <xsl:with-param name="errorCodeValidate" select="'2139'"/>
            <xsl:with-param name="node" select="cbc:DebitedQuantity"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
		<!-- /DebitNote/cac:DebitNoteLine/cac:Item/cac:SellersItemIdentification/cbc:ID Si el tag UBL existe,  el formato del Tag UBL es diferente a alfanumérico de 1 hasta 50 caracteres (se considera cualquier carácter excepto salto de línea)
		OBSERVACION 4234 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4234'"/>
            <xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID"/>
            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{1,50})$'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- /DebitNote/cac:DebitNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode Si el tag UBL existe y el código de tipo de nota de Debito es 10, el valor del Tag UBL es vacío
		ERROR 3001 -->
		<!-- /DebitNote/cac:DebitNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode Si el tag UBL existe y el código de tipo de nota de Debito es 10, el valor del Tag UBL no se encuentra en el listado
		ERROR 3002 -->
        <xsl:if test="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '11'">
        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3001'"/>
                <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
			
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3002'"/>
				<xsl:with-param name="idCatalogo" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
				<xsl:with-param name="catalogo" select="'25'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
        </xsl:if>
 
		<!-- /DebitNote/cac:DebitNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode@listID Si existe el tag, el valor ingresado es diferente a 'UNSPSC'
		ERROR 4254 -->
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(UNSPSC)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:DebitNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode@listAgencyName Si existe el tag, el valor ingresado es diferente a 'GS1 US'
		ERROR 4251 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(GS1 US)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:DebitNoteLine/cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode@listName Si existe el tag, el valor ingresado es diferente a 'Item Classification'
		ERROR 4252 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCodey/@listName"/>
			<xsl:with-param name="regexp" select="'^(Item Classification)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:choose>
            <xsl:when test="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID = 'GTIN-8'">
                <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'3201'"/>
		            <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{8})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Formato ', cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID )"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID = 'GTIN-13'">
                <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'3201'"/>
		            <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{13})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Formato ', cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID )"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID = 'GTIN-14'">
                <xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'3201'"/>
		            <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{14})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Formato ', cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID )"/>
		        </xsl:call-template>
            </xsl:when>            
        </xsl:choose>
		
		<!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3195 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3195'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
            <xsl:with-param name="expresion" select="not(cac:TaxTotal)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ID">
			<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3199'"/>
                <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
		</xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3200'"/>
			<xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID"/>
			<xsl:with-param name="regexp" select="'^(GTIN-8|GTIN-13|GTIN-14)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!-- /DebitNote/cac:DebitNoteLine/cac:Item/cbc:Description Si el tag UBL existe,  el formato del Tag UBL es diferente a alfanumérico de 3 hasta 500 caracteres (se considera cualquier carácter excepto salto de línea)
		ERROR 4084 -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4084'"/>
			<xsl:with-param name="node" select="cac:Item/cbc:Description"/>
			<xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{3,500})$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
        <!-- /DebitNote/cac:DebitNoteLine/cac:Price/cbc:PriceAmount Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 10 decimales
		ERROR 4254 -->
        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2369'"/>
            <xsl:with-param name="errorCodeValidate" select="'2369'"/>
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
		<!-- /DebitNote/cac:DebitNoteLine/cac:Price/cbc:PriceAmount Si "Código de tipo de precio" es 02 (Gratuitas), el valor del Tag UBL es mayor a 0 (cero)
		ERROR 2640 -->
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2640'" />
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount" />
            <xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and cac:Price/cbc:PriceAmount &gt; 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
	    </xsl:call-template>
		

        <xsl:for-each select="cac:PricingReference/cac:AlternativeConditionPrice">
        	
        	<!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount No existe el Tag UBL
	        ERROR 2028 -->
	        <!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 10 decimales 
	        ERROR 2367    
	        <xsl:call-template name="existAndValidateValueTenDecimal">
	            <xsl:with-param name="errorCodeNotExist" select="'2028'"/>
	            <xsl:with-param name="errorCodeValidate" select="'2367'"/>
	            <xsl:with-param name="node" select="cbc:PriceAmount"/>
	            <xsl:with-param name="isGreaterCero" select="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template> -->	    

        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2410'"/>
                <xsl:with-param name="node" select="cbc:PriceTypeCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
            
            <xsl:call-template name="findElementInCatalog">
                <xsl:with-param name="catalogo" select="'16'"/>
                <xsl:with-param name="idCatalogo" select="cbc:PriceTypeCode"/>
                <xsl:with-param name="errorCodeValidate" select="'2410'"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
            <!--
           	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2409'" />
	            <xsl:with-param name="node" select="cbc:PriceTypeCode" />
	            <xsl:with-param name="expresion" select="count(cbc:PriceTypeCode) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
	        </xsl:call-template>-->
            
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4252'"/>
				<xsl:with-param name="node" select="cbc:PriceTypeCode/@listName"/>
				<xsl:with-param name="regexp" select="'^(Tipo de Precio)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4251'"/>
				<xsl:with-param name="node" select="cbc:PriceTypeCode/@listAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4253'"/>
				<xsl:with-param name="node" select="cbc:PriceTypeCode/@listURI"/>
				<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo16)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
            
        </xsl:for-each>
    
     <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2409'" />
            <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode" />
            <xsl:with-param name="expresion" select="count(cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>

		<!-- /DebitNote/cac:DebitNoteLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount Si 
		Si "Afectación al IGV por línea" es 10 (Gravado), 20 (Exonerado) o 30 (Inafecto) y "Código de precio" es 02 (Valor referencial en operaciones no onerosa), el Tag UBL es mayor a 0 (cero)
		ERROR 2425 -->
		<!-- Valor referencial unitario por ítem en operaciones no onerosas -->
		<!-- <xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'2425'" />
			<xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode" />
			<xsl:with-param name="expresion" select="$codigoPrecio='02' and cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount > 0 and cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '20' or text() = '30']" />
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template> 
		-->
		
		<!-- Si el Tag UBL existe, el formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3021'"/>
            <xsl:with-param name="errorCodeValidate" select="'3021'"/>
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:variable name="totalImpuestosxLinea" select="cac:TaxTotal/cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestosxLinea" select="sum(cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount)"/>
        
		<!-- Si el Tag UBL existe, el monto total de impuestos por línea es diferente a la sumatoria de impuestos por línea 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3022'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalImpuestosxLinea + 1 ) &lt; $SumatoriaImpuestosxLinea or ($totalImpuestosxLinea - 1) &gt; $SumatoriaImpuestosxLinea" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		-->
        <!-- El tag /DebitNoteLine/cac:TaxTotal no debe repetirse en el /DebitNoteLine -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3026'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
		<!-- Tributos por linea de detalle -->
        <xsl:apply-templates select="cac:TaxTotal" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="root" select="$root"/>
            <xsl:with-param name="valorVenta" select="cbc:LineExtensionAmount"/>
        </xsl:apply-templates>      
		
		<!-- Tributos por linea de detalle -->
        <xsl:apply-templates select="cac:Allowancecharge" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
            <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>

		<!-- Validaciones de sumatoria -->
        <xsl:variable name="ValorVentaxItem" select="cbc:LineExtensionAmount"/>
        <xsl:variable name="ValorVentaUnitarioxItem" select="cac:Price/cbc:PriceAmount"/>
        <xsl:variable name="ImpuestosItem" select="cac:TaxTotal/cbc:TaxAmount"/>
        <xsl:variable name="DsctosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '01']/cbc:Amount)"/>
        <xsl:variable name="DsctosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '00']/cbc:Amount)"/>
        <xsl:variable name="CargosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '48']/cbc:Amount)"/>
        <xsl:variable name="CargosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '47']/cbc:Amount)"/>
        <xsl:variable name="CantidadItem" select="cbc:DebitedQuantity"/>
       	<xsl:variable name="PrecioUnitarioxItem" select="sum(cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '01']/cbc:PriceAmount)"/>
       	<xsl:variable name="PrecioReferencialUnitarioxItem" select="sum(cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '02']/cbc:PriceAmount)"/>
        
        <xsl:variable name="PrecioUnitarioCalculado" select="($ValorVentaxItem + $ImpuestosItem - $DsctosNoAfectanBI + $CargosNoAfectanBI) div ( $CantidadItem)"/>
        <xsl:variable name="ValorVentaReferencialxItemCalculado" select="($PrecioReferencialUnitarioxItem * $CantidadItem) - $DsctosAfectanBI + $CargosAfectanBI"/>
        <xsl:variable name="ValorVentaxItemCalculado" select="($ValorVentaUnitarioxItem * $CantidadItem) - $DsctosAfectanBI + $CargosAfectanBI"/> 
		
		<!-- 4287 - Precio Unitario x Item = Dividir (suma del valor de venta + impuestos x item - descuentos No afectan a BI + Cargos no afectan a BI ) con la cantida  -->
        <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'4287'"/>
             <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '01']/cbc:PriceAmount" />
             <xsl:with-param name="expresion" select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0) and ($PrecioUnitarioxItem + 1 ) &lt; $PrecioUnitarioCalculado or ($PrecioUnitarioxItem - 1) &gt; $PrecioUnitarioCalculado" />
             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
             <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        <!-- FIN Validacion 4287 -->
				
		  <!-- 4288 - Valor de Venta x Item = Dividir (suma del valor de venta + impuestos x item - descuentos No afectan a BI + Cargos no afectan a BI ) con la cantida -->  
        <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'4288'"/>
             <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
             <xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and (($ValorVentaxItem + 1 ) &lt; $ValorVentaReferencialxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaReferencialxItemCalculado)" />
             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
             <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
             <xsl:with-param name="errorCodeValidate" select="'4288'"/>
             <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
             <xsl:with-param name="expresion" select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0) and (($ValorVentaxItem + 1 ) &lt; $ValorVentaxItemCalculado or ($ValorVentaxItem - 1) &gt; $ValorVentaxItemCalculado)" />
             <!-- <xsl:with-param name="expresion" select="not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0)" />-->
             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
             <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        <!-- FIN Validacion 4288 -->
		
        
        <!-- /DebitNote/cac:DebitNoteLine/cbc:LineExtensionAmount El formato del Tag UBL es diferente de decimal positivo de 12 enteros y hasta 2 decimales
		ERROR 2370 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2370'"/>
            <xsl:with-param name="errorCodeValidate" select="'2370'"/>
            <xsl:with-param name="node" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
		
		
        
        <!--<xsl:if test="$tipoOperacion='0102'">
 
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2501'" />
                <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
                <xsl:with-param name="expresion" select="cbc:LineExtensionAmount &lt;= 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>                
       
        </xsl:if>-->
        
        
        
		<xsl:variable name="codigoSUNAT" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
		<xsl:variable name="indPrimeraVivienda" select="cac:Item/cac:AdditionalItemProperty[cbc:NameCode[text() = '7002']]/cbc:Value"/>
		
		<xsl:if test="$codigoSUNAT = '84121901'">
        	
			<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3150'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7001'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7001')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3151'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7003']) and $indPrimeraVivienda = '3'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7003')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3152'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7004'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7004')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3153'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7005'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7005')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3154'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7006']) and $indPrimeraVivienda = '3'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7006')"/>
            </xsl:call-template>
			            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3155'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '7007']) and $indPrimeraVivienda = '3'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 7007')"/>
            </xsl:call-template>
            
        </xsl:if>
		
		
		<xsl:apply-templates select="cac:Item/cac:AdditionalItemProperty" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>

		
        
    </xsl:template>
	
	<!-- 
	===========================================================================================================================================
	Fin Template cac:DebitNoteLine
	===========================================================================================================================================
	--> 
	
	
	<!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:TaxTotal/cac:TaxSubtotal =========================================== 
    
    ===========================================================================================================================================
    -->        
    <xsl:template match="cac:TaxSubtotal" mode="linea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="root"/>
        
        <xsl:variable name="tipoNotaDebito" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode"/>
        <xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
        <xsl:variable name="MontoTributoCalculado" select="cbc:TaxableAmount * cac:TaxCategory/cbc:Percent * 0.01"/>
        <xsl:variable name="MontoTributo" select="cbc:TaxAmount"/>
        <xsl:variable name="valorVentaLinea" select="$root/cac:DebitNoteLine[cbc:ID[text() = $nroLinea]]/cbc:LineExtensionAmount"/>
        
        
        <xsl:variable name="codTributo">
            <xsl:choose>
                <xsl:when test="$codigoTributo = '1000'">
                    <xsl:value-of select="'igv'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '1016'">
                    <xsl:value-of select="'iva'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9995'">
                    <xsl:value-of select="'exp'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9996'">
                    <xsl:value-of select="'gra'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9997'">
                    <xsl:value-of select="'exo'"/>
                </xsl:when>
                <xsl:when test="$codigoTributo = '9998'">
                    <xsl:value-of select="'ina'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="''"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   3031 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3031'"/>
            <xsl:with-param name="errorCodeValidate" select="'3031'"/>
            <xsl:with-param name="node" select="cbc:TaxableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
		
		<!--2643 Si 'Código de tributo por línea' es 1016 (IVAP), 'Código de tipo de nota de débito' es 12 (IVAP), el valor del Tag UBL es igual a 0 (cero)-->
		<xsl:if test="$codigoTributo = '1016'">
	    	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2643'" />
	            <xsl:with-param name="node" select="cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode = '12' and cac:TaxCategory/cac:TaxScheme/cbc:ID[text()='1016'] and cbc:TaxAmount = 0" />
	        	<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	    	</xsl:call-template>
	    </xsl:if>		
		
        
        <!-- 3222 Tag ubl > 0 and no exista un TaxableAmount  del mismo tributo > 0  -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3222'" />
            <xsl:with-param name="node" select="cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and not($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = $codigoTributo and cbc:TaxableAmount &gt; 0])" />
            <!-- <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and ($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = $codigoTributo]/cbc:TaxableAmount &gt; 0)" />-->
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   2033 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2033'"/>
            <xsl:with-param name="errorCodeValidate" select="'2033'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        
        
        <xsl:if test="$codigoTributo = '9995' or $codigoTributo = '9997' or $codigoTributo = '9998'">
	    	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3110'" />
	            <xsl:with-param name="node" select="cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="cbc:TaxAmount != 0" />
	        	<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	    	</xsl:call-template>
	    </xsl:if>
	            
	    <xsl:if test="$codigoTributo = '9996'">
	        <xsl:call-template name="isTrueExpresion">
	             <xsl:with-param name="errorCodeValidate" select="'3111'" />
	             <xsl:with-param name="node" select="cbc:TaxAmount" />
	             <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text() = '15' or text() = '16' or text() = '17'] and cbc:TaxAmount = 0" />
	             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="isTrueExpresion">
	             <xsl:with-param name="errorCodeValidate" select="'3110'" />
	             <xsl:with-param name="node" select="cbc:TaxAmount" />
	             <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '21' or text() = '31' or text() = '32' or text() = '33' or text() = '34' or text() = '35' or text() = '36' or text() = '37' or text() = '40'] and cbc:TaxAmount != 0" />
	             <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$codigoTributo = '1000' or $codigoTributo = '1016'">
	    	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3111'" />
	            <xsl:with-param name="node" select="cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cbc:TaxAmount = 0" />
	        	<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	    	</xsl:call-template>
	    </xsl:if>
	            
	    <xsl:call-template name="existElement">
		    <xsl:with-param name="errorCodeNotExist" select="'2992'"/>
		    <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
		    <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
	    
	    <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3102'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent"/>
			<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:if test="$codigoTributo = '9996'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2993'" />
	            <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '11' or text() = '12' or text() = '13' or text() = '14' or text = '15' or text() = '16' or text() = '17'] and cac:TaxCategory/cbc:Percent = 0" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$codigoTributo = '2000'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3104'" />
	            <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:Percent = 0" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$codigoTributo = '1000' or $codigoTributo = '1016'">
	    	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2993'" />
	            <xsl:with-param name="node" select="cac:TaxCategory/cbc:Percent" />
	            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:Percent = 0" />
	        	<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	    	</xsl:call-template>
	    </xsl:if>
        
        <xsl:if test="$codigoTributo = '2000'">
	    	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3108'" />
                <xsl:with-param name="node" select="cbc:TaxAmount" />
                <xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoTributoCalculado or ($MontoTributo - 1) &gt; $MontoTributoCalculado" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
	    </xsl:if>
	    
	    <xsl:if test="$codigoTributo = '9999'">
	    	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3109'" />
                <xsl:with-param name="node" select="cbc:TaxAmount" />
                <xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoTributoCalculado or ($MontoTributo - 1) &gt; $MontoTributoCalculado" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
	    </xsl:if>
	    
	    <xsl:if test="cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '11' or text() = '12' or text() = '13' or text() = '14' or text = '15' or text() = '16' or text() = '17']">
	    	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3103'" />
                <xsl:with-param name="node" select="cbc:TaxAmount" />
                <xsl:with-param name="expresion" select="($MontoTributo + 1 ) &lt; $MontoTributoCalculado or ($MontoTributo - 1) &gt; $MontoTributoCalculado" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
	    </xsl:if>
	    
        <xsl:if test="$codigoTributo != '2000' and $codigoTributo != '9999' ">
        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2371'"/>
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
            
            <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
	        ERROR 2378 -->
	        <xsl:call-template name="findElementInCatalogProperty">
				<xsl:with-param name="catalogo" select="'07'"/>
				<xsl:with-param name="propiedad" select="$codTributo"/>
				<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
				<xsl:with-param name="valorPropiedad" select="'1'"/>
				<xsl:with-param name="errorCodeValidate" select="'2040'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$codigoTributo = '2000' or $codigoTributo = '9999'">        
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3050'" />
	            <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
	            <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
	        	<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	    	</xsl:call-template>
        </xsl:if>
        
        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoNotaDebito='11'">
        
            <!-- Si "Código de tributo por línea" es 1000 (IGV) y "Tipo de operación" es 02 (Exportación), el valor del Tag UBL es diferente a 40 (Exportación) 
            ERROR 2642 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2642'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode" />
                <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and cac:TaxCategory/cbc:TaxExemptionReasonCode != '40'" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>  
        
        </xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Afectacion del IGV)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo07)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:if test="$codigoTributo = '2000'">
			<xsl:call-template name="existElement">
               <xsl:with-param name="errorCodeNotExist" select="'2373'"/>
               <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange"/>
               <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
           </xsl:call-template>
           
          	<xsl:call-template name="findElementInCatalog">
	            <xsl:with-param name="catalogo" select="'08'"/>
	            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TierRange"/>
	            <xsl:with-param name="errorCodeValidate" select="'2041'"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$codigoTributo != '2000'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3210'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TierRange" />
                <xsl:with-param name="expresion" select="cac:TaxCategory/cbc:TierRange" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2037'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        
        <!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2036 -->	
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'2036'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
		
        <!-- cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el cac:InvoiceLine ERROR 2355 -->
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3067'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-line', concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', $nroLinea))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2038 y 2996-->	
        <xsl:choose>
			<xsl:when test="$codigoTributo = '2000' or $codigoTributo = '9999'">	
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'2038'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'2996'"/>
					<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

        <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2378 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'name'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
			<xsl:with-param name="errorCodeValidate" select="'3051'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>
		
		<!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2378 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
			<xsl:with-param name="errorCodeValidate" select="'2377'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
		</xsl:call-template>        
       
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:TaxTotal/cac:TaxSubtotal =========================================== 
    
    ===========================================================================================================================================
    -->    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:TaxTotal =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:TaxTotal" mode="linea">
        <xsl:param name="nroLinea"/>
        <xsl:param name="root"/>
        <xsl:param name="valorVenta"/>
        
        <xsl:variable name="tipoNotaDebito" select="$root/cac:DiscrepancyResponse/cbc:ResponseCode"/>
		
        <!-- cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cbc:TaxAmount No existe el Tag UBL o es diferente al Tag anterior 
        ERROR 2372 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2372'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="number(cac:TaxSubtotal/cbc:TaxAmount) != number(cbc:TaxAmount)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        -->
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   2033 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3021'"/>
            <xsl:with-param name="errorCodeValidate" select="'3021'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Tributos duplicados por linea -->
        <xsl:apply-templates select="cac:TaxSubtotal" mode="linea">
           <xsl:with-param name="nroLinea" select="$nroLinea"/>
           <xsl:with-param name="root" select="$root"/>
        </xsl:apply-templates>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2644'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory[cbc:TaxExemptionReasonCode!='17']/cbc:TaxExemptionReasonCode" />
            <xsl:with-param name="expresion" select="cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode='17']/cbc:TaxableAmount &gt; 0 and cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode!='17' and cac:TaxCategory/cac:TaxScheme/cbc:ID[text() != '2000' or text()= '9999']]/cbc:TaxableAmount &gt; 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>  


		<xsl:if test="$tipoNotaDebito = '12'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000' ]) &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>  
        </xsl:if>

        
        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoNotaDebito='11'">
            <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
            ERROR 3100 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '2000' or text() = '1016' or text() = '9997' or text() = '9998' or text() = '9999']) &gt; 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>  
        
        </xsl:if>
                
        <xsl:variable name="totalImpuestosxLinea" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestosxLinea" select="sum(cac:TaxSubtotal/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4293'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalImpuestosxLinea + 1 ) &lt; $SumatoriaImpuestosxLinea or ($totalImpuestosxLinea - 1) &gt; $SumatoriaImpuestosxLinea" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:variable name="TributoISCxLinea">		
            <xsl:choose>
                <xsl:when test="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount">
                    <xsl:value-of select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000']/cbc:TaxAmount"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'0'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="BaseIGVIVAPxLinea" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016']]/cbc:TaxableAmount"/>
        <xsl:variable name="BaseIGVIVAPxLineaCalculado" select="$valorVenta + $TributoISCxLinea"/>
        
        
        <xsl:if test="$BaseIGVIVAPxLinea">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4294'" />
	            <xsl:with-param name="node" select="$BaseIGVIVAPxLinea" />
	            <xsl:with-param name="expresion" select="($BaseIGVIVAPxLinea + 1 ) &lt; $BaseIGVIVAPxLineaCalculado or ($BaseIGVIVAPxLinea - 1) &gt; $BaseIGVIVAPxLineaCalculado" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
        
        <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
        ERROR 3105 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3105'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9995' or text() = '9996' or text() = '9997' or text() = '9998']) &lt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
       <xsl:if test="count(cac:TaxSubtotal) &gt; 1">
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3223'" />
	            <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
	            <xsl:with-param name="expresion" select="not((cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'] and count(cac:TaxSubtotal) = 2) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 2) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1000'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 3) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '1016'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 2) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9995'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 2) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'] and count(cac:TaxSubtotal) = 2) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 3) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9996'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 2) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9997'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'] and count(cac:TaxSubtotal) = 2) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9997'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 3) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9997'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 2) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9998'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'] and count(cac:TaxSubtotal) = 2)or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9998'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '2000'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 3) or
									  (cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9998'] and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = '9999'] and count(cac:TaxSubtotal) = 2))" />
	        </xsl:call-template>
        </xsl:if>        
        
    </xsl:template>

    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:TaxTotal =========================================== 
    
    ===========================================================================================================================================
    -->
	
	
	
	<!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:Item/cac:AdditionalItemProperty =========================================== 
    
    ===========================================================================================================================================
    -->

	
	
	<xsl:template match="cac:Item/cac:AdditionalItemProperty" mode="linea">
        <xsl:param name="nroLinea"/>
        		
		<xsl:variable name="codigoConcepto" select="cbc:NameCode"/>
		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'4235'"/>
            <xsl:with-param name="node" select="cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'55'"/>
            <xsl:with-param name="idCatalogo" select="cbc:NameCode"/>
            <xsl:with-param name="errorCodeValidate" select="'4279'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
		<xsl:choose>
					
            <xsl:when test="$codigoConcepto = '7001'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'26'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7002'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'27'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7003'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,49}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7004'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,49}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7005'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){0,49})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7006'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7007'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
			
        </xsl:choose>
        
    </xsl:template>

    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Item/cac:AdditionalItemProperty =========================================== 
    
    ===========================================================================================================================================
    -->
    
	
	
    

</xsl:stylesheet>
