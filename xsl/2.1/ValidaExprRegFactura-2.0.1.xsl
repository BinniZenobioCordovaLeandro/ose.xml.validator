<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:regexp="http://exslt.org/regular-expressions"
    xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" 
    xmlns:ds="http://www.w3.org/2000/09/xmldsig#" 
    xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" 
    xmlns:sac="urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1"
    xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" 
    xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" 
    xmlns:dp="http://www.datapower.com/extensions" 
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">
    
	<xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" />
    
    <!-- key Documentos Relacionados Duplicados -->
    <xsl:key name="by-document-despatch-reference" match="*[local-name()='Invoice']/cac:DespatchDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>
    
    <xsl:key name="by-document-additional-reference" match="*[local-name()='Invoice']/cac:AdditionalDocumentReference" use="concat(cbc:DocumentTypeCode,' ', cbc:ID)"/>
    
    <!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-invoiceLine-id" match="*[local-name()='Invoice']/cac:InvoiceLine" use="number(cbc:ID)"/>
    
    <!-- key tributos duplicados por linea -->
    <xsl:key name="by-tributos-in-line" match="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal" use="concat(cac:TaxCategory/cac:TaxScheme/cbc:ID,'-', ../../cbc:ID)"/>
    
    <!-- key tributos duplicados por cabecera -->
    <xsl:key name="by-tributos-in-root" match="*[local-name()='Invoice']/cac:TaxTotal/cac:TaxSubtotal" use="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
    
    <!-- key AdditionalMonetaryTotal duplicados -->
    <xsl:key name="by-AdditionalMonetaryTotal" match="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal" use="cbc:ID"/>
    
    <!-- key identificador de prepago duplicados -->
    <xsl:key name="by-idprepaid-in-root" match="*[local-name()='Invoice']/cac:PrepaidPayment" use="cbc:ID"/>
    
    <xsl:key name="by-document-additional-anticipo" match="*[local-name()='Invoice']/cac:AdditionalDocumentReference[cbc:DocumentTypeCode[text() = '02' or text() = '03']]" use="cbc:DocumentStatusCode"/>
        
    
    <xsl:template match="/*">
    
        <!-- 
        ===========================================================================================================================================
        Variables  
        ===========================================================================================================================================
        -->
	
		
		<!-- Validando que el nombre del archivo coincida con la informacion enviada en el XML -->
        
        <xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
        
        <xsl:variable name="tipoComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 13, 2)"/>
        
        <xsl:variable name="numeroSerie" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)"/>
        
        <xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/>
                
       
        
        <!-- Esta validacion se hace de manera general -->
        <!-- Numero de RUC del nombre del archivo no coincide con el consignado en el contenido del archivo XML
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1034'" />
            <xsl:with-param name="node" select="cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroRuc != cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID" />
        </xsl:call-template>
        -->
        
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
        
        <!-- Variables -->
        <xsl:variable name="cbcUBLVersionID" select="cbc:UBLVersionID"/>

        <xsl:variable name="cbcCustomizationID" select="cbc:CustomizationID"/>
        
        <xsl:variable name="monedaComprobante" select="cbc:DocumentCurrencyCode/text()"/>
        
        <xsl:variable name="codigoProducto" select="cac:PaymentTerms/cbc:PaymentMeansID"/>
        
        <xsl:variable name="tipoOperacion" select="cbc:InvoiceTypeCode/@listID"/>
        
        <!-- 
        ===========================================================================================================================================
        Variables  
        ===========================================================================================================================================
        -->
    
    
        <!-- 
        ===========================================================================================================================================
        
        Datos de la Factura Electronica  
        
        ===========================================================================================================================================
        -->
        <!-- cbc:UBLVersionID No existe el Tag UBL ERROR 2075 -->
        <!--  El valor del Tag UBL es diferente de "2.0" ERROR 2074 
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2075'"/>
            <xsl:with-param name="errorCodeValidate" select="'2074'"/>
            <xsl:with-param name="node" select="$cbcUBLVersionID"/>
            <xsl:with-param name="regexp" select="'^(2.1)$'"/>
        </xsl:call-template>
        -->
        
        <!-- cbc:CustomizationID No existe el Tag UBL ERROR 2073 -->
        <!--  Vigente hasta el 01/01/2018   -->
        <!--  El valor del Tag UBL es diferente de "1.0" ERROR 2072 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2073'"/>
            <xsl:with-param name="errorCodeValidate" select="'2072'"/>
            <xsl:with-param name="node" select="$cbcCustomizationID"/>
            <xsl:with-param name="regexp" select="'^(2.0)$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="$cbcCustomizationID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
                
        <!-- Numeracion, conformada por serie y numero correlativo -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'1001'"/>
			<xsl:with-param name="node" select="cbc:ID"/>
			<xsl:with-param name="regexp" select="'^[F][A-Z0-9]{3}-[0-9]{1,8}?$'"/>
		</xsl:call-template>
		
        <!-- ================================== Verificar con el flujo o con Java ============================================================= -->
        <!-- cbc:ID El número de serie del Tag UBL es diferente al número de serie del archivo ERROR 1035 -->
        <!--  El número de comprobante del Tag UBL es diferente al número de comprobante del archivo ERROR 1036 -->
        <!--  El valor del Tag UBL se encuentra en el listado con indicador de estado igual a 0 o 1 ERROR 1033 -->
        <!--  El valor del Tag UBL se encuentra en el listado con indicador de estado igual a 2 ERROR 1032 -->
        
        <!-- cbc:IssueDate La diferencia entre la fecha de recepción del XML y el valor del Tag UBL es mayor al límite del listado ERROR 2108 -->
        <!--  El valor del Tag UBL es mayor a dos días de la fecha de envío del comprobante ERROR 2329 -->
        
        <!-- cbc:InvoiceTypeCode No existe el Tag UBL ERROR 1004 (Verificar que el error ocurra)-->
        <!--  El valor del Tag UBL es diferente al tipo de documento del archivo ERROR 1003 -->
        
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1004'"/>
            <xsl:with-param name="errorCodeValidate" select="'1003'"/>
            <xsl:with-param name="node" select="cbc:InvoiceTypeCode"/>
            <xsl:with-param name="regexp" select="'^01$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <!-- ================================================================================================================================ -->
        
        <!-- cbc:DocumentCurrencyCode No existe el Tag UBL ERROR 2070 -->
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2070'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode"/>
		</xsl:call-template>
		
	
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'3088'"/>
			<xsl:with-param name="idCatalogo" select="cbc:DocumentCurrencyCode"/>
			<xsl:with-param name="catalogo" select="'02'"/>
		</xsl:call-template>
		
		<!--  La moneda de los totales de línea y totales de comprobantes (excepto para los totales de Percepción (2001) y Detracción (2003)) es diferente al valor del Tag UBL ERROR 2071 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2071'" />
            <xsl:with-param name="node" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not(ancestor-or-self::cac:PaymentTerms/cbc:Amount) and not(ancestor-or-self::cac:DeliveryTerms/cbc:Amount) and not(ancestor-or-self::cbc:DeclaredForCarriageValueAmount)]/@currencyID" />
            <xsl:with-param name="expresion" select="descendant::*[@currencyID != $monedaComprobante and not(ancestor-or-self::cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '51' or cbc:AllowanceChargeReasonCode = '52' or cbc:AllowanceChargeReasonCode = '53']) and not (ancestor-or-self::cac:PaymentTerms/cbc:Amount) and not(ancestor-or-self::cac:DeliveryTerms/cbc:Amount) and not(ancestor-or-self::cbc:DeclaredForCarriageValueAmount)]" />
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 4217 Alpha)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Currency)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentCurrencyCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
				
        <!-- 
        ===========================================================================================================================================
        
        Fin Datos de la Factura electronica  
        
        ===========================================================================================================================================
        -->
        
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del Emisor
        
        ===========================================================================================================================================
        -->
        
                    
        <xsl:apply-templates select="cac:AccountingSupplierParty">
        	<xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
	    </xsl:apply-templates>
        
        <xsl:apply-templates select="cac:Delivery/cac:DeliveryLocation/cac:Address">
	            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
	    </xsl:apply-templates>
        
         
        <!-- 
        ===========================================================================================================================================
        
        Fin Datos del Emisor
        
        ===========================================================================================================================================
        --> 
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del cliente o receptor
        
        ===========================================================================================================================================
        -->
        
        <xsl:apply-templates select="cac:AccountingCustomerParty">
            <xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
        </xsl:apply-templates>
        
        <!-- 
        ===========================================================================================================================================
        
        fin Datos del cliente o receptor
        
        ===========================================================================================================================================
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Documentos de referencia
        
        ===========================================================================================================================================
        -->
        
        <xsl:apply-templates select="cac:DespatchDocumentReference"/>
        
        <xsl:apply-templates select="cac:AdditionalDocumentReference"/>
        
        <!-- 
        ===========================================================================================================================================
        
        Documentos de referencia
        
        ===========================================================================================================================================
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del detalle o Ítem de la Factura
        
        ===========================================================================================================================================
        -->
        
        <!--  cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode 
        Si "Código de tributo por línea" es 1000 (IGV) y el valor del Tag UBL es "40" (Exportación), no debe haber otro "Afectación a IGV por la línea" diferente a "40" 
        ERROR 2655
        
        <xsl:variable name="afectacionIgvExportacion" select="count(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID='1000']/cbc:TaxExemptionReasonCode[text() = '40'])"/>
        <xsl:variable name="afectacionIgvNoExportacion" select="count(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID='1000']/cbc:TaxExemptionReasonCode[text() != '40'])"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2655'" />
            <xsl:with-param name="node" select="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory[cac:TaxScheme/cbc:ID='1000']/cbc:TaxExemptionReasonCode" />
            <xsl:with-param name="expresion" select="($afectacionIgvExportacion > 0) and ($afectacionIgvNoExportacion > 0)" />
        </xsl:call-template>
         -->
         
        <xsl:apply-templates select="cac:InvoiceLine">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        
        <!-- 
        ===========================================================================================================================================
        
        Datos del detalle o Ítem de la Factura
        
        ===========================================================================================================================================
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Totales de la Factura
        
        ===========================================================================================================================================
        -->
        
        
        <!-- ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation El Tag UBL no debe repetirse en el /Invoice 
        ERROR 2427 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2427'" />
            <xsl:with-param name="node" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation" />
            <xsl:with-param name="expresion" select="count(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation) &gt; 1" />
        </xsl:call-template>
        -->
        
        <!-- ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID 
        El valor del Tag UBL debe tener por lo menos uno de los siguientes valores en el /Invoice: 1001 (Gravada), 1002 (Inafecta), 1003 (Exonerada), 1004 (Gratuita) o 3001 (FISE) 
        ERROR 2047 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2047'" />
            <xsl:with-param name="node" select="ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID" />
            <xsl:with-param name="expresion" select="not(ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalMonetaryTotal/cbc:ID[text()='1001' or text()='1002' or text()='1003' or text()='1004' or text()='3001'])" />
        </xsl:call-template>
        -->
        
        <!-- cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales 
        ERROR 2065 -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2065'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount"/>            
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <!-- cac:LegalMonetaryTotal/cbc:ChargeTotalAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales 
        ERROR 2064 -->
        <!-- cac:LegalMonetaryTotal/cbc:ChargeTotalAmount    
        El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales    ERROR    2064 -->
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2064'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <!-- cac:LegalMonetaryTotal/cbc:PayableAmount El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales 
        ERROR 2062 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2062'"/>
            <xsl:with-param name="errorCodeValidate" select="'2062'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2031'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3019'"/>
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4314'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount &gt; 1 or cac:LegalMonetaryTotal/cbc:PayableRoundingAmount &lt; -1" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4315'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount/@currencyID" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PayableRoundingAmount/@currencyID != $monedaComprobante" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        <!-- Tributos duplicados por cabecera 
        <xsl:apply-templates select="cac:TaxTotal/cac:TaxSubtotal" mode="cabecera"/>
        -->
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3195 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2956'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
            <xsl:with-param name="expresion" select="not(cac:TaxTotal)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3024 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3024'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="count(cac:TaxTotal) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- Tributos de la cabecera-->
        <xsl:apply-templates select="cac:TaxTotal" mode="cabecera">
            <xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        
        <!-- Cargos y descuentos de la cabecera --> 
        <xsl:apply-templates select="cac:AllowanceCharge" mode="cabecera">
        	<xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
         
       <xsl:if test="$tipoOperacion ='2001'">
             <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3093'" />
                 <xsl:with-param name="node" select="cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text() = '52' or text() = '53']" />
                 <xsl:with-param name="expresion" select="not(cac:AllowanceCharge/cbc:AllowanceChargeReasonCode[text() ='51' or text()='52' or text()='53'])" />            
             </xsl:call-template>
        </xsl:if>
        
		<xsl:variable name="descuentosGlobalesNOAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '03']]/cbc:Amount)"/>
        <xsl:variable name="descuentosxLineaNOAfectaBI" select="sum(cac:InvoiceLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '01']]/cbc:Amount)"/>
       	<xsl:variable name="totalDescuentos" select="sum(cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount)"/>
       	<xsl:variable name="totalDescuentosCalculado" select="$descuentosGlobalesNOAfectaBI + $descuentosxLineaNOAfectaBI"/>
        <xsl:variable name="cargosxLineaNOAfectaBI" select="sum(cac:InvoiceLine/cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '48']]/cbc:Amount)"/>
        <xsl:variable name="cargosGlobalesNOAfectaBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '45' or text() = '46' or text() = '50' or text() = '51' or text() = '52' or text() = '53']]/cbc:Amount)"/>
       	<xsl:variable name="totalCargos" select="sum(cac:LegalMonetaryTotal/cbc:ChargeTotalAmount)"/>
       	<xsl:variable name="totalCargosCalculado" select="$cargosGlobalesNOAfectaBI + $cargosxLineaNOAfectaBI"/>
        <xsl:variable name="totalPrecioVenta" select="sum(cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount)"/>
        <xsl:variable name="totalAnticipo" select="sum(cac:LegalMonetaryTotal/cbc:PrepaidAmount)"/>
        <xsl:variable name="totalImporte" select="sum(cac:LegalMonetaryTotal/cbc:PayableAmount)"/>
        <xsl:variable name="totalRedondeo" select="sum(cac:LegalMonetaryTotal/cbc:PayableRoundingAmount)"/>
        <xsl:variable name="totalImporteCalculado" select="$totalPrecioVenta + $totalCargos - $totalDescuentos - $totalAnticipo + $totalRedondeo"/>
        <xsl:variable name="totalValorVenta" select="sum(cac:LegalMonetaryTotal/cbc:LineExtensionAmount)"/>
        <xsl:variable name="SumatoriaIGV" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount)"/>
        <xsl:variable name="SumatoriaIVAP" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxAmount)" />
        <xsl:variable name="SumatoriaISC" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
        <xsl:variable name="SumatoriaOtrosTributos" select="sum(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)" />
        <xsl:variable name="MontoBaseIGV" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount"/>
        <xsl:variable name="MontoBaseIVAP" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount"/>
        <xsl:variable name="MontoBaseIGVLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxableAmount)"/>
        <xsl:variable name="MontoBaseIVAPLinea" select="sum(cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxableAmount)"/>
        <xsl:variable name="MontoDescuentoAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '02']]/cbc:Amount)"/>
        <xsl:variable name="MontoDescuentoAfectoBIAnticipo" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '04']]/cbc:Amount)"/>
        <xsl:variable name="MontoCargosAfectoBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode[text() = '49']]/cbc:Amount)"/>
        <xsl:variable name="totalValorVentaxLinea" select="sum(cac:InvoiceLine[cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID [text() = '1000' or text() = '1016' or text() = '9995' or text() = '9997' or text() = '9998']]//cbc:LineExtensionAmount)"/>
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
            <xsl:with-param name="errorCodeValidate" select="'4307'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount" />
            <xsl:with-param name="expresion" select="($totalDescuentos + 1 ) &lt; $totalDescuentosCalculado or ($totalDescuentos - 1) &gt; $totalDescuentosCalculado" />
            <xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4308'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:ChargeTotalAmount" />
            <xsl:with-param name="expresion" select="($totalCargos + 1 ) &lt; $totalCargosCalculado or ($totalCargos - 1) &gt; $totalCargosCalculado" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4312'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:PayableAmount" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and (($totalImporte + 1 ) &lt; $totalImporteCalculado or ($totalImporte - 1) &gt; $totalImporteCalculado)" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4309'" />
            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:LineExtensionAmount" />
            <xsl:with-param name="expresion" select="($totalValorVenta + 1 ) &lt; $totalValorVentaCalculado or ($totalValorVenta - 1) &gt; $totalValorVentaCalculado" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        <!-- Detalle de sumatoria -->
        
        <xsl:if test="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000']]/cbc:TaxAmount &gt; 0">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4310'" />
	            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount" />
	            <xsl:with-param name="expresion" select="($totalPrecioVenta + 1 ) &lt; $totalPrecioVentaCalculadoIGV or ($totalPrecioVenta - 1) &gt; $totalPrecioVentaCalculadoIGV" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount and cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1016']]/cbc:TaxAmount &gt; 0">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4310'" />
	            <xsl:with-param name="node" select="cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount" />
	            <xsl:with-param name="expresion" select="($totalPrecioVenta + 1 ) &lt; $totalPrecioVentaCalculadoIVAP or ($totalPrecioVenta - 1) &gt; $totalPrecioVentaCalculadoIVAP" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
        </xsl:if>
        
        <!-- cac:TaxTotal/cbc:TaxAmount Si existe una línea con "Código de tributo por línea" igual a "2000" y "Monto ISC por línea" mayor a cero, el valor del Tag UBL es menor igual a 0 (cero) 
        OBSERV 4020 
        <xsl:variable name="detalleIscGreaterCero" select="cac:InvoiceLine/cac:TaxTotal[cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']/cbc:TaxAmount[text() &gt; 0] "/>
        <xsl:if test="$detalleIscGreaterCero">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4020'" />
                <xsl:with-param name="node" select="cac:TaxTotal/cbc:TaxAmount[../cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='2000']" />
                <xsl:with-param name="expresion" select="not(cac:TaxTotal/cbc:TaxAmount[../cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID='2000' and text() &gt; 0])" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
        </xsl:if>
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Fin Totales de la Factura
        
        ===========================================================================================================================================
        -->
        
        <!-- 
        ===========================================================================================================================================
        
        Información Adicional  - Anticipos
        
        ===========================================================================================================================================
        -->
        
        <xsl:apply-templates select="cac:PrepaidPayment" mode="cabecera">
        	<xsl:with-param name="root" select="."/>
        </xsl:apply-templates>
        
        <!-- /Invoice/cac:LegalMonetaryTotal/cbc:PrepaidAmount Si existe "Tipo de comprobante que se realizó el anticipo" igual a "02", la suma de "Monto anticipado" es diferente al valor del Tag UBL 
        ERROR 2509 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2509'" />
            <xsl:with-param name="node" select="cac:PrepaidPayment[cbc:ID/@schemeID='02']/cbc:PaidAmount" />
            <xsl:with-param name="expresion" select="cac:LegalMonetaryTotal/cbc:PrepaidAmount &gt; 0 and sum(cac:PrepaidPayment/cbc:PaidAmount) != number(cac:LegalMonetaryTotal/cbc:PrepaidAmount)" />
        </xsl:call-template>
        
        <!-- 
        ===========================================================================================================================================
        
        Fin Información Adicional  - Anticipos
        
        ===========================================================================================================================================
        -->
               
        
        
        <!-- 
        ===========================================================================================================================================
        
        Información Adicional
        
        ===========================================================================================================================================
        -->                
        
        <xsl:apply-templates select="cbc:Note"/>
        
        <xsl:call-template name="isTrueExpresion">
	        <xsl:with-param name="errorCodeValidate" select="'4264'" />
	        <xsl:with-param name="node" select="cbc:Note[@languageLocaleID='2007']" />
	        <xsl:with-param name="expresion" select="cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode='17']/cbc:TaxableAmount &gt; 0 and not(cbc:Note[@languageLocaleID='2007'])" />
	        <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4266'" />
            <xsl:with-param name="node" select="cbc:Note[@languageLocaleID='2005']" />
            <xsl:with-param name="expresion" select="cac:Delivery/cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line  and not(cbc:Note[@languageLocaleID='2005'])" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>  
        
        <xsl:if test="$tipoOperacion ='1001' or $tipoOperacion ='1002' or $tipoOperacion ='1003' or $tipoOperacion ='1004'">
             <xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'4265'" />
                 <xsl:with-param name="node" select="cbc:Note[@languageLocaleID='2006']" />
                 <xsl:with-param name="expresion" select="not(cbc:Note[@languageLocaleID='2006'])" />
                 <xsl:with-param name="isError" select ="false()"/>
             </xsl:call-template>
        </xsl:if>
        
        <!-- /Invoice/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:AdditionalProperty/cbc:ID El valor del Tag UBL (1000, 1001, 1002, 2000, 2001, 2002, 2003) no debe repetirse en el /Invoice 
        ERROR 2407 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3014'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(cbc:Note[@languageLocaleID='1000']) &gt; 1 or 
            count(cbc:Note[@languageLocaleID='1002']) &gt; 1 or 
            count(cbc:Note[@languageLocaleID='2000']) &gt; 1 or 
            count(cbc:Note[@languageLocaleID='2001']) &gt; 1 or 
            count(cbc:Note[@languageLocaleID='2002']) &gt; 1 or 
            count(cbc:Note[@languageLocaleID='2003']) &gt; 1 or
            count(cbc:Note[@languageLocaleID='2004']) &gt; 1 or
            count(cbc:Note[@languageLocaleID='2005']) &gt; 1 or
            count(cbc:Note[@languageLocaleID='2006']) &gt; 1 or
            count(cbc:Note[@languageLocaleID='2007']) &gt; 1 or
            count(cbc:Note[@languageLocaleID='2008']) &gt; 1 or
            count(cbc:Note[@languageLocaleID='2009']) &gt; 1 " />
        </xsl:call-template>
        
        <!-- Cambio el tipo de operacion sea obligatorio y exista en el catalogo -->
        <xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'3205'"/>
			<xsl:with-param name="node" select="$tipoOperacion"/>
		</xsl:call-template>
		
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'51'"/>
			<xsl:with-param name="propiedad" select="'factura'"/>
			<xsl:with-param name="idCatalogo" select="$tipoOperacion"/>
			<xsl:with-param name="valorPropiedad" select="'1'"/>
			<xsl:with-param name="errorCodeValidate" select="'3206'"/>
		</xsl:call-template>
             
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4260'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@name"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Operacion)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4261'"/>
			<xsl:with-param name="node" select="cbc:InvoiceTypeCode/@listSchemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo51)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4233'"/>
			<xsl:with-param name="node" select="cac:OrderReference/cbc:ID"/>
			<xsl:with-param name="regexp" select="'^(?!\s*$).{1,20}$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- 
		<xsl:if test="$tipoOperacion = '0110' or $tipoOperacion = '0111'">
        	<xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'1076'" />
                 <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cbc:ID" />
                 <xsl:with-param name="expresion" select="not(cac:Delivery/cac:Shipment)" />
             </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$tipoOperacion = '0110' or $tipoOperacion = '0111'">
        	<xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'1077'" />
                 <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cbc:ID" />
                 <xsl:with-param name="expresion" select="cac:Delivery/cac:Shipment" />
             </xsl:call-template>
        </xsl:if>
        -->
        
        <xsl:apply-templates select="cac:Delivery/cac:Shipment">
        	<xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
	    </xsl:apply-templates>
                
        <xsl:if test="$tipoOperacion = '0303'">
        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3180'"/>
                <xsl:with-param name="node" select="cbc:DueDate"/>                
            </xsl:call-template>
        </xsl:if>
        
        <!-- 
        ===========================================================================================================================================
        
        Fin Información Adicional
        
        ===========================================================================================================================================
        -->
        
         <!-- 
        ===========================================================================================================================================
        
        Detracciones
        
        ===========================================================================================================================================
        -->
        
        <xsl:if test="$tipoOperacion ='1001' or $tipoOperacion ='1002' or $tipoOperacion ='1003' or $tipoOperacion ='1004'">
        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3127'"/>
                <xsl:with-param name="node" select="cac:PaymentTerms/cbc:PaymentMeansID"/>                
            </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$tipoOperacion !='1001' and $tipoOperacion !='1002' and $tipoOperacion !='1003' and $tipoOperacion !='1004'">
        	<xsl:call-template name="isTrueExpresion">
                 <xsl:with-param name="errorCodeValidate" select="'3128'" />
                 <xsl:with-param name="node" select="cac:PaymentTerms/cbc:PaymentMeansID" />
                 <xsl:with-param name="expresion" select="cac:PaymentTerms/cbc:PaymentMeansID" />
             </xsl:call-template>
        </xsl:if>
        
        <xsl:apply-templates select="cac:PaymentTerms">
        	<xsl:with-param name="tipoOperacion" select="$tipoOperacion"/>
        </xsl:apply-templates>
        
        <xsl:if test="$tipoOperacion = '0302'">
	    	<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3173'"/>
				<xsl:with-param name="node" select="cac:PaymentMeans/cbc:PaymentMeansCode"/>
			</xsl:call-template>			
        </xsl:if>
        
        <xsl:apply-templates select="cac:PaymentMeans">
        	<xsl:with-param name="tipoOPeracion" select="$tipoOperacion"/>
        	<xsl:with-param name="codigoProducto" select="$codigoProducto"/>
        </xsl:apply-templates>
        <!-- 
        ===========================================================================================================================================
        
        Fin Detracciones
        
        ===========================================================================================================================================
        -->
        
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
    
    =========================================== fin Template cbc:Note ======================================================
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    ============================================ Template cac:AccountingSupplierParty =========================================================
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AccountingSupplierParty">
    	<xsl:param name="tipoOperacion" select = "'-'" />
        <!-- cac:AccountingSupplierParty/cbc:CustomerAssignedAccountID No existe el Tag UBL ERROR 1006 -->
        <!--  El valor del Tag UBL es diferente al RUC del nombre del XML ERROR 1034 -->
        <!--  El valor del Tag UBL no existe en el listado ERROR 2104 -->
        <!--  El valor del Tag UBL tiene un ind_estado diferente "00" en el listado ERROR 2010 -->
        <!--  El valor del Tag UBL tiene un ind_condicion diferente "00" en el listado ERROR 2011 -->
        
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3089'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>
        
        <!-- cac:AccountingSupplierParty/cbc:AdditionalAccountID No existe el Tag UBL ERROR 1008 -->
        <!--  El valor del Tag UBL es diferente a "6" ERROR 1007 -->
        <!--  Existe más de un Tag UBL en el XML ERROR 2362 -->
        <!-- Tipo de documento -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1008'"/>
            <xsl:with-param name="errorCodeValidate" select="'1007'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^(6)$'"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres ERROR 4092 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4092'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyName/cbc:Name"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,1499}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
    
        <!-- Apellidos y nombres, denominación o razón social -->
        <!-- cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName No existe el Tag UBL ERROR 1037 -->
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 1500 caracteres ERROR 1038 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'1037'"/>
            <xsl:with-param name="errorCodeValidate" select="'1038'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,1499}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4094'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 25 caracteres ERROR 4095 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4095'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,24}$'"/> <!-- de hasta 25 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4096 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4096'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CityName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> <!-- de 1 a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'4093'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID"/>
			<xsl:with-param name="catalogo" select="'13'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4097 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4097'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4098 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4098'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:District"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4041 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4041'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode"/>
            <xsl:with-param name="regexp" select="'^(PE)$'"/> <!-- igual a PE -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 3166-1)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cac:Country/cbc:IdentificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Country)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		 
		<xsl:call-template name="existElementNoVacio">
			<xsl:with-param name="errorCodeNotExist" select="'3030'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cac:RegistrationAddress/cbc:AddressTypeCode"/>
			<!-- PAS115 Se cambio a observación a solicitud de MICHAEL RUIZ  -->
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
		
		<xsl:if test="$tipoOperacion = '0302'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3156'"/>
				<xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID"/>
			</xsl:call-template>				
		</xsl:if>
		
		<xsl:if test="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID">			
			<xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'3157'"/>
	            <xsl:with-param name="errorCodeValidate" select="'3158'"/>
	            <xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
	            <xsl:with-param name="regexp" select="'^(6)$'"/> 
	        </xsl:call-template>
	        
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4255'"/>
				<xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID/@schemeName"/>
				<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4256'"/>
				<xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4257'"/>
				<xsl:with-param name="node" select="cac:Party/cac:AgentParty/cac:PartyIdentification/cbc:ID/@schemeURI"/>
				<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
		</xsl:if>
		
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:AccountingSupplierParty ======================================================
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:Delivery/cac:DeliveryLocation/cac:Address =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Delivery/cac:DeliveryLocation/cac:Address">
		<xsl:param name="tipoOperacion" select = "'-'" />
    	
    	<!-- tipoOperacion es diferente 0104 Venta interna - Itinerante y existe el tag 
        cac:Delivery/cac:DeliveryLocation/cac:Address OBSERVACION 4263 
        <xsl:if test="not($tipoOperacion ='0104')">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4263'" />
                <xsl:with-param name="node" select="cac:AddressLine/cbc:Line" />
                <xsl:with-param name="expresion" select="cac:AddressLine/cbc:Line" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
					
        </xsl:if>
        -->
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4236'"/>
            <xsl:with-param name="node" select="cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 25 caracteres ERROR 4238 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4238'"/>
            <xsl:with-param name="node" select="cbc:CitySubdivisionName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,24}$'"/> <!-- de hasta 25 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4096 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4239'"/>
            <xsl:with-param name="node" select="cbc:CityName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:if test="cbc:ID">
	        <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4231'"/>
				<xsl:with-param name="idCatalogo" select="cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de hasta 30 caracteres ERROR 4097 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4240'"/>
            <xsl:with-param name="node" select="cbc:CountrySubentity"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4241'"/>
            <xsl:with-param name="node" select="cbc:District"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> <!-- de tres a 30 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:choose>
            <xsl:when test="$tipoOperacion ='0201' or $tipoOperacion ='0208'">
				
				<xsl:call-template name="existElement">
					<xsl:with-param name="errorCodeNotExist" select="'3098'"/>
					<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode"/>
				</xsl:call-template>
				
				<xsl:call-template name="findElementInCatalog">
					<xsl:with-param name="errorCodeValidate" select="'3099'"/>
					<xsl:with-param name="idCatalogo" select="cac:Country/cbc:IdentificationCode"/>
					<xsl:with-param name="catalogo" select="'04'"/>
				</xsl:call-template>
				
				<xsl:call-template name="isTrueExpresion">
	                <xsl:with-param name="errorCodeValidate" select="'3099'" />
	                <xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode" />
	                <xsl:with-param name="expresion" select="cac:Country/cbc:IdentificationCode = 'PE'" />
	            </xsl:call-template>
			
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'4041'"/>
		            <xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode"/>
		            <xsl:with-param name="regexp" select="'^(PE)$'"/> <!-- igual a PE -->
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>		        
			</xsl:otherwise>
		</xsl:choose>	
		        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(ISO 3166-1)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Country/cbc:IdentificationCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Country)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
       
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Delivery/cac:DeliveryLocation/cac:Address =========================================== 
    
    ===========================================================================================================================================
    -->
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:AccountingCustomerParty =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:AccountingCustomerParty">
        <xsl:param name="tipoOperacion" select = "'-'" />
        
        <!-- numero de documento -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3090'" />
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification" />
            <xsl:with-param name="expresion" select="count(cac:Party/cac:PartyIdentification) &gt; 1" />
        </xsl:call-template>
        
        <!-- cac:AccountingCustomerParty/cbc:CustomerAssignedAccountID No existe el Tag UBL 
        ERROR 2014 -->
        <xsl:call-template name="existElementNoVacio">
            <xsl:with-param name="errorCodeNotExist" select="'2014'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
        </xsl:call-template>
        
        <xsl:choose>
            <xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='6'">
            	<!--  Si "Tipo de documento de identidad del adquiriente" es 6, el formato del Tag UBL es diferente a numérico de 11 dígitos 
        		ERROR 2017 -->
				<xsl:call-template name="regexpValidateElementIfExist">
		             <xsl:with-param name="errorCodeValidate" select="'2017'"/>
		             <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
		             <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
		         </xsl:call-template>					
			</xsl:when>
			<xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='1'">
				<!--  Si "Tipo de documento de identidad del adquiriente" es "1", el formato del Tag UBL es diferente a numérico de 8 dígitos 
       				OBSERV 4207 -->
				<xsl:call-template name="regexpValidateElementIfExist">
	                <xsl:with-param name="errorCodeValidate" select="'2801'"/>
	                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
	                <xsl:with-param name="regexp" select="'^[\d]{8}$'"/>
	            </xsl:call-template>						
			</xsl:when>
			<xsl:otherwise>
				<!-- Si "Tipo de documento de identidad del adquiriente" es diferente de "1" y diferente "6", el formato del Tag UBL es diferente a alfanumérico de hasta 15 caracteres 
		        	OBSERV 4208 -->
				<xsl:call-template name="regexpValidateElementIfExist">
	                <xsl:with-param name="errorCodeValidate" select="'2802'"/>
	                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
	                <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,15}$'"/>
	            </xsl:call-template>		        
			</xsl:otherwise>
		</xsl:choose>
        
        <!-- No existe el Tag UBL 
        ERROR 2015 -->
        <!-- El Tag UBL es diferente al listado 
        ERROR 2016  TODO agregar la validacion contra el catalogo-->        
        <xsl:call-template name="existElementNoVacio">
			<xsl:with-param name="errorCodeNotExist" select="'2015'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
		</xsl:call-template>
		
        <!-- <xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '-'"> -->
       	<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'2016'"/>
			<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
			<xsl:with-param name="catalogo" select="'06'"/>
		</xsl:call-template>
        <!-- </xsl:if> -->
        
        <xsl:choose>
            <xsl:when test="$tipoOperacion = '0200' or $tipoOperacion = '0201' or $tipoOperacion = '0203' or $tipoOperacion = '0204' or $tipoOperacion = '0205' or $tipoOperacion = '0205' or $tipoOperacion = '0206' or $tipoOperacion = '0207' or $tipoOperacion = '0208'">
            	<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2800'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
		            <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID = '6'" />
        		</xsl:call-template>
			</xsl:when>
			<xsl:when test="$tipoOperacion = '0112'">
				<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2800'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
		            <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '1' and cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '6'" />
        		</xsl:call-template>
			</xsl:when>
			<xsl:when test="$tipoOperacion = '0202' or $tipoOperacion = '0401'">
				<xsl:if test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '-'">
		        	<xsl:call-template name="findElementInCatalog">
						<xsl:with-param name="errorCodeValidate" select="'2800'"/>
						<xsl:with-param name="idCatalogo" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID"/>
						<xsl:with-param name="catalogo" select="'06'"/>
					</xsl:call-template>
		        </xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="isTrueExpresion">
		            <xsl:with-param name="errorCodeValidate" select="'2800'" />
		            <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID" />
		            <xsl:with-param name="expresion" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID != '6'" />
        		</xsl:call-template>					        
			</xsl:otherwise>
		</xsl:choose>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
        <!-- No existe el Tag UBL ERROR 
        2021 -->
        <!-- El formato del Tag UBL es diferente a alfanumérico de 3 hasta 1000 caracteres 
        ERROR 2022 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2021'"/>
            <xsl:with-param name="errorCodeValidate" select="'2022'"/>
            <xsl:with-param name="node" select="cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,1499}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
        </xsl:call-template>
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:AccountingCustomerParty =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:DespatchDocumentReference =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:DespatchDocumentReference">
        
        <!--  El "Tipo de la guía de remisión relacionada" concatenada con el valor del Tag UBL no debe repetirse en el /Invoice 
        ERROR 2364 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2364'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-despatch-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
        
        <!-- cac:DespatchDocumentReference/cbc:ID "Si el Tag UBL existe, el formato del Tag UBL es diferente a:  
        (.){1,}-[0-9]{1,}
        [T][0-9]{3}-[0-9]{1,8}
        [0-9]{4}-[0-9]{1,8}" 
        OBSERV 4006 -->
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4006'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(([T][0-9]{3}-[0-9]{1,8})|([0-9]{4}-[0-9]{1,8})|([E][G][0-9]{2}-[0-9]{1,8})|([G][0-9]{3}-[0-9]{1,8}))$'"/>
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
        
        <!-- cac:DespatchDocumentReference/cbc:DocumentTypeCode Si existe el "Número de la guía de remisión relacionada", el formato del Tag UBL es diferente de "09" o "31" 
        OBSERV 4005 -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4005'"/>
            <xsl:with-param name="errorCodeValidate" select="'4005'"/>
            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
            <xsl:with-param name="regexp" select="'^(31)|(09)$'"/>
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Tipo de Documento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Guia Relacionada : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>
        
        
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:DespatchDocumentReference =========================================== 
    
    ===========================================================================================================================================
    -->
    
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:AdditionalDocumentReference =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AdditionalDocumentReference">
        
        <xsl:if test= "cbc:DocumentTypeCode = '02' or cbc:DocumentTypeCode = '03'">
        	
        	<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3216'"/>
				<xsl:with-param name="node" select="cbc:DocumentStatusCode"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>
			
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3214'" />
	            <xsl:with-param name="node" select="cbc:DocumentStatusCode" />
	            <xsl:with-param name="expresion" select="count(key('by-idprepaid-in-root', cbc:DocumentStatusCode)) &lt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3215'" />
	            <xsl:with-param name="node" select="cbc:DocumentStatusCode" />
	            <xsl:with-param name="expresion" select="count(key('by-document-additional-anticipo', cbc:DocumentStatusCode)) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4252'"/>
				<xsl:with-param name="node" select="cbc:DocumentStatusCode/@listName"/>
				<xsl:with-param name="regexp" select="'^(Anticipo)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4251'"/>
				<xsl:with-param name="node" select="cbc:DocumentStatusCode/@listAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>
			
			<xsl:if test= "cbc:DocumentTypeCode = '02'">
	        	<xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'2521'"/>
		            <xsl:with-param name="node" select="cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^(([F][0-9A-Z]{3}-[0-9]{1,8})|([0-9]{4}-[0-9]{1,8})|([E][0][0][1]-[0-9]{1,8}))$'"/>
		            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		        </xsl:call-template>
        	</xsl:if>
        	
        	<xsl:if test= "cbc:DocumentTypeCode = '03'">
	        	<xsl:call-template name="regexpValidateElementIfExist">
		            <xsl:with-param name="errorCodeValidate" select="'2521'"/>
		            <xsl:with-param name="node" select="cbc:ID"/>
		            <xsl:with-param name="regexp" select="'^(([B][0-9A-Z]{3}-[0-9]{1,8})|([0-9]{4}-[0-9]{1,8})|([E][B][0][1]-[0-9]{1,8}))$'"/>
		            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		        </xsl:call-template>
        	</xsl:if>
        </xsl:if>
        
        <xsl:if test= "cbc:DocumentTypeCode != '02' and cbc:DocumentTypeCode != '03'">
	        <!-- cac:AdditionalDocumentReference/cbc:ID Si el Tag UBL existe, el formato del Tag UBL es diferente a alfanumérico de hasta 100 caracteres 
	        OBSERV 4010 -->
	        <xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4010'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4010'"/>
	            <xsl:with-param name="node" select="cbc:ID"/>
	            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,30}$'"/>
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
	        </xsl:call-template>
        
       		<!-- cac:AdditionalDocumentReference/cbc:DocumentTypeCode Si existe el "Número de otro documento relacionado", el formato del Tag UBL es diferente de "04" o "05" o "99" o "01" 
	        OBSERV 4009 -->
	        <xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4009'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4009'"/>
	            <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
	            <xsl:with-param name="regexp" select="'^(0[145]|99)$'"/>
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
	        </xsl:call-template>
	    </xsl:if>
	    
        
        <xsl:if test= "cbc:DocumentStatusCode">
    		<!-- cac:AdditionalDocumentReference/cbc:DocumentTypeCode Si existe el "Número de otro documento relacionado", el formato del Tag UBL es diferente de "04" o "05" o "99" o "01" 
			OBSERV 2505 -->
			<xsl:call-template name="existAndRegexpValidateElement">
			    <xsl:with-param name="errorCodeNotExist" select="'2505'"/>
			    <xsl:with-param name="errorCodeValidate" select="'2505'"/>
			    <xsl:with-param name="node" select="cbc:DocumentTypeCode"/>
			    <xsl:with-param name="regexp" select="'^(02|03)$'"/>
			    <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>		            
			</xsl:call-template>
			
			<xsl:call-template name="existAndRegexpValidateElement">
			    <xsl:with-param name="errorCodeNotExist" select="'3217'"/>
			    <xsl:with-param name="errorCodeValidate" select="'3217'"/>
			    <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID"/>
			    <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
			    <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
			    <xsl:with-param name="errorCodeValidate" select="'2520'"/>
			    <xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
			    <xsl:with-param name="regexp" select="'^(6)$'"/>
			    <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>
			      
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4255'"/>
				<xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeName"/>
				<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4256'"/>
				<xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
				<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4257'"/>
				<xsl:with-param name="node" select="cac:IssuerParty/cac:PartyIdentification/cbc:ID/@schemeURI"/>
				<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
				<xsl:with-param name="isError" select ="false()"/>
				<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
			</xsl:call-template>
			   
    	</xsl:if> 
        
        <!--  El "Tipo de otro documento relacionado" concatenada con el valor del Tag UBL no debe repetirse en el /Invoice ERROR 2365 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2365'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-additional-reference', concat(cbc:DocumentTypeCode,' ',cbc:ID))) &gt; 1" />
            <xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Documento Relacionado)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:DocumentTypeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo12)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Documento Relacionado : ', cbc:DocumentTypeCode,'-',cbc:ID)"/>
		</xsl:call-template>
    </xsl:template>
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:AdditionalDocumentReference =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:InvoiceLine =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:InvoiceLine">
    
        <xsl:param name="root"/>
        
        <xsl:variable name="nroLinea" select="cbc:ID"/>
        
        <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
        <xsl:variable name="codigoProducto" select="$root/cac:PaymentTerms/cbc:PaymentMeansID"/>
        <xsl:variable name="codigoPrecio" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode"/>
                
        <!-- cac:InvoiceLine/cbc:ID El formato del Tag UBL es diferente de numérico de 3 dígitos ERROR 2023 -->
        <!-- Numero de item -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2023'"/>
            <xsl:with-param name="errorCodeValidate" select="'2023'"/>
            <xsl:with-param name="node" select="cbc:ID"/>
            <xsl:with-param name="regexp" select="'^(?!0*$)\d{1,5}$'"/> <!-- de tres numeros como maximo, no cero -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!--  El valor del Tag UBL no debe repetirse en el /Invoice ERROR 2752 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2752'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-invoiceLine-id', number(cbc:ID))) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <!-- cac:InvoiceLine/cbc:InvoicedQuantity/@unitCode No existe el atributo del Tag UBL ERROR 2883 -->
        <!-- Unidad de medida por item -->
        <xsl:if test="cbc:InvoicedQuantity">
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2883'"/>
                <xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4258'"/>
			<xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCodeListID"/>
			<xsl:with-param name="regexp" select="'^(UN/ECE rec 20)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4259'"/>
			<xsl:with-param name="node" select="cbc:InvoicedQuantity/@unitCodeListAgencyName"/>
			<xsl:with-param name="regexp" select="'^(United Nations Economic Commission for Europe)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
        <!-- cac:InvoiceLine/cbc:InvoicedQuantity No existe el Tag UBL ERROR 2024 -->
        <!--  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales ERROR 2025 -->
        <!-- Cantidad de unidades por item -->
        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2024'"/>
            <xsl:with-param name="errorCodeValidate" select="'2025'"/>
            <xsl:with-param name="node" select="cbc:InvoicedQuantity"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2024'" />
            <xsl:with-param name="node" select="cbc:InvoicedQuantity" />
            <xsl:with-param name="expresion" select="cbc:InvoicedQuantity = 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4269'"/>
            <xsl:with-param name="node" select="cac:Item/cac:SellersItemIdentification/cbc:ID"/>
            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{0,29})$'"/> <!-- Texto de un caracter a 250. acepta saltos de linea, no permite que inicie con espacios -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        
        <xsl:if test="$tipoOperacion = '0200' or $tipoOperacion = '0201' or $tipoOperacion = '0202' or $tipoOperacion = '0203' or $tipoOperacion = '0204' or $tipoOperacion = '0205' or $tipoOperacion = '0206' or $tipoOperacion = '0207' or $tipoOperacion = '0208'">
        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3001'"/>
                <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'3002'"/>
			<xsl:with-param name="idCatalogo" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode"/>
			<xsl:with-param name="catalogo" select="'25'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:if test="$tipoOperacion = '0112' ">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3181'" />
	            <xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode" />
	            <xsl:with-param name="expresion" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode != '84121901' and cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode != '80131501'" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
	        </xsl:call-template>
        </xsl:if>
        
		
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4254'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listID"/>
			<xsl:with-param name="regexp" select="'^(UNSPSC)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(GS1 US)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode/@listName"/>
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
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3200'"/>
			<xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID"/>
			<xsl:with-param name="regexp" select="'^(GTIN-8|GTIN-13|GTIN-14)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
        <xsl:if test="cac:Item/cac:StandardItemIdentification/cbc:ID">
			<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3199'"/>
                <xsl:with-param name="node" select="cac:Item/cac:StandardItemIdentification/cbc:ID/@schemeID"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
		</xsl:if>
        
        <!-- cac:InvoiceLine/cac:Item/cbc:Description No existe el Tag UBL ERROR 2026 -->
        <!--  El formato del Tag UBL es diferente a alfanumérico de 1 hasta 250 caracteres ERROR 2027 -->
        <!-- Descripción detallada del servicio prestado, bien vendido o cedido en uso, indicando las características. -->
        <xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'2026'"/>
            <xsl:with-param name="errorCodeValidate" select="'2027'"/>
            <xsl:with-param name="node" select="cac:Item/cbc:Description"/>
            <xsl:with-param name="regexp" select="'^((?!\s*$)[\s\S]{1,250})$'"/> <!-- Texto de un caracter a 250. acepta saltos de linea, no permite que inicie con espacios -->
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- cac:InvoiceLine/cac:Price/cbc:PriceAmount No existe el Tag UBL ERROR 2068 -->
        <!--  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales ERROR 2369 -->
        <!-- Valor unitario por ítem -->
        <xsl:call-template name="existAndValidateValueTenDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2068'"/>
            <xsl:with-param name="errorCodeValidate" select="'2369'"/>
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2640'" />
            <xsl:with-param name="node" select="cac:Price/cbc:PriceAmount" />
            <xsl:with-param name="expresion" select="cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount &gt; 0 and cac:Price/cbc:PriceAmount &gt; 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea:', $nroLinea, '. ')"/>
	    </xsl:call-template>
        
        <!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode El valor del Tag UBL es diferente al listado ERROR 2410 -->
        <!-- Código de precio unitario -->
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2028'"/>
            <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:for-each select="cac:PricingReference/cac:AlternativeConditionPrice">
        	
        	<!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount No existe el Tag UBL o es vacío 
	        ERROR 2028 -->
	        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales 
	        ERROR 2367 -->	        
	        <xsl:call-template name="existAndValidateValueTenDecimal">
	            <xsl:with-param name="errorCodeNotExist" select="'2028'"/>
	            <xsl:with-param name="errorCodeValidate" select="'2367'"/>
	            <xsl:with-param name="node" select="cbc:PriceAmount"/>
	            <xsl:with-param name="isGreaterCero" select="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
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
            
            <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2409'" />
	            <xsl:with-param name="node" select="cbc:PriceTypeCode" />
	            <xsl:with-param name="expresion" select="count(cbc:PriceTypeCode) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea:', position(), '. ')"/>
	        </xsl:call-template>
            
            
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
        
         <!-- cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceAmount Si 
     	"Afectación al IGV por línea" es 10 (Gravado), 20 (Exonerado) o 30 (Inafecto) y "cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode" es 02 (Valor referencial en operaciones no onerosa), 
     	el Tag UBL es mayor a 0 (cero) 
     	ERROR 2425 -->
	    <!-- Valor referencial unitario por ítem en operaciones no onerosas -->
	    <!-- 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2425'" />
            <xsl:with-param name="node" select="cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode" />
            <xsl:with-param name="expresion" select="$codigoPrecio='02' and cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount > 0 and cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '10' or text() = '20' or text() = '30']" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template> 
        -->
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3224'" />
            <xsl:with-param name="node" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode = '02']/cbc:PriceAmount" />
            <xsl:with-param name="expresion" select="cac:PricingReference/cac:AlternativeConditionPrice[cbc:PriceTypeCode ='02']/cbc:PriceAmount &gt; 0 and not(cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996'] and cbc:TaxableAmount &gt; 0])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3195 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3195'" />
            <xsl:with-param name="node" select="cac:TaxTotal" />
            <xsl:with-param name="expresion" select="not(cac:TaxTotal)" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!--  Debe existir en el cac:InvoiceLine un bloque TaxTotal ERROR 3195 -->
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
              
        
        <!-- Valor de venta por línea -->
        <!-- cac:InvoiceLine/cbc:LineExtensionAmount El formato del Tag UBL es diferente de decimal (positivo o negativo) de 12 enteros y hasta 2 decimales ERROR 2370 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2370'"/>
            <xsl:with-param name="errorCodeValidate" select="'2370'"/>
            <xsl:with-param name="node" select="cbc:LineExtensionAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!-- cbc:LineExtensionAmount    
            Si "Tipo de operación" es 0102 (Venta interna - Anticipo), el Tag UBL es menor igual a 0 (cero)   
            ERROR   2501                        
        <xsl:if test="$tipoOperacion='0102'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2501'" />
                <xsl:with-param name="node" select="cbc:LineExtensionAmount" />
                <xsl:with-param name="expresion" select="cbc:LineExtensionAmount &lt;= 0" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            </xsl:call-template>
        </xsl:if>
        -->
        
        <!-- Cargos y tributos por linea de detalle --> 
        <xsl:apply-templates select="cac:AllowanceCharge" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>
        
        <!-- Validaciones de sumatoria -->
        <xsl:variable name="ValorVentaxItem" select="cbc:LineExtensionAmount"/>
        <xsl:variable name="ValorVentaUnitarioxItem" select="cac:Price/cbc:PriceAmount"/>
        <xsl:variable name="ImpuestosItem" select="cac:TaxTotal/cbc:TaxAmount"/>
        <xsl:variable name="DsctosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '01']/cbc:Amount)"/>
        <xsl:variable name="DsctosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '00']/cbc:Amount)"/>
        <xsl:variable name="CargosNoAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '48']/cbc:Amount)"/>
        <xsl:variable name="CargosAfectanBI" select="sum(cac:AllowanceCharge[cbc:AllowanceChargeReasonCode = '47']/cbc:Amount)"/>
        <xsl:variable name="CantidadItem" select="cbc:InvoicedQuantity"/>
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
        
        <xsl:if test="$codigoProducto = '004'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3063'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3001'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3001')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3130'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3002'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3002')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3131'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3003'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3003')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3132'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3004'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3004')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3134'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3005'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3005')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3133'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3006'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3006')"/>
            </xsl:call-template>
            
        </xsl:if>
        
        <!-- 
        <xsl:if test="$codigoProducto = '026'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3182'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3050']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3050'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3050')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3183'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3051']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3051'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3051')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3184'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3052']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3052'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3052')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3185'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3053']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3053'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3053')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3186'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3054']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3054'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3054')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3197'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3055']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3055'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3055')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3187'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3056']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3056'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3056')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3188'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3057']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3057'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3057')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3189'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3058']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3058'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3058')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3190'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3059']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3059'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3059')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeNotExist" select="'3191'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3060']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '3060'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 3060')"/>
            </xsl:call-template>
        </xsl:if>
        -->
        
        <xsl:if test="$tipoOperacion = '0202'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3136'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4009'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4009')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3137'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4008'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4008')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3138'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4000'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4000')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3139'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4007'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4007')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3140'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4001'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4001')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3141'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4002'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4002')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3142'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4003'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4003')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3143'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4004'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4004')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3144'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4006'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4006')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3145'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4005'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4005')"/>
            </xsl:call-template>
            
        </xsl:if>
        
        <xsl:if test="$tipoOperacion = '0205'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3138'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4000'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4000')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3139'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4007'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4007')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3137'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4008'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4008')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3136'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4009'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4009')"/>
            </xsl:call-template>
                
        </xsl:if>
        
        <xsl:if test="$tipoOperacion = '0301'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3168'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4030']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4030'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4030')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3169'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4031']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4031'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4031')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3170'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4032']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4032'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4032')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3171'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4033']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4033'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4033')"/>
            </xsl:call-template>
            
        </xsl:if>
        
        
        <xsl:if test="$tipoOperacion = '0302'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3159'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4040']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4040'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4040')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3160'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4041']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4041'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4041')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3161'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4042']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4042'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4042')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3162'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4043']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4043'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4043')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3163'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4044']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4044'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4044')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3164'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4045']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4045'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4045')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3165'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4046']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4046'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4046')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3166'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4047']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4047'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4047')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3167'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4048']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4048'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4048')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3204'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4049']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4049'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4049')"/>
            </xsl:call-template>
                        
        </xsl:if>
        
        <xsl:if test="$tipoOperacion = '0303'">
        	<xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3176'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4060']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4060'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4060')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3177'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4061']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4061'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4061')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3178'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4062']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4062'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4062')"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3179'"/>
                <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4063']" />
                <xsl:with-param name="expresion" select="not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '4063'])" />
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 4063')"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3146'"/>
            <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000']" />
            <xsl:with-param name="expresion" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5001' or text() = '5002' or text() = '5003'] and not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000'])"/>
            <xsl:with-param name="descripcion" select="concat('Error: en la linea: ', $nroLinea, ' Concepto: 5000')"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3147'"/>
            <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5001']" />
            <xsl:with-param name="expresion" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000' or text() = '5002' or text() = '5003'] and not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5001'])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 5001')"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3148'"/>
            <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5002']" />
            <xsl:with-param name="expresion" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000' or text() = '5001' or text() = '5003'] and not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5002'])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 5002')"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3149'"/>
            <xsl:with-param name="node" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5003']" />
            <xsl:with-param name="expresion" select="cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5000' or text() = '5001' or text() = '5002'] and not(cac:Item/cac:AdditionalItemProperty/cbc:NameCode[text() = '5003'])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Concepto: 5003')"/>
        </xsl:call-template>
        
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
        
        <xsl:variable name="fechaIngreso" select="cac:Item/cac:AdditionalItemProperty[cbc:NameCode[text() = '4003']]/cac:UsabilityPeriod/cbc:StartDate" />
		<xsl:variable name="fechaSalida" select="cac:Item/cac:AdditionalItemProperty[cbc:NameCode[text() = '4004']]/cac:UsabilityPeriod/cbc:StartDate" />
        <xsl:variable name="cacInvoicePeriodcbcStartDate" select="date:seconds($fechaIngreso)" />
		<xsl:variable name="cacInvoicePeriodcbcEndDate" select="date:seconds($fechaSalida)" />
		
		<!-- La fecha/hora de recepcion del comprobante por ose, no debe de ser mayor a la fecha de recepcion de sunat -->
		<xsl:call-template name="isTrueExpresion">
			<xsl:with-param name="errorCodeValidate" select="'4282'" />
			<xsl:with-param name="node" select="fechaIngreso" />
			<xsl:with-param name="expresion" select="$cacInvoicePeriodcbcStartDate &gt; $cacInvoicePeriodcbcEndDate" />
			<xsl:with-param name="descripcion" select="concat('La fecha de ingreso al establecimiento ', $fechaIngreso,' es mayor a la fecha de salida ', $fechaSalida,'&quot;')"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template> 
        
        <!-- Detracciones Servicios de transporte de carga -->
        <xsl:if test="$codigoProducto = '027'">
        	<xsl:call-template name="existElement">
	        	<xsl:with-param name="errorCodeNotExist" select="'3116'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Despatch/cac:DespatchAddress/cbc:ID"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	       	</xsl:call-template>
	        
	        <xsl:call-template name="existElement">
	        	<xsl:with-param name="errorCodeNotExist" select="'3117'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	       	</xsl:call-template>
	       	
	       	<xsl:call-template name="existElement">
	        	<xsl:with-param name="errorCodeNotExist" select="'3118'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryLocation/cac:Address/cbc:ID"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	       	</xsl:call-template>
	       	
	        <xsl:call-template name="existElement">
	        	<xsl:with-param name="errorCodeNotExist" select="'3119'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	       	</xsl:call-template>
	       	
	        <xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'3120'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Despatch/cbc:Instructions"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
	        <!-- <xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'3121'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms/cbc:ID"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        -->
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3124'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '01']" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '01']) or count(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '01']) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
	        
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3125'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '02']" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '02']) or count(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '02']) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3126'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '03']" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '03']) or count(cac:Delivery/cac:DeliveryTerms/cbc:ID[text() = '03']) &gt; 1" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3122'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '01']]/cbc:Amount" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '01']]/cbc:Amount)" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ValorReferencial: 01')"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3122'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '02']]/cbc:Amount" />
	            <xsl:with-param name="expresion" select="not(cac:Delivery/cac:DeliveryTerms[cbc:ID[text() = '02']]/cbc:Amount)" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ValorReferencial: 02')"/>
	        </xsl:call-template>
	        	        
	        <xsl:if test="cac:Delivery/cac:Shipment/cac:Consignment/cac:PlannedPickupTransportEvent/cac:Location/cbc:ID">
				<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:PlannedPickupTransportEvent/cac:Location/cbc:ID"/>
		            <xsl:with-param name="errorCodeValidate" select="'4200'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
	        </xsl:if>        
	        
	        <xsl:if test="cac:Delivery/cac:Shipment/cac:Consignment/cac:PlannedDeliveryTransportEvent/cac:Location/cbc:ID">
				<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'13'"/>
		            <xsl:with-param name="idCatalogo" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:PlannedDeliveryTransportEvent/cac:Location/cbc:ID"/>
		            <xsl:with-param name="errorCodeValidate" select="'4200'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
	        </xsl:if>
        
	        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
	        <xsl:call-template name="regexpValidateElementIfExist">
	            <xsl:with-param name="errorCodeValidate" select="'4271'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cbc:CarrierServiceInstructions"/>
	            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,100}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
	        <xsl:if test="cac:Delivery/cac:Shipment/cac:Consignment/cac:DeliveryTerms/cbc:Amount">
				<xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'4272'"/>
		            <xsl:with-param name="errorCodeValidate" select="'4272'"/>
		            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:DeliveryTerms/cbc:Amount"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    </xsl:if>
	        
	        <xsl:call-template name="regexpValidateElementIfExist">
	            <xsl:with-param name="errorCodeValidate" select="'4273'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:SizeTypeCode"/>
	            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,14}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
	            <xsl:with-param name="isError" select ="false()"/>
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4274'"/>
	            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension/cbc:AttributeID[text() != '01' and text() != '02']" />
	            <xsl:with-param name="expresion" select="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension/cbc:AttributeID and cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension/cbc:AttributeID[text() != '01' and text() != '02']" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
	        
	        <xsl:apply-templates select="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension" mode="linea">
	            <xsl:with-param name="nroLinea" select="$nroLinea"/>
	        </xsl:apply-templates>
			
			<xsl:if test="cac:Delivery/cac:Shipment/cac:Consignment/cbc:DeclaredForCarriageValueAmount">
				<xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'4278'"/>
		            <xsl:with-param name="errorCodeValidate" select="'4278'"/>
		            <xsl:with-param name="node" select="cac:Delivery/cac:Shipment/cac:Consignment/cbc:DeclaredForCarriageValueAmount"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    </xsl:if>
        </xsl:if>
        
        <xsl:apply-templates select="cac:Delivery" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>
        
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:InvoiceLine =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:Delivery =========================================== 
    
    ===========================================================================================================================================
    -->        
    <xsl:template match="cac:Delivery" mode="linea">
        <xsl:param name="nroLinea"/>

    	<xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'13'"/>
            <xsl:with-param name="idCatalogo" select="cac:Despatch/cac:DespatchAddress/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'4200'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Despatch/cac:DespatchAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Despatch/cac:DespatchAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4236'"/>
            <xsl:with-param name="node" select="cac:Despatch/cac:DespatchAddress/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'13'"/>
            <xsl:with-param name="idCatalogo" select="cac:DeliveryLocation/cac:Address/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'4200'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:DeliveryLocation/cac:Address/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:DeliveryLocation/cac:Address/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4236 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4236'"/>
            <xsl:with-param name="node" select="cac:DeliveryLocation/cac:Address/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,199}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <!--  El formato del Tag UBL es diferente a alfanumérico de 3 hasta 200 caracteres ERROR 4094 -->
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4270'"/>
            <xsl:with-param name="node" select="cac:Despatch/cbc:Instructions"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,500}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:apply-templates select="cac:DeliveryTerms" mode="linea">
            <xsl:with-param name="nroLinea" select="$nroLinea"/>
        </xsl:apply-templates>
		
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:PlannedPickupTransportEvent/cac:Location/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:PlannedPickupTransportEvent/cac:Location/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:PlannedDeliveryTransportEvent/cac:Location/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:PlannedDeliveryTransportEvent/cac:Location/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
	    <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3208'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:DeliveryTerms/cbc:Amount/@currencyID"/>
			<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
				
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:SizeTypeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Configuracion Vehícular)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:TransportEquipment/cbc:SizeTypeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:MTC)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3208'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:TransportEquipment/cac:Delivery/cac:DeliveryTerms/cbc:Amount/@currencyID"/>
			<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3208'"/>
			<xsl:with-param name="node" select="cac:Shipment/cac:Consignment/cbc:DeclaredForCarriageValueAmount/@currencyID"/>
			<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
    </xsl:template>
    <!-- 
    ===========================================================================================================================================
    
    =========================================== FIN - Template cac:Delivery =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    ================= Template cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension =================== 
    
    ===========================================================================================================================================
    -->        
    <xsl:template match="cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension" mode="linea">
        <xsl:param name="nroLinea"/>
        
        <xsl:if test="cbc:AttributeID = '01' or cbc:AttributeID = '02'">
        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4275'"/>
	            <xsl:with-param name="node" select="cbc:Measure" />
	            <xsl:with-param name="expresion" select="not(cbc:Measure)" />
	            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' TipoCarga: ', cbc:AttributeID)"/>
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
	        
	        <!-- <xsl:if test="cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension/cbc:Measure">-->
				<xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'4276'"/>
		            <xsl:with-param name="errorCodeValidate" select="'4276'"/>
		            <xsl:with-param name="node" select="cbc:Measure"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' TipoCarga: ', cbc:AttributeID)"/>
	            	<xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		    <!-- </xsl:if>-->
		    
		    <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4277'"/>
				<xsl:with-param name="node" select="cbc:Measure/@unitCode"/>
				<xsl:with-param name="regexp" select="'^(TNE)$'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' TipoCarga: ', cbc:AttributeID)"/>
	            <xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
	    </xsl:if>
    </xsl:template>
    <!-- 
    ===========================================================================================================================================
    
    ======== FIN - Template cac:Delivery/cac:Shipment/cac:Consignment/cac:TransportHandlingUnit/cac:MeasurementDimension ====================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:DeliveryTerms =========================================== 
    
    ===========================================================================================================================================
    -->        
    <xsl:template match="cac:DeliveryTerms" mode="linea">
        <xsl:param name="nroLinea"/>
        
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3123'"/>
            <xsl:with-param name="errorCodeValidate" select="'3123'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3208'"/>
			<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
			<xsl:with-param name="regexp" select="'^(PEN)$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		</xsl:call-template>
        
    </xsl:template>
    <!-- 
    ===========================================================================================================================================
    
    =========================================== FIN - Template cac:DeliveryTerms =========================================== 
    
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
        
        <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
        <xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
        <xsl:variable name="MontoTributoCalculado" select="cbc:TaxableAmount * cac:TaxCategory/cbc:Percent * 0.01"/>
        <xsl:variable name="MontoTributo" select="cbc:TaxAmount"/>
        <xsl:variable name="valorVentaLinea" select="$root/cac:InvoiceLine[cbc:ID[text() = $nroLinea]]/cbc:LineExtensionAmount"/>
        
        
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
	    
        <xsl:if test="$codigoTributo != '2000' and $codigoTributo != '9999' and $codigoTributo != ''">
        	<xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'2371'"/>
                <xsl:with-param name="node" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
                <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
            </xsl:call-template>
            
            <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
	        ERROR 2378 
	        <xsl:call-template name="findElementInCatalogProperty">
				<xsl:with-param name="catalogo" select="'07'"/>
				<xsl:with-param name="propiedad" select="$codTributo"/>
				<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cbc:TaxExemptionReasonCode"/>
				<xsl:with-param name="valorPropiedad" select="'1'"/>
				<xsl:with-param name="errorCodeValidate" select="'2040'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
			</xsl:call-template>
			-->
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
        <xsl:if test="$tipoOperacion='0200' or $tipoOperacion='0201' or $tipoOperacion='0202' or $tipoOperacion='0203' or $tipoOperacion='0204' or $tipoOperacion='0205' or $tipoOperacion='0206' or $tipoOperacion='0207' or $tipoOperacion='0208'">
        
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
		
		<xsl:if test="$codigoTributo != '2000' and $codigoTributo != '9999'">
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
        
		<!-- 3222 Tag ubl > 0 and no exista un TaxableAmount  del mismo tributo > 0  
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3222'" />
            <xsl:with-param name="node" select="cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="cbc:TaxableAmount &gt; 0 and not($root/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID = $codigoTributo and cbc:TaxableAmount &gt; 0])" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Tributo: ', $codigoTributo)"/>
        </xsl:call-template>
        -->
        
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
        
        <!-- <xsl:variable name="tipoOperacion" select="$root/ext:UBLExtensions/ext:UBLExtension/ext:ExtensionContent/sac:AdditionalInformation/sac:SUNATTransaction/cbc:ID"/>-->
        
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
            <xsl:with-param name="expresion" select="cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode='17']/cbc:TaxableAmount &gt; 0 and $root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode!='17']/cbc:TaxableAmount &gt; 0" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
        </xsl:call-template>       
        
        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoOperacion='0200' or $tipoOperacion='0201' or $tipoOperacion='0202' or $tipoOperacion='0203' or $tipoOperacion='0204' or $tipoOperacion='0205' or $tipoOperacion='0206' or $tipoOperacion='0207' or $tipoOperacion='0208'">
        
            <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
            ERROR 3100 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3100'" />
                <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount &gt; 0" />
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
        ERROR 3100 -->
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
    
    =========================================== Template cac:AllowanceCharge =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AllowanceCharge" mode="linea">
        <xsl:param name="nroLinea"/>
        
        <xsl:variable name="codigoCargoDescuento" select="cbc:AllowanceChargeReasonCode"/>
         
        <xsl:choose>
        
            <!-- <xsl:when test="$codigoCargoDescuento = '45' or $codigoCargoDescuento = '46' or $codigoCargoDescuento = '47' or $codigoCargoDescuento = '48' or $codigoCargoDescuento = '49' or $codigoCargoDescuento = '50' or $codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'"> -->
            <xsl:when test="$codigoCargoDescuento = '47' or $codigoCargoDescuento = '48'">
            	
            	<xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'3114'" />
		           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
		           <xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'false'" />
		           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		        </xsl:call-template>
            	
            </xsl:when>
            
            <!-- <xsl:when test="$codigoCargoDescuento = '00' or $codigoCargoDescuento = '01' or $codigoCargoDescuento = '02' or $codigoCargoDescuento = '03'">-->
            <xsl:when test="$codigoCargoDescuento = '00' or $codigoCargoDescuento = '01'">
            
	            <xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'3114'" />
		           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
		           <xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'true'" />
		           <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		        </xsl:call-template>
		        
            </xsl:when> 
        
        </xsl:choose>
        
        <!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2036 -->		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3073'"/>
            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'53'"/>
            <xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="errorCodeValidate" select="'2954'"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4268'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
			<xsl:with-param name="regexp" select="'^(00|01|47|48)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Cargo/descuento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo53)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
                
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'3052'"/>
			<xsl:with-param name="node" select="cbc:MultiplierFactorNumeric"/>
			<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
		</xsl:call-template>
		
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2955'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        <xsl:variable name="MontoCalculado" select="cbc:BaseAmount * cbc:MultiplierFactorNumeric"/>
        <xsl:variable name="Monto" select="cbc:Amount"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4289'" />
            <xsl:with-param name="node" select="cbc:Amount" />
            <xsl:with-param name="expresion" select="($Monto + 1 ) &lt; $MontoCalculado or ($Monto - 1) &gt; $MontoCalculado" />
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
            <xsl:with-param name="isError" select="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3053'"/>
            <xsl:with-param name="node" select="cbc:BaseAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' Cargo/Descuento: ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
    </xsl:template>

    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Allowancecharge =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:Item/cac:AdditionalItemProperty =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Item/cac:AdditionalItemProperty" mode="linea">
        <xsl:param name="nroLinea"/>
        
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
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:NameCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:NameCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Propiedad del item)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:NameCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo55)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		</xsl:call-template>
		
		<xsl:variable name="codigoConcepto" select="cbc:NameCode"/>
        
		<xsl:choose>
			<!-- INICIO Información Adicional  - Detracciones: Recursos Hidrobiológicos -->
            <xsl:when test="$codigoConcepto = '3001'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,14}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>		        
            </xsl:when>
            
			<xsl:when test="$codigoConcepto = '3002'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,99}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3003'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,149}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3004'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,99}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3005'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3006'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3135'"/>
		            <xsl:with-param name="node" select="cbc:ValueQuantity"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
            	
	            <xsl:call-template name="existAndValidateValueTwoDecimal">
		            <xsl:with-param name="errorCodeNotExist" select="'4281'"/>
		            <xsl:with-param name="errorCodeValidate" select="'4281'"/>
		            <xsl:with-param name="node" select="cbc:ValueQuantity"/>
		            <xsl:with-param name="isGreaterCero" select="false()"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'3115'"/>
					<xsl:with-param name="node" select="cbc:ValueQuantity/@unitCode"/>
					<xsl:with-param name="regexp" select="'^(TNE)$'"/>
					<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
				</xsl:call-template>
            </xsl:when>
            
			<!-- FIN Información Adicional  - Detracciones: Recursos Hidrobiológicos -->
        	<!-- INICIO Información Adicional  - Transporte terrestre de pasajeros -->
            <xsl:when test="$codigoConcepto = '3050'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
	            <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,19}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3051'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,19}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3052'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,14}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3053'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'06'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3054'">
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
		            <xsl:with-param name="isError" select ="false()"/>wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3055'">
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
            
            <xsl:when test="$codigoConcepto = '3056'">
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
            
            <xsl:when test="$codigoConcepto = '3057'">
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
            
            <xsl:when test="$codigoConcepto = '3058'">
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
            
            
            <xsl:when test="$codigoConcepto = '3059'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '3060'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3172'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartTime"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            <!-- FIN Información Adicional  - Transporte terrestre de pasajeros -->
            
            <!-- INICIO Información Adicional  - Beneficio de hospedaje -->
            <xsl:when test="$codigoConcepto = '4000'">
                <xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'04'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4001'">
                <xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'04'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4002'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4003'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4004'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>            
            
            <xsl:when test="$codigoConcepto = '4005'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3135'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:DurationMeasure"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4281'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:DurationMeasure"/>
		            <xsl:with-param name="regexp" select="'^[0-9]{1,4}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        
		        <xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4313'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:DurationMeasure/@unitCode"/>
		            <xsl:with-param name="regexp" select="'^(DAY)$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4006'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4007'">
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
            
            <xsl:when test="$codigoConcepto = '4008'">
                <xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'06'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4009'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,19}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <!-- FIN Información Adicional  - Beneficio de hospedaje -->
            
            <!-- INICIO - Migración de documentos autorizados - Carta Porte Aéreo -->
            <xsl:when test="$codigoConcepto = '4030'">
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
            <xsl:when test="$codigoConcepto = '4031'">
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
            
            <xsl:when test="$codigoConcepto = '4032'">
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
            <xsl:when test="$codigoConcepto = '4033'">
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
            <!-- FIN - Migración de documentos autorizados - Carta Porte Aéreo -->
            
            <!-- INICIO Migración de documentos autorizados - BVME para transporte ferroviario de pasajeros -->
            <xsl:when test="$codigoConcepto = '4040'">
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
            
            <xsl:when test="$codigoConcepto = '4041'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="findElementInCatalog">
		            <xsl:with-param name="catalogo" select="'06'"/>
		            <xsl:with-param name="idCatalogo" select="cbc:Value"/>
		            <xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4042'">
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
            
            <xsl:when test="$codigoConcepto = '4043'">
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
            
            <xsl:when test="$codigoConcepto = '4044'">
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
            
            <xsl:when test="$codigoConcepto = '4045'">
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
            
            <xsl:when test="$codigoConcepto = '4046'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,99}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4047'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3172'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartTime"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4048'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4049'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,19}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <!-- FIN Migración de documentos autorizados - BVME para transporte ferroviario de pasajeros -->
            
            <!-- INICIO Migración de documentos autorizados - Pago de regalía petrolera -->
            <xsl:when test="$codigoConcepto = '4060'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,29}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4061'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,9}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4062'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:StartDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '4063'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3065'"/>
		            <xsl:with-param name="node" select="cac:UsabilityPeriod/cbc:EndDate"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            <!-- FIN Migración de documentos autorizados - Pago de regalía petrolera -->
            
            <!-- INICIO - Ventas Sector Público -->
            <xsl:when test="$codigoConcepto = '5000'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,19}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '5001'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,9}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '5002'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <xsl:when test="$codigoConcepto = '5003'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>
		        
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,29}$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            <!-- FIN - Ventas Sector Público -->
            
            <xsl:when test="$codigoConcepto = '7000'">
            	<xsl:call-template name="existElement">
		            <xsl:with-param name="errorCodeNotExist" select="'3064'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		        </xsl:call-template>		        
            </xsl:when>
            
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
		            <xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
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
            
            <xsl:when test="$codigoConcepto = '7008'">
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){3,30})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7009'">
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){2,29})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
		            <xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea, ' ConceptoItem ', cbc:NameCode)"/>
		            <xsl:with-param name="isError" select ="false()"/>
		        </xsl:call-template>
            </xsl:when>
            
            <xsl:when test="$codigoConcepto = '7010'">
            	<xsl:call-template name="regexpValidateElementIfExist">
	            	<xsl:with-param name="errorCodeValidate" select="'4280'"/>
		            <xsl:with-param name="node" select="cbc:Value"/>
		            <xsl:with-param name="regexp" select="'^((?!\s*$){2,29})$'"/> <!-- Texto de un caracter a 14. acepta saltos de linea, no permite que inicie con espacios -->
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
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:TaxTotal/cac:TaxSubtotal =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:TaxSubtotal" mode="cabecera">
        
        <xsl:variable name="codigoTributo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
        
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
            <xsl:with-param name="errorCodeNotExist" select="'3003'"/>
            <xsl:with-param name="errorCodeValidate" select="'2999'"/>
            <xsl:with-param name="node" select="cbc:TaxableAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>      
        </xsl:call-template>
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   2033 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'2048'"/>
            <xsl:with-param name="errorCodeValidate" select="'2048'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>
        
        <xsl:if test="$codigoTributo = '9995' or $codigoTributo = '9997' or $codigoTributo = '9998'">
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3000'" />
	            <xsl:with-param name="node" select="cbc:TaxAmount" />
	            <xsl:with-param name="expresion" select="cbc:TaxAmount != 0" />
	            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
	        </xsl:call-template>          
        </xsl:if>
                
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3059'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>            
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'05'"/>
            <xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
            <xsl:with-param name="errorCodeValidate" select="'3007'"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de tributos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo05)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>
        
        <!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2054 -->		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2054'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>
        
        <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2964 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'name'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:Name"/>
			<xsl:with-param name="errorCodeValidate" select="'2964'"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>
		
		<!-- Codigo de tributo por linea, el valor del Tag UBL es diferente al listado 
        ERROR 2052 -->		
		<xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'2052'"/>
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>
        
        <!--  El valor del Tag UBL es diferente al listado segun el codigo de tributo
        ERROR 2961 -->
        <xsl:call-template name="findElementInCatalogProperty">
			<xsl:with-param name="catalogo" select="'05'"/>
			<xsl:with-param name="propiedad" select="'UN_ECE_5153'"/>
			<xsl:with-param name="idCatalogo" select="cac:TaxCategory/cac:TaxScheme/cbc:ID"/>
			<xsl:with-param name="valorPropiedad" select="cac:TaxCategory/cac:TaxScheme/cbc:TaxTypeCode"/>
			<xsl:with-param name="errorCodeValidate" select="'2961'"/>
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
		</xsl:call-template>
        
        <!-- cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el /Invoice 
        ERROR 2352 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3068'" />
            <xsl:with-param name="node" select="cac:TaxCategory/cac:TaxScheme/cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-tributos-in-root', cac:TaxCategory/cac:TaxScheme/cbc:ID)) > 1" />
            <xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
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
    
    <xsl:template match="cac:TaxTotal" mode="cabecera">
        
        <xsl:param name="root"/>
        
                <xsl:variable name="tipoOperacion" select="$root/cbc:InvoiceTypeCode/@listID"/>
        <!-- <xsl:variable name="leyenda" select="$root/cbc:Note/@listID"/>-->
        
        <!-- El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 2 decimales   ERROR   3020 -->
        <xsl:call-template name="existAndValidateValueTwoDecimal">
            <xsl:with-param name="errorCodeNotExist" select="'3020'"/>
            <xsl:with-param name="errorCodeValidate" select="'3020'"/>
            <xsl:with-param name="node" select="cbc:TaxAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>            
        </xsl:call-template>
        
        <xsl:if test="$root/cbc:Note[@languageLocaleID = '2001']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4022'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$root/cbc:Note[@languageLocaleID = '2002']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4023'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$root/cbc:Note[@languageLocaleID = '2003']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4024'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$root/cbc:Note[@languageLocaleID = '2008']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'4244'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9997']]/cbc:TaxableAmount = 0" />
                <xsl:with-param name="isError" select ="false()"/>
            </xsl:call-template>
        </xsl:if>
        
        
        <!-- Tributos duplicados por cabebcera -->
        <xsl:apply-templates select="cac:TaxSubtotal" mode="cabecera"/>
           
        <!-- Validaciones exportacion -->
        <xsl:if test="$tipoOperacion='0200' or $tipoOperacion='0201' or $tipoOperacion='0202' or $tipoOperacion='0203' or $tipoOperacion='0204' or $tipoOperacion='0205' or $tipoOperacion='0206' or $tipoOperacion='0207' or $tipoOperacion='0208'">
            <!-- Si "Tipo de operación" es Exportación, el valor del Tag UBL es igual a 1000, 1016, 9997, 9998, 9999, 2000 (Exportación) 
            ERROR 3100 -->
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'3107'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID[text() = '1000' or text() = '1016' or text() = '9997' or text() = '9998' or text() = '9999' or text() = '2000']]/cbc:ID" />
                <xsl:with-param name="expresion" select="count(cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000' or text() = '1016' or text() = '9997' or text() = '9998' or text() = '9999' or text() = '2000']) &gt; 0" />
				<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
            </xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2650'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount &gt; 0 and $root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cbc:TaxExemptionReasonCode[text() = '17']]/cbc:TaxableAmount &gt; 0 " />
			<xsl:with-param name="descripcion" select="concat('Error Tributo ', $codigoTributo)"/>
        </xsl:call-template>
        
        <xsl:if test="$root/cbc:Note[@languageLocaleID = '1002']">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2416'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0" />
            </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$root/cac:InvoiceLine/cac:PricingReference/cac:AlternativeConditionPrice/cbc:PriceTypeCode ='02'">
            <xsl:call-template name="isTrueExpresion">
                <xsl:with-param name="errorCodeValidate" select="'2641'" />
                <xsl:with-param name="node" select="cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme[cbc:ID = '9996']/cbc:ID" />
                <xsl:with-param name="expresion" select="not(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]) or cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxableAmount = 0" />
            </xsl:call-template>
        </xsl:if>
        
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
        
        <xsl:variable name="totalBaseISC" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseISCxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4303'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseISC + 1 ) &lt; $totalBaseISCxLinea or ($totalBaseISC - 1) &gt; $totalBaseISCxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:variable name="totalBaseOtros" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount"/>
        <xsl:variable name="totalBaseOtrosxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4304'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxableAmount" />
            <xsl:with-param name="expresion" select="($totalBaseOtros + 1 ) &lt; $totalBaseOtrosxLinea or ($totalBaseOtros - 1) &gt; $totalBaseOtrosxLinea" />
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
        <xsl:variable name="totalGratuitasxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4311'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9996']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalGratuitas + 1 ) &lt; $totalGratuitasxLinea or ($totalGratuitas - 1) &gt; $totalGratuitasxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:variable name="totalImpuestos" select="cbc:TaxAmount"/>
        <xsl:variable name="SumatoriaImpuestos" select="sum(cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '1000'or text() = '1016' or text() = '9999' or text() = '2000']]/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4301'" />
            <xsl:with-param name="node" select="cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalImpuestos + 1 ) &lt; $SumatoriaImpuestos or ($totalImpuestos - 1) &gt; $SumatoriaImpuestos" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:variable name="totalISC" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount"/>
        <xsl:variable name="totalISCxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4305'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalISC + 1 ) &lt; $totalISCxLinea or ($totalISC - 1) &gt; $totalISCxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:variable name="totalOtros" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount"/>
        <xsl:variable name="totalOtrosxLinea" select="sum($root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount)"/>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4306'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '9999']]/cbc:TaxAmount" />
            <xsl:with-param name="expresion" select="($totalOtros + 1 ) &lt; $totalOtrosxLinea or ($totalOtros - 1) &gt; $totalOtrosxLinea" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'4020'" />
            <xsl:with-param name="node" select="cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:Taxmount" />
            <xsl:with-param name="expresion" select="$root/cac:InvoiceLine/cac:TaxTotal/cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount &gt; 0 and cac:TaxSubtotal[cac:TaxCategory/cac:TaxScheme/cbc:ID[text() = '2000']]/cbc:TaxAmount = 0" />
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <!-- Fin Validacion de sumatroias -->
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:TaxTotal =========================================== 
    
    ===========================================================================================================================================
    -->
    
	<!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:AllowanceCharge =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:AllowanceCharge" mode="cabecera">
    	<xsl:param name="root"/>
        
		<xsl:variable name="codigoCargoDescuento" select="cbc:AllowanceChargeReasonCode"/>
        <xsl:variable name="monedaComprobante" select="$root/cbc:DocumentCurrencyCode"/>
        <xsl:variable name="importeComprobante" select="$root/cac:LegalMonetaryTotal/cbc:PayableAmount"/>
        
        <xsl:if test="$codigoCargoDescuento = '45' or $codigoCargoDescuento = '46' or $codigoCargoDescuento = '49' or $codigoCargoDescuento = '50' or $codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">        	
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3114'" />
				<xsl:with-param name="node" select="cbc:ChargeIndicator" />
				<xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'false'" />
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>           
			</xsl:call-template>        	
        </xsl:if>
        
        <!-- <xsl:when test="$codigoCargoDescuento = '00' or $codigoCargoDescuento = '01' or $codigoCargoDescuento = '02' or $codigoCargoDescuento = '03'"> -->
        <xsl:if test="$codigoCargoDescuento = '02' or $codigoCargoDescuento = '03' or $codigoCargoDescuento = '04'"> 
			<xsl:call-template name="isTrueExpresion">
				<xsl:with-param name="errorCodeValidate" select="'3114'" />
				<xsl:with-param name="node" select="cbc:ChargeIndicator" />
				<xsl:with-param name="expresion" select="cbc:ChargeIndicator/text() = 'true'" />
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>		           
			</xsl:call-template>		        
        </xsl:if>
        
        <xsl:call-template name="existElement">
            <xsl:with-param name="errorCodeNotExist" select="'3072'"/>
            <xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
           <xsl:with-param name="errorCodeValidate" select="'4291'" />
           <xsl:with-param name="node" select="cbc:ChargeIndicator" />
           <xsl:with-param name="expresion" select="cbc:AllowanceChargeReasonCode[text() = '00' or text() = '01' or text() = '47' or text() = '48']" />
           <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
           <xsl:with-param name="isError" select ="false()"/>		           
        </xsl:call-template>
        
        <xsl:call-template name="findElementInCatalog">
            <xsl:with-param name="catalogo" select="'53'"/>
            <xsl:with-param name="idCatalogo" select="cbc:AllowanceChargeReasonCode"/>
            <xsl:with-param name="errorCodeValidate" select="'3071'"/>
            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Cargo/descuento)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:AllowanceChargeReasonCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo53)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		</xsl:call-template>
                
        <xsl:if test="$codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3025'"/>
				<xsl:with-param name="node" select="cbc:MultiplierFactorNumeric"/>
				<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,2})?$'"/>
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="$codigoCargoDescuento != '51' and $codigoCargoDescuento != '52' and $codigoCargoDescuento != '53'">
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3025'"/>
				<xsl:with-param name="node" select="cbc:MultiplierFactorNumeric"/>
				<xsl:with-param name="regexp" select="'^(?!(0)[0-9]+$)[0-9]{1,3}(\.[0-9]{1,5})?$'"/>
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
		</xsl:if>
		
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'2968'"/>
            <xsl:with-param name="node" select="cbc:Amount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        
        <xsl:if test="$codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">
        	<xsl:variable name="MontoCalculadoPercepcion" select="cbc:BaseAmount * cbc:MultiplierFactorNumeric"/>
        	<xsl:variable name="MontoPercepcion" select="cbc:Amount"/>
	        
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2792'"/>
				<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
        </xsl:if>  
        
        <xsl:if test="$codigoCargoDescuento != '45' and $codigoCargoDescuento != '51' and $codigoCargoDescuento != '52' and $codigoCargoDescuento != '53'">
	        <xsl:variable name="MontoCalculado" select="cbc:BaseAmount * cbc:MultiplierFactorNumeric"/>
	       	<xsl:variable name="Monto" select="cbc:Amount"/>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3226'" />
	            <xsl:with-param name="node" select="cbc:Amount" />
	            <xsl:with-param name="expresion" select="($MontoCalculado + 1 ) &lt; $Monto or ($MontoCalculado - 1) &gt; $Monto" />
	            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	        </xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$codigoCargoDescuento = '45'">
			<xsl:call-template name="isTrueExpresion">
	           <xsl:with-param name="errorCodeValidate" select="'3074'" />
	           <xsl:with-param name="node" select="cbc:Amount" />
	           <xsl:with-param name="expresion" select="cbc:Amount = 0" />
	           <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	        </xsl:call-template>	        
		</xsl:if>
		
        <xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'3016'"/>
            <xsl:with-param name="node" select="cbc:BaseAmount"/>
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
        </xsl:call-template>
        
        <xsl:if test="$codigoCargoDescuento = '45'">
			<xsl:call-template name="existElement">
	            <xsl:with-param name="errorCodeNotExist" select="'3092'"/>
	            <xsl:with-param name="node" select="cbc:BaseAmount"/>
	            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	        </xsl:call-template>
			
			<xsl:call-template name="isTrueExpresion">
	           <xsl:with-param name="errorCodeValidate" select="'3092'" />
	           <xsl:with-param name="node" select="cbc:BaseAmount" />
	           <xsl:with-param name="expresion" select="cbc:BaseAmount = 0" />
	           <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	        </xsl:call-template>
		</xsl:if>
        
        <xsl:if test="$codigoCargoDescuento = '51' or $codigoCargoDescuento = '52' or $codigoCargoDescuento = '53'">
        
            <xsl:call-template name="existElement">
                <xsl:with-param name="errorCodeNotExist" select="'3233'"/>
                <xsl:with-param name="node" select="cbc:BaseAmount"/>
                <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
            </xsl:call-template>
            
            <xsl:call-template name="isTrueExpresion">
               <xsl:with-param name="errorCodeValidate" select="'3233'" />
               <xsl:with-param name="node" select="cbc:BaseAmount" />
               <xsl:with-param name="expresion" select="cbc:BaseAmount = 0" />
               <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
            </xsl:call-template>
        
	        <xsl:if test="$monedaComprobante = 'PEN'">
				<xsl:call-template name="isTrueExpresion">
		           <xsl:with-param name="errorCodeValidate" select="'2797'" />
		           <xsl:with-param name="node" select="cbc:BaseAmount" />
		           <xsl:with-param name="expresion" select="cbc:BaseAmount &gt; $importeComprobante" />
		           <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
		        </xsl:call-template>
			</xsl:if>
			
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'2798'" />
	            <xsl:with-param name="node" select="cbc:Amount" />
	            <xsl:with-param name="expresion" select="($MontoCalculadoPercepcion + 1 ) &lt; $MontoPercepcion or ($MontoCalculadoPercepcion - 1) &gt; $MontoPercepcion" />
	            <xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
	        </xsl:call-template>
        	
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2788'"/>
				<xsl:with-param name="node" select="cbc:BaseAmount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>
				<xsl:with-param name="descripcion" select="concat('Error Cargo/Descuento ', $codigoCargoDescuento)"/>
			</xsl:call-template>
        </xsl:if>
        
    </xsl:template>

    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Allowancecharge =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:Delivery/cac:Shipment =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:Delivery/cac:Shipment">
    	<xsl:param name="tipoOperacion" select = "'-'" />
			
		<xsl:if test="cbc:ID">
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4249'"/>
				<xsl:with-param name="idCatalogo" select="cbc:ID"/>
				<xsl:with-param name="catalogo" select="'20'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Motivo de Traslado)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo20)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="validateValueTwoDecimalIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4155'"/>
            <xsl:with-param name="node" select="cbc:GrossWeightMeasure"/>            
            <xsl:with-param name="isGreaterCero" select="false()"/>
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4154'"/>
			<xsl:with-param name="node" select="cbc:GrossWeightMeasure/@unitCode"/>
			<xsl:with-param name="regexp" select="'^(KGM)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- 
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'4125'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		-->
		
		<xsl:call-template name="findElementInCatalog">
			<xsl:with-param name="errorCodeValidate" select="'4043'"/>
			<xsl:with-param name="idCatalogo" select="cac:ShipmentStage/cbc:TransportModeCode"/>
			<xsl:with-param name="catalogo" select="'18'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<!-- 
		<xsl:if test="$tipoOperacion = '0111'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4134'" />
	            <xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode" />
	            <xsl:with-param name="expresion" select="cac:ShipmentStage/cbc:TransportModeCode" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
		</xsl:if>
		-->
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Modalidad de Transporte)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cbc:TransportModeCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo18)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'4126'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:if test="cbc:ID and cac:ShipmentStage/cbc:TransportModeCode = '01'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4286'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="cbc:ID and cac:ShipmentStage/cbc:TransportModeCode = '02'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4159'" />
	            <xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID" />
	            <xsl:with-param name="expresion" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
		</xsl:if>
		
		<xsl:if test="cbc:ID and not(cac:ShipmentStage/cbc:TransportModeCode)">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4160'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID">
			
			<xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4161'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4162'"/>
	            <xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeID"/>
	            <xsl:with-param name="regexp" select="'^(6)$'"/>
	            <xsl:with-param name="isError" select ="false()"/>	            
	        </xsl:call-template>
	        
	        <xsl:call-template name="existAndRegexpValidateElement">
	            <xsl:with-param name="errorCodeNotExist" select="'4164'"/>
	            <xsl:with-param name="errorCodeValidate" select="'4165'"/>
	            <xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyLegalEntity/cbc:RegistrationName"/>
	            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,199}$'"/>
	            <xsl:with-param name="isError" select ="false()"/>	            
	        </xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4163'"/>
            <xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID"/>
            <xsl:with-param name="regexp" select="'^[\d]{11}$'"/>
            <xsl:with-param name="isError" select ="false()"/>	
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:CarrierParty/cac:PartyIdentification/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
        <xsl:if test="$tipoOperacion = '0110' and cac:ShipmentStage/cbc:TransportModeCode = '01' and cac:ShipmentStage/cac:DriverPerson/cbc:ID">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4156'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="$tipoOperacion = '0110' and cac:ShipmentStage/cbc:TransportModeCode = '02'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4157'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
        <xsl:if test="$tipoOperacion = '0111'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4157'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4167'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID"/>
			<xsl:with-param name="regexp" select="'^(?!\s*$).{1,8}$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4170'"/>
			<xsl:with-param name="node" select="cac:TransportHandlingUnit/cac:TransportEquipment/cbc:ID"/>
			<xsl:with-param name="regexp" select="'^(?!\s*$).{6,8}$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:if test="$tipoOperacion = '0110' and cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport/cbc:LicensePlateID">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4156'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="cac:ShipmentStage/cbc:TransportModeCode = '02'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4158'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="$tipoOperacion = '0111'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4158'"/>
				<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:choose>
            <xsl:when test="cac:Party/cac:PartyIdentification/cbc:ID/@schemeID ='1'">
				<!--  Si "Tipo de documento de identidad del adquiriente" es "1", el formato del Tag UBL es diferente a numérico de 8 dígitos 
       				OBSERV 4207 -->
				<xsl:call-template name="regexpValidateElementIfExist">
	                <xsl:with-param name="errorCodeValidate" select="'4174'"/>
	                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
	                <xsl:with-param name="regexp" select="'^[\d]{8}$'"/>
	                <xsl:with-param name="isError" select="false()"/>
	            </xsl:call-template>						
			</xsl:when>
			<xsl:otherwise>
				<!-- Si "Tipo de documento de identidad del adquiriente" es diferente de "4" y diferente "7", el formato del Tag UBL es diferente a alfanumérico de hasta 15 caracteres 
		        	OBSERV 4208 -->
				<xsl:call-template name="regexpValidateElementIfExist">
	                <xsl:with-param name="errorCodeValidate" select="'4174'"/>
	                <xsl:with-param name="node" select="cac:Party/cac:PartyIdentification/cbc:ID"/>
	                <!-- <xsl:with-param name="regexp" select="'^.{15}$'"/> -->
					<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s]{1,15}$'"/>
	                <xsl:with-param name="isError" select="false()"/>
	            </xsl:call-template>		        
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:call-template name="existAndRegexpValidateElement">
            <xsl:with-param name="errorCodeNotExist" select="'4161'"/>
            <xsl:with-param name="errorCodeValidate" select="'4162'"/>
            <xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeID"/>
            <xsl:with-param name="regexp" select="'^(1|4|7|A)$'"/>
            <xsl:with-param name="isError" select ="false()"/>	            
        </xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Documento de Identidad)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cac:ShipmentStage/cac:DriverPerson/cbc:ID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:if test="$tipoOperacion = '0110'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4127'"/>
				<xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4127'"/>
				<xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
		</xsl:if>
		
		<xsl:if test="$tipoOperacion = '0111'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4135'" />
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cbc:ID" />
	            <xsl:with-param name="expresion" select="cac:Delivery/cac:DeliveryAddress/cbc:ID" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4135'" />
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line" />
	            <xsl:with-param name="expresion" select="cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
		</xsl:if>
		
		<xsl:if test="cac:Delivery/cac:DeliveryAddress/cbc:ID">
	        <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4176'"/>
				<xsl:with-param name="idCatalogo" select="cac:Delivery/cac:DeliveryAddress/cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4179'"/>
            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryAddress/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,199}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        
        
        <xsl:if test="$tipoOperacion = '0110'">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4128'"/>
				<xsl:with-param name="node" select="cac:OriginAddress/cbc:ID"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4128'"/>
				<xsl:with-param name="node" select="cac:OriginAddress/cac:AddressLine/cbc:Line"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
			
		</xsl:if>
		
		<xsl:if test="$tipoOperacion = '0111'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4136'" />
	            <xsl:with-param name="node" select="cac:OriginAddress/cbc:ID" />
	            <xsl:with-param name="expresion" select="cac:OriginAddress/cbc:ID" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4136'" />
	            <xsl:with-param name="node" select="cac:OriginAddress/cac:AddressLine/cbc:Line" />
	            <xsl:with-param name="expresion" select="cac:OriginAddress/cac:AddressLine/cbc:Line" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>
		</xsl:if>
		
		<xsl:if test="cac:OriginAddress/cbc:ID">
	        <xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'4181'"/>
				<xsl:with-param name="idCatalogo" select="cac:OriginAddress/cbc:ID"/>
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="isError" select ="false()"/>
			</xsl:call-template>
		</xsl:if>
		
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cac:OriginAddress/cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:INEI)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		   
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cac:OriginAddress/cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Ubigeos)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
        
        <xsl:call-template name="regexpValidateElementIfExist">
            <xsl:with-param name="errorCodeValidate" select="'4184'"/>
            <xsl:with-param name="node" select="cac:OriginAddress/cac:AddressLine/cbc:Line"/>
            <xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{3,199}$'"/> <!-- de tres a 1500 caracteres que no inicie por espacio -->
            <xsl:with-param name="isError" select ="false()"/>
        </xsl:call-template>
        
        <xsl:if test="$tipoOperacion = '0110'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'4129'" />
	            <xsl:with-param name="node" select="cac:Delivery/cac:DeliveryParty/cbc:MarkAttentionIndicator" />
	            <xsl:with-param name="expresion" select="cac:Delivery/cac:DeliveryParty/cbc:MarkAttentionIndicator" />
	            <xsl:with-param name="isError" select ="false()"/>
	        </xsl:call-template>	        
		</xsl:if>
           
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:Delivery/cac:Shipment =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== cac:PrepaidPayment =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <xsl:template match="cac:PrepaidPayment" mode="cabecera">
    	<xsl:param name="root"/>
        
        <!-- /Invoice/cac:PrepaidPayment/cbc:ID Si "Monto anticipado" existe y no existe el Tag UBL 
        OBSERV 2504 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3211'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="cbc:PaidAmount and not(string(cbc:ID))" />
            <xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
        </xsl:call-template>
        
        <!-- cac:TaxTotal/cac:TaxSubtotal/cac:TaxCategory/cac:TaxScheme/cbc:ID El valor del Tag UBL no debe repetirse en el /Invoice 
        ERROR 2352 -->
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3212'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-idprepaid-in-root', cbc:ID)) > 1" />
            <xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
        </xsl:call-template>
        
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'3213'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="count(key('by-document-additional-anticipo', cbc:ID)) = 0" />
            <xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
        </xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Anticipo)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:ID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
			<xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
		</xsl:call-template>
		
		<xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'2503'" />
            <xsl:with-param name="node" select="cbc:PaidAmount" />
            <xsl:with-param name="expresion" select="cbc:PaidAmount and cbc:PaidAmount &lt;= 0" />
            <xsl:with-param name="descripcion" select="concat('Identificador de anticipo : ', cbc:ID)"/>
        </xsl:call-template>
        
        <xsl:if test="cbc:PaidAmount and cbc:PaidAmount &gt; 0">        	
        	<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3220'" />
	            <xsl:with-param name="node" select="$root/cac:LegalMonetaryTotal/cbc:PrepaidAmount" />
	            <xsl:with-param name="expresion" select="not($root/cac:LegalMonetaryTotal/cbc:PrepaidAmount &gt; 0)" />
	        </xsl:call-template>	        
        </xsl:if>
        
    </xsl:template>
        
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin cac:PrepaidPayment =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:PaymentTerms =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:PaymentTerms">
		<xsl:param name="tipoOperacion" select = "'-'" />
		
		<xsl:if test="cbc:PaymentMeansID">
		
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3033'"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansID"/>
				<xsl:with-param name="catalogo" select="'54'"/>
			</xsl:call-template>
			
			<xsl:call-template name="existAndValidateValueTwoDecimal">
	            <xsl:with-param name="errorCodeNotExist" select="'3035'"/>
	            <xsl:with-param name="errorCodeValidate" select="'3037'"/>
	            <xsl:with-param name="node" select="cbc:Amount"/>
	        </xsl:call-template>
	        
	        <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'3208'"/>
				<xsl:with-param name="node" select="cbc:Amount/@currencyID"/>
				<xsl:with-param name="regexp" select="'^(PEN)$'"/>
				<xsl:with-param name="descripcion" select="concat('Error en la linea: ', $nroLinea)"/>
			</xsl:call-template>
			
			<!-- 		
	        <xsl:call-template name="findElementInCatalogProperty">
				<xsl:with-param name="catalogo" select="'54'"/>
				<xsl:with-param name="propiedad" select="tasa"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansID"/>
				<xsl:with-param name="valorPropiedad" select="cbc:PaymentPercent"/>
				<xsl:with-param name="errorCodeValidate" select="'3062'"/>
			</xsl:call-template>
			-->
		</xsl:if>
		
		<xsl:if test="$tipoOperacion = '1002'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3129'" />
	            <xsl:with-param name="node" select="cbc:PaymentMeansID" />
	            <xsl:with-param name="expresion" select="cbc:PaymentMeansID/text() != '004'" />
	        </xsl:call-template>
		</xsl:if>
		
    	<xsl:if test="$tipoOperacion = '1003'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3129'" />
	            <xsl:with-param name="node" select="cbc:PaymentMeansID" />
	            <xsl:with-param name="expresion" select="cbc:PaymentMeansID/text() != '028'" />
	        </xsl:call-template>
		</xsl:if>
		
		<xsl:if test="$tipoOperacion = '1004'">
			<xsl:call-template name="isTrueExpresion">
	            <xsl:with-param name="errorCodeValidate" select="'3129'" />
	            <xsl:with-param name="node" select="cbc:PaymentMeansID" />
	            <xsl:with-param name="expresion" select="cbc:PaymentMeansID/text() != '027'" />
	        </xsl:call-template>
		</xsl:if>
		
    	<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4255'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansID/@schemeName"/>
			<xsl:with-param name="regexp" select="'^(Codigo de detraccion)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4256'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansID/@schemeAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4257'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansID/@schemeURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo54)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
    </xsl:template>    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:PaymentTerms =========================================== 
    
    ===========================================================================================================================================
    -->
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== Template cac:PaymentMeans =========================================== 
    
    ===========================================================================================================================================
    -->
    <xsl:template match="cac:PaymentMeans">
		<xsl:param name="tipoOPeracion"/>
		<xsl:param name="codigoProducto"/>
		
		<xsl:if test="$codigoProducto">
	    	<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3034'"/>
				<xsl:with-param name="node" select="cac:PayeeFinancialAccount/cbc:ID"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:if test="$tipoOPeracion = '0302'">
	    	<!-- <xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3173'"/>
				<xsl:with-param name="node" select="cbc:PaymentMeansCode"/>
			</xsl:call-template>
			-->
			
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'3175'"/>
				<xsl:with-param name="node" select="cbc:PaymentID"/>
			</xsl:call-template>
			
        </xsl:if>
        
        <xsl:if test="cbc:PaymentMeansCode">
        	<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="errorCodeValidate" select="'3174'"/>
				<xsl:with-param name="idCatalogo" select="cbc:PaymentMeansCode"/>
				<xsl:with-param name="catalogo" select="'59'"/>
			</xsl:call-template>
        </xsl:if>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4252'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansCode/@listName"/>
			<xsl:with-param name="regexp" select="'^(Medio de pago)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
        <xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4251'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansCode/@listAgencyName"/>
			<xsl:with-param name="regexp" select="'^(PE:SUNAT)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4253'"/>
			<xsl:with-param name="node" select="cbc:PaymentMeansCode/@listURI"/>
			<xsl:with-param name="regexp" select="'^(urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo59)$'"/>
			<xsl:with-param name="isError" select ="false()"/>
		</xsl:call-template>
        
    </xsl:template>
    
    <!-- 
    ===========================================================================================================================================
    
    =========================================== fin Template cac:PaymentMeans =========================================== 
    
    ===========================================================================================================================================
    -->
    
    
   

</xsl:stylesheet>
