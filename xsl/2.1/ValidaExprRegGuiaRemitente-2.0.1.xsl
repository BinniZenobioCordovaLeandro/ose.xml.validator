<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:dyn="http://exslt.org/dynamic"
	xmlns:gemfunc="http://www.sunat.gob.pe/gem/functions"
	xmlns:func="http://exslt.org/functions"
	xmlns="urn:oasis:names:specification:ubl:schema:xsd:DespatchAdvice-2"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
	xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
	xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">
	<!-- xsl:include href="../../../commons/error/error_utils.xsl" dp:ignore-multiple="yes" / -->
	<xsl:include href="local:///commons/error/error_utils.xsl" dp:ignore-multiple="yes" />
	<xsl:include href="local:///commons/error/validate_utils.xsl" dp:ignore-multiple="yes" />
    
    <!-- key Numero de lineas duplicados fin -->
    <xsl:key name="by-despatchLine-id" match="*[local-name()='DespatchAdvice']/cac:DespatchLine" use="number(cbc:ID)"/>

	<xsl:template match="/*">
    
        <!-- Variables -->
		
		<xsl:variable name="numeroRuc" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 1, 11)"/>
        
        <xsl:variable name="tipoComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 13, 2)"/>
        
        <xsl:variable name="numeroSerie" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 16, 4)"/>
        
        <xsl:variable name="numeroComprobante" select="substring(dp:variable('var://context/cpe/nombreArchivoEnviado'), 21, string-length(dp:variable('var://context/cpe/nombreArchivoEnviado')) - 24)"/>
        
				
		<xsl:variable name="cbcUBLVersionID" select="cbc:UBLVersionID"/>

		<xsl:variable name="cbcCustomizationID"	select="cbc:CustomizationID"/>
		
		<xsl:variable name="cbcID" select="cbc:ID"/>
		
		<xsl:variable name="cbcDespatchAdviceTypeCode" select="cbc:DespatchAdviceTypeCode"/>
		
		<xsl:variable name="cbcIssueDate" select="cbc:IssueDate"/>
		
		<xsl:variable name="cbcNote" select="cbc:Note"/>
		
		<xsl:variable name="cacOrderReference" select="cac:OrderReference"/>
		
		<xsl:variable name="cacAdditionalDocumentReference" select="cac:AdditionalDocumentReference"/>
		
		<xsl:variable name="cbcDespatchSupplierAccountID" select="cac:DespatchSupplierParty/cbc:CustomerAssignedAccountID"/>
		
		<xsl:variable name="cbcDespatchSupplierName" select="cac:DespatchSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>		
		
		<xsl:variable name="cbcDeliveryCustomerAccountID" select="cac:DeliveryCustomerParty/cbc:CustomerAssignedAccountID"/>
		
		<xsl:variable name="cbcDeliveryCustomerName" select="cac:DeliveryCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
		
		<xsl:variable name="cbcSellerSupplierPartyAccountID" select="cac:SellerSupplierParty/cbc:CustomerAssignedAccountID"/>
		
		<xsl:variable name="cbcSellerSupplierPartyName" select="cac:SellerSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName"/>
		
		<xsl:variable name="cbcShipmentHandlingCode" select="cac:Shipment/cbc:HandlingCode"/>
		
		<xsl:variable name="cbcShipmentInformation" select="cac:Shipment/cbc:Information"/>
		
		<xsl:variable name="cbcShipmentSplitConsignmentIndicator" select="cac:Shipment/cbc:SplitConsignmentIndicator"/>
		
		<xsl:variable name="cbcShipmentGrossWeightMeasure" select="cac:Shipment/cbc:GrossWeightMeasure"/>
		
		<xsl:variable name="cbcShipmentTotalTransportHandlingUnitQuantity" select="cac:Shipment/cbc:TotalTransportHandlingUnitQuantity"/>
		
		<xsl:variable name="cbcShipmentStageTransportModeCode" select="cac:Shipment/cac:ShipmentStage/cbc:TransportModeCode"/>
		
		<xsl:variable name="cbcShipmentStageTransitPeriodStartDate" select="cac:Shipment/cac:ShipmentStage/cac:TransitPeriod/cbc:StartDate"/>
		
		<xsl:variable name="cacShipmentStageCarrierParty" select="cac:Shipment/cac:ShipmentStage/cac:CarrierParty"/>
		
		<xsl:variable name="cacShipmentStageDriverPerson" select="cac:Shipment/cac:ShipmentStage/cac:DriverPerson/cbc:ID"/>
		
		<xsl:variable name="cacTransportMeansRoadTransport" select="cac:Shipment/cac:ShipmentStage/cac:TransportMeans/cac:RoadTransport"/>
		
		<xsl:variable name="cacShipmentDeliveryAddress" select="cac:Shipment/cac:Delivery/cac:DeliveryAddress"/>		
		
		<xsl:variable name="cacShipmentOriginAddress" select="cac:Shipment/cac:OriginAddress"/>
		
		<xsl:variable name="cacDespatchLine" select="cac:DespatchLine"/>
		
	
		<!-- Version del UBL -->
		
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2111'"/>
			<xsl:with-param name="errorCodeValidate" select="'2110'"/>
			<xsl:with-param name="node" select="$cbcUBLVersionID"/>
			<xsl:with-param name="regexp" select="'^(2.1)$'"/>
		</xsl:call-template>
		
		
		<!-- Version de la Estructura del Documento -->
		
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2113'"/>
			<xsl:with-param name="errorCodeValidate" select="'2112'"/>
			<xsl:with-param name="node" select="$cbcCustomizationID"/>
			<xsl:with-param name="regexp" select="'^(1.0)$'"/>
		</xsl:call-template>
		
				
		<!-- Numeracion, conformada por serie y numero correlativo -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'1001'"/>
			<xsl:with-param name="node" select="$cbcID"/>
			<xsl:with-param name="regexp" select="'^[T][A-Z0-9]{3}-[0-9]{1,8}?$'"/>
		</xsl:call-template>
		
		<!-- Numero de RUC del nombre del archivo no coincide con el consignado en el contenido del archivo XML 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1034'" />
            <xsl:with-param name="node" select="$cbcDespatchSupplierAccountID" />
            <xsl:with-param name="expresion" select="$numeroRuc != $cbcDespatchSupplierAccountID" />
        </xsl:call-template>
        -->
        <!-- Numero de Serie del nombre del archivo no coincide con el consignado en el contenido del archivo XML 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1035'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroSerie != substring($cbcID, 1, 4)" />
        </xsl:call-template>
        -->
        <!-- Numero de documento en el nombre del archivo no coincide con el consignado en el contenido del XML 
        <xsl:call-template name="isTrueExpresion">
            <xsl:with-param name="errorCodeValidate" select="'1036'" />
            <xsl:with-param name="node" select="cbc:ID" />
            <xsl:with-param name="expresion" select="$numeroComprobante != substring($cbcID, 6)" />
        </xsl:call-template>
		-->
		
		<!-- cbc:IssueDate La diferencia entre la fecha de recepción del XML y el valor del Tag UBL es mayor al límite del listado ERROR 2108 -->
        <!--  El valor del Tag UBL es mayor a dos días de la fecha de envío del comprobante ERROR 2329 -->
		
		<!-- Fecha de emision, patron YYYY-MM-DD 
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'1010'"/>
			<xsl:with-param name="errorCodeValidate" select="'1009'"/>
			<xsl:with-param name="node" select="$cbcIssueDate"/>
			<xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
		</xsl:call-template>
		--> 
		
		<!-- Tipo Comprobante --> 		
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'1050'"/>
			<xsl:with-param name="errorCodeValidate" select="'1051'"/>
			<xsl:with-param name="node" select="$cbcDespatchAdviceTypeCode"/>
			<xsl:with-param name="regexp" select="'^(09)$'"/>
		</xsl:call-template>
				
		<!--  Observaciones  -->
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4186'"/>
			<xsl:with-param name="node" select="$cbcNote"/>
			<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{1,250}$'"/>
			<xsl:with-param name="isError" select="false()"/>
		</xsl:call-template> 
		
		<!-- Guia de baja -->	
		<xsl:if test="cac:OrderReference">
			<xsl:choose>
				<xsl:when test="count(cac:OrderReference)>1">
					<xsl:call-template name="rejectCall">
						<xsl:with-param name="errorCode" select="'2753'" />
						<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 2753)'" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:for-each select="cac:OrderReference">					
						<xsl:call-template name="regexpValidateElementIfExist">
							<xsl:with-param name="errorCodeValidate" select="'1055'"/>
							<xsl:with-param name="node" select="./cbc:ID"/>
							<xsl:with-param name="regexp" select="'^[T][A-Z0-9]{3}-[0-9]{1,8}$|^(EG01)-[0-9]{1,8}$'"/>
						</xsl:call-template> 
						<!-- 
						<xsl:call-template name="existAndRegexpValidateElement">
							<xsl:with-param name="errorCodeNotExist" select="'1053'"/>
							<xsl:with-param name="errorCodeValidate" select="'1054'"/>
							<xsl:with-param name="node" select="./cbc:ID"/>
							<xsl:with-param name="regexp" select="'^[A-Z0-9]{4}-[0-9]{1,8}$'"/>
						</xsl:call-template>
						<xsl:if test="not(regexp:match(substring(./cbc:ID,1,4),'^[T][A-Z0-9]{3}$|^(EG01)$'))">
							<xsl:call-template name="rejectCall">
								<xsl:with-param name="errorCode" select="'1055'" />
								<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 1055)'" />
							</xsl:call-template>
						</xsl:if>
						 -->
						<!-- Falta buscar del catalogo 21 -->				
						<xsl:call-template name="existAndRegexpValidateElement">
							<xsl:with-param name="errorCodeNotExist" select="'1056'"/>
							<xsl:with-param name="errorCodeValidate" select="'2755'"/>
							<xsl:with-param name="node" select="./cbc:OrderTypeCode"/>
							<xsl:with-param name="regexp" select="'^(09)$'"/>
						</xsl:call-template>

						<!-- ^(?!\s*$)[^\s].{2,250}$ 
							 ^(?!\s*$)[^\s]{1,100}$
						-->
						<xsl:call-template name="regexpValidateElementIfExist">
							<xsl:with-param name="errorCodeValidate" select="'4187'"/>
							<xsl:with-param name="node" select="cbc:OrderTypeCode/@name"/>
							<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,49}$'"/>							
							<xsl:with-param name="isError" select="false()"/>
						</xsl:call-template>
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>		
		
		<!-- Documento relacionado -->	
		<xsl:if test="$cacAdditionalDocumentReference">
			<xsl:for-each select="$cacAdditionalDocumentReference">
				
				
				<!-- Falta buscar del catalogo 21 -->				
				<xsl:call-template name="existAndRegexpValidateElement">
					<xsl:with-param name="errorCodeNotExist" select="'1058'"/>
					<xsl:with-param name="errorCodeValidate" select="'2755'"/>
					<xsl:with-param name="node" select="./cbc:DocumentTypeCode"/>
					<xsl:with-param name="regexp" select="'^[0-9]{1,2}$'"/>
				</xsl:call-template>
				
				<xsl:call-template name="findElementInCatalog">
					<xsl:with-param name="errorCodeValidate" select="'2755'"/>
					<xsl:with-param name="idCatalogo" select="./cbc:DocumentTypeCode"/>
					<xsl:with-param name="catalogo" select="'21'"/>
				</xsl:call-template>
				
				<xsl:if test="./cbc:DocumentTypeCode[text() = '01']">
					<xsl:call-template name="regexpValidateElementIfExist">
						<xsl:with-param name="errorCodeValidate" select="'2769'"/>
						<xsl:with-param name="node" select="./cbc:ID"/>
						<xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-[0-9]{2}-[0-9]{4,6}$|^[0-9]{4}-[0-9]{2}-[0-9]{3}-[0-9]{4}$'"/>
					</xsl:call-template>		 
				</xsl:if>
				
				<xsl:if test="./cbc:DocumentTypeCode[text() = '04']">
					<xsl:call-template name="regexpValidateElementIfExist">
						<xsl:with-param name="errorCodeValidate" select="'1057'"/>
						<xsl:with-param name="node" select="./cbc:ID"/>
						<xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-[0-9]{4}$'"/>									
					</xsl:call-template>
					<!-- 
					<xsl:call-template name="existAndRegexpValidateElement">
						<xsl:with-param name="errorCodeNotExist" select="'1057'"/>
						<xsl:with-param name="errorCodeValidate" select="'2770'"/>
						<xsl:with-param name="node" select="./cbc:ID"/>
						<xsl:with-param name="regexp" select="'^[0-9]{3}-[0-9]{4}-[0-9]{4}$'"/>
					</xsl:call-template>
					-->
				</xsl:if>
				
				<xsl:if test="./cbc:DocumentTypeCode[text() != '04' and text() != '01']">		
					<xsl:call-template name="regexpValidateElementIfExist">
						<xsl:with-param name="errorCodeValidate" select="'2756'"/>
						<xsl:with-param name="node" select="./cbc:ID"/>
						<xsl:with-param name="regexp" select="'^.{1,20}$'"/>									
					</xsl:call-template>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		
		<!--  Datos del remitente -->		
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2676'"/>
			<xsl:with-param name="errorCodeValidate" select="'2677'"/>
			<xsl:with-param name="node" select="$cbcDespatchSupplierAccountID"/>
			<xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
		</xsl:call-template>	
					
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2678'"/>
			<xsl:with-param name="errorCodeValidate" select="'2511'"/>
			<xsl:with-param name="node" select="$cbcDespatchSupplierAccountID/@schemeID"/>
			<xsl:with-param name="regexp" select="'^(6)$'"/>
		</xsl:call-template>						
				
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'1037'"/>
			<xsl:with-param name="errorCodeValidate" select="'1038'"/>
			<xsl:with-param name="node" select="$cbcDespatchSupplierName"/>
			<xsl:with-param name="regexp" select="'^(.{1,100})$'"/>
		</xsl:call-template>				
		
		<!-- Datos del destinatario -->
		<xsl:call-template name="existElement">
			<xsl:with-param name="errorCodeNotExist" select="'2757'"/>
			<xsl:with-param name="node" select="$cbcDeliveryCustomerAccountID"/>
		</xsl:call-template>	
					
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2759'"/>
			<xsl:with-param name="errorCodeValidate" select="'2760'"/>
			<xsl:with-param name="node" select="$cbcDeliveryCustomerAccountID/@schemeID"/>
			<xsl:with-param name="regexp" select="'^(0|1|4|6|7|A)$'"/>
		</xsl:call-template>						
		
		<xsl:choose>
			<xsl:when test="$cbcDeliveryCustomerAccountID/@schemeID = '0'">
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2758'"/>
					<xsl:with-param name="node" select="$cbcDeliveryCustomerAccountID"/>
					<xsl:with-param name="regexp" select="'^[a-zA-Z0-9]{1,15}$'"/>				
				</xsl:call-template>
			</xsl:when>			
			<xsl:when test="$cbcDeliveryCustomerAccountID/@schemeID = '1'">
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4207'"/>
					<xsl:with-param name="node" select="$cbcDeliveryCustomerAccountID"/>
					<xsl:with-param name="regexp" select="'^[0-9]{8}$'"/>
					<xsl:with-param name="isError" select="false()"/>					
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$cbcDeliveryCustomerAccountID/@schemeID = '4'">
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4208'"/>
					<xsl:with-param name="node" select="$cbcDeliveryCustomerAccountID"/>
					<xsl:with-param name="regexp" select="'^[a-zA-Z0-9]{1,12}$'"/>		
					<xsl:with-param name="isError" select="false()"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$cbcDeliveryCustomerAccountID/@schemeID = '6'">				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2017'"/>
					<xsl:with-param name="node" select="$cbcDeliveryCustomerAccountID"/>
					<xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$cbcDeliveryCustomerAccountID/@schemeID = '7'">				
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'4208'"/>
					<xsl:with-param name="node" select="$cbcDeliveryCustomerAccountID"/>
					<xsl:with-param name="regexp" select="'^[a-zA-Z0-9]{1,12}$'"/>	
					<xsl:with-param name="isError" select="false()"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="regexpValidateElementIfExist">
					<xsl:with-param name="errorCodeValidate" select="'2758'"/>
					<xsl:with-param name="node" select="$cbcDeliveryCustomerAccountID"/>
					<xsl:with-param name="regexp" select="'^[a-zA-Z0-9]{1,15}$'"/>
				</xsl:call-template>	
			</xsl:otherwise>
		</xsl:choose>		
		
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'2761'"/>
			<xsl:with-param name="errorCodeValidate" select="'2762'"/>
			<xsl:with-param name="node" select="$cbcDeliveryCustomerName"/>
			<xsl:with-param name="regexp" select="'^(.{1,100})$'"/>
		</xsl:call-template>				
		
		<!--  Datos de información del tercero -->
		<xsl:if test="cac:SellerSupplierParty">
			<!--		
			<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2763'"/>
				<xsl:with-param name="errorCodeValidate" select="'2764'"/>
				<xsl:with-param name="node" select="$cbcSellerSupplierPartyAccountID"/>
				<xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
			</xsl:call-template>	
			-->
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2764'"/>
				<xsl:with-param name="node" select="$cbcSellerSupplierPartyAccountID"/>
				<xsl:with-param name="regexp" select="'^[1-2][0-9]{10}$'"/>
			</xsl:call-template>
			
			<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2765'"/>
				<xsl:with-param name="errorCodeValidate" select="'2566'"/>
				<xsl:with-param name="node" select="$cbcSellerSupplierPartyAccountID/@schemeID"/>
				<xsl:with-param name="regexp" select="'^(6)$'"/>
			</xsl:call-template>						
			
			<!--			
			<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'4188'"/>
				<xsl:with-param name="errorCodeValidate" select="'4189'"/>
				<xsl:with-param name="node" select="$cbcSellerSupplierPartyName"/>
				<xsl:with-param name="regexp" select="'^(.{1,100})$'"/>
			</xsl:call-template>
			-->
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4189'"/>
				<xsl:with-param name="node" select="$cbcSellerSupplierPartyName"/>
				<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{0,99}$'"/> <!-- de 1 a 100 caracteres menos saltos de linea (el punto cuenta como un caracter) -->
			</xsl:call-template>			
			
			<xsl:if test="$cbcSellerSupplierPartyAccountID = $cbcDespatchSupplierAccountID or $cbcSellerSupplierPartyAccountID = $cbcDeliveryCustomerAccountID"> 
				<xsl:call-template name="rejectCall">
					<xsl:with-param name="errorCode" select="'4053'" />
					<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 4053)'" />
				</xsl:call-template>
			</xsl:if>
						
		</xsl:if>
		
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'1062'"/>
			<xsl:with-param name="errorCodeValidate" select="'1063'"/>
			<xsl:with-param name="node" select="$cbcShipmentHandlingCode"/>
			<xsl:with-param name="regexp" select="'^(01|1|02|2|04|4|08|8|09|9|13|14|18|19)$'"/>
		</xsl:call-template>
		
		<xsl:if test="$cbcShipmentHandlingCode[text() = '18' or text() = '04' or text() = '4' or text() = '02' or text() = '2']">
			<xsl:if test="$cbcDeliveryCustomerAccountID != $cbcDespatchSupplierAccountID"> 
				<xsl:call-template name="rejectCall">
					<xsl:with-param name="errorCode" select="'2554'" />
					<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 2554)'" />
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
		
		<!-- PAS20165E210300240 - Ajsute por validación de destinatario <> remitente, cuando motivo = 01 o  19 o 09  -->
		<xsl:if test="$cbcShipmentHandlingCode[text() = '01' or text() = '1' or text() = '19' or text() = '09' or text() = '9']">
			<xsl:if test="$cbcDeliveryCustomerAccountID = $cbcDespatchSupplierAccountID"> 
				<xsl:call-template name="rejectCall">
					<xsl:with-param name="errorCode" select="'2555'" />
					<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 2555)'" />
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
		
		<!-- Obligatorio para importación -->
		<xsl:if test="$cbcShipmentHandlingCode[text() = '08' or text() = '8' or text() = '09' or text() = '9']">
			<xsl:if test="count($cacAdditionalDocumentReference/cbc:DocumentTypeCode[text()='01']) = 0">
				<xsl:call-template name="rejectCall">
					<xsl:with-param name="errorCode" select="'2767'" />
					<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 2767)'" />
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
			
		<xsl:if test="$cbcShipmentHandlingCode[text() = '08' or text() = '8']">
			<xsl:if test="count($cacAdditionalDocumentReference/cbc:DocumentTypeCode[text()='04']) = 0">
				<xsl:call-template name="rejectCall">
					<xsl:with-param name="errorCode" select="'2768'" />
					<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 2768)'" />
				</xsl:call-template>
			</xsl:if>
			
			<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2771'"/>
				<xsl:with-param name="errorCodeValidate" select="'2772'"/>
				<xsl:with-param name="node" select="$cbcShipmentTotalTransportHandlingUnitQuantity"/>
				<xsl:with-param name="regexp" select="'^([0-9]{1,12})$'"/>				
			</xsl:call-template>
			
		</xsl:if>
		
		<!-- No se consigna numeracióón DAM para motivo de traslado diferente a importacion o exportacion -->
		<xsl:if test="$cbcShipmentHandlingCode[text() != '08' and text() != '8' and text() != '09' and text() != '9']">
			<xsl:if test="count($cacAdditionalDocumentReference/cbc:DocumentTypeCode[text()='01']) != 0">
				<xsl:call-template name="addWarning">
					<xsl:with-param name="warningCode" select="'4191'" />
					<xsl:with-param name="warningMessage" select="'Error Expr Regular guia remision (codigo: 4191)'" />
				</xsl:call-template>
			</xsl:if>
			
			<xsl:if test="count($cacAdditionalDocumentReference/cbc:DocumentTypeCode[text()='04']) != 0">
				<xsl:call-template name="addWarning">
					<xsl:with-param name="warningCode" select="'4192'" />
					<xsl:with-param name="warningMessage" select="'Error Expr Regular guia remision (codigo: 4192)'" />
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
		
		<!-- No se consigna manifiesto de carga para motivo de traslado diferente a importacion -->
		<xsl:if test="$cbcShipmentHandlingCode[text() != '08' and text() != '8']">
			
			<xsl:if test="$cbcShipmentTotalTransportHandlingUnitQuantity">
				<xsl:call-template name="addWarning">
					<xsl:with-param name="warningCode" select="'4195'" />
					<xsl:with-param name="warningMessage" select="'Error Expr Regular guia remision (codigo: 4195)'" />
				</xsl:call-template>
			</xsl:if>
			
			<!-- 
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'4195'"/>
				<xsl:with-param name="node" select="$cbcShipmentTotalTransportHandlingUnitQuantity"/>
			</xsl:call-template>
			-->
		</xsl:if>
		
		<xsl:if test="$cbcShipmentHandlingCode[text() = '13']">
			<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'4055'"/>
				<xsl:with-param name="errorCodeValidate" select="'4190'"/>
				<xsl:with-param name="node" select="$cbcShipmentInformation"/>
				<xsl:with-param name="regexp" select="'^(.{1,100})$'"/>
				<xsl:with-param name="isError" select="false()"/>
			</xsl:call-template>			
		</xsl:if>
		
		<xsl:call-template name="regexpValidateElementIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4193'"/>
			<xsl:with-param name="node" select="$cbcShipmentSplitConsignmentIndicator"/>
			<xsl:with-param name="regexp" select="'^(true|false)$'"/>
			<xsl:with-param name="isError" select="false()"/>
		</xsl:call-template>			
		
		<!-- 2017-010 IMR 2017-08-28 Ajustes de validaciones de OSE -->
		<xsl:if test="not($cbcShipmentGrossWeightMeasure)">
			<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'2880'" />
				<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 2880)'" />
			</xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="validateValueThreeDecimalIfExist">
			<xsl:with-param name="errorCodeValidate" select="'4155'"/>
			<xsl:with-param name="node" select="$cbcShipmentGrossWeightMeasure"/>
			<xsl:with-param name="isError" select="false()"/>
		</xsl:call-template>		
		
		<xsl:if test="$cbcShipmentGrossWeightMeasure">
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'2881'"/>
				<xsl:with-param name="node" select="$cbcShipmentGrossWeightMeasure/@unitCode"/>
			</xsl:call-template>		
				
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'4154'"/>
				<xsl:with-param name="node" select="$cbcShipmentGrossWeightMeasure/@unitCode"/>
				<xsl:with-param name="regexp" select="'^(KGM)$'"/>
				<xsl:with-param name="isError" select="false()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'1065'"/>
			<xsl:with-param name="errorCodeValidate" select="'2773'"/>
			<xsl:with-param name="node" select="$cbcShipmentStageTransportModeCode"/>
			<xsl:with-param name="regexp" select="'^(01|02|1|2)$'"/>			
		</xsl:call-template>
		
		<xsl:if test="not($cbcShipmentStageTransitPeriodStartDate)">
			<xsl:call-template name="rejectCall">
				<xsl:with-param name="errorCode" select="'1069'" />
				<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 1069)'" />
			</xsl:call-template>
		</xsl:if>
		<!--
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'1065'"/>
			<xsl:with-param name="errorCodeValidate" select="'2773'"/>
			<xsl:with-param name="node" select="$cbcShipmentStageTransitPeriodStartDate"/>
			<xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>			
		</xsl:call-template>		
		-->
		
		<!-- cacShipmentStageCarrierParty (transportista)
		cacShipmentStageDriverPerson (conductores)
		cacTransportMeansRoadTransport (vehiculo) -->
		<xsl:if test="$cbcShipmentStageTransportModeCode[text() = '01']">
			<xsl:if test="not($cacShipmentStageCarrierParty)">
                <xsl:call-template name="addWarning">
                	<xsl:with-param name="warningCode" select="'1066'"/> 
           			<xsl:with-param name="warningMessage" select="'Error Expr Regular guia remision (codigo: 1066)'"/>
           		</xsl:call-template>
            </xsl:if>
           	
           	<xsl:if test="$cacTransportMeansRoadTransport/cbc:LicensePlateID or $cacShipmentStageDriverPerson">                
                <xsl:if test="not($cacTransportMeansRoadTransport/cbc:LicensePlateID) or not($cacShipmentStageDriverPerson) ">
	                <xsl:call-template name="rejectCall">
	                	<xsl:with-param name="errorCode" select="'2774'"/> 
	           			<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 2774)'"/>
	           		</xsl:call-template>
	        	</xsl:if>		        	   		
            </xsl:if>
		</xsl:if>
		
		<xsl:if test="$cbcShipmentStageTransportModeCode[text() = '02']">
			<xsl:if test="not($cacTransportMeansRoadTransport/cbc:LicensePlateID)">
                <xsl:call-template name="rejectCall">
                	<xsl:with-param name="errorCode" select="'1067'"/> 
           			<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 1067)'"/>
           		</xsl:call-template>
            </xsl:if>
            
            <!-- 
            <xsl:if test="not($cacShipmentStageDriverPerson)">
                <xsl:call-template name="rejectCall">
                	<xsl:with-param name="errorCode" select="'1068'"/> 
           			<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 1068)'"/>
           		</xsl:call-template>
            </xsl:if>
           	-->
           	<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'1068'"/>
				<xsl:with-param name="node" select="$cacShipmentStageDriverPerson"/>
			</xsl:call-template>
			
           	<xsl:if test="$cacShipmentStageCarrierParty">
                <xsl:call-template name="addWarning">
                	<xsl:with-param name="warningCode" select="'4159'"/> 
           			<xsl:with-param name="warningMessage" select="'Error Expr Regular guia remision (codigo: 4159)'"/>
           		</xsl:call-template>
            </xsl:if>		      
		</xsl:if>
		
		
		<!-- Fecha de inicio de traslado o fecha de entrega de bienes al transportista --> 
		<!--
		<xsl:call-template name="existAndRegexpValidateElement">
			<xsl:with-param name="errorCodeNotExist" select="'1069'"/>
			<xsl:with-param name="errorCodeValidate" select="'1070'"/>
			<xsl:with-param name="node" select="$cbcShipmentStageTransitPeriodStartDate"/>
			<xsl:with-param name="regexp" select="'^[0-9]{4}-[0-9]{2}-[0-9]{2}?$'"/>
		</xsl:call-template>
		-->
		<!--
		<xsl:if test="not($cacShipmentDeliveryAddress)">
			<xsl:call-template name="rejectCall">
		    	<xsl:with-param name="errorCode" select="'1074'"/> 
				<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 1074)'"/>
			</xsl:call-template>
		</xsl:if>
		-->
		
		<!-- <xsl:for-each select="$cacShipmentDeliveryAddress">  -->
         	<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2775'"/>
				<xsl:with-param name="errorCodeValidate" select="'2776'"/>
				<xsl:with-param name="node" select="$cacShipmentDeliveryAddress/cbc:ID"/>
				<xsl:with-param name="regexp" select="'^[0-9]{6}$'"/>
			</xsl:call-template>
         	
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="idCatalogo" select="$cacShipmentDeliveryAddress/cbc:ID"/>
				<xsl:with-param name="errorCodeValidate" select="'4200'"/>
				<xsl:with-param name="isError" select="false()"/>
			</xsl:call-template>
			
            <xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2777'"/>
				<xsl:with-param name="errorCodeValidate" select="'2778'"/>
				<xsl:with-param name="node" select="$cacShipmentDeliveryAddress/cbc:StreetName"/>
				<xsl:with-param name="regexp" select="'^(.{1,100})$'"/>
			</xsl:call-template>
			             
		<!-- </xsl:for-each>
		-->
		
		<!--		
		<xsl:if test="not($cacShipmentOriginAddress)">
		    <xsl:call-template name="rejectCall">
		    	<xsl:with-param name="errorCode" select="'1075'"/> 
				<xsl:with-param name="errorMessage" select="'Error Expr Regular guia remision (codigo: 1075)'"/>
		    </xsl:call-template>
		</xsl:if>
		-->
		
		<xsl:for-each select="$cacShipmentOriginAddress">
            
         	<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2775'"/>
				<xsl:with-param name="errorCodeValidate" select="'2776'"/>
				<xsl:with-param name="node" select="./cbc:ID"/>
				<xsl:with-param name="regexp" select="'^[0-9]{6}$'"/>
			</xsl:call-template>
         				
			<xsl:call-template name="findElementInCatalog">
				<xsl:with-param name="catalogo" select="'13'"/>
				<xsl:with-param name="idCatalogo" select="./cbc:ID"/>
				<xsl:with-param name="errorCodeValidate" select="'4200'"/>
				<xsl:with-param name="isError" select="false()"/>
			</xsl:call-template>
			
            <xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2777'"/>
				<xsl:with-param name="errorCodeValidate" select="'2778'"/>
				<xsl:with-param name="node" select="./cbc:StreetName"/>
				<xsl:with-param name="regexp" select="'^(.{1,100})$'"/>
			</xsl:call-template>
			             
		</xsl:for-each>
		
	    <xsl:for-each select="$cacDespatchLine">
        				
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2023'"/>
				<xsl:with-param name="node" select="./cbc:ID"/>
				<xsl:with-param name="regexp" select="'^[0-9]{1,3}?$'"/>			
			</xsl:call-template>
			
			<xsl:if test="count(key('by-despatchLine-id', number(cbc:ID))) > 1">
                 <xsl:call-template name="rejectCall"> <xsl:with-param name="errorCode" select="'2752'" /> <xsl:with-param name="errorMessage" select="concat('El numero de item esta duplicado: ', cbc:ID)" /> </xsl:call-template>
            </xsl:if>
			
			<!--<xsl:call-template name="existAndRegexpValidateElement">
				<xsl:with-param name="errorCodeNotExist" select="'2779'"/>
				<xsl:with-param name="errorCodeValidate" select="'2780'"/>
				<xsl:with-param name="node" select="./cbc:DeliveredQuantity"/>
				<xsl:with-param name="regexp" select="'(?!(^0+(\.0+)?$))(^\d{1,12}(\.\d{1,10})?$)'"/>
			</xsl:call-template>
			-->
			<!-- cac:InvoiceLine/cbc:InvoicedQuantity No existe el Tag UBL ERROR 2024 -->
	        <!--  El formato del Tag UBL es diferente de decimal de 12 enteros y hasta 10 decimales ERROR 2025 -->
	        <!-- Cantidad de unidades por item -->
	        <xsl:call-template name="existAndValidateValueTenDecimal">
	            <xsl:with-param name="errorCodeNotExist" select="'2779'"/>
	            <xsl:with-param name="errorCodeValidate" select="'2780'"/>
	            <xsl:with-param name="node" select="./cbc:DeliveredQuantity"/>
	            <xsl:with-param name="isGreaterCero" select="false()"/>
	        </xsl:call-template>
         				
			<xsl:call-template name="existElement">
				<xsl:with-param name="errorCodeNotExist" select="'2781'"/>
				<xsl:with-param name="node" select="./cac:Item/cbc:Name"/>
			</xsl:call-template>
			
			<xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2782'"/>
				<xsl:with-param name="node" select="./cac:Item/cbc:Name"/>
				<xsl:with-param name="regexp" select="'^(?!\s*$)[^\s].{2,250}$'"/>
				<xsl:with-param name="isError" select="false()"/>
			</xsl:call-template>
                        
            <xsl:call-template name="regexpValidateElementIfExist">
				<xsl:with-param name="errorCodeValidate" select="'2783'"/>
				<xsl:with-param name="node" select="./cac:Item/cac:SellersItemIdentification/cbc:ID"/>
				<xsl:with-param name="regexp" select="'^(?!\s*$).{1,16}$'"/>
				<xsl:with-param name="isError" select="false()"/>			
			</xsl:call-template>	
			
	    </xsl:for-each>
	    
		<xsl:copy-of select="." />
		
	</xsl:template>
	
</xsl:stylesheet>
